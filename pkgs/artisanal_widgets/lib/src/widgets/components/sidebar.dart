part of 'components_widgets.dart';

enum SidebarSide { left, right }

class Sidebar extends StatelessWidget {
  Sidebar({
    required this.sidebar,
    required this.child,
    this.width = 24,
    this.gap = 1,
    this.side = SidebarSide.left,
    super.key,
  });

  final Widget sidebar;
  final Widget child;
  final int width;
  final int gap;
  final SidebarSide side;

  @override
  Widget build(BuildContext context) {
    final bar = SizedBox(width: width, child: sidebar);
    final spacer = gap > 0 ? SizedBox(width: gap) : SizedBox.shrink();
    return Row(
      gap: 0,
      children: side == SidebarSide.left
          ? [bar, spacer, Expanded(child: child)]
          : [Expanded(child: child), spacer, bar],
    );
  }
}
