/// Minimal render objects for layout/pipeline experimentation.
@experimental
library;

import 'package:meta/meta.dart' show experimental;

import 'dart:math' as math;

import 'render_object.dart';
import '../layout/geometry.dart' show BoxConstraints, Size, Offset;
import 'package:artisanal/style.dart'
    show Layout, HorizontalAlign, VerticalAlign;
import 'package:artisanal/tui.dart' show TuiTrace, TraceTag;

/// Horizontal/vertical alignment policy along the main axis for flex layouts.
enum RenderMainAxisAlignment {
  start,
  end,
  center,
  spaceBetween,
  spaceAround,
  spaceEvenly,
}

/// Alignment policy along the cross axis for flex layouts.
enum RenderCrossAxisAlignment { start, end, center, stretch }

/// Fit behavior for flex children.
enum RenderFlexFit { tight, loose }

/// How much space a flex layout should consume on its main axis.
enum RenderMainAxisSize { min, max }

/// Renders a text string with constraints.
class RenderText extends RenderBox {
  RenderText({required this.text, this.softWrap = true});

  String text;
  bool softWrap;

  /// Text after wrapping to constraint width (computed during layout).
  String? _wrappedText;
  String? _lastText;
  bool? _lastSoftWrap;
  int? _lastWrapWidth;

  @override
  void layout(BoxConstraints constraints) {
    super.layout(constraints);

    // Wrap text to the constraint width when softWrap is enabled and the
    // width is bounded.  Without this, long text would be silently clipped
    // during paint() instead of reflowing to multiple lines.
    final wrapWidth = softWrap && constraints.hasBoundedWidth
        ? constraints.maxWidth.toInt()
        : null;
    if (_wrappedText == null ||
        _lastText != text ||
        _lastSoftWrap != softWrap ||
        _lastWrapWidth != wrapWidth) {
      if (wrapWidth != null && wrapWidth > 0) {
        _wrappedText = Layout.wrapLines(text, wrapWidth);
      } else {
        _wrappedText = text;
      }
      _lastText = text;
      _lastSoftWrap = softWrap;
      _lastWrapWidth = wrapWidth;
    }

    final width = Layout.getWidth(_wrappedText!).toDouble();
    final height = Layout.getHeight(_wrappedText!).toDouble();
    size = constraints.constrain(Size(width, height));
  }

  @override
  String paint() {
    final wrapped = _wrappedText ?? text;
    final maxW = size.width.toInt();
    final textW = Layout.getWidth(wrapped);
    if (textW <= maxW) return wrapped;
    // Clip lines that exceed the constrained width (hard truncation, no
    // ellipsis).  This mirrors Flutter's behaviour where paint output is
    // clipped to the widget's reported size.
    return wrapped
        .split('\n')
        .map((l) => Layout.truncate(l, maxW, ellipsis: ''))
        .join('\n');
  }
}

/// A horizontal row layout.
class RenderRow extends RenderBox {
  /// Creates a horizontal flex render object.
  RenderRow({
    this.gap = 0,
    this.mainAxisAlignment = RenderMainAxisAlignment.start,
    this.crossAxisAlignment = RenderCrossAxisAlignment.start,
    this.mainAxisSize = RenderMainAxisSize.min,
    this.mainAxisExtent,
    this.crossAxisExtent,
  });

  /// Fixed spacing inserted between adjacent children.
  int gap;

  /// Main-axis alignment used when there is remaining space.
  RenderMainAxisAlignment mainAxisAlignment;

  /// Cross-axis alignment for child placement.
  RenderCrossAxisAlignment crossAxisAlignment;

  /// Whether to use intrinsic width or fill available width.
  RenderMainAxisSize mainAxisSize;

  /// Optional explicit width override on the main axis.
  int? mainAxisExtent;

  /// Optional explicit height override on the cross axis.
  int? crossAxisExtent;

