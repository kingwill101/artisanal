library;

/// Tracked placeholder ranges for prompt composers.
///
/// Large pasted content is inserted as a short display placeholder (e.g.
/// `[Pasted ~12 lines]`) while the full text is retained alongside the range. Ranges track document edits (insertions
/// shift them, deletions shrink or drop them — same rule as extmarks), and
/// [expandPlaceholderRanges] splices full text back in descending order on
/// submit.

/// A display-text range that stands in for larger content.
final class TrackedPlaceholderRange {
  const TrackedPlaceholderRange({
    required this.startOffset,
    required this.endOffset,
    required this.displayText,
    required this.fullText,
  });

  /// Start offset of the display text in the composer document.
  final int startOffset;

  /// End offset (exclusive) of the display text in the composer document.
  final int endOffset;

  /// Short text physically present in the document.
  final String displayText;

  /// Full content substituted on submit.
  final String fullText;

  int get length => endOffset - startOffset;
}

/// Splices each range's [TrackedPlaceholderRange.fullText] into [text].
///
/// Ranges apply descending by start offset so earlier offsets stay valid.
/// Ranges that are empty, out of order overlap, or out of bounds are skipped.
String expandPlaceholderRanges(
  String text,
  List<TrackedPlaceholderRange> ranges,
) {
  final ordered = ranges.toList(growable: false)
    ..sort((a, b) => b.startOffset.compareTo(a.startOffset));
  var result = text;
  var floor = result.length + 1;
  for (final range in ordered) {
    final start = range.startOffset;
    final end = range.endOffset;
    if (start < 0 || end < start || end > result.length || end > floor) {
      continue;
    }
    // Guard against placeholder/display drift: only expand when the
    // display text matches what the range claims.
    if (result.substring(start, end) != range.displayText) {
      continue;
    }
    result = result.substring(0, start) + range.fullText + result.substring(end);
    floor = start;
  }
  return result;
}

/// Tracks placeholder ranges across document edits.
///
/// The host inserts [TrackedPlaceholderRange.displayText] into its document
/// and registers the range here; then forwards every document change so
/// ranges stay aligned until submit.
final class PlaceholderTracker {
  final List<TrackedPlaceholderRange> _ranges = <TrackedPlaceholderRange>[];

  List<TrackedPlaceholderRange> get ranges =>
      List<TrackedPlaceholderRange>.unmodifiable(_ranges);

  bool get isEmpty => _ranges.isEmpty;

  void track(TrackedPlaceholderRange range) {
    _ranges.add(range);
    _ranges.sort((a, b) => a.startOffset.compareTo(b.startOffset));
  }

  bool untrack(TrackedPlaceholderRange range) => _ranges.remove(range);

  void clear() => _ranges.clear();

  /// Shifts ranges for an insertion of [length] graphemes at [offset].
  void applyInsertion({required int offset, required int length}) {
    if (length <= 0) return;
    for (var i = 0; i < _ranges.length; i++) {
      final range = _ranges[i];
      if (range.startOffset >= offset) {
        _ranges[i] = TrackedPlaceholderRange(
          startOffset: range.startOffset + length,
          endOffset: range.endOffset + length,
          displayText: range.displayText,
          fullText: range.fullText,
        );
      } else if (range.endOffset > offset) {
        _ranges[i] = TrackedPlaceholderRange(
          startOffset: range.startOffset,
          endOffset: range.endOffset + length,
          displayText: range.displayText,
          fullText: range.fullText,
        );
      }
    }
  }

  /// Shifts ranges for a deletion of `[startOffset, endOffset)`.
  ///
  /// Ranges fully inside the deletion are dropped; overlapping ranges
  /// shrink to the deletion edge.
  void applyDeletion({required int startOffset, required int endOffset}) {
    var start = startOffset;
    var end = endOffset;
    if (start > end) {
      final next = start;
      start = end;
      end = next;
    }
    final length = end - start;
    if (length <= 0) return;
    final kept = <TrackedPlaceholderRange>[];
    for (final range in _ranges) {
      if (range.endOffset <= start) {
        kept.add(range);
        continue;
      }
      if (range.startOffset >= end) {
        kept.add(
          TrackedPlaceholderRange(
            startOffset: range.startOffset - length,
            endOffset: range.endOffset - length,
            displayText: range.displayText,
            fullText: range.fullText,
          ),
        );
        continue;
      }
      if (range.startOffset >= start && range.endOffset <= end) {
        continue; // Fully deleted: drop.
      }
      if (range.startOffset < start && range.endOffset > end) {
        kept.add(
          TrackedPlaceholderRange(
            startOffset: range.startOffset,
            endOffset: range.endOffset - length,
            displayText: range.displayText,
            fullText: range.fullText,
          ),
        );
        continue;
      }
      if (range.startOffset < start) {
        kept.add(
          TrackedPlaceholderRange(
            startOffset: range.startOffset,
            endOffset: start,
            displayText: range.displayText,
            fullText: range.fullText,
          ),
        );
      } else {
        kept.add(
          TrackedPlaceholderRange(
            startOffset: start,
            endOffset: range.endOffset - length,
            displayText: range.displayText,
            fullText: range.fullText,
          ),
        );
      }
    }
    _ranges
      ..clear()
      ..addAll(kept);
  }

  /// Convenience for a replacement of `[startOffset, endOffset)` with text
  /// of [insertLength] graphemes.
  void applyReplacement({
    required int startOffset,
    required int endOffset,
    required int insertLength,
  }) {
    var start = startOffset;
    var end = endOffset;
    if (start > end) {
      final next = start;
      start = end;
      end = next;
    }
    applyDeletion(startOffset: start, endOffset: end);
    applyInsertion(offset: start, length: insertLength);
  }
}
