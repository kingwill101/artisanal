part of 'components_widgets.dart';

class Drawer extends StatelessWidget {
  Drawer({
    required this.child,
    required this.drawer,
    this.open = false,
    this.width = 28,
    this.side = SidebarSide.left,
    this.onDismiss,
    this.dismissible = true,
    this.backdropColor,
    this.backdropOpacity = 0.6,
    super.key,
  });

  final Widget child;
  final Widget drawer;
  final bool open;
  final int width;
  final SidebarSide side;
  final CmdCallback? onDismiss;
  final bool dismissible;
  final Color? backdropColor;
  final double backdropOpacity;

  @override
  Widget build(BuildContext context) {
    if (!open) return child;
    final theme = ThemeScope.of(context);
    final backdrop = GestureDetector(
      onTap: dismissible ? () => onDismiss?.call() : null,
      child: Opacity(
        opacity: backdropOpacity,
        child: Container(color: backdropColor ?? theme.background),
      ),
    );

    final panel = SizedBox(width: width, child: drawer);
    final positioned = side == SidebarSide.left
        ? Positioned(left: 0, top: 0, bottom: 0, width: width, child: panel)
        : Positioned(right: 0, top: 0, bottom: 0, width: width, child: panel);

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: 0,
          child: backdrop,
        ),
        positioned,
      ],
    );
  }
}
