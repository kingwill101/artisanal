library;

import 'text_change.dart';
import 'text_decorations.dart';
import 'text_document.dart';

final class TextSyntaxBuildResult<State> {
  const TextSyntaxBuildResult({required this.decorations, this.state})
    : patch = null;

  const TextSyntaxBuildResult.patch({required this.patch, this.state})
    : decorations = const <TextDecorationRange>[];

  final List<TextDecorationRange> decorations;
  final TextSyntaxDecorationPatch? patch;
  final State? state;
}

final class TextSyntaxSnapshot<State> {
  TextSyntaxSnapshot({
    String? text,
    required this.decorations,
    required this.language,
    this.document,
    this.state,
    this.change,
  }) : _text = text;

  String get text => _text ??= document?.text ?? '';

  String? _text;
  final List<TextDecorationRange> decorations;
  final String? language;
  final TextDocument? document;
  final State? state;
  final TextDocumentChange? change;
}

abstract class TextSyntaxProvider<State> {
  TextSyntaxBuildResult<State> build(
    String text, {
    TextDocument? document,
    String? language,
    TextSyntaxSnapshot<State>? previous,
    TextDocumentChange? change,
  });

  TextSyntaxBuildResult<State> buildDocument(
    TextDocument document, {
    String? language,
    TextSyntaxSnapshot<State>? previous,
    TextDocumentChange? change,
  }) {
    return build(
      document.textBetweenLines(startLine: 0, endLine: document.lineCount),
      document: document,
      language: language,
      previous: previous,
      change: change,
    );
  }
}

/// Asynchronous syntax provider for parsers that run outside the render loop.
abstract class AsyncTextSyntaxProvider<State> {
  /// Builds decorations for [document], optionally using incremental context.
  Future<TextSyntaxBuildResult<State>> buildDocument(
    TextDocument document, {
    String? language,
    TextSyntaxSnapshot<State>? previous,
    TextDocumentChange? change,
  });
}

final class TextSyntaxLineWindow {
  const TextSyntaxLineWindow({required this.startLine, required this.endLine});

  final int startLine;
  final int endLine;

  bool get isEmpty => startLine >= endLine;

  int startOffsetIn(TextDocument document) =>
      document.lineStartOffset(startLine);

  int endOffsetIn(TextDocument document) => document.lineStartOffset(endLine);
}

final class TextSyntaxChangeWindow {
  const TextSyntaxChangeWindow({
    required this.previousLines,
    required this.nextLines,
  });

  final TextSyntaxLineWindow previousLines;
  final TextSyntaxLineWindow nextLines;
}

final class TextSyntaxDecorationPatch {
  TextSyntaxDecorationPatch({
    required this.previousStartOffset,
    required this.previousEndOffset,
    required this.nextStartOffset,
    required this.nextEndOffset,
    required List<TextDecorationRange> decorations,
  }) : decorations = List<TextDecorationRange>.unmodifiable(decorations);

  factory TextSyntaxDecorationPatch.forChangeWindow({
    required TextDocument previousDocument,
    required TextDocument nextDocument,
    required TextSyntaxChangeWindow window,
    required List<TextDecorationRange> decorations,
  }) {
    return TextSyntaxDecorationPatch(
      previousStartOffset: window.previousLines.startOffsetIn(previousDocument),
      previousEndOffset: window.previousLines.endOffsetIn(previousDocument),
      nextStartOffset: window.nextLines.startOffsetIn(nextDocument),
      nextEndOffset: window.nextLines.endOffsetIn(nextDocument),
      decorations: decorations,
    );
  }

  final int previousStartOffset;
  final int previousEndOffset;
  final int nextStartOffset;
  final int nextEndOffset;
  final List<TextDecorationRange> decorations;

  int get offsetDelta =>
      (nextEndOffset - nextStartOffset) -
      (previousEndOffset - previousStartOffset);
}

