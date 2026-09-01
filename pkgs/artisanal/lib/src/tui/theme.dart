import 'msg.dart';
import 'cmd.dart';
import 'terminal_palette.dart';
import '../style/accessibility.dart' show isDarkColorRgb;
import 'package:ultraviolet/ultraviolet.dart' as uvev;
import 'trace.dart';

/// Tracks terminal-reported colors and background truth.
///
/// This is a lightweight helper that apps/components can keep in their model to
/// avoid re-implementing background color parsing and dark-mode heuristics.
final class TerminalThemeState {
  const TerminalThemeState({
    this.backgroundHex,
    this.foregroundHex,
    this.cursorHex,
    this.hasDarkBackground,
  });

  /// Terminal-reported background color in hex form (e.g. `#0a0a0a`).
  final String? backgroundHex;

  /// Terminal-reported foreground color in hex form.
  final String? foregroundHex;

  /// Terminal-reported cursor color in hex form.
  final String? cursorHex;

  /// Whether the background is considered "dark".
  ///
  /// - `true/false` when known
  /// - `null` when unknown (no report yet)
  final bool? hasDarkBackground;

  TerminalThemeState update(Msg msg) {
    return switch (msg) {
      ForegroundColorMsg(hex: final hex) => TerminalThemeState(
        foregroundHex: hex,
        backgroundHex: backgroundHex,
        cursorHex: cursorHex,
        hasDarkBackground: hasDarkBackground,
      ),
      BackgroundColorMsg(hex: final hex) => _withBackgroundHex(hex),
      CursorColorMsg(hex: final hex) => TerminalThemeState(
        foregroundHex: foregroundHex,
        backgroundHex: backgroundHex,
        cursorHex: hex,
        hasDarkBackground: hasDarkBackground,
      ),
      _ => this,
    };
  }

  TerminalThemeState _withBackgroundHex(String? hex) {
    if (hex == null || hex.isEmpty) return this;
    final dark = _isDarkHex(hex);
    return TerminalThemeState(
      backgroundHex: hex,
      foregroundHex: foregroundHex,
      cursorHex: cursorHex,
      hasDarkBackground: dark ?? hasDarkBackground,
    );
  }

  TerminalThemeState mergePalette(TerminalPaletteSnapshot snapshot) {
    return TerminalThemeState(
      backgroundHex: snapshot.backgroundHex ?? backgroundHex,
      foregroundHex: snapshot.foregroundHex ?? foregroundHex,
      cursorHex: snapshot.cursorHex ?? cursorHex,
      hasDarkBackground: snapshot.backgroundHex != null
          ? snapshot.isBackgroundDark
          : hasDarkBackground,
    );
  }

  static bool? _isDarkHex(String hex) {
    final h = hex.startsWith('#') ? hex.substring(1) : hex;
    if (h.length != 6) return null;
    final r = int.tryParse(h.substring(0, 2), radix: 16);
    final g = int.tryParse(h.substring(2, 4), radix: 16);
    final b = int.tryParse(h.substring(4, 6), radix: 16);
    if (r == null || g == null || b == null) return null;
    return isDarkColorRgb(red: r, green: g, blue: b);
  }
}

/// Tracks terminal color-scheme preference separately from terminal colors.
final class TerminalColorSchemeState {
  const TerminalColorSchemeState({this.hasDarkColorScheme});

  /// Whether the terminal or host prefers a dark color scheme.
  final bool? hasDarkColorScheme;

  TerminalColorSchemeState update(Msg msg) {
    return switch (msg) {
      ColorSchemeMsg(dark: final dark) => TerminalColorSchemeState(
        hasDarkColorScheme: dark,
      ),
      UvEventMsg(event: final ev) when ev is uvev.DarkColorSchemeEvent =>
        const TerminalColorSchemeState(hasDarkColorScheme: true),
      UvEventMsg(event: final ev) when ev is uvev.LightColorSchemeEvent =>
        const TerminalColorSchemeState(hasDarkColorScheme: false),
      _ => this,
    };
  }
}

/// Mixin for models/components that want terminal theme state with minimal
/// boilerplate.
mixin TerminalThemeHost {
  TerminalThemeState terminalTheme = const TerminalThemeState();
  TerminalColorSchemeState terminalColorScheme =
      const TerminalColorSchemeState();
  final TerminalPaletteService terminalPalette = TerminalPaletteService();

  /// Updates terminal color state and color-scheme preference if [msg] carries
  /// terminal appearance information.
  void updateTerminalTheme(Msg msg) {
    final beforeTheme = terminalTheme;
    final beforeColorScheme = terminalColorScheme;
    if (terminalPalette.handle(msg)) {
      terminalTheme = terminalTheme.mergePalette(terminalPalette.snapshot);
    } else {
      terminalTheme = terminalTheme.update(msg);
    }

    terminalColorScheme = terminalColorScheme.update(msg);

    _traceTerminalThemeUpdate(
      msg,
      beforeTheme,
      terminalTheme,
      beforeColorScheme,
      terminalColorScheme,
    );
  }

  /// Requests foreground/background/cursor reports for terminal theme probing.
  Cmd probeTerminalTheme({bool includeCursor = true}) {
    return terminalPalette.requestCoreColors(includeCursor: includeCursor);
  }

  /// Requests the standard terminal theme probes used by most hosts.
  ///
  /// This includes foreground/background reports, optionally the cursor color,
  /// and an optional leading slice of the indexed ANSI palette.
  Cmd initTerminalTheme({bool includeCursor = true, int paletteCount = 0}) {
    final commands = <Cmd>[
      probeTerminalTheme(includeCursor: includeCursor),
      if (paletteCount > 0)
        terminalPalette.requestAnsiPalette(count: paletteCount),
    ];
    return Cmd.batch(commands);
  }
}

void _traceTerminalThemeUpdate(
  Msg msg,
  TerminalThemeState before,
  TerminalThemeState after,
  TerminalColorSchemeState beforeColorScheme,
  TerminalColorSchemeState afterColorScheme,
) {
  if (before != after) {
    TuiTrace.event(
      'terminal.background.update',
      tag: TraceTag.input,
      fields: <String, Object?>{
        'message': msg.runtimeType.toString(),
        'background': after.backgroundHex,
        'foreground': after.foregroundHex,
        'cursor': after.cursorHex,
        'dark': after.hasDarkBackground,
      },
    );
  }

  if (beforeColorScheme.hasDarkColorScheme !=
      afterColorScheme.hasDarkColorScheme) {
    TuiTrace.event(
      'terminal.color_scheme.update',
      tag: TraceTag.input,
      fields: <String, Object?>{
        'message': msg.runtimeType.toString(),
        'dark': afterColorScheme.hasDarkColorScheme,
      },
    );
  }
}
