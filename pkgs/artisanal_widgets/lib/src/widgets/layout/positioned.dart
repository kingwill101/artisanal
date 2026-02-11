part of 'layout_widgets.dart';

class Positioned extends Widget {
  Positioned({
    required this.child,
    this.left,
    this.right,
    this.top,
    this.bottom,
    this.width,
    this.height,
    super.key,
  });

  final Widget child;
  final num? left;
  final num? right;
  final num? top;
  final num? bottom;
  final num? width;
  final num? height;

  @override
  List<Widget> get children => [child];

  @override
  Object view() => child.view();
}
