import 'dart:math' as math;
import 'package:artisanal/style.dart' hide Padding, Align;
import 'geometry.dart';
import '../rendering/render_object.dart';
import '../core/element.dart' show ElementTree, elementOf;
import 'spacing.dart';

import '_layout_utils.dart';

class RenderAlign extends RenderBox {
  RenderAlign({
    this.alignment,
    this.align = HorizontalAlign.left,
    this.verticalAlign = VerticalAlign.top,
    this.width,
    this.height,
  });

  Alignment? alignment;
  HorizontalAlign align;
  VerticalAlign verticalAlign;
  num? width;
  num? height;
  String? _lastPaint;

  RenderObject? get _child => children.isEmpty ? null : children.first;

  @override
  void layout(BoxConstraints constraints) {
    super.layout(constraints);
    final child = _child;
    final requestedWidth = resolveDimension(width);
    final requestedHeight = resolveDimension(height);
    // Resolve the allocation before laying out the child. This is important
    // for explicit dimensions: a child must see the same width that Align
    // eventually paints, rather than the parent's (possibly much larger)
    // maximum.
    final targetWidth = _targetDimension(requestedWidth, constraints, true);
    final targetHeight = _targetDimension(requestedHeight, constraints, false);
    final childMaxWidth = targetWidth?.toDouble() ?? double.infinity;
    final childMaxHeight = targetHeight?.toDouble() ?? double.infinity;
    child?.layout(
      BoxConstraints(maxWidth: childMaxWidth, maxHeight: childMaxHeight),
    );

    final resolvedWidth = _allocatedDimension(
      targetWidth,
      constraints,
      child?.size.width,
      axisWidth: true,
    );
    final resolvedHeight = _allocatedDimension(
      targetHeight,
      constraints,
      child?.size.height,
      axisWidth: false,
    );
    size = Size(resolvedWidth.toDouble(), resolvedHeight.toDouble());

    if (child != null) {
      child.offset = _offsetFor(
        child.size,
        size,
        horizontal: _resolvedHorizontal,
        vertical: _resolvedVertical,
      );
    }
    _lastPaint = _renderAligned(
      child?.paint() ?? '',
      childSize: child?.size ?? Size.zero,
      allocatedSize: size,
    );
  }

  @override
  String paint() {
    final cached = _lastPaint;
    if (cached != null) return cached;
    final child = _child;
    return _renderAligned(
      child?.paint() ?? '',
      childSize: child?.size ?? Size.zero,
      allocatedSize: size,
    );
  }

  String _renderAligned(
    String content, {
    required Size childSize,
    required Size allocatedSize,
  }) => _renderAlignedContent(
    content,
    childSize: childSize,
    allocatedSize: allocatedSize,
    horizontal: _resolvedHorizontal,
    vertical: _resolvedVertical,
  );

  HorizontalAlign get _resolvedHorizontal =>
      alignment == null ? align : horizontalFromAlignment(alignment!);

  VerticalAlign get _resolvedVertical =>
      alignment == null ? verticalAlign : verticalFromAlignment(alignment!);
}

String _renderAlignedContent(
  String content, {
  required Size childSize,
  required Size allocatedSize,
  required HorizontalAlign horizontal,
  required VerticalAlign vertical,
}) {
  final allocatedWidth = math.max(0, allocatedSize.width.round()).toInt();
  final allocatedHeight = math.max(0, allocatedSize.height.round()).toInt();
  final childWidth = math.min(
    math.max(0, childSize.width.round()).toInt(),
    allocatedWidth,
  );
  final childHeight = math.min(
    math.max(0, childSize.height.round()).toInt(),
    allocatedHeight,
  );
  // A render object's size is its allocation, even when its paint is sparse
  // (for example, a background-only child). Establish that box before
  // positioning it so paint and hit testing use the same geometry.
  final fitted = constrainContent(
    content,
    width: childWidth,
    height: childHeight,
  );
  final placed = Layout.place(
    width: allocatedWidth,
    height: allocatedHeight,
    horizontal: horizontal,
    vertical: vertical,
    content: fitted,
  );
  return constrainContent(
    placed,
    width: allocatedWidth,
    height: allocatedHeight,
  );
}

int _allocatedDimension(
  int? target,
  BoxConstraints constraints,
  double? childDimension, {
  required bool axisWidth,
}) {
  if (target != null) return target;
  final measured = childDimension ?? 0;
  return (axisWidth
          ? constraints.constrainWidth(measured)
          : constraints.constrainHeight(measured))
      .round();
}

int? _targetDimension(int? requested, BoxConstraints constraints, bool width) {
  if (requested != null) {
    return (width
            ? constraints.constrainWidth(requested.toDouble())
            : constraints.constrainHeight(requested.toDouble()))
        .round();
  }
  final max = width ? constraints.maxWidth : constraints.maxHeight;
  return max < double.infinity ? max.round() : null;
}

Offset _offsetFor(
  Size child,
  Size allocated, {
  required HorizontalAlign horizontal,
  required VerticalAlign vertical,
}) {
  final dx = math.max(0, allocated.width.round() - child.width.round());
  final dy = math.max(0, allocated.height.round() - child.height.round());
  return Offset(
    switch (horizontal) {
      HorizontalAlign.left => 0,
      HorizontalAlign.center => dx ~/ 2,
      HorizontalAlign.right => dx,
    }.toDouble(),
    switch (vertical) {
      VerticalAlign.top => 0,
      VerticalAlign.center => dy ~/ 2,
      VerticalAlign.bottom => dy,
    }.toDouble(),
  );
}

class Align extends SingleChildRenderObjectWidget {
  Align({
    super.key,
    this.alignment,
    this.align = HorizontalAlign.left,
    this.verticalAlign = VerticalAlign.top,
    this.width,
    this.height,
    super.child,
  });

  final Alignment? alignment;
  final HorizontalAlign align;
  final VerticalAlign verticalAlign;
  final num? width;
  final num? height;

  @override
  RenderObject createRenderObject() {
    return RenderAlign(
      alignment: alignment,
      align: align,
      verticalAlign: verticalAlign,
      width: width,
      height: height,
    );
  }

  @override
  void updateRenderObject(RenderObject renderObject) {
    final box = renderObject as RenderAlign;
    box
      ..alignment = alignment
      ..align = align
      ..verticalAlign = verticalAlign
      ..width = width
      ..height = height;
  }

  @override
  Object view() {
    // Once mounted, layout is the source of truth: in particular, the
    // current parent's bounds may have changed since this widget was created.
    // Reading the existing render object also preserves any stateful child.
    final mounted = elementOf(this)?.renderObject;
    if (mounted is RenderAlign) return mounted.paint();

    // A standalone view still needs layout: explicit width can change child
    // wrapping, and sparse paint is not a measurement of the child's size.
    final tree = ElementTree(this);
    try {
      return tree.render();
    } finally {
      tree.unmount();
    }
  }
}
