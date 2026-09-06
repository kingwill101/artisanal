library;

/// Multi-selection sets for multi-cursor editing flows.
///
/// [EditorState] owns a single cursor + selection; this module adds the set
/// model future multi-cursor features build on: sorted, non-overlapping
/// ranges with a primary index, offset mapping across edits (cursor-friendly:
/// collapsed cursors inside a deletion survive at the deletion start), and
/// descending multi-range insert/delete helpers.

/// One range in a [TextSelectionSet]. Collapsed (`start == end`) ranges are
/// cursors.
final class TextSelectionRange {
  const TextSelectionRange({
    required this.startOffset,
    required this.endOffset,
  });

  final int startOffset;
  final int endOffset;

  bool get isCollapsed => startOffset == endOffset;
  int get length => endOffset - startOffset;

  TextSelectionRange normalized() => startOffset <= endOffset
      ? this
      : TextSelectionRange(startOffset: endOffset, endOffset: startOffset);

  @override
  bool operator ==(Object other) =>
      other is TextSelectionRange &&
      other.startOffset == startOffset &&
      other.endOffset == endOffset;

  @override
  int get hashCode => Object.hash(startOffset, endOffset);
}

/// Sorted, non-overlapping selection ranges with a primary index.
final class TextSelectionSet {
  const TextSelectionSet._({required this.ranges, required this.primaryIndex});

  /// Builds a set, sorting and merging overlapping or touching ranges.
  factory TextSelectionSet(
    Iterable<TextSelectionRange> ranges, {
    int? primaryOffset,
  }) {
    final normalized =
        ranges.map((range) => range.normalized()).toList(growable: false)
          ..sort((a, b) => a.startOffset.compareTo(b.startOffset));
    final merged = <TextSelectionRange>[];
    for (final range in normalized) {
      if (merged.isEmpty || range.startOffset > merged.last.endOffset) {
        merged.add(range);
        continue;
      }
      final last = merged.removeLast();
      merged.add(
        TextSelectionRange(
          startOffset: last.startOffset,
          endOffset: range.endOffset > last.endOffset
              ? range.endOffset
              : last.endOffset,
        ),
      );
    }
    var primaryIndex = 0;
    if (primaryOffset != null) {
      for (var i = 0; i < merged.length; i++) {
        if (primaryOffset >= merged[i].startOffset &&
            primaryOffset <= merged[i].endOffset) {
          primaryIndex = i;
        }
      }
    } else if (merged.isNotEmpty) {
      primaryIndex = merged.length - 1;
    }
    return TextSelectionSet._(
      ranges: List<TextSelectionRange>.unmodifiable(merged),
      primaryIndex: merged.isEmpty ? 0 : primaryIndex,
    );
  }

  factory TextSelectionSet.collapsed(int offset) => TextSelectionSet([
    TextSelectionRange(startOffset: offset, endOffset: offset),
  ], primaryOffset: offset);

  final List<TextSelectionRange> ranges;
  final int primaryIndex;

  bool get isEmpty => ranges.isEmpty;
  TextSelectionRange? get primary =>
      ranges.isEmpty ? null : ranges[primaryIndex.clamp(0, ranges.length - 1)];

  /// Returns a set with [range] added (merging as needed).
  TextSelectionSet add(TextSelectionRange range, {bool makePrimary = true}) {
    final next = TextSelectionSet(
      [...ranges, range],
      primaryOffset: makePrimary
          ? range.normalized().endOffset
          : primary?.endOffset,
    );
    return next;
  }

  /// Collapses every range to its end offset (cursor per range).
  TextSelectionSet collapseEach() => TextSelectionSet(
    ranges.map(
      (range) => TextSelectionRange(
        startOffset: range.endOffset,
        endOffset: range.endOffset,
      ),
    ),
    primaryOffset: primary?.endOffset,
  );

  /// Maps the set through an insertion of [length] graphemes at [offset].
  TextSelectionSet applyInsertion({required int offset, required int length}) {
    if (length <= 0 || ranges.isEmpty) return this;
    return TextSelectionSet(
      ranges.map(
        (range) => TextSelectionRange(
          startOffset: range.startOffset >= offset
              ? range.startOffset + length
              : range.startOffset,
          endOffset: range.endOffset >= offset
              ? range.endOffset + length
              : range.endOffset,
        ),
      ),
      primaryOffset: _mappedPrimary(offset, length, isInsertion: true),
    );
  }

  /// Maps the set through a deletion of `[startOffset, endOffset)`.
  ///
  /// Collapsed cursors inside the deletion survive at its start;
  /// non-collapsed ranges fully inside are dropped; partial overlaps shrink.
  TextSelectionSet applyDeletion({
    required int startOffset,
    required int endOffset,
  }) {
    var start = startOffset;
    var end = endOffset;
    if (start > end) {
      final next = start;
      start = end;
      end = next;
    }
    final length = end - start;
    if (length <= 0 || ranges.isEmpty) return this;
    final kept = <TextSelectionRange>[];
    for (final range in ranges) {
      if (range.endOffset <= start) {
        kept.add(range);
        continue;
      }
      if (range.startOffset >= end) {
        kept.add(
          TextSelectionRange(
            startOffset: range.startOffset - length,
            endOffset: range.endOffset - length,
          ),
        );
        continue;
      }
      if (range.isCollapsed) {
        kept.add(TextSelectionRange(startOffset: start, endOffset: start));
        continue;
      }
      if (range.startOffset >= start && range.endOffset <= end) continue;
      if (range.startOffset < start && range.endOffset > end) {
        kept.add(
          TextSelectionRange(
            startOffset: range.startOffset,
            endOffset: range.endOffset - length,
          ),
        );
        continue;
      }
      if (range.startOffset < start) {
        kept.add(
          TextSelectionRange(startOffset: range.startOffset, endOffset: start),
        );
      } else {
        kept.add(
          TextSelectionRange(
            startOffset: start,
            endOffset: range.endOffset - length,
          ),
        );
      }
    }
    if (kept.isEmpty) {
      return TextSelectionSet.collapsed(start);
    }
    return TextSelectionSet(kept, primaryOffset: primary?.endOffset);
  }

  int? _mappedPrimary(int offset, int length, {required bool isInsertion}) {
    final current = primary;
    if (current == null) return null;
    if (isInsertion) {
      return current.endOffset >= offset
          ? current.endOffset + length
          : current.endOffset;
    }
    return current.endOffset;
  }
}

/// Inserts [insertion] graphemes at every range in [selections] (ranges
/// collapse to the insertion end). Applies descending; returns the new
/// graphemes and set.
({List<String> graphemes, TextSelectionSet selections})
insertTextAtEachSelection(
  List<String> graphemes,
  TextSelectionSet selections,
  List<String> insertion,
) {
  final ordered = selections.ranges.toList(growable: false)
    ..sort((a, b) => b.startOffset.compareTo(a.startOffset));
  final result = List<String>.from(graphemes);
  final ends = <int>[];
  for (final range in ordered) {
    final start = range.startOffset.clamp(0, result.length);
    final end = range.endOffset.clamp(start, result.length);
    result.replaceRange(start, end, insertion);
    final delta = insertion.length - (end - start);
    if (delta != 0) {
      for (var i = 0; i < ends.length; i++) {
        if (ends[i] >= end) ends[i] += delta;
      }
    }
    ends.add(start + insertion.length);
  }
  ends.sort();
  return (
    graphemes: result,
    selections: TextSelectionSet([
      for (final end in ends)
        TextSelectionRange(startOffset: end, endOffset: end),
    ]),
  );
}
