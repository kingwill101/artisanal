import 'dart:math' as math;

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/runtime.dart';

import '../rendering/render_object.dart';
import '_layout_utils.dart';
import 'geometry.dart';
import 'spacing.dart';

class Decoration {
  const Decoration({this.color});

  final Color? color;
}

class BoxDecoration extends Decoration {
  const BoxDecoration({
    super.color,
    this.border,
    this.borderRadius,
    this.gradient,
  });

  final Border? border;
  final BorderRadius? borderRadius;
  final Gradient? gradient;
}

class BorderRadius {
  const BorderRadius.all(int radius)
    : topLeft = radius,
      topRight = radius,
      bottomLeft = radius,
      bottomRight = radius;

  const BorderRadius.only({
    this.topLeft = 0,
    this.topRight = 0,
    this.bottomLeft = 0,
    this.bottomRight = 0,
  });
  final int topLeft;
  final int topRight;
  final int bottomLeft;
  final int bottomRight;
}

class Gradient {
  const Gradient(this.colors);

  final List<Color> colors;
}

class RenderContainer extends RenderBox {
  RenderContainer({
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.background,
    this.foreground,
    this.color,
    this.decoration,
    this.foregroundDecoration,
    this.alignment,
    this.align = HorizontalAlign.left,
    this.verticalAlign = VerticalAlign.top,
  });

  EdgeInsets? padding;
  EdgeInsets? margin;
  num? width;
  num? height;
  Color? background;
  Color? foreground;
  Color? color;
  Decoration? decoration;
  Decoration? foregroundDecoration;
  Alignment? alignment;
  HorizontalAlign align;
  VerticalAlign verticalAlign;

  String? _lastPaint;
  Object? _lastPaintKey;
  String? _lastChildPaint;
  RenderObject? _lastChildPaintTarget;
  Size? _lastChildPaintSize;
  num? _resolvedWidth;
  num? _resolvedHeight;
  EdgeInsets? _resolvedMargin;

  RenderObject? get _child => children.isEmpty ? null : children.first;

