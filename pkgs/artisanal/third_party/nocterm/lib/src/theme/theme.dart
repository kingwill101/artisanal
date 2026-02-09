/// Theming system for nocterm TUI applications.
///
/// This library provides a comprehensive theming system that makes it easy
/// to create consistent, theme-compatible UIs. Colors automatically resolve
/// differently for light and dark themes.
///
/// ## Quick Start
///
/// Wrap your app in a [TuiTheme] and access theme colors with [TuiTheme.of]:
///
/// ```dart
/// // Wrap your app
/// TuiTheme(
///   data: TuiThemeData.dark,
///   child: MyApp(),
/// )
///
/// // Access theme in components
/// final theme = TuiTheme.of(context);
/// final textColor = theme.onSurface;
/// ```
///
/// ## Built-in Themes
///
/// Several popular themes are included:
/// - [TuiThemeData.dark] - Default dark theme
/// - [TuiThemeData.light] - Light theme
/// - [TuiThemeData.nord] - Arctic color palette
/// - [TuiThemeData.dracula] - Vibrant dark theme
/// - [TuiThemeData.catppuccinMocha] - Warm, cozy dark theme
/// - [TuiThemeData.gruvboxDark] - Retro groove theme
///
/// ## Adaptive Colors
///
/// Use [AdaptiveColor] for colors that should differ between themes:
///
/// ```dart
/// final textColor = AdaptiveColor(
///   light: Color.fromRGB(33, 33, 33),
///   dark: Color.fromRGB(248, 248, 242),
/// );
///
/// // Resolve based on current theme
/// final resolvedColor = textColor.resolve(theme.brightness);
/// ```
///
/// ## Semantic Colors
///
/// [TuiColors] provides semantic color constants:
/// - [TuiColors.primary] - Accent color
/// - [TuiColors.error] - Error states
/// - [TuiColors.success] - Success states
/// - [TuiColors.surface] / [TuiColors.onSurface] - Widget backgrounds
library;

export 'brightness.dart';
export 'adaptive_color.dart';
export 'terminal_brightness_detection.dart';
export 'tui_colors.dart';
export 'tui_theme_data.dart';
export 'tui_theme.dart';
