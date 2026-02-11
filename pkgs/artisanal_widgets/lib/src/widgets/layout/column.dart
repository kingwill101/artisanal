part of 'layout_widgets.dart';

class Column extends Flex {
  Column({
    super.children = const [],
    super.gap = 0,
    super.mainAxisAlignment = MainAxisAlignment.start,
    super.crossAxisAlignment = CrossAxisAlignment.start,
    super.mainAxisSize = MainAxisSize.min,
    int? width,
    int? height,
    super.key,
  }) : super(
         direction: Axis.vertical,
         mainAxisExtent: height,
         crossAxisExtent: width,
       );
}
