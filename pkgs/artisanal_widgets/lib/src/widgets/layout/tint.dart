import 'package:artisanal/uv.dart' show UvColor, StyledString, UvStyle, UvRgb, UvIndexed256, UvBasic16, Canvas;

import '../rendering/render_object.dart';
import '../theme.dart';
import '../style.dart';
import '_layout_utils.dart' show renderWidget, colorToUvColor;
import 'geometry.dart';


final Map<UvColor, Color> _uvToStyleColorCache = <UvColor, Color>{};

/// A widget that applies a color tint over its child.
///
/// The tint color is applied as a foreground color overlay on all cells
/// rendered by the child. An [opacity] of 1.0 fully replaces the
/// foreground with the tint color, while 0.0 has no effect.
///
/// In a terminal context, true alpha compositing is not possible, so the tint
/// blends each rendered cell's foreground/background colors toward [color].
///
/// ```dart
/// Tint(
///   color: Colors.red,
///   opacity: 1.0,
///   child: Text('This text appears red'),
/// )
/// ```
class Tint extends SingleChildRenderObjectWidget {
  Tint({required this.color, this.opacity = 1.0, super.child, super.key});

  /// The tint color to apply over the child content.
  final Color color;

  /// How strongly to apply the tint (0.0 = none, 1.0 = full).
  final double opacity;

  @override
  RenderObject createRenderObject() {
    return _RenderTint(color: color, opacity: opacity);
  }

  @override
  void updateRenderObject(RenderObject renderObject) {
    final tint = renderObject as _RenderTint;
    tint
      ..color = color
      ..opacity = opacity;
  }

  @override
  Object view() {
    final content = child != null ? renderWidget(child!) : '';
    return _applyTint(content, color, opacity);
  }
}

class _RenderTint extends RenderBox {
  _RenderTint({required this.color, required this.opacity});

  Color color;
  double opacity;
  String? _lastPaint;

  RenderObject? get _child => children.isEmpty ? null : children.first;

  @override
  void layout(BoxConstraints constraints) {
    super.layout(constraints);
    _child?.layout(constraints);
    final content = _child?.paint() ?? '';
    _lastPaint = _applyTint(content, color, opacity);
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
    return _applyTint(content, color, opacity);
  }
}

/// Applies a color tint to [content].
///
/// Since terminals don't support true alpha blending, this applies the
/// tint by replacing the foreground color of each cell. When [opacity]
/// is 0.0 the content is returned unchanged.
String _applyTint(String content, Color color, double opacity) {
  if (content.isEmpty || opacity <= 0.0) return content;

  final tintFg = colorToUvColor(color);
  if (tintFg == null) return content;

  final w = Layout.getWidth(content);
  final h = Layout.getHeight(content);
  if (w == 0 || h == 0) return content;

  final canvas = Canvas(w, h);
  StyledString(content).draw(canvas, canvas.bounds());
  final defaultFg = colorToUvColor(currentTheme.onBackground);
  final defaultBg = colorToUvColor(currentTheme.background);
  final styleCache = <({int styleKey, bool visibleContent}), UvStyle>{};
  final colorCache = <({UvColor? source, UvColor? fallback}), UvColor?>{};

  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final srcCell = canvas.cellAt(x, y);
      if (srcCell == null || srcCell.isZero) {
        continue;
      }

      final visibleContent =
          srcCell.content.isNotEmpty && srcCell.content != ' ';
      final styleKey = (
        styleKey: srcCell.style.packedKey,
        visibleContent: visibleContent,
      );
      final tintedStyle = styleCache[styleKey] ??= srcCell.style.copyWith(
        fg: _blendTintColor(
          srcCell.style.fg,
          tintFg,
          opacity,
          fallback: visibleContent ? defaultFg : null,
          cache: colorCache,
        ),
        bg: _blendTintColor(
          srcCell.style.bg,
          tintFg,
          opacity,
          fallback: defaultBg,
          cache: colorCache,
        ),
      );
      if (tintedStyle != srcCell.style) {
        srcCell.style = tintedStyle;
      }
    }
  }

  return canvas.render();
}

UvColor? _blendTintColor(
  UvColor? source,
  UvColor tint,
  double opacity, {
  UvColor? fallback,
  Map<({UvColor? source, UvColor? fallback}), UvColor?>? cache,
}) {
  final cacheKey = (source: source, fallback: fallback);
  if (cache != null && cache.containsKey(cacheKey)) {
    return cache[cacheKey];
  }

  final sourceColor = _uvColorToStyleColor(source ?? fallback);
  final tintColor = _uvColorToStyleColor(tint);
  if (sourceColor == null || tintColor == null) {
    return cache != null
        ? (cache[cacheKey] = source ?? fallback)
        : source ?? fallback;
  }

  final blended = colorToUvColor(
    blendColor(
      sourceColor,
      tintColor,
      opacity,
      hasDarkBackground: hasDarkBackground,
    ),
  );
  if (cache != null) {
    cache[cacheKey] = blended;
  }
  return blended;
}

Color? _uvColorToStyleColor(UvColor? color) {
  if (color == null) return null;
  final cached = _uvToStyleColorCache[color];
  if (cached != null) return cached;

  final resolved = switch (color) {
    UvRgb(:final r, :final g, :final b) => BasicColor(
      '#'
      '${r.toRadixString(16).padLeft(2, '0')}'
      '${g.toRadixString(16).padLeft(2, '0')}'
      '${b.toRadixString(16).padLeft(2, '0')}',
    ),
    UvIndexed256(:final index) => AnsiColor(index),
    UvBasic16(:final index, :final bright) => AnsiColor(
      index + (bright ? 8 : 0),
    ),
  };
  _uvToStyleColorCache[color] = resolved;
  return resolved;
}
