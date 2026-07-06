import '../core/widget.dart';
import '../rendering/render_layout.dart';
import '../rendering/render_object.dart';
import '_layout_utils.dart';
import 'enums.dart';
import 'flexible.dart';
import 'geometry.dart';
import 'spacer.dart';


class Flex extends MultiChildRenderObjectWidget {
  Flex({
    required this.direction,
    required super.children,
    this.gap = 0,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.min,
    this.mainAxisExtent,
    this.crossAxisExtent,
    super.key,
  });

  final Axis direction;
  final int gap;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final int? mainAxisExtent;
  final int? crossAxisExtent;

  bool get _isRow => direction == Axis.horizontal;

  @override
  RenderObject createRenderObject() {
    return _isRow
        ? RenderRow(
            gap: gap,
            mainAxisAlignment: _renderMainAxis(mainAxisAlignment),
            crossAxisAlignment: _renderCrossAxis(crossAxisAlignment),
            mainAxisSize: _renderMainAxisSize(mainAxisSize),
            mainAxisExtent: mainAxisExtent,
            crossAxisExtent: crossAxisExtent,
          )
        : RenderColumn(
            gap: gap,
            mainAxisAlignment: _renderMainAxis(mainAxisAlignment),
            crossAxisAlignment: _renderCrossAxis(crossAxisAlignment),
            mainAxisSize: _renderMainAxisSize(mainAxisSize),
            mainAxisExtent: mainAxisExtent,
            crossAxisExtent: crossAxisExtent,
          );
  }

  @override
  void updateRenderObject(RenderObject renderObject) {
    if (renderObject is RenderRow) {
      renderObject
        ..gap = gap
        ..mainAxisAlignment = _renderMainAxis(mainAxisAlignment)
        ..crossAxisAlignment = _renderCrossAxis(crossAxisAlignment)
        ..mainAxisSize = _renderMainAxisSize(mainAxisSize)
        ..mainAxisExtent = mainAxisExtent
        ..crossAxisExtent = crossAxisExtent;
    }
    if (renderObject is RenderColumn) {
      renderObject
        ..gap = gap
        ..mainAxisAlignment = _renderMainAxis(mainAxisAlignment)
        ..crossAxisAlignment = _renderCrossAxis(crossAxisAlignment)
        ..mainAxisSize = _renderMainAxisSize(mainAxisSize)
        ..mainAxisExtent = mainAxisExtent
        ..crossAxisExtent = crossAxisExtent;
    }
  }

  @override
  Object view() {
    if (children.isEmpty) return '';
    final render = createRenderObject() as RenderBox;
    for (final child in children) {
      final renderChild = RenderDelegateBox(() => renderWidget(child));
      final info = _flexInfoFor(child);
      if (info != null) {
        renderChild.parentData = info;
      }
      render.attach(renderChild);
    }
    render.layout(BoxConstraints());
    return render.paint();
  }
}

RenderMainAxisAlignment _renderMainAxis(MainAxisAlignment align) {
  return switch (align) {
    MainAxisAlignment.start => RenderMainAxisAlignment.start,
    MainAxisAlignment.end => RenderMainAxisAlignment.end,
    MainAxisAlignment.center => RenderMainAxisAlignment.center,
    MainAxisAlignment.spaceBetween => RenderMainAxisAlignment.spaceBetween,
    MainAxisAlignment.spaceAround => RenderMainAxisAlignment.spaceAround,
    MainAxisAlignment.spaceEvenly => RenderMainAxisAlignment.spaceEvenly,
  };
}

RenderCrossAxisAlignment _renderCrossAxis(CrossAxisAlignment align) {
  return switch (align) {
    CrossAxisAlignment.start => RenderCrossAxisAlignment.start,
    CrossAxisAlignment.end => RenderCrossAxisAlignment.end,
    CrossAxisAlignment.center => RenderCrossAxisAlignment.center,
    CrossAxisAlignment.stretch => RenderCrossAxisAlignment.stretch,
  };
}

RenderMainAxisSize _renderMainAxisSize(MainAxisSize size) {
  return switch (size) {
    MainAxisSize.min => RenderMainAxisSize.min,
    MainAxisSize.max => RenderMainAxisSize.max,
  };
}

FlexParentData? _flexInfoFor(Widget widget) {
  if (widget is Flexible) {
    return FlexParentData(
      flex: widget.flex,
      fit: widget.fit == FlexFit.tight
          ? RenderFlexFit.tight
          : RenderFlexFit.loose,
    );
  }
  if (widget is Spacer && widget.flex != null) {
    return FlexParentData(flex: widget.flex!, fit: RenderFlexFit.tight);
  }
  return null;
}
