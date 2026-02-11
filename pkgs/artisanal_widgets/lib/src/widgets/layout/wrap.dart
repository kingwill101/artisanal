part of 'layout_widgets.dart';

class Wrap extends MultiChildRenderObjectWidget {
  Wrap({
    required super.children,
    this.direction = Axis.horizontal,
    this.alignment = WrapAlignment.start,
    this.crossAxisAlignment = WrapCrossAlignment.start,
    this.spacing = 0,
    this.runSpacing = 0,
    super.key,
  });

  final Axis direction;
  final WrapAlignment alignment;
  final WrapCrossAlignment crossAxisAlignment;
  final int spacing;
  final int runSpacing;

  @override
  RenderObject createRenderObject() {
    return RenderWrap(
      direction: direction,
      alignment: alignment,
      crossAxisAlignment: crossAxisAlignment,
      spacing: spacing,
      runSpacing: runSpacing,
    );
  }

  @override
  void updateRenderObject(RenderObject renderObject) {
    (renderObject as RenderWrap)
      ..direction = direction
      ..alignment = alignment
      ..crossAxisAlignment = crossAxisAlignment
      ..spacing = spacing
      ..runSpacing = runSpacing;
  }

  @override
  Object view() {
    if (children.isEmpty) return '';
    final render = RenderWrap(
      direction: direction,
      alignment: alignment,
      crossAxisAlignment: crossAxisAlignment,
      spacing: spacing,
      runSpacing: runSpacing,
    );
    for (final child in children) {
      render.attach(RenderDelegateBox(() => _renderWidget(child)));
    }
    render.layout(BoxConstraints());
    return render.paint();
  }
}

class _WrapItem {
  _WrapItem({required this.child, required this.main, required this.cross});

  final RenderObject child;
  final int main;
  final int cross;
}

class _WrapRun {
  _WrapRun({required this.items, required this.main, required this.cross});

  final List<_WrapItem> items;
  final int main;
  final int cross;
}

class RenderWrap extends RenderBox {
  RenderWrap({
    required this.direction,
    required this.alignment,
    required this.crossAxisAlignment,
    required this.spacing,
    required this.runSpacing,
  });

  Axis direction;
  WrapAlignment alignment;
  WrapCrossAlignment crossAxisAlignment;
  int spacing;
  int runSpacing;

  List<_WrapRun> _runs = const [];

  bool get _isHorizontal => direction == Axis.horizontal;

  @override
  void layout(BoxConstraints constraints) {
    super.layout(constraints);
    _runs = _computeRuns(constraints);

    if (_runs.isEmpty) {
      size = constraints.constrain(Size.zero);
      return;
    }

    final contentMain = _runs.map((r) => r.main).reduce(math.max);
    final contentCross =
        _runs.fold<int>(0, (sum, run) => sum + run.cross) +
        (runSpacing * math.max(0, _runs.length - 1));

    final width = _isHorizontal ? contentMain : contentCross;
    final height = _isHorizontal ? contentCross : contentMain;

    size = constraints.constrain(Size(width.toDouble(), height.toDouble()));
  }

  @override
  String paint() {
    if (children.isEmpty) return '';
    final width = size.width.toInt();
    final height = size.height.toInt();
    if (width == 0 || height == 0) return '';

    final canvas = Canvas(width, height);
    final bgStyle = const UvStyle();

    var crossOffset = 0;
    for (final run in _runs) {
      final extraMain = (_isHorizontal ? width : height) - run.main;
      final spacingData = _computeWrapSpacing(
        run.items.length,
        spacing,
        math.max(0, extraMain),
        alignment,
      );

      var mainOffset = spacingData.leading;
      for (var i = 0; i < run.items.length; i++) {
        final item = run.items[i];
        final crossDelta = _wrapCrossOffset(run.cross, item.cross);
        final dx = _isHorizontal ? mainOffset : crossOffset + crossDelta;
        final dy = _isHorizontal ? crossOffset + crossDelta : mainOffset;
        _drawStyledContent(canvas, item.child.paint(), dx, dy, bgStyle);
        mainOffset += item.main;
        if (i < spacingData.between.length) {
          mainOffset += spacingData.between[i];
        }
      }

      crossOffset += run.cross + runSpacing;
    }

    var result = canvas.render();
    result = _padToStackSize(result, width, height);
    return result;
  }

