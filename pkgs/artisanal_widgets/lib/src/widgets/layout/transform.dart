import 'dart:math' as math;
import 'package:artisanal/uv.dart' show StyledString, Canvas, Cell;
import '../rendering/render_object.dart';
import '../style.dart';
import '_layout_utils.dart';
import 'geometry.dart';

/// A widget that applies spatial transformations to its child.
///
/// In a terminal context, true rotation and scaling are not possible due to
/// the character grid nature of terminals. This widget supports:
/// - **translate**: Offset the child by (x, y) cells
/// - **flipHorizontal**: Mirror the content left-to-right
/// - **flipVertical**: Mirror the content top-to-bottom
///
/// ```dart
/// Transform.translate(
///   offset: Offset(5, 2),
///   child: Text('Shifted right 5, down 2'),
/// )
/// ```
class Transform extends SingleChildRenderObjectWidget {
  /// Creates a transform with a translation offset.
  Transform.translate({required Offset offset, super.child, super.key})
    : translateX = offset.dx.round(),
      translateY = offset.dy.round(),
      flipH = false,
      flipV = false;

  /// Creates a transform that flips content horizontally.
  Transform.flipHorizontal({super.child, super.key})
    : translateX = 0,
      translateY = 0,
      flipH = true,
      flipV = false;

  /// Creates a transform that flips content vertically.
  Transform.flipVertical({super.child, super.key})
    : translateX = 0,
      translateY = 0,
      flipH = false,
      flipV = true;

  /// Creates a transform with all options.
  Transform({
    this.translateX = 0,
    this.translateY = 0,
    this.flipH = false,
    this.flipV = false,
    super.child,
    super.key,
  });

  /// Horizontal translation in cells.
  final int translateX;

  /// Vertical translation in cells.
  final int translateY;

  /// Whether to flip content horizontally.
  final bool flipH;

  /// Whether to flip content vertically.
  final bool flipV;

  @override
  RenderObject createRenderObject() {
    return _RenderTransform(
      translateX: translateX,
      translateY: translateY,
      flipH: flipH,
      flipV: flipV,
    );
  }

  @override
  void updateRenderObject(RenderObject renderObject) {
    final r = renderObject as _RenderTransform;
    r
      ..translateX = translateX
      ..translateY = translateY
      ..flipH = flipH
      ..flipV = flipV;
  }

  @override
  Object view() {
    final content = child != null ? renderWidget(child!) : '';
    return _applyTransform(content, translateX, translateY, flipH, flipV);
  }
}

class _RenderTransform extends RenderBox {
  _RenderTransform({
    required this.translateX,
    required this.translateY,
    required this.flipH,
    required this.flipV,
  });

  int translateX;
  int translateY;
  bool flipH;
  bool flipV;
  String? _lastPaint;

  RenderObject? get _child => children.isEmpty ? null : children.first;

  @override
  void layout(BoxConstraints constraints) {
    super.layout(constraints);
    _child?.layout(constraints);
    final content = _child?.paint() ?? '';
    _lastPaint = _applyTransform(content, translateX, translateY, flipH, flipV);
    size = constraints.constrain(
      Size(
        Layout.getWidth(_lastPaint!).toDouble(),
        Layout.getHeight(_lastPaint!).toDouble(),
      ),
    );
  }

  @override
  String paint() {
    final cached = _lastPaint;
    if (cached != null) return cached;
    final content = _child?.paint() ?? '';
    return _applyTransform(content, translateX, translateY, flipH, flipV);
  }
}

/// Applies transform operations to terminal content.
String _applyTransform(
  String content,
  int translateX,
  int translateY,
  bool flipH,
  bool flipV,
) {
  if (content.isEmpty) return content;

  var result = content;

  // Apply flips first using Canvas for cell-level manipulation.
  if (flipH || flipV) {
    final w = Layout.getWidth(result);
    final h = Layout.getHeight(result);
    if (w > 0 && h > 0) {
      // Parse into source canvas.
      final srcCanvas = Canvas(w, h);
      StyledString(result).draw(srcCanvas, srcCanvas.bounds());

      final dstCanvas = Canvas(w, h);
      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          final srcX = flipH ? (w - 1 - x) : x;
          final srcY = flipV ? (h - 1 - y) : y;
          final cell = srcCanvas.cellAt(srcX, srcY);
          if (cell != null && !cell.isZero) {
            dstCanvas.setCell(x, y, cell.clone());
          } else {
            dstCanvas.setCell(x, y, Cell(content: ' ', width: 1));
          }
        }
      }
      result = dstCanvas.render();
    }
  }

  // Apply translation by placing content on a larger canvas.
  if (translateX != 0 || translateY != 0) {
    final w = Layout.getWidth(result);
    final h = Layout.getHeight(result);
    if (w > 0 && h > 0) {
      final newW = w + translateX.abs();
      final newH = h + translateY.abs();
      final offsetX = math.max(0, translateX);
      final offsetY = math.max(0, translateY);

      final canvas = Canvas(newW, newH);
      // Fill with spaces.
      for (var cy = 0; cy < newH; cy++) {
        for (var cx = 0; cx < newW; cx++) {
          canvas.setCell(cx, cy, Cell(content: ' ', width: 1));
        }
      }
      // Draw content at offset.
      final srcCanvas = Canvas(w, h);
      StyledString(result).draw(srcCanvas, srcCanvas.bounds());
      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          final destX = offsetX + x;
          final destY = offsetY + y;
          if (destX >= 0 && destX < newW && destY >= 0 && destY < newH) {
            final cell = srcCanvas.cellAt(x, y);
            if (cell != null && !cell.isZero) {
              canvas.setCell(destX, destY, cell.clone());
            }
          }
        }
      }
      result = canvas.render();
    }
  }

  return result;
}
