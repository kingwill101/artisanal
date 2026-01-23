/// Base classes for display-only TUI components.
///
/// Provides [RenderConfig] for terminal rendering context and [DisplayComponent]
/// as the base class for all static display components.
///
/// ## Usage
///
/// ```dart
/// // Create a render config from current terminal state
/// final config = RenderConfig(
///   terminalWidth: 80,
///   colorProfile: ColorProfile.trueColor,
///   hasDarkBackground: true,
/// );
///
/// // Or create from an existing renderer
/// final config = RenderConfig.fromRenderer(renderer, terminalWidth: 100);
///
/// // Use with components
/// final text = StyledText.success('Done!', renderConfig: config);
/// print(text.render());
/// ```
///
/// {@category TUI}
library;

import '../../../renderer/renderer.dart' show Renderer;
import '../../../style/color.dart';
import '../../../style/style.dart';
import '../../component.dart' as tui;

/// Rendering configuration for display-only UI building blocks.
///
/// Carries terminal state needed to render components correctly:
/// - [terminalWidth]: Available width for text wrapping and layout
/// - [colorProfile]: Terminal color capabilities for ANSI output
/// - [hasDarkBackground]: Whether to use dark-optimized colors
///
/// Bubble models render plain strings from `view()`. These components follow the
/// same convention by rendering to strings and letting the caller decide how to
/// print them (or compose them into a parent model's view).
///
/// ## Example
///
/// ```dart
/// final config = RenderConfig(
///   terminalWidth: 120,
///   colorProfile: ColorProfile.ansi256,
///   hasDarkBackground: false, // Light terminal
/// );
///
/// final alert = Alert.warning('Low disk space', renderConfig: config);
/// print(alert.render());
/// ```
///
/// {@category TUI}
///
/// {@macro artisanal_bubbles_display_components}
class RenderConfig {
  /// Creates a render configuration with the given settings.
  ///
  /// - [terminalWidth]: Width in columns for layout (default: 80)
  /// - [colorProfile]: Terminal color capabilities (default: trueColor)
  /// - [hasDarkBackground]: Dark background for adaptive colors (default: true)
  const RenderConfig({
    this.terminalWidth = 80,
    this.colorProfile = ColorProfile.trueColor,
    this.hasDarkBackground = true,
  });

  /// Creates a [RenderConfig] from a [Renderer]'s detected settings.
  ///
  /// Copies the renderer's color profile and background detection.
  /// The [terminalWidth] must be provided separately.
  factory RenderConfig.fromRenderer(
    Renderer renderer, {
    int terminalWidth = 80,
  }) => RenderConfig(
    terminalWidth: terminalWidth,
    colorProfile: renderer.colorProfile,
    hasDarkBackground: renderer.hasDarkBackground,
  );

  /// Terminal width in columns for text wrapping and layout.
  final int terminalWidth;

  /// Terminal color capabilities for ANSI output.
  ///
  /// Components use this to downsample colors appropriately:
  /// - [ColorProfile.trueColor]: Full 24-bit RGB
  /// - [ColorProfile.ansi256]: 256-color palette
  /// - [ColorProfile.ansi]: 16-color palette
  /// - [ColorProfile.noColor]: No color codes
  /// - [ColorProfile.ascii]: Strip all ANSI sequences
  final ColorProfile colorProfile;

  /// Whether the terminal has a dark background.
  ///
  /// When true, adaptive colors use their dark variants.
  /// When false, adaptive colors use their light variants.
  ///
  /// This affects:
  /// - [AdaptiveColor] resolution
  /// - Syntax highlighting theme selection
  /// - Default text/background contrast choices
  final bool hasDarkBackground;

  /// Configures a [Style] with this config's color profile and background.
  ///
  /// Returns the modified style for method chaining.
  Style configureStyle(Style style) {
    style
      ..colorProfile = colorProfile
      ..hasDarkBackground = hasDarkBackground;
    return style;
  }
}

/// Base type for display-only UI building blocks.
///
/// Display components are stateless, render-only widgets that produce
/// styled terminal output. They don't handle input or maintain state.
///
/// Subclasses implement [render] to produce their output string.
/// The [view] method (from [StaticComponent]) delegates to [render].
///
/// ## Example
///
/// ```dart
/// class MyBadge extends DisplayComponent {
///   const MyBadge(this.label);
///   final String label;
///
///   @override
///   String render() {
///     return Style().bold().background(Colors.blue).render(' $label ');
///   }
/// }
/// ```
abstract class DisplayComponent extends tui.StaticComponent {
  const DisplayComponent();

  /// Renders the component as a styled string.
  ///
  /// Subclasses implement this to produce their ANSI-styled output.
  String render();

  @override
  String view() => render();

  /// Number of lines in the rendered output.
  int get lineCount => render().split('\n').length;

  @override
  String toString() => render();
}