  @override
  void layout(BoxConstraints constraints) {
    final span = TuiTrace.begin(
      'RenderRow.layout',
      tag: TraceTag.layout,
      extra: 'children=${children.length}',
    );
    super.layout(constraints);
    var width = 0.0;
    var height = 0.0;

    final isStretch = crossAxisAlignment == RenderCrossAxisAlignment.stretch;

    // --- Two-pass flex layout (mirrors Flutter's RenderFlex) ---
    //
    // Pass 1: Layout non-flex children to determine how much space is left
    // for flex children.  Use loose cross constraints initially; stretch
    // is applied in a final pass once the resolved cross size is known.

    final flexData = children.map(_flexDataFor).toList();
    final totalFlex = flexData.fold<int>(0, (sum, f) => sum + f.flex);
    final gapTotal = children.length > 1
        ? gap * (children.length - 1).toDouble()
        : 0.0;

    var nonFlexWidth = 0.0;
    for (var i = 0; i < children.length; i++) {
      if (flexData[i].flex > 0) continue;
      final childConstraints = BoxConstraints(
        minWidth: 0,
        maxWidth: constraints.hasBoundedWidth
            ? double.infinity
            : constraints.maxWidth,
        minHeight: 0,
        maxHeight: constraints.maxHeight,
      );
      children[i].layout(childConstraints);
      nonFlexWidth += children[i].size.width;
      height = math.max(height, children[i].size.height);
    }

    // Pass 2: Distribute remaining space among flex children.
    if (totalFlex > 0 && constraints.hasBoundedWidth) {
      final available = math.max(
        0.0,
        constraints.maxWidth - nonFlexWidth - gapTotal,
      );
      for (var i = 0; i < children.length; i++) {
        final data = flexData[i];
        if (data.flex <= 0) continue;
        final alloc = (available * data.flex) / totalFlex;
        final allocInt = alloc.floorToDouble();
        final childConstraints = data.fit == RenderFlexFit.tight
            ? BoxConstraints(
                minWidth: allocInt,
                maxWidth: allocInt,
                minHeight: 0,
                maxHeight: constraints.maxHeight,
              )
            : BoxConstraints(
                minWidth: 0,
                maxWidth: allocInt,
                minHeight: 0,
                maxHeight: constraints.maxHeight,
              );
        children[i].layout(childConstraints);
        height = math.max(height, children[i].size.height);
      }
    } else {
      // No flex or unbounded — layout flex children with loose constraints.
      for (var i = 0; i < children.length; i++) {
        if (flexData[i].flex <= 0) continue;
        final childConstraints = BoxConstraints(
          minWidth: 0,
          maxWidth: constraints.hasBoundedWidth
              ? double.infinity
              : constraints.maxWidth,
          minHeight: 0,
          maxHeight: constraints.maxHeight,
        );
        children[i].layout(childConstraints);
        height = math.max(height, children[i].size.height);
      }
    }

    // Resolve cross size: max(constraints.minHeight, maxChildHeight).
    // This matches Flutter's RenderFlex cross-axis resolution.
    final crossSize = math.max(constraints.minHeight, height);

    // Pass 3 (stretch only): Re-layout children that need to match the
    // resolved cross size.  This is necessary because the initial passes
    // used loose cross constraints to discover the natural cross extent.
    if (isStretch) {
      for (var i = 0; i < children.length; i++) {
        final child = children[i];
        if (child.size.height == crossSize) continue;
        final prevConstraints = child.constraints;
        final stretchConstraints = BoxConstraints(
          minWidth: prevConstraints.minWidth,
          maxWidth: prevConstraints.maxWidth,
          minHeight: crossSize,
          maxHeight: crossSize,
        );
        child.layout(stretchConstraints);
      }
    }

    width = children.fold<double>(0, (sum, c) => sum + c.size.width) + gapTotal;

    final contentWidth = width;
    final contentHeight = isStretch ? crossSize : height;

    final resolvedWidth = mainAxisSize == RenderMainAxisSize.max
        ? (mainAxisExtent?.toDouble() ??
              (constraints.hasBoundedWidth
                  ? constraints.maxWidth
                  : contentWidth))
        : contentWidth;
    final resolvedHeight = crossAxisExtent?.toDouble() ?? contentHeight;

    size = constraints.constrain(Size(resolvedWidth, resolvedHeight));

    // Compute child offsets matching the paint layout logic.
    _computeChildOffsets();
    span.end(extra: 'size=${size.width.toInt()}x${size.height.toInt()}');
  }

