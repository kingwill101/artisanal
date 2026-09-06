import 'package:ultraviolet/core.dart' as ultraviolet;

import 'view.dart';

/// Axis used by [FrameLayout.split].
enum FrameAxis {
  /// Divide the area into left-to-right columns.
  horizontal,

  /// Divide the area into top-to-bottom rows.
  vertical,
}

/// Space removed from the edges of a [FrameArea] before layout.
final class FrameInsets {
  /// Creates explicit edge insets.
  const FrameInsets({
    this.left = 0,
    this.top = 0,
    this.right = 0,
    this.bottom = 0,
  }) : assert(left >= 0),
       assert(top >= 0),
       assert(right >= 0),
       assert(bottom >= 0);

  /// Creates equal insets on every edge.
  const FrameInsets.all(int value)
    : assert(value >= 0),
      left = value,
      top = value,
      right = value,
      bottom = value;

  /// Left inset in cells.
  final int left;

  /// Top inset in cells.
  final int top;

  /// Right inset in cells.
  final int right;

  /// Bottom inset in cells.
  final int bottom;
}

/// A requested size along one axis of a [FrameLayout].
sealed class FrameConstraint {
  const FrameConstraint();
}

/// A fixed number of terminal cells.
final class FrameLength extends FrameConstraint {
  /// Creates a fixed-length constraint.
  const FrameLength(this.cells) : assert(cells >= 0);

  /// Requested cells.
  final int cells;
}

/// A percentage of the available axis before fixed sizes are allocated.
final class FramePercentage extends FrameConstraint {
  /// Creates a percentage constraint between zero and 100.
  const FramePercentage(this.percent) : assert(percent >= 0 && percent <= 100);

  /// Requested percentage.
  final int percent;
}

/// A weighted share of space left after fixed and percentage constraints.
final class FrameFill extends FrameConstraint {
  /// Creates a weighted fill constraint.
  const FrameFill([this.flex = 1]) : assert(flex > 0);

  /// Relative share of remaining cells.
  final int flex;
}

/// Pure helpers for splitting terminal frame areas.
///
/// Length constraints are allocated first, followed by percentages and fills.
/// If requests exceed the available space, later allocations are clipped.
/// Weighted-fill rounding remainders are assigned deterministically in
/// declaration order.
abstract final class FrameLayout {
  /// Splits [area] into left-to-right columns.
  static List<FrameArea> horizontal(
    FrameArea area,
    List<FrameConstraint> constraints, {
    int gap = 0,
    FrameInsets insets = const FrameInsets(),
  }) => split(
    area,
    constraints,
    axis: FrameAxis.horizontal,
    gap: gap,
    insets: insets,
  );

  /// Splits [area] into top-to-bottom rows.
  static List<FrameArea> vertical(
    FrameArea area,
    List<FrameConstraint> constraints, {
    int gap = 0,
    FrameInsets insets = const FrameInsets(),
  }) => split(
    area,
    constraints,
    axis: FrameAxis.vertical,
    gap: gap,
    insets: insets,
  );

  /// Splits [area] along [axis].
  static List<FrameArea> split(
    FrameArea area,
    List<FrameConstraint> constraints, {
    required FrameAxis axis,
    int gap = 0,
    FrameInsets insets = const FrameInsets(),
  }) {
    if (gap < 0) {
      throw ArgumentError.value(gap, 'gap', 'must not be negative');
    }
    if (constraints.isEmpty) return const <FrameArea>[];

    final inner = _inset(area, insets);
    final mainSize = axis == FrameAxis.horizontal ? inner.width : inner.height;
    final requestedGap = gap * (constraints.length - 1);
    final gapBudget = requestedGap.clamp(0, mainSize);
    final available = mainSize - gapBudget;
    final sizes = List<int>.filled(constraints.length, 0);
    var remaining = available;

    for (var i = 0; i < constraints.length; i++) {
      if (constraints[i] case FrameLength(:final cells)) {
        final allocated = cells.clamp(0, remaining);
        sizes[i] = allocated;
        remaining -= allocated;
      }
    }

    for (var i = 0; i < constraints.length; i++) {
      if (constraints[i] case FramePercentage(:final percent)) {
        final requested = available * percent ~/ 100;
        final allocated = requested.clamp(0, remaining);
        sizes[i] = allocated;
        remaining -= allocated;
      }
    }

    final fillIndices = <int>[];
    final fillWeights = <int>[];
    for (var i = 0; i < constraints.length; i++) {
      if (constraints[i] case FrameFill(:final flex)) {
        fillIndices.add(i);
        fillWeights.add(flex);
      }
    }
    if (fillIndices.isNotEmpty && remaining > 0) {
      final allocations = ultraviolet.splitByLargestRemainder(
        remaining,
        fillWeights,
      );
      for (var i = 0; i < fillIndices.length; i++) {
        sizes[fillIndices[i]] = allocations[i];
      }
    }

    final actualGap = constraints.length <= 1
        ? 0
        : gapBudget ~/ (constraints.length - 1);
    var cursor = axis == FrameAxis.horizontal ? inner.x : inner.y;
    return List<FrameArea>.generate(constraints.length, (index) {
      final size = sizes[index];
      final result = axis == FrameAxis.horizontal
          ? FrameArea(cursor, inner.y, size, inner.height)
          : FrameArea(inner.x, cursor, inner.width, size);
      cursor += size + actualGap;
      final end = axis == FrameAxis.horizontal ? inner.right : inner.bottom;
      if (cursor > end) cursor = end;
      return result;
    }, growable: false);
  }

  static FrameArea _inset(FrameArea area, FrameInsets insets) {
    return area.inset(
      left: insets.left,
      top: insets.top,
      right: insets.right,
      bottom: insets.bottom,
    );
  }
}
