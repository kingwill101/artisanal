part of 'layout_widgets.dart';

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
    this.clipBehavior = Overflow.clip,
  });

  num? width;
  num? height;
  Alignment alignment;
  StackFit fit;
  Overflow clipBehavior;

  @override
  void layout(BoxConstraints constraints) {
    super.layout(constraints);
    var maxWidth = 0.0;
    var maxHeight = 0.0;
    final isExpand = fit == StackFit.expand;
    final expandWidth = isExpand && constraints.hasBoundedWidth
        ? constraints.maxWidth
        : null;
    final expandHeight = isExpand && constraints.hasBoundedHeight
        ? constraints.maxHeight
        : null;
    var hasNonPositionedChild = false;

    for (final child in children) {
      final data = child.parentData as StackParentData?;
      if (data != null && data.isPositioned) {
        continue;
      }
      child.layout(
        BoxConstraints(
          minWidth: expandWidth ?? 0,
          maxWidth: expandWidth ?? constraints.maxWidth,
          minHeight: expandHeight ?? 0,
          maxHeight: expandHeight ?? constraints.maxHeight,
        ),
      );
      hasNonPositionedChild = true;
      maxWidth = math.max(maxWidth, child.size.width);
      maxHeight = math.max(maxHeight, child.size.height);
    }

    var resolvedWidth =
        _resolveDimensionDouble(width) ??
        (expandWidth ??
            (hasNonPositionedChild
            ? maxWidth
            : constraints.hasBoundedWidth
            ? constraints.maxWidth
            : 0.0));
    var resolvedHeight =
        _resolveDimensionDouble(height) ??
        (expandHeight ??
            (hasNonPositionedChild
            ? maxHeight
            : constraints.hasBoundedHeight
            ? constraints.maxHeight
            : 0.0));

    if (resolvedWidth.isInfinite) {
      resolvedWidth = maxWidth;
    }
    if (resolvedHeight.isInfinite) {
      resolvedHeight = maxHeight;
    }

    // Positioned children paint over the stack's resolved size but do not
    // contribute to it in loose mode.
    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      final data = child.parentData as StackParentData?;
      if (data != null && data.isPositioned) {
        final left = _resolveDimensionDouble(data.left);
        final right = _resolveDimensionDouble(data.right);
        final top = _resolveDimensionDouble(data.top);
        final bottom = _resolveDimensionDouble(data.bottom);
        final childWidth =
            _resolveDimensionDouble(data.width) ??
            (left != null && right != null
                ? math.max(0, resolvedWidth - left - right)
                : null);
        final childHeight =
            _resolveDimensionDouble(data.height) ??
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

    size = constraints.constrain(Size(resolvedWidth, resolvedHeight));
  }

  @override
  String paint() {
    if (children.isEmpty) return '';
    final targetWidth = size.width.toInt();
    final targetHeight = size.height.toInt();
    if (targetWidth == 0 || targetHeight == 0) return '';

    final canvas = Canvas(targetWidth, targetHeight);
    final bgStyle = const UvStyle();

    var isFirstChild = true;
    for (final child in children) {
      final content = child.paint();
      final childWidth = child.size.width.toInt();
      final childHeight = child.size.height.toInt();
      final data = child.parentData as StackParentData?;
      var x = 0;
      var y = 0;

      if (data != null && data.isPositioned) {
        final left = _resolveDimension(data.left);
        final right = _resolveDimension(data.right);
        final top = _resolveDimension(data.top);
        final bottom = _resolveDimension(data.bottom);
        if (left != null) {
          x = left;
        } else if (right != null) {
          x = targetWidth - childWidth - right;
        } else {
          x = ((alignment.x + 1) / 2 * (targetWidth - childWidth)).round();
        }

        if (top != null) {
          y = top;
        } else if (bottom != null) {
          y = targetHeight - childHeight - bottom;
        } else {
          y = ((alignment.y + 1) / 2 * (targetHeight - childHeight)).round();
        }
      } else {
        x = ((alignment.x + 1) / 2 * (targetWidth - childWidth)).round();
        y = ((alignment.y + 1) / 2 * (targetHeight - childHeight)).round();
      }

      if (isFirstChild &&
          x == 0 &&
          y == 0 &&
          childWidth == targetWidth &&
          childHeight == targetHeight) {
        // First child fills the entire canvas — draw StyledString directly
        // onto the main canvas, skipping the temp canvas + cell-by-cell copy.
        StyledString(content).draw(canvas, canvas.bounds());
      } else {
        _drawStyledContent(
          canvas,
          content,
          x,
          y,
          bgStyle,
          transparent: !isFirstChild,
        );
      }
      isFirstChild = false;
    }

    var result = canvas.render();
    result = _padToStackSize(result, targetWidth, targetHeight);
    return result;
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
  });

  final num? width;
  final num? height;
  final Alignment alignment;
  final StackFit fit;
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
      final renderChild = RenderDelegateBox(() => _renderWidget(child));
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
