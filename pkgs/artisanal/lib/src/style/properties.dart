/// Property types for the fluent style system.
///
/// Provides [Padding], [Margin], and [Align] types for controlling
/// spacing and alignment in styled content.
library;

/// Underline style variants, inspired by lipgloss v2.
///
/// Notes:
/// - Not all terminals support all underline styles.
/// - Unsupported styles may render as a standard underline or be ignored.
enum UnderlineStyle { none, single, double, curly, dotted, dashed }

/// Represents padding (internal spacing) for styled content.
///
/// Padding adds space between the content and its border.
///
/// ```dart
/// // Uniform padding
/// final p1 = Padding.all(2);
///
/// // Vertical and horizontal
/// final p2 = Padding.symmetric(vertical: 1, horizontal: 2);
///
/// // Per-side
/// final p3 = Padding.only(top: 1, left: 2);
/// ```
class Padding {
  /// Creates padding with explicit values for each side.
  const Padding({this.top = 0, this.right = 0, this.bottom = 0, this.left = 0});

  /// Creates uniform padding on all sides.
  const Padding.all(int value)
    : top = value,
      right = value,
      bottom = value,
      left = value;

  /// Creates symmetric padding.
  ///
  /// [vertical] applies to top and bottom.
  /// [horizontal] applies to left and right.
  const Padding.symmetric({int vertical = 0, int horizontal = 0})
    : top = vertical,
      bottom = vertical,
      left = horizontal,
      right = horizontal;

  /// Creates padding with only the specified sides.
  const Padding.only({
    this.top = 0,
    this.right = 0,
    this.bottom = 0,
    this.left = 0,
  });

  /// No padding.
  static const zero = Padding();

  /// Padding on the top side.
  final int top;

  /// Padding on the right side.
  final int right;

  /// Padding on the bottom side.
  final int bottom;

  /// Padding on the left side.
  final int left;

  /// Total horizontal padding (left + right).
  int get horizontal => left + right;

  /// Total vertical padding (top + bottom).
  int get vertical => top + bottom;

  /// Whether all padding values are zero.
  bool get isZero => top == 0 && right == 0 && bottom == 0 && left == 0;

  /// Creates a copy with the specified values replaced.
  Padding copyWith({int? top, int? right, int? bottom, int? left}) {
    return Padding(
      top: top ?? this.top,
      right: right ?? this.right,
      bottom: bottom ?? this.bottom,
      left: left ?? this.left,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Padding &&
        other.top == top &&
        other.right == right &&
        other.bottom == bottom &&
        other.left == left;
  }

  @override
  int get hashCode => Object.hash(top, right, bottom, left);

  @override
  String toString() =>
      'Padding(top: $top, right: $right, bottom: $bottom, left: $left)';
}

/// Represents margin (external spacing) for styled content.
///
/// Margin adds space outside the border of the content.
///
/// ```dart
/// // Uniform margin
/// final m1 = Margin.all(2);
///
/// // Vertical and horizontal
/// final m2 = Margin.symmetric(vertical: 1, horizontal: 2);
///
/// // Per-side
/// final m3 = Margin.only(top: 1, left: 2);
/// ```
class Margin {
  /// Creates margin with explicit values for each side.
  const Margin({this.top = 0, this.right = 0, this.bottom = 0, this.left = 0});

  /// Creates uniform margin on all sides.
  const Margin.all(int value)
    : top = value,
      right = value,
      bottom = value,
      left = value;

  /// Creates symmetric margin.
  ///
  /// [vertical] applies to top and bottom.
  /// [horizontal] applies to left and right.
  const Margin.symmetric({int vertical = 0, int horizontal = 0})
    : top = vertical,
      bottom = vertical,
      left = horizontal,
      right = horizontal;

  /// Creates margin with only the specified sides.
  const Margin.only({
    this.top = 0,
    this.right = 0,
    this.bottom = 0,
    this.left = 0,
  });

  /// No margin.
  static const zero = Margin();

  /// Margin on the top side.
  final int top;

  /// Margin on the right side.
  final int right;

  /// Margin on the bottom side.
  final int bottom;

  /// Margin on the left side.
  final int left;

  /// Total horizontal margin (left + right).
  int get horizontal => left + right;

  /// Total vertical margin (top + bottom).
  int get vertical => top + bottom;

  /// Whether all margin values are zero.
  bool get isZero => top == 0 && right == 0 && bottom == 0 && left == 0;

