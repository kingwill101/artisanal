import '../render_object.dart';
import '_layout_utils.dart';
import 'geometry.dart';
import 'spacing.dart';

/// A widget that imposes different constraints on its child than it gets
/// from its parent, possibly allowing the child to overflow the parent.
///
/// This is useful when you want the child to be laid out as if it had
/// more (or less) space than the parent provides. The [OverflowBox]
/// itself reports its own size based on the parent constraints, but the
/// child may be larger or smaller.
///
/// ```dart
/// OverflowBox(
///   minWidth: 0,
///   maxWidth: 100,
///   child: Text('This text can be up to 100 columns wide'),
/// )
/// ```
class OverflowBox extends SingleChildRenderObjectWidget {
  OverflowBox({
    this.minWidth,
    this.maxWidth,
    this.minHeight,
    this.maxHeight,
    this.alignment = Alignment.center,
    super.child,
    super.key,
  });

  /// The minimum width constraint to impose on the child.
  /// If null, the parent's min width constraint is used.
  final double? minWidth;

  /// The maximum width constraint to impose on the child.
  /// If null, the parent's max width constraint is used.
  final double? maxWidth;

  /// The minimum height constraint to impose on the child.
  /// If null, the parent's min height constraint is used.
  final double? minHeight;

  /// The maximum height constraint to impose on the child.
  /// If null, the parent's max height constraint is used.
  final double? maxHeight;

  /// How to align the child within this widget's bounds.
  final Alignment alignment;

  @override
  RenderObject createRenderObject() {
    return _RenderOverflowBox(
      minWidth: minWidth,
      maxWidth: maxWidth,
      minHeight: minHeight,
      maxHeight: maxHeight,
      alignment: alignment,
    );
  }

  @override
  void updateRenderObject(RenderObject renderObject) {
    final box = renderObject as _RenderOverflowBox;
    box
      ..overrideMinWidth = minWidth
      ..overrideMaxWidth = maxWidth
      ..overrideMinHeight = minHeight
      ..overrideMaxHeight = maxHeight
      ..alignment = alignment;
  }

  @override
  Object view() {
    if (child == null) return '';
    return renderWidget(child!);
  }
}

class _RenderOverflowBox extends RenderBox {
  _RenderOverflowBox({
    double? minWidth,
    double? maxWidth,
    double? minHeight,
    double? maxHeight,
    this.alignment = Alignment.center,
  }) : overrideMinWidth = minWidth,
       overrideMaxWidth = maxWidth,
       overrideMinHeight = minHeight,
       overrideMaxHeight = maxHeight;

  double? overrideMinWidth;
  double? overrideMaxWidth;
  double? overrideMinHeight;
  double? overrideMaxHeight;
  Alignment alignment;

  RenderObject? get _child => children.isEmpty ? null : children.first;

  @override
  void layout(BoxConstraints constraints) {
    super.layout(constraints);

    // This widget's own size follows the parent constraints.
    size = constraints.constrain(
      Size(constraints.maxWidth, constraints.maxHeight),
    );

    // But the child gets different constraints.
    if (_child != null) {
      final childConstraints = BoxConstraints(
        minWidth: overrideMinWidth ?? constraints.minWidth,
        maxWidth: overrideMaxWidth ?? constraints.maxWidth,
        minHeight: overrideMinHeight ?? constraints.minHeight,
        maxHeight: overrideMaxHeight ?? constraints.maxHeight,
      );
      _child!.layout(childConstraints);
    }
  }

  @override
  String paint() {
    return _child?.paint() ?? '';
  }
}

/// A widget that is a specific size but passes its original constraints
/// through to its child, which may then overflow.
///
/// Unlike [OverflowBox] which lets you override the child's constraints,
/// [SizedOverflowBox] has a fixed `size` for its own layout, but the child
/// receives the incoming parent constraints unmodified. The child is
/// positioned within the [SizedOverflowBox] according to `alignment`.
///
/// ```dart
/// SizedOverflowBox(
///   size: Size(20, 5),
///   child: Text('This child may be larger than 20x5'),
/// )
/// ```
class SizedOverflowBox extends SingleChildRenderObjectWidget {
  SizedOverflowBox({
    required this.requestedSize,
    this.alignment = Alignment.center,
    super.child,
    super.key,
  });

  /// The size this widget should take up.
  final Size requestedSize;

  /// How to align the child within this widget's bounds.
  final Alignment alignment;

  @override
  RenderObject createRenderObject() {
    return _RenderSizedOverflowBox(
      requestedSize: requestedSize,
      alignment: alignment,
    );
  }

  @override
  void updateRenderObject(RenderObject renderObject) {
    final box = renderObject as _RenderSizedOverflowBox;
    box
      ..requestedSize = requestedSize
      ..alignment = alignment;
  }

  @override
  Object view() {
    if (child == null) return '';
    return renderWidget(child!);
  }
}

class _RenderSizedOverflowBox extends RenderBox {
  _RenderSizedOverflowBox({
    required this.requestedSize,
    this.alignment = Alignment.center,
  });

  Size requestedSize;
  Alignment alignment;

  RenderObject? get _child => children.isEmpty ? null : children.first;

  @override
  void layout(BoxConstraints constraints) {
    super.layout(constraints);

    // Our own size is the requested size, clamped to parent constraints.
    size = constraints.constrain(requestedSize);

    // The child gets the original parent constraints, allowing overflow.
    _child?.layout(constraints);
  }

  @override
  String paint() {
    return _child?.paint() ?? '';
  }
}
