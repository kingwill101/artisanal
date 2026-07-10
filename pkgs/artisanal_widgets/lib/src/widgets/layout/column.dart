import 'flex.dart';

class Column extends Flex {
  Column({
    super.children = const [],
    super.gap = 0,
    super.mainAxisAlignment = .start,
    super.crossAxisAlignment = .start,
    super.mainAxisSize = .min,
    int? width,
    int? height,
    super.key,
  }) : super(
         direction: .vertical,
         mainAxisExtent: height,
         crossAxisExtent: width,
       );
}
