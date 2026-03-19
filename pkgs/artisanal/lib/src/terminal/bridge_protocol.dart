import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import '../style/color.dart';
import 'backend.dart';
import 'terminal_base.dart' show RawModeGuard;

/// Message kinds used by [TerminalBridgeMessage].
enum TerminalBridgeMessageType {
  /// Runtime output destined for the host terminal surface.
  output,

  /// Host text input forwarded to the runtime.
  inputText,

  /// Host binary input forwarded to the runtime.
  inputBytes,

  /// Host resize notification.
  resize,

  /// Host shutdown/interrupt notification.
  shutdown,
}

/// JSON-serializable bridge message for remote/browser terminal hosts.
///
/// This is the transport schema layered above [TerminalBridge]. It is intended
/// for line-delimited JSON channels, websockets, or any other message-oriented
/// transport where the host and runtime are in different processes.
final class TerminalBridgeMessage {
  const TerminalBridgeMessage._({
    required this.type,
    this.data,
    this.bytesBase64,
    this.width,
    this.height,
  });

  /// Creates an output message from the runtime to the host.
  const TerminalBridgeMessage.output(String data)
    : this._(type: TerminalBridgeMessageType.output, data: data);

  /// Creates a text input message from the host to the runtime.
  const TerminalBridgeMessage.inputText(String text)
    : this._(type: TerminalBridgeMessageType.inputText, data: text);

  /// Creates a binary input message from the host to the runtime.
  factory TerminalBridgeMessage.inputBytes(List<int> bytes) {
    return TerminalBridgeMessage._(
      type: TerminalBridgeMessageType.inputBytes,
      bytesBase64: base64Encode(bytes),
    );
  }

  /// Creates a resize notification.
  const TerminalBridgeMessage.resize({
    required int width,
    required int height,
  }) : this._(
         type: TerminalBridgeMessageType.resize,
         width: width,
         height: height,
       );

  /// Creates a shutdown notification.
  const TerminalBridgeMessage.shutdown()
    : this._(type: TerminalBridgeMessageType.shutdown);

  /// Message kind.
  final TerminalBridgeMessageType type;

  /// String payload for [TerminalBridgeMessageType.output] and
  /// [TerminalBridgeMessageType.inputText].
  final String? data;

  /// Base64 payload for [TerminalBridgeMessageType.inputBytes].
  final String? bytesBase64;

  /// Width payload for [TerminalBridgeMessageType.resize].
  final int? width;

  /// Height payload for [TerminalBridgeMessageType.resize].
  final int? height;

  /// Decodes a bridge message from JSON.
  factory TerminalBridgeMessage.fromJson(Map<String, dynamic> json) {
    final rawType = (json['type'] as String? ?? '').trim();
    final type = switch (rawType) {
      'output' => TerminalBridgeMessageType.output,
      'input.text' => TerminalBridgeMessageType.inputText,
      'input.bytes' => TerminalBridgeMessageType.inputBytes,
      'resize' => TerminalBridgeMessageType.resize,
      'shutdown' => TerminalBridgeMessageType.shutdown,
      _ => throw FormatException('Unknown terminal bridge message type: $rawType'),
    };

    return TerminalBridgeMessage._(
      type: type,
      data: json['data'] as String?,
      bytesBase64: json['bytesBase64'] as String?,
      width: json['width'] as int?,
      height: json['height'] as int?,
    );
  }

  /// Encodes this message to JSON.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'type': switch (type) {
        TerminalBridgeMessageType.output => 'output',
        TerminalBridgeMessageType.inputText => 'input.text',
        TerminalBridgeMessageType.inputBytes => 'input.bytes',
        TerminalBridgeMessageType.resize => 'resize',
        TerminalBridgeMessageType.shutdown => 'shutdown',
      },
      if (data != null) 'data': data,
      if (bytesBase64 != null) 'bytesBase64': bytesBase64,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
    };
  }

  /// Encodes this message as a single JSON object string.
  String encodeJson() => jsonEncode(toJson());

  /// Decodes a single JSON object string into a bridge message.
  static TerminalBridgeMessage decodeJson(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Terminal bridge message must decode to a JSON object.');
    }
    return TerminalBridgeMessage.fromJson(decoded);
  }

  /// Decodes [bytesBase64] for binary input messages.
  List<int>? decodeBytes() {
    final raw = bytesBase64;
    if (raw == null) return null;
    return base64Decode(raw);
  }
}

