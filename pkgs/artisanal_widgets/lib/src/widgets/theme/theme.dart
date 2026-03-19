/// Theme system for widgets.
///
/// Provides semantic color slots, text styles, and optional component-level
/// theme data that widgets can use for consistent theming.
///
/// The theme system is layered:
/// 1. **Semantic colors** — primary, surface, error, etc.
/// 2. **Extended colors** — surfaceVariant, highlight, info, etc.
/// 3. **Text styles** — title, body, label at multiple sizes.
/// 4. **Component themes** — optional per-widget theme overrides.
///
/// Extended colors and component themes are optional; widgets fall back to
/// deriving values from the core semantic colors when they are not set.
///
/// ```dart
/// // Use the global theme
/// final color = theme.primary;
/// final style = theme.titleLarge;
///
/// // Set a custom theme
/// setTheme(Theme.dark());
///
/// // Customize component themes
/// setTheme(Theme.dark().copyWith(
///   statusBarTheme: StatusBarThemeData(background: myColor),
/// ));
/// ```
library;

import 'package:artisanal/style.dart';
import '../layout/layout_widgets.dart' show EdgeInsets;

// ─────────────────────────────────────────────────────────────────────────────
// Component Theme Data Classes
// ─────────────────────────────────────────────────────────────────────────────

/// Theme data for [StatusBar] widgets.
///
/// All fields are optional; widgets derive defaults from the parent [Theme]
/// semantic colors when not provided.
class StatusBarThemeData {
  const StatusBarThemeData({
    this.background,
    this.foreground,
    this.keyBackground,
    this.keyForeground,
    this.keyStyle,
    this.labelStyle,
    this.separator,
  });

  /// Background color of the status bar.
  /// Defaults to [Theme.surface].
  final Color? background;

  /// Default text color in the status bar.
  /// Defaults to [Theme.onSurface].
  final Color? foreground;

  /// Background color for key hint badges (e.g., "esc", "ctrl+p").
  /// Defaults to [Theme.muted].
  final Color? keyBackground;

  /// Foreground color for key hint badges.
  /// Defaults to [Theme.onSurface].
  final Color? keyForeground;

  /// Style applied to key hint text.
  final Style? keyStyle;

  /// Style applied to label text next to key hints.
  final Style? labelStyle;

  /// Separator string between items (e.g., "  " or " │ ").
  final String? separator;

  /// Copy with selective overrides.
  StatusBarThemeData copyWith({
    Color? background,
    Color? foreground,
    Color? keyBackground,
    Color? keyForeground,
    Style? keyStyle,
    Style? labelStyle,
    String? separator,
  }) {
    return StatusBarThemeData(
      background: background ?? this.background,
      foreground: foreground ?? this.foreground,
      keyBackground: keyBackground ?? this.keyBackground,
      keyForeground: keyForeground ?? this.keyForeground,
      keyStyle: keyStyle ?? this.keyStyle,
      labelStyle: labelStyle ?? this.labelStyle,
      separator: separator ?? this.separator,
    );
  }
}

/// Theme data for [AccentPanel] widgets.
///
/// Accent panels display a colored vertical stripe on one side with content.
class AccentPanelThemeData {
  const AccentPanelThemeData({
    this.accentColor,
    this.accentWidth,
    this.background,
    this.foreground,
    this.padding,
    this.border,
  });

  /// Color of the accent stripe.
  /// Defaults to [Theme.primary].
  final Color? accentColor;

  /// Character width of the accent stripe (typically 1 or 2).
  /// Defaults to 1.
  final int? accentWidth;

  /// Background color of the panel body.
  /// Defaults to [Theme.surface].
  final Color? background;

  /// Text color in the panel body.
  /// Defaults to [Theme.onSurface].
  final Color? foreground;

  /// Content padding inside the panel.
  final EdgeInsets? padding;

  /// Border style for the panel frame.
  final Border? border;

  /// Copy with selective overrides.
  AccentPanelThemeData copyWith({
    Color? accentColor,
    int? accentWidth,
    Color? background,
    Color? foreground,
    EdgeInsets? padding,
    Border? border,
  }) {
    return AccentPanelThemeData(
      accentColor: accentColor ?? this.accentColor,
      accentWidth: accentWidth ?? this.accentWidth,
      background: background ?? this.background,
      foreground: foreground ?? this.foreground,
      padding: padding ?? this.padding,
      border: border ?? this.border,
    );
  }
}

