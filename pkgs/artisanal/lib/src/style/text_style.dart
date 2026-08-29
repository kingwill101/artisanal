/// Immutable, inheritable styling for terminal text.
library;

import 'package:meta/meta.dart';

import 'color.dart';
import 'properties.dart';
import 'style.dart';

/// The terminal-supported intensity of a glyph.
///
/// Terminals expose bold and dim as text intensities rather than arbitrary
/// numeric font weights.
enum FontWeight {
  /// Normal terminal intensity.
  normal,

  /// Bold or increased terminal intensity.
  bold,

  /// Dim or faint terminal intensity.
  dim,
}

/// Whether terminal glyphs use their normal or italic variant.
enum FontStyle {
  /// Upright glyphs.
  normal,

  /// Italic glyphs.
  italic,
}

/// The visual style used for an underline decoration.
enum TextDecorationStyle {
  /// A single solid underline.
  solid,

  /// A double underline.
  double,

  /// A dotted underline.
  dotted,

  /// A dashed underline.
  dashed,

  /// A wavy underline.
  wavy,
}

/// A set of lines painted near terminal text.
///
/// Decorations can be combined with [TextDecoration.combine].
@immutable
final class TextDecoration {
  const TextDecoration._(this._mask);

  static const int _underlineMask = 1 << 0;
  static const int _lineThroughMask = 1 << 1;

  /// No text decoration.
  static const TextDecoration none = TextDecoration._(0);

  /// A line underneath the text.
  static const TextDecoration underline = TextDecoration._(_underlineMask);

  /// A line through the middle of the text.
  static const TextDecoration lineThrough = TextDecoration._(_lineThroughMask);

  final int _mask;

  /// Combines multiple decorations into one declaration.
  factory TextDecoration.combine(List<TextDecoration> decorations) {
    var mask = 0;
    for (final decoration in decorations) {
      mask |= decoration._mask;
    }
    return TextDecoration._(mask);
  }

  /// Whether this declaration contains all lines in [other].
  bool contains(TextDecoration other) => (_mask & other._mask) == other._mask;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TextDecoration && other._mask == _mask;

  @override
  int get hashCode => _mask.hashCode;

  @override
  String toString() {
    if (this == none) return 'TextDecoration.none';
    if (this == underline) return 'TextDecoration.underline';
    if (this == lineThrough) return 'TextDecoration.lineThrough';
    return 'TextDecoration.combine([TextDecoration.underline, '
        'TextDecoration.lineThrough])';
  }
}

/// An immutable set of text-only terminal style declarations.
///
/// [TextStyle] complements [Style]: it is intended for text and span
/// inheritance, while [Style] remains the complete fluent API for text,
/// spacing, borders, sizing, alignment, and rendering.
///
/// Nullable properties are unspecified and therefore inherit. Explicit
/// values such as [FontWeight.normal], [FontStyle.normal], and
/// [TextDecoration.none] reset the corresponding inherited presentation.
///
/// ```dart
/// const heading = TextStyle(
///   color: Colors.purple,
///   fontWeight: FontWeight.bold,
/// );
///
/// final block = heading.applyTo(
///   Style().padding(0, 2).border(Border.rounded),
/// );
/// ```
///
/// {@category Style}
@immutable
final class TextStyle {
  /// Creates an immutable terminal text style.
  const TextStyle({
    this.inherit = true,
    this.color,
    this.backgroundColor,
    this.fontWeight,
    this.fontStyle,
    this.decoration,
    this.decorationColor,
    this.decorationStyle,
    this.reverse,
    this.blink,
  });

  /// Whether unspecified properties inherit from a parent text style.
  final bool inherit;

  /// Foreground text color, or `null` to leave it unspecified.
  final Color? color;

  /// Background text color, or `null` to leave it unspecified.
  final Color? backgroundColor;

  /// Glyph intensity, or `null` to leave it unspecified.
  final FontWeight? fontWeight;

  /// Glyph slant, or `null` to leave it unspecified.
  final FontStyle? fontStyle;

  /// Lines painted near the text, or `null` to leave them unspecified.
  final TextDecoration? decoration;

  /// Underline color, or `null` to leave it unspecified.
  final Color? decorationColor;

  /// Underline variant, or `null` to leave it unspecified.
  final TextDecorationStyle? decorationStyle;

  /// Whether reverse video is enabled, disabled, or inherited when `null`.
  final bool? reverse;

  /// Whether blinking is enabled, disabled, or inherited when `null`.
  final bool? blink;

  /// Returns a copy with the supplied properties replaced.
  ///
  /// As with Flutter's `TextStyle.copyWith`, a `null` argument preserves the
  /// current property. Construct a new style when a declaration must become
  /// unspecified again.
  TextStyle copyWith({
    bool? inherit,
    Color? color,
    Color? backgroundColor,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    bool? reverse,
    bool? blink,
  }) {
    return TextStyle(
      inherit: inherit ?? this.inherit,
      color: color ?? this.color,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      fontWeight: fontWeight ?? this.fontWeight,
      fontStyle: fontStyle ?? this.fontStyle,
      decoration: decoration ?? this.decoration,
      decorationColor: decorationColor ?? this.decorationColor,
      decorationStyle: decorationStyle ?? this.decorationStyle,
      reverse: reverse ?? this.reverse,
      blink: blink ?? this.blink,
    );
  }

