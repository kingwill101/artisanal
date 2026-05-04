import 'package:artisanal_widgets/widgets.dart' as w;

import '../models/diff_comment_target.dart';

final class GithubDiffInteractionState {
  int selectedAnchorIndex = 0;
  int? rangeStartAnchorIndex;
  bool hasSelection = false;

  void reset() {
    selectedAnchorIndex = 0;
    rangeStartAnchorIndex = null;
    hasSelection = false;
  }

  bool get rangeActive => rangeStartAnchorIndex != null;

  w.DiffCommentAnchor? selectedAnchor(List<w.DiffCommentAnchor> anchors) {
    if (anchors.isEmpty) return null;
    if (!hasSelection) return null;
    clamp(anchors);
    return anchors[selectedAnchorIndex];
  }

  void clamp(List<w.DiffCommentAnchor> anchors) {
    if (anchors.isEmpty) {
      selectedAnchorIndex = 0;
      rangeStartAnchorIndex = null;
      hasSelection = false;
      return;
    }
    selectedAnchorIndex = selectedAnchorIndex
        .clamp(0, anchors.length - 1)
        .toInt();
    final rangeStart = rangeStartAnchorIndex;
    if (rangeStart != null) {
      rangeStartAnchorIndex = rangeStart.clamp(0, anchors.length - 1).toInt();
    }
  }

  bool selectAnchor(
    List<w.DiffCommentAnchor> anchors,
    w.DiffCommentAnchor anchor,
  ) {
    final index = _indexOfAnchor(anchors, anchor);
    if (index == null) return false;
    selectedAnchorIndex = index;
    hasSelection = true;
    return true;
  }

  bool selectRenderLine(
    List<w.DiffCommentAnchor> anchors,
    int renderLine, {
    w.DiffCommentSide? side,
  }) {
    final index = _indexAtRenderLine(anchors, renderLine, side: side);
    if (index == null) return false;
    selectedAnchorIndex = index;
    hasSelection = true;
    return true;
  }

  bool moveSelection(List<w.DiffCommentAnchor> anchors, int delta) {
    if (anchors.isEmpty) return false;
    final before = selectedAnchorIndex;
    final hadSelection = hasSelection;
    selectedAnchorIndex = (selectedAnchorIndex + delta)
        .clamp(0, anchors.length - 1)
        .toInt();
    hasSelection = true;
    return selectedAnchorIndex != before || !hadSelection;
  }

  bool selectSide(List<w.DiffCommentAnchor> anchors, w.DiffCommentSide side) {
    final selected = selectedAnchor(anchors);
    if (selected == null || selected.side == side) return false;
    final sameRenderedLine = anchors.indexWhere(
      (anchor) =>
          anchor.renderLine == selected.renderLine && anchor.side == side,
    );
    if (sameRenderedLine >= 0) {
      selectedAnchorIndex = sameRenderedLine;
      hasSelection = true;
      return true;
    }
    final sameSourceLine = anchors.indexWhere(
      (anchor) =>
          anchor.path == selected.path &&
          anchor.line == selected.line &&
          anchor.side == side,
    );
    if (sameSourceLine >= 0) {
      selectedAnchorIndex = sameSourceLine;
      hasSelection = true;
      return true;
    }
    return false;
  }

  bool toggleRange(List<w.DiffCommentAnchor> anchors) {
    if (anchors.isEmpty) return false;
    hasSelection = true;
    if (rangeStartAnchorIndex == null) {
      rangeStartAnchorIndex = selectedAnchorIndex
          .clamp(0, anchors.length - 1)
          .toInt();
    } else {
      rangeStartAnchorIndex = null;
    }
    return true;
  }

  List<w.DiffCommentLineHighlight> highlights(
    List<w.DiffCommentAnchor> anchors,
  ) {
    if (anchors.isEmpty) return const <w.DiffCommentLineHighlight>[];
    if (!hasSelection) return const <w.DiffCommentLineHighlight>[];
    clamp(anchors);
    final result = <w.DiffCommentLineHighlight>[];
    final range = _rangeAnchors(anchors);
    for (final anchor in range) {
      result.add(w.DiffCommentLineHighlight.range(anchor));
    }
    result.add(
      w.DiffCommentLineHighlight.selected(anchors[selectedAnchorIndex]),
    );
    return result;
  }

  GithubDiffCommentTarget? targetFor(List<w.DiffCommentAnchor> anchors) {
    final selected = selectedAnchor(anchors);
    if (selected == null) return null;
    final range = _rangeBounds(anchors);
    if (range == null) return GithubDiffCommentTarget.fromAnchor(selected);
    if (range.start.line == range.end.line) {
      return GithubDiffCommentTarget.fromAnchor(selected);
    }
    return GithubDiffCommentTarget.fromAnchor(
      range.end,
      startAnchor: range.start,
    );
  }

  List<w.DiffCommentAnchor> _rangeAnchors(List<w.DiffCommentAnchor> anchors) {
    final range = _rangeBounds(anchors);
    if (range == null) return const <w.DiffCommentAnchor>[];
    return anchors
        .where(
          (anchor) =>
              anchor.path == range.start.path &&
              anchor.side == range.start.side &&
              anchor.line >= range.start.line &&
              anchor.line <= range.end.line,
        )
        .toList(growable: false);
  }

  ({w.DiffCommentAnchor start, w.DiffCommentAnchor end})? _rangeBounds(
    List<w.DiffCommentAnchor> anchors,
  ) {
    final startIndex = rangeStartAnchorIndex;
    if (startIndex == null || anchors.isEmpty) return null;
    clamp(anchors);
    final start = anchors[startIndex];
    final selected = anchors[selectedAnchorIndex];
    if (start.path != selected.path || start.side != selected.side) {
      return null;
    }
    return start.line <= selected.line
        ? (start: start, end: selected)
        : (start: selected, end: start);
  }

  int? _indexOfAnchor(
    List<w.DiffCommentAnchor> anchors,
    w.DiffCommentAnchor selected,
  ) {
    final index = anchors.indexWhere(
      (anchor) =>
          anchor.renderLine == selected.renderLine &&
          anchor.path == selected.path &&
          anchor.line == selected.line &&
          anchor.side == selected.side,
    );
    return index < 0 ? null : index;
  }

  int? _indexAtRenderLine(
    List<w.DiffCommentAnchor> anchors,
    int renderLine, {
    w.DiffCommentSide? side,
  }) {
    int? fallback;
    for (var index = 0; index < anchors.length; index++) {
      final anchor = anchors[index];
      if (renderLine < anchor.renderLine) break;
      if (renderLine >= anchor.renderLineEnd) continue;
      fallback ??= index;
      if (side == null || anchor.side == side) return index;
    }
    return fallback;
  }
}
