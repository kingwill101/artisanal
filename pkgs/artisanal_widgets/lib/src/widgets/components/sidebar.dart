import 'package:artisanal_widgets/src/widgets/core/widget.dart';
import 'package:artisanal_widgets/src/widgets/framework.dart';
import 'package:artisanal_widgets/src/widgets/layout/_layout_core.dart';

/// Placement side for the sidebar content.
enum SidebarSide { left, right }

/// A fixed-width sidebar adjacent to the main content.
///
/// The [Sidebar] arranges its [child] and [sidebar] in a horizontal [Row]
/// with a [gap] between them. The sidebar is placed on [side] and has a fixed
/// [width] in cells.
///
/// Example:
/// ```dart
/// Sidebar(
///   sidebar: ListView(
///     children: [NavigationItem('Home'), NavigationItem('Settings')],
///   ),
///   child: ContentArea(),
///   width: 20,
/// )
/// ```
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
