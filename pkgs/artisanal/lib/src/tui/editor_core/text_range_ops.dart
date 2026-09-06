library;

import 'text_document.dart';
import 'text_selection_set.dart';

/// Produces a new selection set from the document and current selections.
///
/// Hosts use this for motions, search, mouse drags, and fold-aware movement.
/// Editing styles (insert-only, modal, multi-cursor) share the same type.
typedef EditorRangeResolver =
    TextSelectionSet Function(TextDocument document, TextSelectionSet current);

/// Maps each range through [transform] and rebuilds the set.
///
/// Returns the original [selections] when every range is unchanged.
TextSelectionSet mapSelectionRanges(
  TextSelectionSet selections, {
  required TextSelectionRange Function(TextSelectionRange range) transform,
}) {
  if (selections.ranges.isEmpty) return selections;
  final moved = <TextSelectionRange>[];
  var primaryOffset = selections.primary!.endOffset;
  var changed = false;
  for (final range in selections.ranges) {
    final next = transform(range);
    changed = changed || next != range;
    moved.add(next);
    if (range == selections.primary) primaryOffset = next.endOffset;
  }
  if (!changed) return selections;
  return TextSelectionSet(moved, primaryOffset: primaryOffset);
}

/// Moves or extends every range end through [mapEnd].
///
/// When [extend] is false and a range is non-collapsed, the range collapses
/// to its start (backward) or end (forward) without further mapping — the
/// usual “arrow key dismisses the selection” rule.
TextSelectionSet mapSelectionEnds(
  TextSelectionSet selections, {
  required int Function(int endOffset, TextSelectionRange range) mapEnd,
  required bool forward,
  bool extend = false,
}) {
  return mapSelectionRanges(
    selections,
    transform: (range) {
      if (extend) {
        return TextSelectionRange(
          startOffset: range.startOffset,
          endOffset: mapEnd(range.endOffset, range),
        );
      }
      if (!range.isCollapsed) {
        final offset = forward ? range.endOffset : range.startOffset;
        return TextSelectionRange(startOffset: offset, endOffset: offset);
      }
      final offset = mapEnd(range.endOffset, range);
      return TextSelectionRange(startOffset: offset, endOffset: offset);
    },
  );
}
