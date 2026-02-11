part of 'layout_widgets.dart';

class Flexible extends Widget {
  Flexible({
    required this.child,
    this.flex = 1,
    this.fit = FlexFit.loose,
    super.key,
  });

  final Widget child;
  final int flex;
  final FlexFit fit;

  @override
  List<Widget> get children => [child];

  @override
  Object view() => child.view();
}
