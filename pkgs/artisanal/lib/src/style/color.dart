/// Color system for the fluent style library.
///
/// Provides a flexible color abstraction supporting:
/// - Hex colors (`#ff0000`)
/// - ANSI color codes (0-255)
/// - Adaptive colors (light/dark terminal)
/// - Complete colors (per-profile explicit)
///
/// ```dart
/// // Hex color
/// Style().foreground(Colors.red)
/// Style().foreground(BasicColor('#ff5500'))
///
/// // ANSI code
/// Style().foreground(AnsiColor(196))
///
/// // Adaptive (auto light/dark)
/// Style().foreground(AdaptiveColor(
///   light: Colors.black,
///   dark: Colors.white,
/// ))
/// ```
library;

import '../colorprofile/convert.dart' as cp;
import '../colorprofile/profile.dart' as cp;

/// Color profile indicating terminal color capabilities.
enum ColorProfile {
  /// No ANSI support (plain text, no decoration).
  ascii,

  /// ANSI SGR supported, but colors are disabled.
  ///
  /// This corresponds to the `NO_COLOR` convention: keep text decoration
  /// (bold/italic/etc.) but drop colors.
  noColor,

  /// Basic 16-color ANSI support.
  ansi,

  /// 256-color ANSI support.
  ansi256,

  /// True color (24-bit RGB) support.
  trueColor,
}

/// Extension to convert from internal [cp.Profile] to [ColorProfile].
extension ColorProfileConverter on ColorProfile {
  /// Converts an internal [cp.Profile] to a [ColorProfile].
  static ColorProfile fromProfile(cp.Profile profile) {
    return switch (profile) {
      cp.Profile.unknown || cp.Profile.noTty => ColorProfile.ascii,
      cp.Profile.ascii => ColorProfile.ascii,
      cp.Profile.ansi => ColorProfile.ansi,
      cp.Profile.ansi256 => ColorProfile.ansi256,
      cp.Profile.trueColor => ColorProfile.trueColor,
    };
  }
}

/// Abstract base class for terminal colors.
///
/// All color types implement this interface to produce ANSI escape sequences.
///
/// {@category Style}
///
/// {@macro artisanal_style_colors}
abstract class Color {
  const Color();

  /// Produces the ANSI escape sequence for this color.
  ///
  /// [profile] indicates the terminal's color capabilities.
  /// [background] if true, produces background color sequence.
  /// [underline] if true, produces underline color sequence (SGR 58).
  /// [hasDarkBackground] hints whether terminal has dark background (for adaptive colors).
  String toAnsi(
    ColorProfile profile, {
    bool background = false,
    bool underline = false,
    bool hasDarkBackground = true,
  });

  /// Returns a dimmed version of this color (if applicable).
  Color get dim => this;

  /// Returns the hex representation of this color.
  String toHex();
}

/// A color specified as a hex string or ANSI string code.
///
/// Supports:
/// - Hex colors: `#ff0000`, `#f00`, `ff0000`
/// - ANSI string codes: `196`, `21`
///
/// ```dart
/// final red = BasicColor('#ff0000');
/// final blue = BasicColor('21');
/// ```
class BasicColor extends Color {
  /// Creates a color from a hex string or ANSI code string.
  const BasicColor(this.value);

  /// The color value (hex string or ANSI code).
  final String value;

  /// Whether this is a hex color.
  bool get isHex => value.startsWith('#') || _isHexString(value);

  static bool _isHexString(String s) {
    if (s.length != 6 && s.length != 3) return false;
    // Must contain hex digits
    if (!RegExp(r'^[0-9a-fA-F]+$').hasMatch(s)) return false;
    // For 3-char strings, distinguish hex colors from ANSI codes:
    // Pure numeric strings like '196' are ANSI codes, not hex colors
    // Hex shorthand like 'f00' must contain at least one letter a-f
    if (s.length == 3 && RegExp(r'^[0-9]+$').hasMatch(s)) {
      return false;
    }
    return true;
  }