  List<_WrapRun> _computeRuns(BoxConstraints constraints) {
    if (children.isEmpty) return const [];
    final runs = <_WrapRun>[];
    final maxMain = _isHorizontal
        ? (constraints.hasBoundedWidth ? constraints.maxWidth.toInt() : null)
        : (constraints.hasBoundedHeight ? constraints.maxHeight.toInt() : null);

    // Loosen min constraints so children can report their natural sizes
    // (matching Flutter's RenderWrap).
    final childConstraints = BoxConstraints(
      maxWidth: constraints.maxWidth,
      maxHeight: constraints.maxHeight,
    );

    final items = <_WrapItem>[];
    for (final child in children) {
      child.layout(childConstraints);
      final main = _isHorizontal
          ? child.size.width.toInt()
          : child.size.height.toInt();
      final cross = _isHorizontal
          ? child.size.height.toInt()
          : child.size.width.toInt();
      items.add(_WrapItem(child: child, main: main, cross: cross));
    }

    if (maxMain == null || maxMain <= 0) {
      final totalMain =
          items.fold<int>(0, (sum, item) => sum + item.main) +
          (spacing * math.max(0, items.length - 1)).toInt();
      final maxCross = items.isEmpty
          ? 0
          : items.map((item) => item.cross).reduce(math.max);
      runs.add(_WrapRun(items: items, main: totalMain, cross: maxCross));
      return runs;
    }

    var current = <_WrapItem>[];
    var currentMain = 0;
    var currentCross = 0;

    void flush() {
      if (current.isEmpty) return;
      runs.add(
        _WrapRun(items: current, main: currentMain, cross: currentCross),
      );
      current = <_WrapItem>[];
      currentMain = 0;
      currentCross = 0;
    }

    for (final item in items) {
      final proposed = current.isEmpty
          ? item.main
          : currentMain + spacing + item.main;
      if (current.isNotEmpty && proposed > maxMain) {
        flush();
      }
      currentMain = current.isEmpty
          ? item.main
          : currentMain + spacing + item.main;
      currentCross = math.max(currentCross, item.cross);
      current.add(item);
    }
    flush();
    return runs;
  }

  int _wrapCrossOffset(int runCross, int itemCross) {
    return switch (crossAxisAlignment) {
      WrapCrossAlignment.start => 0,
      WrapCrossAlignment.center => (runCross - itemCross) ~/ 2,
      WrapCrossAlignment.end => runCross - itemCross,
    };
  }
}

_FlexSpacing _computeWrapSpacing(
  int count,
  int baseGap,
  int extra,
  WrapAlignment alignment,
) {
  if (count <= 1) {
    return _FlexSpacing(0, const [], 0);
  }

  switch (alignment) {
    case WrapAlignment.start:
      return _FlexSpacing(0, List.filled(count - 1, baseGap), 0);
    case WrapAlignment.end:
      return _FlexSpacing(extra, List.filled(count - 1, baseGap), 0);
    case WrapAlignment.center:
      final lead = extra ~/ 2;
      return _FlexSpacing(lead, List.filled(count - 1, baseGap), extra - lead);
    case WrapAlignment.spaceBetween:
      final total = baseGap * (count - 1) + extra;
      final base = total ~/ (count - 1);
      final leftover = total % (count - 1);
      final gaps = List<int>.generate(
        count - 1,
        (i) => base + (i < leftover ? 1 : 0),
      );
      return _FlexSpacing(0, gaps, 0);
    case WrapAlignment.spaceAround:
      final total = baseGap * (count - 1) + extra;
      final base = total ~/ count;
      final leftover = total % count;
      final leading = base ~/ 2;
      final trailing = base - leading;
      final gaps = List<int>.generate(
        count - 1,
        (i) => base + (i < leftover ? 1 : 0),
      );
      return _FlexSpacing(leading, gaps, trailing);
    case WrapAlignment.spaceEvenly:
      final total = baseGap * (count - 1) + extra;
      final base = total ~/ (count + 1);
      final leftover = total % (count + 1);
      final leading = base + (leftover > 0 ? 1 : 0);
      final gaps = List<int>.generate(
        count - 1,
        (i) => base + (i + 1 < leftover ? 1 : 0),
      );
      final trailing = base + (leftover > count ? 1 : 0);
      return _FlexSpacing(leading, gaps, trailing);
  }
}

class _FlexSpacing {
  _FlexSpacing(this.leading, this.between, this.trailing);

  final int leading;
  final List<int> between;
  final int trailing;
}
