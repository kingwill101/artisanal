/// Theme and color palette support for TUI applications.
///
/// Provides predefined color themes and a [ThemePalette] class for
/// consistent styling across an application.
library;

import 'color.dart';

/// A semantic color palette for theming TUI applications.
///
/// Each property represents a semantic role (accent, success, error, etc.)
/// rather than a specific color, allowing themes to be swapped easily.
///
/// Colors use [AdaptiveColor] to automatically adjust for light/dark
/// terminal backgrounds.
///
/// ```dart
/// final theme = ThemePalette.dark;
/// final style = Style().foreground(theme.accent);
/// ```
class ThemePalette {
  /// Creates a custom theme palette.
  const ThemePalette({
    required this.accent,
    required this.accentBold,
    required this.text,
    required this.textDim,
    required this.textBold,
    required this.border,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.highlight,
    this.background,
  });

  /// Primary accent color for active/selected elements.
  final Color accent;

  /// Bold variant of accent for titles and emphasis.
  final Color accentBold;

  /// Standard text color.
  final Color text;

  /// Dimmed text color for secondary information.
  final Color textDim;

  /// Bold/bright text color for emphasis.
  final Color textBold;

  /// Border and separator color.
  final Color border;

  /// Success/positive indicator color (typically green).
  final Color success;

  /// Warning indicator color (typically yellow/orange).
  final Color warning;

  /// Error/danger indicator color (typically red).
  final Color error;

  /// Informational indicator color (typically blue).
  final Color info;

  /// Highlight/special color (typically purple/magenta).
  final Color highlight;

  /// Optional background color (null for default terminal background).
  final Color? background;

  // ─────────────────────────────────────────────────────────────────────────
  // Predefined Themes
  // ─────────────────────────────────────────────────────────────────────────

  /// Dark theme - classic terminal colors on dark background.
  ///
  /// Uses standard ANSI colors that work well on dark terminals.
  static const dark = ThemePalette(
    accent: Colors.cyan,
    accentBold: Colors.cyan,
    text: Colors.gray,
    textDim: Colors.gray,
    textBold: Colors.white,
    border: Colors.blue,
    success: Colors.green,
    warning: Colors.yellow,
    error: Colors.red,
    info: Colors.blue,
    highlight: Colors.purple,
  );

  /// Light theme - darker colors for light terminal backgrounds.
  ///
  /// Uses adaptive colors that work on light backgrounds.
  static const light = ThemePalette(
    accent: AdaptiveColor(light: BasicColor('#0066cc'), dark: Colors.blue),
    accentBold: AdaptiveColor(light: BasicColor('#0066cc'), dark: Colors.blue),
    text: AdaptiveColor(light: BasicColor('#333333'), dark: Colors.gray),
    textDim: AdaptiveColor(light: BasicColor('#666666'), dark: Colors.gray),
    textBold: AdaptiveColor(light: Colors.black, dark: Colors.white),
    border: AdaptiveColor(light: BasicColor('#999999'), dark: Colors.blue),
    success: AdaptiveColor(
      light: BasicColor('#228B22'), // Forest green
      dark: Colors.green,
    ),
    warning: AdaptiveColor(
      light: BasicColor('#DAA520'), // Goldenrod
      dark: Colors.yellow,
    ),
    error: AdaptiveColor(light: BasicColor('#CC0000'), dark: Colors.red),
    info: AdaptiveColor(
      light: BasicColor('#4169E1'), // Royal blue
      dark: Colors.blue,
    ),
    highlight: AdaptiveColor(
      light: BasicColor('#8B008B'), // Dark magenta
      dark: Colors.purple,
    ),
  );

  /// Hacker theme - Matrix-inspired green-on-black aesthetic.
  ///
  /// All shades of green with high contrast for that classic hacker look.
  static const hacker = ThemePalette(
    accent: BasicColor('#00FF00'), // Bright green
    accentBold: BasicColor('#00FF00'),
    text: BasicColor('#00CC00'),
    textDim: BasicColor('#008800'),
    textBold: BasicColor('#00FF00'),
    border: BasicColor('#006600'),
    success: BasicColor('#00FF00'),
    warning: BasicColor('#FFFF00'),
    error: BasicColor('#FF0000'),
    info: BasicColor('#00FFFF'),
    highlight: BasicColor('#00FF00'),
  );

  /// Ocean theme - calming blue/turquoise palette.
  ///
  /// Cool ocean-inspired colors with turquoise accents.
  static const ocean = ThemePalette(
    accent: BasicColor('#00CED1'), // Dark turquoise
    accentBold: BasicColor('#40E0D0'), // Turquoise
    text: BasicColor('#87CEEB'), // Sky blue
    textDim: BasicColor('#4682B4'), // Steel blue
    textBold: BasicColor('#E0FFFF'), // Light cyan
    border: BasicColor('#20B2AA'), // Light sea green
    success: BasicColor('#00FA9A'), // Medium spring green
    warning: BasicColor('#FFD700'), // Gold
    error: BasicColor('#FF6347'), // Tomato
    info: BasicColor('#1E90FF'), // Dodger blue
    highlight: BasicColor('#7B68EE'), // Medium slate blue
  );

