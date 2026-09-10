import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:artisanal/editor_core.dart'
    show
        EditorCompletionItem,
        EditorCompletionKind,
        EditorCompletionRequest,
        EditorCompletionResult,
        TextDiagnosticSeverity,
        TextDocument,
        parseSnippet;
import 'package:pro_lsp/pro_lsp.dart';
import 'package:stream_channel/stream_channel.dart';

import 'editor_language_service.dart';

typedef LanguageServerProcessStarter = Future<Process> Function();

/// LSP client for the Dart language server shipped with the Dart SDK.
///
/// Protocol framing, typed messages, requests, and lifecycle state are
/// delegated to `package:pro_lsp`.
final class DartLanguageService implements EditorLanguageService {
  DartLanguageService({
    required this.workspaceRoot,
    LanguageServerProcessStarter? startProcess,
    this.changeDebounce = const Duration(milliseconds: 180),
  }) : _startProcess = startProcess;

  final String workspaceRoot;
  final LanguageServerProcessStarter? _startProcess;
  final Duration changeDebounce;
  final StreamController<EditorLanguageEvent> _events =
      StreamController.broadcast(sync: true);
  final Map<String, _DartDocument> _documents = {};

  Future<LspClient>? _startingClient;
  LspClient? _client;
  Process? _process;
  StreamSubscription<String>? _stderrSubscription;
  bool _disposed = false;

  @override
  Stream<EditorLanguageEvent> get events => _events.stream;

  @override
  bool supports(String languageId) => languageId == 'dart';

  @override
  void openDocument({
    required String path,
    required String languageId,
    required String text,
  }) {
    if (_disposed || !supports(languageId) || _documents.containsKey(path)) {
      return;
    }
    final document = _DartDocument(path: path, text: text);
    _documents[path] = document;
    final opening = _openDocument(document);
    document.opening = opening;
    unawaited(opening);
  }

  Future<void> _openDocument(_DartDocument document) async {
    try {
      final client = await _ensureClient();
      if (_disposed || !_documents.containsKey(document.path)) return;
      client.server.textDocument.didOpen(
        DidOpenTextDocumentParams(
          textDocument: TextDocumentItem(
            uri: document.uri,
            languageId: LanguageKind.dart,
            version: document.version,
            text: document.text,
          ),
        ),
      );
      document.opened = true;
      document.lastSentVersion = document.version;
    } catch (error) {
      _emit(EditorLanguageStatus('Dart LSP failed: $error', ready: false));
    }
  }

  @override
  void changeDocument({required String path, required String text}) {
    final document = _documents[path];
    if (_disposed || document == null || document.text == text) return;
    document
      ..text = text
      ..version += 1
      ..changeTimer?.cancel()
      ..changeTimer = Timer(changeDebounce, () => _publishChange(document));
  }

  void _publishChange(_DartDocument document) {
    final client = _client;
    if (_disposed ||
        client == null ||
        !document.opened ||
        document.lastSentVersion == document.version) {
      return;
    }
    client.server.textDocument.didChange(
      DidChangeTextDocumentParams(
        textDocument: VersionedTextDocumentIdentifier(
          uri: document.uri,
          version: document.version,
        ),
        contentChanges: [
          TextDocumentContentChangeEvent.textDocumentContentChangeWholeDocument(
            TextDocumentContentChangeWholeDocument(text: document.text),
          ),
        ],
      ),
    );
    document.lastSentVersion = document.version;
  }

  @override
  void closeDocument(String path) {
    final document = _documents.remove(path);
    if (document == null) return;
    document.changeTimer?.cancel();
    if (document.opened) {
      _client?.server.textDocument.didClose(
        DidCloseTextDocumentParams(
          textDocument: TextDocumentIdentifier(uri: document.uri),
        ),
      );
    }
  }

  @override
  void saveDocument({required String path, required String text}) {
    final document = _documents[path];
    if (document == null || !document.opened) return;
    _client?.server.textDocument.didSave(
      DidSaveTextDocumentParams(
        textDocument: TextDocumentIdentifier(uri: document.uri),
        text: text,
      ),
    );
  }

  @override
  Future<EditorCompletionResult> provideCompletions({
    required String path,
    required EditorCompletionRequest request,
  }) async {
    final document = _documents[path];
    if (_disposed || document == null) return const EditorCompletionResult();

    changeDocument(path: path, text: request.documentText);
    await document.opening;
    final client = _client;
    if (_disposed || client == null || !document.opened) {
      return const EditorCompletionResult();
    }

    document.changeTimer?.cancel();
    _publishChange(document);
    final editorDocument = TextDocument(text: request.documentText);
    final position = toEditorLanguagePosition(
      editorDocument,
      request.cursorOffset,
    );
    final result = await client.server.textDocument.completion(
      CompletionParams(
        textDocument: TextDocumentIdentifier(uri: document.uri),
        position: Position(line: position.line, character: position.character),
      ),
      timeout: const Duration(seconds: 5),
    );
    if (result.isNull) return const EditorCompletionResult();

    final completionList = result.asCompletionList;
    final items =
        completionList?.items ??
        result.asCompletionItemList ??
        const <CompletionItem>[];
    return EditorCompletionResult(
      items: [
        for (final item in items)
          _toEditorCompletion(editorDocument, request.cursorOffset, item),
      ],
      isIncomplete: completionList?.isIncomplete ?? false,
    );
  }

