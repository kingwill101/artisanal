/// Renderer abstraction for terminal output.
///
/// Provides an interface for rendering styled content to different outputs.
///
/// ```dart
/// // Use a string renderer for testing
/// final testRenderer = StringRenderer();
/// style.render('Hello', renderer: testRenderer);
/// print(testRenderer.output);
/// ```
library;

import '../style/color.dart';
import 'renderer_default_io.dart'
    if (dart.library.html) 'renderer_default_stub.dart'
    as renderer_default;

export '../style/color.dart' show ColorProfile;

export 'renderer_impl.dart' if (dart.library.html) 'renderer_stub.dart';

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

  /// Gets the underlying output sink/writer for this renderer, if available.
  Object? get output;
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
  Object? get output => null;

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
  Object? get output => null;

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
/// This is lazily initialized to a [NullRenderer] on first access
/// (or [TerminalRenderer] when `dart:io` is available).
/// You can replace it with a custom renderer for testing or other purposes.
Renderer? _defaultRenderer;

/// Gets the default renderer.
///
/// Returns a [NullRenderer] if not explicitly set
/// (or [TerminalRenderer] when `dart:io` is available).
Renderer get defaultRenderer =>
    _defaultRenderer ??= renderer_default.createDefaultRenderer();

/// Sets the default renderer.
///
/// Pass `null` to reset to the default.
set defaultRenderer(Renderer? renderer) {
  _defaultRenderer = renderer;
}

/// Resets the default renderer to a new default.
void resetDefaultRenderer() {
  _defaultRenderer = null;
}
