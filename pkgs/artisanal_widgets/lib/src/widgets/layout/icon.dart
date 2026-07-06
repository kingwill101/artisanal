import 'package:artisanal/style.dart' hide Padding, Align;

import '../rendering/render_layout.dart';
import '../rendering/render_object.dart';
import '../theme/theme.dart' show hasDarkBackground;
import '_layout_utils.dart';

class IconData {
  const IconData(this.codePoint);

  final int codePoint;

  String get glyph => String.fromCharCode(codePoint);
}

class Icons {
  static const add = IconData(0x2b);
  static const remove = IconData(0x2d);
  static const check = IconData(0x2713);
  static const close = IconData(0x2715);
  static const arrowLeft = IconData(0x2190);
  static const arrowRight = IconData(0x2192);
  static const arrowUp = IconData(0x2191);
  static const arrowDown = IconData(0x2193);
  static const star = IconData(0x2605);
}

class Icon extends LeafRenderObjectWidget {
  Icon(this.icon, {this.size, this.color, this.style, super.key});

  final IconData icon;
  final num? size;
  final Color? color;
  final Style? style;

  @override
  RenderObject createRenderObject() {
    return RenderText(text: _render());
  }

  @override
  void updateRenderObject(RenderObject renderObject) {
    (renderObject as RenderText).text = _render();
  }

  @override
  Object view() => _render();

  String _render() {
    final glyph = icon.glyph;
    final resolvedSize = resolveDimension(size);
    final resolvedStyle = _resolveIconStyle();
    final content = resolvedStyle == null ? glyph : resolvedStyle.render(glyph);

    if (resolvedSize == null) return content;

    return constrainContent(content, width: resolvedSize, height: resolvedSize);
  }

  Style? _resolveIconStyle() {
    if (style == null && color == null) return null;
    final resolved = (style ?? Style()).copy();
    if (color != null) {
      resolved.foreground(color!);
    }
    resolved.hasDarkBackground = hasDarkBackground;
    return resolved;
  }
}
