import 'package:artisanal_widgets/src/widgets/rendering/render_object.dart';

import 'package:artisanal/widgets.dart';

import 'package:artisanal/tui.dart';
import 'package:artisanal/style.dart' show Color, Border, Style, Colors, Layout;

@Deprecated(
  'Use DialogRoute via Navigator.of(context).showDialog() instead. '
  'Will be removed in a future release.',
)
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
    final theme = ThemeScope.of(context);

    // Blend the background content toward the backdrop color so the dialog
    // stands out while keeping the underlying content visible.
    final dimmedChild = backdropOpacity < 1.0 && backdropOpacity > 0.0
        ? Tint(
            color: backdropColor ?? theme.background,
            opacity: backdropOpacity,
            child: child,
          )
        : child;

    // Prevent pointer/scroll events from leaking to background content while
    // a modal is open. The dismiss layer and dialog remain interactive.
    final blockedBackground = _ModalInputBlocker(
      child: IgnorePointer(
        ignoring: true,
        child: _FrozenBackdropHost(frozen: true, child: dimmedChild),
      ),
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
        Positioned(left: 0, right: 0, top: 0, bottom: 0, child: dismissLayer),
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
    return switch (msg) {
      WindowSizeMsg() || BackgroundColorMsg() || ColorProfileMsg() => null,
      _ => Cmd.none(),
    };
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _FrozenBackdropHost extends StatefulWidget {
  _FrozenBackdropHost({required this.frozen, required this.child});

  final bool frozen;
  final Widget child;

  @override
  State createState() => _FrozenBackdropHostState();
}

class _FrozenBackdropHostState extends State<_FrozenBackdropHost> {
  Widget? _capturedChild;

  @override
  void initState() {
    super.initState();
    _capturedChild = widget.child;
  }

  @override
  Cmd? didUpdateWidget(covariant _FrozenBackdropHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.frozen) {
      _capturedChild = widget.child;
      return null;
    }
    if (!oldWidget.frozen) {
      _capturedChild = widget.child;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveChild = widget.frozen
        ? (_capturedChild ?? widget.child)
        : widget.child;
    return _FrozenBackdrop(frozen: widget.frozen, child: effectiveChild);
  }
}

class _FrozenBackdrop extends SingleChildRenderObjectWidget {
  _FrozenBackdrop({required this.frozen, super.child});

  final bool frozen;

  @override
  Object view() => '';

  @override
  RenderObject createRenderObject() {
    return _RenderFrozenBackdrop(frozen: frozen);
  }

  @override
  void updateRenderObject(RenderObject renderObject) {
    (renderObject as _RenderFrozenBackdrop).frozen = frozen;
  }
}

class _RenderFrozenBackdrop extends RenderBox {
  _RenderFrozenBackdrop({required bool frozen}) : _frozen = frozen;

  bool _frozen;
  String? _snapshotPaint;
  Size _snapshotSize = Size.zero;
  BoxConstraints? _snapshotConstraints;

  RenderObject? get _child => children.isEmpty ? null : children.first;

  set frozen(bool value) {
    if (_frozen == value) return;
    _frozen = value;
    if (!value) {
      _snapshotPaint = null;
      _snapshotConstraints = null;
      _snapshotSize = Size.zero;
    }
  }

  @override
  void layout(BoxConstraints constraints) {
    super.layout(constraints);
    if (_frozen &&
        _snapshotPaint != null &&
        _snapshotConstraints == constraints) {
      size = constraints.constrain(_snapshotSize);
      return;
    }

    final child = _child;
    if (child == null) {
      _snapshotPaint = '';
      _snapshotConstraints = constraints;
      _snapshotSize = constraints.constrain(Size.zero);
      size = _snapshotSize;
      return;
    }

    child.layout(constraints);
    final content = child.paint();
    final resolvedSize = constraints.constrain(
      Size(
        Layout.getWidth(content).toDouble(),
        Layout.getHeight(content).toDouble(),
      ),
    );
    size = resolvedSize;
    _snapshotConstraints = constraints;
    _snapshotSize = resolvedSize;
    if (_frozen) {
      _snapshotPaint = content;
    }
  }

  @override
  String paint() {
    final cached = _snapshotPaint;
    if (_frozen && cached != null) return cached;
    final content = _child?.paint() ?? '';
    if (_frozen) {
      _snapshotPaint = content;
    }
    return content;
  }
}
