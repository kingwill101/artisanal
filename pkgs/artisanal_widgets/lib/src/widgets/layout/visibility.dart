part of 'layout_widgets.dart';

class Visibility extends Widget {
  Visibility({
    required this.child,
    this.visible = true,
    this.replacement,
    super.key,
  });

  final Widget child;
  final bool visible;
  final Widget? replacement;

  @override
  List<Widget> get children {
    if (visible) return [child];
    if (replacement != null) return [replacement!];
    return const [];
  }

  @override
  Object view() {
    if (visible) return child.view();
    return replacement?.view() ?? '';
  }
}