/// Theme data for [CommandPalette] widgets.
///
/// Command palettes are searchable, grouped list modals with keyboard
/// navigation (similar to VS Code's command palette).
class CommandPaletteThemeData {
  const CommandPaletteThemeData({
    this.background,
    this.foreground,
    this.selectedBackground,
    this.selectedForeground,
    this.headerForeground,
    this.searchBackground,
    this.searchForeground,
    this.shortcutForeground,
    this.border,
    this.borderColor,
    this.width,
    this.maxHeight,
  });

  /// Background color of the palette.
  /// Defaults to [Theme.surface].
  final Color? background;

  /// Default text color in the palette.
  /// Defaults to [Theme.onSurface].
  final Color? foreground;

  /// Background color for the selected/highlighted item.
  /// Defaults to [Theme.primary].
  final Color? selectedBackground;

  /// Text color for the selected/highlighted item.
  /// Defaults to [Theme.onPrimary].
  final Color? selectedForeground;

  /// Text color for section headers.
  /// Defaults to [Theme.muted].
  final Color? headerForeground;

  /// Background color for the search input area.
  /// Defaults to [Theme.background].
  final Color? searchBackground;

  /// Text color for the search input.
  /// Defaults to [Theme.onBackground].
  final Color? searchForeground;

  /// Text color for keyboard shortcut hints.
  /// Defaults to [Theme.muted].
  final Color? shortcutForeground;

  /// Border style for the palette frame.
  final Border? border;

  /// Border color for the palette frame.
  /// Defaults to [Theme.border].
  final Color? borderColor;

  /// Width of the palette in columns.
  final int? width;

  /// Maximum height of the palette in rows.
  final int? maxHeight;

  /// Copy with selective overrides.
  CommandPaletteThemeData copyWith({
    Color? background,
    Color? foreground,
    Color? selectedBackground,
    Color? selectedForeground,
    Color? headerForeground,
    Color? searchBackground,
    Color? searchForeground,
    Color? shortcutForeground,
    Border? border,
    Color? borderColor,
    int? width,
    int? maxHeight,
  }) {
    return CommandPaletteThemeData(
      background: background ?? this.background,
      foreground: foreground ?? this.foreground,
      selectedBackground: selectedBackground ?? this.selectedBackground,
      selectedForeground: selectedForeground ?? this.selectedForeground,
      headerForeground: headerForeground ?? this.headerForeground,
      searchBackground: searchBackground ?? this.searchBackground,
      searchForeground: searchForeground ?? this.searchForeground,
      shortcutForeground: shortcutForeground ?? this.shortcutForeground,
      border: border ?? this.border,
      borderColor: borderColor ?? this.borderColor,
      width: width ?? this.width,
      maxHeight: maxHeight ?? this.maxHeight,
    );
  }
}

/// Theme data for dialog widgets ([DialogConfirm], [DialogAlert],
/// [DialogPrompt], [DialogSelect]).
///
/// Controls the visual appearance of modal dialogs and inline prompt panels.
class DialogThemeData {
  const DialogThemeData({
    this.background,
    this.foreground,
    this.overlayColor,
    this.overlayOpacity,
    this.buttonBackground,
    this.buttonSelectedBackground,
    this.buttonForeground,
    this.buttonSelectedForeground,
    this.hintForeground,
    this.footerBackground,
    this.width,
    this.maxHeight,
  });

  /// Background color of the dialog panel.
  /// Defaults to [Theme.surface].
  final Color? background;

  /// Default text color in the dialog.
  /// Defaults to [Theme.onSurface].
  final Color? foreground;

  /// Color of the modal overlay/backdrop.
  /// Defaults to [Theme.background].
  final Color? overlayColor;

  /// Opacity of the modal overlay (0.0–1.0).
  /// Defaults to 0.6.
  final double? overlayOpacity;

  /// Background color for action buttons in their default state.
  /// Defaults to [Theme.resolvedSurfaceVariant].
  final Color? buttonBackground;

