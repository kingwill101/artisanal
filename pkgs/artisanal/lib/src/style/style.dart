/// Fluent, chainable style builder for CLI output.
///
/// Inspired by Go's lipgloss library, this provides a composable way
/// to build text styles for terminal output.
///
/// ```dart
/// final style = Style()
///     .bold()
///     .foreground(Colors.green)
///     .padding(1, 2)
///     .border(Border.rounded)
///     .width(40);
///
/// print(style.render('Hello World'));
///
/// // Style inheritance
/// final derived = baseStyle.copy()..inherit(overrideStyle);
/// ```
library;

import 'dart:math' as math;

import 'border.dart';
import 'blending.dart' as blend;
import 'chars.dart';
import 'color.dart';
import 'properties.dart';
import 'ranges.dart' as ranges;
import 'style_model.dart';
import 'tag_parser.dart';
import '../layout/layout.dart';
import '../renderer/renderer.dart';
import '../terminal/ansi.dart';
import '../tui/trace.dart';
import 'package:ultraviolet/unicode.dart' as uni;
import 'package:ultraviolet/rendering.dart' as uv_wrap;

const int _styleRenderTraceThresholdUs = 5000;

void _traceStyleRender(String message, Stopwatch? sw) {
  if (sw == null) return;
  sw.stop();
  if (sw.elapsedMicroseconds < _styleRenderTraceThresholdUs) return;
  TuiTrace.log('$message ${sw.elapsedMicroseconds}us', tag: TraceTag.render);
}

// ─────────────────────────────────────────────────────────────────────────────
// Property Bits
// ─────────────────────────────────────────────────────────────────────────────

/// Bitfield flags for tracking which properties have been explicitly set.
class _PropBits {
  static const int bold = 1 << 0;
  static const int italic = 1 << 1;
  static const int underline = 1 << 2;
  static const int strikethrough = 1 << 3;
  static const int dim = 1 << 4;
  static const int inverse = 1 << 5;
  static const int blink = 1 << 6;
  static const int foreground = 1 << 7;
  static const int background = 1 << 8;
  static const int width = 1 << 9;
  static const int height = 1 << 10;
  static const int padding = 1 << 11;
  static const int paddingTop = 1 << 12;
  static const int paddingRight = 1 << 13;
  static const int paddingBottom = 1 << 14;
  static const int paddingLeft = 1 << 15;
  static const int margin = 1 << 16;
  static const int marginTop = 1 << 17;
  static const int marginRight = 1 << 18;
  static const int marginBottom = 1 << 19;
  static const int marginLeft = 1 << 20;
  static const int align = 1 << 21;
  static const int border = 1 << 22;
  static const int borderSides = 1 << 23;
  static const int borderForeground = 1 << 24;
  static const int borderBackground = 1 << 25;
  static const int maxWidth = 1 << 26;
  static const int maxHeight = 1 << 27;
  static const int inline = 1 << 28;
  static const int transform = 1 << 29;
  static const int alignVertical = 1 << 30;
  // Per-side border colors use a separate bitfield (_borderProps)

  // Additional properties (using a second bitfield _props2)
  static const int tabWidth = 1 << 0;
  static const int underlineSpaces = 1 << 1;
  static const int strikethroughSpaces = 1 << 2;
  static const int marginBackground = 1 << 3;
  static const int stringValue = 1 << 4;
  static const int borderTop = 1 << 5;
  static const int borderRight = 1 << 6;
  static const int borderBottom = 1 << 7;
  static const int borderLeft = 1 << 8;
  static const int wrapAnsi = 1 << 9;
  static const int underlineStyle = 1 << 10;
  static const int hyperlink = 1 << 11;
  static const int colorWhitespace = 1 << 12;
  static const int borderForegroundBlend = 1 << 13;
  static const int borderForegroundBlendOffset = 1 << 14;
  static const int underlineColor = 1 << 15;
  static const int paddingChar = 1 << 16;
  static const int marginChar = 1 << 17;
  static const int whitespaceChar = 1 << 18;
  static const int whitespaceForeground = 1 << 19;
}

/// Fluent, chainable style builder for terminal output.
///
/// All setter methods return `this` for chaining. Use [render] to apply
/// the style to text and produce ANSI-escaped output.
///
/// ## Basic Usage
///
/// ```dart
/// final style = Style()
///     .bold()
///     .foreground(Colors.green)
///     .render('Success!');
/// ```
///
/// ## Style Composition
///
/// Styles can be composed using [inherit], which copies only the
/// explicitly-set properties from another style:
///
/// ```dart
/// final base = Style().foreground(Colors.white).padding(1);
/// final accent = Style().bold().foreground(Colors.cyan);
///
/// // Inherits bold and foreground from accent, keeps padding from base
/// final combined = base.copy()..inherit(accent);
/// Fluent, chainable style builder for CLI output.
///
/// Inspired by Go's lipgloss library, this provides a composable way
/// to build text styles for terminal output.
///
/// {@category Style}
///
/// {@macro artisanal_style_overview}
///
/// ```dart
/// final style = Style()
///     .bold()
///     .foreground(Colors.green)
///     .padding(1, 2)
///     .border(Border.rounded)
///     .width(40);
///
/// print(style.render('Hello World'));
/// ```
class Style {
  /// Creates a new empty style.
  Style();

  // ─────────────────────────────────────────────────────────────────────────────
  // Property Tracking
  // ─────────────────────────────────────────────────────────────────────────────

  /// Bitfield tracking which properties are explicitly set.
  int _props = 0;

  /// Second bitfield for additional properties.
  int _props2 = 0;

  /// Non-breaking space character.
  static const nbsp = '\u00A0';

  bool _hasFlag(int flag) => _props & flag != 0;
  void _setFlag(int flag) {
    _props |= flag;
    _invalidateTextStyleCache();
  }

  void _clearFlag(int flag) {
    _props &= ~flag;
    _invalidateTextStyleCache();
  }

  bool _hasFlag2(int flag) => _props2 & flag != 0;
  void _setFlag2(int flag) {
    _props2 |= flag;
    _invalidateTextStyleCache();
  }