  @override
  void layout(BoxConstraints constraints) {
    final span = TuiTrace.begin(
      'RenderContainer.layout',
      tag: TraceTag.layout,
      extra: 'w=$width h=$height',
    );
    super.layout(constraints);

    // Resolve the outer box before laying out the child.  In particular, an
    // explicit width can still be clipped by the parent's max width; deriving
    // child constraints from the requested width would let the child paint
    // outside the box (and makes wrapping depend on an invisible width).
    final boxDec = decoration is BoxDecoration
        ? decoration as BoxDecoration
        : null;
    final bdr = boxDec?.border;
    final bdrLeft = (bdr != null && bdr.isVisible) ? bdr.getLeftSize() : 0;
    final bdrRight = (bdr != null && bdr.isVisible) ? bdr.getRightSize() : 0;
    final bdrTop = (bdr != null && bdr.isVisible) ? bdr.getTopSize() : 0;
    final bdrBottom = (bdr != null && bdr.isVisible) ? bdr.getBottomSize() : 0;
    final bdrH = bdrLeft + bdrRight;
    final bdrV = bdrTop + bdrBottom;
    final padLeft = roundClamp(padding?.left ?? 0);
    final padRight = roundClamp(padding?.right ?? 0);
    final padTop = roundClamp(padding?.top ?? 0);
    final padBottom = roundClamp(padding?.bottom ?? 0);
    final padH = padLeft + padRight;
    final padV = padTop + padBottom;
    final mrgLeft = roundClamp(margin?.left ?? 0);
    final mrgRight = roundClamp(margin?.right ?? 0);
    final mrgTop = roundClamp(margin?.top ?? 0);
    final mrgBottom = roundClamp(margin?.bottom ?? 0);
    final mrgH = mrgLeft + mrgRight;
    final mrgV = mrgTop + mrgBottom;

    final innerOverheadH = padH + bdrH;
    final innerOverheadV = padV + bdrV;

    double availableMin(double min, double max, int overhead) {
      final availableMax = math.max(0.0, max - overhead);
      return math.min(availableMax, math.max(0.0, min - overhead));
    }

    double availableMax(double max, int overhead) =>
        math.max(0.0, max - overhead);

    final requestedWidth = resolveDimension(width);
    final requestedHeight = resolveDimension(height);
    final allocatedOuterWidth = requestedWidth == null
        ? null
        : constraints.constrainWidth(
            requestedWidth.toDouble() + mrgH.toDouble(),
          );
    final allocatedOuterHeight = requestedHeight == null
        ? null
        : constraints.constrainHeight(
            requestedHeight.toDouble() + mrgV.toDouble(),
          );

    // Margins consume space in the parent, but never space inside the
    // container.  Keep each range valid when overhead exceeds a bound.
    final alignmentLoosensChild = alignment != null;
    final childConstraints = BoxConstraints(
      minWidth: alignmentLoosensChild
          ? 0
          : requestedWidth == null
          ? availableMin(
              constraints.minWidth,
              constraints.maxWidth,
              mrgH + innerOverheadH,
            ).toDouble()
          : math.max(0, allocatedOuterWidth! - mrgH - innerOverheadH),
      maxWidth: requestedWidth == null
          ? availableMax(constraints.maxWidth, mrgH + innerOverheadH)
          : math.max(0, allocatedOuterWidth! - mrgH - innerOverheadH),
      minHeight: alignmentLoosensChild
          ? 0
          : requestedHeight == null
          ? availableMin(
              constraints.minHeight,
              constraints.maxHeight,
              mrgV + innerOverheadV,
            ).toDouble()
          : math.max(0, allocatedOuterHeight! - mrgV - innerOverheadV),
      maxHeight: requestedHeight == null
          ? availableMax(constraints.maxHeight, mrgV + innerOverheadV)
          : math.max(0, allocatedOuterHeight! - mrgV - innerOverheadV),
    );
    _child?.layout(childConstraints);
    final contentW = _child?.size.width.toInt() ?? 0;
    final contentH = _child?.size.height.toInt() ?? 0;

    final naturalOuterWidth = contentW + innerOverheadH + mrgH;
    final naturalOuterHeight = contentH + innerOverheadV + mrgV;
    final outerWidth =
        allocatedOuterWidth ??
        constraints.constrainWidth(naturalOuterWidth.toDouble());
    final outerHeight =
        allocatedOuterHeight ??
        constraints.constrainHeight(naturalOuterHeight.toDouble());
    final renderWidth = math.max(0, outerWidth - mrgH);
    final renderHeight = math.max(0, outerHeight - mrgV);

    // If margins alone exceed the available box, retain their leading portion
    // rather than adding the full requested margins back during painting.
    final effectiveLeft = math.min(mrgLeft, outerWidth.toInt());
    final effectiveTop = math.min(mrgTop, outerHeight.toInt());
    _resolvedMargin = mrgH > outerWidth || mrgV > outerHeight
        ? EdgeInsets.only(
            left: effectiveLeft,
            right: math.min(
              mrgRight,
              math.max(0, outerWidth.toInt() - effectiveLeft),
            ),
            top: effectiveTop,
            bottom: math.min(
              mrgBottom,
              math.max(0, outerHeight.toInt() - effectiveTop),
            ),
          )
        : margin;
    _resolvedWidth = renderWidth;
    _resolvedHeight = renderHeight;
    size = Size(outerWidth, outerHeight);

    // Set child offset to match where renderContainerContent places the
    // content on the canvas: margin + border + padding + alignment.
    if (_child != null) {
      final resolvedAlign = alignment == null
          ? align
          : horizontalFromAlignment(alignment!);
      final resolvedVertical = alignment == null
          ? verticalAlign
          : verticalFromAlignment(alignment!);

      final availW = math
          .max(0, renderWidth - padLeft - padRight - bdrH)
          .toInt();
      final availH = math
          .max(0, renderHeight - padTop - padBottom - bdrV)
          .toInt();

      final alignedX = offsetForHorizontal(resolvedAlign, availW, contentW);
      final alignedY = offsetForVertical(resolvedVertical, availH, contentH);

      _child!.offset = Offset(
        (effectiveLeft + bdrLeft + padLeft + alignedX).toDouble(),
        (effectiveTop + bdrTop + padTop + alignedY).toDouble(),
      );
    }
    span.end(extra: 'size=${size.width.toInt()}x${size.height.toInt()}');
  }

