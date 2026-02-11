part of 'layout_widgets.dart';

class Expanded extends Flexible {
  Expanded({required super.child, super.flex, super.key})
    : super(fit: FlexFit.tight);
}
