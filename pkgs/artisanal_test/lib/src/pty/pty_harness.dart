import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'pty_backend.dart';
import 'pty_event.dart';
import 'pty_spawn_request.dart';
import 'pty_trace.dart';

/// Creates PTY sessions using an injected backend implementation.
final class PtyHarness {
  /// Creates a harness backed by [backendFactory].
  const PtyHarness({required this.backendFactory});

  /// Factory responsible for creating the real or fake PTY process.
  final PtyBackendFactory backendFactory;

  /// Spawns and immediately attaches to a PTY session.
  Future<PtySession> spawn(PtySpawnRequest request) async {
    final backend = await backendFactory(request);
    return PtySession._attach(request: request, backend: backend);
  }
}

/// A live PTY interaction with byte capture and deterministic event ordering.
final class PtySession {
  PtySession._({required this.request, required PtyBackend backend})
    : _backend = backend;

  static PtySession _attach({
    required PtySpawnRequest request,
    required PtyBackend backend,
  }) {
    final session = PtySession._(request: request, backend: backend);
    session._outputSubscription = backend.output.listen(
      session._handleOutput,
      onError: session._handleOutputError,
      onDone: session._handleOutputDone,
    );
    unawaited(session._watchExit());
    return session;
  }

  /// Spawn request used to create this session.
  final PtySpawnRequest request;

  final PtyBackend _backend;
  final Stopwatch _clock = Stopwatch()..start();
  final List<int> _output = <int>[];
  final List<PtyEvent> _capturedEvents = <PtyEvent>[];
  final StreamController<PtyEvent> _eventController =
      StreamController<PtyEvent>.broadcast(sync: true);
  final StreamController<void> _stateController =
      StreamController<void>.broadcast(sync: true);
  final Completer<int> _exitCompleter = Completer<int>();

  late final StreamSubscription<Uint8List> _outputSubscription;
  Future<PtyTrace>? _closeFuture;
  Object? _outputError;
  StackTrace? _outputErrorStack;
  bool _outputDone = false;
  bool _closing = false;
  bool _closed = false;

  /// Broadcast stream of newly captured events.
  ///
  /// Events emitted before a listener subscribes remain available through
  /// [trace] and [outputBytes].
  Stream<PtyEvent> get events => _eventController.stream;

  /// Whether the backend output stream has closed.
  bool get isOutputDone => _outputDone;

  /// Whether [close] has completed.
  bool get isClosed => _closed;

  /// Concatenated output received so far.
  Uint8List get outputBytes => Uint8List.fromList(_output);

  /// Convenience UTF-8 view of [outputBytes].
  String get outputText => utf8.decode(outputBytes, allowMalformed: true);

  /// Immutable trace snapshot of the session's current state.
  PtyTrace get trace => PtyTrace(request: request, events: _capturedEvents);

  /// Writes [bytes] and records them after the backend accepts the write.
  Future<void> sendBytes(List<int> bytes) async {
    _ensureInteractive();
    final copy = Uint8List.fromList(bytes);
    await _backend.write(copy);
    _record(PtyInputEvent(elapsed: _clock.elapsed, bytes: copy));
  }

  /// UTF-8 encodes [text], writes it, and records the exact encoded bytes.
  Future<void> sendText(String text) => sendBytes(utf8.encode(text));

  /// Resizes the PTY and records the successful size change.
  Future<void> resize({required int columns, required int rows}) async {
    _ensureInteractive();
    _validateTerminalSize(columns: columns, rows: rows);
    await _backend.resize(columns: columns, rows: rows);
    _record(
      PtyResizeEvent(
        elapsed: _clock.elapsed,
        columns: columns,
        rows: rows,
      ),
    );
  }

