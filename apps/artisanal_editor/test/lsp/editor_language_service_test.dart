import 'dart:async';
import 'dart:io';

import 'package:artisanal/editor_core.dart'
    show
        EditorCompletionItem,
        EditorCompletionRequest,
        EditorCompletionResult,
        TextDiagnosticSeverity,
        TextDocument;
import 'package:artisanal_editor/src/lsp/editor_language_service.dart';
import 'package:artisanal_editor/src/workspace/editor_file_repository.dart';
import 'package:artisanal_editor/src/workspace/editor_workspace.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('converts UTF-16 positions to grapheme columns', () {
    final document = TextDocument(text: 'a😀e\u0301z');

    final diagnostics = toEditorDiagnostics(document, const [
      EditorLanguageDiagnostic(
        startLine: 0,
        startCharacter: 1,
        endLine: 0,
        endCharacter: 3,
        severity: TextDiagnosticSeverity.error,
        message: 'emoji',
      ),
      EditorLanguageDiagnostic(
        startLine: 0,
        startCharacter: 3,
        endLine: 0,
        endCharacter: 5,
        severity: TextDiagnosticSeverity.warning,
        message: 'combining character',
      ),
    ]);

    expect(diagnostics[0].startColumn, 1);
    expect(diagnostics[0].endColumn, 2);
    expect(diagnostics[1].startColumn, 2);
    expect(diagnostics[1].endColumn, 3);
  });

  test('rounds malformed positions inside a grapheme outward', () {
    final document = TextDocument(text: 'a😀z');

    final diagnostic = toEditorDiagnostics(document, const [
      EditorLanguageDiagnostic(
        startLine: 0,
        startCharacter: 2,
        endLine: 0,
        endCharacter: 2,
        severity: TextDiagnosticSeverity.hint,
        message: 'inside surrogate pair',
      ),
    ]).single;

    expect(diagnostic.startColumn, 1);
    expect(diagnostic.endColumn, 2);
  });

  test('converts between grapheme offsets and LSP UTF-16 positions', () {
    final document = TextDocument(text: 'a😀e\u0301z\nnext');

    final lsp = toEditorLanguagePosition(document, 3);
    expect(lsp.line, 0);
    expect(lsp.character, 5);
    expect(
      editorOffsetForLanguagePosition(document, lsp.line, lsp.character),
      3,
    );
  });

  test('workspace merges language and pattern diagnostics', () async {
    final sandbox = await Directory.systemTemp.createTemp('editor-lsp-');
    addTearDown(() async => sandbox.delete(recursive: true));
    final path = p.join(sandbox.path, 'main.dart');
    await File(path).writeAsString('// TODO\nvoid main() {}\n');
    const repository = EditorFileRepository();
    final files = await repository.discover(sandbox.path);
    final language = _FakeLanguageService();
    final workspace = EditorWorkspace(
      root: sandbox.path,
      files: files,
      repository: repository,
      languageService: language,
    );
    addTearDown(workspace.dispose);

    final buffer = await workspace.open(files.single);
    expect(language.openedPaths, [path]);
    expect(buffer.controller.diagnostics, hasLength(1));
    expect(buffer.completionProvider, isNotNull);

    final completion = await buffer.completionProvider!.provide(
      const EditorCompletionRequest(
        documentText: 'void main() {}',
        cursorOffset: 4,
        documentVersion: 1,
      ),
    );
    expect(completion.items.single.label, 'main');
    expect(language.completedPaths, [path]);

    language.emit(const EditorLanguageStatus('Dart LSP ready', ready: true));
    expect(workspace.languageReady, isTrue);
    expect(workspace.outputLines, contains('Dart LSP ready'));

    language.emit(
      EditorLanguageDiagnostics(
        uri: Uri.file(path).toString(),
        version: 1,
        diagnostics: const [
          EditorLanguageDiagnostic(
            startLine: 1,
            startCharacter: 5,
            endLine: 1,
            endCharacter: 9,
            severity: TextDiagnosticSeverity.error,
            message: 'Undefined name.',
            source: 'dart',
          ),
        ],
      ),
    );

    expect(buffer.controller.diagnostics, hasLength(2));
    expect(
      buffer.controller.diagnostics.map((item) => item.source),
      containsAll(['artisanal-editor', 'dart']),
    );

    buffer.controller.insertText('// changed\n');
    expect(language.changedPaths, [path]);
    expect(
      buffer.controller.diagnostics.every((item) => item.source != 'dart'),
      isTrue,
    );

    await workspace.saveActive();
    expect(language.savedPaths, [path]);
    workspace.close(buffer);
    expect(language.closedPaths, [path]);

    language.emit(const EditorLanguageStatus('Dart LSP stopped', ready: false));
    expect(workspace.languageReady, isFalse);
  });
}

final class _FakeLanguageService implements EditorLanguageService {
  final StreamController<EditorLanguageEvent> _events =
      StreamController.broadcast(sync: true);
  final List<String> openedPaths = [];
  final List<String> changedPaths = [];
  final List<String> savedPaths = [];
  final List<String> closedPaths = [];
  final List<String> completedPaths = [];

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
    if (supports(languageId)) openedPaths.add(path);
  }

  @override
  void changeDocument({required String path, required String text}) {
    changedPaths.add(path);
  }

  @override
  void saveDocument({required String path, required String text}) {
    savedPaths.add(path);
  }

  @override
  void closeDocument(String path) {
    closedPaths.add(path);
  }

  @override
  Future<EditorCompletionResult> provideCompletions({
    required String path,
    required EditorCompletionRequest request,
  }) async {
    completedPaths.add(path);
    return const EditorCompletionResult(
      items: [EditorCompletionItem(label: 'main', insertText: 'main')],
    );
  }

  @override
  Future<EditorLanguageHover?> provideHover({
    required String path,
    required String documentText,
    required int cursorOffset,
  }) async {
    return const EditorLanguageHover(contents: 'Fake hover');
  }

  void emit(EditorLanguageEvent event) => _events.add(event);

  @override
  Future<void> dispose() => _events.close();
}
