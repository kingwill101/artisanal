import 'dart:async';

import 'package:artisanal/editor_core.dart'
    show
        EditorCompletionProvider,
        EditorCompletionRequest,
        EditorCompletionResult,
        EditorCommandDispatchResult,
        TextDecorationRange,
        TextDiagnosticSeverity,
        TextDocument,
        TextPatternDiagnosticRule,
        TextPositionDiagnosticRange;
import 'package:artisanal/runtime.dart' show Cmd;
import 'package:artisanal_widgets/editors.dart'
    show TextAreaController, TextPositionDiagnosticsSource;

import '../lsp/editor_language_service.dart';
import '../modal/modal_editing.dart';
import '../syntax/editor_syntax_highlighter.dart';
import 'editor_file_repository.dart';

const editorDiagnosticRules = <TextPatternDiagnosticRule>[
  TextPatternDiagnosticRule(
    pattern: 'FIXME',
    severity: TextDiagnosticSeverity.error,
    code: 'FIXME',
    message: 'Resolve this FIXME before shipping.',
    source: 'artisanal-editor',
    wholeWord: true,
  ),
  TextPatternDiagnosticRule(
    pattern: 'TODO',
    severity: TextDiagnosticSeverity.warning,
    code: 'TODO',
    message: 'Tracked TODO item.',
    source: 'artisanal-editor',
    wholeWord: true,
  ),
  TextPatternDiagnosticRule(
    pattern: 'HACK',
    severity: TextDiagnosticSeverity.info,
    code: 'HACK',
    message: 'Review this workaround.',
    source: 'artisanal-editor',
    wholeWord: true,
  ),
];

const _treeSitterDecorationLayer = 'artisanal-editor.tree-sitter';
const _treeSitterDecorationPriority = 110;

/// Text controller that exposes app-level named-command dispatch.
///
/// Artisanal's model already owns command execution. The standalone editor
/// subclasses the widget controller only to publish those model changes to
/// syntax and diagnostic bindings.
final class EditorTextController extends TextAreaController {
  EditorTextController({required super.text});

  EditorCommandDispatchResult dispatch(String commandId) {
    final result = model.executeCommand(commandId);
    notifyListeners();
    return result;
  }

  /// Requests completions through Artisanal's existing editor session.
  Cmd requestCompletions(EditorCompletionProvider provider) {
    return model.requestCompletions(provider);
  }

  /// Moves the active completion and publishes the selection change.
  void moveCompletion(int delta) {
    if (model.moveCompletionSelection(delta)) notifyListeners();
  }

  /// Accepts the active completion as one editor transaction.
  bool acceptCompletion() {
    final accepted = model.acceptCompletion();
    if (accepted) notifyListeners();
    return accepted;
  }

  /// Dismisses the current completion session.
  void cancelCompletions() {
    model.cancelCompletions();
    notifyListeners();
  }
}

final class _LanguageCompletionProvider implements EditorCompletionProvider {
  const _LanguageCompletionProvider({
    required this.path,
    required this.service,
  });

  final String path;
  final EditorLanguageService service;

  @override
  Future<EditorCompletionResult> provide(EditorCompletionRequest request) {
    return service.provideCompletions(path: path, request: request);
  }
}

final class _EditorDiagnostics {
  _EditorDiagnostics(this._controller)
    : _patterns = TextPositionDiagnosticsSource.patternRules(
        text: _controller,
        rules: editorDiagnosticRules,
      ) {
    _patterns.addListener(_sync);
    _sync();
  }

  final EditorTextController _controller;
  final TextPositionDiagnosticsSource _patterns;
  List<TextPositionDiagnosticRange> _language = const [];

  void setLanguage(Iterable<TextPositionDiagnosticRange> diagnostics) {
    _language = diagnostics.toList(growable: false);
    _sync();
  }

  void _sync() {
    final combined = [..._patterns.value, ..._language];
    if (combined.isEmpty) {
      _controller.clearDiagnostics();
    } else {
      _controller.setDiagnosticsFromPositions(combined);
    }
  }

  void dispose() {
    _patterns
      ..removeListener(_sync)
      ..dispose();
  }
}