  /// Creates a copy with the specified values replaced.
  Margin copyWith({int? top, int? right, int? bottom, int? left}) {
    return Margin(
      top: top ?? this.top,
      right: right ?? this.right,
      bottom: bottom ?? this.bottom,
      left: left ?? this.left,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Margin &&
        other.top == top &&
        other.right == right &&
        other.bottom == bottom &&
        other.left == left;
  }

  @override
  int get hashCode => Object.hash(top, right, bottom, left);

  @override
  String toString() =>
      'Margin(top: $top, right: $right, bottom: $bottom, left: $left)';
}

/// Horizontal alignment options.
enum HorizontalAlign {
  /// Align content to the left.
  left,

  /// Align content to the center.
  center,

  /// Align content to the right.
  right,
}

/// Vertical alignment options.
enum VerticalAlign {
  /// Align content to the top.
  top,

  /// Align content to the center.
  center,

  /// Align content to the bottom.
  bottom,
}

/// Combined alignment for both horizontal and vertical positioning.
///
/// This class provides a unified way to specify both horizontal and
/// vertical alignment, similar to lipgloss's Position type.
///
/// ```dart
/// final align = Align(HorizontalAlign.center, VerticalAlign.top);
///
/// // Or use presets
/// final centered = Align.center;
/// final topLeft = Align.topLeft;
/// ```
class Align {
  /// Creates an alignment with the specified horizontal and vertical values.
  const Align(this.horizontal, this.vertical);

  /// Horizontal alignment.
  final HorizontalAlign horizontal;

  /// Vertical alignment.
  final VerticalAlign vertical;

  // ───────────────────────────────────────────────────────────────────────────
  // Preset alignments
  // ───────────────────────────────────────────────────────────────────────────

  /// Top-left alignment.
  static const topLeft = Align(HorizontalAlign.left, VerticalAlign.top);

  /// Top-center alignment.
  static const topCenter = Align(HorizontalAlign.center, VerticalAlign.top);

  /// Top-right alignment.
  static const topRight = Align(HorizontalAlign.right, VerticalAlign.top);

  /// Center-left alignment.
  static const centerLeft = Align(HorizontalAlign.left, VerticalAlign.center);

  /// Center alignment (both horizontal and vertical).
  static const center = Align(HorizontalAlign.center, VerticalAlign.center);

  /// Center-right alignment.
  static const centerRight = Align(HorizontalAlign.right, VerticalAlign.center);

  /// Bottom-left alignment.
  static const bottomLeft = Align(HorizontalAlign.left, VerticalAlign.bottom);

  /// Bottom-center alignment.
  static const bottomCenter = Align(
    HorizontalAlign.center,
    VerticalAlign.bottom,
  );

  /// Bottom-right alignment.
  static const bottomRight = Align(HorizontalAlign.right, VerticalAlign.bottom);

  // ───────────────────────────────────────────────────────────────────────────
  // Convenience aliases
  // ───────────────────────────────────────────────────────────────────────────

  /// Alias for [topLeft].
  static const left = topLeft;

  /// Alias for [topRight].
  static const right = topRight;

  /// Alias for [topCenter].
  static const top = topCenter;

  /// Alias for [bottomCenter].
  static const bottom = bottomCenter;

  /// Creates a copy with the specified values replaced.
  Align copyWith({HorizontalAlign? horizontal, VerticalAlign? vertical}) {
    return Align(horizontal ?? this.horizontal, vertical ?? this.vertical);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Align &&
        other.horizontal == horizontal &&
        other.vertical == vertical;
  }

  @override
  int get hashCode => Object.hash(horizontal, vertical);

  @override
  String toString() => 'Align($horizontal, $vertical)';
}

/// Extension to convert [HorizontalAlign] to a fractional position.
extension HorizontalAlignPosition on HorizontalAlign {
  /// Returns the fractional position (0.0 = left, 0.5 = center, 1.0 = right).
  double get position => switch (this) {
    HorizontalAlign.left => 0.0,
    HorizontalAlign.center => 0.5,
    HorizontalAlign.right => 1.0,
  };
}

/// Extension to convert [VerticalAlign] to a fractional position.
extension VerticalAlignPosition on VerticalAlign {
  /// Returns the fractional position (0.0 = top, 0.5 = center, 1.0 = bottom).
  double get position => switch (this) {
    VerticalAlign.top => 0.0,
    VerticalAlign.center => 0.5,
    VerticalAlign.bottom => 1.0,
  };
}
