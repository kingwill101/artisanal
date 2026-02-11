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

enum RenderMainAxisAlignment {
  start,
  end,
  center,
  spaceBetween,
  spaceAround,
  spaceEvenly,
}

enum RenderCrossAxisAlignment { start, end, center, stretch }

enum RenderFlexFit { tight, loose }

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
  RenderRow({
    this.gap = 0,
    this.mainAxisAlignment = RenderMainAxisAlignment.start,
    this.crossAxisAlignment = RenderCrossAxisAlignment.start,
    this.mainAxisSize = RenderMainAxisSize.min,
    this.mainAxisExtent,
    this.crossAxisExtent,
  });

  int gap;
  RenderMainAxisAlignment mainAxisAlignment;
  RenderCrossAxisAlignment crossAxisAlignment;
  RenderMainAxisSize mainAxisSize;
  int? mainAxisExtent;
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
    assert(() {
      final hasTightFlex = flexData.any(
        (f) => f.flex > 0 && f.fit == RenderFlexFit.tight,
      );
      if (hasTightFlex && !constraints.hasBoundedWidth) {
        throw AssertionError(
          'RenderRow has non-zero flex children with unbounded width constraints. '
          'Use MainAxisSize.min, wrap in a bounded parent, or switch flex children to loose fit.',
        );
      }
      return true;
    }());
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
    final blocks = children.map((c) => c.paint()).toList();
    final flexData = children.map(_flexDataFor).toList();
    final maxMain = size.width.toInt();
    final adjusted = _applyFlexRow(blocks, flexData, maxMain, gap);
    final aligned = _applyCrossAlignment(
      adjusted,
      crossAxisAlignment,
      size.height.toInt(),
    );
    final totalMain = _sumMain(aligned) + gap * (children.length - 1);
    final extra = math.max(0, maxMain - totalMain);
    final spacing = _computeSpacing(
      children.length,
      gap,
      extra,
      mainAxisAlignment,
    );

    final result = _joinHorizontalWithSpacing(aligned, spacing);
    span.end(extra: 'size=${size.width.toInt()}x${size.height.toInt()}');
    return result;
  }
}

/// A vertical column layout.
class RenderColumn extends RenderBox {
  RenderColumn({
    this.gap = 0,
    this.mainAxisAlignment = RenderMainAxisAlignment.start,
    this.crossAxisAlignment = RenderCrossAxisAlignment.start,
    this.mainAxisSize = RenderMainAxisSize.min,
    this.mainAxisExtent,
    this.crossAxisExtent,
  });

  int gap;
  RenderMainAxisAlignment mainAxisAlignment;
  RenderCrossAxisAlignment crossAxisAlignment;
  RenderMainAxisSize mainAxisSize;
  int? mainAxisExtent;
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
    final blocks = children.map((c) => c.paint()).toList();
    final flexData = children.map(_flexDataFor).toList();
    final maxMain = size.height.toInt();
    final adjusted = _applyFlexColumn(blocks, flexData, maxMain, gap);
    final aligned = _applyCrossAlignmentHorizontal(
      adjusted,
      crossAxisAlignment,
      size.width.toInt(),
    );
    final totalMain = _sumMainVertical(aligned) + gap * (children.length - 1);
    final extra = math.max(0, maxMain - totalMain);
    final spacing = _computeSpacing(
      children.length,
      gap,
      extra,
      mainAxisAlignment,
    );

    final result = _joinVerticalWithSpacing(aligned, spacing);
    span.end(extra: 'size=${size.width.toInt()}x${size.height.toInt()}');
    return result;
  }
}

class FlexParentData {
  const FlexParentData({required this.flex, required this.fit});

  final int flex;
  final RenderFlexFit fit;
}

FlexParentData _flexDataFor(RenderObject child) {
  final data = child.parentData;
  if (data is FlexParentData) return data;
  return const FlexParentData(flex: 0, fit: RenderFlexFit.loose);
}

int _sumMain(List<String> blocks) {
  return blocks.fold<int>(0, (sum, block) => sum + Layout.getWidth(block));
}