TextSyntaxChangeWindow textSyntaxChangeWindow({
  required TextDocument previousDocument,
  required TextDocument nextDocument,
  required TextDocumentChange change,
  int lookBehindLines = 0,
  int lookAheadLines = 0,
}) {
  final previousStartLine = (change.startPosition.line - lookBehindLines).clamp(
    0,
    previousDocument.lineCount,
  );
  final previousEndLine = (change.oldEndPosition.line + lookAheadLines + 1)
      .clamp(previousStartLine, previousDocument.lineCount);
  final nextStartLine = (change.startPosition.line - lookBehindLines).clamp(
    0,
    nextDocument.lineCount,
  );
  final nextEndLine = (change.newEndPosition.line + lookAheadLines + 1).clamp(
    nextStartLine,
    nextDocument.lineCount,
  );
  return TextSyntaxChangeWindow(
    previousLines: TextSyntaxLineWindow(
      startLine: previousStartLine,
      endLine: previousEndLine,
    ),
    nextLines: TextSyntaxLineWindow(
      startLine: nextStartLine,
      endLine: nextEndLine,
    ),
  );
}

List<TextDecorationRange> mergeTextSyntaxDecorationPatch(
  List<TextDecorationRange> previousDecorations,
  TextSyntaxDecorationPatch patch,
) {
  final merged =
      <TextDecorationRange>[
        for (final decoration in previousDecorations) ...[
          if (decoration.endOffset <= patch.previousStartOffset)
            decoration
          else if (decoration.startOffset >= patch.previousEndOffset)
            TextDecorationRange(
              startOffset: decoration.startOffset + patch.offsetDelta,
              endOffset: decoration.endOffset + patch.offsetDelta,
              styleKey: decoration.styleKey,
            )
          else ...[
            if (decoration.startOffset < patch.previousStartOffset)
              TextDecorationRange(
                startOffset: decoration.startOffset,
                endOffset: patch.previousStartOffset,
                styleKey: decoration.styleKey,
              ),
            if (decoration.endOffset > patch.previousEndOffset)
              TextDecorationRange(
                startOffset: patch.nextEndOffset,
                endOffset: decoration.endOffset + patch.offsetDelta,
                styleKey: decoration.styleKey,
              ),
          ],
        ],
        ...patch.decorations,
      ]..sort((a, b) {
        final startComparison = a.startOffset.compareTo(b.startOffset);
        if (startComparison != 0) {
          return startComparison;
        }
        final endComparison = a.endOffset.compareTo(b.endOffset);
        if (endComparison != 0) {
          return endComparison;
        }
        return a.styleKey.compareTo(b.styleKey);
      });
  return List<TextDecorationRange>.unmodifiable(merged);
}

final class TextSyntaxSession<State> {
  TextSyntaxSession({required this.provider, this.language});

  final TextSyntaxProvider<State> provider;
  String? language;

  TextSyntaxSnapshot<State>? _snapshot;

  TextSyntaxSnapshot<State>? get snapshot => _snapshot;

  TextSyntaxSnapshot<State> sync(
    String text, {
    String? language,
    bool force = false,
    TextDocumentChange? change,
  }) {
    final resolvedLanguage = language ?? this.language;
    final previous = _snapshot;
    if (!force &&
        previous != null &&
        previous.text == text &&
        previous.language == resolvedLanguage &&
        (change == null || change.isNoop)) {
      return previous;
    }

    final resolvedChange =
        !force && previous != null && previous.language == resolvedLanguage
        ? (change ?? computeTextDocumentChange(previous.text, text))
        : null;
    final result = provider.build(
      text,
      document: null,
      language: resolvedLanguage,
      previous: resolvedChange == null ? null : previous,
      change: resolvedChange,
    );
    final decorations = result.patch != null && previous != null
        ? mergeTextSyntaxDecorationPatch(previous.decorations, result.patch!)
        : result.decorations;
    final snapshot = TextSyntaxSnapshot<State>(
      text: text,
      decorations: List<TextDecorationRange>.unmodifiable(decorations),
      language: resolvedLanguage,
      document: null,
      state: result.state,
      change: resolvedChange,
    );
    _snapshot = snapshot;
    return snapshot;
  }

