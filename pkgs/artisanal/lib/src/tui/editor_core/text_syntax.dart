library;

import 'package:characters/characters.dart';

import 'editor_state.dart';
import 'text_decorations.dart';
import 'text_document.dart';

final class TextDocumentChange {
  const TextDocumentChange({
    required this.startOffset,
    required this.oldEndOffset,
    required this.newEndOffset,
    required this.startPosition,
    required this.oldEndPosition,
    required this.newEndPosition,
  });

  final int startOffset;
  final int oldEndOffset;
  final int newEndOffset;
  final TextPosition startPosition;
  final TextPosition oldEndPosition;
  final TextPosition newEndPosition;

  int get deletedLength => oldEndOffset - startOffset;
  int get insertedLength => newEndOffset - startOffset;
  bool get isNoop => deletedLength == 0 && insertedLength == 0;
}

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

TextDocumentChange computeTextDocumentChange(String previousText, String nextText) {
  final previous = previousText.characters.toList(growable: false);
  final next = nextText.characters.toList(growable: false);

  var prefix = 0;
  final maxPrefix = previous.length < next.length ? previous.length : next.length;
  while (prefix < maxPrefix && previous[prefix] == next[prefix]) {
    prefix += 1;
  }

  var previousSuffix = previous.length;
  var nextSuffix = next.length;
  while (previousSuffix > prefix &&
      nextSuffix > prefix &&
      previous[previousSuffix - 1] == next[nextSuffix - 1]) {
    previousSuffix -= 1;
    nextSuffix -= 1;
  }

  final previousDocument = TextDocument(text: previousText);
  final nextDocument = TextDocument(text: nextText);
  return TextDocumentChange(
    startOffset: prefix,
    oldEndOffset: previousSuffix,
    newEndOffset: nextSuffix,
    startPosition: previousDocument.positionForOffset(prefix),
    oldEndPosition: previousDocument.positionForOffset(previousSuffix),
    newEndPosition: nextDocument.positionForOffset(nextSuffix),
  );
}
