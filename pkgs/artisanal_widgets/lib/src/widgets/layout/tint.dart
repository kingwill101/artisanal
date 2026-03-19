part of 'layout_widgets.dart';

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
    final content = child != null ? _renderWidget(child!) : '';
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

  final tintFg = _colorToUvColor(color);
  if (tintFg == null) return content;

  final w = Layout.getWidth(content);
  final h = Layout.getHeight(content);
  if (w == 0 || h == 0) return content;

  final canvas = Canvas(w, h);
  final styledBounds = StyledString(content).bounds();
  final tempCanvas = Canvas(styledBounds.width, styledBounds.height);
  StyledString(content).draw(tempCanvas, tempCanvas.bounds());

  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (x >= styledBounds.width || y >= styledBounds.height) {
        canvas.setCell(x, y, Cell(content: ' ', width: 1));
        continue;
      }

      final srcCell = tempCanvas.cellAt(x, y);
      if (srcCell == null || srcCell.isZero) {
        canvas.setCell(x, y, Cell(content: ' ', width: 1));
        continue;
      }

      final defaultFg = _colorToUvColor(currentTheme.onBackground);
      final defaultBg = _colorToUvColor(currentTheme.background);
      final tintedStyle = srcCell.style.copyWith(
        fg: _blendTintColor(
          srcCell.style.fg,
          tintFg,
          opacity,
          fallback: srcCell.content.trim().isEmpty ? null : defaultFg,
        ),
        bg: _blendTintColor(
          srcCell.style.bg,
          tintFg,
          opacity,
          fallback: defaultBg,
        ),
      );

      canvas.setCell(
        x,
        y,
        Cell(
          content: srcCell.content,
          width: srcCell.width,
          style: tintedStyle,
          link: srcCell.link,
        ),
      );
    }
  }

  return canvas.render();
}

UvColor? _blendTintColor(
  UvColor? source,
  UvColor tint,
  double opacity, {
  UvColor? fallback,
}) {
  final sourceColor = _uvColorToStyleColor(source ?? fallback);
  final tintColor = _uvColorToStyleColor(tint);
  if (sourceColor == null || tintColor == null) {
    return source ?? fallback;
  }

  return _colorToUvColor(
    blendColor(
      sourceColor,
      tintColor,
      opacity,
      hasDarkBackground: hasDarkBackground,
    ),
  );
}

Color? _uvColorToStyleColor(UvColor? color) {
  return switch (color) {
    UvRgb(:final r, :final g, :final b) => BasicColor(
      '#'
      '${r.toRadixString(16).padLeft(2, '0')}'
      '${g.toRadixString(16).padLeft(2, '0')}'
      '${b.toRadixString(16).padLeft(2, '0')}',
    ),
    UvIndexed256(:final index) => AnsiColor(index),
    UvBasic16(:final index, :final bright) => AnsiColor(index + (bright ? 8 : 0)),
    _ => null,
  };
}
