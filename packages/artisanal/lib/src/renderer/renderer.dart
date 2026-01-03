/// Renderer abstraction for terminal output.
///
/// Provides an interface for rendering styled content to different outputs,
/// with color profile detection and background detection.
///
/// ```dart
/// // Use the default terminal renderer
/// final renderer = TerminalRenderer();
/// print(renderer.colorProfile); // ColorProfile.trueColor
///
/// // Use a string renderer for testing
/// final testRenderer = StringRenderer();
/// style.render('Hello', renderer: testRenderer);
/// print(testRenderer.output);
/// ```
library;

import 'dart:io';

import '../colorprofile/detect.dart' as cp_detect;
import '../colorprofile/downsample.dart' as cp_downsample;
import '../colorprofile/profile.dart' as cp;
import '../style/color.dart';
import '../terminal/ansi.dart' show Ansi;

export '../style/color.dart' show ColorProfile;

/// Abstract interface for rendering styled output.
///
/// Implementations handle writing to different outputs (terminal, string buffer)
/// and provide information about the target's color capabilities.
abstract class Renderer {
  /// The color profile of the output target.
  ColorProfile get colorProfile;

  /// Sets the color profile for this renderer.
  set colorProfile(ColorProfile profile);

  /// Whether the output target has a dark background.
  ///
  /// Used by [AdaptiveColor] to select appropriate color variants.
  bool get hasDarkBackground;

  /// Sets whether this renderer has a dark background.
  set hasDarkBackground(bool value);

  /// Writes text to the output without a trailing newline.
  void write(String text);

  /// Writes text to the output followed by a newline.
  void writeln([String text = '']);

  /// Gets the output sink/writer for this renderer.
  ///
  /// Returns the underlying output destination.
  /// For [TerminalRenderer], this is the IOSink.
  /// For [StringRenderer], this returns null (use [output] getter instead).
  IOSink? get output;
}

/// A renderer that outputs to a terminal.
///
/// Automatically detects the terminal's color capabilities from
/// environment variables.
class TerminalRenderer implements Renderer {
  /// Creates a terminal renderer.
  ///
  /// If [output] is not provided, defaults to [stdout].
  /// If [forceProfile] is provided, uses that instead of auto-detection.
  /// If [forceDarkBackground] is provided, uses that instead of auto-detection.
  /// If [forceNoAnsi] is true, strips all ANSI escape sequences when writing.
  /// If [forceIsTty] is provided, it overrides TTY detection.
  TerminalRenderer({
    IOSink? output,
    ColorProfile? forceProfile,
    bool? forceDarkBackground,
    bool? forceNoAnsi,
    bool? forceIsTty,
  }) : _output = output ?? stdout,
       _overrideProfile = forceProfile,
       _overrideDarkBackground = forceDarkBackground,
       _overrideNoAnsi = forceNoAnsi,
       _overrideIsTty = forceIsTty;

  IOSink _output;
  ColorProfile? _overrideProfile;
  bool? _overrideDarkBackground;
  final bool? _overrideNoAnsi;
  final bool? _overrideIsTty;

  ColorProfile? _cachedProfile;
  bool? _cachedDarkBackground;
  cp.Profile? _cachedInternalProfile;

  @override
  ColorProfile get colorProfile {
    if (_overrideProfile != null) return _overrideProfile!;
    return _cachedProfile ??= _mapProfile(
      _cachedInternalProfile ??= _detectInternalProfile(),
    );
  }

  @override
  set colorProfile(ColorProfile profile) {
    _overrideProfile = profile;
  }

  @override
  bool get hasDarkBackground {
    if (_overrideDarkBackground != null) return _overrideDarkBackground!;
    return _cachedDarkBackground ??= _detectDarkBackground();
  }

  @override
  set hasDarkBackground(bool value) {
    _overrideDarkBackground = value;
  }

  @override
  IOSink get output => _output;

  /// Sets the output sink for this renderer.
  set output(IOSink sink) {
    _output = sink;
    _cachedProfile = null;
    _cachedInternalProfile = null;
  }

  @override
  void write(String text) {
    _output.write(_process(text));
  }

  @override
  void writeln([String text = '']) {
    _output.writeln(_process(text));
  }

  cp.Profile _detectInternalProfile() {
    return cp_detect.detectForSink(
      _output,
      env: Platform.environment,
      forceIsTty: _overrideIsTty,
    );
  }

  String _process(String text) {
    final p = _effectiveInternalProfile();

    if (p == cp.Profile.noTty) {
      return Ansi.stripAnsi(text);
    }

    if (p == cp.Profile.trueColor) {
      return text;
    }

    return cp_downsample.downsampleSgr(text, p);
  }

  cp.Profile _effectiveInternalProfile() {
    if (_overrideNoAnsi == true) return cp.Profile.noTty;

    if (_overrideProfile != null) {
      return _internalFromColorProfile(_overrideProfile!);
    }

    return _cachedInternalProfile ??= _detectInternalProfile();
  }

  static cp.Profile _internalFromColorProfile(ColorProfile profile) {
    return switch (profile) {
      ColorProfile.trueColor => cp.Profile.trueColor,
      ColorProfile.ansi256 => cp.Profile.ansi256,
      ColorProfile.ansi => cp.Profile.ansi,
      ColorProfile.noColor => cp.Profile.ascii,
      ColorProfile.ascii => cp.Profile.noTty,
    };
  }

