import 'dart:math' as math;

import 'package:artisanal/uv.dart' show StyledString, Canvas, UvStyle;

import '../core/widget.dart';
import '../rendering/render_object.dart';
import '_layout_utils.dart';
import 'enums.dart';
import 'geometry.dart';
import 'positioned.dart';
import 'spacing.dart';

void _checkStackClipping(Overflow value) {
  if (value != Overflow.clip) {
    throw UnsupportedError(
      'Stack supports Overflow.clip only. Use an Overlay for content '
      'outside the stack bounds.',
    );
  }
}

int? _stackInset(num? value) =>
    value == null || !value.isFinite ? null : value.round();

double? _stackExtent(num? value, double available) {
  final resolved = resolveDimensionDouble(value);
  if (resolved == null) return null;
  if (resolved.isInfinite) return available.isFinite ? available : null;
  return math.max(0.0, resolved.roundToDouble());
}

class StackParentData {
  const StackParentData({
    this.left,
    this.right,
    this.top,
    this.bottom,
    this.width,
    this.height,
  });

  final num? left;
  final num? right;
  final num? top;
  final num? bottom;
  final num? width;
  final num? height;

  bool get isPositioned {
    return left != null ||
        right != null ||
        top != null ||
        bottom != null ||
        width != null ||
        height != null;
  }
}

class RenderStack extends RenderBox {
  RenderStack({
    this.width,
    this.height,
    this.alignment = Alignment.topLeft,
    this.fit = StackFit.loose,
    Overflow clipBehavior = Overflow.clip,
  }) : _clipBehavior = clipBehavior {
    _checkStackClipping(clipBehavior);
  }

  num? width;
  num? height;
  Alignment alignment;
  StackFit fit;
  Overflow _clipBehavior;

  /// Clipping policy. Visible overflow requires an ancestor Overlay instead.
  Overflow get clipBehavior => _clipBehavior;

  set clipBehavior(Overflow value) {
    _checkStackClipping(value);
    _clipBehavior = value;
  }

  Offset _resolveChildOffset(
    RenderObject child,
    StackParentData? data,
    int targetWidth,
    int targetHeight,
  ) {
    final childWidth = child.size.width.toInt();
    final childHeight = child.size.height.toInt();

    if (data != null && data.isPositioned) {
      final left = _stackInset(data.left);
      final right = _stackInset(data.right);
      final top = _stackInset(data.top);
      final bottom = _stackInset(data.bottom);

      final x =
          left ??
          (right != null
              ? targetWidth - childWidth - right
              : ((alignment.x + 1) / 2 * (targetWidth - childWidth)).round());
      final y =
          top ??
          (bottom != null
              ? targetHeight - childHeight - bottom
              : ((alignment.y + 1) / 2 * (targetHeight - childHeight)).round());
      return Offset(x.toDouble(), y.toDouble());
    }

    return Offset(
      ((alignment.x + 1) / 2 * (targetWidth - childWidth)).round().toDouble(),
      ((alignment.y + 1) / 2 * (targetHeight - childHeight)).round().toDouble(),
    );
  }

  @override
  void layout(BoxConstraints constraints) {
    super.layout(constraints);
    final requestedWidth = _stackExtent(width, constraints.maxWidth);
    final requestedHeight = _stackExtent(height, constraints.maxHeight);
    final boxConstraints = BoxConstraints(
      minWidth: requestedWidth ?? 0,
      maxWidth: requestedWidth ?? double.infinity,
      minHeight: requestedHeight ?? 0,
      maxHeight: requestedHeight ?? double.infinity,
    ).enforce(constraints);
    var maxWidth = 0.0;
    var maxHeight = 0.0;
    final isExpand = fit == StackFit.expand;
    final expandWidth = isExpand && boxConstraints.hasBoundedWidth
        ? boxConstraints.maxWidth
        : null;
    final expandHeight = isExpand && boxConstraints.hasBoundedHeight
        ? boxConstraints.maxHeight
        : null;
    final nonPositionedConstraints = switch (fit) {
      StackFit.loose => boxConstraints.loosen(),
      StackFit.expand => BoxConstraints(
        minWidth: expandWidth ?? 0,
        maxWidth: boxConstraints.maxWidth,
        minHeight: expandHeight ?? 0,
        maxHeight: boxConstraints.maxHeight,
      ),
      StackFit.passthrough => boxConstraints,
    };
    var hasNonPositionedChild = false;

    for (final child in children) {
      final data = child.parentData as StackParentData?;
      if (data != null && data.isPositioned) {
        continue;
      }
      child.layout(nonPositionedConstraints);
      hasNonPositionedChild = true;
      maxWidth = math.max(maxWidth, child.size.width);
      maxHeight = math.max(maxHeight, child.size.height);
    }

    var resolvedWidth =
        requestedWidth ??
        (expandWidth ??
            (hasNonPositionedChild
                ? maxWidth
                : boxConstraints.hasBoundedWidth
                ? boxConstraints.maxWidth
                : 0.0));
    var resolvedHeight =
        requestedHeight ??
        (expandHeight ??
            (hasNonPositionedChild
                ? maxHeight
                : boxConstraints.hasBoundedHeight
                ? boxConstraints.maxHeight
                : 0.0));

    if (resolvedWidth.isInfinite) {
      resolvedWidth = maxWidth;
    }
    if (resolvedHeight.isInfinite) {
      resolvedHeight = maxHeight;
    }

    // Positioned stretches and offsets must use the same allocated rectangle
    // that painting and hit testing use, not an unclamped size request.
    size = boxConstraints.constrain(Size(resolvedWidth, resolvedHeight));
    resolvedWidth = size.width;
    resolvedHeight = size.height;

    // Positioned children paint over the stack's resolved size but do not
    // contribute to it in loose mode.
    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      final data = child.parentData as StackParentData?;
      if (data != null && data.isPositioned) {
        final left = _stackInset(data.left);
        final right = _stackInset(data.right);
        final top = _stackInset(data.top);
        final bottom = _stackInset(data.bottom);
        final childWidth =
            resolveDimension(data.width)?.toDouble() ??
            (left != null && right != null
                ? math.max(0, resolvedWidth - left - right)
                : null);
        final childHeight =
            resolveDimension(data.height)?.toDouble() ??
            (top != null && bottom != null
                ? math.max(0, resolvedHeight - top - bottom)
                : null);
        final childConstraints = BoxConstraints(
          minWidth: childWidth ?? 0,
          maxWidth: childWidth ?? resolvedWidth,
          minHeight: childHeight ?? 0,
          maxHeight: childHeight ?? resolvedHeight,
        );
        child.layout(childConstraints);
      }
    }

