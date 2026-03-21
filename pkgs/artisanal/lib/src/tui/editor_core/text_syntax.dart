library;

import 'text_change.dart';
import 'text_decorations.dart';
import 'text_document.dart';

final class TextSyntaxBuildResult<State> {
  const TextSyntaxBuildResult({required this.decorations, this.state});

  final List<TextDecorationRange> decorations;
  final State? state;
}

final class TextSyntaxSnapshot<State> {
  const TextSyntaxSnapshot({
    required this.text,
    required this.decorations,
    required this.language,
    this.document,
    this.state,
    this.change,
  });

  final String text;
  final List<TextDecorationRange> decorations;
  final String? language;
  final TextDocument? document;
  final State? state;
  final TextDocumentChange? change;
}

abstract interface class TextSyntaxProvider<State> {
  TextSyntaxBuildResult<State> build(
    String text, {
    String? language,
    TextSyntaxSnapshot<State>? previous,
    TextDocumentChange? change,
  });
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
      language: resolvedLanguage,
      previous: resolvedChange == null ? null : previous,
      change: resolvedChange,
    );
    final snapshot = TextSyntaxSnapshot<State>(
      text: text,
      decorations: List<TextDecorationRange>.unmodifiable(result.decorations),
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
    final text = document.text;
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
        ? change ??
              (previous.document != null
                  ? computeTextDocumentChangeForDocuments(
                      previousDocument: previous.document!,
                      nextDocument: document,
                    )
                  : computeTextDocumentChange(previous.text, text))
        : null;
    final result = provider.build(
      text,
      language: resolvedLanguage,
      previous: resolvedChange == null ? null : previous,
      change: resolvedChange,
    );
    final snapshot = TextSyntaxSnapshot<State>(
      text: text,
      decorations: List<TextDecorationRange>.unmodifiable(result.decorations),
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
