/// Fluent styling system for terminal text (Lip Gloss for Dart).
///
/// This library provides a powerful, declarative styling system for terminal
/// applications. It allows you to define styles for text, borders, padding,
/// margins, and alignment using a fluent API.
///
/// {@category Style}
///
/// ## Key Concepts
///
/// - **[Style]**: The primary entry point for defining text formatting.
/// - **[Color]**: Support for ANSI 16, ANSI 256, and TrueColor (RGB).
/// - **[Layout]**: Utilities for joining styled blocks horizontally or vertically.
/// - **[Border]**: Predefined and custom border styles for boxes.
/// - **[List]**: Support for styled bulleted or numbered lists.
/// - **[Table]**: Support for rendering data in styled grids.
///
/// ## Usage
///
/// ```dart
/// import 'package:artisanal/style.dart';
///
/// final style = Style()
///   .bold()
///   .foreground(Colors.purple)
///   .padding(1, 2)
///   .border(Border.rounded);
///
/// print(style.render('Hello, Artisanal!'));
/// ```
///
/// ## Fluent Styling
///
/// {@macro artisanal_style_overview}
///
/// ## Colors and Profiles
///
/// {@macro artisanal_style_colors}
///
/// ## Layout and Composition
///
/// {@macro artisanal_style_layout}
///
/// {@template artisanal_style_overview}
/// Artisanal Style uses a fluent, immutable API inspired by Lip Gloss. Each
/// method call returns a new [Style] instance with the property applied,
/// allowing for easy composition and reuse.
///
/// Styles can include:
/// - Text effects (bold, italic, underline, strikethrough)
/// - Colors (foreground, background, underline color)
/// - Spacing (padding, margin)
/// - Borders (rounded, thick, double, etc.)
/// - Alignment (horizontal and vertical)
/// {@endtemplate}
///
/// {@template artisanal_style_colors}
/// Colors in Artisanal are profile-aware. The [ColorProfile] determines how
/// colors are rendered (ANSI 16, ANSI 256, or TrueColor).
///
/// - [BasicColor]: Standard 16 ANSI colors.
/// - [AnsiColor]: 256-color palette.
/// - [CompleteColor]: Full 24-bit RGB colors.
/// - [AdaptiveColor]: Automatically chooses between light/dark variants.
/// {@endtemplate}
///
/// {@template artisanal_style_layout}
/// Use the [Layout] class to join multiple styled blocks together:
/// - `Layout.joinHorizontal`: Place blocks side-by-side.
/// - `Layout.joinVertical`: Stack blocks on top of each other.
///
/// You can also use [Style.width] and [Style.height] to create fixed-size
/// boxes with alignment.
/// {@endtemplate}
library;

export 'src/style/style.dart';
export 'src/layout/layout.dart' show Layout;
export 'src/style/properties.dart'
    show
        UnderlineStyle,
        VerticalAlign,
        HorizontalAlign,
        Padding,
        Margin,
        Align,
        HorizontalAlignPosition,
        VerticalAlignPosition;
export 'src/style/color.dart'
    show
        Color,
        AnsiColor,
        BasicColor,
        AdaptiveColor,
        CompleteColor,
        CompleteAdaptiveColor,
        NoColor,
        Colors,
        ColorProfile;
export 'src/style/border.dart' show Border, BorderSides;
export 'src/style/list.dart'
    show
        LipList,
        ListEnumerators,
        ListIndenters,
        ListItem,
        ListItems,
        ListStyleFunc,
        ListEnumeratorFunc,
        ListIndenterFunc;
export 'src/layout/layout.dart' show Layout, WhitespaceOptions;
export 'src/style/ranges.dart' show StyleRange, styleRanges, Ranges;
export 'src/style/blending.dart' show blend1D, blend2D;
export 'src/style/writer.dart'
    show
        Writer,
        resetWriter,
        Print,
        PrintAll,
        Println,
        PrintlnAll,
        Printf,
        Sprint,
        SprintAll,
        Sprintln,
        SprintlnAll,
        Sprintf,
        SprintfAll,
        Fprint,
        Fprintln,
        Fprintf,
        stringForProfile;
export 'src/style/theme.dart' show ThemePalette;
