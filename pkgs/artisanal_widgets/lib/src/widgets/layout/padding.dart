part of 'layout_widgets.dart';

class RenderPadding extends RenderBox {
  RenderPadding({this.padding});

  EdgeInsets? padding;
  String? _lastPaint;

  RenderObject? get _child => children.isEmpty ? null : children.first;

  @override
  void layout(BoxConstraints constraints) {
    super.layout(constraints);
    final padLeft = _roundClamp(padding?.left ?? 0);
    final padRight = _roundClamp(padding?.right ?? 0);
    final padTop = _roundClamp(padding?.top ?? 0);
    final padBottom = _roundClamp(padding?.bottom ?? 0);
    final padH = padLeft + padRight;
    final padV = padTop + padBottom;

    final childConstraints = BoxConstraints(
      minWidth: math.max(0, constraints.minWidth - padH),
      maxWidth: math.max(0, constraints.maxWidth - padH),
      minHeight: math.max(0, constraints.minHeight - padV),
      maxHeight: math.max(0, constraints.maxHeight - padV),
    );

    final child = _child;
    if (child != null) {
      child.layout(childConstraints);
      child.offset = Offset(padLeft.toDouble(), padTop.toDouble());
    }

    size = constraints.constrain(
      Size(
        (child?.size.width ?? 0) + padH.toDouble(),
        (child?.size.height ?? 0) + padV.toDouble(),
      ),
    );

    final content = child?.paint() ?? '';
    final rendered = _renderContainerContent(
      contentStr: content,
      padding: padding,
      width: size.width.toInt(),
      height: size.height.toInt(),
    );
    _lastPaint = Layout.truncateLines(
      rendered,
      size.width.toInt(),
      ellipsis: '',
    );
    size = constraints.constrain(
      Size(
        Layout.getWidth(_lastPaint!).toDouble(),
        Layout.getHeight(_lastPaint!).toDouble(),
      ),
    );
  }

  @override
  String paint() {
    final cached = _lastPaint;
    if (cached != null) return cached;
    final content = _child?.paint() ?? '';
    final rendered = _renderContainerContent(
      contentStr: content,
      padding: padding,
      width: size.width.toInt(),
      height: size.height.toInt(),
    );
    return Layout.truncateLines(rendered, size.width.toInt(), ellipsis: '');
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
