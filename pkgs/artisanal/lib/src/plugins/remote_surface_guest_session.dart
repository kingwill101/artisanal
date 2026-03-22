import 'dart:async';
import 'dart:io' as io;

import 'remote_surface_channel.dart';
import 'remote_surface_guest_services.dart';
import 'remote_surface_protocol.dart';

/// Plugin-side session wrapper around a remote plugin channel.
///
/// The guest session owns the channel subscription, captures the initial
/// [RemotePluginHostHello] handshake, and then forwards all subsequent host
/// messages through [messages].
final class RemotePluginGuestSession {
  RemotePluginGuestSession._(this.channel) {
    _messages = StreamController<RemotePluginMessage>.broadcast(
      onListen: _flushPendingEvents,
    );
  }

  /// Connects to a remote host channel and completes the hello handshake.
  static Future<RemotePluginGuestSession> connect({
    required RemotePluginJsonChannel channel,
    required RemotePluginHello pluginHello,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final session = RemotePluginGuestSession._(channel);
    final hostHelloFuture = session._hostHello.future;
    unawaited(_ignoreHandshakeError(hostHelloFuture));
    session._bind();
    try {
      await channel.send(pluginHello);
      session.hostHello = await hostHelloFuture.timeout(
        timeout,
        onTimeout: () => throw TimeoutException(
          'Timed out waiting for host.hello.',
          timeout,
        ),
      );
      return session;
    } catch (_) {
      await session.dispose();
      rethrow;
    }
  }

  /// Binds stdin/stdout-like streams and completes the hello handshake.
  static Future<RemotePluginGuestSession> bindStdio({
    required RemotePluginHello pluginHello,
    Stream<List<int>>? input,
    FutureOr<void> Function(String line)? sendLine,
    RemotePluginProtocolValidator validator =
        const RemotePluginProtocolValidator(),
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final channel = RemotePluginJsonChannel(
      sendLine:
          sendLine ??
          (line) async {
            io.stdout.write(line);
            await io.stdout.flush();
          },
      validator: validator,
    );
    channel.bindBytes(input ?? io.stdin);
    return connect(
      channel: channel,
      pluginHello: pluginHello,
      timeout: timeout,
    );
  }

  final RemotePluginJsonChannel channel;
  late final StreamController<RemotePluginMessage> _messages;
  final Completer<RemotePluginHostHello> _hostHello =
      Completer<RemotePluginHostHello>();
  final List<_PendingGuestSessionEvent> _pendingEvents =
      <_PendingGuestSessionEvent>[];

  StreamSubscription<RemotePluginMessage>? _subscription;
  bool _disposed = false;
  late final RemotePluginHostHello hostHello;
  late final RemotePluginGuestServices services = RemotePluginGuestServices(
    this,
  );

  /// Post-handshake host messages.
  Stream<RemotePluginMessage> get messages => _messages.stream;

  void _flushPendingEvents() {
    if (_disposed || !_messages.hasListener || _pendingEvents.isEmpty) {
      return;
    }

    final pendingEvents = List<_PendingGuestSessionEvent>.of(_pendingEvents);
    _pendingEvents.clear();
    for (final event in pendingEvents) {
      event.deliver(_messages);
    }
  }

  void _emitMessage(RemotePluginMessage message) {
    if (_disposed) {
      return;
    }

    if (_messages.hasListener) {
      _messages.add(message);
      return;
    }

    _pendingEvents.add(_PendingGuestSessionMessage(message));
  }

  void _emitError(Object error, StackTrace stackTrace) {
    if (_disposed) {
      return;
    }

    if (_messages.hasListener) {
      _messages.addError(error, stackTrace);
      return;
    }

    _pendingEvents.add(_PendingGuestSessionError(error, stackTrace));
  }

  void _bind() {
    _subscription = channel.messages.listen(
      (message) {
        if (!_hostHello.isCompleted) {
          if (message case RemotePluginHostHello()) {
            _hostHello.complete(message);
            return;
          }
          _hostHello.completeError(
            StateError(
              'Expected host.hello before ${message.messageType.wireName}.',
            ),
          );
          return;
        }

        _emitMessage(message);
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!_hostHello.isCompleted) {
          _hostHello.completeError(error, stackTrace);
          return;
        }
        _emitError(error, stackTrace);
      },
      onDone: () {
        if (!_hostHello.isCompleted) {
          _hostHello.completeError(
            StateError('Remote host channel closed before host.hello.'),
          );
        }
        if (!_disposed) {
          _messages.close();
        }
      },
      cancelOnError: false,
    );
  }

  /// Sends one plugin message to the host.
  Future<void> send(RemotePluginMessage message) => channel.send(message);

  /// Disposes the session subscription and closes the underlying channel.
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _pendingEvents.clear();
    await _subscription?.cancel();
    await _messages.close();
    await channel.dispose();
  }
}

Future<void> _ignoreHandshakeError<T>(Future<T> future) async {
  try {
    await future;
  } catch (_) {}
}

sealed class _PendingGuestSessionEvent {
  const _PendingGuestSessionEvent();

  void deliver(StreamController<RemotePluginMessage> controller);
}

final class _PendingGuestSessionMessage extends _PendingGuestSessionEvent {
  const _PendingGuestSessionMessage(this.message);

  final RemotePluginMessage message;

  @override
  void deliver(StreamController<RemotePluginMessage> controller) {
    controller.add(message);
  }
}

final class _PendingGuestSessionError extends _PendingGuestSessionEvent {
  const _PendingGuestSessionError(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;

  @override
  void deliver(StreamController<RemotePluginMessage> controller) {
    controller.addError(error, stackTrace);
  }
}