  void _computeChildOffsets() {
    if (children.isEmpty) return;

    final flexData = children.map(_flexDataFor).toList();
    final maxMain = size.width.toInt();
    final childWidths = <double>[];

    // Replicate the flex sizing logic to get actual child widths.
    final rawWidths = children.map((c) => c.size.width.toInt()).toList();
    final totalFlex = flexData.fold<int>(0, (sum, f) => sum + f.flex);
    final contentMain = rawWidths.fold<int>(0, (sum, w) => sum + w);
    final totalWithGap = contentMain + gap * (children.length - 1);
    final flexExtra = math.max(0, maxMain - totalWithGap);

    for (var i = 0; i < children.length; i++) {
      final data = flexData[i];
      var w = rawWidths[i].toDouble();
      if (totalFlex > 0 && data.flex > 0 && data.fit == RenderFlexFit.tight) {
        w += (flexExtra * data.flex) ~/ totalFlex;
      }
      childWidths.add(w);
    }

    // Compute main-axis spacing (matches _computeSpacing + _joinHorizontalWithSpacing).
    final totalMain = childWidths.fold<double>(0, (s, w) => s + w);
    final mainExtra = math.max(
      0.0,
      maxMain - totalMain - gap * (children.length - 1),
    );
    final spacing = _computeSpacing(
      children.length,
      gap,
      mainExtra.toInt(),
      mainAxisAlignment,
    );

    // Compute cross-axis offsets per child (matches _applyCrossAlignment).
    final maxCross = size.height.toInt();

    var x = spacing.leading.toDouble();
    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      final childHeight = child.size.height;

      final crossOffset = switch (crossAxisAlignment) {
        RenderCrossAxisAlignment.start => 0.0,
        RenderCrossAxisAlignment.end => maxCross - childHeight,
        RenderCrossAxisAlignment.center => (maxCross - childHeight) / 2,
        RenderCrossAxisAlignment.stretch => 0.0,
      };

      child.offset = Offset(x, crossOffset);

      x += childWidths[i];
      if (i < spacing.between.length) {
        x += spacing.between[i];
      }
    }
  }

  @override
  String paint() {
    if (children.isEmpty) return '';
    final span = TuiTrace.begin(
      'RenderRow.paint',
      tag: TraceTag.paint,
      extra: 'children=${children.length}',
    );
    final blocks = children.map((c) => c.paint()).toList(growable: false);
    final flexData = children.map(_flexDataFor).toList(growable: false);
    final maxMain = size.width.toInt();
    final maxCross = size.height.toInt();
    final childWidths = children
        .map((c) => c.size.width.toInt())
        .toList(growable: false);
    final childHeights = children
        .map((c) => c.size.height.toInt())
        .toList(growable: false);

    final totalFlex = flexData.fold<int>(0, (sum, f) => sum + f.flex);
    final adjusted = List<String>.of(blocks, growable: false);
    final adjustedWidths = List<int>.of(childWidths, growable: false);

    if (totalFlex > 0) {
      var nonFlexWidth = 0;
      for (var i = 0; i < adjusted.length; i++) {
        if (flexData[i].flex <= 0) nonFlexWidth += adjustedWidths[i];
      }
      final gapTotal = gap * (adjusted.length - 1);
      final available = math.max(0, maxMain - nonFlexWidth - gapTotal);

      for (var i = 0; i < adjusted.length; i++) {
        final data = flexData[i];
        if (data.flex <= 0 || data.fit == RenderFlexFit.loose) continue;

        final target = (available * data.flex) ~/ totalFlex;
        var block = adjusted[i];
        final currentWidth = adjustedWidths[i];
        if (currentWidth > target) {
          block = Layout.truncateLines(block, target, ellipsis: '');
        }
        adjusted[i] = Layout.place(
          width: target,
          height: childHeights[i],
          horizontal: HorizontalAlign.left,
          vertical: VerticalAlign.top,
          content: block,
        );
        adjustedWidths[i] = target;
      }
    }

    final aligned = <String>[];
    final vAlign = switch (crossAxisAlignment) {
      RenderCrossAxisAlignment.start => VerticalAlign.top,
      RenderCrossAxisAlignment.center => VerticalAlign.center,
      RenderCrossAxisAlignment.end => VerticalAlign.bottom,
      RenderCrossAxisAlignment.stretch => VerticalAlign.top,
    };

    for (var i = 0; i < adjusted.length; i++) {
      final block = adjusted[i];
      final childWidth = adjustedWidths[i];
      final childHeight = childHeights[i];
      if (vAlign == VerticalAlign.top && childHeight == maxCross) {
        aligned.add(block);
      } else {
        aligned.add(
          Layout.place(
            width: childWidth,
            height: maxCross,
            horizontal: HorizontalAlign.left,
            vertical: vAlign,
            content: block,
          ),
        );
      }
    }

    final totalMain =
        adjustedWidths.fold<int>(0, (sum, w) => sum + w) +
        gap * (children.length - 1);
    final extra = math.max(0, maxMain - totalMain);
    final spacing = _computeSpacing(
      children.length,
      gap,
      extra,
      mainAxisAlignment,
    );

    final result = Layout.place(
      width: maxMain,
      height: maxCross,
      horizontal: HorizontalAlign.left,
      vertical: VerticalAlign.top,
      content: _joinHorizontalWithSpacing(aligned, spacing),
    );
    span.end(extra: 'size=${size.width.toInt()}x${size.height.toInt()}');
    return result;
  }
}

