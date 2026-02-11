part of 'layout_widgets.dart';

class ShrinkWrap extends Widget {
  ShrinkWrap({required this.child, super.key});

  final Widget child;

  @override
  List<Widget> get children => [child];

  @override
  Object view() => child.view();
}
