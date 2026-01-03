/// Screen: a 2D surface of [Cell]s bounded by a [Rectangle].
///
/// The [Screen] interface unifies cell I/O, region operations, and width
/// measurement, forming the foundation for composition via [Canvas] and
/// diff-based rendering through [UvTerminalRenderer]. Optional fast-path
/// interfaces enable clear/fill/clone operations for performance.
///
/// {@category Ultraviolet}
/// {@subCategory Rendering}
///
/// {@macro artisanal_uv_concept_overview}
/// {@macro artisanal_uv_renderer_overview}
/// {@macro artisanal_uv_performance_tips}
///
/// Example:
/// ```dart
/// void paint(Screen scr) {
///   final area = scr.bounds();
///   for (var y = area.minY; y < area.maxY; y++) {
///     for (var x = area.minX; x < area.maxX; x++) {
///       scr.setCell(x, y, Cell(content: ' '));
///     }
///   }
/// }
/// ```
library;
import 'cell.dart';
import 'geometry.dart';
import '../unicode/width.dart';

/// Screen is a 2D surface of cells.
///
/// Upstream: `third_party/ultraviolet/buffer.go` (`Screen` interface).
abstract class Screen {
  /// Returns the screen bounds as a [Rectangle].
  Rectangle bounds();

  /// Returns the cell at ([x], [y]) or null if out of bounds.
  Cell? cellAt(int x, int y);

  /// Sets the cell at ([x], [y]) to [cell].
  void setCell(int x, int y, Cell? cell);

  /// Returns the active grapheme width measurement method.
  WidthMethod widthMethod();
}

/// Optional fast-path: clear the entire screen.
///
/// Upstream: `third_party/ultraviolet/screen` (Clear).
abstract class ClearableScreen implements Screen {
  /// Clears the entire screen to empty cells.
  void clear();
}

/// Optional fast-path: clear an area of the screen.
///
/// Upstream: `third_party/ultraviolet/screen` (ClearArea).
abstract class ClearAreaScreen implements Screen {
  /// Clears [area] of the screen to empty cells.
  void clearArea(Rectangle area);
}

/// Optional fast-path: fill the entire screen.
///
/// Upstream: `third_party/ultraviolet/screen` (Fill).
abstract class FillableScreen implements Screen {
  /// Fills the entire screen with [cell].
  void fill(Cell? cell);
}

/// Optional fast-path: fill an area of the screen.
///
/// Upstream: `third_party/ultraviolet/screen` (FillArea).
abstract class FillAreaScreen implements Screen {
  /// Fills [area] of the screen with [cell].
  void fillArea(Cell? cell, Rectangle area);
}

/// Optional fast-path: clone the entire screen into a buffer.
///
/// Upstream: `third_party/ultraviolet/screen` (Clone).
abstract class CloneableScreen implements Screen {
  /// Returns a copy of the screen's backing buffer.
  Object clone();
}

/// Optional fast-path: clone a screen area into a buffer.
///
/// Upstream: `third_party/ultraviolet/screen` (CloneArea).
abstract class CloneAreaScreen implements Screen {
  /// Returns a copy of [area] from the screen's backing buffer, or null.
  Object? cloneArea(Rectangle area);
}
