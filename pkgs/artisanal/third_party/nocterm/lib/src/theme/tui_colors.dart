import '../style.dart';
import 'adaptive_color.dart';

/// Semantic color constants that adapt to light and dark themes.
///
/// These colors are designed to work well in both light and dark themes,
/// automatically providing appropriate contrast. Use these colors instead
/// of hardcoded color values to ensure your UI looks good in all themes.
///
/// Example:
/// ```dart
/// // Instead of:
/// TextStyle(color: Colors.blue)
///
/// // Use:
/// TextStyle(color: TuiColors.primary.resolve(theme.brightness))
/// ```
abstract class TuiColors {
  // Prevent instantiation
  TuiColors._();

  // ===== Background Colors =====

  /// The main background color for the application.
  static const AdaptiveColor background = AdaptiveColor(
    light: Color(0xFAFAFA),
    dark: Color(0x18181C),
  );

  /// Text/icon color on top of [background].
  static const AdaptiveColor onBackground = AdaptiveColor(
    light: Color(0x18181C),
    dark: Color(0xF8F8F2),
  );

  // ===== Surface Colors =====

  /// Surface colors for widgets like cards, dialogs, menus.
  static const AdaptiveColor surface = AdaptiveColor(
    light: Color(0xFFFFFF),
    dark: Color(0x24242A),
  );

  /// Text/icon color on top of [surface].
  static const AdaptiveColor onSurface = AdaptiveColor(
    light: Color(0x18181C),
    dark: Color(0xF8F8F2),
  );

  // ===== Primary Colors =====

  /// The primary accent color for branding and emphasis.
  static const AdaptiveColor primary = AdaptiveColor(
    light: Color(0x4F77B8),
    dark: Color(0x8BB3F4),
  );

  /// Text/icon color on top of [primary].
  static const AdaptiveColor onPrimary = AdaptiveColor(
    light: Color(0xFFFFFF),
    dark: Color(0x18181C),
  );

  // ===== Secondary Colors =====

  /// Alternative accent color for secondary emphasis.
  static const AdaptiveColor secondary = AdaptiveColor(
    light: Color(0x6B7280),
    dark: Color(0x9CA3AF),
  );

  /// Text/icon color on top of [secondary].
  static const AdaptiveColor onSecondary = AdaptiveColor(
    light: Color(0xFFFFFF),
    dark: Color(0x18181C),
  );

  // ===== Error Colors =====

  /// Color for error states and destructive actions.
  static const AdaptiveColor error = AdaptiveColor(
    light: Color(0xBF3948),
    dark: Color(0xE76170),
  );

  /// Text/icon color on top of [error].
  static const AdaptiveColor onError = AdaptiveColor(
    light: Color(0xFFFFFF),
    dark: Color(0x18181C),
  );

  // ===== Status Colors =====

  /// Color for success states.
  static const AdaptiveColor success = AdaptiveColor(
    light: Color(0x3B995C),
    dark: Color(0x8BD598),
  );

  /// Text/icon color on top of [success].
  static const AdaptiveColor onSuccess = AdaptiveColor(
    light: Color(0xFFFFFF),
    dark: Color(0x18181C),
  );

  /// Color for warning states.
  static const AdaptiveColor warning = AdaptiveColor(
    light: Color(0xB5994D),
    dark: Color(0xF1D589),
  );

  /// Text/icon color on top of [warning].
  static const AdaptiveColor onWarning = AdaptiveColor(
    light: Color(0x18181C),
    dark: Color(0x18181C),
  );

  // ===== Outline Colors =====

  /// Color for borders and dividers.
  static const AdaptiveColor outline = AdaptiveColor(
    light: Color(0x6A717E),
    dark: Color(0x9299A6),
  );

  /// Lighter variant of outline for subtle borders.
  static const AdaptiveColor outlineVariant = AdaptiveColor(
    light: Color(0xD1D5DB),
    dark: Color(0x4B5563),
  );
}
