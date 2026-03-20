import 'dart:async';
import 'dart:convert';

import 'remote_surface_protocol.dart';
import 'remote_surface_transport.dart';

/// Message channel for newline-delimited remote plugin JSON traffic.
///
/// The channel owns inbound decoding and outbound framing, but leaves process
/// lifecycle and transport selection to the caller.
final class RemotePluginJsonChannel {
  RemotePluginJsonChannel({
    required FutureOr<void> Function(String line) sendLine,
    RemotePluginProtocolValidator validator =
        const RemotePluginProtocolValidator(),
  }) : _sendLine = sendLine,
       _validator = validator;

  final FutureOr<void> Function(String line) _sendLine;
  final RemotePluginProtocolValidator _validator;
  final StreamController<RemotePluginMessage> _messages =
      StreamController<RemotePluginMessage>.broadcast();

  StreamSubscription<Object?>? _lineSubscription;
  bool _disposed = false;

  /// Typed inbound protocol messages.
  Stream<RemotePluginMessage> get messages => _messages.stream;

  Future<RemotePluginMessage?> _decodeLine(String rawLine) async {
    final line = rawLine.trim();
    if (line.isEmpty) {
      return null;
    }
    return RemotePluginMessage.decodeJson(line, validator: _validator);
  }

  /// Decodes and emits one inbound JSON line.
  Future<void> addLine(String line) async {
    if (_disposed) {
      return;
    }

    try {
      final message = await _decodeLine(line);
      if (!_disposed && message != null) {
        _messages.add(message);
      }
    } catch (error, stackTrace) {
      if (!_disposed) {
        _messages.addError(error, stackTrace);
      }
    }
  }

  /// Binds an inbound line stream to this channel.
  void bindLines(Stream<String> lines) {
    _lineSubscription?.cancel();
    _lineSubscription = lines
        .asyncMap(_decodeLine)
        .listen(
          (message) {
            if (!_disposed && message != null) {
              _messages.add(message);
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!_disposed) {
              _messages.addError(error, stackTrace);
            }
          },
          onDone: () {
            if (!_disposed) {
              _messages.close();
            }
          },
          cancelOnError: false,
        );
  }

  /// Binds UTF-8 bytes that contain newline-delimited JSON.
  void bindBytes(Stream<List<int>> bytes) {
    bindLines(bytes.transform(utf8.decoder).transform(const LineSplitter()));
  }

  /// Validates and sends one outbound protocol message.
  Future<void> send(RemotePluginMessage message) async {
    await _validator.validateMessageOrThrow(message);
    await _sendLine(RemotePluginJsonTransport.encodeLine(message));
  }

  /// Cancels subscriptions and closes the message stream.
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    await _lineSubscription?.cancel();
    await _messages.close();
  }
}