  @override
  Future<EditorLanguageHover?> provideHover({
    required String path,
    required String documentText,
    required int cursorOffset,
  }) async {
    final document = _documents[path];
    if (_disposed || document == null) return null;

    changeDocument(path: path, text: documentText);
    await document.opening;
    final client = _client;
    if (_disposed || client == null || !document.opened) return null;

    document.changeTimer?.cancel();
    _publishChange(document);
    final editorDocument = TextDocument(text: documentText);
    final position = toEditorLanguagePosition(editorDocument, cursorOffset);
    final hover = await client.server.textDocument.hover(
      HoverParams(
        textDocument: TextDocumentIdentifier(uri: document.uri),
        position: Position(line: position.line, character: position.character),
      ),
      timeout: const Duration(seconds: 5),
    );
    if (hover == null) return null;

    final contents = _hoverContents(hover.contents.toJson()).trim();
    if (contents.isEmpty) return null;
    final range = hover.range;
    return EditorLanguageHover(
      contents: contents,
      startOffset: range == null
          ? null
          : editorOffsetForLanguagePosition(
              editorDocument,
              range.start.line,
              range.start.character,
            ),
      endOffset: range == null
          ? null
          : editorOffsetForLanguagePosition(
              editorDocument,
              range.end.line,
              range.end.character,
              roundUp: true,
            ),
    );
  }

  Future<LspClient> _ensureClient() {
    final client = _client;
    if (client != null) return Future.value(client);
    return _startingClient ??= _startClient().whenComplete(() {
      _startingClient = null;
    });
  }

  Future<LspClient> _startClient() async {
    _emit(const EditorLanguageStatus('Starting Dart LSP…', ready: false));
    final process =
        await (_startProcess?.call() ??
            Process.start('dart', const [
              'language-server',
              '--protocol=lsp',
            ], workingDirectory: workspaceRoot));
    _process = process;
    final stderrSubscription = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          if (line.trim().isNotEmpty) {
            _emit(EditorLanguageStatus('Dart LSP: $line'));
          }
        });
    _stderrSubscription = stderrSubscription;

    final client = LspClient.fromChannel(
      StreamChannel<List<int>>(process.stdout, process.stdin),
    );
    client.onError = (error, _) =>
        _emit(EditorLanguageStatus('Dart LSP error: $error', ready: false));
    client.textDocument.onPublishDiagnostics(_handleDiagnostics);
    try {
      await client.start(
        capabilities: const ClientCapabilities(),
        rootUri: Uri.directory(workspaceRoot).toString(),
        clientInfo: const ClientInfo(
          name: 'artisanal-editor',
          version: '0.1.0-dev.1',
        ),
      );
    } catch (_) {
      try {
        await client.close();
      } on Object {
        // Continue cleaning up the failed process and subscriptions.
      }
      try {
        await stderrSubscription.cancel();
      } on Object {
        // Continue cleaning up the failed process.
      }
      process.kill();
      if (identical(_client, client)) _client = null;
      if (identical(_process, process)) _process = null;
      if (identical(_stderrSubscription, stderrSubscription)) {
        _stderrSubscription = null;
      }
      rethrow;
    }
    if (_disposed) {
      await client.close();
      throw StateError('Language service disposed during startup.');
    }
    _client = client;
    _emit(const EditorLanguageStatus('Dart LSP ready', ready: true));
    unawaited(
      process.exitCode.then((code) {
        if (!_disposed) {
          _emit(
            EditorLanguageStatus(
              'Dart LSP exited with code $code',
              ready: false,
            ),
          );
        }
      }),
    );
    return client;
  }

  Future<void> _handleDiagnostics(
    PublishDiagnosticsParams params,
    LspRequest _,
  ) async {
    final document = _documents.values
        .where((candidate) => candidate.uri == params.uri)
        .firstOrNull;
    if (document == null || document.changeTimer?.isActive == true) return;
    final version = params.version;
    if (version != null && version < document.lastSentVersion) return;
    _emit(
      EditorLanguageDiagnostics(
        uri: params.uri,
        version: version,
        diagnostics: [
          for (final diagnostic in params.diagnostics)
            EditorLanguageDiagnostic(
              startLine: diagnostic.range.start.line,
              startCharacter: diagnostic.range.start.character,
              endLine: diagnostic.range.end.line,
              endCharacter: diagnostic.range.end.character,
              severity: _severity(diagnostic.severity),
              message:
                  diagnostic.message.asString ??
                  diagnostic.message.asMarkupContent?.value ??
                  'Language server diagnostic',
              code:
                  diagnostic.code?.asString ??
                  diagnostic.code?.asInt?.toString(),
              source: diagnostic.source ?? 'dart',
            ),
        ],
      ),
    );
  }

  void _emit(EditorLanguageEvent event) {
    if (!_disposed) _events.add(event);
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    for (final document in _documents.values) {
      document.changeTimer?.cancel();
    }
    _documents.clear();

    final client = _client;
    if (client != null) {
      try {
        await client.server.general.shutdown(
          timeout: const Duration(seconds: 1),
        );
        client.server.general.exit();
      } on Object {
        // The process may already have exited; transport cleanup still runs.
      }
      await client.close();
    }
    _process?.kill();
    await _stderrSubscription?.cancel();
    await _events.close();
  }
}

