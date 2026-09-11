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
    super.layout(constraints);
    final combined = additionalConstraints.enforce(constraints);
    _child?.layout(combined);
    size = combined.constrain(_child?.size ?? Size.zero);
    final rendered = constrainContent(
      _child?.paint() ?? '',
      width: size.width.isFinite ? size.width.toInt() : null,
      height: size.height.isFinite ? size.height.toInt() : null,
    );
    _lastPaint = rendered;
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
