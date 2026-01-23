import 'msg.dart';
import '../uv/uv.dart' as uvev;

/// Tracks terminal theme information (background + dark/light heuristic).
///
/// This is a lightweight helper that apps/components can keep in their model to
/// avoid re-implementing background color parsing and dark-mode heuristics.
final class TerminalThemeState {
  const TerminalThemeState({this.backgroundHex, this.hasDarkBackground});

  /// Terminal-reported background color in hex form (e.g. `#0a0a0a`).
  final String? backgroundHex;

  /// Whether the background is considered "dark".
  ///
  /// - `true/false` when known
  /// - `null` when unknown (no report yet)
  final bool? hasDarkBackground;

  TerminalThemeState update(Msg msg) {
    return switch (msg) {
      BackgroundColorMsg(hex: final hex) => _withBackgroundHex(hex),

      // UV decoder can also emit light/dark scheme events.
      UvEventMsg(event: final ev) when ev is uvev.DarkColorSchemeEvent =>
        TerminalThemeState(
          backgroundHex: backgroundHex,
          hasDarkBackground: true,
        ),

      UvEventMsg(event: final ev) when ev is uvev.LightColorSchemeEvent =>
        TerminalThemeState(
          backgroundHex: backgroundHex,
          hasDarkBackground: false,
        ),

      _ => this,
    };
  }

  TerminalThemeState _withBackgroundHex(String? hex) {
    if (hex == null || hex.isEmpty) return this;
    final dark = _isDarkHex(hex);
    return TerminalThemeState(
      backgroundHex: hex,
      hasDarkBackground: dark ?? hasDarkBackground,
    );
  }

  static bool? _isDarkHex(String hex) {
    final h = hex.startsWith('#') ? hex.substring(1) : hex;
    if (h.length != 6) return null;
    final r = int.tryParse(h.substring(0, 2), radix: 16);
    final g = int.tryParse(h.substring(2, 4), radix: 16);
    final b = int.tryParse(h.substring(4, 6), radix: 16);
    if (r == null || g == null || b == null) return null;
    // Perceived luminance; threshold tuned for terminals.
    final lum = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255.0;
    return lum < 0.5;
  }
}

/// Mixin for models/components that want terminal theme state with minimal
/// boilerplate.
mixin TerminalThemeHost {
  TerminalThemeState terminalTheme = const TerminalThemeState();

  /// Updates [terminalTheme] if [msg] carries theme information.
  void updateTerminalTheme(Msg msg) {
    terminalTheme = terminalTheme.update(msg);
  }
}
