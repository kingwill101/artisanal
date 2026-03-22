/// Tiling pane manager primitives for interactive terminal layouts.
///
/// This module models a lightweight, immutable binary split tree with:
/// - split creation
/// - drag-to-resize with per-side minimum constraints
/// - snap-target discovery for drag interactions
/// - keyboard style pane navigation
/// - invariant validation
library;

import 'dart:math' as math;

/// Direction for pane geometry splits.
enum PaneSplitDirection {
  /// Split splits a region horizontally (top and bottom panes).
  horizontal,

  /// Split splits a region vertically (left and right panes).
  vertical,
}

/// Navigation direction used for focus traversal.
enum PaneNavigationDirection { up, down, left, right }

/// Snap alignment for drag gestures near a split handle.
enum PaneSnapAlignment { before, after }

/// A target split handle used for snap behavior.
final class PaneSnapTarget {
  final String splitId;
  final PaneSplitDirection direction;
  final PaneSnapAlignment alignment;

  const PaneSnapTarget({
    required this.splitId,
    required this.direction,
    required this.alignment,
  });
}

/// Rectangle coordinates for leaf pane geometry.
final class PaneRect {
  final String paneId;
  final int x;
  final int y;
  final int width;
  final int height;

  const PaneRect({
    required this.paneId,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}

/// Geometry for a split handle used by resize/snap calculations.
final class SplitHandle {
  final String splitId;
  final PaneSplitDirection direction;
  final int x;
  final int y;
  final int width;
  final int height;

  const SplitHandle({
    required this.splitId,
    required this.direction,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  /// Horizontal (left-to-right) boundary coordinate for this split.
  int get boundaryX => switch (direction) {
    PaneSplitDirection.vertical => x,
    PaneSplitDirection.horizontal => x + width,
  };

  /// Vertical (top-to-bottom) boundary coordinate for this split.
  int get boundaryY => switch (direction) {
    PaneSplitDirection.vertical => y + height,
    PaneSplitDirection.horizontal => y,
  };
}

sealed class PaneTreeNode {
  const PaneTreeNode();

  /// Collects all pane IDs reachable from this node.
  Set<String> paneIds();

  /// Collects all split IDs reachable from this node.
  Set<String> splitIds();

  /// Minimum widths needed for this node.
  int minWidth(int paneMinWidth, int paneMinHeight);

  /// Minimum heights needed for this node.
  int minHeight(int paneMinWidth, int paneMinHeight);
}

final class PaneLeaf extends PaneTreeNode {
  final String paneId;

  const PaneLeaf(this.paneId);

  @override
  Set<String> paneIds() => <String>{paneId};

  @override
  Set<String> splitIds() => <String>{};

  @override
  int minWidth(int paneMinWidth, int paneMinHeight) => paneMinWidth;

  @override
  int minHeight(int paneMinWidth, int paneMinHeight) => paneMinHeight;
}

final class PaneSplit extends PaneTreeNode {
  final String splitId;
  final PaneSplitDirection direction;
  final PaneTreeNode first;
  final PaneTreeNode second;
  final double ratio;

  const PaneSplit({
    required this.splitId,
    required this.direction,
    required this.first,
    required this.second,
    required this.ratio,
  });

  @override
  Set<String> paneIds() => <String>{...first.paneIds(), ...second.paneIds()};

  @override
  Set<String> splitIds() => <String>{
    splitId,
    ...first.splitIds(),
    ...second.splitIds(),
  };

  @override
  int minWidth(int paneMinWidth, int paneMinHeight) => switch (direction) {
    PaneSplitDirection.vertical =>
      first.minWidth(paneMinWidth, paneMinHeight) +
          second.minWidth(paneMinWidth, paneMinHeight),
    PaneSplitDirection.horizontal => math.max(
      first.minWidth(paneMinWidth, paneMinHeight),
      second.minWidth(paneMinWidth, paneMinHeight),
    ),
  };

  @override
  int minHeight(int paneMinWidth, int paneMinHeight) => switch (direction) {
    PaneSplitDirection.vertical => math.max(
      first.minHeight(paneMinWidth, paneMinHeight),
      second.minHeight(paneMinWidth, paneMinHeight),
    ),
    PaneSplitDirection.horizontal =>
      first.minHeight(paneMinWidth, paneMinHeight) +
          second.minHeight(paneMinWidth, paneMinHeight),
  };
}

/// A complete computed layout for all leaf panes and split handles.
final class PaneLayout {
  final Map<String, PaneRect> panes;
  final Map<String, SplitHandle> splits;

  const PaneLayout({required this.panes, required this.splits});
}

/// Immutable tiling pane manager with split tree and focused pane id.
final class TilingPaneManager {
  final PaneTreeNode root;
  final String focusedPaneId;
  final int paneMinWidth;
  final int paneMinHeight;
  final int snapThreshold;

  const TilingPaneManager._({
    required this.root,
    required this.focusedPaneId,
    required this.paneMinWidth,
    required this.paneMinHeight,
    this.snapThreshold = 2,
  }) : assert(paneMinWidth >= 1, 'paneMinWidth must be at least 1'),
       assert(paneMinHeight >= 1, 'paneMinHeight must be at least 1');

  factory TilingPaneManager({
    String rootPaneId = 'root',
    int paneMinWidth = 1,
    int paneMinHeight = 1,
    int snapThreshold = 2,
  }) {
    return TilingPaneManager._(
      root: PaneLeaf(rootPaneId),
      focusedPaneId: rootPaneId,
      paneMinWidth: paneMinWidth,
      paneMinHeight: paneMinHeight,
      snapThreshold: snapThreshold,
    );
  }

  /// Creates a manager using a prebuilt pane tree. Intended for tests
  /// and advanced users that need deterministic tree fixtures.
  factory TilingPaneManager.withRoot({
    required PaneTreeNode root,
    required String focusedPaneId,
    int paneMinWidth = 1,
    int paneMinHeight = 1,
    int snapThreshold = 2,
  }) {
    return TilingPaneManager._(
      root: root,
      focusedPaneId: focusedPaneId,
      paneMinWidth: paneMinWidth,
      paneMinHeight: paneMinHeight,
      snapThreshold: snapThreshold,
    );
  }

  /// Returns true if all invariants required by `validationErrors` hold.
  bool get isValid => validationErrors().isEmpty;

  /// Validates structural invariants and returns one or more descriptive errors.
  List<String> validationErrors() {
    final errors = <String>[];

    final paneIdList = _collectPaneIds(root);
    final paneIdSet = paneIdList.toSet();
    if (paneIdList.isEmpty) {
      errors.add('root must contain at least one pane');
    }
    if (paneIdList.length != paneIdSet.length) {
      errors.add('pane ids must be unique');
    }

    final splitIds = _collectSplitIds(root);
    final splitIdSet = splitIds.toSet();
    if (splitIds.length != _countSplits(root)) {
      errors.add('split ids must be unique');
    }
    if (splitIds.length != splitIdSet.length) {
      errors.add('split ids must be unique');
    }

    if (paneMinWidth < 1 || paneMinHeight < 1) {
      errors.add('pane minimums must be >=1');
    }

    if (root is PaneSplit) {
      if (!_validateSplitNode(root as PaneSplit, errors)) {
        errors.add('split ratios must be finite within (0, 1)');
      }
    } else if (root is PaneLeaf && !paneIdSet.contains(focusedPaneId)) {
      errors.add('focusedPaneId must exist in tree');
    }

    if (!paneIdSet.contains(focusedPaneId)) {
      errors.add('focusedPaneId must exist in tree');
    }

    return errors;
  }

  /// Splits the target pane into two children and returns a new manager.
  TilingPaneManager splitPane({
    required String targetPaneId,
    required String splitId,
    required String splitPaneId,
    required PaneSplitDirection direction,
    double ratio = 0.5,
  }) {
    if (splitPaneId == targetPaneId) {
      throw StateError('splitPaneId cannot equal targetPaneId');
    }

    final nextRatio = _clampRatio(ratio);
    final nextRoot = _splitNode(
      root,
      targetPaneId,
      splitId,
      splitPaneId,
      direction,
      nextRatio,
    );
    if (nextRoot == root) {
      throw StateError('target pane not found: $targetPaneId');
    }

    return TilingPaneManager._(
      root: nextRoot,
      focusedPaneId: focusedPaneId,
      paneMinWidth: paneMinWidth,
      paneMinHeight: paneMinHeight,
      snapThreshold: snapThreshold,
    );
  }

  /// Focuses the nearest neighboring pane in the requested direction.
  TilingPaneManager focusByDirection({
    required PaneNavigationDirection direction,
    required int width,
    required int height,
  }) {
    if (!isValid) {
      return this;
    }

    final layout = this.layout(width: width, height: height);
    final focused = layout.panes[focusedPaneId];
    if (focused == null) return this;

    String? nextId;
    int bestScore = -1;
    int bestDistance = math.max(width, height) + 1;

    for (final entry in layout.panes.entries) {
      if (entry.key == focusedPaneId) continue;
      final candidate = entry.value;
      if (!_isAdjacent(focused, candidate, direction)) continue;

      final score =
          direction == PaneNavigationDirection.left ||
              direction == PaneNavigationDirection.right
          ? _overlapLength(
              focused.y,
              focused.height,
              candidate.y,
              candidate.height,
            )
          : _overlapLength(
              focused.x,
              focused.width,
              candidate.x,
              candidate.width,
            );

      if (score == 0) continue;
      final distance = switch (direction) {
        PaneNavigationDirection.left =>
          focused.x - (candidate.x + candidate.width),
        PaneNavigationDirection.right =>
          candidate.x - (focused.x + focused.width),
        PaneNavigationDirection.up =>
          focused.y - (candidate.y + candidate.height),
        PaneNavigationDirection.down =>
          candidate.y - (focused.y + focused.height),
      };

      if (score > bestScore ||
          (score == bestScore && distance < bestDistance)) {
        bestScore = score;
        bestDistance = distance;
        nextId = entry.key;
      }
    }

    if (nextId == null) return this;
    return copyWith(focusedPaneId: nextId);
  }

  /// Computes and returns pane layout for a given terminal size.
  PaneLayout layout({required int width, required int height}) {
    final panes = <String, PaneRect>{};
    final splits = <String, SplitHandle>{};
    _layoutNode(root, 0, 0, width, height, panes: panes, splits: splits);
    return PaneLayout(panes: panes, splits: splits);
  }

  /// Returns a snap target if a pointer is near a split divider.
  PaneSnapTarget? snapTarget({
    required int x,
    required int y,
    required int width,
    required int height,
  }) {
    if (!isValid) return null;
    if (width <= 0 || height <= 0) return null;

    final currentLayout = layout(width: width, height: height);

    for (final handle in currentLayout.splits.values) {
      if (handle.direction == PaneSplitDirection.vertical) {
        if (_isWithinHorizontalSnap(x, handle.boundaryX, snapThreshold) &&
            y >= handle.y &&
            y < handle.y + handle.height) {
          return PaneSnapTarget(
            splitId: handle.splitId,
            direction: handle.direction,
            alignment: x <= handle.boundaryX
                ? PaneSnapAlignment.before
                : PaneSnapAlignment.after,
          );
        }
      } else {
        if (_isWithinHorizontalSnap(y, handle.boundaryY, snapThreshold) &&
            x >= handle.x &&
            x < handle.x + handle.width) {
          return PaneSnapTarget(
            splitId: handle.splitId,
            direction: handle.direction,
            alignment: y <= handle.boundaryY
                ? PaneSnapAlignment.before
                : PaneSnapAlignment.after,
          );
        }
      }
    }
    return null;
  }

  /// Adjusts a split ratio by pointer drag while respecting min sizes.
  TilingPaneManager dragResizeSplit({
    required String splitId,
    required int delta,
    required int width,
    required int height,
  }) {
    if (delta == 0) return this;
    final current = layout(width: width, height: height);
    final handle = current.splits[splitId];
    if (handle == null) return this;
    final mainLength = switch (handle.direction) {
      PaneSplitDirection.vertical => handle.height,
      PaneSplitDirection.horizontal => handle.width,
    };
    if (mainLength <= 0) return this;

    final updated = _applyResize(root, splitId, delta / mainLength);
    if (updated == root) return this;
    return TilingPaneManager._(
      root: updated,
      focusedPaneId: focusedPaneId,
      paneMinWidth: paneMinWidth,
      paneMinHeight: paneMinHeight,
      snapThreshold: snapThreshold,
    );
  }

  /// Returns a manager with updated focus.
  TilingPaneManager copyWith({String? focusedPaneId}) {
    return TilingPaneManager._(
      root: root,
      focusedPaneId: focusedPaneId ?? this.focusedPaneId,
      paneMinWidth: paneMinWidth,
      paneMinHeight: paneMinHeight,
      snapThreshold: snapThreshold,
    );
  }

  PaneTreeNode _applyResize(
    PaneTreeNode node,
    String splitId,
    double deltaRatio,
  ) {
    if (node is PaneLeaf) return node;
    if (node is PaneSplit) {
      if (node.splitId == splitId) {
        final ratio = _clampRatio(node.ratio + deltaRatio);
        return PaneSplit(
          splitId: node.splitId,
          direction: node.direction,
          first: node.first,
          second: node.second,
          ratio: ratio,
        );
      }
      final first = _applyResize(node.first, splitId, deltaRatio);
      if (first != node.first) {
        return PaneSplit(
          splitId: node.splitId,
          direction: node.direction,
          first: first,
          second: node.second,
          ratio: node.ratio,
        );
      }

      final second = _applyResize(node.second, splitId, deltaRatio);
      if (second != node.second) {
        return PaneSplit(
          splitId: node.splitId,
          direction: node.direction,
          first: node.first,
          second: second,
          ratio: node.ratio,
        );
      }
      return node;
    }
    return node;
  }

  PaneTreeNode _splitNode(
    PaneTreeNode node,
    String targetPaneId,
    String splitId,
    String splitPaneId,
    PaneSplitDirection direction,
    double ratio,
  ) {
    if (node is PaneLeaf) {
      if (node.paneId != targetPaneId) return node;
      return PaneSplit(
        splitId: splitId,
        direction: direction,
        first: PaneLeaf(node.paneId),
        second: PaneLeaf(splitPaneId),
        ratio: ratio,
      );
    }
    if (node is PaneSplit) {
      final nextFirst = _splitNode(
        node.first,
        targetPaneId,
        splitId,
        splitPaneId,
        direction,
        ratio,
      );
      if (nextFirst != node.first) {
        return PaneSplit(
          splitId: node.splitId,
          direction: node.direction,
          first: nextFirst,
          second: node.second,
          ratio: node.ratio,
        );
      }

      final nextSecond = _splitNode(
        node.second,
        targetPaneId,
        splitId,
        splitPaneId,
        direction,
        ratio,
      );
      if (nextSecond != node.second) {
        return PaneSplit(
          splitId: node.splitId,
          direction: node.direction,
          first: node.first,
          second: nextSecond,
          ratio: node.ratio,
        );
      }
      return node;
    }
    return node;
  }

  void _layoutNode(
    PaneTreeNode node,
    int x,
    int y,
    int width,
    int height, {
    required Map<String, PaneRect> panes,
    required Map<String, SplitHandle> splits,
  }) {
    if (width <= 0 || height <= 0) return;

    if (node is PaneLeaf) {
      panes[node.paneId] = PaneRect(
        paneId: node.paneId,
        x: x,
        y: y,
        width: width,
        height: height,
      );
      return;
    }
    if (node is PaneSplit) {
      final ratio = _ratioForSplit(node, width, height);
      switch (node.direction) {
        case PaneSplitDirection.vertical:
          final leftWidth = math.max(1, (width * ratio).round());
          final safeLeftWidth = math.max(1, math.min(width - 1, leftWidth));
          final handleX = x + safeLeftWidth;
          final rightWidth = width - safeLeftWidth;
          splits[node.splitId] = SplitHandle(
            splitId: node.splitId,
            direction: node.direction,
            x: handleX,
            y: y,
            width: 1,
            height: height,
          );
          _layoutNode(
            node.first,
            x,
            y,
            safeLeftWidth,
            height,
            panes: panes,
            splits: splits,
          );
          _layoutNode(
            node.second,
            handleX,
            y,
            rightWidth,
            height,
            panes: panes,
            splits: splits,
          );
          return;
        case PaneSplitDirection.horizontal:
          final topHeight = math.max(1, (height * ratio).round());
          final safeTopHeight = math.max(1, math.min(height - 1, topHeight));
          final handleY = y + safeTopHeight;
          final bottomHeight = height - safeTopHeight;
          splits[node.splitId] = SplitHandle(
            splitId: node.splitId,
            direction: node.direction,
            x: x,
            y: handleY,
            width: width,
            height: 1,
          );
          _layoutNode(
            node.first,
            x,
            y,
            width,
            safeTopHeight,
            panes: panes,
            splits: splits,
          );
          _layoutNode(
            node.second,
            x,
            handleY,
            width,
            bottomHeight,
            panes: panes,
            splits: splits,
          );
          return;
      }
    }
  }

  double _ratioForSplit(PaneSplit split, int width, int height) {
    final safeRatio = _clampRatio(split.ratio);
    final firstMin = switch (split.direction) {
      PaneSplitDirection.vertical => split.first.minWidth(
        paneMinWidth,
        paneMinHeight,
      ),
      PaneSplitDirection.horizontal => split.first.minHeight(
        paneMinWidth,
        paneMinHeight,
      ),
    };
    final secondMin = switch (split.direction) {
      PaneSplitDirection.vertical => split.second.minWidth(
        paneMinWidth,
        paneMinHeight,
      ),
      PaneSplitDirection.horizontal => split.second.minHeight(
        paneMinWidth,
        paneMinHeight,
      ),
    };

    final mainAxis = switch (split.direction) {
      PaneSplitDirection.vertical => width,
      PaneSplitDirection.horizontal => height,
    };
    if (mainAxis <= 0) return safeRatio;
    final minRatio = firstMin / mainAxis;
    final maxRatio = (mainAxis - secondMin) / mainAxis;
    if (minRatio >= maxRatio) return safeRatio;
    return safeRatio.clamp(minRatio, maxRatio);
  }

  bool _validateSplitNode(PaneSplit split, List<String> errors) {
    var ok = true;
    if (!split.ratio.isFinite || split.ratio <= 0.0 || split.ratio >= 1.0) {
      errors.add('split ${split.splitId} ratio out of range');
      ok = false;
    }
    if (split.first is PaneSplit) {
      ok = _validateSplitNode(split.first as PaneSplit, errors) && ok;
    } else if (split.first is! PaneLeaf) {
      ok = false;
    }
    if (split.second is PaneSplit) {
      ok = _validateSplitNode(split.second as PaneSplit, errors) && ok;
    } else if (split.second is! PaneLeaf) {
      ok = false;
    }
    return ok;
  }

  static int _countSplits(PaneTreeNode node) {
    if (node is PaneSplit) {
      return 1 + _countSplits(node.first) + _countSplits(node.second);
    }
    return 0;
  }

  List<String> _collectPaneIds(PaneTreeNode node) {
    if (node is PaneLeaf) {
      return <String>[node.paneId];
    }
    if (node is PaneSplit) {
      return <String>[
        ..._collectPaneIds(node.first),
        ..._collectPaneIds(node.second),
      ];
    }
    return <String>[];
  }

  List<String> _collectSplitIds(PaneTreeNode node) {
    if (node is PaneLeaf) {
      return const <String>[];
    }
    if (node is PaneSplit) {
      return <String>[
        node.splitId,
        ..._collectSplitIds(node.first),
        ..._collectSplitIds(node.second),
      ];
    }
    return const <String>[];
  }

  static double _clampRatio(double ratio) {
    if (!ratio.isFinite) return 0.5;
    return ratio.clamp(0.05, 0.95);
  }

  static bool _isWithinHorizontalSnap(int value, int line, int threshold) =>
      (value - line).abs() <= threshold;

  static bool _isAdjacent(
    PaneRect focused,
    PaneRect candidate,
    PaneNavigationDirection direction,
  ) {
    switch (direction) {
      case PaneNavigationDirection.left:
        if (candidate.x + candidate.width != focused.x) return false;
        return _overlapLength(
              focused.y,
              focused.height,
              candidate.y,
              candidate.height,
            ) >
            0;
      case PaneNavigationDirection.right:
        if (candidate.x != focused.x + focused.width) return false;
        return _overlapLength(
              focused.y,
              focused.height,
              candidate.y,
              candidate.height,
            ) >
            0;
      case PaneNavigationDirection.up:
        if (candidate.y + candidate.height != focused.y) return false;
        return _overlapLength(
              focused.x,
              focused.width,
              candidate.x,
              candidate.width,
            ) >
            0;
      case PaneNavigationDirection.down:
        if (candidate.y != focused.y + focused.height) return false;
        return _overlapLength(
              focused.x,
              focused.width,
              candidate.x,
              candidate.width,
            ) >
            0;
    }
  }

  static int _overlapLength(int startA, int lengthA, int startB, int lengthB) {
    final start = math.max(startA, startB);
    final end = math.min(startA + lengthA, startB + lengthB);
    return math.max(0, end - start);
  }
}
