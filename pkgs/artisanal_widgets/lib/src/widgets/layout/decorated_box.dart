import 'package:artisanal/style.dart' hide Padding, Align;

import '../rendering/render_object.dart';
import '_layout_utils.dart';
import 'colored_box.dart';
import 'container.dart';
import 'geometry.dart';

/// Where to paint a decoration relative to the child.
enum DecorationPosition {
  /// Paint the decoration behind the child.
  background,

  /// Paint the decoration in front of the child.
  foreground,
}

/// A widget that paints a [Decoration] either behind or in front of its child.
///
/// This is a lower-level building block — [Container] uses it internally.
/// Use [DecoratedBox] when you want decoration without the padding, margin,
/// or alignment features that [Container] provides.
///
/// ```dart
/// DecoratedBox(
///   decoration: BoxDecoration(
///     color: Colors.blue,
///     border: Border.rounded,
///     borderRadius: BorderRadius.all(1),
///   ),
///   child: Padding(
///     padding: EdgeInsets.all(1),
///     child: Text('Decorated'),
///   ),
/// )
/// ```
class DecoratedBox extends SingleChildRenderObjectWidget {
  DecoratedBox({
    required this.decoration,
    this.position = DecorationPosition.background,
    super.child,
    super.key,
  });

  /// The decoration to paint.
  final Decoration decoration;

  /// Whether to paint the decoration behind or in front of the child.
  final DecorationPosition position;

  @override
  RenderObject createRenderObject() {
    return _RenderDecoratedBox(decoration: decoration, position: position);
  }

  @override
  void updateRenderObject(RenderObject renderObject) {
    final box = renderObject as _RenderDecoratedBox;
    box
      ..decoration = decoration
      ..position = position;
  }

  @override
  Object view() {
    final content = child != null ? renderWidget(child!) : '';
    return _renderDecoratedContent(content, decoration, position);
  }
}

class _RenderDecoratedBox extends RenderBox {
  _RenderDecoratedBox({required this.decoration, required this.position});

  Decoration decoration;
  DecorationPosition position;
  String? _lastPaint;

  RenderObject? get _child => children.isEmpty ? null : children.first;

  @override
  void layout(BoxConstraints constraints) {
    super.layout(constraints);
    _child?.layout(constraints);
    final content = _child?.paint() ?? '';
    _lastPaint = _renderDecoratedContent(content, decoration, position);
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
    return _renderDecoratedContent(content, decoration, position);
  }
}

String _renderDecoratedContent(
  String content,
  Decoration decoration,
  DecorationPosition position,
) {
  // For a simple Decoration (not BoxDecoration), just apply background color.
  if (decoration is! BoxDecoration) {
    if (decoration.color != null) {
      return renderColoredContent(content, decoration.color!);
    }
    return content;
  }

  // BoxDecoration: delegate to the container renderer for border, radius, etc.
  return renderContainerContent(
    contentStr: content,
    decoration: decoration,
    foregroundDecoration: position == DecorationPosition.foreground
        ? decoration
        : null,
  );
}