/// JSON message channel layered over a [TerminalBridge].
///
/// Outbound runtime output is exposed as JSON strings on [outboundMessages].
/// Inbound host messages can be fed through [addInboundJson] or [bindInbound].
final class TerminalBridgeJsonChannel {
  /// Creates a channel for [bridge].
  TerminalBridgeJsonChannel(this.bridge) {
    _outputSubscription = bridge.output.listen((chunk) {
      if (_disposed) return;
      _outboundController.add(TerminalBridgeMessage.output(chunk).encodeJson());
    });
  }

  /// The bridged terminal controller.
  final TerminalBridge bridge;

  final StreamController<String> _outboundController =
      StreamController<String>.broadcast();
  StreamSubscription<String>? _outputSubscription;
  StreamSubscription<String>? _inboundSubscription;
  bool _disposed = false;

  /// Outbound JSON messages produced by the runtime.
  Stream<String> get outboundMessages => _outboundController.stream;

  /// Decodes and applies one inbound JSON message.
  void addInboundJson(String message) {
    if (_disposed) return;
    _dispatch(TerminalBridgeMessage.decodeJson(message));
  }

  /// Binds an inbound JSON stream to this channel.
  void bindInbound(Stream<String> messages) {
    _inboundSubscription?.cancel();
    _inboundSubscription = messages.listen(addInboundJson);
  }

  void _dispatch(TerminalBridgeMessage message) {
    switch (message.type) {
      case TerminalBridgeMessageType.output:
        throw ArgumentError.value(
          message.type,
          'message.type',
          'Host must not send output messages back into the runtime.',
        );
      case TerminalBridgeMessageType.inputText:
        bridge.addInputString(message.data ?? '');
      case TerminalBridgeMessageType.inputBytes:
        bridge.addInput(message.decodeBytes() ?? const <int>[]);
      case TerminalBridgeMessageType.resize:
        final width = message.width;
        final height = message.height;
        if (width == null || height == null) {
          throw FormatException('Resize messages require width and height.');
        }
        bridge.resize(width: width, height: height);
      case TerminalBridgeMessageType.shutdown:
        bridge.requestShutdown();
    }
  }

  /// Disposes channel subscriptions and closes the outbound stream.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _outputSubscription?.cancel();
    await _inboundSubscription?.cancel();
    await _outboundController.close();
  }
}

/// Message-oriented backend that speaks the terminal bridge JSON protocol.
///
/// Use this when the host transport already gives you discrete string or binary
/// messages, such as websockets or structured IPC channels.
final class JsonTerminalBackend implements TerminalBackend {
  /// Creates a JSON protocol backend.
  JsonTerminalBackend({
    required void Function(String message) sendMessage,
    required Stream<Object?> inboundMessages,
    Future<void> Function()? flushMessages,
    Future<void> Function()? closeTransport,
    TerminalDimensions initialSize = const (width: 80, height: 24),
    this.supportsAnsi = true,
    this.isTerminal = true,
    this.colorProfile = ColorProfile.trueColor,
    this.movementCaps = const (useTabs: false, useBackspace: true),
  }) : _flushMessages = flushMessages,
       _closeTransport = closeTransport,
       _delegate = EmbeddedTerminalBackend(
         output: (data) {
           _trySendBridgeMessage(
             sendMessage,
             TerminalBridgeMessage.output(data).encodeJson(),
           );
         },
         initialSize: initialSize,
         supportsAnsi: supportsAnsi,
         isTerminal: isTerminal,
         colorProfile: colorProfile,
         movementCaps: movementCaps,
       ) {
    _inboundSubscription = inboundMessages.listen(
      _handleInboundMessage,
      onError: _delegate.addInputError,
      onDone: _delegate.requestShutdown,
      cancelOnError: false,
    );
  }

  final Future<void> Function()? _flushMessages;
  final Future<void> Function()? _closeTransport;
  final EmbeddedTerminalBackend _delegate;
  StreamSubscription<Object?>? _inboundSubscription;
  bool _disposed = false;

  @override
  final bool supportsAnsi;

  @override
  final bool isTerminal;

  @override
  final ColorProfile colorProfile;

  final ({bool useTabs, bool useBackspace}) movementCaps;

