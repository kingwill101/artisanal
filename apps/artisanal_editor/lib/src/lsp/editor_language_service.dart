import 'package:artisanal/editor_core.dart'
    show
        EditorCompletionRequest,
        EditorCompletionResult,
        TextDiagnosticSeverity,
        TextDocument,
        TextPosition,
        TextPositionDiagnosticRange;

/// An LSP position expressed as a zero-based line and UTF-16 character.
final class EditorLanguagePosition {
  const EditorLanguagePosition({required this.line, required this.character});

  final int line;
  final int character;
}

/// Hover documentation returned by a language service.
final class EditorLanguageHover {
  const EditorLanguageHover({
    required this.contents,
    this.startOffset,
    this.endOffset,
  });

  /// Markdown-formatted hover contents.
  final String contents;

  /// Optional grapheme range associated with the hovered symbol.
  final int? startOffset;
  final int? endOffset;
}

/// A diagnostic reported by a language server.
///
/// LSP character offsets are UTF-16 code units. They are kept at this
/// application boundary until [toEditorDiagnostics] converts them to the
/// grapheme columns used by Artisanal's editor.
final class EditorLanguageDiagnostic {
  const EditorLanguageDiagnostic({
    required this.startLine,
    required this.startCharacter,
    required this.endLine,
    required this.endCharacter,
    required this.severity,
    required this.message,
    this.code,
    this.source,
  });

  final int startLine;
  final int startCharacter;
  final int endLine;
  final int endCharacter;
  final TextDiagnosticSeverity severity;
  final String message;
  final String? code;
  final String? source;
}

/// An event emitted by an editor language service.
sealed class EditorLanguageEvent {
  const EditorLanguageEvent();
}

/// A new complete diagnostic set for one document.
final class EditorLanguageDiagnostics extends EditorLanguageEvent {
  const EditorLanguageDiagnostics({
    required this.uri,
    required this.diagnostics,
    this.version,
  });

  final String uri;
  final List<EditorLanguageDiagnostic> diagnostics;
  final int? version;
}

/// A lifecycle or log message suitable for the editor Output panel.
final class EditorLanguageStatus extends EditorLanguageEvent {
  const EditorLanguageStatus(this.message, {this.ready});

  final String message;
  final bool? ready;
}

/// Product-owned bridge between editor buffers and language servers.
abstract interface class EditorLanguageService {
  /// Language service lifecycle, diagnostics, and log events.
  Stream<EditorLanguageEvent> get events;

  /// Whether this service owns documents with [languageId].
  bool supports(String languageId);

  /// Starts synchronizing an open document.
  void openDocument({
    required String path,
    required String languageId,
    required String text,
  });

  /// Publishes the latest full document text.
  void changeDocument({required String path, required String text});

  /// Stops synchronizing a document.
  void closeDocument(String path);

  /// Notifies the server that a document was saved.
  void saveDocument({required String path, required String text});

  /// Requests completions for an open document.
  Future<EditorCompletionResult> provideCompletions({
    required String path,
    required EditorCompletionRequest request,
  });

  /// Requests hover documentation at an Artisanal grapheme offset.
  Future<EditorLanguageHover?> provideHover({
    required String path,
    required String documentText,
    required int cursorOffset,
  });

  /// Stops all language-server resources.
  Future<void> dispose();
}

/// Converts LSP UTF-16 diagnostic ranges to Artisanal grapheme ranges.
List<TextPositionDiagnosticRange> toEditorDiagnostics(
  TextDocument document,
  Iterable<EditorLanguageDiagnostic> diagnostics,
) {
  return [
    for (final diagnostic in diagnostics)
      TextPositionDiagnosticRange(
        startLine: diagnostic.startLine,
        startColumn: lspUtf16ToGraphemeColumn(
          document,
          diagnostic.startLine,
          diagnostic.startCharacter,
          roundUp: false,
        ),
        endLine: diagnostic.endLine,
        endColumn: lspUtf16ToGraphemeColumn(
          document,
          diagnostic.endLine,
          diagnostic.endCharacter,
          roundUp: true,
        ),
        severity: diagnostic.severity,
        code: diagnostic.code,
        message: diagnostic.message,
        source: diagnostic.source,
      ),
  ];
}

/// Converts an Artisanal grapheme offset into an LSP UTF-16 position.
EditorLanguagePosition toEditorLanguagePosition(
  TextDocument document,
  int offset,
) {
  final position = document.positionForOffset(offset);
  final graphemes = document.lineGraphemesAt(position.line);
  var character = 0;
  for (var column = 0; column < position.column; column++) {
    character += graphemes[column].length;
  }
  return EditorLanguagePosition(line: position.line, character: character);
}

/// Converts an LSP UTF-16 position into an Artisanal grapheme offset.
int editorOffsetForLanguagePosition(
  TextDocument document,
  int line,
  int character, {
  bool roundUp = false,
}) {
  final lineIndex = line.clamp(0, document.lineCount - 1);
  return document.offsetForPosition(
    TextPosition(
      line: lineIndex,
      column: lspUtf16ToGraphemeColumn(
        document,
        lineIndex,
        character,
        roundUp: roundUp,
      ),
    ),
  );
}

/// Converts a UTF-16 character offset to a grapheme column on [line].
int lspUtf16ToGraphemeColumn(
  TextDocument document,
  int line,
  int character, {
  required bool roundUp,
}) {
  final lineIndex = line.clamp(0, document.lineCount - 1);
  final target = character.clamp(0, document.lineAt(lineIndex).length);
  var utf16Offset = 0;
  final graphemes = document.lineGraphemesAt(lineIndex);
  for (var column = 0; column < graphemes.length; column++) {
    final nextOffset = utf16Offset + graphemes[column].length;
    if (target < nextOffset) {
      return roundUp ? column + 1 : column;
    }
    if (target == nextOffset) {
      return column + 1;
    }
    utf16Offset = nextOffset;
  }
  return graphemes.length;
}