  void _clearFlag2(int flag) {
    _props2 &= ~flag;
    _invalidateTextStyleCache();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Text Attribute Properties
  // ─────────────────────────────────────────────────────────────────────────────

  bool _bold = false;
  bool _italic = false;
  bool _underline = false;
  UnderlineStyle _underlineStyle = UnderlineStyle.single;
  bool _strikethrough = false;
  bool _dim = false;
  bool _inverse = false;
  bool _blink = false;

  // ─────────────────────────────────────────────────────────────────────────────
  // Color Properties
  // ─────────────────────────────────────────────────────────────────────────────

  Color? _foreground;
  Color? _background;
  Color? _borderForeground;
  Color? _borderBackground;

  // Per-side border colors
  Color? _borderTopForeground;
  Color? _borderRightForeground;
  Color? _borderBottomForeground;
  Color? _borderLeftForeground;
  Color? _borderTopBackground;
  Color? _borderRightBackground;
  Color? _borderBottomBackground;
  Color? _borderLeftBackground;

  List<Color> _borderForegroundBlend = const [];
  int _borderForegroundBlendOffset = 0;

  /// Bitfield for per-side border color properties.
  int _borderProps = 0;
  static const int _borderTopFg = 1 << 0;
  static const int _borderRightFg = 1 << 1;
  static const int _borderBottomFg = 1 << 2;
  static const int _borderLeftFg = 1 << 3;
  static const int _borderTopBg = 1 << 4;
  static const int _borderRightBg = 1 << 5;
  static const int _borderBottomBg = 1 << 6;
  static const int _borderLeftBg = 1 << 7;

  // ─────────────────────────────────────────────────────────────────────────────
  // Dimension Properties
  // ─────────────────────────────────────────────────────────────────────────────

  int _width = 0;
  int _height = 0;
  int _maxWidth = 0;
  int _maxHeight = 0;

  // ─────────────────────────────────────────────────────────────────────────────
  // Spacing Properties
  // ─────────────────────────────────────────────────────────────────────────────

  Padding _padding = Padding.zero;
  Margin _margin = Margin.zero;

  // ─────────────────────────────────────────────────────────────────────────────
  // Layout Properties
  // ─────────────────────────────────────────────────────────────────────────────

  HorizontalAlign _align = HorizontalAlign.left;
  VerticalAlign _alignVertical = VerticalAlign.top;
  Border? _border;
  BorderSides _borderSides = BorderSides.all;
  bool _inline = false;
  bool _wrapAnsi = false;

  // ─────────────────────────────────────────────────────────────────────────────
  // Transform
  // ─────────────────────────────────────────────────────────────────────────────

  String Function(String)? _transform;

  // ─────────────────────────────────────────────────────────────────────────────
  // Pre-set String
  // ─────────────────────────────────────────────────────────────────────────────

  /// Pre-set string content for this style.
  String? _string;

  // ─────────────────────────────────────────────────────────────────────────────
  // Whitespace Options
  // ─────────────────────────────────────────────────────────────────────────────

  /// Custom character(s) for whitespace fill.
  String _whitespaceChar = ' ';

  /// Foreground color for whitespace fill.
  Color? _whitespaceForeground;

  // ─────────────────────────────────────────────────────────────────────────────
  // Additional Style Properties
  // ─────────────────────────────────────────────────────────────────────────────

  /// Tab width for tab character handling.
  int _tabWidth = 4;

  /// Whether to underline spaces.
  bool _underlineSpaces = false;

  /// Whether to strikethrough spaces.
  bool _strikethroughSpaces = false;

  /// Whether to apply background styling to whitespace outside the core text.
  ///
  /// Lipgloss v2 parity: defaults to true.
  bool _colorWhitespace = true;

  String? _hyperlinkUrl;
  String _hyperlinkParams = '';

  /// Background color for margin areas.
  Color? _marginBackground;

  /// Underline color.
  Color? _underlineColor;

  /// Character used for padding.
  String _paddingChar = ' ';

  /// Character used for margins.
  String _marginChar = ' ';

  // ─────────────────────────────────────────────────────────────────────────────
  // Rendering Context
  // ─────────────────────────────────────────────────────────────────────────────

  /// Color profile for rendering (defaults to trueColor).
  ColorProfile _colorProfile = ColorProfile.trueColor;

  /// Whether the terminal has a dark background.
  bool _hasDarkBackground = true;

  RenderContext? _activeRenderContext;

  String? _cachedTextStylePrefix;
  String? _cachedTextStyleSuffix;
  bool _hasCachedTextStyle = false;
  String? _cachedSpaceTextStylePrefix;
  String? _cachedSpaceTextStyleSuffix;
  bool _hasCachedSpaceTextStyle = false;

  ColorProfile get colorProfile =>
      _activeRenderContext?.colorProfile ?? _colorProfile;
  set colorProfile(ColorProfile value) {
    if (_colorProfile == value) return;
    _colorProfile = value;
    _invalidateTextStyleCache();
  }

  bool get hasDarkBackground =>
      _activeRenderContext?.hasDarkBackground ?? _hasDarkBackground;
  set hasDarkBackground(bool value) {
    if (_hasDarkBackground == value) return;
    _hasDarkBackground = value;
    _invalidateTextStyleCache();
  }

  void _invalidateTextStyleCache() {
    _hasCachedTextStyle = false;
    _cachedTextStylePrefix = null;
    _cachedTextStyleSuffix = null;
    _hasCachedSpaceTextStyle = false;
    _cachedSpaceTextStylePrefix = null;
    _cachedSpaceTextStyleSuffix = null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FLUENT SETTERS
  // ═══════════════════════════════════════════════════════════════════════════

  // ─────────────────────────────────────────────────────────────────────────────
  // Text Attributes
  // ─────────────────────────────────────────────────────────────────────────────

  /// Sets bold text.
  Style bold([bool value = true]) {
    _bold = value;
    _setFlag(_PropBits.bold);
    return this;
  }

  /// Sets italic text.
  Style italic([bool value = true]) {
    _italic = value;
    _setFlag(_PropBits.italic);
    return this;
  }

  /// Sets underlined text.
  Style underline([bool value = true]) {
    _underline = value;
    _setFlag(_PropBits.underline);
    if (value && _underlineStyle == UnderlineStyle.none) {
      _underlineStyle = UnderlineStyle.single;
    }
    return this;
  }

  /// Sets whether spaces should be underlined.
  Style underlineSpaces([bool value = true]) {
    _underlineSpaces = value;
    _setFlag2(_PropBits.underlineSpaces);
    return this;
  }

  /// Sets the underline style variant.
  ///
  /// This enables underline when the style is not [UnderlineStyle.none].
  Style underlineStyle(UnderlineStyle style) {
    _underlineStyle = style;
    _setFlag2(_PropBits.underlineStyle);

    _underline = style != UnderlineStyle.none;
    _setFlag(_PropBits.underline);

    return this;
  }

  /// Adds an OSC 8 hyperlink around rendered output.
  ///
  /// This is additive and works with wrapping and layout, since the hyperlink
  /// is applied after layout (per rendered line).
  Style hyperlink(String url, {String params = ''}) {
    _hyperlinkUrl = url;
    _hyperlinkParams = params;
    _setFlag2(_PropBits.hyperlink);
    return this;
  }

  /// Removes hyperlink styling.
  Style unsetHyperlink() {
    _hyperlinkUrl = null;
    _hyperlinkParams = '';
    _clearFlag2(_PropBits.hyperlink);
    return this;
  }

  /// Removes bold styling.
  Style unsetBold() {
    _bold = false;
    _clearFlag(_PropBits.bold);
    return this;
  }

  /// Removes italic styling.
  Style unsetItalic() {
    _italic = false;
    _clearFlag(_PropBits.italic);
    return this;
  }

  /// Removes underline styling.
  Style unsetUnderline() {
    _underline = false;
    _clearFlag(_PropBits.underline);
    _clearFlag2(_PropBits.underlineStyle);
    _clearFlag2(_PropBits.underlineColor);
    return this;
  }

  /// Removes strikethrough styling.
  Style unsetStrikethrough() {
    _strikethrough = false;
    _clearFlag(_PropBits.strikethrough);
    return this;
  }

  /// Removes dimmed styling.
  Style unsetDim() {
    _dim = false;
    _clearFlag(_PropBits.dim);
    return this;
  }

  /// Alias for [unsetDim].
  Style unsetFaint() => unsetDim();

  /// Removes inverse styling.
  Style unsetInverse() {
    _inverse = false;
    _clearFlag(_PropBits.inverse);
    return this;
  }

  /// Alias for [unsetInverse].
  Style unsetReverse() => unsetInverse();

  /// Removes blink styling.
  Style unsetBlink() {
    _blink = false;
    _clearFlag(_PropBits.blink);
    return this;
  }

  /// Removes foreground color.
  Style unsetForeground() {
    _foreground = null;
    _clearFlag(_PropBits.foreground);
    return this;
  }

  /// Removes background color.
  Style unsetBackground() {
    _background = null;
    _clearFlag(_PropBits.background);
    return this;
  }

  /// Removes width constraint.
  Style unsetWidth() {
    _width = 0;
    _clearFlag(_PropBits.width);
    return this;
  }

  /// Removes height constraint.
  Style unsetHeight() {
    _height = 0;
    _clearFlag(_PropBits.height);
    return this;
  }

  /// Removes alignment.
  Style unsetAlign() {
    _align = HorizontalAlign.left;
    _alignVertical = VerticalAlign.top;
    _clearFlag(_PropBits.align);
    _clearFlag(_PropBits.alignVertical);
    return this;
  }

  /// Removes padding.
  Style unsetPadding() {
    _padding = Padding.zero;
    _clearFlag(_PropBits.padding);
    _clearFlag(_PropBits.paddingTop);
    _clearFlag(_PropBits.paddingRight);
    _clearFlag(_PropBits.paddingBottom);
    _clearFlag(_PropBits.paddingLeft);
    _clearFlag2(_PropBits.paddingChar);
    return this;
  }

  /// Removes underline color.
  Style unsetUnderlineColor() {
    _underlineColor = null;
    _clearFlag2(_PropBits.underlineColor);
    return this;
  }

  /// Removes padding character.
  Style unsetPaddingChar() {
    _paddingChar = ' ';
    _clearFlag2(_PropBits.paddingChar);
    return this;
  }

  /// Removes margin character.
  Style unsetMarginChar() {
    _marginChar = ' ';
    _clearFlag2(_PropBits.marginChar);
    return this;
  }

  /// Removes custom whitespace characters.
  Style unsetWhitespaceChars() {
    _whitespaceChar = ' ';
    _clearFlag2(_PropBits.whitespaceChar);
    return this;
  }

  /// Removes whitespace foreground styling.
  Style unsetWhitespaceForeground() {
    _whitespaceForeground = null;
    _clearFlag2(_PropBits.whitespaceForeground);
    return this;
  }

  /// Sets strikethrough text.
  Style strikethrough([bool value = true]) {
    _strikethrough = value;
    _setFlag(_PropBits.strikethrough);
    return this;
  }

  /// Sets whether spaces should have strikethrough.
  Style strikethroughSpaces([bool value = true]) {
    _strikethroughSpaces = value;
    _setFlag2(_PropBits.strikethroughSpaces);
    return this;
  }

  /// Sets dimmed/faint text.
  Style dim([bool value = true]) {
    _dim = value;
    _setFlag(_PropBits.dim);
    return this;
  }

  /// Alias for [dim].
  Style faint([bool value = true]) => dim(value);

  /// Sets inverse/reverse video.
  Style inverse([bool value = true]) {
    _inverse = value;
    _setFlag(_PropBits.inverse);
    return this;
  }

  /// Alias for [inverse].
  Style reverse([bool value = true]) => inverse(value);

  /// Sets blinking text (limited terminal support).
  Style blink([bool value = true]) {
    _blink = value;
    _setFlag(_PropBits.blink);
    return this;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Colors
  // ─────────────────────────────────────────────────────────────────────────────

  /// Sets the foreground (text) color.
  Style foreground(Color color) {
    _foreground = color;
    _setFlag(_PropBits.foreground);
    return this;
  }

  /// Returns the currently configured foreground color, if set.
  Color? get foregroundColor => _foreground;

  /// Sets the background color.
  Style background(Color color) {
    _background = color;
    _setFlag(_PropBits.background);
    return this;
  }

  /// Sets the underline color.
  Style underlineColor(Color color) {
    _underlineColor = color;
    _setFlag2(_PropBits.underlineColor);
    return this;
  }

  /// Sets the border foreground color.
  Style borderForeground(Color color) {
    _borderForeground = color;
    _setFlag(_PropBits.borderForeground);
    return this;
  }

  /// Sets the border background color.
  Style borderBackground(Color color) {
    _borderBackground = color;
    _setFlag(_PropBits.borderBackground);
    return this;
  }

  /// Sets the top border foreground color.
  Style borderTopForeground(Color color) {
    _borderTopForeground = color;
    _borderProps |= _borderTopFg;
    return this;
  }

  /// Sets the right border foreground color.
  Style borderRightForeground(Color color) {
    _borderRightForeground = color;
    _borderProps |= _borderRightFg;
    return this;
  }

  /// Sets the bottom border foreground color.
  Style borderBottomForeground(Color color) {
    _borderBottomForeground = color;
    _borderProps |= _borderBottomFg;
    return this;
  }

  /// Sets the left border foreground color.
  Style borderLeftForeground(Color color) {
    _borderLeftForeground = color;
    _borderProps |= _borderLeftFg;
    return this;
  }

  /// Sets the top border background color.
  Style borderTopBackground(Color color) {
    _borderTopBackground = color;
    _borderProps |= _borderTopBg;
    return this;
  }

  /// Sets the right border background color.
  Style borderRightBackground(Color color) {
    _borderRightBackground = color;
    _borderProps |= _borderRightBg;
    return this;
  }

  /// Sets the bottom border background color.
  Style borderBottomBackground(Color color) {
    _borderBottomBackground = color;
    _borderProps |= _borderBottomBg;
    return this;
  }

  /// Sets the left border background color.
  Style borderLeftBackground(Color color) {
    _borderLeftBackground = color;
    _borderProps |= _borderLeftBg;
    return this;
  }

  /// Sets a foreground color gradient for the border.
  ///
  /// Lipgloss v2 parity: if fewer than 2 colors are provided, blending is
  /// effectively disabled and the regular border foreground colors apply.
  Style borderForegroundBlend(List<Color> colors) {
    _borderForegroundBlend = colors;
    _setFlag2(_PropBits.borderForegroundBlend);
    return this;
  }

  /// Sets the border blend offset (in cells along the perimeter).
  ///
  /// Positive offsets move the gradient start backward (matching lipgloss v2).
  Style borderForegroundBlendOffset(int value) {
    _borderForegroundBlendOffset = value;
    _setFlag2(_PropBits.borderForegroundBlendOffset);
    return this;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Dimensions
  // ─────────────────────────────────────────────────────────────────────────────

  /// Sets the fixed width of the styled content.
  Style width(int value) {
    _width = value;
    _setFlag(_PropBits.width);
    return this;
  }

  /// Sets the fixed height of the styled content.
  Style height(int value) {
    _height = value;
    _setFlag(_PropBits.height);
    return this;
  }

  /// Sets the maximum width of the styled content.
  Style maxWidth(int value) {
    _maxWidth = value;
    _setFlag(_PropBits.maxWidth);
    return this;
  }

  /// Sets the maximum height of the styled content.
  Style maxHeight(int value) {
    _maxHeight = value;
    _setFlag(_PropBits.maxHeight);
    return this;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Padding
  // ─────────────────────────────────────────────────────────────────────────────

  /// Sets padding on all sides or vertical/horizontal.
  ///
  /// - `padding(1)` - 1 on all sides
  /// - `padding(1, 2)` - 1 vertical, 2 horizontal
  /// - `padding(1, 2, 3, 4)` - top, right, bottom, left
  Style padding(int topOrAll, [int? right, int? bottom, int? left]) {
    if (right == null && bottom == null && left == null) {
      // All sides
      _padding = Padding.all(topOrAll);
    } else if (bottom == null && left == null) {
      // Vertical, horizontal
      _padding = Padding.symmetric(vertical: topOrAll, horizontal: right!);
    } else {
      // Individual sides
      _padding = Padding(
        top: topOrAll,
        right: right ?? 0,
        bottom: bottom ?? 0,
        left: left ?? 0,
      );
    }
    _setFlag(_PropBits.padding);
    return this;
  }

  /// Sets top padding.
  Style paddingTop(int value) {
    _padding = _padding.copyWith(top: value);
    _setFlag(_PropBits.paddingTop);
    return this;
  }

  /// Sets right padding.
  Style paddingRight(int value) {
    _padding = _padding.copyWith(right: value);
    _setFlag(_PropBits.paddingRight);
    return this;
  }

  /// Sets bottom padding.
  Style paddingBottom(int value) {
    _padding = _padding.copyWith(bottom: value);
    _setFlag(_PropBits.paddingBottom);
    return this;
  }

  /// Sets left padding.
  Style paddingLeft(int value) {
    _padding = _padding.copyWith(left: value);
    _setFlag(_PropBits.paddingLeft);
    return this;
  }

  /// Sets the character used for padding.
  Style paddingChar(String char) {
    _paddingChar = char;
    _setFlag2(_PropBits.paddingChar);
    return this;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Margin
  // ─────────────────────────────────────────────────────────────────────────────

  /// Sets margin on all sides or vertical/horizontal.
  ///
  /// - `margin(1)` - 1 on all sides
  /// - `margin(1, 2)` - 1 vertical, 2 horizontal
  /// - `margin(1, 2, 3, 4)` - top, right, bottom, left
  Style margin(int topOrAll, [int? right, int? bottom, int? left]) {
    if (right == null && bottom == null && left == null) {
      // All sides
      _margin = Margin.all(topOrAll);
    } else if (bottom == null && left == null) {
      // Vertical, horizontal
      _margin = Margin.symmetric(vertical: topOrAll, horizontal: right!);
    } else {
      // Individual sides
      _margin = Margin(
        top: topOrAll,
        right: right ?? 0,
        bottom: bottom ?? 0,
        left: left ?? 0,
      );
    }
    _setFlag(_PropBits.margin);
    return this;
  }

  /// Sets top margin.
  Style marginTop(int value) {
    _margin = _margin.copyWith(top: value);
    _setFlag(_PropBits.marginTop);
    return this;
  }

  /// Sets right margin.
  Style marginRight(int value) {
    _margin = _margin.copyWith(right: value);
    _setFlag(_PropBits.marginRight);
    return this;
  }

  /// Sets bottom margin.
  Style marginBottom(int value) {
    _margin = _margin.copyWith(bottom: value);
    _setFlag(_PropBits.marginBottom);
    return this;
  }

  /// Sets left margin.
  Style marginLeft(int value) {
    _margin = _margin.copyWith(left: value);
    _setFlag(_PropBits.marginLeft);
    return this;
  }

  /// Sets the character used for margins.
  Style marginChar(String char) {
    _marginChar = char;
    _setFlag2(_PropBits.marginChar);
    return this;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Alignment
  // ─────────────────────────────────────────────────────────────────────────────

  /// Sets horizontal text alignment, optionally with vertical alignment.
  ///
  /// With one argument, sets horizontal alignment only.
  /// With two arguments, sets both horizontal and vertical alignment.
  ///
  /// ```dart
  /// style.align(HorizontalAlign.center); // horizontal only
  /// style.align(HorizontalAlign.center, VerticalAlign.middle); // both
  /// ```
  Style align(HorizontalAlign horizontal, [VerticalAlign? vertical]) {
    _align = horizontal;
    _setFlag(_PropBits.align);
    if (vertical != null) {
      _alignVertical = vertical;
      _setFlag(_PropBits.alignVertical);
    }
    return this;
  }

  /// Sets horizontal text alignment (alias for [align]).
  Style alignHorizontal(HorizontalAlign value) => align(value);

  /// Sets vertical text alignment within the height.
  Style alignVertical(VerticalAlign value) {
    _alignVertical = value;
    _setFlag(_PropBits.alignVertical);
    return this;
  }

  /// Aligns text to the left.
  Style alignLeft() => align(HorizontalAlign.left);

  /// Aligns text to the center horizontally.
  Style alignCenter() => align(HorizontalAlign.center);

  /// Aligns text to the right.
  Style alignRight() => align(HorizontalAlign.right);

  /// Aligns text to the top.
  Style alignTop() => alignVertical(VerticalAlign.top);

  /// Aligns text to the center vertically.
  Style alignMiddle() => alignVertical(VerticalAlign.center);

  /// Aligns text to the bottom.
  Style alignBottom() => alignVertical(VerticalAlign.bottom);

  // ─────────────────────────────────────────────────────────────────────────────
  // Border
  // ─────────────────────────────────────────────────────────────────────────────

  /// Sets the border style, optionally specifying which sides are visible.
  ///
  /// With one argument, sets the border style and enables all sides.
  /// With additional arguments, sets visibility for top, right, bottom, left.
  ///
  /// ```dart
  /// // Enable border on all sides
  /// style.border(Border.rounded());
  ///
  /// // Enable border on top and bottom only
  /// style.border(Border.rounded(), top: true, bottom: true);
  ///
  /// // Explicitly set all sides
  /// style.border(Border.rounded(), top: true, right: false, bottom: true, left: false);
  /// ```
  Style border(
    Border value, {
    bool? top,
    bool? right,
    bool? bottom,
    bool? left,
  }) {
    _border = value;
    _setFlag(_PropBits.border);

    // If any side is specified, apply the border sides
    if (top != null || right != null || bottom != null || left != null) {
      _borderSides = BorderSides(
        top: top ?? false,
        right: right ?? false,
        bottom: bottom ?? false,
        left: left ?? false,
      );
      _setFlag(_PropBits.borderSides);
    }
    return this;
  }

  /// Alias for setting border style only (without changing sides).
  ///
  /// This matches the lipgloss API where `BorderStyle()` sets the border type
  /// without affecting which sides are visible.
  Style borderStyle(Border value) {
    _border = value;
    _setFlag(_PropBits.border);
    return this;
  }

  /// Sets which border sides are visible.
  Style borderSides(BorderSides value) {
    _borderSides = value;
    _setFlag(_PropBits.borderSides);
    return this;
  }

  /// Shows or hides the top border.
  Style borderTop(bool visible) {
    _borderSides = _borderSides.copyWith(top: visible);
    _setFlag(_PropBits.borderSides);
    return this;
  }

  /// Shows or hides the bottom border.
  Style borderBottom(bool visible) {
    _borderSides = _borderSides.copyWith(bottom: visible);
    _setFlag(_PropBits.borderSides);
    return this;
  }

  /// Shows or hides the left border.
  Style borderLeft(bool visible) {
    _borderSides = _borderSides.copyWith(left: visible);
    _setFlag(_PropBits.borderSides);
    return this;
  }

  /// Shows or hides the right border.
  Style borderRight(bool visible) {
    _borderSides = _borderSides.copyWith(right: visible);
    _setFlag(_PropBits.borderSides);
    return this;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Pre-set String
  // ─────────────────────────────────────────────────────────────────────────────

  /// Sets a pre-defined string content for this style.
  ///
  /// When set, calling [toString] will render this string with the style,
  /// allowing the style to be used directly as a string.
  ///
  /// ```dart
  /// final divider = Style()
  ///     .foreground(Colors.muted)
  ///     .padding(0, 1)
  ///     .setString('•');
  ///
  /// print('Item 1${divider}Item 2${divider}Item 3');
  /// // Output: Item 1 • Item 2 • Item 3
  /// ```
  Style setString(Object? value) {
    if (value is List) {
      _string = value.map((e) => e?.toString() ?? '').join(' ');
    } else {
      _string = value?.toString();
    }
    _setFlag2(_PropBits.stringValue);
    return this;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Whitespace Options
  // ─────────────────────────────────────────────────────────────────────────────

  /// Sets custom character(s) for whitespace fill.
  ///
  /// Used when filling space in aligned content or padding.
  ///
  /// ```dart
  /// final style = Style()
  ///     .width(20)
  ///     .align(HorizontalAlign.center)
  ///     .whitespaceChars('·');
  /// ```
  Style whitespaceChars(String chars) {
    if (Layout.visibleLength(chars) != 1) {
      throw ArgumentError.value(
        chars,
        'chars',
        'Whitespace characters must occupy one cell',
      );
    }
    _whitespaceChar = chars;
    _setFlag2(_PropBits.whitespaceChar);
    return this;
  }

  /// Sets the foreground color for whitespace fill.
  Style whitespaceForeground(Color color) {
    _whitespaceForeground = color;
    _setFlag2(_PropBits.whitespaceForeground);
    return this;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Other
  // ─────────────────────────────────────────────────────────────────────────────

  /// Sets inline mode (ignores padding, margin, border).
  Style inline([bool value = true]) {
    _inline = value;
    _setFlag(_PropBits.inline);
    return this;
  }

  /// Sets whether to use ANSI-preserving wrapping.
  ///
  /// When enabled, ANSI pen state (SGR + OSC 8) is preserved across
  /// wrapped lines.
  Style wrapAnsi([bool value = true]) {
    _wrapAnsi = value;
    _setFlag2(_PropBits.wrapAnsi);
    return this;
  }

  /// Sets a text transformation function.
  Style transform(String Function(String) fn) {
    _transform = fn;
    _setFlag(_PropBits.transform);
    return this;
  }

  /// Sets the tab width for tab character handling.
  Style tabWidth(int width) {
    _tabWidth = width;
    _setFlag2(_PropBits.tabWidth);
    return this;
  }

  /// Sets the background color for margin areas.
  Style marginBackground(Color color) {
    _marginBackground = color;
    _setFlag2(_PropBits.marginBackground);
    return this;
  }

  /// Sets whether to color whitespace outside the core text (padding/alignment).
  ///
  /// Lipgloss v2 parity: defaults to true.
  ///
  /// When false, background color (and other whitespace styling) will not be
  /// applied to padding/alignment fill. Foreground color is never applied to
  /// whitespace unless inverse mode is enabled.
  Style colorWhitespace([bool value = true]) {
    _colorWhitespace = value;
    _setFlag2(_PropBits.colorWhitespace);
    return this;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UNSET METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Unsets margin.
  Style unsetMargin() {
    _margin = Margin.zero;
    _clearFlag(_PropBits.margin);
    _clearFlag(_PropBits.marginTop);
    _clearFlag(_PropBits.marginRight);
    _clearFlag(_PropBits.marginBottom);
    _clearFlag(_PropBits.marginLeft);
    return this;
  }

  /// Unsets border.
  Style unsetBorder() {
    _border = null;
    _clearFlag(_PropBits.border);
    return this;
  }

  /// Unsets transform.
  Style unsetTransform() {
    _transform = null;
    _clearFlag(_PropBits.transform);
    return this;
  }

  /// Unsets max width.
  Style unsetMaxWidth() {
    _maxWidth = 0;
    _clearFlag(_PropBits.maxWidth);
    return this;
  }

  /// Unsets max height.
  Style unsetMaxHeight() {
    _maxHeight = 0;
    _clearFlag(_PropBits.maxHeight);
    return this;
  }

  /// Unsets horizontal alignment.
  Style unsetAlignHorizontal() {
    _align = HorizontalAlign.left;
    _clearFlag(_PropBits.align);
    return this;
  }

  /// Unsets vertical alignment.
  Style unsetAlignVertical() {
    _alignVertical = VerticalAlign.top;
    _clearFlag(_PropBits.alignVertical);
    return this;
  }

  /// Unsets inline mode.
  Style unsetInline() {
    _inline = false;
    _clearFlag(_PropBits.inline);
    return this;
  }

  /// Unsets tab width.
  Style unsetTabWidth() {
    _tabWidth = 4;
    _clearFlag2(_PropBits.tabWidth);
    return this;
  }

  /// Unsets underline spaces.
  Style unsetUnderlineSpaces() {
    _underlineSpaces = false;
    _clearFlag2(_PropBits.underlineSpaces);
    return this;
  }

  /// Unsets strikethrough spaces.
  Style unsetStrikethroughSpaces() {
    _strikethroughSpaces = false;
    _clearFlag2(_PropBits.strikethroughSpaces);
    return this;
  }

  /// Unsets margin background color.
  Style unsetMarginBackground() {
    _marginBackground = null;
    _clearFlag2(_PropBits.marginBackground);
    return this;
  }

  /// Unsets top border visibility.
  Style unsetBorderTop() {
    _clearFlag2(_PropBits.borderTop);
    return this;
  }

  /// Unsets right border visibility.
  Style unsetBorderRight() {
    _clearFlag2(_PropBits.borderRight);
    return this;
  }

  /// Unsets bottom border visibility.
  Style unsetBorderBottom() {
    _clearFlag2(_PropBits.borderBottom);
    return this;
  }

  /// Unsets left border visibility.
  Style unsetBorderLeft() {
    _clearFlag2(_PropBits.borderLeft);
    return this;
  }

  /// Unsets the pre-set string value.
  Style unsetString() {
    _string = null;
    _clearFlag2(_PropBits.stringValue);
    return this;
  }

  /// Unsets border foreground color.
  Style unsetBorderForeground() {
    _borderForeground = null;
    _borderTopForeground = null;
    _borderRightForeground = null;
    _borderBottomForeground = null;
    _borderLeftForeground = null;
    _clearFlag(_PropBits.borderForeground);
    _borderProps &=
        ~(_borderTopFg | _borderRightFg | _borderBottomFg | _borderLeftFg);
    return this;
  }

  /// Unsets border background color.
  Style unsetBorderBackground() {
    _borderBackground = null;
    _borderTopBackground = null;
    _borderRightBackground = null;
    _borderBottomBackground = null;
    _borderLeftBackground = null;
    _clearFlag(_PropBits.borderBackground);
    _borderProps &=
        ~(_borderTopBg | _borderRightBg | _borderBottomBg | _borderLeftBg);
    return this;
  }

  /// Unsets padding top.
  Style unsetPaddingTop() {
    _padding = _padding.copyWith(top: 0);
    _clearFlag(_PropBits.paddingTop);
    return this;
  }

  /// Unsets padding right.
  Style unsetPaddingRight() {
    _padding = _padding.copyWith(right: 0);
    _clearFlag(_PropBits.paddingRight);
    return this;
  }

  /// Unsets padding bottom.
  Style unsetPaddingBottom() {
    _padding = _padding.copyWith(bottom: 0);
    _clearFlag(_PropBits.paddingBottom);
    return this;
  }

  /// Unsets padding left.
  Style unsetPaddingLeft() {
    _padding = _padding.copyWith(left: 0);
    _clearFlag(_PropBits.paddingLeft);
    return this;
  }

  /// Unsets margin top.
  Style unsetMarginTop() {
    _margin = _margin.copyWith(top: 0);
    _clearFlag(_PropBits.marginTop);
    return this;
  }

  /// Unsets margin right.
  Style unsetMarginRight() {
    _margin = _margin.copyWith(right: 0);
    _clearFlag(_PropBits.marginRight);
    return this;
  }

  /// Unsets margin bottom.
  Style unsetMarginBottom() {
    _margin = _margin.copyWith(bottom: 0);
    _clearFlag(_PropBits.marginBottom);
    return this;
  }

  /// Unsets margin left.
  Style unsetMarginLeft() {
    _margin = _margin.copyWith(left: 0);
    _clearFlag(_PropBits.marginLeft);
    return this;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Whether bold is explicitly set.
  bool get isBold => _hasFlag(_PropBits.bold) && _bold;

  /// Whether italic is explicitly set.
  bool get isItalic => _hasFlag(_PropBits.italic) && _italic;

  /// Whether underline is explicitly set.
  bool get isUnderline => _hasFlag(_PropBits.underline) && _underline;

  /// Gets the underline style variant.
  ///
  /// If not explicitly set, defaults to [UnderlineStyle.single].
  UnderlineStyle get getUnderlineStyle => _hasFlag2(_PropBits.underlineStyle)
      ? _underlineStyle
      : UnderlineStyle.single;

  /// Whether a hyperlink is explicitly set.
  bool get hasHyperlink =>
      _hasFlag2(_PropBits.hyperlink) && _hyperlinkUrl != null;

  /// Gets the hyperlink URL if set.
  String? get getHyperlinkUrl =>
      _hasFlag2(_PropBits.hyperlink) ? _hyperlinkUrl : null;

  /// Gets the hyperlink params if set.
  String get getHyperlinkParams =>
      _hasFlag2(_PropBits.hyperlink) ? _hyperlinkParams : '';

  /// Whether strikethrough is explicitly set.
  bool get isStrikethrough =>
      _hasFlag(_PropBits.strikethrough) && _strikethrough;

  /// Whether dim is explicitly set.
  bool get isDim => _hasFlag(_PropBits.dim) && _dim;

  /// Whether inverse is explicitly set.
  bool get isInverse => _hasFlag(_PropBits.inverse) && _inverse;

  /// Whether blink is explicitly set.
  bool get isBlink => _hasFlag(_PropBits.blink) && _blink;

  /// Whether inline mode is set.
  bool get isInline => _hasFlag(_PropBits.inline) && _inline;

  /// Gets the tab width.
  int get getTabWidth => _hasFlag2(_PropBits.tabWidth) ? _tabWidth : 4;

  /// Whether underline spaces is set.
  bool get isUnderlineSpaces =>
      _hasFlag2(_PropBits.underlineSpaces) && _underlineSpaces;

  /// Whether strikethrough spaces is set.
  bool get isStrikethroughSpaces =>
      _hasFlag2(_PropBits.strikethroughSpaces) && _strikethroughSpaces;

  /// Gets the margin background color if set.
  Color? get getMarginBackground =>
      _hasFlag2(_PropBits.marginBackground) ? _marginBackground : null;

  /// Gets the underline color if set.
  Color? get getUnderlineColor =>
      _hasFlag2(_PropBits.underlineColor) ? _underlineColor : null;

  /// Gets the character used for padding.
  String get getPaddingChar => _paddingChar;

  /// Gets the character used for margins.
  String get getMarginChar => _marginChar;

  /// Gets whether spaces are underlined.
  bool get getUnderlineSpaces => _underlineSpaces;

  /// Gets whether spaces have strikethrough.
  bool get getStrikethroughSpaces => _strikethroughSpaces;

  /// Gets whether top border is visible.
  bool get getBorderTop =>
      _hasFlag2(_PropBits.borderTop) ? _borderSides.top : true;

  /// Gets whether right border is visible.
  bool get getBorderRight =>
      _hasFlag2(_PropBits.borderRight) ? _borderSides.right : true;

  /// Gets whether bottom border is visible.
  bool get getBorderBottom =>
      _hasFlag2(_PropBits.borderBottom) ? _borderSides.bottom : true;

  /// Gets whether left border is visible.
  bool get getBorderLeft =>
      _hasFlag2(_PropBits.borderLeft) ? _borderSides.left : true;

  /// Gets the pre-set string value.
  String? get value => _hasFlag2(_PropBits.stringValue) ? _string : null;

  /// Gets the foreground color if set.
  Color? get getForeground =>
      _hasFlag(_PropBits.foreground) ? _foreground : null;

  /// Gets the background color if set.
  Color? get getBackground =>
      _hasFlag(_PropBits.background) ? _background : null;

  /// Gets the width if set.
  int get getWidth => _hasFlag(_PropBits.width) ? _width : 0;

  /// Gets the height if set.
  int get getHeight => _hasFlag(_PropBits.height) ? _height : 0;

  /// Gets the max width if set.
  int get getMaxWidth => _hasFlag(_PropBits.maxWidth) ? _maxWidth : 0;

  /// Gets the max height if set.
  int get getMaxHeight => _hasFlag(_PropBits.maxHeight) ? _maxHeight : 0;

  /// Gets the padding.
  Padding get getPadding => _padding;

  /// Gets the top padding.
  int get getPaddingTop => _padding.top;

  /// Gets the right padding.
  int get getPaddingRight => _padding.right;

  /// Gets the bottom padding.
  int get getPaddingBottom => _padding.bottom;

  /// Gets the left padding.
  int get getPaddingLeft => _padding.left;

  /// Gets the horizontal padding (left + right).
  int get getHorizontalPadding => _padding.horizontal;

  /// Gets the vertical padding (top + bottom).
  int get getVerticalPadding => _padding.vertical;

  /// Gets the margin.
  Margin get getMargin => _margin;

  /// Gets the top margin.
  int get getMarginTop => _margin.top;

  /// Gets the right margin.
  int get getMarginRight => _margin.right;

  /// Gets the bottom margin.
  int get getMarginBottom => _margin.bottom;

  /// Gets the left margin.
  int get getMarginLeft => _margin.left;

  /// Gets the horizontal margin (left + right).
  int get getHorizontalMargins => _margin.horizontal;

  /// Gets the vertical margin (top + bottom).
  int get getVerticalMargins => _margin.vertical;

  /// Gets the horizontal alignment.
  HorizontalAlign get getAlign => _align;

  /// Gets the horizontal alignment (alias).
  HorizontalAlign get getAlignHorizontal => _align;

  /// Gets the vertical alignment.
  VerticalAlign get getAlignVertical => _alignVertical;

  /// Gets the border if set.
  Border? get getBorder => _hasFlag(_PropBits.border) ? _border : null;

  /// Gets the border style (alias for getBorder).
  Border? get getBorderStyle => getBorder;

  /// Gets the border sides.
  BorderSides get getBorderSides => _borderSides;

  /// Gets the border foreground color if set.
  Color? get getBorderForeground =>
      _hasFlag(_PropBits.borderForeground) ? _borderForeground : null;

  /// Gets the border background color if set.
  Color? get getBorderBackground =>
      _hasFlag(_PropBits.borderBackground) ? _borderBackground : null;

  /// Gets the top border foreground color if set.
  Color? get getBorderTopForeground =>
      (_borderProps & _borderTopFg) != 0 ? _borderTopForeground : null;

  /// Gets the right border foreground color if set.
  Color? get getBorderRightForeground =>
      (_borderProps & _borderRightFg) != 0 ? _borderRightForeground : null;

  /// Gets the bottom border foreground color if set.
  Color? get getBorderBottomForeground =>
      (_borderProps & _borderBottomFg) != 0 ? _borderBottomForeground : null;

  /// Gets the left border foreground color if set.
  Color? get getBorderLeftForeground =>
      (_borderProps & _borderLeftFg) != 0 ? _borderLeftForeground : null;

  /// Gets the top border background color if set.
  Color? get getBorderTopBackground =>
      (_borderProps & _borderTopBg) != 0 ? _borderTopBackground : null;

  /// Gets the right border background color if set.
  Color? get getBorderRightBackground =>
      (_borderProps & _borderRightBg) != 0 ? _borderRightBackground : null;

  /// Gets the bottom border background color if set.
  Color? get getBorderBottomBackground =>
      (_borderProps & _borderBottomBg) != 0 ? _borderBottomBackground : null;

  /// Gets the left border background color if set.
  Color? get getBorderLeftBackground =>
      (_borderProps & _borderLeftBg) != 0 ? _borderLeftBackground : null;

  /// Gets the border foreground blend stops, if set.
  List<Color> get getBorderForegroundBlend =>
      _hasFlag2(_PropBits.borderForegroundBlend)
      ? _borderForegroundBlend
      : const [];

  /// Gets the border foreground blend offset, if set.
  int get getBorderForegroundBlendOffset =>
      _hasFlag2(_PropBits.borderForegroundBlendOffset)
      ? _borderForegroundBlendOffset
      : 0;

  /// Gets the horizontal frame size (border + padding).
  int get getHorizontalFrameSize {
    var size = _padding.horizontal;
    if (_hasFlag(_PropBits.border) && _border != null && _border!.isVisible) {
      final metrics = _border!.measure(_borderSides);
      size += metrics.horizontal;
    }
    return size;
  }

  /// Gets the vertical frame size (border + padding).
  int get getVerticalFrameSize {
    var size = _padding.vertical;
    if (_hasFlag(_PropBits.border) && _border != null && _border!.isVisible) {
      final metrics = _border!.measure(_borderSides);
      size += metrics.vertical;
    }
    return size;
  }

  /// Gets the frame size (border + padding) as (width, height).
  ({int width, int height}) get getFrameSize =>
      (width: getHorizontalFrameSize, height: getVerticalFrameSize);

  /// Measures the current box model as immutable metrics.
  BoxMetrics get boxMetrics => BoxMetrics(
    contentWidth: _width > 0 ? _width : 0,
    contentHeight: _height > 0 ? _height : 0,
    padding: _padding,
    margin: _margin,
    border: _hasFlag(_PropBits.border) && _border != null
        ? _border!.measure(_borderSides)
        : const BorderMetrics.none(),
  );

  /// Gets the transform function if set.
  String Function(String)? get getTransform =>
      _hasFlag(_PropBits.transform) ? _transform : null;

  /// Gets the pre-set string value if set.
  String? get getValue => _string;

  // ═══════════════════════════════════════════════════════════════════════════
  // PROPERTY CHECKING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Whether a specific property flag is set.
  bool hasProperty(int flag) => _hasFlag(flag);

  /// Whether any text attribute is set.
  bool get hasTextAttributes =>
      _hasFlag(_PropBits.bold) ||
      _hasFlag(_PropBits.italic) ||
      _hasFlag(_PropBits.underline) ||
      _hasFlag(_PropBits.strikethrough) ||
      _hasFlag(_PropBits.dim) ||
      _hasFlag(_PropBits.inverse) ||
      _hasFlag(_PropBits.blink);

  /// Whether this style has no active properties.
  ///
  /// This matches the internal early-return condition used by `render()`.
  bool get isEmpty => _props == 0 && _props2 == 0;

  /// Whether any color is set.
  bool get hasColors =>
      _hasFlag(_PropBits.foreground) ||
      _hasFlag(_PropBits.background) ||
      _hasFlag2(_PropBits.underlineColor) ||
      _hasFlag2(_PropBits.marginBackground);

  /// Whether any spacing (padding or margin) is set.
  bool get hasSpacing =>
      _hasFlag(_PropBits.padding) ||
      _hasFlag(_PropBits.paddingTop) ||
      _hasFlag(_PropBits.paddingRight) ||
      _hasFlag(_PropBits.paddingBottom) ||
      _hasFlag(_PropBits.paddingLeft) ||
      _hasFlag(_PropBits.margin) ||
      _hasFlag(_PropBits.marginTop) ||
      _hasFlag(_PropBits.marginRight) ||
      _hasFlag(_PropBits.marginBottom) ||
      _hasFlag(_PropBits.marginLeft);

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPOSITION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Creates a copy of this style.
  Style copy() {
    final s = Style();
    s._props = _props;
    s._props2 = _props2;
    s._bold = _bold;
    s._italic = _italic;
    s._underline = _underline;
    s._underlineStyle = _underlineStyle;
    s._strikethrough = _strikethrough;
    s._dim = _dim;
    s._inverse = _inverse;
    s._blink = _blink;
    s._foreground = _foreground;
    s._background = _background;
    s._underlineColor = _underlineColor;
    s._borderForeground = _borderForeground;
    s._borderBackground = _borderBackground;
    s._borderTopForeground = _borderTopForeground;
    s._borderTopBackground = _borderTopBackground;
    s._borderRightForeground = _borderRightForeground;
    s._borderRightBackground = _borderRightBackground;
    s._borderBottomForeground = _borderBottomForeground;
    s._borderBottomBackground = _borderBottomBackground;
    s._borderLeftForeground = _borderLeftForeground;
    s._borderLeftBackground = _borderLeftBackground;
    s._borderForegroundBlend = List<Color>.from(_borderForegroundBlend);
    s._borderForegroundBlendOffset = _borderForegroundBlendOffset;
    s._borderProps = _borderProps;
    s._width = _width;
    s._height = _height;
    s._maxWidth = _maxWidth;
    s._maxHeight = _maxHeight;
    s._padding = _padding;
    s._margin = _margin;
    s._align = _align;
    s._alignVertical = _alignVertical;
    s._border = _border;
    s._borderSides = _borderSides;
    s._inline = _inline;
    s._wrapAnsi = _wrapAnsi;
    s._transform = _transform;
    s._whitespaceChar = _whitespaceChar;
    s._whitespaceForeground = _whitespaceForeground;
    s._string = _string;
    s._tabWidth = _tabWidth;
    s._underlineSpaces = _underlineSpaces;
    s._strikethroughSpaces = _strikethroughSpaces;
    s._colorWhitespace = _colorWhitespace;
    s._hyperlinkUrl = _hyperlinkUrl;
    s._hyperlinkParams = _hyperlinkParams;
    s._marginBackground = _marginBackground;
    s._colorProfile = _colorProfile;
    s._hasDarkBackground = _hasDarkBackground;
    return s;
  }

  /// Returns an immutable snapshot of the current style state.
  StyleData get data => StyleData(
    bold: _bold,
    italic: _italic,
    underline: _underline,
    underlineStyle: _underlineStyle,
    strikethrough: _strikethrough,
    dim: _dim,
    inverse: _inverse,
    blink: _blink,
    foreground: _foreground,
    background: _background,
    borderForeground: _borderForeground,
    borderBackground: _borderBackground,
    borderTopForeground: _borderTopForeground,
    borderRightForeground: _borderRightForeground,
    borderBottomForeground: _borderBottomForeground,
    borderLeftForeground: _borderLeftForeground,
    borderTopBackground: _borderTopBackground,
    borderRightBackground: _borderRightBackground,
    borderBottomBackground: _borderBottomBackground,
    borderLeftBackground: _borderLeftBackground,
    borderForegroundBlend: List<Color>.from(_borderForegroundBlend),
    borderForegroundBlendOffset: _borderForegroundBlendOffset,
    width: _width == 0 ? null : _width,
    height: _height == 0 ? null : _height,
    maxWidth: _maxWidth == 0 ? null : _maxWidth,
    maxHeight: _maxHeight == 0 ? null : _maxHeight,
    padding: _padding,
    margin: _margin,
    align: _align,
    alignVertical: _alignVertical,
    border: _border,
    borderSides: _borderSides,
    inline: _inline,
    wrapAnsi: _wrapAnsi,
    transform: _transform,
    paddingChar: _paddingChar,
    marginChar: _marginChar,
    whitespaceChar: _whitespaceChar,
    whitespaceForeground: _whitespaceForeground,
    stringValue: _string,
    tabWidth: _tabWidth,
    underlineSpaces: _underlineSpaces,
    strikethroughSpaces: _strikethroughSpaces,
    colorWhitespace: _colorWhitespace,
    hyperlinkUrl: _hyperlinkUrl,
    hyperlinkParams: _hyperlinkParams,
    marginBackground: _marginBackground,
    underlineColor: _underlineColor,
  );

  /// Inherits explicitly-set properties from another style.
  ///
  /// Only properties that are explicitly set on [other] will be copied
  /// to this style, leaving other properties unchanged.
  Style inherit(Style other) {
    if (other._hasFlag(_PropBits.bold)) {
      _bold = other._bold;
      _setFlag(_PropBits.bold);
    }
    if (other._hasFlag(_PropBits.italic)) {
      _italic = other._italic;
      _setFlag(_PropBits.italic);
    }
    if (other._hasFlag(_PropBits.underline)) {
      _underline = other._underline;
      _setFlag(_PropBits.underline);
    }
    if (other._hasFlag2(_PropBits.underlineStyle)) {
      _underlineStyle = other._underlineStyle;
      _setFlag2(_PropBits.underlineStyle);
    }
    if (other._hasFlag(_PropBits.strikethrough)) {
      _strikethrough = other._strikethrough;
      _setFlag(_PropBits.strikethrough);
    }
    if (other._hasFlag(_PropBits.dim)) {
      _dim = other._dim;
      _setFlag(_PropBits.dim);
    }
    if (other._hasFlag(_PropBits.inverse)) {
      _inverse = other._inverse;
      _setFlag(_PropBits.inverse);
    }
    if (other._hasFlag(_PropBits.blink)) {
      _blink = other._blink;
      _setFlag(_PropBits.blink);
    }
    if (other._hasFlag(_PropBits.foreground)) {
      _foreground = other._foreground;
      _setFlag(_PropBits.foreground);
    }
    if (other._hasFlag(_PropBits.background)) {
      _background = other._background;
      _setFlag(_PropBits.background);
    }
    if (other._hasFlag(_PropBits.borderForeground)) {
      _borderForeground = other._borderForeground;
      _setFlag(_PropBits.borderForeground);
    }
    if (other._hasFlag(_PropBits.borderBackground)) {
      _borderBackground = other._borderBackground;
      _setFlag(_PropBits.borderBackground);
    }
    if (other._hasFlag(_PropBits.width)) {
      _width = other._width;
      _setFlag(_PropBits.width);
    }
    if (other._hasFlag(_PropBits.height)) {
      _height = other._height;
      _setFlag(_PropBits.height);
    }
    if (other._hasFlag(_PropBits.maxWidth)) {
      _maxWidth = other._maxWidth;
      _setFlag(_PropBits.maxWidth);
    }
    if (other._hasFlag(_PropBits.maxHeight)) {
      _maxHeight = other._maxHeight;
      _setFlag(_PropBits.maxHeight);
    }
    if (other._hasFlag(_PropBits.padding)) {
      _padding = other._padding;
      _setFlag(_PropBits.padding);
    }
    if (other._hasFlag(_PropBits.paddingTop)) {
      _padding = _padding.copyWith(top: other._padding.top);
      _setFlag(_PropBits.paddingTop);
    }
    if (other._hasFlag(_PropBits.paddingRight)) {
      _padding = _padding.copyWith(right: other._padding.right);
      _setFlag(_PropBits.paddingRight);
    }
    if (other._hasFlag(_PropBits.paddingBottom)) {
      _padding = _padding.copyWith(bottom: other._padding.bottom);
      _setFlag(_PropBits.paddingBottom);
    }
    if (other._hasFlag(_PropBits.paddingLeft)) {
      _padding = _padding.copyWith(left: other._padding.left);
      _setFlag(_PropBits.paddingLeft);
    }
    if (other._hasFlag(_PropBits.margin)) {
      _margin = other._margin;
      _setFlag(_PropBits.margin);
    }
    if (other._hasFlag(_PropBits.marginTop)) {
      _margin = _margin.copyWith(top: other._margin.top);
      _setFlag(_PropBits.marginTop);
    }
    if (other._hasFlag(_PropBits.marginRight)) {
      _margin = _margin.copyWith(right: other._margin.right);
      _setFlag(_PropBits.marginRight);
    }
    if (other._hasFlag(_PropBits.marginBottom)) {
      _margin = _margin.copyWith(bottom: other._margin.bottom);
      _setFlag(_PropBits.marginBottom);
    }
    if (other._hasFlag(_PropBits.marginLeft)) {
      _margin = _margin.copyWith(left: other._margin.left);
      _setFlag(_PropBits.marginLeft);
    }
    if (other._hasFlag(_PropBits.align)) {
      _align = other._align;
      _setFlag(_PropBits.align);
    }
    if (other._hasFlag(_PropBits.border)) {
      _border = other._border;
      _setFlag(_PropBits.border);
    }
    if (other._hasFlag(_PropBits.borderSides)) {
      _borderSides = other._borderSides;
      _setFlag(_PropBits.borderSides);
    }
    if (other._hasFlag(_PropBits.inline)) {
      _inline = other._inline;
      _setFlag(_PropBits.inline);
    }
    if (other._hasFlag2(_PropBits.wrapAnsi)) {
      _wrapAnsi = other._wrapAnsi;
      _setFlag2(_PropBits.wrapAnsi);
    }
    if (other._hasFlag(_PropBits.transform)) {
      _transform = other._transform;
      _setFlag(_PropBits.transform);
    }
    if (other._hasFlag(_PropBits.alignVertical)) {
      _alignVertical = other._alignVertical;
      _setFlag(_PropBits.alignVertical);
    }
    // Per-side border colors use _borderProps bitfield
    if ((other._borderProps & _borderTopFg) != 0) {
      _borderTopForeground = other._borderTopForeground;
      _borderProps |= _borderTopFg;
    }
    if ((other._borderProps & _borderTopBg) != 0) {
      _borderTopBackground = other._borderTopBackground;
      _borderProps |= _borderTopBg;
    }
    if ((other._borderProps & _borderRightFg) != 0) {
      _borderRightForeground = other._borderRightForeground;
      _borderProps |= _borderRightFg;
    }
    if ((other._borderProps & _borderRightBg) != 0) {
      _borderRightBackground = other._borderRightBackground;
      _borderProps |= _borderRightBg;
    }
    if ((other._borderProps & _borderBottomFg) != 0) {
      _borderBottomForeground = other._borderBottomForeground;
      _borderProps |= _borderBottomFg;
    }
    if ((other._borderProps & _borderBottomBg) != 0) {
      _borderBottomBackground = other._borderBottomBackground;
      _borderProps |= _borderBottomBg;
    }
    if ((other._borderProps & _borderLeftFg) != 0) {
      _borderLeftForeground = other._borderLeftForeground;
      _borderProps |= _borderLeftFg;
    }
    if ((other._borderProps & _borderLeftBg) != 0) {
      _borderLeftBackground = other._borderLeftBackground;
      _borderProps |= _borderLeftBg;
    }
    // Properties from _props2
    if (other._hasFlag2(_PropBits.tabWidth)) {
      _tabWidth = other._tabWidth;
      _setFlag2(_PropBits.tabWidth);
    }
    if (other._hasFlag2(_PropBits.underlineSpaces)) {
      _underlineSpaces = other._underlineSpaces;
      _setFlag2(_PropBits.underlineSpaces);
    }
    if (other._hasFlag2(_PropBits.strikethroughSpaces)) {
      _strikethroughSpaces = other._strikethroughSpaces;
      _setFlag2(_PropBits.strikethroughSpaces);
    }
    if (other._hasFlag2(_PropBits.colorWhitespace)) {
      _colorWhitespace = other._colorWhitespace;
      _setFlag2(_PropBits.colorWhitespace);
    }
    if (other._hasFlag2(_PropBits.borderForegroundBlend)) {
      _borderForegroundBlend = List<Color>.from(other._borderForegroundBlend);
      _setFlag2(_PropBits.borderForegroundBlend);
    }
    if (other._hasFlag2(_PropBits.borderForegroundBlendOffset)) {
      _borderForegroundBlendOffset = other._borderForegroundBlendOffset;
      _setFlag2(_PropBits.borderForegroundBlendOffset);
    }
    if (other._hasFlag2(_PropBits.marginBackground)) {
      _marginBackground = other._marginBackground;
      _setFlag2(_PropBits.marginBackground);
    }
    if (other._hasFlag2(_PropBits.stringValue)) {
      _string = other._string;
      _setFlag2(_PropBits.stringValue);
    }
    if (other._hasFlag2(_PropBits.hyperlink)) {
      _hyperlinkUrl = other._hyperlinkUrl;
      _hyperlinkParams = other._hyperlinkParams;
      _setFlag2(_PropBits.hyperlink);
    }
    if (other._hasFlag2(_PropBits.borderTop)) {
      _borderSides = _borderSides.copyWith(top: other._borderSides.top);
      _setFlag2(_PropBits.borderTop);
    }
    if (other._hasFlag2(_PropBits.borderRight)) {
      _borderSides = _borderSides.copyWith(right: other._borderSides.right);
      _setFlag2(_PropBits.borderRight);
    }
    if (other._hasFlag2(_PropBits.borderBottom)) {
      _borderSides = _borderSides.copyWith(bottom: other._borderSides.bottom);
      _setFlag2(_PropBits.borderBottom);
    }
    if (other._hasFlag2(_PropBits.borderLeft)) {
      _borderSides = _borderSides.copyWith(left: other._borderSides.left);
      _setFlag2(_PropBits.borderLeft);
    }
    if (other._hasFlag2(_PropBits.whitespaceChar)) {
      _whitespaceChar = other._whitespaceChar;
      _setFlag2(_PropBits.whitespaceChar);
    }
    if (other._hasFlag2(_PropBits.whitespaceForeground)) {
      _whitespaceForeground = other._whitespaceForeground;
      _setFlag2(_PropBits.whitespaceForeground);
    }
    return this;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RENDERING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Renders the given text with this style applied.
  ///
  /// This produces an ANSI-escaped string ready for terminal output.
  ///
  /// If [text] is a [List], its elements are joined with spaces.
  String render([Object? text]) {
    String content;
    if (text is List) {
      content = text.map((e) => e?.toString() ?? '').join(' ');
    } else {
      content = text?.toString() ?? '';
    }

    // lipgloss v2 compatibility: if this style has a pre-set string value,
    // render it *in addition to* any provided text.
    //
    // In Go lipgloss, Style.Render(strs...) prepends Style.value and joins with
    // spaces. We mirror that behavior here for API parity (e.g. tree/list
    // prefix markers via `setString()`).
    final preset = _string;
    if (preset != null && preset.isNotEmpty) {
      if (content.isEmpty) {
        content = preset;
      } else {
        content = '$preset $content';
      }
    }

    return renderWithContext(
      content,
      RenderContext(
        colorProfile: _colorProfile,
        hasDarkBackground: _hasDarkBackground,
      ),
    );
  }

  /// Renders the given text with an explicit render context.
  String renderWithContext(Object? text, RenderContext context) {
    final previousContext = _activeRenderContext;
    _activeRenderContext = context;
    try {
      return _renderComposed(text?.toString() ?? '');
    } finally {
      _activeRenderContext = previousContext;
    }
  }

  /// Renders the given text using the settings from the provided [renderer].
  ///
  /// This method temporarily updates this style's [colorProfile] and
  /// [hasDarkBackground] to match the [renderer], renders the text, and then
  /// restores the original settings.
  ///
  /// The rendered text is also written to the [renderer].
  String renderTo(Renderer renderer, [Object? text]) {
    final result = renderWithContext(
      text,
      RenderContext(
        colorProfile: renderer.colorProfile,
        hasDarkBackground: renderer.hasDarkBackground,
      ),
    );
    renderer.write(result);
    return result;
  }

  String _renderComposed(String text) {
    final Stopwatch? sw =
        TuiTrace.enabled && TuiTrace.isTagEnabled(TraceTag.render)
        ? Stopwatch()
        : null;
    sw?.start();
    text = _applyConsoleTags(text);

    // Potentially convert tabs to spaces
    text = _maybeConvertTabs(text);
    // carriage returns can cause strange behaviour when rendering.
    text = text.replaceAll('\r\n', '\n');

    // If this style has no active properties, return the string unchanged.
    // This matches lipgloss' early return when a style is effectively empty.
    if (_props == 0 && _props2 == 0) {
      _traceStyleRender('style.render noop len=${text.length}', sw);
      return text;
    }

    // Check if any styling or layout is needed
    final hasLayout =
        _hasFlag(_PropBits.width) ||
        _hasFlag(_PropBits.height) ||
        _hasFlag(_PropBits.maxWidth) ||
        _hasFlag(_PropBits.maxHeight) ||
        _hasFlag(_PropBits.border) ||
        _hasFlag(_PropBits.align) ||
        _hasFlag(_PropBits.transform) ||
        hasSpacing;

    if (colorProfile == ColorProfile.ascii &&
        !hasTextAttributes &&
        !hasLayout) {
      _traceStyleRender('style.render ascii len=${text.length}', sw);
      return text;
    }

    var result = text;

    // Apply transform first
    if (_hasFlag(_PropBits.transform) && _transform != null) {
      result = _transform!(result);
    }

    // If inline, skip layout processing
    if (_inline) {
      final inlineResult = _applyTextStyles(result);
      _traceStyleRender(
        'style.render inline len=${text.length} props=$_props props2=$_props2',
        sw,
      );
      return inlineResult;
    }

    // Process lines for layout
    var lines = result.split('\n');

    // Apply max width (truncate)
    if (_hasFlag(_PropBits.maxWidth) && _maxWidth > 0) {
      lines = _truncateLines(lines, _maxWidth);
    }

    // Calculate content width
    var contentWidth = _getMaxLineWidth(lines);

    // Apply fixed width - wrap text to fit
    // Like lipgloss, wrap at (width - horizontal padding) so content + padding = width
    if (_hasFlag(_PropBits.width) && _width > 0) {
      final wrapAt = _width - _padding.horizontal;
      lines = _wrapText(lines, wrapAt > 0 ? wrapAt : _width);
      contentWidth = wrapAt > 0 ? wrapAt : _width;
    }

    // Render core text (styled content) before padding/alignment/border.
    //
    // Lipgloss v2 parity: padding/alignment whitespace should not inherit
    // foreground color by default, and background styling on whitespace is
    // controlled by `colorWhitespace`.
    lines = lines.map(_applyTextStyles).toList();

    // Apply padding (fixed spaces, alignment fills to width later)
    if (!_padding.isZero) {
      lines = _applyPadding(lines);
    }

    var boxWidth = contentWidth + _padding.horizontal;
    if (_hasFlag(_PropBits.width) && _width > 0) {
      boxWidth = _width;
    }

    // Apply alignment to reach target width
    // Like lipgloss, this runs when there are multiple lines OR when width is set
    // The target width is the full _width (including padding), or the widest line if no width set
    if ((lines.length > 1 || _hasFlag(_PropBits.width)) && boxWidth > 0) {
      lines = _alignLines(lines, boxWidth, widestLine: boxWidth);
    }

    // Update contentWidth after alignment for border
    contentWidth = boxWidth;

    // Apply border
    if (_hasFlag(_PropBits.border) && _border != null && _border!.isVisible) {
      lines = _applyBorder(lines, contentWidth);
      final metrics = _border!.measure(_borderSides);
      contentWidth += metrics.horizontal;
    }

    // Apply fixed height (affects the styled box, margin is applied after)
    if (_hasFlag(_PropBits.height) && _height > 0) {
      lines = _applyHeight(lines, _height);
    }

    // Apply max height
    if (_hasFlag(_PropBits.maxHeight) &&
        _maxHeight > 0 &&
        lines.length > _maxHeight) {
      lines = lines.take(_maxHeight).toList();
    }

    // Apply margin (after sizing the box; margin lines are unstyled)
    if (!_margin.isZero) {
      lines = _applyMargin(lines, contentWidth);
    }

    result = lines.join('\n');
    _traceStyleRender(
      'style.render len=${text.length} props=$_props props2=$_props2',
      sw,
    );
    return result;
  }

  bool get _useSpaceStyler {
    final underline = _hasFlag(_PropBits.underline) && _underline;
    final strikethrough = _hasFlag(_PropBits.strikethrough) && _strikethrough;
    final underlineSpaces =
        _hasFlag2(_PropBits.underlineSpaces) && _underlineSpaces;
    final strikethroughSpaces =
        _hasFlag2(_PropBits.strikethroughSpaces) && _strikethroughSpaces;

    return (underline && !underlineSpaces) ||
        (strikethrough && !strikethroughSpaces) ||
        underlineSpaces ||
        strikethroughSpaces;
  }

  /// Applies ANSI text styling to a string.
  String _applyTextStyles(String text) {
    if (colorProfile == ColorProfile.ascii) {
      return text;
    }

    if (!_useSpaceStyler) {
      return _applyStylesToString(text);
    }

    final buf = StringBuffer();
    var i = 0;
    while (i < text.length) {
      final (:grapheme, :nextIndex) = uni.readGraphemeAt(text, i);
      if (grapheme == ' ' || grapheme == '\t' || grapheme == '\u00A0') {
        buf.write(_applyStylesToString(grapheme, isSpace: true));
      } else {
        buf.write(_applyStylesToString(grapheme, isSpace: false));
      }
      i = nextIndex;
    }
    return buf.toString();
  }

  String _applyStylesToString(String text, {bool isSpace = false}) {
    if (colorProfile == ColorProfile.ascii) return text;
    final cached = _resolveTextStyleAffixes(isSpace);
    if (cached == null) return text;
    return '${cached.prefix}$text${cached.suffix}\x1b[m';
  }

  ({String prefix, String suffix})? _resolveTextStyleAffixes(bool isSpace) {
    if (isSpace) {
      if (_hasCachedSpaceTextStyle) {
        if (_cachedSpaceTextStylePrefix == null) return null;
        return (
          prefix: _cachedSpaceTextStylePrefix!,
          suffix: _cachedSpaceTextStyleSuffix!,
        );
      }
    } else if (_hasCachedTextStyle) {
      if (_cachedTextStylePrefix == null) return null;
      return (prefix: _cachedTextStylePrefix!, suffix: _cachedTextStyleSuffix!);
    }

    final prefix = StringBuffer();
    final suffix = StringBuffer();
    var hasAnsi = false;

    // Apply colors
    if (_hasFlag(_PropBits.background) && _background != null) {
      final ansi = _background!.toAnsi(
        colorProfile,
        background: true,
        hasDarkBackground: hasDarkBackground,
      );
      if (ansi.isNotEmpty) {
        prefix.write(ansi);
        hasAnsi = true;
      }
    }

    if (_hasFlag(_PropBits.foreground) && _foreground != null) {
      final ansi = _foreground!.toAnsi(
        colorProfile,
        background: false,
        hasDarkBackground: hasDarkBackground,
      );
      if (ansi.isNotEmpty) {
        prefix.write(ansi);
        hasAnsi = true;
      }
    }

    // Apply text attributes
    if (_hasFlag(_PropBits.bold) && _bold) {
      prefix.write('\x1b[1m');
      hasAnsi = true;
    }
    if (_hasFlag(_PropBits.italic) && _italic) {
      prefix.write('\x1b[3m');
      hasAnsi = true;
    }
    if (_hasFlag(_PropBits.underline) && _underline) {
      final underlineSpaces =
          _hasFlag2(_PropBits.underlineSpaces) && _underlineSpaces;
      if (!isSpace || underlineSpaces) {
        final style = getUnderlineStyle;
        final start = switch (style) {
          UnderlineStyle.none => '',
          UnderlineStyle.single => '\x1b[4m',
          UnderlineStyle.double => '\x1b[21m',
          UnderlineStyle.curly => '\x1b[4:3m',
          UnderlineStyle.dotted => '\x1b[4:4m',
          UnderlineStyle.dashed => '\x1b[4:5m',
        };
        if (start.isNotEmpty) {
          // Underline color must be applied *within* the underline span.
          // If we emit 58/59 outside, the 59 reset would occur before 4m/4:xm.
          prefix.write(start);
          if (_hasFlag2(_PropBits.underlineColor) && _underlineColor != null) {
            final ansi = _underlineColor!.toAnsi(
              colorProfile,
              underline: true,
              hasDarkBackground: hasDarkBackground,
            );
            if (ansi.isNotEmpty) {
              prefix.write(ansi);
              suffix.write('\x1b[59m');
            }
          }
          suffix.write('\x1b[24m');
          hasAnsi = true;
        }
      }
    }
    if (_hasFlag(_PropBits.strikethrough) && _strikethrough) {
      final strikethroughSpaces =
          _hasFlag2(_PropBits.strikethroughSpaces) && _strikethroughSpaces;
      if (!isSpace || strikethroughSpaces) {
        prefix.write('\x1b[9m');
        hasAnsi = true;
      }
    }
    if (_hasFlag(_PropBits.dim) && _dim) {
      prefix.write('\x1b[2m');
      hasAnsi = true;
    }
    if (_hasFlag(_PropBits.inverse) && _inverse) {
      prefix.write('\x1b[7m');
      hasAnsi = true;
    }
    if (_hasFlag(_PropBits.blink) && _blink) {
      prefix.write('\x1b[5m');
      hasAnsi = true;
    }

    if (_hasFlag2(_PropBits.hyperlink) && _hyperlinkUrl != null) {
      final params = _hyperlinkParams;
      final linkPrefix = params.isEmpty
          ? '\x1b]8;;${_hyperlinkUrl!}\x1b\\'
          : '\x1b]8;$params;${_hyperlinkUrl!}\x1b\\';
      prefix.write(linkPrefix);
      suffix.write('\x1b]8;;\x1b\\');
      hasAnsi = true;
    }

    // lipgloss v2 parity: use a full reset when any styling is applied.
    if (!hasAnsi) {
      if (isSpace) {
        _hasCachedSpaceTextStyle = true;
      } else {
        _hasCachedTextStyle = true;
      }
      return null;
    }

    final resolved = (prefix: '$prefix', suffix: '$suffix');
    if (isSpace) {
      _cachedSpaceTextStylePrefix = resolved.prefix;
      _cachedSpaceTextStyleSuffix = resolved.suffix;
      _hasCachedSpaceTextStyle = true;
    } else {
      _cachedTextStylePrefix = resolved.prefix;
      _cachedTextStyleSuffix = resolved.suffix;
      _hasCachedTextStyle = true;
    }
    return resolved;
  }

  bool get _styleWhitespaceEnabled {
    final reverse = _hasFlag(_PropBits.inverse) && _inverse;
    final hasBg = _hasFlag(_PropBits.background) && _background != null;
    return reverse ||
        (_colorWhitespace && hasBg) ||
        _hasFlag2(_PropBits.whitespaceForeground) ||
        _hasFlag2(_PropBits.whitespaceChar);
  }

  /// Styles whitespace outside the core text (padding/alignment fill).
  ///
  /// Lipgloss v2 parity:
  /// - Foreground is not applied to whitespace unless inverse is enabled.
  /// - Background is applied to whitespace only when `colorWhitespace` is true.
  String _styleWhitespace(String text) {
    if (text.isEmpty) return text;
    if (colorProfile == ColorProfile.ascii) return text;
    if (!_styleWhitespaceEnabled) return text;

    final reverse = _hasFlag(_PropBits.inverse) && _inverse;

    var styled = _hasFlag2(_PropBits.whitespaceChar)
        ? _whitespaceChar * Layout.visibleLength(text)
        : text;
    var hasAnsi = false;

    if (_hasFlag2(_PropBits.whitespaceForeground) &&
        _whitespaceForeground != null) {
      final ansi = _whitespaceForeground!.toAnsi(
        colorProfile,
        background: false,
        hasDarkBackground: hasDarkBackground,
      );
      if (ansi.isNotEmpty) {
        styled = '$ansi$styled';
        hasAnsi = true;
      }
    }

    // Apply background only if colorWhitespace is enabled.
    if (_colorWhitespace &&
        _hasFlag(_PropBits.background) &&
        _background != null) {
      final ansi = _background!.toAnsi(
        colorProfile,
        background: true,
        hasDarkBackground: hasDarkBackground,
      );
      if (ansi.isNotEmpty) {
        styled = '$ansi$styled';
        hasAnsi = true;
      }
    }

    // Apply foreground to whitespace only in reverse mode.
    if (reverse && _hasFlag(_PropBits.foreground) && _foreground != null) {
      final ansi = _foreground!.toAnsi(
        colorProfile,
        background: false,
        hasDarkBackground: hasDarkBackground,
      );
      if (ansi.isNotEmpty) {
        styled = '$ansi$styled';
        hasAnsi = true;
      }
    }

    if (reverse) {
      styled = '\x1b[7m$styled';
      hasAnsi = true;
    }

    return hasAnsi ? '$styled\x1b[m' : styled;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Layout Helpers
  // ─────────────────────────────────────────────────────────────────────────────

  /// Strips ANSI escape sequences from a string.
  static String stripAnsi(String text) {
    return Ansi.stripAnsi(text);
  }

  /// Applies one of two styles to runes at specific rune indices.
  ///
  /// This mirrors lipgloss v2's `StyleRunes` helper: the string is treated as a
  /// sequence of runes (Unicode code points), and `indices` refers to rune
  /// positions, not bytes.
  ///
  /// Indices out of bounds are ignored.
  static String styleRunes(
    String str,
    Iterable<int> indices,
    Style matched,
    Style unmatched,
  ) {
    final indexSet = indices.toSet();
    final runes = str.runes.toList(growable: false);
    if (runes.isEmpty) return '';

    final out = StringBuffer();
    var group = StringBuffer();

    for (var i = 0; i < runes.length; i++) {
      group.writeCharCode(runes[i]);

      final matches = indexSet.contains(i);
      final nextMatches = indexSet.contains(i + 1);

      if (matches != nextMatches || i == runes.length - 1) {
        out.write((matches ? matched : unmatched).render(group.toString()));
        group = StringBuffer();
      }
    }

    return out.toString();
  }

  /// Gets the visible length of a string (ignoring ANSI codes).
  static int visibleLength(String text) {
    return Ansi.visibleLength(text);
  }

  /// Stacks multiple blocks of text on top of each other.
  ///
  /// Higher layers (later in the list) overlay lower layers. Spaces in higher
  /// layers are treated as transparent, allowing the layer below to show through.
  static String stack(List<String> blocks) => Layout.stack(blocks);

  int _getMaxLineWidth(List<String> lines) {
    if (lines.isEmpty) return 0;
    var maxWidth = 0;
    for (final line in lines) {
      final width = visibleLength(line);
      if (width > maxWidth) maxWidth = width;
    }
    return maxWidth;
  }

  List<String> _truncateLines(List<String> lines, int maxWidth) {
    return lines.map((line) => _truncateLine(line, maxWidth)).toList();
  }

  /// Truncates a single line while preserving ANSI codes.
  String _truncateLine(String line, int maxWidth) {
    final visible = visibleLength(line);
    if (visible <= maxWidth) return line;

    final targetLen = maxWidth - 1; // Leave room for ellipsis
    if (targetLen <= 0) return EllipsisChars.horizontal;
    final sliced = ranges.cutAnsiByCells(line, 0, targetLen);
    return '$sliced\x1B[0m${EllipsisChars.horizontal}';
  }

  /// Wraps text to fit within a specified width.
  ///
  /// Breaks lines at word boundaries when possible, preserving ANSI codes.
  List<String> _wrapText(List<String> lines, int maxWidth) {
    final joined = lines.join('\n');
    return uv_wrap.wrapAnsiPreserving(joined, maxWidth).split('\n');
  }

  /// Aligns lines horizontally, like lipgloss's alignTextHorizontal.
  ///
  /// For each line:
  /// 1. Calculate shortAmount = widestLine - lineWidth (to match widest line)
  /// 2. Add additional space if width > (shortAmount + lineWidth)
  /// This ensures all lines become the same width, and reach the target width if set.
  List<String> _alignLines(
    List<String> lines,
    int targetWidth, {
    int? widestLine,
  }) {
    if (lines.isEmpty) return lines;

    final widest = widestLine ?? _getMaxLineWidth(lines);

    return lines.map((line) {
      final lineWidth = visibleLength(line);
      var shortAmount = widest - lineWidth; // difference from widest line

      // Add more if we need to reach target width
      final neededForWidth = targetWidth - (shortAmount + lineWidth);
      if (neededForWidth > 0) {
        shortAmount += neededForWidth;
      }

      if (shortAmount <= 0) return line;

      String ws(int n) {
        if (n <= 0) return '';
        final raw = _paddingChar * n;
        return _styleWhitespace(raw);
      }

      switch (_align) {
        case HorizontalAlign.left:
          return '$line${ws(shortAmount)}';
        case HorizontalAlign.center:
          final left = shortAmount ~/ 2;
          final right = shortAmount - left;
          return '${ws(left)}$line${ws(right)}';
        case HorizontalAlign.right:
          return '${ws(shortAmount)}$line';
      }
    }).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Console-style tag parsing (Symfony/Laravel)
  // ─────────────────────────────────────────────────────────────────────────

  String _maybeConvertTabs(String text) {
    final tw = _hasFlag2(_PropBits.tabWidth) ? _tabWidth : 4;
    return Ansi.expandTabs(text, tabWidth: tw);
  }

  String _applyConsoleTags(String text) {
    return ConsoleTagParser(
      colorProfile: colorProfile,
      hasDarkBackground: hasDarkBackground,
    ).render(text);
  }

  /// Applies padding (fixed spaces, not filling to width).
  /// Like lipgloss, padding adds fixed space characters - alignment fills to width later.
  List<String> _applyPadding(List<String> lines) {
    final result = <String>[];
    final leftPad = _styleWhitespace(_paddingChar * _padding.left);
    final rightPad = _styleWhitespace(_paddingChar * _padding.right);

    // Top padding - empty lines (will be filled by alignment)
    for (var i = 0; i < _padding.top; i++) {
      result.add('');
    }

    // Content with horizontal padding (fixed spaces, not filling)
    for (final line in lines) {
      result.add('$leftPad$line$rightPad');
    }

    // Bottom padding - empty lines (will be filled by alignment)
    for (var i = 0; i < _padding.bottom; i++) {
      result.add('');
    }

    return result;
  }

  List<String> _applyBorder(List<String> lines, int contentWidth) {
    final result = <String>[];
    final b = _border!;
    final sides = _borderSides;

    Color? resolveBorderFg(int sideMask, Color? sideColor) =>
        (_borderProps & sideMask) != 0 ? sideColor : getBorderForeground;
    Color? resolveBorderBg(int sideMask, Color? sideColor) =>
        (_borderProps & sideMask) != 0 ? sideColor : getBorderBackground;

    final topBg = resolveBorderBg(_borderTopBg, _borderTopBackground);
    final rightBg = resolveBorderBg(_borderRightBg, _borderRightBackground);
    final bottomBg = resolveBorderBg(_borderBottomBg, _borderBottomBackground);
    final leftBg = resolveBorderBg(_borderLeftBg, _borderLeftBackground);

    final topFg = resolveBorderFg(_borderTopFg, _borderTopForeground);
    final rightFg = resolveBorderFg(_borderRightFg, _borderRightForeground);
    final bottomFg = resolveBorderFg(_borderBottomFg, _borderBottomForeground);
    final leftFg = resolveBorderFg(_borderLeftFg, _borderLeftForeground);

    bool canStyle() =>
        colorProfile != ColorProfile.ascii &&
        colorProfile != ColorProfile.noColor;

    String styleBorderSolid(String text, {Color? fg, Color? bg}) {
      if (!canStyle()) return text;
      if (text.isEmpty) return text;
      if (fg == null && bg == null) return text;

      final buf = StringBuffer();
      if (bg != null) {
        final bgAnsi = bg.toAnsi(
          colorProfile,
          background: true,
          hasDarkBackground: hasDarkBackground,
        );
        if (bgAnsi.isNotEmpty) buf.write(bgAnsi);
      }
      if (fg != null) {
        final fgAnsi = fg.toAnsi(
          colorProfile,
          background: false,
          hasDarkBackground: hasDarkBackground,
        );
        if (fgAnsi.isNotEmpty) buf.write(fgAnsi);
      }
      buf.write(text);
      buf.write('\x1b[m');
      return buf.toString();
    }

    String styleBorderBlend(
      String border,
      List<Color> fgGradient, {
      Color? bg,
    }) {
      if (!canStyle()) return border;
      if (border.isEmpty) return border;
      if (fgGradient.isEmpty && bg == null) return border;

      final buf = StringBuffer();
      if (bg != null) {
        final bgAnsi = bg.toAnsi(
          colorProfile,
          background: true,
          hasDarkBackground: hasDarkBackground,
        );
        if (bgAnsi.isNotEmpty) buf.write(bgAnsi);
      }

      var i = 0;
      for (final g in uni.graphemes(border)) {
        if (fgGradient.isNotEmpty) {
          final fg =
              fgGradient[i < fgGradient.length ? i : fgGradient.length - 1];
          final fgAnsi = fg.toAnsi(
            colorProfile,
            background: false,
            hasDarkBackground: hasDarkBackground,
          );
          if (fgAnsi.isNotEmpty) buf.write(fgAnsi);
        }
        buf.write(g);
        i++;
      }
      buf.write('\x1b[m');
      return buf.toString();
    }

    final useBlend =
        _hasFlag2(_PropBits.borderForegroundBlend) &&
        _borderForegroundBlend.length >= 2;

    _BorderBlend? blendState;
    if (useBlend) {
      final width = contentWidth;
      final height = lines.length;
      final steps = (height + width + 2) * 2;
      final gradient = blend.blend1D(
        steps,
        _borderForegroundBlend,
        hasDarkBackground: hasDarkBackground,
      );
      if (gradient.length == steps) {
        final rotated = _rotateGradient(
          gradient,
          _hasFlag2(_PropBits.borderForegroundBlendOffset)
              ? _borderForegroundBlendOffset
              : 0,
        );
        var offset = 0;
        List<Color> take(int n) {
          final out = rotated.sublist(offset, offset + n);
          offset += n;
          return out;
        }

        blendState = _BorderBlend(
          top: take(width + 2),
          right: take(height),
          bottom: take(width + 2).reversed.toList(growable: false),
          left: take(height).reversed.toList(growable: false),
        );
      }
    }

    // Top border
    if (sides.top) {
      final left = sides.left ? b.topLeft : '';
      final right = sides.right ? b.topRight : '';
      final raw = '$left${b.top * contentWidth}$right';
      if (blendState != null) {
        result.add(styleBorderBlend(raw, blendState.top, bg: topBg));
      } else {
        result.add(styleBorderSolid(raw, fg: topFg, bg: topBg));
      }
    }

    // Content lines with side borders
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final left = sides.left
          ? (blendState != null
                ? styleBorderSolid(b.left, fg: blendState.left[i], bg: leftBg)
                : styleBorderSolid(b.left, fg: leftFg, bg: leftBg))
          : '';
      final right = sides.right
          ? (blendState != null
                ? styleBorderSolid(
                    b.right,
                    fg: blendState.right[i],
                    bg: rightBg,
                  )
                : styleBorderSolid(b.right, fg: rightFg, bg: rightBg))
          : '';
      result.add('$left$line$right');
    }

    // Bottom border
    if (sides.bottom) {
      final left = sides.left ? b.bottomLeft : '';
      final right = sides.right ? b.bottomRight : '';
      final raw = '$left${b.bottom * contentWidth}$right';
      if (blendState != null) {
        result.add(styleBorderBlend(raw, blendState.bottom, bg: bottomBg));
      } else {
        result.add(styleBorderSolid(raw, fg: bottomFg, bg: bottomBg));
      }
    }

    return result;
  }

  List<String> _applyMargin(List<String> lines, int contentWidth) {
    final result = <String>[];
    final leftMargin = _styleMargin(_marginChar * _margin.left);
    final rightMargin = _styleMargin(_marginChar * _margin.right);
    final horizontalFill = _styleMargin(_marginChar * contentWidth);

    // Top margin
    for (var i = 0; i < _margin.top; i++) {
      result.add('$leftMargin$horizontalFill$rightMargin');
    }

    // Content with horizontal margin
    for (final line in lines) {
      result.add('$leftMargin$line$rightMargin');
    }

    // Bottom margin
    for (var i = 0; i < _margin.bottom; i++) {
      result.add('$leftMargin$horizontalFill$rightMargin');
    }

    return result;
  }

  String _styleMargin(String text) {
    if (text.isEmpty) return text;
    if (colorProfile == ColorProfile.ascii) return text;
    if (!_hasFlag2(_PropBits.marginBackground) || _marginBackground == null) {
      return text;
    }

    final ansi = _marginBackground!.toAnsi(
      colorProfile,
      background: true,
      hasDarkBackground: hasDarkBackground,
    );
    return ansi.isNotEmpty ? '$ansi$text\x1b[m' : text;
  }

  List<String> _applyHeight(List<String> lines, int targetHeight) {
    if (lines.length >= targetHeight) {
      return lines.take(targetHeight).toList();
    }

    final result = List<String>.from(lines);
    final width = result.isEmpty
        ? 0
        : result.map(visibleLength).reduce(math.max);
    final fillLine = _styleWhitespace(' ' * width);
    final remaining = targetHeight - result.length;

    var top = 0;
    var bottom = 0;
    switch (_alignVertical) {
      case VerticalAlign.top:
        bottom = remaining;
        break;
      case VerticalAlign.center:
        top = remaining ~/ 2;
        bottom = remaining - top;
        break;
      case VerticalAlign.bottom:
        top = remaining;
        break;
    }

    for (var i = 0; i < top; i++) {
      result.insert(0, fillLine);
    }
    for (var i = 0; i < bottom; i++) {
      result.add(fillLine);
    }
    return result;
  }

  @override
  String toString() {
    // If a string was pre-set, render it
    if (_string != null) {
      return _renderComposed(_string!);
    }
    // Otherwise, return a debug representation
    final parts = <String>[];
    if (isBold) parts.add('bold');
    if (isItalic) parts.add('italic');
    if (isUnderline) parts.add('underline');
    if (_hasFlag(_PropBits.foreground)) parts.add('fg:$_foreground');
    if (_hasFlag(_PropBits.background)) parts.add('bg:$_background');
    if (_hasFlag(_PropBits.width)) parts.add('width:$_width');
    if (_hasFlag(_PropBits.height)) parts.add('height:$_height');
    if (!_padding.isZero) parts.add('padding:$_padding');
    if (!_margin.isZero) parts.add('margin:$_margin');
    if (_hasFlag(_PropBits.border)) parts.add('border:$_border');
    return 'Style(${parts.join(', ')})';
  }
}

final class _BorderBlend {
  const _BorderBlend({
    required this.top,
    required this.right,
    required this.bottom,
    required this.left,
  });

  final List<Color> top;
  final List<Color> right;
  final List<Color> bottom;
  final List<Color> left;
}

List<T> _rotateGradient<T>(List<T> gradient, int offset) {
  if (gradient.isEmpty) return gradient;
  if (offset == 0) return gradient;

  // lipgloss v2 parity: rotate left by (-offset).
  var r = -offset;
  final n = gradient.length;
  r %= n;
  if (r < 0) r += n;
  if (r == 0) return gradient;

  return [...gradient.sublist(r), ...gradient.sublist(0, r)];
}

/// Styles individual runes in a string using a styler function.
///
String styleRunes(String s, Style Function(int rune, int index) styler) {
  final runes = s.runes.toList(growable: false);
  if (runes.isEmpty) return '';

  final out = StringBuffer();
  for (var i = 0; i < runes.length; i++) {
    final style = styler(runes[i], i);
    out.write(style.render(String.fromCharCode(runes[i])));
  }
  return out.toString();
}

/// Style set for interactive states.
///
/// `normal` always applies. State styles are overlaid in this order:
/// focused -> hovered -> active -> disabled.
///
/// This mirrors common CSS pseudo-class behavior where later styles in the
/// chain take precedence when multiple states are active.
class InteractiveStyle {
  /// Creates a new interactive style bundle.
  InteractiveStyle({
    Style? normal,
    this.hover,
    this.focus,
    this.active,
    this.disabled,
  }) : normal = normal ?? Style();

  /// Base style used when no state is active.
  final Style normal;

  /// Optional style to apply when the element is hovered.
  final Style? hover;

  /// Optional style to apply when the element is focused.
  final Style? focus;

  /// Optional style to apply when the element is active/pressed.
  final Style? active;

  /// Optional style to apply when the element is disabled.
  final Style? disabled;

  /// Resolves the combined style from the current interaction state.
  ///
  /// State precedence is:
  /// 1. [focus]
  /// 2. [hover]
  /// 3. [active]
  /// 4. [disabled]
  ///
  /// The precedence order gives hover a higher priority than focus to support
  /// the parity requirement where hover wins when both states are active.
  Style resolve({
    bool isFocused = false,
    bool isHovered = false,
    bool isActive = false,
    bool isDisabled = false,
  }) {
    final resolved = normal.copy();
    if (isFocused) {
      if (focus != null) {
        resolved.inherit(focus!);
      }
    }
    if (isHovered) {
      if (hover != null) {
        resolved.inherit(hover!);
      }
    }
    if (isActive) {
      if (active != null) {
        resolved.inherit(active!);
      }
    }
    if (isDisabled) {
      if (disabled != null) {
        resolved.inherit(disabled!);
      }
    }
    return resolved;
  }
}

/// Convenience extensions for common semantic styles.
extension StyleConvenienceExtensions on Style {
  /// Renders text with the muted color.
  String muted(Object? text) => copy().foreground(Colors.muted).render(text);

  /// Renders text with bold formatting.
  String emphasize(Object? text) => copy().bold().render(text);

  /// Renders text with the success color.
  String success(Object? text) =>
      copy().foreground(Colors.success).render(text);

  /// Renders text with the warning color.
  String warning(Object? text) =>
      copy().foreground(Colors.warning).render(text);

  /// Renders text with the error color.
  String error(Object? text) => copy().foreground(Colors.error).render(text);

  /// Renders text with the info color.
  String info(Object? text) => copy().foreground(Colors.info).render(text);
}