  void _handleInboundMessage(Object? event) {
    if (_disposed) return;

    try {
      final raw = switch (event) {
        String value => value,
        List<int> value => utf8.decode(value),
        _ => throw FormatException(
          'Terminal bridge transport expects String or List<int> messages.',
        ),
      };
      final message = TerminalBridgeMessage.decodeJson(raw);
      switch (message.type) {
        case TerminalBridgeMessageType.output:
          throw ArgumentError.value(
            message.type,
            'message.type',
            'Host must not send output messages back into the runtime.',
          );
        case TerminalBridgeMessageType.inputText:
          _delegate.addInput(utf8.encode(message.data ?? ''));
        case TerminalBridgeMessageType.inputBytes:
          _delegate.addInput(message.decodeBytes() ?? const <int>[]);
        case TerminalBridgeMessageType.resize:
          final width = message.width;
          final height = message.height;
          if (width == null || height == null) {
            throw FormatException('Resize messages require width and height.');
          }
          _delegate.notifySizeChanged((width: width, height: height));
        case TerminalBridgeMessageType.shutdown:
          _delegate.requestShutdown();
      }
    } catch (error, stackTrace) {
      _delegate.addInputError(error, stackTrace);
    }
  }

  @override
  void writeRaw(String data) {
    if (_disposed) return;
    _delegate.writeRaw(data);
  }

  @override
  Future<void> flush() async {
    if (_disposed) return;
    await _delegate.flush();
    final flushMessages = _flushMessages;
    if (flushMessages != null) {
      await flushMessages();
    }
  }

  @override
  TerminalDimensions get size => _delegate.size;

  @override
  Stream<List<int>>? get inputStream => _delegate.inputStream;

  @override
  Stream<TerminalDimensions>? get resizeStream => _delegate.resizeStream;

  @override
  Stream<void>? get shutdownStream => _delegate.shutdownStream;

  @override
  RawModeGuard enableRawMode() => _delegate.enableRawMode();

  @override
  void disableRawMode() => _delegate.disableRawMode();

  @override
  bool get isRawMode => _delegate.isRawMode;

  @override
  ({bool useTabs, bool useBackspace}) optimizeMovements() => movementCaps;

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _inboundSubscription?.cancel();
    _inboundSubscription = null;
    _delegate.dispose();
    final closeTransport = _closeTransport;
    if (closeTransport != null) {
      unawaited(closeTransport());
    }
  }
}

void _trySendBridgeMessage(
  void Function(String message) sendMessage,
  String message,
) {
  try {
    sendMessage(message);
  } on StateError {
    // The transport closed between runtime shutdown and a late write. Treat it
    // as a no-op so forced remote-session teardown does not surface spurious
    // errors from startup probes or final repaint attempts.
  }
}

/// WebSocket-backed backend that speaks the terminal bridge JSON protocol.
///
/// Use this when a remote/browser host exchanges structured JSON bridge
/// messages over a websocket instead of raw terminal bytes.
final class WebSocketTerminalBackend implements TerminalBackend {
  /// Creates a websocket-backed backend.
  WebSocketTerminalBackend(
    this.socket, {
    TerminalDimensions initialSize = const (width: 80, height: 24),
    bool supportsAnsi = true,
    bool isTerminal = true,
    ColorProfile colorProfile = ColorProfile.trueColor,
    ({bool useTabs, bool useBackspace}) movementCaps = const (
      useTabs: false,
      useBackspace: true,
    ),
    this.closeSocketOnDispose = true,
  }) : _delegate = JsonTerminalBackend(
         sendMessage: socket.add,
         inboundMessages: socket,
         closeTransport: closeSocketOnDispose ? () => socket.close() : null,
         initialSize: initialSize,
         supportsAnsi: supportsAnsi,
         isTerminal: isTerminal,
         colorProfile: colorProfile,
         movementCaps: movementCaps,
       );

  /// The connected websocket.
  final io.WebSocket socket;

  final JsonTerminalBackend _delegate;

  /// Whether the websocket should be closed when the backend is disposed.
  final bool closeSocketOnDispose;

  @override
  void writeRaw(String data) => _delegate.writeRaw(data);

  @override
  Future<void> flush() => _delegate.flush();

  @override
  TerminalDimensions get size => _delegate.size;

  @override
  bool get supportsAnsi => _delegate.supportsAnsi;

  @override
  bool get isTerminal => _delegate.isTerminal;

  @override
  ColorProfile get colorProfile => _delegate.colorProfile;

  @override
  Stream<List<int>>? get inputStream => _delegate.inputStream;

  @override
  Stream<TerminalDimensions>? get resizeStream => _delegate.resizeStream;

  @override
  Stream<void>? get shutdownStream => _delegate.shutdownStream;

  @override
  RawModeGuard enableRawMode() => _delegate.enableRawMode();

  @override
  void disableRawMode() => _delegate.disableRawMode();

  @override
  bool get isRawMode => _delegate.isRawMode;

  @override
  ({bool useTabs, bool useBackspace}) optimizeMovements() =>
      _delegate.optimizeMovements();

  @override
  void dispose() => _delegate.dispose();
}
