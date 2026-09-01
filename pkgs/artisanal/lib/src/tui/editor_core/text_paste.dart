library;

import 'dart:math' as math;

import 'package:ultraviolet/unicode.dart' as uni;

enum TextPasteMode { inline, chunked, collapsed }

final class TextPastePlan {
  const TextPastePlan({
    required this.mode,
    required this.lineCount,
    required this.runeCount,
  });

  final TextPasteMode mode;
  final int lineCount;
  final int runeCount;

  bool get collapse => mode == TextPasteMode.collapsed;
  bool get chunked => mode == TextPasteMode.chunked;
}

final class TextPasteChunk {
  const TextPasteChunk({
    required this.start,
    required this.end,
    required this.hasMore,
  });

  final int start;
  final int end;
  final bool hasMore;
}

final class TextPasteChunkStep {
  const TextPasteChunkStep({
    required this.runes,
    required this.start,
    required this.end,
    required this.totalRunes,
    this.nextSession,
  });

  final List<int> runes;
  final int start;
  final int end;
  final int totalRunes;
  final TextPasteSession? nextSession;

  bool get hasMore => nextSession != null;
}

final class TextPasteReference {
  const TextPasteReference({
    required this.uri,
    required this.content,
    required this.lineCount,
  });

  final String uri;
  final String content;
  final int lineCount;

  String get token => textCollapsedPasteToken(lineCount: lineCount);
}

final class TextPasteReferenceStore {
  final Map<String, String> _buffer = <String, String>{};
  int _nextRefId = 1;
  String? _lastRef;

  String? get lastRef => _lastRef;
  Map<String, String> get buffer => Map.unmodifiable(_buffer);

  TextPasteReference store(String content, {required int lineCount}) {
    final uri = 'paste://${_nextRefId++}';
    _buffer[uri] = content;
    _lastRef = uri;
    return TextPasteReference(uri: uri, content: content, lineCount: lineCount);
  }
}

final class TextPasteController {
  TextPasteController({TextPasteReferenceStore? references})
    : _references = references ?? TextPasteReferenceStore();

  final TextPasteReferenceStore _references;
  TextPasteSession? _pendingSession;

  String? get lastRef => _references.lastRef;
  Map<String, String> get buffer => _references.buffer;
  bool get hasPendingChunkedPaste => _pendingSession != null;

  TextPasteReference storeCollapsed(String content, {required int lineCount}) {
    return _references.store(content, lineCount: lineCount);
  }

  TextPasteChunkStep? startChunked(String content, {required int chunkSize}) {
    _pendingSession = TextPasteSession.fromText(content);
    return takeNextChunk(chunkSize: chunkSize);
  }

  TextPasteChunkStep? takeNextChunk({required int chunkSize}) {
    final session = _pendingSession;
    if (session == null) {
      return null;
    }

    final step = session.takeChunk(chunkSize);
    if (step == null) {
      _pendingSession = null;
      return null;
    }

    _pendingSession = step.nextSession;
    return step;
  }

  void clearPendingChunkedPaste() {
    _pendingSession = null;
  }
}

final class TextPasteSession {
  const TextPasteSession._({required this.runes, required this.offset});

  factory TextPasteSession.fromText(String content) {
    return TextPasteSession._(runes: uni.codePoints(content), offset: 0);
  }

  final List<int> runes;
  final int offset;

  int get totalRunes => runes.length;
  bool get isComplete => offset >= runes.length;

  TextPasteChunkStep? takeChunk(int chunkSize) {
    final chunk = nextTextPasteChunk(
      totalRunes: totalRunes,
      offset: offset,
      chunkSize: chunkSize,
    );
    if (chunk == null) {
      return null;
    }

    return TextPasteChunkStep(
      runes: runes.sublist(chunk.start, chunk.end),
      start: chunk.start,
      end: chunk.end,
      totalRunes: totalRunes,
      nextSession: chunk.hasMore
          ? TextPasteSession._(runes: runes, offset: chunk.end)
          : null,
    );
  }
}

int textCountLines(String text) {
  if (text.isEmpty) return 1;

  var lines = 1;
  for (var i = 0; i < text.length; i++) {
    if (text.codeUnitAt(i) == 10) {
      lines++;
    }
  }
  return lines;
}

String textCollapsedPasteToken({required int lineCount}) {
  return '[Pasted ~$lineCount lines]';
}

TextPastePlan planTextPaste(
  String content, {
  required bool collapseLargePaste,
  required int collapsedPasteMinChars,
  required int collapsedPasteMinLines,
  required int chunkThresholdRunes,
}) {
  final lineCount = textCountLines(content);
  final runeCount = uni.codePoints(content).length;
  final shouldCollapse =
      collapseLargePaste &&
      (content.length >= collapsedPasteMinChars ||
          lineCount >= collapsedPasteMinLines);

  return TextPastePlan(
    mode: shouldCollapse
        ? TextPasteMode.collapsed
        : runeCount >= chunkThresholdRunes
        ? TextPasteMode.chunked
        : TextPasteMode.inline,
    lineCount: lineCount,
    runeCount: runeCount,
  );
}

TextPasteChunk? nextTextPasteChunk({
  required int totalRunes,
  required int offset,
  required int chunkSize,
}) {
  if (offset >= totalRunes || chunkSize <= 0) {
    return null;
  }

  final end = math.min(totalRunes, offset + chunkSize);
  return TextPasteChunk(start: offset, end: end, hasMore: end < totalRunes);
}
