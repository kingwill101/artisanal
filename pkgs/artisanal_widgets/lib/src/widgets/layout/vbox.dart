import '../style.dart';
import 'column.dart';
import 'enums.dart';

class VBox extends Column {
  VBox({
    required super.children,
    super.gap = 0,
    HorizontalAlign align = HorizontalAlign.left,
    super.key,
  }) : super(crossAxisAlignment: _crossFromHorizontal(align));
}

CrossAxisAlignment _crossFromHorizontal(HorizontalAlign align) {
  return switch (align) {
    HorizontalAlign.left => CrossAxisAlignment.start,
    HorizontalAlign.center => CrossAxisAlignment.center,
    HorizontalAlign.right => CrossAxisAlignment.end,
  };
}
