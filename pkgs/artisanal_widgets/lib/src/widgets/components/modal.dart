part of 'components_widgets.dart';

class Modal extends StatelessWidget {
  Modal({
    required this.child,
    required this.dialog,
    this.open = false,
    this.onDismiss,
    this.dismissible = true,
    this.backdropColor,
    this.backdropOpacity = 0.6,
    super.key,
  });

  final Widget child;
  final Widget dialog;
  final bool open;
  final CmdCallback? onDismiss;
  final bool dismissible;
  final Color? backdropColor;
  final double backdropOpacity;

  @override
  Widget build(BuildContext context) {
    if (!open) return child;

    // Dim the background content so the dialog stands out.
    // In a terminal we cannot do true alpha blending, so Opacity applies
    // Style().dim() to the child content, letting it remain visible but
    // visually receded behind the dialog.
    final dimmedChild = backdropOpacity < 1.0 && backdropOpacity > 0.0
        ? Opacity(opacity: backdropOpacity, child: child)
        : child;

    // Prevent pointer/scroll events from leaking to background content while
    // a modal is open. The dismiss layer and dialog remain interactive.
    final blockedBackground = _ModalInputBlocker(
      child: IgnorePointer(ignoring: true, child: dimmedChild),
    );

    // Transparent dismiss layer — sized to fill the stack but paints nothing,
    // so the dimmed child shows through.
    final dismissLayer = dismissible
        ? GestureDetector(onTap: () => onDismiss?.call(), child: Container())
        : Container();

    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        blockedBackground,
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: 0,
          child: dismissLayer,
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: 0,
          child: Center(child: FocusScope(isTrapped: true, child: dialog)),
        ),
      ],
    );
  }
}

class _ModalInputBlocker extends StatefulWidget {
  _ModalInputBlocker({required this.child});

  final Widget child;

  @override
  State createState() => _ModalInputBlockerState();
}

class _ModalInputBlockerState extends State<_ModalInputBlocker> {
  @override
  Cmd? handleIntercept(Msg msg) {
    if (msg is KeyMsg || msg is MouseMsg) {
      return Cmd.none();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
