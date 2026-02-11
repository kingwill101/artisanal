part of 'layout_widgets.dart';

class RenderPadding extends RenderBox {
  RenderPadding({this.padding});

  EdgeInsets? padding;
  String? _lastPaint;

  RenderObject? get _child => children.isEmpty ? null : children.first;

  @override
  void layout(BoxConstraints constraints) {
    super.layout(constraints);
    _child?.layout(constraints);
    final content = _child?.paint() ?? '';
    final rendered = _renderContainerContent(
      contentStr: content,
      padding: padding,
    );
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
    return _renderContainerContent(contentStr: content, padding: padding);
  }
}

class Padding extends SingleChildRenderObjectWidget {
  Padding({super.key, required this.padding, super.child});

  final EdgeInsets padding;

  @override
  RenderObject createRenderObject() {
    return RenderPadding(padding: padding);
  }

  @override
  void updateRenderObject(RenderObject renderObject) {
    (renderObject as RenderPadding).padding = padding;
  }

  @override
  Object view() => _renderContainerContent(
    contentStr: child == null ? '' : _renderWidget(child!),
    padding: padding,
  );
}
