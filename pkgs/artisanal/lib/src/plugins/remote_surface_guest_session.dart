import 'dart:async';
import 'dart:io' as io;

import 'remote_surface_channel.dart';
import 'remote_surface_protocol.dart';

/// Plugin-side session wrapper around a remote plugin channel.
///
/// The guest session owns the channel subscription, captures the initial
/// [RemotePluginHostHello] handshake, and then forwards all subsequent host
/// messages through [messages].
final class RemotePluginGuestSession {
  RemotePluginGuestSession._(this.channel);

  /// Connects to a remote host channel and completes the hello handshake.
  static Future<RemotePluginGuestSession> connect({
    required RemotePluginJsonChannel channel,
    required RemotePluginHello pluginHello,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final session = RemotePluginGuestSession._(channel);
    session._bind();
    try {
      await channel.send(pluginHello);
      session.hostHello = await session._hostHello.future.timeout(
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
      sendLine: sendLine ?? io.stdout.write,
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
  final StreamController<RemotePluginMessage> _messages =
      StreamController<RemotePluginMessage>.broadcast();
  final Completer<RemotePluginHostHello> _hostHello =
      Completer<RemotePluginHostHello>();

  StreamSubscription<RemotePluginMessage>? _subscription;
  bool _disposed = false;
  late final RemotePluginHostHello hostHello;

  /// Post-handshake host messages.
  Stream<RemotePluginMessage> get messages => _messages.stream;

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

        if (!_disposed) {
          _messages.add(message);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!_hostHello.isCompleted) {
          _hostHello.completeError(error, stackTrace);
          return;
        }
        if (!_disposed) {
          _messages.addError(error, stackTrace);
        }
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
    await _subscription?.cancel();
    await _messages.close();
    await channel.dispose();
  }
}
