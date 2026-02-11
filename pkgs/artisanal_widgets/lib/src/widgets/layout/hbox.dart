part of 'layout_widgets.dart';

class HBox extends Row {
  HBox({
    required super.children,
    super.gap = 1,
    VerticalAlign align = VerticalAlign.top,
    super.key,
  }) : super(crossAxisAlignment: _crossFromVertical(align));
}

CrossAxisAlignment _crossFromVertical(VerticalAlign align) {
  return switch (align) {
    VerticalAlign.top => CrossAxisAlignment.start,
    VerticalAlign.center => CrossAxisAlignment.center,
    VerticalAlign.bottom => CrossAxisAlignment.end,
  };
}
