import 'geometry.dart';
import '../core/element.dart'
    show Element, ElementFactory, ElementTree, RenderObjectElement, elementOf;
import '../core/framework.dart' show BuildContext;
import '../core/widget.dart' show Widget;
import '../rendering/render_object.dart'
    show RenderBox, RenderObject, RenderObjectWidget;

/// Builds a widget subtree using the constraints supplied by its parent.
///
/// These are the constraints passed to this render object during the current
/// layout, rather than the terminal viewport constraints.
class LayoutBuilder extends RenderObjectWidget implements ElementFactory {
  LayoutBuilder({required this.builder, super.key});

  /// Called with the incoming parent constraints.
  final Widget Function(BuildContext context, BoxConstraints constraints)
  builder;

  @override
  Element createElement() => _LayoutBuilderElement(this);

  @override
  RenderObject createRenderObject() => _RenderLayoutBuilder();

  @override
  Object view() {
    final mounted = elementOf(this);
    if (mounted != null) {
      return mounted.render(constraints: mounted.renderObject?.constraints);
    }
    // Standalone view has no parent; use the same lifecycle with unbounded
    // constraints rather than inventing viewport dimensions or dropping output.
    final tree = ElementTree(this);
    try {
      return tree.render();
    } finally {
      tree.unmount();
    }
  }
}

class _LayoutBuilderElement extends RenderObjectElement {
  _LayoutBuilderElement(LayoutBuilder super.widget) {
    (renderObject as _RenderLayoutBuilder).layoutCallback = _performLayout;
  }

  BoxConstraints? _lastConstraints;
  bool _needsLayoutBuild = true;

  LayoutBuilder get _layoutWidget => widget as LayoutBuilder;

  @override
  void update(Widget newWidget) {
    if (identical(widget, newWidget)) return;
    _needsLayoutBuild = true;
    super.update(newWidget);
  }

  @override
  List<Widget> build() {
    // Dependency changes participate in the ordinary build queue, but the
    // callback must wait for layout. Keep existing children mounted meanwhile.
    _needsLayoutBuild = true;
    return [for (final child in children) child.widget];
  }

  @override
  void unmount() {
    (renderObject as _RenderLayoutBuilder).layoutCallback = null;
    super.unmount();
  }

  void _performLayout(BoxConstraints constraints) {
    if (_lastConstraints == constraints && !_needsLayoutBuild) return;
    rebuildForLayout(() => [_layoutWidget.builder(context, constraints)]);
    syncRenderChildrenForLayout();
    _lastConstraints = constraints;
    _needsLayoutBuild = false;
  }
}

class _RenderLayoutBuilder extends RenderBox {
  void Function(BoxConstraints)? layoutCallback;
  bool _inLayout = false;
  RenderObject? get _child => children.isEmpty ? null : children.first;

  @override
  void layout(BoxConstraints constraints) {
    if (_inLayout) {
      throw StateError('LayoutBuilder cannot recursively lay itself out.');
    }
    _inLayout = true;
    try {
      super.layout(constraints);
      layoutCallback?.call(constraints);
      final child = _child;
      child?.layout(constraints);
      size = constraints.constrain(child?.size ?? Size.zero);
    } finally {
      _inLayout = false;
    }
  }

  @override
  String paint() => _child?.paint() ?? '';
}
