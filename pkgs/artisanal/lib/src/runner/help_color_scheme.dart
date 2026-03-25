import '../renderer/renderer.dart';
import '../style/color.dart';
import '../style/style.dart';

/// Color scheme for command help output.
///
/// Provides customizable colors for different parts of help text:
/// - headings (e.g., "Description:", "Usage:")
/// - commands (e.g., `serve`, `build`)
/// - options (e.g., `--port`, `-p`)
/// - descriptions
/// - error messages
///
/// Uses [AdaptiveColor] so colors automatically adapt to:
/// - Terminal color capabilities (ANSI vs truecolor)
/// - Light/dark terminal backgrounds
///
/// {@category Core}
///
/// ## Usage
///
/// ```dart
/// // Use a preset
/// runner.helpColorScheme = HelpColorScheme.dark();
///
/// // Or customize
/// runner.helpColorScheme = HelpColorScheme(
///   heading: AdaptiveColor(light: AnsiColor(33), dark: AnsiColor(39)),
///   command: AdaptiveColor(light: AnsiColor(28), dark: AnsiColor(35)),
/// );
/// ```
class HelpColorScheme {
  /// Creates a help color scheme with the given colors.
  ///
  /// All colors default to [AdaptiveColor] variants that work well on both
  /// light and dark terminals.
  const HelpColorScheme({
    this.heading,
    this.command,
    this.option,
    this.description,
    this.error,
    this.emphasis,
    this.namespace,
  });

  /// Color for section headings (e.g., "Description:", "Usage:").
  ///
  /// Default: yellow/amber (adaptive)
  final Color? heading;

  /// Color for command names.
  ///
  /// Default: green (adaptive)
  final Color? command;

  /// Color for option flags.
  ///
  /// Default: cyan (adaptive)
  final Color? option;

  /// Color for option descriptions.
  ///
  /// Default: none (uses default text color)
  final Color? description;

  /// Color for error messages.
  ///
  /// Default: red (adaptive)
  final Color? error;

  /// Color for emphasized text (e.g., quotes around command names).
  ///
  /// Default: bold only (no color change)
  final Color? emphasis;

  /// Color for namespace prefixes in command listings.
  ///
  /// Default: same as heading
  final Color? namespace;

  /// Default color scheme optimized for dark terminals.
  static HelpColorScheme dark() => const HelpColorScheme(
    heading: AdaptiveColor(
      light: BasicColor('#f59e0b'),
      dark: BasicColor('#fbbf24'),
    ),
    command: AdaptiveColor(
      light: BasicColor('#22c55e'),
      dark: BasicColor('#4ade80'),
    ),
    option: AdaptiveColor(
      light: BasicColor('#06b6d4'),
      dark: BasicColor('#22d3ee'),
    ),
    description: null,
    error: AdaptiveColor(
      light: BasicColor('#ef4444'),
      dark: BasicColor('#f87171'),
    ),
    emphasis: null,
    namespace: AdaptiveColor(
      light: BasicColor('#a855f7'),
      dark: BasicColor('#c084fc'),
    ),
  );

  /// Default color scheme optimized for light terminals.
  static HelpColorScheme light() => const HelpColorScheme(
    heading: AdaptiveColor(
      light: BasicColor('#d97706'),
      dark: BasicColor('#f59e0b'),
    ),
    command: AdaptiveColor(
      light: BasicColor('#16a34a'),
      dark: BasicColor('#22c55e'),
    ),
    option: AdaptiveColor(
      light: BasicColor('#0891b2'),
      dark: BasicColor('#06b6d4'),
    ),
    description: null,
    error: AdaptiveColor(
      light: BasicColor('#dc2626'),
      dark: BasicColor('#ef4444'),
    ),
    emphasis: null,
    namespace: AdaptiveColor(
      light: BasicColor('#7c3aed'),
      dark: BasicColor('#a855f7'),
    ),
  );

  /// Minimal color scheme using a single foreground color.
  ///
  /// Uses [foregroundColor] for all styled elements. Useful when you want
  /// a unified look or minimal color usage.
  static HelpColorScheme minimal(Color foregroundColor) => HelpColorScheme(
    heading: foregroundColor,
    command: foregroundColor,
    option: foregroundColor,
    description: null,
    error: foregroundColor,
    emphasis: null,
    namespace: foregroundColor,
  );

