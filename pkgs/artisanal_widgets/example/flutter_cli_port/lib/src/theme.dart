import 'package:artisanal/style.dart' as style;

final class FlutterCliTheme {
  const FlutterCliTheme({
    required this.bg,
    required this.fg,
    required this.accent,
    required this.success,
    required this.warn,
    required this.error,
    required this.dim,
    required this.cyan,
  });

  static const tokyoNight = FlutterCliTheme(
    bg: style.BasicColor('#1a1b26'),
    fg: style.BasicColor('#c0caf5'),
    accent: style.BasicColor('#7aa2f7'),
    success: style.BasicColor('#9ece6a'),
    warn: style.BasicColor('#e0af68'),
    error: style.BasicColor('#f7768e'),
    dim: style.BasicColor('#565f89'),
    cyan: style.BasicColor('#7dcfff'),
  );

  final style.Color bg;
  final style.Color fg;
  final style.Color accent;
  final style.Color success;
  final style.Color warn;
  final style.Color error;
  final style.Color dim;
  final style.Color cyan;

  style.Style get base => style.Style()
    ..foreground(fg)
    ..background(bg);

  style.Style get dimmed => style.Style()
    ..foreground(dim)
    ..background(bg);

  style.Style get header => style.Style()
    ..foreground(accent)
    ..background(bg)
    ..bold();

  style.Style fgStyle(style.Color color) => style.Style()
    ..foreground(color)
    ..background(bg);

  style.Style bold(style.Color color) => fgStyle(color)..bold();
}
