library;

import 'package:characters/characters.dart';

import 'editor_state.dart';
import 'text_document.dart';

const String textDefaultExtmarkType = 'default';

final class TextExtmark {
  const TextExtmark({
    required this.id,
    required this.type,
    required this.startOffset,
    required this.endOffset,
    this.virtual = false,
    this.styleKey,
    this.priority = 0,
    this.data,
  });

  final int id;
  final String type;
  final int startOffset;
  final int endOffset;
  final bool virtual;
  final String? styleKey;
  final int priority;
  final Object? data;

  int get length => endOffset - startOffset;
  bool get isEmpty => startOffset >= endOffset;

  bool containsOffset(int offset) {
    return offset >= startOffset && offset < endOffset;
  }

  TextExtmark normalized() {
    if (startOffset <= endOffset) {
      return this;
    }
    return TextExtmark(
      id: id,
      type: type,
      startOffset: endOffset,
      endOffset: startOffset,
      virtual: virtual,
      styleKey: styleKey,
      priority: priority,
      data: data,
    );
  }

  TextExtmark clamp(int maxLength) {
    final normalizedMark = normalized();
    return TextExtmark(
      id: id,
      type: type,
      startOffset: normalizedMark.startOffset.clamp(0, maxLength),
      endOffset: normalizedMark.endOffset.clamp(0, maxLength),
      virtual: virtual,
      styleKey: styleKey,
      priority: priority,
      data: data,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TextExtmark &&
        other.id == id &&
        other.type == type &&
        other.startOffset == startOffset &&
        other.endOffset == endOffset &&
        other.virtual == virtual &&
        other.styleKey == styleKey &&
        other.priority == priority &&
        other.data == data;
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    startOffset,
    endOffset,
    virtual,
    styleKey,
    priority,
    data,
  );

  @override
  String toString() {
    return 'TextExtmark('
        'id: $id, type: $type, startOffset: $startOffset, '
        'endOffset: $endOffset, virtual: $virtual, styleKey: $styleKey, '
        'priority: $priority, data: $data'
        ')';
  }
}

final class TextExtmarkOptions {
  const TextExtmarkOptions({
    required this.startOffset,
    required this.endOffset,
    this.type = textDefaultExtmarkType,
    this.virtual = false,
    this.styleKey,
    this.priority = 0,
    this.data,
  });

  final int startOffset;
  final int endOffset;
  final String type;
  final bool virtual;
  final String? styleKey;
  final int priority;
  final Object? data;
}

final class TextExtmarkPositionRange {
  const TextExtmarkPositionRange({required this.start, required this.end});

  final TextPosition start;
  final TextPosition end;

  @override
  bool operator ==(Object other) {
    return other is TextExtmarkPositionRange &&
        other.start == start &&
        other.end == end;
  }

  @override
  int get hashCode => Object.hash(start, end);
}

final class TextExtmarksController {
  final Map<int, TextExtmark> _extmarks = <int, TextExtmark>{};
  final Map<String, Set<int>> _extmarksByType = <String, Set<int>>{};
  int _nextId = 1;

  int create(TextExtmarkOptions options) {
    final id = _nextId++;
    final extmark = TextExtmark(
      id: id,
      type: options.type,
      startOffset: options.startOffset,
      endOffset: options.endOffset,
      virtual: options.virtual,
      styleKey: options.styleKey,
      priority: options.priority,
      data: options.data,
    ).normalized().clamp(1 << 30);

    _extmarks[id] = extmark;
    (_extmarksByType[extmark.type] ??= <int>{}).add(id);
    return id;
  }

  bool delete(int id) {
    final extmark = _extmarks.remove(id);
    if (extmark == null) {
      return false;
    }
    final ids = _extmarksByType[extmark.type];
    ids?.remove(id);
    if (ids != null && ids.isEmpty) {
      _extmarksByType.remove(extmark.type);
    }
    return true;
  }

  TextExtmark? get(int id) => _extmarks[id];

  List<TextExtmark> getAll() => _sorted(_extmarks.values);

  List<TextExtmark> getVirtual() {
    return _sorted(_extmarks.values.where((extmark) => extmark.virtual));
  }

  List<TextExtmark> getAtOffset(int offset) {
    return _sorted(
      _extmarks.values.where((extmark) => extmark.containsOffset(offset)),
    );
  }

  List<TextExtmark> getAllForType(String type) {
    final ids = _extmarksByType[type];
    if (ids == null || ids.isEmpty) {
      return const <TextExtmark>[];
    }
    return _sorted(ids.map((id) => _extmarks[id]).whereType<TextExtmark>());
  }

  void clear() {
    _extmarks.clear();
    _extmarksByType.clear();
  }

