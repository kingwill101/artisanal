import 'dart:math' as math;

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart';

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

  RenderObject? get _child => children.isEmpty ? null : children.first;

  @override
  void layout(BoxConstraints constraints) {
    final span = TuiTrace.begin(
      'RenderContainer.layout',
      tag: TraceTag.layout,
      extra: 'w=$width h=$height',
    );
    super.layout(constraints);

    // Compute the decoration overhead (padding + border + margin) so we can
    // deflate child constraints — matching Flutter's RenderPadding behaviour.
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

    // Overhead inside the container box that reduces space available to child.
    // Margin is outside the container and must not constrain the child.
    final innerOverheadH = padH + bdrH;
    final innerOverheadV = padV + bdrV;

    var childConstraints = constraints;
    if (width != null || height != null) {
      childConstraints = BoxConstraints(
        minWidth: math.max(
          0,
          (width?.toDouble() ?? constraints.minWidth) - innerOverheadH,
        ),
        maxWidth: math.max(
          0,
          (width?.toDouble() ?? constraints.maxWidth) - innerOverheadH,
        ),
        minHeight: math.max(
          0,
          (height?.toDouble() ?? constraints.minHeight) - innerOverheadV,
        ),
        maxHeight: math.max(
          0,
          (height?.toDouble() ?? constraints.maxHeight) - innerOverheadV,
        ),
      );
    } else if (alignment != null) {
      // Alignment is set — loosen min constraints so the child can size
      // naturally and then be positioned within the container.  This
      // matches Flutter's Container behaviour with alignment.
      childConstraints = BoxConstraints(
        minWidth: 0,
        maxWidth: math.max(0, constraints.maxWidth - innerOverheadH),
        minHeight: 0,
        maxHeight: math.max(0, constraints.maxHeight - innerOverheadV),
      );
    } else {
      // No explicit size, no alignment — propagate parent constraints
      // through (deflated by padding/border/margin overhead) so that
      // children see the same tightness the parent intended.  This
      // matches Flutter behaviour where a Container with only `color`
      // (or padding) is constraint-transparent.
      childConstraints = BoxConstraints(
        minWidth: math.max(0, constraints.minWidth - innerOverheadH),
        maxWidth: math.max(0, constraints.maxWidth - innerOverheadH),
        minHeight: math.max(0, constraints.minHeight - innerOverheadV),
        maxHeight: math.max(0, constraints.maxHeight - innerOverheadV),
      );
    }
    _child?.layout(childConstraints);
    final contentW = _child?.size.width.toInt() ?? 0;
    final contentH = _child?.size.height.toInt() ?? 0;

    // Compute the natural total size that renderContainerContent would
    // produce when width/height are null, accounting for padding, border,
    // and margin — mirroring the same arithmetic in renderContainerContent.
    final naturalInnerW = (width != null)
        ? resolveDimension(width)!
        : (contentW + padH + bdrH);
    final naturalInnerH = (height != null)
        ? resolveDimension(height)!
        : (contentH + padV + bdrV);
    final naturalTotalW = naturalInnerW + mrgH;
    final naturalTotalH = naturalInnerH + mrgV;

    final constrained = constraints.constrain(
      Size(naturalTotalW.toDouble(), naturalTotalH.toDouble()),
    );

    // Ensure the render dimensions match the constrained size so the
    // Canvas output never exceeds the constraints.  This handles both
    // when constraints force a *larger* size (expansion) and when they
    // force a *smaller* size (clamping) than the natural dimensions.
    num? renderWidth = width;
    num? renderHeight = height;
    if (width == null && constrained.width != naturalTotalW) {
      renderWidth = constrained.width - mrgH;
    }
    if (height == null && constrained.height != naturalTotalH) {
      renderHeight = constrained.height - mrgV;
    }

    _resolvedWidth = renderWidth;
    _resolvedHeight = renderHeight;
    size = constraints.constrain(
      Size(
        (renderWidth != null
                ? resolveDimension(renderWidth) ?? 0
                : naturalInnerW) +
            mrgH.toDouble(),
        (renderHeight != null
                ? resolveDimension(renderHeight) ?? 0
                : naturalInnerH) +
            mrgV.toDouble(),
      ),
    );

    // Set child offset to match where renderContainerContent places the
    // content on the canvas: margin + border + padding + alignment.
    if (_child != null) {
      final resolvedW = resolveDimension(renderWidth);
      final resolvedH = resolveDimension(renderHeight);

      final resolvedAlign = alignment == null
          ? align
          : horizontalFromAlignment(alignment!);
      final resolvedVertical = alignment == null
          ? verticalAlign
          : verticalFromAlignment(alignment!);

      final availW = resolvedW != null
          ? math.max(0, resolvedW - padLeft - padRight - bdrH)
          : 0;
      final availH = resolvedH != null
          ? math.max(0, resolvedH - padTop - padBottom - bdrV)
          : 0;

      final alignedX = resolvedW != null
          ? offsetForHorizontal(resolvedAlign, availW, contentW)
          : 0;
      final alignedY = resolvedH != null
          ? offsetForVertical(resolvedVertical, availH, contentH)
          : 0;

      _child!.offset = Offset(
        (mrgLeft + bdrLeft + padLeft + alignedX).toDouble(),
        (mrgTop + bdrTop + padTop + alignedY).toDouble(),
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
    final key = (
      content,
      padding,
      margin,
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
      margin: margin,
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
