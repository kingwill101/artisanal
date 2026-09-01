/// Provides a [tui.KeymapHub] to descendants and rebuilds on stack/pending.
library;

import 'package:artisanal/runtime.dart' as tui;

import '../core/framework.dart'
    show BuildContext, InheritedWidget, State, StatefulWidget;
import '../core/widget.dart' show Widget;
import '../focus/focus.dart' show FocusScope;
import '../layout/center.dart';
import '../layout/container.dart';
import '../layout/enums.dart' show StackFit;
import '../layout/gesture_detector.dart';
import '../layout/ignore_pointer.dart';
import '../layout/opacity.dart';
import '../layout/positioned.dart';
import '../layout/stack.dart';
import 'shortcuts_sheet.dart';

/// Inherited access to the app [tui.KeymapHub].
///
/// Prefer constructing via [KeymapHubScope]. Snapshots pending state so
/// [updateShouldNotify] works with a mutable hub.
class KeymapHubInherited extends InheritedWidget {
  KeymapHubInherited({
    required this.hub,
    required this.generation,
    required this.isSequencePending,
    required this.pendingPrefixLabel,
    required this.helpSheetOpen,
    required super.child,
    super.key,
  });

  final tui.KeymapHub hub;
  final int generation;
  final bool isSequencePending;
  final String pendingPrefixLabel;
  final bool helpSheetOpen;

  static KeymapHubInherited? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<KeymapHubInherited>();
  }

  @override
  bool updateShouldNotify(covariant KeymapHubInherited oldWidget) {
    return hub != oldWidget.hub ||
        generation != oldWidget.generation ||
        isSequencePending != oldWidget.isSequencePending ||
        pendingPrefixLabel != oldWidget.pendingPrefixLabel ||
        helpSheetOpen != oldWidget.helpSheetOpen;
  }
}

/// Hosts a [tui.KeymapHub]: listens for stack/pending changes, handles
/// [tui.KeymapActionMsg], and exposes the hub via [KeymapHubScope.maybeOf].
///
/// When [helpActionId] matches a resolved action (default
/// [tui.shortcutHelpActionId]), toggles an overlay [ShortcutsSheet] built
/// from the active surface bindings.
///
/// **Important:** the app child (e.g. [Navigator]) stays at a fixed slot in
/// the tree when the help sheet opens/closes so route state is preserved.
///
/// ```dart
/// final hub = tui.KeymapHub();
/// // ProgramOptions(interceptor: hub)
///
/// KeymapHubScope(
///   hub: hub,
///   onAction: (id, surfaceId) { /* dispatch */ },
///   child: ShortcutSurfaceScope(
///     surfaceId: 'session',
///     bindings: [
///       ...sessionBindings,
///       tui.ShortcutBinding.help(), // ?
///     ],
///     child: SessionShell(...),
///   ),
/// )
/// ```
class KeymapHubScope extends StatefulWidget {
  KeymapHubScope({
    required this.hub,
    required this.child,
    this.onAction,
    this.helpActionId = tui.shortcutHelpActionId,
    this.includeReachableInHelp = false,
    this.helpSheetTitle = 'Shortcuts',
    super.key,
  });

  final tui.KeymapHub hub;
  final Widget child;

  /// Called when a [tui.KeymapActionMsg] is resolved (after built-in help).
  final void Function(String id, String surfaceId)? onAction;

  /// Action id that toggles the shortcuts sheet.
  ///
  /// Set to `null` to disable built-in help handling.
  final String? helpActionId;

  /// When true, help sheet includes lower non-exclusive surfaces.
  final bool includeReachableInHelp;

  final String helpSheetTitle;

  /// Nearest hub from the tree, or `null`.
  static tui.KeymapHub? maybeOf(BuildContext context) {
    return KeymapHubInherited.maybeOf(context)?.hub;
  }

