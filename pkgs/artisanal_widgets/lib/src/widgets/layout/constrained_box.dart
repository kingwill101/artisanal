import 'dart:math' as math;

import 'package:artisanal/style.dart' hide Padding, Align;

import '../rendering/render_object.dart';
import '_layout_utils.dart';
import 'geometry.dart';

class RenderConstrainedBox extends RenderBox {
  RenderConstrainedBox({required this.additionalConstraints});

  BoxConstraints additionalConstraints;
  String? _lastPaint;

  RenderObject? get _child => children.isEmpty ? null : children.first;

  @override
  void layout(BoxConstraints constraints) {
    final combined = BoxConstraints(
      minWidth: math.max(constraints.minWidth, additionalConstraints.minWidth),
      maxWidth: math.min(constraints.maxWidth, additionalConstraints.maxWidth),
      minHeight: math.max(
        constraints.minHeight,
        additionalConstraints.minHeight,
      ),
      maxHeight: math.min(
        constraints.maxHeight,
        additionalConstraints.maxHeight,
      ),
    );
    super.layout(combined);
    _child?.layout(combined);
    final rendered = constrainContent(
      _child?.paint() ?? '',
      width: combined.hasBoundedWidth ? combined.maxWidth.toInt() : null,
      height: combined.hasBoundedHeight ? combined.maxHeight.toInt() : null,
    );
    _lastPaint = rendered;
    size = combined.constrain(
      Size(
        Layout.getWidth(rendered).toDouble(),
        Layout.getHeight(rendered).toDouble(),
      ),
    );
  }

  @override
  String paint() => _lastPaint ?? _child?.paint() ?? '';
}

class ConstrainedBox extends SingleChildRenderObjectWidget {
  ConstrainedBox({required this.constraints, super.child, super.key});

  final BoxConstraints constraints;

  @override
  RenderObject createRenderObject() {
    return RenderConstrainedBox(additionalConstraints: constraints);
  }

  @override
  void updateRenderObject(RenderObject renderObject) {
    (renderObject as RenderConstrainedBox).additionalConstraints = constraints;
  }

  @override
  Object view() {
    final content = child == null ? '' : renderWidget(child!);
    final width = constraints.hasBoundedWidth
        ? constraints.maxWidth.toInt()
        : null;
    final height = constraints.hasBoundedHeight
        ? constraints.maxHeight.toInt()
        : null;
    return constrainContent(content, width: width, height: height);
  }
}