  void applyInsertion({required int offset, required String text}) {
    final insertOffset = offset.clamp(0, 1 << 30);
    final length = text.characters.length;
    if (length <= 0) {
      return;
    }

    for (final entry in _extmarks.entries.toList(growable: false)) {
      final extmark = entry.value;
      if (extmark.startOffset >= insertOffset) {
        _extmarks[entry.key] = TextExtmark(
          id: extmark.id,
          type: extmark.type,
          startOffset: extmark.startOffset + length,
          endOffset: extmark.endOffset + length,
          virtual: extmark.virtual,
          styleKey: extmark.styleKey,
          priority: extmark.priority,
          data: extmark.data,
        );
      } else if (extmark.endOffset > insertOffset) {
        _extmarks[entry.key] = TextExtmark(
          id: extmark.id,
          type: extmark.type,
          startOffset: extmark.startOffset,
          endOffset: extmark.endOffset + length,
          virtual: extmark.virtual,
          styleKey: extmark.styleKey,
          priority: extmark.priority,
          data: extmark.data,
        );
      }
    }
  }

  void applyDeletion({required int startOffset, required int endOffset}) {
    final range = _normalizedOffsets(startOffset, endOffset);
    final deleteStart = range.start;
    final deleteEnd = range.end;
    final length = deleteEnd - deleteStart;
    if (length <= 0) {
      return;
    }

    final toDelete = <int>[];
    for (final entry in _extmarks.entries.toList(growable: false)) {
      final extmark = entry.value;
      if (extmark.endOffset <= deleteStart) {
        continue;
      }

      if (extmark.startOffset >= deleteEnd) {
        _extmarks[entry.key] = TextExtmark(
          id: extmark.id,
          type: extmark.type,
          startOffset: extmark.startOffset - length,
          endOffset: extmark.endOffset - length,
          virtual: extmark.virtual,
          styleKey: extmark.styleKey,
          priority: extmark.priority,
          data: extmark.data,
        );
        continue;
      }

      if (extmark.startOffset >= deleteStart &&
          extmark.endOffset <= deleteEnd) {
        toDelete.add(entry.key);
        continue;
      }

      if (extmark.startOffset < deleteStart && extmark.endOffset > deleteEnd) {
        _extmarks[entry.key] = TextExtmark(
          id: extmark.id,
          type: extmark.type,
          startOffset: extmark.startOffset,
          endOffset: extmark.endOffset - length,
          virtual: extmark.virtual,
          styleKey: extmark.styleKey,
          priority: extmark.priority,
          data: extmark.data,
        );
        continue;
      }

      if (extmark.startOffset < deleteStart &&
          extmark.endOffset > deleteStart) {
        _extmarks[entry.key] = TextExtmark(
          id: extmark.id,
          type: extmark.type,
          startOffset: extmark.startOffset,
          endOffset: deleteStart,
          virtual: extmark.virtual,
          styleKey: extmark.styleKey,
          priority: extmark.priority,
          data: extmark.data,
        );
        continue;
      }

      if (extmark.startOffset < deleteEnd && extmark.endOffset > deleteEnd) {
        _extmarks[entry.key] = TextExtmark(
          id: extmark.id,
          type: extmark.type,
          startOffset: deleteStart,
          endOffset: extmark.endOffset - length,
          virtual: extmark.virtual,
          styleKey: extmark.styleKey,
          priority: extmark.priority,
          data: extmark.data,
        );
      }
    }

    for (final id in toDelete) {
      delete(id);
    }
  }

  void applyReplacement({
    required int startOffset,
    required int endOffset,
    required String text,
  }) {
    final range = _normalizedOffsets(startOffset, endOffset);
    applyDeletion(startOffset: range.start, endOffset: range.end);
    applyInsertion(offset: range.start, text: text);
  }

  List<TextExtmark> _sorted(Iterable<TextExtmark> extmarks) {
    final result = extmarks.toList(growable: false);
    result.sort((a, b) {
      final startComparison = a.startOffset.compareTo(b.startOffset);
      if (startComparison != 0) {
        return startComparison;
      }
      final endComparison = a.endOffset.compareTo(b.endOffset);
      if (endComparison != 0) {
        return endComparison;
      }
      return a.id.compareTo(b.id);
    });
    return result;
  }
}

TextExtmarkPositionRange textExtmarkPositionRange(
  TextDocument document,
  TextExtmark extmark,
) {
  final normalized = extmark.normalized();
  return TextExtmarkPositionRange(
    start: document.positionForOffset(normalized.startOffset),
    end: document.positionForOffset(normalized.endOffset),
  );
}

({int start, int end}) _normalizedOffsets(int startOffset, int endOffset) {
  if (startOffset <= endOffset) {
    return (start: startOffset, end: endOffset);
  }
  return (start: endOffset, end: startOffset);
}