  /// Nearest hub; asserts if missing.
  static tui.KeymapHub of(BuildContext context) {
    final hub = maybeOf(context);
    assert(hub != null, 'KeymapHubScope.of() called with no KeymapHubScope');
    return hub!;
  }

  /// Whether the help sheet is currently open on the nearest scope.
  static bool isHelpSheetOpen(BuildContext context) {
    return KeymapHubInherited.maybeOf(context)?.helpSheetOpen ?? false;
  }

  @override
  State createState() => _KeymapHubScopeState();
}

class _KeymapHubScopeState extends State<KeymapHubScope> {
  int _generation = 0;
  bool _helpOpen = false;

  @override
  void initState() {
    super.initState();
    widget.hub.addListener(_onHubChanged);
  }

  @override
  tui.Cmd? didUpdateWidget(covariant KeymapHubScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.hub, widget.hub)) {
      oldWidget.hub.removeListener(_onHubChanged);
      widget.hub.addListener(_onHubChanged);
      _generation++;
    }
    return null;
  }

  @override
  void dispose() {
    widget.hub.removeListener(_onHubChanged);
    super.dispose();
  }

  void _onHubChanged() {
    if (!mounted) return;
    setState(() => _generation++);
  }

  void _toggleHelp() {
    setState(() {
      _helpOpen = !_helpOpen;
      _generation++;
    });
  }

  void _closeHelp() {
    if (!_helpOpen) return;
    setState(() {
      _helpOpen = false;
      _generation++;
    });
  }

  @override
  tui.Cmd? handleIntercept(tui.Msg msg) {
    // Capture esc before children when the help sheet is open.
    if (_helpOpen && msg is tui.KeyMsg && msg.key.isEscape) {
      _closeHelp();
      return tui.Cmd.none();
    }
    return super.handleIntercept(msg);
  }

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.BatchMsg) {
      for (final m in msg.messages) {
        handleUpdate(m);
      }
      return super.handleUpdate(msg);
    }

    if (msg is tui.KeymapActionMsg) {
      final helpId = widget.helpActionId;
      if (helpId != null && msg.id == helpId) {
        _toggleHelp();
        return tui.Cmd.none();
      }
      widget.onAction?.call(msg.id, msg.surfaceId);
      if (mounted) setState(() => _generation++);
    } else if (msg is tui.KeymapSequencePrefixMsg) {
      if (mounted) setState(() => _generation++);
    } else if (msg is tui.KeymapSequenceCancelledMsg) {
      // Tests may inject cancel without going through hub.onSend.
      if (widget.hub.isSequencePending) {
        widget.hub.resetPending();
      }
      if (mounted) setState(() => _generation++);
    }

    return super.handleUpdate(msg);
  }

  @override
  @override
  Widget build(BuildContext context) {
    final hub = widget.hub;

    // Keep a stable tree shape: app content is always the first stack child
    // so Navigator/route State survives help open/close. (The old Modal
    // helper returned bare [child] when closed vs Stack when open, which
    // remounted the navigator and reset to the initial route.)
    return Stack(
      fit: StackFit.expand,
      children: [
        KeymapHubInherited(
          hub: hub,
          generation: _generation,
          isSequencePending: hub.isSequencePending,
          pendingPrefixLabel: hub.pendingPrefixLabel,
          helpSheetOpen: _helpOpen,
          child: Opacity(
            // Dim slightly when help is open without remounting.
            opacity: _helpOpen ? 0.45 : 1.0,
            child: IgnorePointer(
              ignoring: _helpOpen,
              child: widget.child,
            ),
          ),
        ),
        if (_helpOpen) ...[
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () {
                _closeHelp();
                return null;
              },
              // Transparent hit target for backdrop dismiss.
              child: Container(),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: FocusScope(
                isTrapped: true,
                child: ShortcutsSheet.forHub(
                  hub,
                  includeReachable: widget.includeReachableInHelp,
                  title: widget.helpSheetTitle,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
