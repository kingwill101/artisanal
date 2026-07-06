import '../render_object.dart';
import '_layout_utils.dart';
import 'geometry.dart';

/// A render object that never reports a hit, causing hit-testing to skip
/// its subtree and continue to siblings in the parent's child list.
///
/// This is the render-object counterpart of [IgnorePointer].
class RenderIgnorePointer extends RenderBox {
  RenderIgnorePointer({this.ignoring = true});

  /// Whether hit-testing is disabled for this subtree.
  bool ignoring;

  RenderObject? get _child => children.isEmpty ? null : children.first;

  @override
  void layout(BoxConstraints constraints) {
    super.layout(constraints);
    _child?.layout(constraints);
    if (_child != null) {
      size = _child!.size;
    }
  }

  @override
  String paint() => _child?.paint() ?? '';

  @override
  bool hitTest(
    HitTestResult result, {
    required double localX,
    required double localY,
  }) {
    if (ignoring) return false;
    return super.hitTest(result, localX: localX, localY: localY);
  }
}

/// A widget that is invisible to hit-testing.
///
/// When [ignoring] is `true` (the default), the widget's subtree cannot
/// receive mouse events via hit-testing. In a [Stack], this causes events
/// to fall through to siblings painted below.
///
/// This is useful for overlays (e.g., [DebugOverlay]) that should be visible
/// but not block mouse interaction with the content underneath.
///
/// ```dart
/// Stack(
///   children: [
///     interactiveContent,
///     IgnorePointer(
///       child: Align(
///         alignment: Alignment.topRight,
///         child: overlayWidget,
///       ),
///     ),
///   ],
/// )
/// ```
class IgnorePointer extends SingleChildRenderObjectWidget {
  IgnorePointer({super.child, this.ignoring = true, super.key});

  /// Whether this widget is invisible to hit-testing.
  ///
  /// When `true`, mouse events pass through this widget's subtree.
  /// When `false`, hit-testing behaves normally.
  final bool ignoring;

  @override
  RenderObject createRenderObject() {
    return RenderIgnorePointer(ignoring: ignoring);
  }

  @override
  void updateRenderObject(RenderObject renderObject) {
    (renderObject as RenderIgnorePointer).ignoring = ignoring;
  }

  @override
  Object view() => child == null ? '' : renderWidget(child!);
}
