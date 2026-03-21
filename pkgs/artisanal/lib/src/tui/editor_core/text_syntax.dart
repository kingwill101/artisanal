library;

import 'text_change.dart';
import 'text_decorations.dart';

final class TextSyntaxBuildResult<State> {
  const TextSyntaxBuildResult({
    required this.decorations,
    this.state,
  });

  final List<TextDecorationRange> decorations;
  final State? state;
}

final class TextSyntaxSnapshot<State> {
  const TextSyntaxSnapshot({
    required this.text,
    required this.decorations,
    required this.language,
    this.state,
    this.change,
  });

  final String text;
  final List<TextDecorationRange> decorations;
  final String? language;
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
  TextSyntaxSession({
    required this.provider,
    this.language,
  });

  final TextSyntaxProvider<State> provider;
  String? language;

  TextSyntaxSnapshot<State>? _snapshot;

  TextSyntaxSnapshot<State>? get snapshot => _snapshot;

  TextSyntaxSnapshot<State> sync(
    String text, {
    String? language,
    bool force = false,
  }) {
    final resolvedLanguage = language ?? this.language;
    final previous = _snapshot;
    if (!force &&
        previous != null &&
        previous.text == text &&
        previous.language == resolvedLanguage) {
      return previous;
    }

    final change = !force &&
            previous != null &&
            previous.language == resolvedLanguage
        ? computeTextDocumentChange(previous.text, text)
        : null;
    final result = provider.build(
      text,
      language: resolvedLanguage,
      previous: change == null ? null : previous,
      change: change,
    );
    final snapshot = TextSyntaxSnapshot<State>(
      text: text,
      decorations: List<TextDecorationRange>.unmodifiable(result.decorations),
      language: resolvedLanguage,
      state: result.state,
      change: change,
    );
    _snapshot = snapshot;
    return snapshot;
  }

  void clear() {
    _snapshot = null;
  }
}
