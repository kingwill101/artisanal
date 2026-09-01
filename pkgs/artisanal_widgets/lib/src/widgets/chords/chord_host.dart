/// Hosts a [ChordController]: feeds lifecycle messages and rebuilds the tree.
library;

import 'package:artisanal/runtime.dart' as tui;

import '../core/framework.dart' show State, StatefulWidget;
import '../core/widget.dart' show Widget;
import 'chord_controller.dart';
import 'chord_scope.dart';

/// Wraps the app (or a subtree) so chord messages update [controller] and
/// descendants can call [ChordController.of] without manual wiring.
///
/// ```dart
/// ChordHost(
///   controller: chords,
///   onResolved: (id) { /* dispatch actions */ },
///   child: MyApp(),
/// )
/// ```
///
/// Place this high in the tree (above [Navigator] routes) so route widgets
/// see live pending state via [InheritedWidget], not stale constructor args.
class ChordHost extends StatefulWidget {
  ChordHost({
    required this.controller,
    required this.child,
    this.onResolved,
    super.key,
  });

  /// Shared controller (also used to build [ChordController.interceptor]).
  final ChordController controller;

  /// Called when a chord resolves to a binding [id].
  final void Function(String id)? onResolved;

  /// Subtree that can read [controller] via [ChordController.of].
  final Widget child;

  @override
  State createState() => _ChordHostState();
}

class _ChordHostState extends State<ChordHost> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  tui.Cmd? didUpdateWidget(covariant ChordHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
    return null;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (ChordController.isChordMessage(msg)) {
      final id = widget.controller.applyMessage(msg);
      if (id != null) {
        widget.onResolved?.call(id);
      }
    }
    return super.handleUpdate(msg);
  }

  @override
  Widget build(context) {
    return ChordScope(
      controller: widget.controller,
      child: widget.child,
    );
  }
}