  /// Normalizes hex value to 6-character format with #.
  String get _normalizedHex {
    var hex = value.replaceFirst('#', '');
    if (hex.length == 3) {
      hex = hex.split('').map((c) => '$c$c').join();
    }
    return '#$hex';
  }

  @override
  String toAnsi(
    ColorProfile profile, {
    bool background = false,
    bool underline = false,
    bool hasDarkBackground = true,
  }) {
    if (isHex) {
      if (profile == ColorProfile.ascii || profile == ColorProfile.noColor) {
        return '';
      }

      final rgb = _parseHexRgb(_normalizedHex);
      return cp.sgrColor(
        profile: _toInternalProfile(profile),
        background: background,
        underline: underline,
        rgb: cp.Rgb(rgb.$1, rgb.$2, rgb.$3),
      );
    } else {
      // ANSI code
      if (profile == ColorProfile.ascii || profile == ColorProfile.noColor) {
        return '';
      }

      final code = (int.tryParse(value) ?? 0).clamp(0, 255);

      // lipgloss v2 parity: prefer 16-color SGR codes when possible.
      // Note: Underline color (SGR 58) does not have 16-color variants.
      if (code <= 15 && !underline) {
        final base = background ? 40 : 30;
        final brightBase = background ? 100 : 90;
        if (code < 8) {
          return '\x1b[${base + code}m';
        }
        return '\x1b[${brightBase + (code - 8)}m';
      }

      return cp.sgrColor(
        profile: _toInternalProfile(profile),
        background: background,
        underline: underline,
        ansi256: code,
      );
    }
  }

  @override
  Color get dim => isHex ? BasicColor(_dimHex(_normalizedHex)) : this;

  @override
  String toHex() => isHex ? _normalizedHex : '';

  static String _dimHex(String hex) {
    // Reduce brightness by 40%
    final r = int.parse(hex.substring(1, 3), radix: 16);
    final g = int.parse(hex.substring(3, 5), radix: 16);
    final b = int.parse(hex.substring(5, 7), radix: 16);
    final dr = (r * 0.6).round().clamp(0, 255);
    final dg = (g * 0.6).round().clamp(0, 255);
    final db = (b * 0.6).round().clamp(0, 255);
    return '#${dr.toRadixString(16).padLeft(2, '0')}'
        '${dg.toRadixString(16).padLeft(2, '0')}'
        '${db.toRadixString(16).padLeft(2, '0')}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is BasicColor && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'BasicColor($value)';
}

/// An explicit ANSI color code (0-255).
///
/// Use this when you want to specify an exact ANSI-256 color code.
///
/// ```dart
/// final red = AnsiColor(196);
/// final blue = AnsiColor(21);
/// ```
class AnsiColor extends Color {
  /// Creates an ANSI color from a code (0-255).
  const AnsiColor(this.code) : assert(code >= 0 && code <= 255);

  /// The ANSI color code (0-255).
  final int code;

  @override
  String toAnsi(
    ColorProfile profile, {
    bool background = false,
    bool underline = false,
    bool hasDarkBackground = true,
  }) {
    if (profile == ColorProfile.ascii || profile == ColorProfile.noColor) {
      return '';
    }

    if (profile == ColorProfile.ansi && code >= 16) {
      // Degrade to ANSI-16.
      return cp.sgrColor(
        profile: cp.Profile.ansi,
        background: background,
        underline: underline,
        ansi16: cp.ansi256ToAnsi16(code),
      );
    }

    if (underline) {
      // SGR 58 uses xterm-style colon parameters for underline color.
      return '\x1B[58:5:${code}m';
    }
    final p = background ? 48 : 38;
    return '\x1B[$p;5;${code}m';
  }

  @override
  String toHex() => '';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is AnsiColor && other.code == code);

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'AnsiColor($code)';
}

