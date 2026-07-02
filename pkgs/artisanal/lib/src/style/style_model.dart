library;

import 'border.dart';
import 'color.dart';
import 'properties.dart';

enum BoxSizing { contentBox, borderBox }

final class RenderContext {
  const RenderContext({
    required this.colorProfile,
    required this.hasDarkBackground,
  });

  final ColorProfile colorProfile;
  final bool hasDarkBackground;
}

final class BoxMetrics {
  const BoxMetrics({
    required this.contentWidth,
    required this.contentHeight,
    required this.padding,
    required this.margin,
    required this.border,
    this.sizing = BoxSizing.contentBox,
  });

  final int contentWidth;
  final int contentHeight;
  final Padding padding;
  final Margin margin;
  final BorderMetrics border;
  final BoxSizing sizing;

  int get innerWidth => contentWidth + padding.horizontal;
  int get innerHeight => contentHeight + padding.vertical;
  int get borderBoxWidth => innerWidth + border.horizontal;
  int get borderBoxHeight => innerHeight + border.vertical;
  int get outerWidth => borderBoxWidth + margin.horizontal;
  int get outerHeight => borderBoxHeight + margin.vertical;
}

final class StyleData {
  const StyleData({
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.underlineStyle = UnderlineStyle.single,
    this.strikethrough = false,
    this.dim = false,
    this.inverse = false,
    this.blink = false,
    this.foreground,
    this.background,
    this.borderForeground,
    this.borderBackground,
    this.borderTopForeground,
    this.borderRightForeground,
    this.borderBottomForeground,
    this.borderLeftForeground,
    this.borderTopBackground,
    this.borderRightBackground,
    this.borderBottomBackground,
    this.borderLeftBackground,
    this.borderForegroundBlend = const [],
    this.borderForegroundBlendOffset = 0,
    this.width,
    this.height,
    this.maxWidth,
    this.maxHeight,
    this.padding = Padding.zero,
    this.margin = Margin.zero,
    this.align = HorizontalAlign.left,
    this.alignVertical = VerticalAlign.top,
    this.border,
    this.borderSides = BorderSides.all,
    this.inline = false,
    this.wrapAnsi = false,
    this.transform,
    this.paddingChar = ' ',
    this.marginChar = ' ',
    this.whitespaceChar = ' ',
    this.whitespaceForeground,
    this.stringValue,
    this.tabWidth = 4,
    this.underlineSpaces = false,
    this.strikethroughSpaces = false,
    this.colorWhitespace = true,
    this.hyperlinkUrl,
    this.hyperlinkParams = '',
    this.marginBackground,
    this.underlineColor,
  });

  final bool bold;
  final bool italic;
  final bool underline;
  final UnderlineStyle underlineStyle;
  final bool strikethrough;
  final bool dim;
  final bool inverse;
  final bool blink;

  final Color? foreground;
  final Color? background;
  final Color? borderForeground;
  final Color? borderBackground;
  final Color? borderTopForeground;
  final Color? borderRightForeground;
  final Color? borderBottomForeground;
  final Color? borderLeftForeground;
  final Color? borderTopBackground;
  final Color? borderRightBackground;
  final Color? borderBottomBackground;
  final Color? borderLeftBackground;
  final List<Color> borderForegroundBlend;
  final int borderForegroundBlendOffset;

  final int? width;
  final int? height;
  final int? maxWidth;
  final int? maxHeight;

  final Padding padding;
  final Margin margin;
  final HorizontalAlign align;
  final VerticalAlign alignVertical;
  final Border? border;
  final BorderSides borderSides;
  final bool inline;
  final bool wrapAnsi;
  final String Function(String)? transform;
  final String paddingChar;
  final String marginChar;
  final String whitespaceChar;
  final Color? whitespaceForeground;
  final String? stringValue;
  final int tabWidth;
  final bool underlineSpaces;
  final bool strikethroughSpaces;
  final bool colorWhitespace;
  final String? hyperlinkUrl;
  final String hyperlinkParams;
  final Color? marginBackground;
  final Color? underlineColor;