  /// Background color for the selected/active action button.
  /// Defaults to [Theme.primary].
  final Color? buttonSelectedBackground;

  /// Text color for action buttons in their default state.
  /// Defaults to [Theme.onSurface].
  final Color? buttonForeground;

  /// Text color for the selected/active action button.
  /// Defaults to [Theme.onPrimary].
  final Color? buttonSelectedForeground;

  /// Text color for keyboard hint labels.
  /// Defaults to [Theme.muted].
  final Color? hintForeground;

  /// Background color for the footer bar in inline prompt panels.
  /// Defaults to [Theme.resolvedSurfaceVariant].
  final Color? footerBackground;

  /// Width of the dialog panel in columns.
  /// Defaults to 60.
  final int? width;

  /// Maximum height of the dialog panel in rows.
  /// Defaults to 20.
  final int? maxHeight;

  /// Copy with selective overrides.
  DialogThemeData copyWith({
    Color? background,
    Color? foreground,
    Color? overlayColor,
    double? overlayOpacity,
    Color? buttonBackground,
    Color? buttonSelectedBackground,
    Color? buttonForeground,
    Color? buttonSelectedForeground,
    Color? hintForeground,
    Color? footerBackground,
    int? width,
    int? maxHeight,
  }) {
    return DialogThemeData(
      background: background ?? this.background,
      foreground: foreground ?? this.foreground,
      overlayColor: overlayColor ?? this.overlayColor,
      overlayOpacity: overlayOpacity ?? this.overlayOpacity,
      buttonBackground: buttonBackground ?? this.buttonBackground,
      buttonSelectedBackground:
          buttonSelectedBackground ?? this.buttonSelectedBackground,
      buttonForeground: buttonForeground ?? this.buttonForeground,
      buttonSelectedForeground:
          buttonSelectedForeground ?? this.buttonSelectedForeground,
      hintForeground: hintForeground ?? this.hintForeground,
      footerBackground: footerBackground ?? this.footerBackground,
      width: width ?? this.width,
      maxHeight: maxHeight ?? this.maxHeight,
    );
  }
}

/// Theme data for [GitDiffViewer] widgets.
///
/// Controls the colors used for diff added/removed lines and context.
class GitDiffThemeData {
  const GitDiffThemeData({
    this.addedBackground,
    this.addedForeground,
    this.removedBackground,
    this.removedForeground,
    this.contextForeground,
    this.headerForeground,
  });

  /// Background color for added lines.
  /// Defaults to [Theme.success] with reduced intensity.
  final Color? addedBackground;

  /// Text color for added lines.
  /// Defaults to [Theme.resolvedOnSuccess].
  final Color? addedForeground;

  /// Background color for removed lines.
  /// Defaults to [Theme.error] with reduced intensity.
  final Color? removedBackground;

  /// Text color for removed lines.
  /// Defaults to [Theme.onError].
  final Color? removedForeground;

  /// Text color for context (unchanged) lines.
  /// Defaults to [Theme.muted].
  final Color? contextForeground;

  /// Text color for diff headers (@@ ... @@).
  /// Defaults to [Theme.primary].
  final Color? headerForeground;

