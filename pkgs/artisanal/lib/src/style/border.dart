/// Border definitions for the fluent style system.
///
/// Provides a data-driven approach to border styling, with presets
/// for common border styles.
///
/// ```dart
/// // Use a preset
/// Style().border(Border.rounded)
///
/// // Create custom border
/// Style().border(Border(
///   top: '═',
///   bottom: '═',
///   left: '║',
///   right: '║',
///   topLeft: '╔',
///   topRight: '╗',
///   bottomLeft: '╚',
///   bottomRight: '╝',
/// ))
/// ```
library;

import '../unicode/grapheme.dart' as uni;

/// Defines the characters used to draw borders.
///
/// A border consists of:
/// - Edge characters (top, bottom, left, right)
/// - Corner characters (topLeft, topRight, bottomLeft, bottomRight)
/// - Optional middle connectors for tables (middleLeft, middleRight, etc.)
class Border {
  /// Creates a border with the specified characters.
  const Border({
    required this.top,
    required this.bottom,
    required this.left,
    required this.right,
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
    this.middleLeft,
    this.middleRight,
    this.middleTop,
    this.middleBottom,
    this.middle,
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // Edge Characters
  // ─────────────────────────────────────────────────────────────────────────────

  /// Character for the top edge.
  final String top;

  /// Character for the bottom edge.
  final String bottom;

  /// Character for the left edge.
  final String left;

  /// Character for the right edge.
  final String right;

  // ─────────────────────────────────────────────────────────────────────────────
  // Corner Characters
  // ─────────────────────────────────────────────────────────────────────────────

  /// Character for the top-left corner.
  final String topLeft;

  /// Character for the top-right corner.
  final String topRight;

  /// Character for the bottom-left corner.
  final String bottomLeft;

  /// Character for the bottom-right corner.
  final String bottomRight;

  // ─────────────────────────────────────────────────────────────────────────────
  // Middle Connectors (for tables)
  // ─────────────────────────────────────────────────────────────────────────────

  /// Character for middle-left connector (├).
  final String? middleLeft;

  /// Character for middle-right connector (┤).
  final String? middleRight;

  /// Character for middle-top connector (┬).
  final String? middleTop;

  /// Character for middle-bottom connector (┴).
  final String? middleBottom;

  /// Character for middle cross connector (┼).
  final String? middle;

  // ─────────────────────────────────────────────────────────────────────────────
  // Preset Borders
  // ─────────────────────────────────────────────────────────────────────────────

  /// Normal/single-line border (┌─┐│└─┘).
  static const normal = Border(
    top: '─',
    bottom: '─',
    left: '│',
    right: '│',
    topLeft: '┌',
    topRight: '┐',
    bottomLeft: '└',
    bottomRight: '┘',
    middleLeft: '├',
    middleRight: '┤',
    middleTop: '┬',
    middleBottom: '┴',
    middle: '┼',
  );

  /// Rounded border with curved corners (╭─╮│╰─╯).
  static const rounded = Border(
    top: '─',
    bottom: '─',
    left: '│',
    right: '│',
    topLeft: '╭',
    topRight: '╮',
    bottomLeft: '╰',
    bottomRight: '╯',
    middleLeft: '├',
    middleRight: '┤',
    middleTop: '┬',
    middleBottom: '┴',
    middle: '┼',
  );

  /// Thick/heavy border (┏━┓┃┗━┛).
  static const thick = Border(
    top: '━',
    bottom: '━',
    left: '┃',
    right: '┃',
    topLeft: '┏',
    topRight: '┓',
    bottomLeft: '┗',
    bottomRight: '┛',
    middleLeft: '┣',
    middleRight: '┫',
    middleTop: '┳',
    middleBottom: '┻',
    middle: '╋',
  );

  /// Double-line border (╔═╗║╚═╝).
  static const double = Border(
    top: '═',
    bottom: '═',
    left: '║',
    right: '║',
    topLeft: '╔',
    topRight: '╗',
    bottomLeft: '╚',
    bottomRight: '╝',
    middleLeft: '╠',
    middleRight: '╣',
    middleTop: '╦',
    middleBottom: '╩',
    middle: '╬',
  );

  /// Block border using full block characters (█).
  static const block = Border(
    top: '█',
    bottom: '█',
    left: '█',
    right: '█',
    topLeft: '█',
    topRight: '█',
    bottomLeft: '█',
    bottomRight: '█',
    middleLeft: '█',
    middleRight: '█',
    middleTop: '█',
    middleBottom: '█',
    middle: '█',
  );

  /// Outer half-block border (▛▀▜▌▐▙▄▟).
  static const outerHalfBlock = Border(
    top: '▀',
    bottom: '▄',
    left: '▌',
    right: '▐',
    topLeft: '▛',
    topRight: '▜',
    bottomLeft: '▙',
    bottomRight: '▟',
  );

  /// Inner half-block border (▗▄▖▐▌▝▀▘).
  static const innerHalfBlock = Border(
    top: '▄',
    bottom: '▀',
    left: '▐',
    right: '▌',
    topLeft: '▗',
    topRight: '▖',
    bottomLeft: '▝',
    bottomRight: '▘',
  );

  /// Hidden border using spaces (preserves layout without visible border).
  static const hidden = Border(
    top: ' ',
    bottom: ' ',
    left: ' ',
    right: ' ',
    topLeft: ' ',
    topRight: ' ',
    bottomLeft: ' ',
    bottomRight: ' ',
    middleLeft: ' ',
    middleRight: ' ',
    middleTop: ' ',
    middleBottom: ' ',
    middle: ' ',
  );

  /// ASCII border for maximum compatibility (+--+||+--+).
  static const ascii = Border(
    top: '-',
    bottom: '-',
    left: '|',
    right: '|',
    topLeft: '+',
    topRight: '+',
    bottomLeft: '+',
    bottomRight: '+',
    middleLeft: '+',
    middleRight: '+',
    middleTop: '+',
    middleBottom: '+',
    middle: '+',
  );

  /// Markdown-style border for tables.
  static const markdown = Border(
    top: '-',
    bottom: '-',
    left: '|',
    right: '|',
    topLeft: '|',
    topRight: '|',
    bottomLeft: '|',
    bottomRight: '|',
    middleLeft: '|',
    middleRight: '|',
    middleTop: '|',
    middleBottom: '|',
    middle: '|',
  );

  /// No border (empty strings).
  static const none = Border(
    top: '',
    bottom: '',
    left: '',
    right: '',
    topLeft: '',
    topRight: '',
    bottomLeft: '',
    bottomRight: '',
  );

  // ─────────────────────────────────────────────────────────────────────────────
  // Helper Methods
  // ─────────────────────────────────────────────────────────────────────────────

  /// Whether this border has any visible characters.
  bool get isVisible =>
      top.isNotEmpty ||
      bottom.isNotEmpty ||
      left.isNotEmpty ||
      right.isNotEmpty;

  /// Whether this border has middle connectors defined.
  bool get hasMiddleConnectors =>
      middleLeft != null ||
      middleRight != null ||
      middleTop != null ||
      middleBottom != null ||
      middle != null;

  /// Returns the width of the top border.
  ///
  /// If borders contain runes of varying widths, the widest rune is returned.
  /// If no border exists on the top edge, 0 is returned.
  int getTopSize() {
    return _getBorderEdgeWidth([topLeft, top, topRight]);
  }

  /// Returns the width of the right border.
  ///
  /// If borders contain runes of varying widths, the widest rune is returned.
  /// If no border exists on the right edge, 0 is returned.
  int getRightSize() {
    return _getBorderEdgeWidth([topRight, right, bottomRight]);
  }

  /// Returns the width of the bottom border.
  ///
  /// If borders contain runes of varying widths, the widest rune is returned.
  /// If no border exists on the bottom edge, 0 is returned.
  int getBottomSize() {
    return _getBorderEdgeWidth([bottomLeft, bottom, bottomRight]);
  }

  /// Returns the width of the left border.
  ///
  /// If borders contain runes of varying widths, the widest rune is returned.
  /// If no border exists on the left edge, 0 is returned.
  int getLeftSize() {
    return _getBorderEdgeWidth([topLeft, left, bottomLeft]);
  }

  /// Helper to get the maximum rune width among border parts.
  static int _getBorderEdgeWidth(List<String> borderParts) {
    var maxWidth = 0;
    for (final piece in borderParts) {
      final w = _maxRuneWidth(piece);
      if (w > maxWidth) {
        maxWidth = w;
      }
    }
    return maxWidth;
  }

  /// Returns the maximum display width of any rune in a string.
  static int _maxRuneWidth(String s) {
    if (s.isEmpty) return 0;
    var maxWidth = 0;
    for (final g in uni.graphemes(s)) {
      final w = _runeWidth(uni.firstCodePoint(g));
      if (w > maxWidth) {
        maxWidth = w;
      }
    }
    return maxWidth;
  }

  /// Returns the display width of a single rune.
  static int _runeWidth(int rune) {
    // Full-width characters (CJK, emoji, etc.)
    if ((rune >= 0x1100 && rune <= 0x115F) || // Hangul Jamo
        (rune >= 0x2E80 && rune <= 0x9FFF) || // CJK
        (rune >= 0xAC00 && rune <= 0xD7A3) || // Hangul Syllables
        (rune >= 0xF900 && rune <= 0xFAFF) || // CJK Compatibility
        (rune >= 0xFE10 && rune <= 0xFE1F) || // Vertical Forms
        (rune >= 0xFE30 && rune <= 0xFE6F) || // CJK Compatibility Forms
        (rune >= 0xFF00 && rune <= 0xFF60) || // Fullwidth ASCII
        (rune >= 0xFFE0 && rune <= 0xFFE6) || // Fullwidth symbols
        (rune >= 0x20000 && rune <= 0x3FFFF) || // CJK Extensions
        (rune >= 0x1F300 && rune <= 0x1F9FF)) {
      // Emoji
      return 2;
    }
    return 1;
  }

  /// Creates a copy with the specified values replaced.
  Border copyWith({
    String? top,
    String? bottom,
    String? left,
    String? right,
    String? topLeft,
    String? topRight,
    String? bottomLeft,
    String? bottomRight,
    String? middleLeft,
    String? middleRight,
    String? middleTop,
    String? middleBottom,
    String? middle,
  }) {
    return Border(
      top: top ?? this.top,
      bottom: bottom ?? this.bottom,
      left: left ?? this.left,
      right: right ?? this.right,
      topLeft: topLeft ?? this.topLeft,
      topRight: topRight ?? this.topRight,
      bottomLeft: bottomLeft ?? this.bottomLeft,
      bottomRight: bottomRight ?? this.bottomRight,
      middleLeft: middleLeft ?? this.middleLeft,
      middleRight: middleRight ?? this.middleRight,
      middleTop: middleTop ?? this.middleTop,
      middleBottom: middleBottom ?? this.middleBottom,
      middle: middle ?? this.middle,
    );
  }

  /// Builds the top border line for a given width.
  String buildTop(int innerWidth) {
    if (!isVisible) return '';
    return '$topLeft${top * innerWidth}$topRight';
  }

  /// Builds the bottom border line for a given width.
  String buildBottom(int innerWidth) {
    if (!isVisible) return '';
    return '$bottomLeft${bottom * innerWidth}$bottomRight';
  }

  /// Builds a horizontal separator line (for table rows).
  String buildSeparator(int innerWidth) {
    if (!isVisible) return '';
    final ml = middleLeft ?? topLeft;
    final mr = middleRight ?? topRight;
    return '$ml${top * innerWidth}$mr';
  }

  /// Wraps a single line of content with left and right borders.
  String wrapLine(String content) {
    if (!isVisible) return content;
    return '$left$content$right';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Border &&
        other.top == top &&
        other.bottom == bottom &&
        other.left == left &&
        other.right == right &&
        other.topLeft == topLeft &&
        other.topRight == topRight &&
        other.bottomLeft == bottomLeft &&
        other.bottomRight == bottomRight &&
        other.middleLeft == middleLeft &&
        other.middleRight == middleRight &&
        other.middleTop == middleTop &&
        other.middleBottom == middleBottom &&
        other.middle == middle;
  }

  @override
  int get hashCode => Object.hash(
    top,
    bottom,
    left,
    right,
    topLeft,
    topRight,
    bottomLeft,
    bottomRight,
    middleLeft,
    middleRight,
    middleTop,
    middleBottom,
    middle,
  );

  @override
  String toString() => 'Border(${_presetName ?? "custom"})';

  String? get _presetName {
    if (this == normal) return 'normal';
    if (this == rounded) return 'rounded';
    if (this == thick) return 'thick';
    if (this == double) return 'double';
    if (this == block) return 'block';
    if (this == hidden) return 'hidden';
    if (this == ascii) return 'ascii';
    if (this == markdown) return 'markdown';
    if (this == none) return 'none';
    return null;
  }
}

/// Controls which sides of a border are visible.
///
/// Used in conjunction with [Border] to selectively show/hide sides.
///
/// ```dart
/// Style()
///     .border(Border.rounded)
///     .borderSides(BorderSides(top: true, bottom: true))
/// ```
class BorderSides {
  /// Creates border side visibility settings.
  const BorderSides({
    this.top = true,
    this.bottom = true,
    this.left = true,
    this.right = true,
  });

  /// Show all sides.
  static const all = BorderSides();

  /// Show no sides (same as no border).
  static const none = BorderSides(
    top: false,
    bottom: false,
    left: false,
    right: false,
  );

  /// Show only horizontal sides (top and bottom).
  static const horizontal = BorderSides(left: false, right: false);

  /// Show only vertical sides (left and right).
  static const vertical = BorderSides(top: false, bottom: false);

  /// Show only top side.
  static const topOnly = BorderSides(bottom: false, left: false, right: false);

  /// Show only bottom side.
  static const bottomOnly = BorderSides(top: false, left: false, right: false);

  /// Whether the top border is visible.
  final bool top;

  /// Whether the bottom border is visible.
  final bool bottom;

  /// Whether the left border is visible.
  final bool left;

  /// Whether the right border is visible.
  final bool right;

  /// Whether any side is visible.
  bool get hasAny => top || bottom || left || right;

  /// Creates a copy with the specified values replaced.
  BorderSides copyWith({bool? top, bool? bottom, bool? left, bool? right}) {
    return BorderSides(
      top: top ?? this.top,
      bottom: bottom ?? this.bottom,
      left: left ?? this.left,
      right: right ?? this.right,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BorderSides &&
        other.top == top &&
        other.bottom == bottom &&
        other.left == left &&
        other.right == right;
  }

  @override
  int get hashCode => Object.hash(top, bottom, left, right);

  @override
  String toString() =>
      'BorderSides(top: $top, bottom: $bottom, left: $left, right: $right)';
}
