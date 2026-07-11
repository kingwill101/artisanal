import '../rendering/render_object.dart';
import '_layout_utils.dart';
import 'geometry.dart';

class RenderSizedBox extends RenderBox {
  RenderSizedBox({this.width, this.height});

  num? width;
  num? height;
  String? _lastPaint;

  RenderObject? get _child => children.isEmpty ? null : children.first;

  @override
  void layout(BoxConstraints constraints) {
    super.layout(constraints);

    final targetWidth = resolveDimension(width)?.toDouble();
    final targetHeight = resolveDimension(height)?.toDouble();

    final childConstraints = BoxConstraints(
      minWidth: targetWidth ?? constraints.minWidth,
      maxWidth: targetWidth ?? constraints.maxWidth,
      minHeight: targetHeight ?? constraints.minHeight,
      maxHeight: targetHeight ?? constraints.maxHeight,
    );

    _child?.layout(childConstraints);

    final rendered = constrainContent(
      _child?.paint() ?? '',
      width: targetWidth?.toInt(),
      height: targetHeight?.toInt(),
    );
    _lastPaint = rendered;

    final measured = constraints.constrain(
      Size(
        targetWidth ?? _child?.size.width ?? 0,
        targetHeight ?? _child?.size.height ?? 0,
      ),
    );

    size = constraints.constrain(Size(measured.width, measured.height));
  }

  @override
  String paint() {
    final cached = _lastPaint;
    if (cached != null) return cached;
    return _renderSized(_child?.paint() ?? '');
  }

  String _renderSized(String content) {
    final targetWidth = resolveDimension(width);
    final targetHeight = resolveDimension(height);
    return constrainContent(content, width: targetWidth, height: targetHeight);
  }
}

class SizedBox extends SingleChildRenderObjectWidget {
  SizedBox({this.width, this.height, super.child, super.key});

  SizedBox.square({required num dimension, super.child, super.key})
    : width = dimension,
      height = dimension;

  SizedBox.shrink({super.child, super.key}) : width = 0, height = 0;

  final num? width;
  final num? height;

  @override
  RenderObject createRenderObject() {
    return RenderSizedBox(width: width, height: height);
  }

  @override
  void updateRenderObject(RenderObject renderObject) {
    final box = renderObject as RenderSizedBox;
    box
      ..width = width
      ..height = height;
  }

  @override
  Object view() {
    final content = child == null ? '' : renderWidget(child!);
    return constrainContent(
      content,
      width: resolveDimension(width),
      height: resolveDimension(height),
    );
  }
}
