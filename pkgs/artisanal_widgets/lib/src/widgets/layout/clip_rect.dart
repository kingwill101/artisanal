import 'package:artisanal/style.dart' hide Padding, Align;
import '_layout_utils.dart';
import 'geometry.dart';
import '../rendering/render_object.dart';

/// A widget that clips its child to its allocated size.
///
/// Any content that extends beyond the width or height of the clip region
/// is truncated. This is useful for preventing overflow in constrained
/// terminal layouts.
///
/// ```dart
/// ClipRect(
///   width: 20,
///   height: 5,
///   child: Text(longMultilineString),
/// )
/// ```
class ClipRect extends SingleChildRenderObjectWidget {
  ClipRect({this.width, this.height, this.top, super.child, super.key});

  /// Maximum width in columns. If null, uses child's natural width.
  final int? width;

  /// Maximum height in rows. If null, uses child's natural height.
  final int? height;

  /// Number of rows to drop from the top before applying [height]. This lets
  /// [ClipRect] render a middle band `[top, top + height)` of the child, which
  /// is useful for scrolling a tall child through a fixed window.
  final int? top;

  @override
  RenderObject createRenderObject() {
    return _RenderClipRect(clipWidth: width, clipHeight: height, clipTop: top);
  }

  @override
  void updateRenderObject(RenderObject renderObject) {
    final clip = renderObject as _RenderClipRect;
    clip
      ..clipWidth = width
      ..clipHeight = height
      ..clipTop = top;
  }

  @override
  Object view() {
    final content = child != null ? renderWidget(child!) : '';
    return _clipContent(content, width, height, top);
  }
}

class _RenderClipRect extends RenderBox {
  _RenderClipRect({this.clipWidth, this.clipHeight, this.clipTop});

  int? clipWidth;
  int? clipHeight;
  int? clipTop;
  String? _lastPaint;

  RenderObject? get _child => children.isEmpty ? null : children.first;

  @override
  void layout(BoxConstraints constraints) {
    super.layout(constraints);
    _child?.layout(constraints);
    final content = _child?.paint() ?? '';
    _lastPaint = _clipContent(content, clipWidth, clipHeight, clipTop);
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
    return _clipContent(content, clipWidth, clipHeight, clipTop);
  }
}

/// Clips [content] to the given [maxWidth] and [maxHeight], dropping [top]
/// rows from the top first.
String _clipContent(String content, int? maxWidth, int? maxHeight, int? top) {
  if (content.isEmpty) return '';
  if (maxWidth == null && maxHeight == null && (top == null || top <= 0)) {
    return content;
  }

  var result = content;

  // Drop top rows before clipping height.
  if (top != null && top > 0) {
    final rows = result.split('\n');
    result = rows.skip(top).join('\n');
  }

  // Clip width: truncate each line to maxWidth columns (no ellipsis — hard clip).
  if (maxWidth != null && maxWidth > 0) {
    result = Layout.truncateLines(result, maxWidth, ellipsis: '');
  } else if (maxWidth != null && maxWidth <= 0) {
    return '';
  }

  // Clip height: keep only the first maxHeight lines.
  if (maxHeight != null && maxHeight > 0) {
    result = Layout.truncateHeight(result, maxHeight);
  } else if (maxHeight != null && maxHeight <= 0) {
    return '';
  }

  return result;
}
