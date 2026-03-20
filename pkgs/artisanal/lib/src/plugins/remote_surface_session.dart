import 'dart:async';

import 'remote_surface_channel.dart';
import 'remote_surface_protocol.dart';

/// Host-side session wrapper around a remote plugin channel.
///
/// The session owns the channel subscription, captures the initial
/// [RemotePluginHello] handshake, and then forwards all subsequent plugin
/// messages through [messages].
final class RemotePluginSession {
  RemotePluginSession._(this.channel) {
    _messages = StreamController<RemotePluginMessage>.broadcast(
      onListen: _flushPendingEvents,
    );
  }

  /// Connects to a remote plugin channel and completes the hello handshake.
  static Future<RemotePluginSession> connect({
    required RemotePluginJsonChannel channel,
    required RemotePluginHostHello hostHello,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final session = RemotePluginSession._(channel);
    session._bind();
    try {
      await channel.send(hostHello);
      session.pluginHello = await session._pluginHello.future.timeout(
        timeout,
        onTimeout: () => throw TimeoutException(
          'Timed out waiting for plugin.hello.',
          timeout,
        ),
      );
      return session;
    } catch (_) {
      await session.dispose();
      rethrow;
    }
  }

  final RemotePluginJsonChannel channel;
  late final StreamController<RemotePluginMessage> _messages;
  final Completer<RemotePluginHello> _pluginHello =
      Completer<RemotePluginHello>();
  final List<_PendingSessionEvent> _pendingEvents = <_PendingSessionEvent>[];

  StreamSubscription<RemotePluginMessage>? _subscription;
  bool _disposed = false;
  late final RemotePluginHello pluginHello;

  /// Post-handshake plugin messages.
  Stream<RemotePluginMessage> get messages => _messages.stream;

  void _flushPendingEvents() {
    if (_disposed || !_messages.hasListener || _pendingEvents.isEmpty) {
      return;
    }

    final pendingEvents = List<_PendingSessionEvent>.of(_pendingEvents);
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

    _pendingEvents.add(_PendingSessionMessage(message));
  }

  void _emitError(Object error, StackTrace stackTrace) {
    if (_disposed) {
      return;
    }

    if (_messages.hasListener) {
      _messages.addError(error, stackTrace);
      return;
    }

    _pendingEvents.add(_PendingSessionError(error, stackTrace));
  }

  void _bind() {
    _subscription = channel.messages.listen(
      (message) {
        if (!_pluginHello.isCompleted) {
          if (message case RemotePluginHello()) {
            _pluginHello.complete(message);
            return;
          }
          _pluginHello.completeError(
            StateError(
              'Expected plugin.hello before '
              '${message.messageType.wireName}.',
            ),
          );
          return;
        }

        _emitMessage(message);
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!_pluginHello.isCompleted) {
          _pluginHello.completeError(error, stackTrace);
          return;
        }
        _emitError(error, stackTrace);
      },
      onDone: () {
        if (!_pluginHello.isCompleted) {
          _pluginHello.completeError(
            StateError('Remote plugin channel closed before plugin.hello.'),
          );
        }
        if (!_disposed) {
          _messages.close();
        }
      },
      cancelOnError: false,
    );
  }

  /// Sends one host message to the remote plugin.
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

sealed class _PendingSessionEvent {
  const _PendingSessionEvent();

  void deliver(StreamController<RemotePluginMessage> controller);
}

final class _PendingSessionMessage extends _PendingSessionEvent {
  const _PendingSessionMessage(this.message);

  final RemotePluginMessage message;

  @override
  void deliver(StreamController<RemotePluginMessage> controller) {
    controller.add(message);
  }
}

final class _PendingSessionError extends _PendingSessionEvent {
  const _PendingSessionError(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;

  @override
  void deliver(StreamController<RemotePluginMessage> controller) {
    controller.addError(error, stackTrace);
  }
}
