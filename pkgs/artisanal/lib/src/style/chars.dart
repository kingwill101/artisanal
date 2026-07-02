/// Predefined Unicode character sets for terminal display.
///
/// Provides organized access to block elements, geometric shapes, box drawing
/// characters, and other Unicode glyphs used throughout artisanal and
/// artisanal_widgets.
library;

export '../tui/bubbles/components/panel_chars.dart';

/// Block shade characters (U+2580–U+259F).
class BlockShades {
  BlockShades._();

  /// Full block █ (U+2588).
  static const full = '█';

  /// Dark shade ▓ (U+2593).
  static const dark = '▓';

  /// Medium shade ▒ (U+2592).
  static const medium = '▒';

  /// Light shade ░ (U+2591).
  static const light = '░';

  /// Upper half block ▀ (U+2580).
  static const upper = '▀';

  /// Lower half block ▄ (U+2584).
  static const lower = '▄';

  /// Left half block ▌ (U+258C).
  static const left = '▌';

  /// Right half block ▐ (U+2590).
  static const right = '▐';
}

/// Medium-weight block elements (U+25B0–U+25B1).
class BlockMedium {
  BlockMedium._();

  /// Medium solid block ▰ (U+25B0).
  static const solid = '▰';

  /// Medium empty block ▱ (U+25B1).
  static const empty = '▱';
}

/// Sparse block shapes (U+25A0–U+25AB).
class SparseBlocks {
  SparseBlocks._();

  /// Solid square ■ (U+25A0).
  static const solid = '■';

  /// Empty square □ (U+25A1).
  static const empty = '□';

  /// Small solid square ▪ (U+25AA).
  static const smallSolid = '▪';

  /// Small empty square ▫ (U+25AB).
  static const smallEmpty = '▫';
}

/// Quadrant block glyphs for sub-pixel rendering (U+2596–U+259F).
class BlockQuadrants {
  BlockQuadrants._();

  /// Upper-left quadrant ▘.
  static const upperLeft = '▘';

  /// Upper-right quadrant ▝.
  static const upperRight = '▝';

  /// Lower-left quadrant ▖.
  static const lowerLeft = '▖';

  /// Lower-right quadrant ▗.
  static const lowerRight = '▗';

  /// Left halves ▚ — upper-left + lower-right.
  static const leftHalves = '▚';

  /// Right halves ▞ — upper-right + lower-left.
  static const rightHalves = '▞';

  /// All but lower-right ▛.
  static const allButLowerRight = '▛';

  /// All but lower-left ▜.
  static const allButLowerLeft = '▜';

  /// All but upper-right ▙.
  static const allButUpperRight = '▙';

  /// All but upper-left ▟.
  static const allButUpperLeft = '▟';
}

/// Circle glyphs (U+25CB–U+25D5).
class Circles {
  Circles._();

  /// Filled circle ● (U+25CF).
  static const filled = '●';

  /// Empty circle ○ (U+25CB).
  static const empty = '○';

  /// 25% fill ◔ (U+25D4) — upper-right quadrant.
  static const fill25 = '◔';

  /// 50% fill ◑ (U+25D1) — lower half.
  static const fill50 = '◑';

  /// 75% fill ◕ (U+25D5) — all but upper-left.
  static const fill75 = '◕';
}

/// Arc segment and circle-segment characters for spinning animations
/// (U+25D8–U+25E1).
class ArcSegments {
  ArcSegments._();

  /// Upper-left quadrant arc ◜.
  static const upperLeftArc = '◜';

  /// Upper half circle ◠.
  static const upperHalf = '◠';

  /// Upper-right quadrant arc ◝.
  static const upperRightArc = '◝';

  /// Lower-right quadrant arc ◞.
  static const lowerRightArc = '◞';

  /// Lower half circle ◡.
  static const lowerHalf = '◡';

  /// Lower-left quadrant arc ◟.
  static const lowerLeftArc = '◟';

  /// Left half circle ◐.
  static const leftHalf = '◐';

  /// Right half circle ◓.
  static const rightHalf = '◓';

