import 'flex.dart';

class Row extends Flex {
  Row({
    super.children = const [],
    super.gap = 0,
    super.mainAxisAlignment = .start,
    super.crossAxisAlignment = .start,
    super.mainAxisSize = .min,
    int? width,
    int? height,
    super.key,
  }) : super(
         direction: .horizontal,
         mainAxisExtent: width,
         crossAxisExtent: height,
       );
}
