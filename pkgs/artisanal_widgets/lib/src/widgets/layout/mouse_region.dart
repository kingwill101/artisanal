part of 'layout_widgets.dart';

class MouseRegion extends StatelessWidget {
  MouseRegion({
    required this.child,
    this.onEnter,
    this.onExit,
    this.enabled = true,
    super.key,
  });

  final Widget child;
  final MouseEnterCallback? onEnter;
  final MouseExitCallback? onExit;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return GestureDetector(
      child: child,
      onEnter: onEnter,
      onExit: onExit,
      captureMouse: false,
    );
  }
}
