import 'dart:async';
import 'package:artisanal/runtime.dart' show Cmd;
import '../core/framework.dart' show BuildContext, StatefulWidget, State;
import '../core/widget.dart';

enum AsyncConnectionState { none, waiting, active, done }

final class AsyncSnapshot<T> {
  const AsyncSnapshot._({
    required this.connectionState,
    this.data,
    this.error,
    this.stackTrace,
  });

  const AsyncSnapshot.nothing()
    : this._(connectionState: AsyncConnectionState.none);

  const AsyncSnapshot.withData(AsyncConnectionState state, T data)
    : this._(connectionState: state, data: data);

  const AsyncSnapshot.withError(
    AsyncConnectionState state,
    Object error, [
    StackTrace? stackTrace,
  ]) : this._(connectionState: state, error: error, stackTrace: stackTrace);

  final AsyncConnectionState connectionState;
  final T? data;
  final Object? error;
  final StackTrace? stackTrace;

  bool get hasData => data != null;
  bool get hasError => error != null;

  AsyncSnapshot<T> inState(AsyncConnectionState state) {
    return AsyncSnapshot<T>._(
      connectionState: state,
      data: data,
      error: error,
      stackTrace: stackTrace,
    );
  }
}

typedef AsyncWidgetBuilder<T> =
    Widget Function(BuildContext context, AsyncSnapshot<T> snapshot);

class FutureBuilder<T> extends StatefulWidget {
  FutureBuilder({
    required this.builder,
    this.future,
    this.initialData,
    super.key,
  });

  final Future<T>? future;
  final T? initialData;
  final AsyncWidgetBuilder<T> builder;

  @override
  State<FutureBuilder<T>> createState() => _FutureBuilderState<T>();
}

class _FutureBuilderState<T> extends State<FutureBuilder<T>> {
  Object? _activeToken;
  late AsyncSnapshot<T> _snapshot;

  @override
  void initState() {
    super.initState();
    final initialData = widget.initialData;
    _snapshot = initialData == null
        ? AsyncSnapshot<T>.nothing()
        : AsyncSnapshot<T>.withData(AsyncConnectionState.none, initialData);
  }

  @override
  Cmd? handleInit() => _subscribe();

  @override
  Cmd? didUpdateWidget(covariant FutureBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.future != oldWidget.future) {
      return _subscribe();
    }
    return null;
  }

  Cmd? _subscribe() {
    final future = widget.future;
    _activeToken = null;
    if (future == null) {
      setState(() {
        _snapshot = _snapshot.inState(AsyncConnectionState.none);
      });
      return null;
    }

    final token = Object();
    _activeToken = token;
    setState(() {
      _snapshot = _snapshot.inState(AsyncConnectionState.waiting);
    });

    return Cmd(() async {
      try {
        final value = await future;
        if (!mounted || !identical(_activeToken, token)) {
          return null;
        }
        setState(() {
          _snapshot = AsyncSnapshot<T>.withData(
            AsyncConnectionState.done,
            value,
          );
        });
      } on Object catch (error, stackTrace) {
        if (!mounted || !identical(_activeToken, token)) {
          return null;
        }
        setState(() {
          _snapshot = AsyncSnapshot<T>.withError(
            AsyncConnectionState.done,
            error,
            stackTrace,
          );
        });
      }
      return null;
    });
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _snapshot);
}

class StreamBuilder<T> extends StatefulWidget {
  StreamBuilder({
    required this.builder,
    this.stream,
    this.initialData,
    super.key,
  });

  final Stream<T>? stream;
  final T? initialData;
  final AsyncWidgetBuilder<T> builder;

  @override
  State<StreamBuilder<T>> createState() => _StreamBuilderState<T>();
}

class _StreamBuilderState<T> extends State<StreamBuilder<T>> {
  StreamSubscription<T>? _subscription;
  Stream<T>? _subscribedStream;
  Object? _activeToken;
  late AsyncSnapshot<T> _snapshot;

  @override
  void initState() {
    super.initState();
    final initialData = widget.initialData;
    _snapshot = initialData == null
        ? AsyncSnapshot<T>.nothing()
        : AsyncSnapshot<T>.withData(AsyncConnectionState.none, initialData);
  }

  @override
  Cmd? handleInit() => _subscribe();

  @override
  Cmd? didUpdateWidget(covariant StreamBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stream != oldWidget.stream) {
      return _subscribe();
    }
    return null;
  }

  @override
  void dispose() {
    _activeToken = null;
    unawaited(_subscription?.cancel());
    _subscription = null;
    _subscribedStream = null;
    super.dispose();
  }

  Cmd? _subscribe() {
    final stream = widget.stream;
    if (_subscription != null && identical(_subscribedStream, stream)) {
      return null;
    }

    _activeToken = null;
    unawaited(_subscription?.cancel());
    _subscription = null;
    _subscribedStream = null;

    if (stream == null) {
      setState(() {
        _snapshot = _snapshot.inState(AsyncConnectionState.none);
      });
      return null;
    }

    final token = Object();
    _activeToken = token;
    _subscribedStream = stream;
    setState(() {
      _snapshot = _snapshot.inState(AsyncConnectionState.waiting);
    });
    _subscription = stream.listen(
      (value) {
        if (!mounted || !identical(_activeToken, token)) return;
        setState(() {
          _snapshot = AsyncSnapshot<T>.withData(
            AsyncConnectionState.active,
            value,
          );
        });
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!mounted || !identical(_activeToken, token)) return;
        setState(() {
          _snapshot = AsyncSnapshot<T>.withError(
            AsyncConnectionState.active,
            error,
            stackTrace,
          );
        });
      },
      onDone: () {
        if (!mounted || !identical(_activeToken, token)) return;
        setState(() {
          _snapshot = _snapshot.inState(AsyncConnectionState.done);
        });
      },
      cancelOnError: false,
    );
    return null;
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _snapshot);
}