  TextSyntaxSnapshot<State> syncDocument(
    TextDocument document, {
    String? language,
    bool force = false,
    TextDocumentChange? change,
  }) {
    final resolvedLanguage = language ?? this.language;
    final previous = _snapshot;
    if (!force &&
        previous != null &&
        previous.language == resolvedLanguage &&
        previous.document != null &&
        previous.document!.storageIdentity == document.storageIdentity &&
        previous.document!.revision == document.revision &&
        (change == null || change.isNoop)) {
      return previous;
    }

    final resolvedChange =
        !force && previous != null && previous.language == resolvedLanguage
        ? change ??
              (previous.document != null
                  ? computeTextDocumentChangeForDocuments(
                      previousDocument: previous.document!,
                      nextDocument: document,
                    )
                  : computeTextDocumentChange(
                      previous.text,
                      document.textBetweenLines(
                        startLine: 0,
                        endLine: document.lineCount,
                      ),
                    ))
        : null;
    final result = provider.buildDocument(
      document,
      language: resolvedLanguage,
      previous: resolvedChange == null ? null : previous,
      change: resolvedChange,
    );
    final decorations = result.patch != null && previous != null
        ? mergeTextSyntaxDecorationPatch(previous.decorations, result.patch!)
        : result.decorations;
    final snapshot = TextSyntaxSnapshot<State>(
      decorations: List<TextDecorationRange>.unmodifiable(decorations),
      language: resolvedLanguage,
      document: document.copy(),
      state: result.state,
      change: resolvedChange,
    );
    _snapshot = snapshot;
    return snapshot;
  }

  void clear() {
    _snapshot = null;
  }
}

/// Coordinates asynchronous syntax builds and rejects stale responses.
///
/// A newer [request] or [cancel] invalidates every outstanding build. Providers
/// do not need cancellation support: late results are simply not published.
final class AsyncTextSyntaxSession<State> {
  AsyncTextSyntaxSession({required this.provider, this.language});

  /// Provider used to build syntax snapshots.
  final AsyncTextSyntaxProvider<State> provider;

  /// Default language passed to the provider.
  String? language;

  int _generation = 0;
  TextSyntaxSnapshot<State>? _snapshot;

  /// Most recently accepted snapshot.
  TextSyntaxSnapshot<State>? get snapshot => _snapshot;

  /// Requests a syntax build, returning `null` when its result became stale.
  Future<TextSyntaxSnapshot<State>?> request(
    TextDocument document, {
    String? language,
    TextDocumentChange? change,
    bool force = false,
  }) async {
    final generation = ++_generation;
    final resolvedLanguage = language ?? this.language;
    final previous = _snapshot;
    if (!force &&
        previous?.document == document &&
        previous?.language == resolvedLanguage &&
        (change == null || change.isNoop)) {
      return previous;
    }
    final incrementalPrevious = !force && previous?.language == resolvedLanguage
        ? previous
        : null;
    final result = await provider.buildDocument(
      document,
      language: resolvedLanguage,
      previous: incrementalPrevious,
      change: incrementalPrevious == null ? null : change,
    );
    if (generation != _generation) return null;
    final decorations = result.patch != null && incrementalPrevious != null
        ? mergeTextSyntaxDecorationPatch(
            incrementalPrevious.decorations,
            result.patch!,
          )
        : result.decorations;
    final snapshot = TextSyntaxSnapshot<State>(
      document: document,
      decorations: List<TextDecorationRange>.unmodifiable(decorations),
      language: resolvedLanguage,
      state: result.state,
      change: change,
    );
    _snapshot = snapshot;
    return snapshot;
  }

  /// Invalidates every outstanding request without clearing accepted syntax.
  void cancel() {
    _generation++;
  }

  /// Clears accepted syntax and invalidates every outstanding request.
  void reset() {
    cancel();
    _snapshot = null;
  }
}