  static ColorProfile _mapProfile(cp.Profile profile) {
    return switch (profile) {
      cp.Profile.trueColor => ColorProfile.trueColor,
      cp.Profile.ansi256 => ColorProfile.ansi256,
      cp.Profile.ansi => ColorProfile.ansi,
      cp.Profile.ascii => ColorProfile.noColor,
      cp.Profile.noTty => ColorProfile.ascii,
      cp.Profile.unknown => ColorProfile.ascii,
    };
  }

  /// Detects whether the terminal has a dark background.
  ///
  /// This is a heuristic based on common terminal configurations.
  /// Most terminals default to dark backgrounds, so we default to true.
  static bool _detectDarkBackground() {
    final env = Platform.environment;

    // Check for explicit COLORFGBG variable (format: "fg;bg")
    final colorFgBg = env['COLORFGBG'];
    if (colorFgBg != null) {
      final parts = colorFgBg.split(';');
      if (parts.length >= 2) {
        final bg = int.tryParse(parts.last);
        if (bg != null) {
          // ANSI colors 0-6 and 8 are typically dark
          // Colors 7 and 15 are light (white)
          return bg != 7 && bg != 15;
        }
      }
    }

    // Check for macOS Terminal.app with light theme
    final termProgram = env['TERM_PROGRAM'];
    if (termProgram == 'Apple_Terminal') {
      // Apple Terminal defaults to light, but many users change it
      // Default to dark as it's more common in developer setups
      return true;
    }

    // Most terminals default to dark backgrounds
    return true;
  }

  @override
  String toString() =>
      'TerminalRenderer(colorProfile: $colorProfile, darkBackground: $hasDarkBackground)';
}

/// A renderer that captures output to a string buffer.
///
/// Useful for testing styled output without terminal dependency.
///
/// ```dart
/// final renderer = StringRenderer();
/// style.render('Hello');
/// renderer.writeln('Hello');
///
/// expect(renderer.output, contains('Hello'));
/// renderer.clear();
/// ```
class StringRenderer implements Renderer {
  /// Creates a string renderer with optional configuration.
  ///
  /// [colorProfile] defaults to [ColorProfile.trueColor] for testing.
  /// [hasDarkBackground] defaults to true.
  StringRenderer({ColorProfile? colorProfile, bool? hasDarkBackground})
    : _colorProfile = colorProfile ?? ColorProfile.trueColor,
      _hasDarkBackground = hasDarkBackground ?? true;

  final StringBuffer _buffer = StringBuffer();

  ColorProfile _colorProfile;
  bool _hasDarkBackground;

  @override
  ColorProfile get colorProfile => _colorProfile;

  @override
  set colorProfile(ColorProfile profile) {
    _colorProfile = profile;
  }

  @override
  bool get hasDarkBackground => _hasDarkBackground;

  @override
  set hasDarkBackground(bool value) {
    _hasDarkBackground = value;
  }

  @override
  IOSink? get output => null;

  @override
  void write(String text) => _buffer.write(text);

  @override
  void writeln([String text = '']) => _buffer.writeln(text);

  /// Gets the captured output as a string.
  String get stringOutput => _buffer.toString();

  /// Gets the output and clears the buffer.
  String flush() {
    final result = _buffer.toString();
    _buffer.clear();
    return result;
  }

  /// Clears the captured output.
  void clear() => _buffer.clear();

  /// Whether the buffer is empty.
  bool get isEmpty => _buffer.isEmpty;

  /// Whether the buffer is not empty.
  bool get isNotEmpty => _buffer.isNotEmpty;

  /// The number of characters in the buffer.
  int get length => _buffer.length;

  @override
  String toString() =>
      'StringRenderer(colorProfile: $colorProfile, length: $length)';
}

/// A renderer that discards all output.
///
/// Useful for silencing output in quiet mode or benchmarking.
class NullRenderer implements Renderer {
  /// Creates a null renderer.
  NullRenderer({
    ColorProfile colorProfile = ColorProfile.ascii,
    bool hasDarkBackground = true,
  }) : _colorProfile = colorProfile,
       _hasDarkBackground = hasDarkBackground;

  ColorProfile _colorProfile;
  bool _hasDarkBackground;

  @override
  ColorProfile get colorProfile => _colorProfile;

  @override
  set colorProfile(ColorProfile profile) {
    _colorProfile = profile;
  }

  @override
  bool get hasDarkBackground => _hasDarkBackground;

  @override
  set hasDarkBackground(bool value) {
    _hasDarkBackground = value;
  }

  @override
  IOSink? get output => null;

  @override
  void write(String text) {}

  @override
  void writeln([String text = '']) {}

  @override
  String toString() => 'NullRenderer()';
}

// ─────────────────────────────────────────────────────────────────────────────
// Global Default Renderer
// ─────────────────────────────────────────────────────────────────────────────

/// The default renderer used when none is specified.
///
/// This is lazily initialized to a [TerminalRenderer] on first access.
/// You can replace it with a custom renderer for testing or other purposes.
Renderer? _defaultRenderer;

/// Gets the default renderer.
///
/// Returns a [TerminalRenderer] if not explicitly set.
Renderer get defaultRenderer => _defaultRenderer ??= TerminalRenderer();

/// Sets the default renderer.
///
/// Pass `null` to reset to the default [TerminalRenderer].
set defaultRenderer(Renderer? renderer) {
  _defaultRenderer = renderer;
}

/// Resets the default renderer to a new [TerminalRenderer].
void resetDefaultRenderer() {
  _defaultRenderer = null;
}
