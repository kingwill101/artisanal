part of 'layout_widgets.dart';

class ShrinkWrap extends Widget {
  ShrinkWrap({required this.child, super.key});

  final Widget child;

  @override
  bool get debugRenderObjectPassthrough => true;

  @override
  List<Widget> get children => [child];

  @override
  Object view() => child.view();
}