  StyleData copyWith({
    bool? bold,
    bool? italic,
    bool? underline,
    UnderlineStyle? underlineStyle,
    bool? strikethrough,
    bool? dim,
    bool? inverse,
    bool? blink,
    Color? foreground,
    Color? background,
    Color? borderForeground,
    Color? borderBackground,
    Color? borderTopForeground,
    Color? borderRightForeground,
    Color? borderBottomForeground,
    Color? borderLeftForeground,
    Color? borderTopBackground,
    Color? borderRightBackground,
    Color? borderBottomBackground,
    Color? borderLeftBackground,
    List<Color>? borderForegroundBlend,
    int? borderForegroundBlendOffset,
    int? width,
    int? height,
    int? maxWidth,
    int? maxHeight,
    Padding? padding,
    Margin? margin,
    HorizontalAlign? align,
    VerticalAlign? alignVertical,
    Border? border,
    BorderSides? borderSides,
    bool? inline,
    bool? wrapAnsi,
    String Function(String)? transform,
    String? paddingChar,
    String? marginChar,
    String? whitespaceChar,
    Color? whitespaceForeground,
    String? stringValue,
    int? tabWidth,
    bool? underlineSpaces,
    bool? strikethroughSpaces,
    bool? colorWhitespace,
    String? hyperlinkUrl,
    String? hyperlinkParams,
    Color? marginBackground,
    Color? underlineColor,
  }) {
    return StyleData(
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      underlineStyle: underlineStyle ?? this.underlineStyle,
      strikethrough: strikethrough ?? this.strikethrough,
      dim: dim ?? this.dim,
      inverse: inverse ?? this.inverse,
      blink: blink ?? this.blink,
      foreground: foreground ?? this.foreground,
      background: background ?? this.background,
      borderForeground: borderForeground ?? this.borderForeground,
      borderBackground: borderBackground ?? this.borderBackground,
      borderTopForeground: borderTopForeground ?? this.borderTopForeground,
      borderRightForeground: borderRightForeground ?? this.borderRightForeground,
      borderBottomForeground: borderBottomForeground ?? this.borderBottomForeground,
      borderLeftForeground: borderLeftForeground ?? this.borderLeftForeground,
      borderTopBackground: borderTopBackground ?? this.borderTopBackground,
      borderRightBackground: borderRightBackground ?? this.borderRightBackground,
      borderBottomBackground: borderBottomBackground ?? this.borderBottomBackground,
      borderLeftBackground: borderLeftBackground ?? this.borderLeftBackground,
      borderForegroundBlend: borderForegroundBlend ?? this.borderForegroundBlend,
      borderForegroundBlendOffset:
          borderForegroundBlendOffset ?? this.borderForegroundBlendOffset,
      width: width ?? this.width,
      height: height ?? this.height,
      maxWidth: maxWidth ?? this.maxWidth,
      maxHeight: maxHeight ?? this.maxHeight,
      padding: padding ?? this.padding,
      margin: margin ?? this.margin,
      align: align ?? this.align,
      alignVertical: alignVertical ?? this.alignVertical,
      border: border ?? this.border,
      borderSides: borderSides ?? this.borderSides,
      inline: inline ?? this.inline,
      wrapAnsi: wrapAnsi ?? this.wrapAnsi,
      transform: transform ?? this.transform,
      paddingChar: paddingChar ?? this.paddingChar,
      marginChar: marginChar ?? this.marginChar,
      whitespaceChar: whitespaceChar ?? this.whitespaceChar,
      whitespaceForeground: whitespaceForeground ?? this.whitespaceForeground,
      stringValue: stringValue ?? this.stringValue,
      tabWidth: tabWidth ?? this.tabWidth,
      underlineSpaces: underlineSpaces ?? this.underlineSpaces,
      strikethroughSpaces: strikethroughSpaces ?? this.strikethroughSpaces,
      colorWhitespace: colorWhitespace ?? this.colorWhitespace,
      hyperlinkUrl: hyperlinkUrl ?? this.hyperlinkUrl,
      hyperlinkParams: hyperlinkParams ?? this.hyperlinkParams,
      marginBackground: marginBackground ?? this.marginBackground,
      underlineColor: underlineColor ?? this.underlineColor,
    );
  }

  StyleData merge(StyleData overlay) {
    return copyWith(
      bold: overlay.bold,
      italic: overlay.italic,
      underline: overlay.underline,
      underlineStyle: overlay.underlineStyle,
      strikethrough: overlay.strikethrough,
      dim: overlay.dim,
      inverse: overlay.inverse,
      blink: overlay.blink,
      foreground: overlay.foreground,
      background: overlay.background,
      borderForeground: overlay.borderForeground,
      borderBackground: overlay.borderBackground,
      borderTopForeground: overlay.borderTopForeground,
      borderRightForeground: overlay.borderRightForeground,
      borderBottomForeground: overlay.borderBottomForeground,
      borderLeftForeground: overlay.borderLeftForeground,
      borderTopBackground: overlay.borderTopBackground,
      borderRightBackground: overlay.borderRightBackground,
      borderBottomBackground: overlay.borderBottomBackground,
      borderLeftBackground: overlay.borderLeftBackground,
      borderForegroundBlend: overlay.borderForegroundBlend.isEmpty
          ? borderForegroundBlend
          : overlay.borderForegroundBlend,
      borderForegroundBlendOffset: overlay.borderForegroundBlendOffset,
      width: overlay.width,
      height: overlay.height,
      maxWidth: overlay.maxWidth,
      maxHeight: overlay.maxHeight,
      padding: overlay.padding,
      margin: overlay.margin,
      align: overlay.align,
      alignVertical: overlay.alignVertical,
      border: overlay.border,
      borderSides: overlay.borderSides,
      inline: overlay.inline,
      wrapAnsi: overlay.wrapAnsi,
      transform: overlay.transform,
      paddingChar: overlay.paddingChar,
      marginChar: overlay.marginChar,
      whitespaceChar: overlay.whitespaceChar,
      whitespaceForeground: overlay.whitespaceForeground,
      stringValue: overlay.stringValue,
      tabWidth: overlay.tabWidth,
      underlineSpaces: overlay.underlineSpaces,
      strikethroughSpaces: overlay.strikethroughSpaces,
      colorWhitespace: overlay.colorWhitespace,
      hyperlinkUrl: overlay.hyperlinkUrl,
      hyperlinkParams: overlay.hyperlinkParams,
      marginBackground: overlay.marginBackground,
      underlineColor: overlay.underlineColor,
    );
  }
}
