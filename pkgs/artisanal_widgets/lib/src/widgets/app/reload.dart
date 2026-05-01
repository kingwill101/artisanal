import 'dart:async';

import 'package:artisanal/tui.dart' show Cmd, Msg;

import '../core/framework.dart';
import '../core/key.dart';
import '../core/widget.dart';

/// The kind of reload requested through [ReloadController].
enum ReloadMode {
  /// Rebuilds the subtree while preserving compatible state.
  reload,

  /// Forces the subtree to remount from scratch.
  restart,
}

/// One reload signal emitted by [ReloadController].
final class ReloadSignal {
  const ReloadSignal._({required this.mode, required this.revision});

  /// Creates a rebuild-preserving reload signal.
  const ReloadSignal.reload(int revision)
    : this._(mode: ReloadMode.reload, revision: revision);

  /// Creates a full restart signal.
  const ReloadSignal.restart(int revision)
    : this._(mode: ReloadMode.restart, revision: revision);

  /// Requested reload behavior.
  final ReloadMode mode;

  /// Monotonic revision counter.
  final int revision;
}

/// Controller for development-time subtree reloads.
///
/// This is a lightweight bridge for file watchers, editor tooling, or manual
/// key bindings. Pair it with [ReloadHost] to rebuild a subtree in place or
/// fully restart it.
final class ReloadController {
  final StreamController<ReloadSignal> _events =
      StreamController<ReloadSignal>.broadcast(sync: true);
  final Set<void Function(ReloadSignal signal)> _listeners =
      <void Function(ReloadSignal signal)>{};
  int _revision = 0;

  /// Current revision number.
  int get revision => _revision;

  /// Stream of reload signals.
  Stream<ReloadSignal> get stream => _events.stream;

  /// Adds a synchronous listener for reload events.
  void addListener(void Function(ReloadSignal signal) listener) {
    _listeners.add(listener);
  }

  /// Removes a previously added listener.
  void removeListener(void Function(ReloadSignal signal) listener) {
    _listeners.remove(listener);
  }

  /// Rebuilds the subtree while preserving compatible state.
  void reload() {
    _revision++;
    _emit(ReloadSignal.reload(_revision));
  }

  /// Restarts the subtree from scratch.
  void restart() {
    _revision++;
    _emit(ReloadSignal.restart(_revision));
  }

  void _emit(ReloadSignal signal) {
    _events.add(signal);
    for (final listener in List<void Function(ReloadSignal)>.from(_listeners)) {
      listener(signal);
    }
  }

  /// Closes the controller stream.
  Future<void> dispose() => _events.close();
}

/// Builder used by [ReloadHost].
typedef ReloadWidgetBuilder =
    Widget Function(BuildContext context, int revision);

/// Exposes a [ReloadController] to descendant widgets.
class ReloadScope extends InheritedWidget {
  ReloadScope({required this.controller, required super.child, super.key});

  final ReloadController controller;

  /// Returns the nearest controller, if any.
  static ReloadController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ReloadScope>()
        ?.controller;
  }

  /// Returns the nearest controller.
  static ReloadController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(controller != null, 'No ReloadScope found in the widget tree');
    return controller!;
  }

  @override
  bool updateShouldNotify(covariant ReloadScope oldWidget) {
    return controller != oldWidget.controller;
  }
}

/// Rebuildable host for development-time reloads.
///
/// Call [ReloadController.reload] to rerun [builder] while preserving
/// compatible state, or [ReloadController.restart] to force a full remount.
class ReloadHost extends StatefulWidget {
  ReloadHost({required this.controller, required this.builder, super.key});

  final ReloadController controller;
  final ReloadWidgetBuilder builder;

  @override
  State<ReloadHost> createState() => _ReloadHostState();
}

class _ReloadHostState extends State<ReloadHost> {
  int _revision = 0;
  Key _restartBoundaryKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _revision = widget.controller.revision;
  }

  @override
  Cmd? didUpdateWidget(covariant ReloadHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _revision = widget.controller.revision;
      _restartBoundaryKey = UniqueKey();
      return Cmd.listen<ReloadSignal>(
        widget.controller.stream,
        onData: _ReloadHostSignalMsg.new,
      );
    }
    return null;
  }

  @override
  Cmd? handleInit() {
    return Cmd.listen<ReloadSignal>(
      widget.controller.stream,
      onData: _ReloadHostSignalMsg.new,
    );
  }

  @override
  Cmd? handleUpdate(Msg msg) {
    if (msg is _ReloadHostSignalMsg) {
      setState(() {
        _revision = msg.signal.revision;
        if (msg.signal.mode == ReloadMode.restart) {
          _restartBoundaryKey = UniqueKey();
        }
      });
      return null;
    }
    return super.handleUpdate(msg);
  }

  @override
  Widget build(BuildContext context) {
    return ReloadScope(
      controller: widget.controller,
      child: _ReloadBoundary(
        key: _restartBoundaryKey,
        child: _ReloadBuilder(builder: widget.builder, revision: _revision),
      ),
    );
  }
}

class _ReloadBoundary extends StatelessWidget {
  _ReloadBoundary({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

class _ReloadBuilder extends StatelessWidget {
  _ReloadBuilder({required this.builder, required this.revision});

  final ReloadWidgetBuilder builder;
  final int revision;

  @override
  Widget build(BuildContext context) => builder(context, revision);
}

class _ReloadHostSignalMsg extends Msg {
  const _ReloadHostSignalMsg(this.signal);

  final ReloadSignal signal;
}