int _sumMainVertical(List<String> blocks) {
  return blocks.fold<int>(0, (sum, block) => sum + Layout.getHeight(block));
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

List<String> _applyCrossAlignment(
  List<String> blocks,
  RenderCrossAxisAlignment alignment,
  int height,
) {
  final vAlign = switch (alignment) {
    RenderCrossAxisAlignment.start => VerticalAlign.top,
    RenderCrossAxisAlignment.center => VerticalAlign.center,
    RenderCrossAxisAlignment.end => VerticalAlign.bottom,
    RenderCrossAxisAlignment.stretch => VerticalAlign.top,
  };

  return blocks.map((block) {
    final width = Layout.getWidth(block);
    return Layout.place(
      width: width,
      height: height,
      horizontal: HorizontalAlign.left,
      vertical: vAlign,
      content: block,
    );
  }).toList();
}

List<String> _applyCrossAlignmentHorizontal(
  List<String> blocks,
  RenderCrossAxisAlignment alignment,
  int width,
) {
  final hAlign = switch (alignment) {
    RenderCrossAxisAlignment.start => HorizontalAlign.left,
    RenderCrossAxisAlignment.center => HorizontalAlign.center,
    RenderCrossAxisAlignment.end => HorizontalAlign.right,
    RenderCrossAxisAlignment.stretch => HorizontalAlign.left,
  };

  return blocks.map((block) {
    final height = Layout.getHeight(block);
    return Layout.place(
      width: width,
      height: height,
      horizontal: hAlign,
      vertical: VerticalAlign.top,
      content: block,
    );
  }).toList();
}

List<String> _applyFlexRow(
  List<String> blocks,
  List<FlexParentData> flexData,
  int? maxMain,
  int gap,
) {
  if (maxMain == null) return blocks;

  final sizes = blocks.map(Layout.getWidth).toList();
  final totalFlex = flexData.fold<int>(0, (sum, f) => sum + f.flex);
  if (totalFlex <= 0) return blocks;

  // Compute space consumed by non-flex children.
  var nonFlexWidth = 0;
  for (var i = 0; i < blocks.length; i++) {
    if (flexData[i].flex <= 0) nonFlexWidth += sizes[i];
  }
  final gapTotal = gap * (blocks.length - 1);
  final available = math.max(0, maxMain - nonFlexWidth - gapTotal);

  final adjusted = <String>[];
  for (var i = 0; i < blocks.length; i++) {
    final data = flexData[i];
    final width = sizes[i];
    if (data.flex <= 0 || data.fit == RenderFlexFit.loose) {
      adjusted.add(blocks[i]);
      continue;
    }

    final target = (available * data.flex) ~/ totalFlex;
    var block = blocks[i];
    // Clip if wider than target, pad if narrower.
    if (width > target) {
      block = Layout.truncateLines(block, target, ellipsis: '');
    }
    adjusted.add(
      Layout.place(
        width: target,
        height: Layout.getHeight(block),
        horizontal: HorizontalAlign.left,
        vertical: VerticalAlign.top,
        content: block,
      ),
    );
  }
  return adjusted;
}

List<String> _applyFlexColumn(
  List<String> blocks,
  List<FlexParentData> flexData,
  int? maxMain,
  int gap,
) {
  if (maxMain == null) return blocks;

  final sizes = blocks.map(Layout.getHeight).toList();
  final totalFlex = flexData.fold<int>(0, (sum, f) => sum + f.flex);
  if (totalFlex <= 0) return blocks;

  // Compute space consumed by non-flex children.
  var nonFlexHeight = 0;
  for (var i = 0; i < blocks.length; i++) {
    if (flexData[i].flex <= 0) nonFlexHeight += sizes[i];
  }
  final gapTotal = gap * (blocks.length - 1);
  final available = math.max(0, maxMain - nonFlexHeight - gapTotal);

  final adjusted = <String>[];
  for (var i = 0; i < blocks.length; i++) {
    final data = flexData[i];
    final height = sizes[i];
    if (data.flex <= 0 || data.fit == RenderFlexFit.loose) {
      adjusted.add(blocks[i]);
      continue;
    }

    final target = (available * data.flex) ~/ totalFlex;
    var block = blocks[i];
    // Clip if taller than target, pad if shorter.
    if (height > target) {
      block = Layout.truncateHeight(block, target);
    }
    adjusted.add(
      Layout.place(
        width: Layout.getWidth(block),
        height: target,
        horizontal: HorizontalAlign.left,
        vertical: VerticalAlign.top,
        content: block,
      ),
    );
  }
  return adjusted;
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