TextDiagnosticSeverity _severity(DiagnosticSeverity? severity) {
  return switch (severity) {
    DiagnosticSeverity.error => TextDiagnosticSeverity.error,
    DiagnosticSeverity.warning => TextDiagnosticSeverity.warning,
    DiagnosticSeverity.information => TextDiagnosticSeverity.info,
    DiagnosticSeverity.hint || null => TextDiagnosticSeverity.hint,
  };
}

EditorCompletionItem _toEditorCompletion(
  TextDocument document,
  int cursorOffset,
  CompletionItem item,
) {
  final edit = _completionEdit(item);
  final sourceText = edit?.newText ?? item.insertText ?? item.label;
  final insertText = item.insertTextFormat == InsertTextFormat.snippet
      ? parseSnippet(sourceText).text
      : sourceText;
  final range = edit?.range;
  final replacementStart = range == null
      ? _identifierReplacementStart(document, cursorOffset)
      : editorOffsetForLanguagePosition(
          document,
          range.start.line,
          range.start.character,
        );
  final replacementEnd = range == null
      ? cursorOffset
      : editorOffsetForLanguagePosition(
          document,
          range.end.line,
          range.end.character,
          roundUp: true,
        );
  return EditorCompletionItem(
    label: item.label,
    insertText: insertText,
    kind: _completionKind(item.kind),
    detail: item.detail ?? '',
    documentation:
        item.documentation?.asString ??
        item.documentation?.asMarkupContent?.value ??
        '',
    filterText: item.filterText,
    sortText: item.sortText,
    replacementStart: replacementStart,
    replacementEnd: replacementEnd,
  );
}

({String newText, Range range})? _completionEdit(CompletionItem item) {
  final textEdit = item.textEdit?.asTextEdit;
  if (textEdit != null) {
    return (newText: textEdit.newText, range: textEdit.range);
  }
  final insertReplaceEdit = item.textEdit?.asInsertReplaceEdit;
  if (insertReplaceEdit != null) {
    return (
      newText: insertReplaceEdit.newText,
      range: insertReplaceEdit.replace,
    );
  }
  return null;
}

int _identifierReplacementStart(TextDocument document, int cursorOffset) {
  final position = document.positionForOffset(cursorOffset);
  final graphemes = document.lineGraphemesAt(position.line);
  var column = position.column;
  while (column > 0 && _isIdentifierGrapheme(graphemes[column - 1])) {
    column--;
  }
  return document.lineStartOffset(position.line) + column;
}

bool _isIdentifierGrapheme(String grapheme) =>
    RegExp(r'^[A-Za-z0-9_$]$').hasMatch(grapheme);

EditorCompletionKind _completionKind(CompletionItemKind? kind) {
  return switch (kind) {
    CompletionItemKind.method => EditorCompletionKind.method,
    CompletionItemKind.function => EditorCompletionKind.function,
    CompletionItemKind.constructor => EditorCompletionKind.constructor,
    CompletionItemKind.field => EditorCompletionKind.field,
    CompletionItemKind.variable => EditorCompletionKind.variable,
    CompletionItemKind.class$ ||
    CompletionItemKind.interface$ ||
    CompletionItemKind.enum$ ||
    CompletionItemKind.struct ||
    CompletionItemKind.typeParameter => EditorCompletionKind.type,
    CompletionItemKind.module => EditorCompletionKind.module,
    CompletionItemKind.property => EditorCompletionKind.property,
    CompletionItemKind.keyword => EditorCompletionKind.keyword,
    CompletionItemKind.snippet => EditorCompletionKind.snippet,
    CompletionItemKind.file ||
    CompletionItemKind.folder => EditorCompletionKind.file,
    _ => EditorCompletionKind.text,
  };
}

String _hoverContents(Object value) {
  return switch (value) {
    final String text => text,
    {'kind': _, 'value': final String text} => text,
    {'language': final String language, 'value': final String text} =>
      '```$language\n$text\n```',
    final List<Object?> values =>
      values
          .whereType<Object>()
          .map(_hoverContents)
          .where((part) => part.isNotEmpty)
          .join('\n\n'),
    _ => '',
  };
}

final class _DartDocument {
  _DartDocument({required this.path, required this.text})
    : uri = Uri.file(path).toString();

  final String path;
  final String uri;
  String text;
  int version = 1;
  int lastSentVersion = 0;
  bool opened = false;
  Timer? changeTimer;
  Future<void>? opening;
}
