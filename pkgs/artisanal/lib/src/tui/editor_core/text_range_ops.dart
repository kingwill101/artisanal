library;

import 'editor_state.dart';
import 'text_document.dart';
import 'text_selection_set.dart';

/// Produces a new selection set from the document and current selections.
///
/// Hosts use this for motions, search, mouse drags, and fold-aware movement.
/// Editing styles (insert-only, modal, multi-cursor) share the same type.
typedef EditorRangeResolver =
    TextSelectionSet Function(TextDocument document, TextSelectionSet current);

/// Reports whether a logical document line is hidden from vertical movement.
typedef TextLineHiddenPredicate = bool Function(int line);

/// Resolves the next visible logical line while retaining a preferred column.
///
/// [preferredColumn] normally comes from the first vertical move in a sequence.
/// Passing it through later calls lets a cursor cross a short line and return
/// to the original column on a longer line. Hidden lines are skipped when
/// [isLineHidden] is supplied. If there is no adjacent visible line, the
/// original [offset] is returned.
int textOffsetOnAdjacentVisibleLine({
  required TextDocument document,
  required int offset,
  required bool below,
  int? preferredColumn,
  TextLineHiddenPredicate? isLineHidden,
}) {
  final position = document.positionForOffset(offset);
  var targetLine = position.line + (below ? 1 : -1);
  while (targetLine >= 0 &&
      targetLine < document.lineCount &&
      (isLineHidden?.call(targetLine) ?? false)) {
    targetLine += below ? 1 : -1;
  }
  if (targetLine < 0 || targetLine >= document.lineCount) return offset;
  final targetColumn = (preferredColumn ?? position.column).clamp(
    0,
    document.lineLength(targetLine),
  );
  return document.offsetForPosition(
    TextPosition(line: targetLine, column: targetColumn),
  );
}

/// Maps each range through [transform] and rebuilds the set.
///
/// Returns the original [selections] when every range is unchanged.
TextSelectionSet mapSelectionRanges(
  TextSelectionSet selections, {
  required TextSelectionRange Function(TextSelectionRange range) transform,
}) {
  if (selections.ranges.isEmpty) return selections;
  final moved = <TextSelectionRange>[];
  var primaryOffset = selections.primary!.activeOffset;
  var changed = false;
  for (final range in selections.ranges) {
    final next = transform(range);
    changed = changed || next != range;
    moved.add(next);
    if (range == selections.primary) primaryOffset = next.activeOffset;
  }
  if (!changed) return selections;
  return TextSelectionSet(moved, primaryOffset: primaryOffset);
}

/// Moves or extends every range's active edge through [mapEnd].
///
/// When [extend] is false and a range is non-collapsed, the range collapses
/// to its start (backward) or end (forward) without further mapping — the
/// usual “arrow key dismisses the selection” rule. Extension retains the
/// anchor and can cross it without losing direction.
TextSelectionSet mapSelectionEnds(
  TextSelectionSet selections, {
  required int Function(int activeOffset, TextSelectionRange range) mapEnd,
  required bool forward,
  bool extend = false,
}) {
  return mapSelectionRanges(
    selections,
    transform: (range) {
      if (extend) {
        return TextSelectionRange.directional(
          anchorOffset: range.anchorOffset,
          activeOffset: mapEnd(range.activeOffset, range),
        );
      }
      if (!range.isCollapsed) {
        final offset = forward ? range.endOffset : range.startOffset;
        return TextSelectionRange(startOffset: offset, endOffset: offset);
      }
      final offset = mapEnd(range.activeOffset, range);
      return TextSelectionRange(startOffset: offset, endOffset: offset);
    },
  );
}
