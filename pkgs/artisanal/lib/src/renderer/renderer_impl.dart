import 'dart:io';

import '../colorprofile/detect_impl.dart' as cp_detect;
import '../colorprofile/downsample.dart' as cp_downsample;
import '../colorprofile/profile.dart' as cp;
import '../style/color.dart' show ColorProfile;
import '../terminal/ansi.dart' show Ansi;
import 'renderer.dart' show Renderer;

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
    final colorFgBg = env['COLORFGBG'];
    if (colorFgBg != null) {
      final parts = colorFgBg.split(';');
      if (parts.length >= 2) {
        final bg = int.tryParse(parts.last);
        if (bg != null) {
          return bg != 7 && bg != 15;
        }
      }
    }
    final termProgram = env['TERM_PROGRAM'];
    if (termProgram == 'Apple_Terminal') {
      return true;
    }
    return true;
  }

  @override
  String toString() =>
      'TerminalRenderer(colorProfile: $colorProfile, darkBackground: $hasDarkBackground)';
}
