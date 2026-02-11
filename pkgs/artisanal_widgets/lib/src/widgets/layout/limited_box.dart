part of 'layout_widgets.dart';

/// A box that limits its size only when it's unconstrained.
///
/// If the incoming maximum width is unbounded (infinite), [maxWidth] is used
/// as the constraint. Similarly for [maxHeight]. When the incoming constraints
/// already have a finite bound, [LimitedBox] passes them through unchanged.
///
/// This is useful for widgets in lists or other unbounded parents where you
/// want a reasonable maximum size without overriding explicit constraints.
///
/// ```dart
/// LimitedBox(
///   maxWidth: 100,
///   maxHeight: 40,
///   child: Text('This text has a size limit in unbounded layouts'),
/// )
/// ```
class LimitedBox extends SingleChildRenderObjectWidget {
  LimitedBox({
    this.maxWidth = double.infinity,
    this.maxHeight = double.infinity,
    super.child,
    super.key,
  });

  /// Maximum width to impose when parent provides no width constraint.
  final double maxWidth;

  /// Maximum height to impose when parent provides no height constraint.
  final double maxHeight;

  @override
  RenderObject createRenderObject() {
    return _RenderLimitedBox(maxWidth: maxWidth, maxHeight: maxHeight);
  }

  @override
  void updateRenderObject(RenderObject renderObject) {
    final r = renderObject as _RenderLimitedBox;
    r
      ..maxWidth = maxWidth
      ..maxHeight = maxHeight;
  }

  @override
  Object view() {
    final content = child == null ? '' : _renderWidget(child!);
    // In the view path we don't have parent constraints, so just apply limits
    // as if unbounded.
    final w = maxWidth.isFinite ? maxWidth.toInt() : null;
    final h = maxHeight.isFinite ? maxHeight.toInt() : null;
    return _constrainContent(content, width: w, height: h);
  }
}

class _RenderLimitedBox extends RenderBox {
  _RenderLimitedBox({required this.maxWidth, required this.maxHeight});

  double maxWidth;
  double maxHeight;
  String? _lastPaint;

  RenderObject? get _child => children.isEmpty ? null : children.first;

  BoxConstraints _limitConstraints(BoxConstraints constraints) {
    return BoxConstraints(
      minWidth: constraints.minWidth,
      maxWidth: constraints.hasBoundedWidth
          ? constraints.maxWidth
          : math.min(maxWidth, constraints.maxWidth),
      minHeight: constraints.minHeight,
      maxHeight: constraints.hasBoundedHeight
          ? constraints.maxHeight
          : math.min(maxHeight, constraints.maxHeight),
    );
  }

  @override
  void layout(BoxConstraints constraints) {
    final limited = _limitConstraints(constraints);
    super.layout(limited);
    _child?.layout(limited);
    final rendered = _constrainContent(
      _child?.paint() ?? '',
      width: limited.hasBoundedWidth ? limited.maxWidth.toInt() : null,
      height: limited.hasBoundedHeight ? limited.maxHeight.toInt() : null,
    );
    _lastPaint = rendered;
    size = limited.constrain(
      Size(
        Layout.getWidth(rendered).toDouble(),
        Layout.getHeight(rendered).toDouble(),
      ),
    );
  }

  @override
  String paint() => _lastPaint ?? _child?.paint() ?? '';
}