/// A vertical column layout.
class RenderColumn extends RenderBox {
  /// Creates a vertical flex render object.
  RenderColumn({
    this.gap = 0,
    this.mainAxisAlignment = RenderMainAxisAlignment.start,
    this.crossAxisAlignment = RenderCrossAxisAlignment.start,
    this.mainAxisSize = RenderMainAxisSize.min,
    this.mainAxisExtent,
    this.crossAxisExtent,
  });

  /// Fixed spacing inserted between adjacent children.
  int gap;

  /// Main-axis alignment used when there is remaining space.
  RenderMainAxisAlignment mainAxisAlignment;

  /// Cross-axis alignment for child placement.
  RenderCrossAxisAlignment crossAxisAlignment;

  /// Whether to use intrinsic height or fill available height.
  RenderMainAxisSize mainAxisSize;

  /// Optional explicit height override on the main axis.
  int? mainAxisExtent;

  /// Optional explicit width override on the cross axis.
  int? crossAxisExtent;

  @override
  void layout(BoxConstraints constraints) {
    final span = TuiTrace.begin(
      'RenderColumn.layout',
      tag: TraceTag.layout,
      extra: 'children=${children.length}',
    );
    super.layout(constraints);
    var width = 0.0;
    var height = 0.0;

    final isStretch = crossAxisAlignment == RenderCrossAxisAlignment.stretch;

    // --- Two-pass flex layout (mirrors Flutter's RenderFlex) ---

    final flexData = children.map(_flexDataFor).toList();
    final totalFlex = flexData.fold<int>(0, (sum, f) => sum + f.flex);
    assert(() {
      final hasTightFlex = flexData.any(
        (f) => f.flex > 0 && f.fit == RenderFlexFit.tight,
      );
      if (hasTightFlex && !constraints.hasBoundedHeight) {
        throw AssertionError(
          'RenderColumn has non-zero flex children with unbounded height constraints. '
          'Use MainAxisSize.min, wrap in a bounded parent, or switch flex children to loose fit.',
        );
      }
      return true;
    }());
    final gapTotal = children.length > 1
        ? gap * (children.length - 1).toDouble()
        : 0.0;

    // Pass 1: Layout non-flex children with loose cross constraints.
    // Stretch is applied in a final pass once the resolved cross size
    // is known.
    var nonFlexHeight = 0.0;
    for (var i = 0; i < children.length; i++) {
      if (flexData[i].flex > 0) continue;
      final childConstraints = BoxConstraints(
        minWidth: 0,
        maxWidth: constraints.maxWidth,
        minHeight: 0,
        maxHeight: constraints.hasBoundedHeight
            ? double.infinity
            : constraints.maxHeight,
      );
      children[i].layout(childConstraints);
      nonFlexHeight += children[i].size.height;
      width = math.max(width, children[i].size.width);
    }

    // Pass 2: Distribute remaining space among flex children.
    if (totalFlex > 0 && constraints.hasBoundedHeight) {
      final available = math.max(
        0.0,
        constraints.maxHeight - nonFlexHeight - gapTotal,
      );
      for (var i = 0; i < children.length; i++) {
        final data = flexData[i];
        if (data.flex <= 0) continue;
        final alloc = (available * data.flex) / totalFlex;
        final allocInt = alloc.floorToDouble();
        final childConstraints = data.fit == RenderFlexFit.tight
            ? BoxConstraints(
                minWidth: 0,
                maxWidth: constraints.maxWidth,
                minHeight: allocInt,
                maxHeight: allocInt,
              )
            : BoxConstraints(
                minWidth: 0,
                maxWidth: constraints.maxWidth,
                minHeight: 0,
                maxHeight: allocInt,
              );
        children[i].layout(childConstraints);
        width = math.max(width, children[i].size.width);
      }
    } else {
      // No flex or unbounded — layout flex children with loose constraints.
      for (var i = 0; i < children.length; i++) {
        if (flexData[i].flex <= 0) continue;
        final childConstraints = BoxConstraints(
          minWidth: 0,
          maxWidth: constraints.maxWidth,
          minHeight: 0,
          maxHeight: constraints.hasBoundedHeight
              ? double.infinity
              : constraints.maxHeight,
        );
        children[i].layout(childConstraints);
        width = math.max(width, children[i].size.width);
      }
    }

    // Resolve cross size: max(constraints.minWidth, maxChildWidth).
    // This matches Flutter's RenderFlex cross-axis resolution.
    final crossSize = math.max(constraints.minWidth, width);

    // Pass 3 (stretch only): Re-layout children that need to match the
    // resolved cross size.
    if (isStretch) {
      for (var i = 0; i < children.length; i++) {
        final child = children[i];
        if (child.size.width == crossSize) continue;
        final prevConstraints = child.constraints;
        final stretchConstraints = BoxConstraints(
          minWidth: crossSize,
          maxWidth: crossSize,
          minHeight: prevConstraints.minHeight,
          maxHeight: prevConstraints.maxHeight,
        );
        child.layout(stretchConstraints);
      }
    }

    height =
        children.fold<double>(0, (sum, c) => sum + c.size.height) + gapTotal;

    final contentWidth = isStretch ? crossSize : width;
    final contentHeight = height;

    final resolvedHeight = mainAxisSize == RenderMainAxisSize.max
        ? (mainAxisExtent?.toDouble() ??
              (constraints.hasBoundedHeight
                  ? constraints.maxHeight
                  : contentHeight))
        : contentHeight;
    final resolvedWidth = crossAxisExtent?.toDouble() ?? contentWidth;

    size = constraints.constrain(Size(resolvedWidth, resolvedHeight));

    // Compute child offsets matching the paint layout logic.
    _computeChildOffsets();
    span.end(extra: 'size=${size.width.toInt()}x${size.height.toInt()}');
  }

