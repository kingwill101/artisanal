import 'dart:math' as math;

import 'package:artisanal/style.dart' show Color;
import 'package:artisanal/uv.dart'
    show
        BufferFilter,
        BufferRenderSink,
        Canvas,
        Cell,
        StyledString,
        UvStyle,
        rect;

import '../core/widget.dart';
import '../framework.dart';
import '../rendering/render_object.dart';
import '../theme/theme_scope.dart';
import '_layout_utils.dart';
import 'geometry.dart';

/// Preset terminal-cell patterns used to paint a [Shadow].
enum TerminalShadowStyle {
  /// A solid background-colored block.
  block(' '),

  /// Light shade cells.
  light('░'),

  /// Medium shade cells.
  medium('▒'),

  /// Dark shade cells.
  dark('▓');

  const TerminalShadowStyle(this.glyph);

  /// Glyph used by this style.
  final String glyph;
}

/// Paints a cell-based shadow behind [child].
class Shadow extends StatelessWidget {
  /// Creates a terminal shadow.
  Shadow({
    required this.child,
    this.offsetX = 2,
    this.offsetY = 1,
    this.color,
    this.shadowStyle = TerminalShadowStyle.medium,
    super.key,
  });

  /// Foreground widget.
  final Widget child;

  /// Horizontal shadow offset in cells.
  final int offsetX;

  /// Vertical shadow offset in cells.
  final int offsetY;

  /// Shadow color, defaulting to the active theme shadow color.
  final Color? color;

  /// Cell pattern used for the shadow.
  final TerminalShadowStyle shadowStyle;

  @override
  List<Widget> get children => [child];

  @override
  Widget build(BuildContext context) => _ShadowBox(
    offsetX: offsetX,
    offsetY: offsetY,
    color: color ?? ThemeScope.of(context).resolvedShadow,
    shadowStyle: shadowStyle,
    child: child,
  );
}

final class _ShadowBox extends SingleChildRenderObjectWidget {
  _ShadowBox({
    required this.offsetX,
    required this.offsetY,
    required this.color,
    required this.shadowStyle,
    required super.child,
  });

  final int offsetX;
  final int offsetY;
  final Color color;
  final TerminalShadowStyle shadowStyle;

  @override
  RenderObject createRenderObject() => _RenderShadow(
    offsetX: offsetX,
    offsetY: offsetY,
    color: color,
    shadowStyle: shadowStyle,
  );

  @override
  void updateRenderObject(RenderObject renderObject) {
    final shadow = renderObject as _RenderShadow;
    shadow
      ..offsetX = offsetX
      ..offsetY = offsetY
      ..color = color
      ..shadowStyle = shadowStyle;
  }

  @override
  Object view() {
    final render = createRenderObject() as _RenderShadow;
    final childWidget = child;
    if (childWidget != null) {
      render.attach(RenderDelegateBox(() => renderWidget(childWidget)));
    }
    render.layout(BoxConstraints());
    return render.paint();
  }
}

final class _RenderShadow extends RenderBox {
  _RenderShadow({
    required this.offsetX,
    required this.offsetY,
    required this.color,
    required this.shadowStyle,
  });

  int offsetX;
  int offsetY;
  Color color;
  TerminalShadowStyle shadowStyle;

  RenderObject? get _child => children.isEmpty ? null : children.first;

  @override
  void layout(BoxConstraints constraints) {
    super.layout(constraints);
    final horizontalExtent = offsetX.abs();
    final verticalExtent = offsetY.abs();
    final childConstraints = BoxConstraints(
      minWidth: math.max(0, constraints.minWidth - horizontalExtent),
      maxWidth: math.max(0, constraints.maxWidth - horizontalExtent),
      minHeight: math.max(0, constraints.minHeight - verticalExtent),
      maxHeight: math.max(0, constraints.maxHeight - verticalExtent),
    );
    _child?.layout(childConstraints);
    final childSize = _child?.size ?? Size.zero;
    size = constraints.constrain(
      Size(
        childSize.width + horizontalExtent,
        childSize.height + verticalExtent,
      ),
    );
    _child?.offset = Offset(
      offsetX < 0 ? -offsetX.toDouble() : 0,
      offsetY < 0 ? -offsetY.toDouble() : 0,
    );
  }

  @override
  String paint() {
    final child = _child;
    if (child == null) return '';
    final width = size.width.toInt();
    final height = size.height.toInt();
    if (width <= 0 || height <= 0) return '';

    final childWidth = child.size.width.toInt();
    final childHeight = child.size.height.toInt();
    final childX = child.offset.dx.toInt();
    final childY = child.offset.dy.toInt();
    final shadowX = childX + offsetX;
    final shadowY = childY + offsetY;
    final uvColor = colorToUvColor(color);
    final glyph = shadowStyle.glyph;
    final shadowCell = Cell(
      content: glyph,
      style: glyph == ' ' ? UvStyle(bg: uvColor) : UvStyle(fg: uvColor),
    );

    final canvas = Canvas(width, height);
    for (var y = 0; y < childHeight; y++) {
      for (var x = 0; x < childWidth; x++) {
        canvas.setCell(shadowX + x, shadowY + y, shadowCell);
      }
    }
    canvas.fillArea(
      Cell.emptyCell(),
      rect(childX, childY, childWidth, childHeight),
    );
    StyledString(
      child.paint(),
    ).draw(canvas, rect(childX, childY, childWidth, childHeight));
    return padToStackSize(canvas.render(), width, height);
  }
}

/// Applies one or more UV [BufferFilter]s to the cells painted by [child].
class CellFilter extends SingleChildRenderObjectWidget {
  /// Creates a filtered cell subtree.
  CellFilter({
    required this.filters,
    this.deltaTime = 0,
    required super.child,
    super.key,
  });

  /// Filters applied in order.
  final List<BufferFilter> filters;

  /// Time delta supplied to animated filters.
  final double deltaTime;

  @override
  RenderObject createRenderObject() =>
      _RenderCellFilter(filters: filters, deltaTime: deltaTime);

  @override
  void updateRenderObject(RenderObject renderObject) {
    final filter = renderObject as _RenderCellFilter;
    filter
      ..filters = filters
      ..deltaTime = deltaTime;
  }

  @override
  Object view() {
    final render = createRenderObject() as _RenderCellFilter;
    final childWidget = child;
    if (childWidget != null) {
      render.attach(RenderDelegateBox(() => renderWidget(childWidget)));
    }
    render.layout(BoxConstraints());
    return render.paint();
  }
}

final class _RenderCellFilter extends RenderBox {
  _RenderCellFilter({required this.filters, required this.deltaTime});

  List<BufferFilter> filters;
  double deltaTime;
  BufferRenderSink? _sink;

  RenderObject? get _child => children.isEmpty ? null : children.first;

  @override
  void layout(BoxConstraints constraints) {
    super.layout(constraints);
    _child?.layout(constraints);
    size = constraints.constrain(_child?.size ?? Size.zero);
  }

  @override
  String paint() {
    final child = _child;
    if (child == null) return '';
    final width = size.width.toInt();
    final height = size.height.toInt();
    if (width <= 0 || height <= 0) return '';
    final source = Canvas(width, height);
    StyledString(child.paint()).draw(source, source.bounds());
    final sink = _sink ??= BufferRenderSink(width: width, height: height);
    return sink.render(source.buffer, filters, dt: deltaTime).render();
  }
}
