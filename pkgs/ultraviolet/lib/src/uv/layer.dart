/// Composable 2D visual layers with z-ordering, hit-testing, and rendering.
///
/// {@category Ultraviolet}
/// {@subCategory Composition}
///
/// {@macro artisanal_uv_concept_overview}
/// {@macro artisanal_uv_renderer_overview}
/// {@macro artisanal_uv_events_overview}
/// {@macro artisanal_uv_performance_tips}
/// {@macro artisanal_uv_compatibility}
///
/// A [Layer] wraps a [Drawable] with `x`, `y`, and `z` positioning, optional
/// child layers, and a stable `id` for lookup and hits. The [Compositor]
/// flattens the layer tree, computes aggregate bounds, maintains an `id` index,
/// and draws in deterministic z-order (higher `z` above lower; ties broken by
/// traversal order) onto a [Screen] or into a [Canvas].
///
/// Hit-testing returns the top-most match via [LayerHit], scanning from highest
/// z-order down. Composition respects geometry unions to minimize overdraw,
/// and [Compositor.render] uses a [Canvas] to produce a string snapshot.
///
/// Example:
/// ```dart
/// final base = newLayer('Hello').setId('greeting')..setZ(0);
/// final badge = newLayer('!').setId('badge')..setX(5)..setZ(1);
/// final comp = Compositor([base, badge]);
///
/// final hit = comp.hit(5, 0); // top-most at x=5, y=0
/// assert(hit.id == 'badge');
///
/// // Compose to a canvas or draw onto a screen region.
/// final rendered = comp.render();
/// // void paint(Screen scr) => comp.draw(scr, comp.bounds());
/// ```
library;

import 'dart:math' as math;

import 'canvas.dart';
import 'drawable.dart';
import 'geometry.dart';
import 'screen.dart';
import 'styled_string.dart';

/// Layer represents a visual layer with content and positioning.
///
/// Upstream: `third_party/lipgloss/layer.go` (`Layer`).
final class Layer {
  Layer(this.drawable, [List<Layer> layers = const []])
    : _layers = [...layers] {
    _recomputeSize();
  }

  String id = '';
  Drawable drawable;
  int x = 0;
  int y = 0;
  int z = 0;

  int width = 0;
  int height = 0;

  final List<Layer> _layers;

  /// Child layers attached to this layer.
  List<Layer> get layers => List.unmodifiable(_layers);

  /// Sets the stable [id] used for lookup and hit testing.
  Layer setId(String value) {
    id = value;
    return this;
  }

  /// Sets the horizontal position in cells.
  Layer setX(int value) {
    x = value;
    _recomputeSize();
    return this;
  }

  /// Sets the vertical position in cells.
  Layer setY(int value) {
    y = value;
    _recomputeSize();
    return this;
  }

  /// Sets the z-order for this layer.
  Layer setZ(int value) {
    z = value;
    return this;
  }

  /// Adds [layers] as children of this layer.
  Layer addLayers(List<Layer> layers) {
    _layers.addAll(layers);
    _recomputeSize();
    return this;
  }

  /// Returns the first layer with [lookupId], searching descendants.
  Layer? getLayer(String lookupId) {
    if (lookupId.isEmpty) return null;
    if (id == lookupId) return this;
    for (final child in _layers) {
      final found = child.getLayer(lookupId);
      if (found != null) return found;
    }
    return null;
  }

  /// Returns the maximum z-order in this subtree.
  int maxZ() {
    var maxZ = z;
    for (final child in _layers) {
      maxZ = math.max(maxZ, child.maxZ());
    }
    return maxZ;
  }

  void _recomputeSize() {
    final area = _boundsWithOffset(0, 0);
    width = area.width;
    height = area.height;
  }

  Rectangle _boundsWithOffset(int parentX, int parentY) {
    final absX = x + parentX;
    final absY = y + parentY;

    final b = drawable.bounds();
    var area = Rectangle(
      minX: absX,
      minY: absY,
      maxX: absX + b.width,
      maxY: absY + b.height,
    );

    for (final child in _layers) {
      area = area.union(child._boundsWithOffset(absX, absY));
    }
    return area;
  }
}

/// Creates a new [Layer] from a [String] or [Drawable].
///
/// Throws an [ArgumentError] if [content] is neither.
Layer newLayer(Object content, [List<Layer> layers = const []]) {
  if (content is Drawable) {
    return Layer(content, layers);
  } else if (content is String) {
    return Layer(StyledString(content), layers);
  } else {
    throw ArgumentError('content must be a String or Drawable');
  }
}