  void _computeChildOffsets() {
    if (children.isEmpty) return;

    final flexData = children.map(_flexDataFor).toList();
    final maxMain = size.height.toInt();
    final childHeights = <double>[];

    // Replicate the flex sizing logic to get actual child heights.
    final rawHeights = children.map((c) => c.size.height.toInt()).toList();
    final totalFlex = flexData.fold<int>(0, (sum, f) => sum + f.flex);
    final contentMain = rawHeights.fold<int>(0, (sum, h) => sum + h);
    final totalWithGap = contentMain + gap * (children.length - 1);
    final flexExtra = math.max(0, maxMain - totalWithGap);

    for (var i = 0; i < children.length; i++) {
      final data = flexData[i];
      var h = rawHeights[i].toDouble();
      if (totalFlex > 0 && data.flex > 0 && data.fit == RenderFlexFit.tight) {
        h += (flexExtra * data.flex) ~/ totalFlex;
      }
      childHeights.add(h);
    }

    // Compute main-axis spacing (matches _computeSpacing + _joinVerticalWithSpacing).
    final totalMain = childHeights.fold<double>(0, (s, h) => s + h);
    final mainExtra = math.max(
      0.0,
      maxMain - totalMain - gap * (children.length - 1),
    );
    final spacing = _computeSpacing(
      children.length,
      gap,
      mainExtra.toInt(),
      mainAxisAlignment,
    );

    // Compute cross-axis offsets per child (matches _applyCrossAlignmentHorizontal).
    final maxCross = size.width.toInt();

    var y = spacing.leading.toDouble();
    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      final childWidth = child.size.width;

      final crossOffset = switch (crossAxisAlignment) {
        RenderCrossAxisAlignment.start => 0.0,
        RenderCrossAxisAlignment.end => maxCross - childWidth,
        RenderCrossAxisAlignment.center => (maxCross - childWidth) / 2,
        RenderCrossAxisAlignment.stretch => 0.0,
      };

      child.offset = Offset(crossOffset, y);

      y += childHeights[i];
      if (i < spacing.between.length) {
        y += spacing.between[i];
      }
    }
  }

  @override
  String paint() {
    if (children.isEmpty) return '';
    final span = TuiTrace.begin(
      'RenderColumn.paint',
      tag: TraceTag.paint,
      extra: 'children=${children.length}',
    );
    final blocks = children.map((c) => c.paint()).toList(growable: false);
    final flexData = children.map(_flexDataFor).toList(growable: false);
    final maxMain = size.height.toInt();
    final maxCross = size.width.toInt();
    final childHeights = children
        .map((c) => c.size.height.toInt())
        .toList(growable: false);
    final childWidths = children
        .map((c) => c.size.width.toInt())
        .toList(growable: false);

    final totalFlex = flexData.fold<int>(0, (sum, f) => sum + f.flex);
    final adjusted = List<String>.of(blocks, growable: false);
    final adjustedHeights = List<int>.of(childHeights, growable: false);

    if (totalFlex > 0) {
      var nonFlexHeight = 0;
      for (var i = 0; i < adjusted.length; i++) {
        if (flexData[i].flex <= 0) nonFlexHeight += adjustedHeights[i];
      }
      final gapTotal = gap * (adjusted.length - 1);
      final available = math.max(0, maxMain - nonFlexHeight - gapTotal);

      for (var i = 0; i < adjusted.length; i++) {
        final data = flexData[i];
        if (data.flex <= 0 || data.fit == RenderFlexFit.loose) continue;

        final target = (available * data.flex) ~/ totalFlex;
        var block = adjusted[i];
        final currentHeight = adjustedHeights[i];
        if (currentHeight > target) {
          block = Layout.truncateHeight(block, target);
        }
        adjusted[i] = Layout.place(
          width: childWidths[i],
          height: target,
          horizontal: HorizontalAlign.left,
          vertical: VerticalAlign.top,
          content: block,
        );
        adjustedHeights[i] = target;
      }
    }

    final aligned = <String>[];
    final hAlign = switch (crossAxisAlignment) {
      RenderCrossAxisAlignment.start => HorizontalAlign.left,
      RenderCrossAxisAlignment.center => HorizontalAlign.center,
      RenderCrossAxisAlignment.end => HorizontalAlign.right,
      RenderCrossAxisAlignment.stretch => HorizontalAlign.left,
    };

    for (var i = 0; i < adjusted.length; i++) {
      final block = adjusted[i];
      final childWidth = childWidths[i];
      final childHeight = adjustedHeights[i];
      if (hAlign == HorizontalAlign.left && childWidth == maxCross) {
        aligned.add(block);
      } else {
        aligned.add(
          Layout.place(
            width: maxCross,
            height: childHeight,
            horizontal: hAlign,
            vertical: VerticalAlign.top,
            content: block,
          ),
        );
      }
    }

    final totalMain =
        adjustedHeights.fold<int>(0, (sum, h) => sum + h) +
        gap * (children.length - 1);
    final extra = math.max(0, maxMain - totalMain);
    final spacing = _computeSpacing(
      children.length,
      gap,
      extra,
      mainAxisAlignment,
    );

    final result = Layout.place(
      width: maxCross,
      height: maxMain,
      horizontal: HorizontalAlign.left,
      vertical: VerticalAlign.top,
      content: _joinVerticalWithSpacing(aligned, spacing),
    );
    span.end(extra: 'size=${size.width.toInt()}x${size.height.toInt()}');
    return result;
  }
}