  /// Monokai theme - inspired by the popular editor theme.
  ///
  /// Warm colors with pink/orange accents on dark background.
  static const monokai = ThemePalette(
    accent: BasicColor('#F92672'), // Pink
    accentBold: BasicColor('#F92672'),
    text: BasicColor('#F8F8F2'), // Off-white
    textDim: BasicColor('#75715E'), // Comment gray
    textBold: BasicColor('#FFFFFF'),
    border: BasicColor('#49483E'), // Dark gray
    success: BasicColor('#A6E22E'), // Green
    warning: BasicColor('#E6DB74'), // Yellow
    error: BasicColor('#F92672'), // Pink/red
    info: BasicColor('#66D9EF'), // Cyan
    highlight: BasicColor('#AE81FF'), // Purple
  );

  /// Dracula theme - popular dark theme with purple accents.
  ///
  /// Dark background with pastel colors.
  static const dracula = ThemePalette(
    accent: BasicColor('#BD93F9'), // Purple
    accentBold: BasicColor('#BD93F9'),
    text: BasicColor('#F8F8F2'), // Foreground
    textDim: BasicColor('#6272A4'), // Comment
    textBold: BasicColor('#FFFFFF'),
    border: BasicColor('#44475A'), // Current line
    success: BasicColor('#50FA7B'), // Green
    warning: BasicColor('#F1FA8C'), // Yellow
    error: BasicColor('#FF5555'), // Red
    info: BasicColor('#8BE9FD'), // Cyan
    highlight: BasicColor('#FF79C6'), // Pink
  );

  /// Nord theme - arctic, bluish color palette.
  ///
  /// Cool, muted colors inspired by Nordic aesthetics.
  static const nord = ThemePalette(
    accent: BasicColor('#88C0D0'), // Frost cyan
    accentBold: BasicColor('#8FBCBB'), // Frost teal
    text: BasicColor('#D8DEE9'), // Snow storm
    textDim: BasicColor('#4C566A'), // Polar night
    textBold: BasicColor('#ECEFF4'), // Bright snow
    border: BasicColor('#3B4252'), // Dark polar
    success: BasicColor('#A3BE8C'), // Aurora green
    warning: BasicColor('#EBCB8B'), // Aurora yellow
    error: BasicColor('#BF616A'), // Aurora red
    info: BasicColor('#81A1C1'), // Frost blue
    highlight: BasicColor('#B48EAD'), // Aurora purple
  );

  /// Solarized Dark theme - ethan schoonover's popular color scheme.
  static const solarizedDark = ThemePalette(
    accent: BasicColor('#268BD2'), // Blue
    accentBold: BasicColor('#268BD2'),
    text: BasicColor('#839496'), // Base0
    textDim: BasicColor('#586E75'), // Base01
    textBold: BasicColor('#93A1A1'), // Base1
    border: BasicColor('#073642'), // Base02
    success: BasicColor('#859900'), // Green
    warning: BasicColor('#B58900'), // Yellow
    error: BasicColor('#DC322F'), // Red
    info: BasicColor('#2AA198'), // Cyan
    highlight: BasicColor('#6C71C4'), // Violet
  );

  /// Solarized Light theme - light variant of solarized.
  static const solarizedLight = ThemePalette(
    accent: BasicColor('#268BD2'), // Blue
    accentBold: BasicColor('#268BD2'),
    text: BasicColor('#657B83'), // Base00
    textDim: BasicColor('#93A1A1'), // Base1
    textBold: BasicColor('#073642'), // Base02
    border: BasicColor('#EEE8D5'), // Base2
    success: BasicColor('#859900'), // Green
    warning: BasicColor('#B58900'), // Yellow
    error: BasicColor('#DC322F'), // Red
    info: BasicColor('#2AA198'), // Cyan
    highlight: BasicColor('#6C71C4'), // Violet
  );

  /// All predefined themes.
  static const values = [
    dark,
    light,
    hacker,
    ocean,
    monokai,
    dracula,
    nord,
    solarizedDark,
    solarizedLight,
  ];

  /// Theme names corresponding to [values].
  static const names = [
    'dark',
    'light',
    'hacker',
    'ocean',
    'monokai',
    'dracula',
    'nord',
    'solarizedDark',
    'solarizedLight',
  ];

  /// Get a theme by name (case-insensitive).
  ///
  /// Returns [dark] if name is not found.
  static ThemePalette byName(String name) {
    final lower = name.toLowerCase();
    final index = names.indexWhere((n) => n.toLowerCase() == lower);
    return index >= 0 ? values[index] : dark;
  }
}