  /// Upper half circle ◒.
  static const upperHalfCircle = '◒';

  /// Lower half circle ◑.
  static const lowerHalfCircle = '◑';
}

/// Triangular indicator glyphs (U+25B2–U+25C0).
class Triangles {
  Triangles._();

  /// Up-pointing triangle ▲ (U+25B2).
  static const up = '▲';

  /// Down-pointing triangle ▼ (U+25BC).
  static const down = '▼';

  /// Right-pointing triangle ▶ (U+25B6).
  static const right = '▶';

  /// Left-pointing triangle ◀ (U+25C0).
  static const left = '◀';
}

/// Common arrow glyphs used in key help and navigation labels.
class Arrows {
  Arrows._();

  /// Up arrow ↑.
  static const up = '↑';

  /// Down arrow ↓.
  static const down = '↓';

  /// Left arrow ←.
  static const left = '←';

  /// Right arrow →.
  static const right = '→';
}

/// Common keyboard glyphs used in key help labels.
class KeyboardChars {
  KeyboardChars._();

  /// Return/enter key ↵.
  static const enter = '↵';

  /// Backspace key ⌫.
  static const backspace = '⌫';
}

/// Sparkline bar characters (U+2581–U+2588).
class SparkBars {
  SparkBars._();

  /// Eight levels of spark bar fill, from empty to full.
  static const List<String> levels = [
    ' ',
    '▁',
    '▂',
    '▃',
    '▄',
    '▅',
    '▆',
    '▇',
    '█',
  ];
}

/// Braille pattern characters for progress indicators.
class BrailleChars {
  BrailleChars._();

  /// Full braille pattern ⣿ (U+28FF).
  static const full = '⣿';

  /// Pattern with only top row ⣀ (U+2880).
  static const topRow = '⣀';
}

/// Status indicator symbols.
class StatusChars {
  StatusChars._();

  /// Check mark ✓ (U+2713).
  static const check = '✓';

  /// Ballot X ✗ (U+2717).
  static const cross = '✗';

  /// Multiplication X ✕ (U+2715).
  static const x = '✕';

  /// Circled division slash ⊘ (U+2298) — skipped step.
  static const skipped = '⊘';
}

/// Dot and marker characters.
class DotChars {
  DotChars._();

  /// Middle dot · (U+00B7).
  static const middle = '·';

  /// Bullet • (U+2022).
  static const bullet = '•';

  /// Small black square ⬝ (U+2B1D).
  static const small = '⬝';
}

/// Miscellaneous singleton punctuation glyphs.
class EllipsisChars {
  EllipsisChars._();

  /// Horizontal ellipsis ….
  static const horizontal = '…';
}

/// Character pair for a scanner (Knight Rider) animation style.
///
/// Use with [Spinners.scanner] or [ScannerChars] presets.
class ScannerCharSet {
  /// Creates a scanner character set.
  const ScannerCharSet({required this.active, this.inactive = '⬝'});

  /// Characters used for active (head/trail) positions.
  ///
  /// When multiple characters are provided they are mapped across the
  /// trail gradient — the first is the brightest head position and
  /// subsequent entries serve as the trailing gradient shapes.
  final List<String> active;

  /// Character used for inactive (background) positions.
  final String inactive;
}

/// Predefined scanner animation character sets.
class ScannerChars {
  ScannerChars._();

  /// Blocks style: solid block for active, small dot for inactive.
  ///
  /// Matches the `createFrames({style: "blocks"})` output in opencode.
  static const blocks = ScannerCharSet(
    active: [SparseBlocks.solid],
    inactive: '⬝',
  );

  /// Diamonds style: diamond shapes for active, middle dot for inactive.
  ///
  /// Matches the `createFrames({style: "diamonds"})` output in opencode.
  static const diamonds = ScannerCharSet(
    active: ['⬥', '◆', '⬩', '⬪'],
    inactive: DotChars.middle,
  );
}

/// Pagination dot characters.
class PaginationDots {
  PaginationDots._();

  /// Active/current page dot ●.
  static const active = '●';

  /// Inactive page dot ○.
  static const inactive = '○';
}