/// One open editor buffer and its product-specific mode/tooling state.
final class EditorBuffer {
  EditorBuffer({
    required this.file,
    required this.controller,
    required this.completionProvider,
    EditorSyntaxHighlighter? syntaxHighlighter,
    required void Function(EditorBuffer buffer) onTextChanged,
  }) : _onTextChanged = onTextChanged,
       _syntaxHighlighter = syntaxHighlighter,
       _diagnostics = _EditorDiagnostics(controller),
       _lastText = controller.text {
    controller.addListener(_handleControllerChanged);
    // Supplying the file contents to TextAreaController is a replacement
    // operation, so discard that bootstrap snapshot before the user edits.
    // Otherwise the first undo restores the controller's empty default.
    controller.clearHistory();
    controller.model.markSaved();
    _refreshSyntax(immediately: true);
  }

  final EditorFileEntry file;
  final EditorTextController controller;
  final EditorCompletionProvider? completionProvider;
  final ModalEditingController modal = ModalEditingController();
  final void Function(EditorBuffer buffer) _onTextChanged;
  final EditorSyntaxHighlighter? _syntaxHighlighter;
  final _EditorDiagnostics _diagnostics;
  String _lastText;
  int _syntaxGeneration = 0;
  Timer? _syntaxDebounce;
  bool _disposed = false;

  bool get isDirty => controller.model.isDirty;

  void markSaved() => controller.model.markSaved();

  void setLanguageDiagnostics(
    Iterable<TextPositionDiagnosticRange> diagnostics,
  ) {
    _diagnostics.setLanguage(diagnostics);
  }

  void _handleControllerChanged() {
    final text = controller.text;
    if (text == _lastText) return;
    _lastText = text;
    _diagnostics.setLanguage(const []);
    _refreshSyntax();
    _onTextChanged(this);
  }

  void _refreshSyntax({bool immediately = false}) {
    final highlighter = _syntaxHighlighter;
    if (highlighter == null || !highlighter.supports(file.language)) return;
    final generation = ++_syntaxGeneration;
    final document = controller.document.copy();
    _syntaxDebounce?.cancel();
    if (!immediately) {
      _syntaxDebounce = Timer(
        const Duration(milliseconds: 120),
        () => _runSyntaxHighlight(highlighter, document, generation),
      );
      return;
    }
    _runSyntaxHighlight(highlighter, document, generation);
  }

  void _runSyntaxHighlight(
    EditorSyntaxHighlighter highlighter,
    TextDocument document,
    int generation,
  ) {
    unawaited(
      highlighter
          .highlight(languageId: file.language, document: document)
          .then((List<TextDecorationRange> decorations) {
            if (_disposed || generation != _syntaxGeneration) return;
            controller.setDecorationLayer(
              _treeSitterDecorationLayer,
              decorations,
              priority: _treeSitterDecorationPriority,
            );
          })
          .catchError((Object _) {
            if (_disposed || generation != _syntaxGeneration) return;
            controller.clearDecorationLayer(_treeSitterDecorationLayer);
          }),
    );
  }

  void dispose() {
    _disposed = true;
    _syntaxGeneration++;
    _syntaxDebounce?.cancel();
    controller.removeListener(_handleControllerChanged);
    _diagnostics.dispose();
    controller.dispose();
  }
}

/// An application-level workspace update for the widget event loop.
final class EditorWorkspaceEvent {
  const EditorWorkspaceEvent({this.message});

  final String? message;
}

/// Open buffers, active selection, and filesystem operations for one project.
final class EditorWorkspace {
  EditorWorkspace({
    required this.root,
    required this.files,
    required EditorFileRepository repository,
    EditorLanguageService? languageService,
    EditorSyntaxHighlighter? syntaxHighlighter,
  }) : _repository = repository,
       _languageService = languageService,
       _syntaxHighlighter = syntaxHighlighter {
    _languageSubscription = languageService?.events.listen(
      _handleLanguageEvent,
    );
  }

  final String root;
  final List<EditorFileEntry> files;
  final EditorFileRepository _repository;
  final EditorLanguageService? _languageService;
  final EditorSyntaxHighlighter? _syntaxHighlighter;
  final Map<String, EditorBuffer> _buffers = {};
  final StreamController<EditorWorkspaceEvent> _events =
      StreamController.broadcast(sync: true);
  final List<String> _output = [];
  StreamSubscription<EditorLanguageEvent>? _languageSubscription;
  String? _activePath;
  bool _disposed = false;
  bool _languageReady = false;

  List<EditorBuffer> get openBuffers => List.unmodifiable(_buffers.values);

  /// Workspace changes consumed by the Artisanal widget event loop.
  Stream<EditorWorkspaceEvent> get events => _events.stream;

