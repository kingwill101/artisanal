part of 'layout_widgets.dart';

/// A widget that fills its area with a single solid color.
///
/// This is a simpler alternative to [Container] when you only need a
/// colored background with no border, padding, or alignment.
///
/// ```dart
/// ColoredBox(
///   color: Colors.blue,
///   child: Text('On blue background'),
/// )
/// ```
class ColoredBox extends SingleChildRenderObjectWidget {
  ColoredBox({required this.color, super.child, super.key});

  /// The background color to fill.
  final Color color;

  @override
  RenderObject createRenderObject() {
    return _RenderColoredBox(color: color);
  }

  @override
  void updateRenderObject(RenderObject renderObject) {
    (renderObject as _RenderColoredBox).color = color;
  }

  @override
  Object view() {
    final content = child != null ? _renderWidget(child!) : '';
    return _renderColoredContent(content, color);
  }
}

class _RenderColoredBox extends RenderBox {
  _RenderColoredBox({required this.color});

  Color color;
  String? _lastPaint;

  RenderObject? get _child => children.isEmpty ? null : children.first;

  @override
  void layout(BoxConstraints constraints) {
    super.layout(constraints);
    _child?.layout(constraints);
    final content = _child?.paint() ?? '';
    _lastPaint = _renderColoredContent(content, color);
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
    return _renderColoredContent(content, color);
  }
}

String _renderColoredContent(String content, Color color) {
  if (content.isEmpty) return '';
  final bgColor = _colorToUvColor(color);
  if (bgColor == null) return content;

  final w = Layout.getWidth(content);
  final h = Layout.getHeight(content);
  if (w == 0 || h == 0) return content;

  final canvas = Canvas(w, h);
  final bgStyle = UvStyle(bg: bgColor);

  // Fill background.
  final bgCell = Cell(content: ' ', width: 1, style: bgStyle);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      canvas.setCell(x, y, bgCell.clone());
    }
  }

  // Draw content on top.
  _drawStyledContent(canvas, content, 0, 0, bgStyle);
  return canvas.render();
}