/// An adaptive color that switches based on terminal background.
///
/// Automatically uses [light] variant on light terminals and [dark]
/// variant on dark terminals.
///
/// ```dart
/// final textColor = AdaptiveColor(
///   light: Colors.black,
///   dark: Colors.white,
/// );
/// ```
class AdaptiveColor extends Color {
  /// Creates an adaptive color with light and dark variants.
  const AdaptiveColor({required this.light, required this.dark});

  /// Color to use on light backgrounds.
  final Color light;

  /// Color to use on dark backgrounds.
  final Color dark;

  @override
  String toAnsi(
    ColorProfile profile, {
    bool background = false,
    bool underline = false,
    bool hasDarkBackground = true,
  }) {
    final color = hasDarkBackground ? dark : light;
    return color.toAnsi(
      profile,
      background: background,
      underline: underline,
      hasDarkBackground: hasDarkBackground,
    );
  }

  @override
  Color get dim => AdaptiveColor(light: light.dim, dark: dark.dim);

  @override
  String toHex() => dark.toHex();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdaptiveColor && other.light == light && other.dark == dark);

  @override
  int get hashCode => Object.hash(light, dark);

  @override
  String toString() => 'AdaptiveColor(light: $light, dark: $dark)';
}

/// A color with explicit values for each color profile.
///
/// Use this when you want full control over color appearance at each
/// capability level, without automatic degradation.
///
/// ```dart
/// final brand = CompleteColor(
///   trueColor: '#ff5500',
///   ansi256: '208',
///   ansi: '1',  // Red as fallback
/// );
/// ```
class CompleteColor extends Color {
  /// Creates a complete color with per-profile values.
  const CompleteColor({required this.trueColor, this.ansi256, this.ansi});

  /// True color (24-bit) hex value.
  final String trueColor;

  /// ANSI-256 color code (as string).
  final String? ansi256;

  /// Basic ANSI color code (as string, 0-7 or 0-15).
  final String? ansi;

  @override
  String toAnsi(
    ColorProfile profile, {
    bool background = false,
    bool underline = false,
    bool hasDarkBackground = true,
  }) {
    switch (profile) {
      case ColorProfile.ascii:
      case ColorProfile.noColor:
        return '';
      case ColorProfile.ansi:
        if (ansi != null) {
          final code = int.tryParse(ansi!) ?? 0;
          final p = underline ? 58 : (background ? 40 : 30);
          // Note: Underline color (SGR 58) does not have 16-color variants,
          // but we use 58;5;N as a fallback if needed.
          if (underline) {
            return '\x1B[58;5;${code}m';
          }
          return '\x1B[${p + code}m';
        }
        // Fall through to ansi256
        continue ansi256Case;
      ansi256Case:
      case ColorProfile.ansi256:
        if (ansi256 != null) {
          final code = int.tryParse(ansi256!) ?? 0;
          final p = underline ? 58 : (background ? 48 : 38);
          return '\x1B[$p;5;${code}m';
        }
        // Fall through to trueColor
        continue trueColorCase;
      trueColorCase:
      case ColorProfile.trueColor:
        return BasicColor(trueColor).toAnsi(
          profile,
          background: background,
          underline: underline,
          hasDarkBackground: hasDarkBackground,
        );
    }
  }

  @override
  String toHex() => trueColor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CompleteColor &&
          other.trueColor == trueColor &&
          other.ansi256 == ansi256 &&
          other.ansi == ansi);

  @override
  int get hashCode => Object.hash(trueColor, ansi256, ansi);

  @override
  String toString() =>
      'CompleteColor(trueColor: $trueColor, ansi256: $ansi256, ansi: $ansi)';
}