  @override
  String paint() {
    final child = _child;
    String content;
    if (child == null) {
      content = '';
    } else {
      final canReuseChild =
          _lastChildPaint != null &&
          identical(_lastChildPaintTarget, child) &&
          _lastChildPaintSize == child.size &&
          !child.paintDirty;
      if (canReuseChild) {
        content = _lastChildPaint!;
      } else {
        content = child.paint();
        _lastChildPaint = content;
        _lastChildPaintTarget = child;
        _lastChildPaintSize = child.size;
      }
    }
    final widthForPaint = (_resolvedWidth ?? width) ?? size.width.toInt();
    final heightForPaint = (_resolvedHeight ?? height) ?? size.height.toInt();
    final marginForPaint = _resolvedMargin ?? margin;
    final key = (
      content,
      padding,
      marginForPaint,
      widthForPaint,
      heightForPaint,
      background,
      foreground,
      color,
      decoration,
      foregroundDecoration,
      alignment,
      align,
      verticalAlign,
    );

    final cached = _lastPaint;
    if (cached != null && _lastPaintKey == key) return cached;

    final rendered = renderContainerContent(
      contentStr: content,
      padding: padding,
      margin: marginForPaint,
      width: widthForPaint,
      height: heightForPaint,
      background: background,
      foreground: foreground,
      color: color,
      decoration: decoration,
      foregroundDecoration: foregroundDecoration,
      alignment: alignment,
      align: align,
      verticalAlign: verticalAlign,
    );
    _lastPaint = rendered;
    _lastPaintKey = key;
    return rendered;
  }
}

class Container extends SingleChildRenderObjectWidget {
  Container({
    super.key,
    super.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.background,
    this.foreground,
    this.color,
    this.decoration,
    this.foregroundDecoration,
    this.alignment,
    this.align = HorizontalAlign.left,
    this.verticalAlign = VerticalAlign.top,
  });

  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final num? width;
  final num? height;
  final Color? background;
  final Color? foreground;
  final Color? color;
  final Decoration? decoration;
  final Decoration? foregroundDecoration;
  final Alignment? alignment;
  final HorizontalAlign align;
  final VerticalAlign verticalAlign;

  @override
  RenderObject createRenderObject() {
    return RenderContainer(
      padding: padding,
      margin: margin,
      width: width,
      height: height,
      background: background,
      foreground: foreground,
      color: color,
      decoration: decoration,
      foregroundDecoration: foregroundDecoration,
      alignment: alignment,
      align: align,
      verticalAlign: verticalAlign,
    );
  }

  @override
  void updateRenderObject(RenderObject renderObject) {
    final box = renderObject as RenderContainer;
    box
      ..padding = padding
      ..margin = margin
      ..width = width
      ..height = height
      ..background = background
      ..foreground = foreground
      ..color = color
      ..decoration = decoration
      ..foregroundDecoration = foregroundDecoration
      ..alignment = alignment
      ..align = align
      ..verticalAlign = verticalAlign;
  }

  @override
  Object view() => _render();

  String _render() {
    final contentStr = child != null ? renderWidget(child!) : '';
    return renderContainerContent(
      contentStr: contentStr,
      padding: padding,
      margin: margin,
      width: width,
      height: height,
      background: background,
      foreground: foreground,
      color: color,
      decoration: decoration,
      foregroundDecoration: foregroundDecoration,
      alignment: alignment,
      align: align,
      verticalAlign: verticalAlign,
    );
  }
}
