import 'geometry.dart';
import 'screen.dart';

/// Drawable can draw itself into a [Screen].
///
/// Upstream: `third_party/ultraviolet/buffer.go` (`Drawable`).
abstract interface class Drawable {
  /// Draws this drawable into [screen] within [area].
  void draw(Screen screen, Rectangle area);

  /// Returns the bounds required to draw this drawable.
  Rectangle bounds();
}

/// A no-op drawable with a fixed size.
///
/// Useful as a safe fallback when a terminal does not support any image
/// protocol: the renderer won't emit unknown escape sequences.
final class EmptyDrawable implements Drawable {
  /// Creates a drawable that occupies [width] by [height] cells.
  const EmptyDrawable({this.width = 0, this.height = 0});

  final int width;
  final int height;

  /// Returns the bounds of this empty drawable.
  @override
  Rectangle bounds() => Rectangle(minX: 0, minY: 0, maxX: width, maxY: height);

  /// Draws nothing.
  @override
  void draw(Screen screen, Rectangle area) {
    // no-op
  }
}
