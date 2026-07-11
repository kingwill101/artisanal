import '../../glamour/theme.dart';
import '../../style/style.dart';
import 'options.dart';

/// Bridge between [GlamourTheme] and [AnsiRendererOptions].
///
/// Converts a Glamour theme into the ANSI renderer options so that
/// Glamour-themed markdown can be rendered through the unified
/// [AnsiRenderer] pipeline instead of the separate [GlamourRenderer].
///
/// This is the first step toward eliminating the separate Glamour
/// rendering path and having a single, themeable markdown renderer.
extension GlamourThemeToOptions on GlamourTheme {
  /// Converts this Glamour theme to [AnsiRendererOptions].
  ///
  /// Glamour's [GlamourPrimitiveStyle] includes both [Style] properties
  /// (bold, italic, color, etc.) and structural properties
  /// (prefix, suffix, blockPrefix, blockSuffix, margin, indent, format).
  /// The structural properties are mapped to [MarkdownElementStyle]
  /// while the style properties are mapped to [Style].
  AnsiRendererOptions toAnsiRendererOptions({int? width, bool renderImages = false}) {
    return AnsiRendererOptions(
      width: width,
      renderImages: renderImages,
      h1Style: _toStyle(h1),
      h2Style: _toStyle(h2),
      h3Style: _toStyle(h3),
      h4Style: _toStyle(h4),
      h5Style: _toStyle(h5),
      h6Style: _toStyle(heading),
      emphasisStyle: _toStyleFromPrimitive(emph),
      strongStyle: _toStyleFromPrimitive(strong),
      codeStyle: _toStyle(code),
      codeBlockStyle: _toStyle(codeBlock.style),
      linkStyle: _toStyleFromPrimitive(link),
      blockquoteStyle: _toStyle(blockQuote),
      blockquoteBorderColor: blockQuote.style.color,
      strikethroughStyle: _toStyleFromPrimitive(strikethrough),
      bulletChar: item.blockPrefix?.replaceAll(' ', '') ?? '\u2022',
      checkboxChecked: task.ticked,
      checkboxUnchecked: task.unticked,
      listIndent: list.levelIndent ?? 2,
      syntaxTheme: codeBlock.chroma,
      tableHeaderStyle: _toStyleFromPrimitive(strong),
    );
  }

  Style? _toStyle(GlamourBlockStyle blockStyle) {
    if (blockStyle.style.color == null &&
        blockStyle.style.backgroundColor == null &&
        blockStyle.style.bold != true &&
        blockStyle.style.italic != true &&
        blockStyle.style.underline != true) {
      return null;
    }
    return blockStyle.style.toStyle;
  }

  Style? _toStyleFromPrimitive(GlamourPrimitiveStyle primitive) {
    if (primitive.color == null &&
        primitive.backgroundColor == null &&
        primitive.bold != true &&
        primitive.italic != true &&
        primitive.underline != true) {
      return null;
    }
    return primitive.toStyle;
  }
}
