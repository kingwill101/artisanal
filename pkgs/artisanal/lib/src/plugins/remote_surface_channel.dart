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
       _validator = validator {
    _messages = StreamController<RemotePluginMessage>.broadcast(
      onListen: _flushPendingEvents,
    );
  }

  final FutureOr<void> Function(String line) _sendLine;
  final RemotePluginProtocolValidator _validator;
  late final StreamController<RemotePluginMessage> _messages;
  final List<_PendingChannelEvent> _pendingEvents = <_PendingChannelEvent>[];

  StreamSubscription<Object?>? _lineSubscription;
  bool _disposed = false;

  /// Typed inbound protocol messages.
  Stream<RemotePluginMessage> get messages => _messages.stream;

  void _flushPendingEvents() {
    if (_disposed || !_messages.hasListener || _pendingEvents.isEmpty) {
      return;
    }

    final pendingEvents = List<_PendingChannelEvent>.of(_pendingEvents);
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

    _pendingEvents.add(_PendingChannelMessage(message));
  }

  void _emitError(Object error, StackTrace stackTrace) {
    if (_disposed) {
      return;
    }

    if (_messages.hasListener) {
      _messages.addError(error, stackTrace);
      return;
    }

    _pendingEvents.add(_PendingChannelError(error, stackTrace));
  }

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
      if (message != null) {
        _emitMessage(message);
      }
    } catch (error, stackTrace) {
      _emitError(error, stackTrace);
    }
  }

  /// Binds an inbound line stream to this channel.
  void bindLines(Stream<String> lines) {
    _lineSubscription?.cancel();
    _lineSubscription = lines
        .asyncMap(_decodeLine)
        .listen(
          (message) {
            if (message != null) {
              _emitMessage(message);
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            _emitError(error, stackTrace);
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
    _pendingEvents.clear();
    await _lineSubscription?.cancel();
    await _messages.close();
  }
}

sealed class _PendingChannelEvent {
  const _PendingChannelEvent();

  void deliver(StreamController<RemotePluginMessage> controller);
}

final class _PendingChannelMessage extends _PendingChannelEvent {
  const _PendingChannelMessage(this.message);

  final RemotePluginMessage message;

  @override
  void deliver(StreamController<RemotePluginMessage> controller) {
    controller.add(message);
  }
}

final class _PendingChannelError extends _PendingChannelEvent {
  const _PendingChannelError(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;

  @override
  void deliver(StreamController<RemotePluginMessage> controller) {
    controller.addError(error, stackTrace);
  }
}
