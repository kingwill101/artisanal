import 'dart:async';

import 'remote_surface_channel.dart';
import 'remote_surface_protocol.dart';

/// Host-side session wrapper around a remote plugin channel.
///
/// The session owns the channel subscription, captures the initial
/// [RemotePluginHello] handshake, and then forwards all subsequent plugin
/// messages through [messages].
final class RemotePluginSession {
  RemotePluginSession._(this.channel);

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
  final StreamController<RemotePluginMessage> _messages =
      StreamController<RemotePluginMessage>.broadcast();
  final Completer<RemotePluginHello> _pluginHello =
      Completer<RemotePluginHello>();

  StreamSubscription<RemotePluginMessage>? _subscription;
  bool _disposed = false;
  late final RemotePluginHello pluginHello;

  /// Post-handshake plugin messages.
  Stream<RemotePluginMessage> get messages => _messages.stream;

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

        if (!_disposed) {
          _messages.add(message);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!_pluginHello.isCompleted) {
          _pluginHello.completeError(error, stackTrace);
          return;
        }
        if (!_disposed) {
          _messages.addError(error, stackTrace);
        }
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
    await _subscription?.cancel();
    await _messages.close();
    await channel.dispose();
  }
}