/// Parent-data used by flex containers for each child render object.
class FlexParentData {
  /// Creates flex parent data.
  const FlexParentData({required this.flex, required this.fit});

  /// Flex factor used to divide remaining main-axis space.
  final int flex;

  /// Fit behavior when a positive [flex] is provided.
  final RenderFlexFit fit;
}

FlexParentData _flexDataFor(RenderObject child) {
  final data = child.parentData;
  if (data is FlexParentData) return data;
  return const FlexParentData(flex: 0, fit: RenderFlexFit.loose);
}

class _FlexSpacing {
  _FlexSpacing(this.leading, this.between, this.trailing);

  final int leading;
  final List<int> between;
  final int trailing;
}

_FlexSpacing _computeSpacing(
  int count,
  int baseGap,
  int extra,
  RenderMainAxisAlignment alignment,
) {
  if (count <= 1) {
    return _FlexSpacing(0, const [], 0);
  }

  switch (alignment) {
    case RenderMainAxisAlignment.start:
      return _FlexSpacing(0, List.filled(count - 1, baseGap), 0);
    case RenderMainAxisAlignment.end:
      return _FlexSpacing(extra, List.filled(count - 1, baseGap), 0);
    case RenderMainAxisAlignment.center:
      final lead = extra ~/ 2;
      return _FlexSpacing(lead, List.filled(count - 1, baseGap), extra - lead);
    case RenderMainAxisAlignment.spaceBetween:
      final total = baseGap * (count - 1) + extra;
      final base = count > 1 ? total ~/ (count - 1) : 0;
      final leftover = count > 1 ? total % (count - 1) : 0;
      final gaps = List<int>.generate(
        count - 1,
        (i) => base + (i < leftover ? 1 : 0),
      );
      return _FlexSpacing(0, gaps, 0);
    case RenderMainAxisAlignment.spaceAround:
      final total = baseGap * (count - 1) + extra;
      final base = total ~/ count;
      final leftover = total % count;
      final leading = base ~/ 2;
      final trailing = base - leading;
      final gaps = List<int>.generate(
        count - 1,
        (i) => base + (i < leftover ? 1 : 0),
      );
      return _FlexSpacing(leading, gaps, trailing);
    case RenderMainAxisAlignment.spaceEvenly:
      final total = baseGap * (count - 1) + extra;
      final base = total ~/ (count + 1);
      final leftover = total % (count + 1);
      final leading = base + (leftover > 0 ? 1 : 0);
      final gaps = List<int>.generate(
        count - 1,
        (i) => base + (i + 1 < leftover ? 1 : 0),
      );
      final trailing = base + (leftover > count ? 1 : 0);
      return _FlexSpacing(leading, gaps, trailing);
  }
}