  /// Waits until [pattern] appears in cumulative output.
  ///
  /// Matching is independent of backend stream chunk boundaries. The returned
  /// snapshot contains all output available at the moment the match is found.
  Future<PtyOutputMatch> waitForOutput(
    List<int> pattern, {
    Duration timeout = const Duration(seconds: 5),
  }) {
    _ensureReadable();
    if (pattern.isEmpty) {
      throw ArgumentError.value(pattern, 'pattern', 'Must not be empty.');
    }
    if (timeout <= Duration.zero) {
      throw ArgumentError.value(timeout, 'timeout', 'Must be positive.');
    }

    final needle = Uint8List.fromList(pattern);
    final completer = Completer<PtyOutputMatch>();
    StreamSubscription<void>? subscription;
    Timer? timer;

    void completeFromCurrentOutput() {
      if (completer.isCompleted) {
        return;
      }
      final outputError = _outputError;
      if (outputError != null) {
        completer.completeError(
          outputError,
          _outputErrorStack ?? StackTrace.current,
        );
        return;
      }

      final start = _indexOfBytes(_output, needle);
      if (start >= 0) {
        completer.complete(
          PtyOutputMatch(
            start: start,
            end: start + needle.length,
            output: _output,
          ),
        );
        return;
      }

      if (_outputDone) {
        completer.completeError(
          PtyOutputClosedException(
            pattern: needle,
            output: _output,
          ),
        );
      }
    }

    subscription = _stateController.stream.listen(
      (_) => completeFromCurrentOutput(),
      onError: (Object error, StackTrace stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      },
      onDone: completeFromCurrentOutput,
    );

    // Subscribe first, then inspect the cumulative buffer so output cannot be
    // lost in the gap between an initial check and listener registration.
    completeFromCurrentOutput();

    if (!completer.isCompleted) {
      timer = Timer(timeout, () {
        if (!completer.isCompleted) {
          completer.completeError(
            PtyTimeoutException(
              operation: 'waiting for PTY output',
              timeout: timeout,
              output: outputBytes,
            ),
          );
        }
      });
    }

    return completer.future.whenComplete(() async {
      timer?.cancel();
      await subscription?.cancel();
    });
  }

  /// UTF-8 encodes [text] and waits for it in cumulative output.
  Future<PtyOutputMatch> waitForText(
    String text, {
    Duration timeout = const Duration(seconds: 5),
  }) => waitForOutput(utf8.encode(text), timeout: timeout);

  /// Waits for the child exit code.
  Future<int> waitForExit({Duration? timeout}) {
    final future = _exitCompleter.future;
    if (timeout == null) {
      return future;
    }
    if (timeout <= Duration.zero) {
      throw ArgumentError.value(timeout, 'timeout', 'Must be positive.');
    }
    return future.timeout(
      timeout,
      onTimeout: () => throw PtyTimeoutException(
        operation: 'waiting for PTY exit',
        timeout: timeout,
        output: outputBytes,
      ),
    );
  }

  /// Requests child termination without closing the session immediately.
  Future<void> kill() async {
    _ensureInteractive();
    await _backend.kill();
  }

  /// Closes the backend and returns the final trace snapshot.
  ///
  /// When [terminate] is true, a best-effort termination request is sent before
  /// resources are closed. [exitGracePeriod] allows backends a brief interval
  /// to report the exit event after close begins.
  Future<PtyTrace> close({
    bool terminate = true,
    Duration exitGracePeriod = const Duration(milliseconds: 250),
  }) {
    if (exitGracePeriod < Duration.zero) {
      throw ArgumentError.value(
        exitGracePeriod,
        'exitGracePeriod',
        'Must not be negative.',
      );
    }
    return _closeFuture ??= _close(
      terminate: terminate,
      exitGracePeriod: exitGracePeriod,
    );
  }

  Future<PtyTrace> _close({
    required bool terminate,
    required Duration exitGracePeriod,
  }) async {
    _closing = true;
    Object? firstError;
    StackTrace? firstStackTrace;

    if (terminate && !_exitCompleter.isCompleted) {
      try {
        await _backend.kill();
      } catch (error, stackTrace) {
        firstError = error;
        firstStackTrace = stackTrace;
      }
    }

    try {
      await _backend.close();
    } catch (error, stackTrace) {
      firstError ??= error;
      firstStackTrace ??= stackTrace;
    }

    if (!_exitCompleter.isCompleted && exitGracePeriod > Duration.zero) {
      try {
        await _exitCompleter.future.timeout(exitGracePeriod);
      } on TimeoutException {
        // Some backends cannot report an exit code once forcibly closed. The
        // trace remains valid without an exit event.
      } catch (error, stackTrace) {
        firstError ??= error;
        firstStackTrace ??= stackTrace;
      }
    }

    await _outputSubscription.cancel();
    _outputDone = true;
    if (!_stateController.isClosed) {
      _stateController.add(null);
    }
    _clock.stop();
    _closed = true;
    await _stateController.close();
    await _eventController.close();

    if (firstError != null) {
      Error.throwWithStackTrace(firstError, firstStackTrace!);
    }
    return trace;
  }