/// A color with explicit values for each profile, with light and dark variants.
///
/// Combines [CompleteColor] with adaptive background detection.
/// Use this when you need full control over color appearance at each
/// capability level AND need to adapt to light/dark backgrounds.
///
/// ```dart
/// final brand = CompleteAdaptiveColor(
///   light: CompleteColor(
///     trueColor: '#0044aa',
///     ansi256: '25',
///     ansi: '4',  // Blue
///   ),
///   dark: CompleteColor(
///     trueColor: '#66aaff',
///     ansi256: '117',
///     ansi: '6',  // Cyan
///   ),
/// );
/// ```
class CompleteAdaptiveColor extends Color {
  /// Creates a complete adaptive color with light and dark variants.
  const CompleteAdaptiveColor({required this.light, required this.dark});

  /// Complete color to use on light backgrounds.
  final CompleteColor light;

  /// Complete color to use on dark backgrounds.
  final CompleteColor dark;

  @override
  String toAnsi(
    ColorProfile profile, {
    bool background = false,
    bool underline = false,
    bool hasDarkBackground = true,
  }) {
    final color = hasDarkBackground ? dark : light;
    return color.toAnsi(
      profile,
      background: background,
      underline: underline,
      hasDarkBackground: hasDarkBackground,
    );
  }

  @override
  Color get dim => CompleteAdaptiveColor(
    light: CompleteColor(
      trueColor: BasicColor(light.trueColor).dim is BasicColor
          ? (BasicColor(light.trueColor).dim as BasicColor).value
          : light.trueColor,
      ansi256: light.ansi256,
      ansi: light.ansi,
    ),
    dark: CompleteColor(
      trueColor: BasicColor(dark.trueColor).dim is BasicColor
          ? (BasicColor(dark.trueColor).dim as BasicColor).value
          : dark.trueColor,
      ansi256: dark.ansi256,
      ansi: dark.ansi,
    ),
  );

  @override
  String toHex() => dark.toHex();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CompleteAdaptiveColor &&
          other.light == light &&
          other.dark == dark);

  @override
  int get hashCode => Object.hash(light, dark);

  @override
  String toString() => 'CompleteAdaptiveColor(light: $light, dark: $dark)';
}

/// No color (absence of color styling).
///
/// Use this to explicitly indicate no color should be applied.
class NoColor extends Color {
  const NoColor();

  @override
  String toAnsi(
    ColorProfile profile, {
    bool background = false,
    bool underline = false,
    bool hasDarkBackground = true,
  }) => '';

  @override
  String toHex() => '';

  @override
  bool operator ==(Object other) => other is NoColor;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'NoColor()';
}

/// Semantic and named color presets.
///
/// Provides commonly used colors for CLI applications.
///
/// ```dart
/// Style().foreground(Colors.success)
/// Style().foreground(Colors.red)
/// Style().background(Colors.gray)
/// ```
class Colors {
  Colors._();

  // ─────────────────────────────────────────────────────────────────────────────
  // Semantic Colors
  // ─────────────────────────────────────────────────────────────────────────────

  /// Success color (green).
  static const success = BasicColor('#22c55e');

  /// Error color (red).
  static const error = BasicColor('#ef4444');

  /// Warning color (yellow/amber).
  static const warning = BasicColor('#f59e0b');

  /// Info color (blue).
  static const info = BasicColor('#3b82f6');

  /// Muted/dimmed color (gray).
  static const muted = BasicColor('#6b7280');

  // ─────────────────────────────────────────────────────────────────────────────
  // Basic Named Colors
  // ─────────────────────────────────────────────────────────────────────────────

  /// Black.
  static const black = BasicColor('#000000');

  /// Red.
  static const red = BasicColor('#ef4444');

  /// Green.
  static const green = BasicColor('#22c55e');

  /// Yellow.
  static const yellow = BasicColor('#eab308');

  /// Blue.
  static const blue = BasicColor('#3b82f6');

  /// Magenta/Purple.
  static const magenta = BasicColor('#a855f7');

  /// Cyan.
  static const cyan = BasicColor('#06b6d4');

  /// White.
  static const white = BasicColor('#ffffff');

  // ─────────────────────────────────────────────────────────────────────────────
  // Bright Variants
  // ─────────────────────────────────────────────────────────────────────────────