  /// Merges [child] over this style and returns the resolved declaration.
  ///
  /// Non-null properties from [child] take precedence. When
  /// [TextStyle.inherit] is `false` on [child], this style is ignored and
  /// [child] is returned unchanged.
  TextStyle merge(TextStyle? child) {
    if (child == null) return this;
    if (!child.inherit) return child;

    return TextStyle(
      inherit: inherit,
      color: child.color ?? color,
      backgroundColor: child.backgroundColor ?? backgroundColor,
      fontWeight: child.fontWeight ?? fontWeight,
      fontStyle: child.fontStyle ?? fontStyle,
      decoration: child.decoration ?? decoration,
      decorationColor: child.decorationColor ?? decorationColor,
      decorationStyle: child.decorationStyle ?? decorationStyle,
      reverse: child.reverse ?? reverse,
      blink: child.blink ?? blink,
    );
  }

  /// Applies these text declarations to [target] and returns it.
  ///
  /// This mutates [target] in the same fluent manner as other [Style]
  /// setters. Layout, border, spacing, and rendering properties already on
  /// [target] are preserved.
  ///
  /// When [inherit] is `false`, inherited text attributes are first reset to
  /// terminal defaults without clearing non-text [Style] properties.
  Style applyTo(Style target) {
    if (!inherit) {
      target
        ..foreground(const DefaultColor())
        ..background(const DefaultColor())
        ..underlineColor(const DefaultColor())
        ..underlineStyle(UnderlineStyle.single)
        ..bold(false)
        ..italic(false)
        ..underline(false)
        ..strikethrough(false)
        ..dim(false)
        ..inverse(false)
        ..blink(false);
    }

    final color = this.color;
    if (color != null) target.foreground(color);

    final backgroundColor = this.backgroundColor;
    if (backgroundColor != null) target.background(backgroundColor);

    switch (fontWeight) {
      case FontWeight.normal:
        target.bold(false).dim(false);
      case FontWeight.bold:
        target.bold().dim(false);
      case FontWeight.dim:
        target.bold(false).dim();
      case null:
        break;
    }

    switch (fontStyle) {
      case FontStyle.normal:
        target.italic(false);
      case FontStyle.italic:
        target.italic();
      case null:
        break;
    }

    final decorationColor = this.decorationColor;
    if (decorationColor != null) target.underlineColor(decorationColor);

    switch (decorationStyle) {
      case TextDecorationStyle.solid:
        target.underlineStyle(UnderlineStyle.single);
      case TextDecorationStyle.double:
        target.underlineStyle(UnderlineStyle.double);
      case TextDecorationStyle.dotted:
        target.underlineStyle(UnderlineStyle.dotted);
      case TextDecorationStyle.dashed:
        target.underlineStyle(UnderlineStyle.dashed);
      case TextDecorationStyle.wavy:
        target.underlineStyle(UnderlineStyle.curly);
      case null:
        break;
    }

    // Apply the decoration set last because Style.underlineStyle() enables an
    // underline. An explicit TextDecoration.none must still win.
    final decoration = this.decoration;
    if (decoration != null) {
      target
        ..underline(decoration.contains(TextDecoration.underline))
        ..strikethrough(decoration.contains(TextDecoration.lineThrough));
    }

    final reverse = this.reverse;
    if (reverse != null) target.inverse(reverse);

    final blink = this.blink;
    if (blink != null) target.blink(blink);

    return target;
  }

  /// Creates a mutable [Style] containing these text declarations.
  Style toStyle() => applyTo(Style());

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextStyle &&
          other.inherit == inherit &&
          other.color == color &&
          other.backgroundColor == backgroundColor &&
          other.fontWeight == fontWeight &&
          other.fontStyle == fontStyle &&
          other.decoration == decoration &&
          other.decorationColor == decorationColor &&
          other.decorationStyle == decorationStyle &&
          other.reverse == reverse &&
          other.blink == blink;

  @override
  int get hashCode => Object.hash(
    inherit,
    color,
    backgroundColor,
    fontWeight,
    fontStyle,
    decoration,
    decorationColor,
    decorationStyle,
    reverse,
    blink,
  );

  @override
  String toString() =>
      'TextStyle('
      'inherit: $inherit, '
      'color: $color, '
      'backgroundColor: $backgroundColor, '
      'fontWeight: $fontWeight, '
      'fontStyle: $fontStyle, '
      'decoration: $decoration, '
      'decorationColor: $decorationColor, '
      'decorationStyle: $decorationStyle, '
      'reverse: $reverse, '
      'blink: $blink)';
}