  Future<void> _watchExit() async {
    try {
      final exitCode = await _backend.exitCode;
      if (_exitCompleter.isCompleted) {
        return;
      }
      _record(PtyExitEvent(elapsed: _clock.elapsed, exitCode: exitCode));
      _exitCompleter.complete(exitCode);
    } catch (error, stackTrace) {
      if (!_exitCompleter.isCompleted) {
        _exitCompleter.completeError(error, stackTrace);
      }
      if (!_eventController.isClosed) {
        _eventController.addError(error, stackTrace);
      }
    }
  }

  void _handleOutput(Uint8List bytes) {
    if (bytes.isEmpty) {
      return;
    }
    final copy = Uint8List.fromList(bytes);
    _output.addAll(copy);
    _record(PtyOutputEvent(elapsed: _clock.elapsed, bytes: copy));
    if (!_stateController.isClosed) {
      _stateController.add(null);
    }
  }

  void _handleOutputError(Object error, StackTrace stackTrace) {
    _outputError = error;
    _outputErrorStack = stackTrace;
    if (!_eventController.isClosed) {
      _eventController.addError(error, stackTrace);
    }
    if (!_stateController.isClosed) {
      _stateController.addError(error, stackTrace);
    }
  }

  void _handleOutputDone() {
    _outputDone = true;
    if (!_stateController.isClosed) {
      _stateController.add(null);
    }
  }

  void _record(PtyEvent event) {
    _capturedEvents.add(event);
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  void _ensureInteractive() {
    if (_closing || _closed) {
      throw const PtySessionClosedException();
    }
  }

  void _ensureReadable() {
    if (_closed) {
      throw const PtySessionClosedException();
    }
  }
}

/// Location and output snapshot produced by [PtySession.waitForOutput].
final class PtyOutputMatch {
  /// Creates a match result and defensively copies [output].
  PtyOutputMatch({
    required this.start,
    required this.end,
    required List<int> output,
  }) : output = Uint8List.fromList(output);

  /// Inclusive byte offset at which the pattern begins.
  final int start;

  /// Exclusive byte offset immediately after the pattern.
  final int end;

  /// Cumulative output available when the match was found.
  final Uint8List output;
}

/// Thrown when an operation is attempted after session closure begins.
final class PtySessionClosedException implements Exception {
  /// Creates the exception.
  const PtySessionClosedException();

  @override
  String toString() => 'PtySessionClosedException: PTY session is closed.';
}

/// Thrown when output closes before the requested pattern appears.
final class PtyOutputClosedException implements Exception {
  /// Creates the exception and defensively copies diagnostic bytes.
  PtyOutputClosedException({
    required List<int> pattern,
    required List<int> output,
  }) : pattern = Uint8List.fromList(pattern),
       output = Uint8List.fromList(output);

  /// Pattern that was not observed.
  final Uint8List pattern;

  /// Output captured before the stream closed.
  final Uint8List output;

  @override
  String toString() =>
      'PtyOutputClosedException: output closed before pattern '
      '${base64Encode(pattern)} appeared; captured ${output.length} bytes.';
}

/// Thrown when a PTY wait exceeds its deadline.
final class PtyTimeoutException implements Exception {
  /// Creates a timeout exception and defensively copies diagnostic output.
  PtyTimeoutException({
    required this.operation,
    required this.timeout,
    required List<int> output,
  }) : output = Uint8List.fromList(output);

  /// Human-readable operation that timed out.
  final String operation;

  /// Configured timeout.
  final Duration timeout;

  /// Output captured when the timeout fired.
  final Uint8List output;

  @override
  String toString() =>
      'PtyTimeoutException: timed out after $timeout while $operation; '
      'captured ${output.length} bytes.';
}

int _indexOfBytes(List<int> haystack, Uint8List needle) {
  if (needle.length > haystack.length) {
    return -1;
  }
  final lastStart = haystack.length - needle.length;
  for (var start = 0; start <= lastStart; start++) {
    var matches = true;
    for (var index = 0; index < needle.length; index++) {
      if (haystack[start + index] != needle[index]) {
        matches = false;
        break;
      }
    }
    if (matches) {
      return start;
    }
  }
  return -1;
}

void _validateTerminalSize({required int columns, required int rows}) {
  if (columns <= 0) {
    throw RangeError.range(columns, 1, null, 'columns');
  }
  if (rows <= 0) {
    throw RangeError.range(rows, 1, null, 'rows');
  }
}
