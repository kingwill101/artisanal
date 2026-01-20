/// Theme system for widgets.
///
/// Provides semantic color slots and text styles that widgets can use
/// for consistent theming across the application.
///
/// ```dart
/// // Use the global theme
/// final color = theme.primary;
/// final style = theme.titleLarge;
///
/// // Set a custom theme
/// setTheme(Theme.dark());
/// ```
library;

import '../../style/style.dart';
import '../../style/color.dart';

/// Theme containing semantic colors and text styles for widgets.
class Theme {
  const Theme({
    required this.primary,
    required this.secondary,
    required this.surface,
    required this.background,
    required this.error,
    required this.success,
    required this.warning,
    required this.onPrimary,
    required this.onSecondary,
    required this.onSurface,
    required this.onBackground,
    required this.onError,
    required this.muted,
    required this.border,
    required this.titleLarge,
    required this.titleMedium,
    required this.titleSmall,
    required this.bodyLarge,
    required this.bodyMedium,
    required this.bodySmall,
    required this.labelLarge,
    required this.labelMedium,
    required this.labelSmall,
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // Semantic Colors
  // ─────────────────────────────────────────────────────────────────────────────

  /// Primary accent color for interactive elements.
  final Color primary;

  /// Secondary accent color for less prominent elements.
  final Color secondary;

  /// Surface color for cards, panels, etc.
  final Color surface;

  /// Background color for the main area.
  final Color background;

  /// Error/danger color.
  final Color error;

  /// Success color.
  final Color success;

  /// Warning color.
  final Color warning;

  /// Text color on primary backgrounds.
  final Color onPrimary;

  /// Text color on secondary backgrounds.
  final Color onSecondary;

  /// Text color on surface backgrounds.
  final Color onSurface;

  /// Text color on main background.
  final Color onBackground;

  /// Text color on error backgrounds.
  final Color onError;

  /// Muted/dimmed text color.
  final Color muted;

  /// Border color.
  final Color border;

  // ─────────────────────────────────────────────────────────────────────────────
  // Text Styles
  // ─────────────────────────────────────────────────────────────────────────────

  /// Large title style.
  final Style titleLarge;

  /// Medium title style.
  final Style titleMedium;

  /// Small title style.
  final Style titleSmall;

  /// Large body text style.
  final Style bodyLarge;

  /// Medium body text style.
  final Style bodyMedium;

  /// Small body text style.
  final Style bodySmall;

  /// Large label style.
  final Style labelLarge;

  /// Medium label style.
  final Style labelMedium;

  /// Small label style (dimmed).
  final Style labelSmall;

  // ─────────────────────────────────────────────────────────────────────────────
  // Built-in Themes
  // ─────────────────────────────────────────────────────────────────────────────

  /// Dark theme with cyan accents.
  static Theme dark() {
    const primary = AnsiColor(39); // Cyan
    const secondary = AnsiColor(99); // Purple
    const surface = AnsiColor(236); // Dark gray
    const background = AnsiColor(233); // Very dark gray
    const error = AnsiColor(196); // Red
    const success = AnsiColor(42); // Green
    const warning = AnsiColor(214); // Orange
    const onPrimary = AnsiColor(232); // Black
    const onSecondary = AnsiColor(255); // White
    const onSurface = AnsiColor(252); // Light gray
    const onBackground = AnsiColor(250); // Light gray
    const onError = AnsiColor(255); // White
    const muted = AnsiColor(242); // Gray
    const border = AnsiColor(238); // Dark gray

    return Theme(
      primary: primary,
      secondary: secondary,
      surface: surface,
      background: background,
      error: error,
      success: success,
      warning: warning,
      onPrimary: onPrimary,
      onSecondary: onSecondary,
      onSurface: onSurface,
      onBackground: onBackground,
      onError: onError,
      muted: muted,
      border: border,
      titleLarge: Style().bold().foreground(onBackground),
      titleMedium: Style().bold().foreground(onSurface),
      titleSmall: Style().bold().foreground(muted),
      bodyLarge: Style().foreground(onBackground),
      bodyMedium: Style().foreground(onSurface),
      bodySmall: Style().foreground(muted),
      labelLarge: Style().foreground(onSurface),
      labelMedium: Style().foreground(muted),
      labelSmall: Style().dim().foreground(muted),
    );
  }

  /// Light theme with blue accents.
  static Theme light() {
    const primary = AnsiColor(33); // Blue
    const secondary = AnsiColor(90); // Purple
    const surface = AnsiColor(254); // Light gray
    const background = AnsiColor(255); // White
    const error = AnsiColor(160); // Dark red
    const success = AnsiColor(28); // Dark green
    const warning = AnsiColor(172); // Dark orange
    const onPrimary = AnsiColor(255); // White
    const onSecondary = AnsiColor(255); // White
    const onSurface = AnsiColor(235); // Dark gray
    const onBackground = AnsiColor(232); // Black
    const onError = AnsiColor(255); // White
    const muted = AnsiColor(245); // Gray
    const border = AnsiColor(250); // Light gray

    return Theme(
      primary: primary,
      secondary: secondary,
      surface: surface,
      background: background,
      error: error,
      success: success,
      warning: warning,
      onPrimary: onPrimary,
      onSecondary: onSecondary,
      onSurface: onSurface,
      onBackground: onBackground,
      onError: onError,
      muted: muted,
      border: border,
      titleLarge: Style().bold().foreground(onBackground),
      titleMedium: Style().bold().foreground(onSurface),
      titleSmall: Style().bold().foreground(muted),
      bodyLarge: Style().foreground(onBackground),
      bodyMedium: Style().foreground(onSurface),
      bodySmall: Style().foreground(muted),
      labelLarge: Style().foreground(onSurface),
      labelMedium: Style().foreground(muted),
      labelSmall: Style().dim().foreground(muted),
    );
  }

  /// Copy this theme with some values changed.
  Theme copyWith({
    Color? primary,
    Color? secondary,
    Color? surface,
    Color? background,
    Color? error,
    Color? success,
    Color? warning,
    Color? onPrimary,
    Color? onSecondary,
    Color? onSurface,
    Color? onBackground,
    Color? onError,
    Color? muted,
    Color? border,
    Style? titleLarge,
    Style? titleMedium,
    Style? titleSmall,
    Style? bodyLarge,
    Style? bodyMedium,
    Style? bodySmall,
    Style? labelLarge,
    Style? labelMedium,
    Style? labelSmall,
  }) {
    return Theme(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      surface: surface ?? this.surface,
      background: background ?? this.background,
      error: error ?? this.error,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      onPrimary: onPrimary ?? this.onPrimary,
      onSecondary: onSecondary ?? this.onSecondary,
      onSurface: onSurface ?? this.onSurface,
      onBackground: onBackground ?? this.onBackground,
      onError: onError ?? this.onError,
      muted: muted ?? this.muted,
      border: border ?? this.border,
      titleLarge: titleLarge ?? this.titleLarge,
      titleMedium: titleMedium ?? this.titleMedium,
      titleSmall: titleSmall ?? this.titleSmall,
      bodyLarge: bodyLarge ?? this.bodyLarge,
      bodyMedium: bodyMedium ?? this.bodyMedium,
      bodySmall: bodySmall ?? this.bodySmall,
      labelLarge: labelLarge ?? this.labelLarge,
      labelMedium: labelMedium ?? this.labelMedium,
      labelSmall: labelSmall ?? this.labelSmall,
    );
  }

  /// Adaptive theme that auto-switches based on terminal background.
  ///
  /// This is the recommended default. Colors automatically adapt when the
  /// terminal reports its background color via OSC 11.
  ///
  /// Uses [AdaptiveColor] for all color slots, which resolve based on
  /// [hasDarkBackground] at render time.
  static Theme adaptive() {
    // Primary/accent colors - cyan for both, works well on light and dark
    const primary = AdaptiveColor(
      light: AnsiColor(33), // Blue
      dark: AnsiColor(39), // Cyan
    );
    const secondary = AdaptiveColor(
      light: AnsiColor(90), // Purple
      dark: AnsiColor(99), // Purple
    );

    // Surface/background - these are the key adaptive colors
    const surface = AdaptiveColor(
      light: AnsiColor(254), // Light gray
      dark: AnsiColor(236), // Dark gray
    );
    const background = AdaptiveColor(
      light: AnsiColor(255), // White
      dark: AnsiColor(233), // Very dark gray
    );

    // Status colors
    const error = AdaptiveColor(
      light: AnsiColor(160), // Dark red
      dark: AnsiColor(196), // Bright red
    );
    const success = AdaptiveColor(
      light: AnsiColor(28), // Dark green
      dark: AnsiColor(42), // Bright green
    );
    const warning = AdaptiveColor(
      light: AnsiColor(172), // Dark orange
      dark: AnsiColor(214), // Bright orange
    );

    // Text colors - must contrast with background
    const onPrimary = AdaptiveColor(
      light: AnsiColor(255), // White on dark primary
      dark: AnsiColor(232), // Black on light primary
    );
    const onSecondary = AnsiColor(255); // White
    const onSurface = AdaptiveColor(
      light: AnsiColor(235), // Dark gray on light surface
      dark: AnsiColor(252), // Light gray on dark surface
    );
    const onBackground = AdaptiveColor(
      light: AnsiColor(232), // Black on light background
      dark: AnsiColor(250), // Light gray on dark background
    );
    const onError = AnsiColor(255); // White
    const muted = AdaptiveColor(
      light: AnsiColor(245), // Medium gray
      dark: AnsiColor(242), // Medium gray
    );
    const border = AdaptiveColor(
      light: AnsiColor(250), // Light gray border
      dark: AnsiColor(238), // Dark gray border
    );

    return Theme(
      primary: primary,
      secondary: secondary,
      surface: surface,
      background: background,
      error: error,
      success: success,
      warning: warning,
      onPrimary: onPrimary,
      onSecondary: onSecondary,
      onSurface: onSurface,
      onBackground: onBackground,
      onError: onError,
      muted: muted,
      border: border,
      titleLarge: Style().bold().foreground(onBackground),
      titleMedium: Style().bold().foreground(onSurface),
      titleSmall: Style().bold().foreground(muted),
      bodyLarge: Style().foreground(onBackground),
      bodyMedium: Style().foreground(onSurface),
      bodySmall: Style().foreground(muted),
      labelLarge: Style().foreground(onSurface),
      labelMedium: Style().foreground(muted),
      labelSmall: Style().dim().foreground(muted),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Global Theme State
// ─────────────────────────────────────────────────────────────────────────────

Theme _currentTheme = Theme.adaptive();
bool _hasDarkBackground = true;

/// Returns the current global theme.
Theme get currentTheme => _currentTheme;

/// Whether the terminal has a dark background.
///
/// This affects how [AdaptiveColor] values resolve when rendering.
bool get hasDarkBackground => _hasDarkBackground;

/// Sets the global theme.
void setTheme(Theme theme) {
  _currentTheme = theme;
}

/// Updates the dark background state.
///
/// Call this when the terminal reports its background color.
/// This is typically done automatically by [Widget.update] when it
/// receives a [BackgroundColorMsg].
void setHasDarkBackground(bool value) {
  _hasDarkBackground = value;
}

/// Updates theme based on background hex color (e.g., '#1a1a1a').
///
/// Automatically determines if the background is dark based on luminance.
void updateThemeFromBackground(String? hex) {
  if (hex == null || hex.isEmpty) return;
  final h = hex.startsWith('#') ? hex.substring(1) : hex;
  if (h.length != 6) return;

  final r = int.tryParse(h.substring(0, 2), radix: 16);
  final g = int.tryParse(h.substring(2, 4), radix: 16);
  final b = int.tryParse(h.substring(4, 6), radix: 16);
  if (r == null || g == null || b == null) return;

  // Perceived luminance; threshold tuned for terminals
  final lum = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255.0;
  _hasDarkBackground = lum < 0.5;
}
