import 'package:artisanal/style.dart' hide Padding, Align;
import '../core/widget.dart';
import '../rendering/render_object.dart';
import '../theme/theme.dart' show hasDarkBackground;
import '_layout_utils.dart';
import 'geometry.dart';

class _RenderOpacity extends RenderBox {
  _RenderOpacity({required this.opacity});

  double opacity;
  String? _lastPaint;

  RenderObject? get _child => children.isEmpty ? null : children.first;

  @override
  void layout(BoxConstraints constraints) {
    super.layout(constraints);
    _child?.layout(constraints);
    final content = _child?.paint() ?? '';
    if (opacity <= 0) {
      _lastPaint = '';
    } else if (opacity >= 1) {
      _lastPaint = content;
    } else {
      final style = Style().dim();
      style.hasDarkBackground = hasDarkBackground;
      _lastPaint = style.render(content);
    }
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
    if (opacity <= 0) return '';
    if (opacity >= 1) return content;
    final style = Style().dim();
    style.hasDarkBackground = hasDarkBackground;
    return style.render(content);
  }
}

class Opacity extends SingleChildRenderObjectWidget {
  Opacity({required Widget super.child, this.opacity = 1.0, super.key});

  final double opacity;

  @override
  RenderObject createRenderObject() {
    return _RenderOpacity(opacity: opacity);
  }

  @override
  void updateRenderObject(RenderObject renderObject) {
    (renderObject as _RenderOpacity).opacity = opacity;
  }

  @override
  Object view() => _render();

  Object _render() {
    final content = child == null ? '' : renderWidget(child!);
    if (opacity <= 0) return '';
    if (opacity >= 1) return content;
    final style = Style().dim();
    style.hasDarkBackground = hasDarkBackground;
    return style.render(content);
  }
}