  /// Default color scheme (matches current behavior).
  static HelpColorScheme get default_ => const HelpColorScheme(
    heading: AdaptiveColor(
      light: BasicColor('#f59e0b'),
      dark: BasicColor('#fbbf24'),
    ),
    command: AdaptiveColor(
      light: BasicColor('#22c55e'),
      dark: BasicColor('#4ade80'),
    ),
    option: AdaptiveColor(
      light: BasicColor('#22c55e'),
      dark: BasicColor('#4ade80'),
    ),
    description: null,
    error: AdaptiveColor(
      light: BasicColor('#ef4444'),
      dark: BasicColor('#f87171'),
    ),
    emphasis: null,
    namespace: AdaptiveColor(
      light: BasicColor('#f59e0b'),
      dark: BasicColor('#fbbf24'),
    ),
  );

  /// Creates a copy of this scheme with the given fields replaced.
  HelpColorScheme copyWith({
    Color? heading,
    Color? command,
    Color? option,
    Color? description,
    Color? error,
    Color? emphasis,
    Color? namespace,
  }) {
    return HelpColorScheme(
      heading: heading ?? this.heading,
      command: command ?? this.command,
      option: option ?? this.option,
      description: description ?? this.description,
      error: error ?? this.error,
      emphasis: emphasis ?? this.emphasis,
      namespace: namespace ?? this.namespace,
    );
  }

  /// Resolves the heading color for the given renderer configuration.
  String resolveHeading(Renderer renderer) {
    final color = heading ?? HelpColorScheme.default_.heading!;
    return (Style()
          ..colorProfile = renderer.colorProfile
          ..hasDarkBackground = renderer.hasDarkBackground
          ..bold()
          ..foreground(color))
        .render('Heading');
  }

  /// Returns a styling function for headings.
  String Function(String) headingStyle(Renderer renderer) {
    final color = heading ?? HelpColorScheme.default_.heading!;
    return (text) =>
        (Style()
              ..colorProfile = renderer.colorProfile
              ..hasDarkBackground = renderer.hasDarkBackground
              ..bold()
              ..foreground(color))
            .render(text);
  }

  /// Returns a styling function for commands.
  String Function(String) commandStyle(Renderer renderer) {
    final color = command ?? HelpColorScheme.default_.command!;
    return (text) =>
        (Style()
              ..colorProfile = renderer.colorProfile
              ..hasDarkBackground = renderer.hasDarkBackground
              ..foreground(color))
            .render(text);
  }

  /// Returns a styling function for options.
  String Function(String) optionStyle(Renderer renderer) {
    final color = option ?? command ?? HelpColorScheme.default_.option!;
    return (text) =>
        (Style()
              ..colorProfile = renderer.colorProfile
              ..hasDarkBackground = renderer.hasDarkBackground
              ..foreground(color))
            .render(text);
  }

  /// Returns a styling function for error messages.
  String Function(String) errorStyle(Renderer renderer) {
    final color = error ?? HelpColorScheme.default_.error!;
    return (text) =>
        (Style()
              ..colorProfile = renderer.colorProfile
              ..hasDarkBackground = renderer.hasDarkBackground
              ..foreground(color))
            .render(text);
  }

  /// Returns a styling function for emphasized text.
  ///
  /// If [emphasis] is not set, returns a bold-only style (matching original behavior).
  String Function(String) emphasisStyle(Renderer renderer) {
    final color = emphasis;
    return (text) {
      final style = Style()
        ..colorProfile = renderer.colorProfile
        ..hasDarkBackground = renderer.hasDarkBackground
        ..bold();
      if (color != null) {
        style.foreground(color);
      }
      return style.render(text);
    };
  }

  /// Returns a styling function for namespaces.
  String Function(String) namespaceStyle(Renderer renderer) {
    final color = namespace ?? heading ?? HelpColorScheme.default_.namespace!;
    return (text) =>
        (Style()
              ..colorProfile = renderer.colorProfile
              ..hasDarkBackground = renderer.hasDarkBackground
              ..bold()
              ..foreground(color))
            .render(text);
  }
}