  /// Recent language-service output, oldest first.
  List<String> get outputLines => List.unmodifiable(_output);

  /// Whether the configured language server completed its handshake.
  bool get languageReady => _languageReady;

  EditorBuffer? get activeBuffer =>
      _activePath == null ? null : _buffers[_activePath];

  Future<EditorBuffer> open(EditorFileEntry file) async {
    final existing = _buffers[file.path];
    if (existing != null) {
      _activePath = file.path;
      return existing;
    }

    final text = await _repository.read(file);
    final controller = EditorTextController(text: text);
    final languageService = _languageService;
    final buffer = EditorBuffer(
      file: file,
      controller: controller,
      completionProvider:
          languageService != null && languageService.supports(file.language)
          ? _LanguageCompletionProvider(
              path: file.path,
              service: languageService,
            )
          : null,
      syntaxHighlighter: _syntaxHighlighter,
      onTextChanged: _handleBufferTextChanged,
    );
    _buffers[file.path] = buffer;
    _activePath = file.path;
    _languageService?.openDocument(
      path: file.path,
      languageId: file.language,
      text: text,
    );
    return buffer;
  }

  void _handleBufferTextChanged(EditorBuffer buffer) {
    _languageService?.changeDocument(
      path: buffer.file.path,
      text: buffer.controller.text,
    );
    _emit();
  }

  void _handleLanguageEvent(EditorLanguageEvent event) {
    if (_disposed) return;
    switch (event) {
      case EditorLanguageDiagnostics(:final uri, :final diagnostics):
        final buffer = _bufferForUri(uri);
        if (buffer == null) return;
        buffer.setLanguageDiagnostics(
          toEditorDiagnostics(buffer.controller.document, diagnostics),
        );
        _emit();
      case EditorLanguageStatus(:final message, :final ready):
        if (ready != null) _languageReady = ready;
        _output.add(message);
        if (_output.length > 100) {
          _output.removeRange(0, _output.length - 100);
        }
        _emit(message);
    }
  }

  EditorBuffer? _bufferForUri(String uri) {
    for (final buffer in _buffers.values) {
      if (Uri.file(buffer.file.path).toString() == uri) return buffer;
    }
    return null;
  }

  void _emit([String? message]) {
    if (!_disposed) {
      _events.add(EditorWorkspaceEvent(message: message));
    }
  }

  void activate(EditorBuffer buffer) {
    if (_buffers.containsKey(buffer.file.path)) {
      _activePath = buffer.file.path;
    }
  }

  void activateNext({bool backwards = false}) {
    final buffers = openBuffers;
    if (buffers.length < 2) return;
    final current = buffers.indexOf(activeBuffer!);
    final delta = backwards ? -1 : 1;
    final next = (current + delta) % buffers.length;
    _activePath = buffers[next].file.path;
  }

  /// Requests hover documentation for [buffer]'s current cursor.
  Future<EditorLanguageHover?> requestHover(EditorBuffer buffer) {
    final languageService = _languageService;
    if (languageService == null ||
        !languageService.supports(buffer.file.language)) {
      return Future.value();
    }
    return languageService.provideHover(
      path: buffer.file.path,
      documentText: buffer.controller.text,
      cursorOffset: buffer.controller.model.cursorOffset,
    );
  }

  Future<void> saveActive() async {
    final buffer = activeBuffer;
    if (buffer == null) return;
    await save(buffer);
  }

  /// Persists [buffer] without changing the active buffer.
  Future<void> save(EditorBuffer buffer) async {
    if (!_buffers.containsKey(buffer.file.path)) return;
    final savedText = buffer.controller.text;
    await _repository.write(buffer.file, savedText);
    if (buffer.controller.text == savedText) {
      buffer.markSaved();
    }
    _languageService?.saveDocument(path: buffer.file.path, text: savedText);
  }

  void close(EditorBuffer buffer) {
    final index = openBuffers.indexOf(buffer);
    final removed = _buffers.remove(buffer.file.path);
    if (removed == null) return;
    _languageService?.closeDocument(buffer.file.path);
    removed.dispose();
    if (_activePath == buffer.file.path) {
      final remaining = openBuffers;
      _activePath = remaining.isEmpty
          ? null
          : remaining[index.clamp(0, remaining.length - 1)].file.path;
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final buffer in _buffers.values) {
      buffer.dispose();
    }
    _buffers.clear();
    unawaited(_languageSubscription?.cancel());
    unawaited(_languageService?.dispose());
    unawaited(_events.close());
  }
}