  /// Copy with selective overrides.
  GitDiffThemeData copyWith({
    Color? addedBackground,
    Color? addedForeground,
    Color? removedBackground,
    Color? removedForeground,
    Color? contextForeground,
    Color? headerForeground,
  }) {
    return GitDiffThemeData(
      addedBackground: addedBackground ?? this.addedBackground,
      addedForeground: addedForeground ?? this.addedForeground,
      removedBackground: removedBackground ?? this.removedBackground,
      removedForeground: removedForeground ?? this.removedForeground,
      contextForeground: contextForeground ?? this.contextForeground,
      headerForeground: headerForeground ?? this.headerForeground,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Theme
// ─────────────────────────────────────────────────────────────────────────────

/// Theme containing semantic colors, text styles, and component themes.
class Theme {
  const Theme({
    // Core semantic colors (required)
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
    // Extended semantic colors (optional)
    this.surfaceVariant,
    this.onSurfaceVariant,
    this.outline,
    this.info,
    this.onSuccess,
    this.onWarning,
    this.onInfo,
    this.highlight,
    this.onHighlight,
    this.shadow,
    // Text styles (required)
    required this.titleLarge,
    required this.titleMedium,
    required this.titleSmall,
    required this.bodyLarge,
    required this.bodyMedium,
    required this.bodySmall,
    required this.labelLarge,
    required this.labelMedium,
    required this.labelSmall,
    // Component themes (optional)
    this.statusBarTheme,
    this.accentPanelTheme,
    this.commandPaletteTheme,
    this.dialogTheme,
    this.gitDiffTheme,
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // Core Semantic Colors
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
  // Extended Semantic Colors
  // ─────────────────────────────────────────────────────────────────────────────

  /// Alternate surface color for visual differentiation (e.g., sidebar vs main).
  /// Falls back to [surface] when null.
  final Color? surfaceVariant;

  /// Text color on [surfaceVariant] backgrounds.
  /// Falls back to [onSurface] when null.
  final Color? onSurfaceVariant;

  /// Subtle outline/divider color, lighter than [border].
  /// Falls back to [border] when null.
  final Color? outline;

  /// Informational color (e.g., help text, info badges).
  /// Falls back to [primary] when null.
  final Color? info;

  /// Text color on [success] backgrounds.
  /// Falls back to [onPrimary] when null.
  final Color? onSuccess;

  /// Text color on [warning] backgrounds.
  /// Falls back to [onPrimary] when null.
  final Color? onWarning;

  /// Text color on [info] backgrounds.
  /// Falls back to [onPrimary] when null.
  final Color? onInfo;

  /// Selection/highlight background color.
  /// Falls back to [primary] when null.
  final Color? highlight;

  /// Text color on [highlight] backgrounds.
  /// Falls back to [onPrimary] when null.
  final Color? onHighlight;

  /// Shadow/elevation hint color.
  /// Falls back to [muted] when null.
  final Color? shadow;

  // ─────────────────────────────────────────────────────────────────────────────
  // Resolved Extended Colors (convenience getters)
  // ─────────────────────────────────────────────────────────────────────────────

  /// Resolved [surfaceVariant], falling back to [surface].
  Color get resolvedSurfaceVariant => surfaceVariant ?? surface;

  /// Resolved [onSurfaceVariant], falling back to [onSurface].
  Color get resolvedOnSurfaceVariant => onSurfaceVariant ?? onSurface;

  /// Resolved [outline], falling back to [border].
  Color get resolvedOutline => outline ?? border;

  /// Resolved [info], falling back to [primary].
  Color get resolvedInfo => info ?? primary;

  /// Resolved [onSuccess], falling back to [onPrimary].
  Color get resolvedOnSuccess => onSuccess ?? onPrimary;

  /// Resolved [onWarning], falling back to [onPrimary].
  Color get resolvedOnWarning => onWarning ?? onPrimary;

  /// Resolved [onInfo], falling back to [onPrimary].
  Color get resolvedOnInfo => onInfo ?? onPrimary;

  /// Resolved [highlight], falling back to [primary].
  Color get resolvedHighlight => highlight ?? primary;

  /// Resolved [onHighlight], falling back to [onPrimary].
  Color get resolvedOnHighlight => onHighlight ?? onPrimary;

  /// Resolved [shadow], falling back to [muted].
  Color get resolvedShadow => shadow ?? muted;

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
  // Component Themes
  // ─────────────────────────────────────────────────────────────────────────────

  /// Theme overrides for [StatusBar] widgets.
  final StatusBarThemeData? statusBarTheme;

  /// Theme overrides for [AccentPanel] widgets.
  final AccentPanelThemeData? accentPanelTheme;

  /// Theme overrides for [CommandPalette] widgets.
  final CommandPaletteThemeData? commandPaletteTheme;

  /// Theme overrides for dialog widgets.
  final DialogThemeData? dialogTheme;

  /// Theme overrides for [GitDiffViewer] widgets.
  final GitDiffThemeData? gitDiffTheme;

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
      // Extended colors
      surfaceVariant: const AnsiColor(234), // Slightly lighter than background
      onSurfaceVariant: onSurface,
      outline: const AnsiColor(240), // Subtle divider
      info: const AnsiColor(39), // Cyan (same as primary)
      onSuccess: const AnsiColor(232), // Black on green
      onWarning: const AnsiColor(232), // Black on orange
      onInfo: const AnsiColor(232), // Black on cyan
      highlight: const AnsiColor(25), // Dark blue highlight
      onHighlight: const AnsiColor(255), // White on highlight
      shadow: const AnsiColor(232), // Near-black shadow
      // Text styles
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
      // Extended colors
      surfaceVariant: const AnsiColor(253), // Slightly darker than white
      onSurfaceVariant: onSurface,
      outline: const AnsiColor(248), // Subtle light divider
      info: const AnsiColor(33), // Blue (same as primary)
      onSuccess: const AnsiColor(255), // White on green
      onWarning: const AnsiColor(232), // Black on orange
      onInfo: const AnsiColor(255), // White on blue
      highlight: const AnsiColor(153), // Light blue highlight
      onHighlight: const AnsiColor(232), // Black on highlight
      shadow: const AnsiColor(248), // Light gray shadow
      // Text styles
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
    // Core semantic colors
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
    // Extended semantic colors
    Color? surfaceVariant,
    Color? onSurfaceVariant,
    Color? outline,
    Color? info,
    Color? onSuccess,
    Color? onWarning,
    Color? onInfo,
    Color? highlight,
    Color? onHighlight,
    Color? shadow,
    // Text styles
    Style? titleLarge,
    Style? titleMedium,
    Style? titleSmall,
    Style? bodyLarge,
    Style? bodyMedium,
    Style? bodySmall,
    Style? labelLarge,
    Style? labelMedium,
    Style? labelSmall,
    // Component themes
    StatusBarThemeData? statusBarTheme,
    AccentPanelThemeData? accentPanelTheme,
    CommandPaletteThemeData? commandPaletteTheme,
    DialogThemeData? dialogTheme,
    GitDiffThemeData? gitDiffTheme,
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
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      onSurfaceVariant: onSurfaceVariant ?? this.onSurfaceVariant,
      outline: outline ?? this.outline,
      info: info ?? this.info,
      onSuccess: onSuccess ?? this.onSuccess,
      onWarning: onWarning ?? this.onWarning,
      onInfo: onInfo ?? this.onInfo,
      highlight: highlight ?? this.highlight,
      onHighlight: onHighlight ?? this.onHighlight,
      shadow: shadow ?? this.shadow,
      titleLarge: titleLarge ?? this.titleLarge,
      titleMedium: titleMedium ?? this.titleMedium,
      titleSmall: titleSmall ?? this.titleSmall,
      bodyLarge: bodyLarge ?? this.bodyLarge,
      bodyMedium: bodyMedium ?? this.bodyMedium,
      bodySmall: bodySmall ?? this.bodySmall,
      labelLarge: labelLarge ?? this.labelLarge,
      labelMedium: labelMedium ?? this.labelMedium,
      labelSmall: labelSmall ?? this.labelSmall,
      statusBarTheme: statusBarTheme ?? this.statusBarTheme,
      accentPanelTheme: accentPanelTheme ?? this.accentPanelTheme,
      commandPaletteTheme: commandPaletteTheme ?? this.commandPaletteTheme,
      dialogTheme: dialogTheme ?? this.dialogTheme,
      gitDiffTheme: gitDiffTheme ?? this.gitDiffTheme,
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
      // Extended colors
      surfaceVariant: const AdaptiveColor(
        light: AnsiColor(253),
        dark: AnsiColor(234),
      ),
      onSurfaceVariant: onSurface,
      outline: const AdaptiveColor(light: AnsiColor(248), dark: AnsiColor(240)),
      info: primary,
      onSuccess: const AdaptiveColor(
        light: AnsiColor(255),
        dark: AnsiColor(232),
      ),
      onWarning: const AdaptiveColor(
        light: AnsiColor(232),
        dark: AnsiColor(232),
      ),
      onInfo: onPrimary,
      highlight: const AdaptiveColor(
        light: AnsiColor(153),
        dark: AnsiColor(25),
      ),
      onHighlight: const AdaptiveColor(
        light: AnsiColor(232),
        dark: AnsiColor(255),
      ),
      shadow: const AdaptiveColor(light: AnsiColor(248), dark: AnsiColor(232)),
      // Text styles
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
/// receives a terminal background color update.
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
