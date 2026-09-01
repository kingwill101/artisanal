import 'package:artisanal/style.dart' show Color;
import '_component_foundation.dart';
import 'sidebar.dart';

/// A slide-out panel that overlays content from the left or right.
///
/// The [Drawer] displays its [child] with an optional dimmed backdrop and
/// reveals the [drawer] widget from [side] when [open] is `true`.
///
/// The drawer is dismissible by clicking the backdrop when [dismissible] is true.
/// Use [width] to control the drawer's width in cells.
///
/// Example:
/// ```dart
/// Drawer(
///   open: _showSidebar,
///   side: SidebarSide.left,
///   drawer: ListView(
///     children: [Text('Menu Item 1'), Text('Menu Item 2')],
///   ),
///   child: MainContent(),
/// )

// ignore_for_file: unused_shown_name
/// ```
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
    final dimmedChild = backdropOpacity > 0.0
        ? Tint(
            color: backdropColor ?? theme.background,
            opacity: backdropOpacity,
            child: child,
          )
        : child;

    final dismissLayer = dismissible
        ? GestureDetector(onTap: () => onDismiss?.call(), child: Container())
        : Container();

    final panel = SizedBox(width: width, child: drawer);
    final positioned = side == SidebarSide.left
        ? Positioned(left: 0, top: 0, bottom: 0, width: width, child: panel)
        : Positioned(right: 0, top: 0, bottom: 0, width: width, child: panel);

    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(ignoring: true, child: dimmedChild),
        Positioned(left: 0, right: 0, top: 0, bottom: 0, child: dismissLayer),
        positioned,
      ],
    );
  }
}