  /// Bright black (dark gray).
  static const brightBlack = BasicColor('#4b5563');

  /// Bright red.
  static const brightRed = BasicColor('#f87171');

  /// Bright green.
  static const brightGreen = BasicColor('#4ade80');

  /// Bright yellow.
  static const brightYellow = BasicColor('#facc15');

  /// Bright blue.
  static const brightBlue = BasicColor('#60a5fa');

  /// Bright magenta.
  static const brightMagenta = BasicColor('#c084fc');

  /// Bright cyan.
  static const brightCyan = BasicColor('#22d3ee');

  /// Bright white.
  static const brightWhite = BasicColor('#f9fafb');

  // ─────────────────────────────────────────────────────────────────────────────
  // Gray Scale
  // ─────────────────────────────────────────────────────────────────────────────

  /// Lightest gray.
  static const gray50 = BasicColor('#f9fafb');

  /// Very light gray.
  static const gray100 = BasicColor('#f3f4f6');

  /// Light gray.
  static const gray200 = BasicColor('#e5e7eb');

  /// Light-medium gray.
  static const gray300 = BasicColor('#d1d5db');

  /// Medium gray.
  static const gray400 = BasicColor('#9ca3af');

  /// Gray.
  static const gray = BasicColor('#6b7280');

  /// Medium-dark gray.
  static const gray600 = BasicColor('#4b5563');

  /// Dark gray.
  static const gray700 = BasicColor('#374151');

  /// Very dark gray.
  static const gray800 = BasicColor('#1f2937');

  /// Darkest gray.
  static const gray900 = BasicColor('#111827');

  // ─────────────────────────────────────────────────────────────────────────────
  // Accent Colors
  // ─────────────────────────────────────────────────────────────────────────────

  /// Purple accent.
  static const purple = BasicColor('#a855f7');

  /// Pink accent.
  static const pink = BasicColor('#ec4899');

  /// Orange accent.
  static const orange = BasicColor('#f97316');

  /// Teal accent.
  static const teal = BasicColor('#14b8a6');

  /// Indigo accent.
  static const indigo = BasicColor('#6366f1');

  /// Rose accent.
  static const rose = BasicColor('#f43f5e');

  /// Lime accent.
  static const lime = BasicColor('#84cc16');

  /// Sky blue accent.
  static const sky = BasicColor('#0ea5e9');

  // ─────────────────────────────────────────────────────────────────────────────
  // Special
  // ─────────────────────────────────────────────────────────────────────────────

  /// No color (transparent).
  static const none = NoColor();

  /// Creates an adaptive color from light and dark variants.
  static AdaptiveColor adaptive({required Color light, required Color dark}) {
    return AdaptiveColor(light: light, dark: dark);
  }

  /// Creates a color from a hex string.
  static BasicColor hex(String value) => BasicColor(value);

  /// Creates a color from an ANSI-256 code.
  static AnsiColor ansi(int code) => AnsiColor(code);

  /// Creates a color from RGB values.
  static BasicColor rgb(int r, int g, int b) {
    final hex =
        '#${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}';
    return BasicColor(hex);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper Functions
// ─────────────────────────────────────────────────────────────────────────────

cp.Profile _toInternalProfile(ColorProfile profile) {
  return switch (profile) {
    ColorProfile.trueColor => cp.Profile.trueColor,
    ColorProfile.ansi256 => cp.Profile.ansi256,
    ColorProfile.ansi => cp.Profile.ansi,
    ColorProfile.noColor => cp.Profile.ascii,
    ColorProfile.ascii => cp.Profile.noTty,
  };
}

(int, int, int) _parseHexRgb(String hex) {
  final normalized = hex.startsWith('#') ? hex.substring(1) : hex;
  final r = int.parse(normalized.substring(0, 2), radix: 16);
  final g = int.parse(normalized.substring(2, 4), radix: 16);
  final b = int.parse(normalized.substring(4, 6), radix: 16);
  return (r, g, b);
}