final class LayerHit {
  const LayerHit({this.id = '', this.layer, this.bounds});

  final String id;
  final Layer? layer;
  final Rectangle? bounds;

  /// Whether this hit contains no layer.
  bool get isEmpty => layer == null;
}

final class _CompositeLayer {
  const _CompositeLayer({
    required this.layer,
    required this.absX,
    required this.absY,
    required this.bounds,
    required this.order,
  });

  final Layer layer;
  final int absX;
  final int absY;
  final Rectangle bounds;
  final int order;
}

/// Compositor manages layer composition, drawing and hit testing.
///
/// Upstream: `third_party/lipgloss/layer.go` (`Compositor`).
final class Compositor implements Drawable {
  Compositor([List<Layer> layers = const []])
    : _root = Layer(StyledString(''))..addLayers(layers) {
    // Upstream: `third_party/lipgloss/layer.go` (`NewCompositor`) flattens on
    // construction so `Bounds`, `Hit`, and `GetLayer` work immediately.
    _flatten();
  }

  final Layer _root;

  final List<_CompositeLayer> _layers = [];
  final Map<String, Layer> _index = {};
  Rectangle _bounds = const Rectangle(minX: 0, minY: 0, maxX: 0, maxY: 0);

  /// Rebuilds the flattened layer list and bounds.
  void refresh() => _flatten();

  /// Adds [layers] to the compositor root and refreshes.
  void addLayers(List<Layer> layers) {
    _root.addLayers(layers);
    _flatten();
  }

  /// Returns the compositor bounds.
  @override
  Rectangle bounds() => _bounds;

  /// Returns the layer with [id], if any.
  Layer? getLayer(String id) => _index[id];

  /// Returns the top-most layer hit at ([x], [y]).
  LayerHit hit(int x, int y) {
    final p = Position(x, y);
    for (var i = _layers.length - 1; i >= 0; i--) {
      final cl = _layers[i];
      if (cl.layer.id.isNotEmpty && cl.bounds.contains(p)) {
        return LayerHit(id: cl.layer.id, layer: cl.layer, bounds: cl.bounds);
      }
    }
    return const LayerHit();
  }

  /// Draws visible layers that overlap [area] onto [scr].
  @override
  void draw(Screen scr, Rectangle area) {
    if (_layers.isEmpty) _flatten();
    for (final cl in _layers) {
      if (cl.bounds.overlaps(area)) {
        cl.layer.drawable.draw(scr, cl.bounds);
      }
    }
  }

  /// Renders the compositor to a string snapshot.
  String render() {
    if (_layers.isEmpty) _flatten();
    final w = _bounds.width;
    final h = _bounds.height;
    final canvas = Canvas(w, h);
    canvas.compose(this);
    return canvas.render();
  }

  void _flatten() {
    _layers.clear();
    _index.clear();
    _bounds = const Rectangle(minX: 0, minY: 0, maxX: 0, maxY: 0);

    var order = 0;
    void recurse(Layer layer, int parentX, int parentY) {
      final absX = layer.x + parentX;
      final absY = layer.y + parentY;
      final b = layer.drawable.bounds();
      final bounds = Rectangle(
        minX: absX,
        minY: absY,
        maxX: absX + b.width,
        maxY: absY + b.height,
      );

      _layers.add(
        _CompositeLayer(
          layer: layer,
          absX: absX,
          absY: absY,
          bounds: bounds,
          order: order++,
        ),
      );

      if (layer.id.isNotEmpty) {
        _index[layer.id] = layer;
      }

      for (final child in layer.layers) {
        recurse(child, absX, absY);
      }
    }

    recurse(_root, 0, 0);
    // Upstream sorts by z-index. Dart's `sort` is not stable, which can cause
    // equal z-index layers to reorder across refreshes and produce surprising
    // draw ordering. Tie-break on traversal order for deterministic layering.
    _layers.sort((a, b) {
      final z = a.layer.z.compareTo(b.layer.z);
      if (z != 0) return z;
      return a.order.compareTo(b.order);
    });

    if (_layers.isNotEmpty) {
      var b = _layers.first.bounds;
      for (var i = 1; i < _layers.length; i++) {
        b = b.union(_layers[i].bounds);
      }
      _bounds = b;
    }
  }
}
