import 'dart:math' as math;
import 'package:artisanal/style.dart' hide Padding, Align;
import 'geometry.dart';
import '../rendering/render_object.dart';
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
    _child?.layout(constraints.loosen());

    final child = _child;
    final content = child?.paint() ?? '';
    final contentWidth = Layout.getWidth(content);
    final contentHeight = Layout.getHeight(content);

    // Match Flutter Align/Center semantics: when width/height factors are not
    // provided, expand to fill bounded constraints; otherwise shrink-wrap.
    final resolvedWidth =
        resolveDimension(width) ??
        (constraints.hasBoundedWidth
            ? constraints.maxWidth.toInt()
            : contentWidth);
    final resolvedHeight =
        resolveDimension(height) ??
        (constraints.hasBoundedHeight
            ? constraints.maxHeight.toInt()
            : contentHeight);

    if (child != null) {
      final resolvedAlign = alignment == null
          ? align
          : horizontalFromAlignment(alignment!);
      final resolvedVertical = alignment == null
          ? verticalAlign
          : verticalFromAlignment(alignment!);

      final maxDx = math.max(0, resolvedWidth - contentWidth);
      final maxDy = math.max(0, resolvedHeight - contentHeight);
      final dx = switch (resolvedAlign) {
        HorizontalAlign.left => 0,
        HorizontalAlign.center => maxDx ~/ 2,
        HorizontalAlign.right => maxDx,
      };
      final dy = switch (resolvedVertical) {
        VerticalAlign.top => 0,
        VerticalAlign.center => maxDy ~/ 2,
        VerticalAlign.bottom => maxDy,
      };

      child.offset = Offset(dx.toDouble(), dy.toDouble());
    }

    final rendered = _renderAligned(content);
    _lastPaint = rendered;
    size = constraints.constrain(
      Size(
        Layout.getWidth(rendered).toDouble(),
        Layout.getHeight(rendered).toDouble(),
      ),
    );
  }

  @override
  String paint() {
    final cached = _lastPaint;
    if (cached != null) return cached;
    final content = _child?.paint() ?? '';
    return _renderAligned(content);
  }

  String _renderAligned(String content) {
    final contentWidth = Layout.getWidth(content);
    final contentHeight = Layout.getHeight(content);
    // Match Flutter Align/Center semantics: when width/height factors are not
    // provided, expand to fill bounded constraints; otherwise shrink-wrap.
    final resolvedWidth =
        resolveDimension(width) ??
        (constraints.hasBoundedWidth
            ? constraints.maxWidth.toInt()
            : contentWidth);
    final resolvedHeight =
        resolveDimension(height) ??
        (constraints.hasBoundedHeight
            ? constraints.maxHeight.toInt()
            : contentHeight);
    final resolvedAlign = alignment == null
        ? align
        : horizontalFromAlignment(alignment!);
    final resolvedVertical = alignment == null
        ? verticalAlign
        : verticalFromAlignment(alignment!);
    return Layout.place(
      width: resolvedWidth,
      height: resolvedHeight,
      horizontal: resolvedAlign,
      vertical: resolvedVertical,
      content: content,
    );
  }
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
    final content = child == null ? '' : renderWidget(child!);
    final resolvedWidth = resolveDimension(width) ?? Layout.getWidth(content);
    final resolvedHeight =
        resolveDimension(height) ?? Layout.getHeight(content);
    final resolvedAlign = alignment == null
        ? align
        : horizontalFromAlignment(alignment!);
    final resolvedVertical = alignment == null
        ? verticalAlign
        : verticalFromAlignment(alignment!);
    return Layout.place(
      width: resolvedWidth,
      height: resolvedHeight,
      horizontal: resolvedAlign,
      vertical: resolvedVertical,
      content: content,
    );
  }
}
