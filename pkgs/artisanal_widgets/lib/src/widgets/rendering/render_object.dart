/// Render object layer for widget layout and paint.
@experimental
library;

import 'package:meta/meta.dart' show experimental;

import '../core/widget.dart';
import 'package:artisanal/tui.dart' show View;
import 'package:artisanal/style.dart' show Layout;
import '../layout/geometry.dart'
    show BoxConstraints, Size, Offset, HitTestResult, HitTestEntry;

/// A render object represents a layout/paintable node.
abstract class RenderObject {
  RenderObject? parent;
  final List<RenderObject> children = [];
  Size size = Size.zero;

  /// Position relative to the parent render object, computed during layout.
  Offset offset = Offset.zero;

  BoxConstraints constraints = BoxConstraints();
  Object? element;
  Object? parentData;
  bool _paintDirty = true;

  /// Whether this render object (or a descendant in its subtree) needs paint.
  bool get paintDirty => _paintDirty;

  void attach(RenderObject child) {
    children.add(child);
    child.parent = this;
  }

  void detach(RenderObject child) {
    if (!identical(child.parent, this)) return;
    children.remove(child);
    child.parent = null;
  }

  void detachAll(Iterable<RenderObject> detachedChildren) {
    final detachedSet = detachedChildren is Set<RenderObject>
        ? detachedChildren
        : detachedChildren.toSet();
    if (detachedSet.isEmpty) return;

    children.removeWhere(detachedSet.contains);
    for (final child in detachedSet) {
      if (identical(child.parent, this)) {
        child.parent = null;
      }
    }
  }

  void layout(BoxConstraints constraints) {
    this.constraints = constraints;
    size = constraints.constrain(Size.zero);
  }

  String paint();

  /// Performs hit-testing at (localX, localY) in this object's coordinate
  /// space.  Adds matching entries to [result], deepest first.
  ///
  /// Returns `true` if this object or a descendant was hit.
  bool hitTest(
    HitTestResult result, {
    required double localX,
    required double localY,
  }) {
    if (localX < 0 ||
        localY < 0 ||
        localX >= size.width ||
        localY >= size.height) {
      return false;
    }

    // Test children in reverse order (last painted = on top).
    for (var i = children.length - 1; i >= 0; i--) {
      final child = children[i];
      final childX = localX - child.offset.dx;
      final childY = localY - child.offset.dy;
      if (childX < 0 ||
          childY < 0 ||
          childX >= child.size.width ||
          childY >= child.size.height) {
        continue;
      }
      if (child.hitTest(result, localX: childX, localY: childY)) {
        break; // deepest hit found via this child
      }
    }

    // Add ourselves — callers walk the path from deepest to shallowest.
    result.add(HitTestEntry(this, localX: localX, localY: localY));
    return true;
  }

  /// Called when a descendant render object's paint output has changed.
  ///
  /// Viewport render objects override this to invalidate their paint cache
  /// so the next [paint] call re-renders the child subtree.
  void markDescendantNeedsPaint() {
    _paintDirty = true;
  }

  /// Marks this render object as needing paint without invalidating
  /// descendant-specific paint caches.
  ///
  /// Use this for scroll-offset-only updates where content is unchanged but
  /// parent render caches must re-read this subtree's paint output.
  void markNeedsPaintOnly() {
    _paintDirty = true;
  }

  /// Marks this render object's paint state as clean.
  ///
  /// Call this after consuming the latest [paint] output.
  void clearPaintDirty() {
    _paintDirty = false;
  }

  /// Marks this render object and all descendants as paint-clean.
  void clearPaintDirtySubtree() {
    _paintDirty = false;
    for (final child in children) {
      child.clearPaintDirtySubtree();
    }
  }

  void dispose() {
    children.clear();
    parent = null;
  }
}

/// A render object with box constraints.
abstract class RenderBox extends RenderObject {}

/// A render box that delegates paint to a callback.
class RenderDelegateBox extends RenderBox {
  RenderDelegateBox(this._paintDelegate);

  Object Function() _paintDelegate;
  String? _lastPaint;

  set paintDelegate(Object Function() value) {
    _paintDelegate = value;
    _lastPaint = null;
  }

  @override
  void layout(BoxConstraints constraints) {
    super.layout(constraints);
    final content = _viewToString(_paintDelegate());
    _lastPaint = content;
    final width = Layout.getWidth(content).toDouble();
    final height = Layout.getHeight(content).toDouble();
    size = constraints.constrain(Size(width, height));
  }

  @override
  String paint() {
    final cached = _lastPaint;
    if (cached != null) return cached;
    return _viewToString(_paintDelegate());
  }
}

String _viewToString(Object v) {
  if (v is String) return v;
  if (v is View) return v.content;
  return v.toString();
}

/// Base class for widgets that create render objects.
abstract class RenderObjectWidget extends Widget {
  RenderObjectWidget({super.key});

  RenderObject createRenderObject();

  void updateRenderObject(RenderObject renderObject) {}

  void didUnmountRenderObject(RenderObject renderObject) {}
}

/// A render object widget with no children.
abstract class LeafRenderObjectWidget extends RenderObjectWidget {
  LeafRenderObjectWidget({super.key});

  @override
  List<Widget> get children => const [];
}

/// A render object widget with a single child.
abstract class SingleChildRenderObjectWidget extends RenderObjectWidget {
  SingleChildRenderObjectWidget({this.child, super.key});

  final Widget? child;

  @override
  List<Widget> get children => child == null ? const [] : [child!];
}

/// A render object widget with multiple children.
abstract class MultiChildRenderObjectWidget extends RenderObjectWidget {
  MultiChildRenderObjectWidget({required this.children, super.key});

  @override
  final List<Widget> children;
}