    final targetWidth = size.width.toInt();
    final targetHeight = size.height.toInt();
    for (final child in children) {
      final data = child.parentData as StackParentData?;
      child.offset = _resolveChildOffset(
        child,
        data,
        targetWidth,
        targetHeight,
      );
    }
  }

  @override
  String paint() {
    if (children.isEmpty) return '';
    final targetWidth = size.width.toInt();
    final targetHeight = size.height.toInt();
    if (targetWidth == 0 || targetHeight == 0) return '';

    final canvas = Canvas(targetWidth, targetHeight);
    try {
      final bgStyle = const UvStyle();

      var isFirstChild = true;
      for (final child in children) {
        final content = child.paint();
        final childWidth = child.size.width.toInt();
        final childHeight = child.size.height.toInt();
        final x = child.offset.dx.toInt();
        final y = child.offset.dy.toInt();

        if (isFirstChild &&
            x == 0 &&
            y == 0 &&
            childWidth == targetWidth &&
            childHeight == targetHeight) {
          // First child fills the entire canvas — draw StyledString directly
          // onto the main canvas, skipping the temp canvas + cell-by-cell copy.
          StyledString(content).draw(canvas, canvas.bounds());
        } else {
          drawStyledContent(
            canvas,
            content,
            x,
            y,
            bgStyle,
            transparent: !isFirstChild,
            contentWidth: childWidth,
            contentHeight: childHeight,
          );
        }
        isFirstChild = false;
      }

      var result = canvas.render();
      result = padToStackSize(result, targetWidth, targetHeight);
      return result;
    } finally {
      // The canvas owns its backing ScreenBuffer. The rendered string is
      // extracted above, so releasing the cells cannot affect the result.
      canvas.dispose();
    }
  }
}

class Stack extends MultiChildRenderObjectWidget {
  Stack({
    required super.children,
    this.width,
    this.height,
    this.alignment = Alignment.topLeft,
    this.fit = StackFit.loose,
    this.clipBehavior = Overflow.clip,
    super.key,
  }) {
    _checkStackClipping(clipBehavior);
  }

  final num? width;
  final num? height;
  final Alignment alignment;
  final StackFit fit;

  /// Only [Overflow.clip] is supported by the bounded stack compositor.
  ///
  /// Requesting [Overflow.visible] throws [UnsupportedError]. Use an Overlay
  /// to place popups outside a component's bounds.
  final Overflow clipBehavior;

  @override
  RenderObject createRenderObject() {
    return RenderStack(
      width: width,
      height: height,
      alignment: alignment,
      fit: fit,
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(RenderObject renderObject) {
    final stack = renderObject as RenderStack;
    stack
      ..width = width
      ..height = height
      ..alignment = alignment
      ..fit = fit
      ..clipBehavior = clipBehavior;
  }

  @override
  Object view() {
    final render = RenderStack(
      width: width,
      height: height,
      alignment: alignment,
      fit: fit,
      clipBehavior: clipBehavior,
    );
    for (final child in children) {
      final renderChild = RenderDelegateBox(() => renderWidget(child));
      final info = _stackInfoFor(child);
      if (info != null) {
        renderChild.parentData = info;
      }
      render.attach(renderChild);
    }
    render.layout(BoxConstraints());
    return render.paint();
  }
}

StackParentData? _stackInfoFor(Widget widget) {
  if (widget is Positioned) {
    return StackParentData(
      left: widget.left,
      right: widget.right,
      top: widget.top,
      bottom: widget.bottom,
      width: widget.width,
      height: widget.height,
    );
  }
  return null;
}