String _joinHorizontalWithSpacing(List<String> blocks, _FlexSpacing spacing) {
  if (blocks.isEmpty) return '';
  final spaced = <String>[];
  if (spacing.leading > 0) {
    spaced.add(' ' * spacing.leading);
  }

  for (var i = 0; i < blocks.length; i++) {
    spaced.add(blocks[i]);
    if (i < spacing.between.length && spacing.between[i] > 0) {
      spaced.add(' ' * spacing.between[i]);
    }
  }

  if (spacing.trailing > 0) {
    spaced.add(' ' * spacing.trailing);
  }

  return Layout.joinHorizontal(VerticalAlign.top, spaced, gap: 0);
}

String _joinVerticalWithSpacing(List<String> blocks, _FlexSpacing spacing) {
  if (blocks.isEmpty) return '';
  final spaced = <String>[];
  if (spacing.leading > 0) {
    spaced.add(List.filled(spacing.leading, '').join('\n'));
  }

  for (var i = 0; i < blocks.length; i++) {
    spaced.add(blocks[i]);
    if (i < spacing.between.length && spacing.between[i] > 0) {
      spaced.add(List.filled(spacing.between[i], '').join('\n'));
    }
  }

  if (spacing.trailing > 0) {
    spaced.add(List.filled(spacing.trailing, '').join('\n'));
  }

  return spaced.join('\n');
}
