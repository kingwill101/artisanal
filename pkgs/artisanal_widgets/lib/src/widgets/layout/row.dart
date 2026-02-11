part of 'layout_widgets.dart';

class Row extends Flex {
  Row({
    super.children = const [],
    super.gap = 0,
    super.mainAxisAlignment = MainAxisAlignment.start,
    super.crossAxisAlignment = CrossAxisAlignment.start,
    super.mainAxisSize = MainAxisSize.min,
    int? width,
    int? height,
    super.key,
  }) : super(
         direction: Axis.horizontal,
         mainAxisExtent: width,
         crossAxisExtent: height,
       );
}
