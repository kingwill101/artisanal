/// Stub for `bridge_protocol.dart` when `dart:io` is not available.
library;

import 'dart:async';
import 'dart:convert';

import 'backend.dart' show TerminalBackend;
import '../style/color.dart' show ColorProfile;
import 'terminal_base.dart' show RawModeGuard;

/// Stub for [TerminalBridgeMessageType] on web/WASM.
enum TerminalBridgeMessageType {
  output,
  inputText,
  inputBytes,
  resize,
  shutdown,
}

/// Stub for [TerminalBridgeMessage] on web/WASM.
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
  const TerminalBridgeMessage.resize({required int width, required int height})
    : this._(
        type: TerminalBridgeMessageType.resize,
        width: width,
        height: height,
      );

  /// Creates a shutdown notification.
  const TerminalBridgeMessage.shutdown()
    : this._(type: TerminalBridgeMessageType.shutdown);

  /// Stub: not available on web.
  final TerminalBridgeMessageType type;

  /// Stub: not available on web.
  final String? data;

  /// Stub: not available on web.
  final String? bytesBase64;

  /// Stub: not available on web.
  final int? width;

  /// Stub: not available on web.
  final int? height;

  /// Decodes a bridge message from JSON.
  factory TerminalBridgeMessage.fromJson(Map<String, dynamic> json) {
    throw UnsupportedError('TerminalBridgeMessage not available on web');
  }

  /// Encodes this message to JSON.
  Map<String, Object?> toJson() {
    throw UnsupportedError('TerminalBridgeMessage not available on web');
  }

  /// Encodes this message as a single JSON object string.
  String encodeJson() => jsonEncode(toJson());

  /// Stub: not available on web.
  static TerminalBridgeMessage decodeJson(String source) =>
      throw UnsupportedError('TerminalBridgeMessage not available on web');

  /// Stub: not available on web.
  List<int>? decodeBytes() =>
      throw UnsupportedError('TerminalBridgeMessage not available on web');
}

/// Stub for [TerminalBridgeJsonChannel] on web/WASM.
final class TerminalBridgeJsonChannel {
  /// Creates a stub JSON bridge channel.
  TerminalBridgeJsonChannel(Object bridge);

  /// Stub: not available on web.
  Stream<String> get outboundMessages =>
      throw UnsupportedError('TerminalBridgeJsonChannel not available on web');

  /// Stub: not available on web.
  void addInboundJson(String message) {
    throw UnsupportedError('TerminalBridgeJsonChannel not available on web');
  }

  /// Stub: not available on web.
  void bindInbound(Stream<String> messages) {
    throw UnsupportedError('TerminalBridgeJsonChannel not available on web');
  }

  /// Stub: not available on web.
  Future<void> dispose() {
    throw UnsupportedError('TerminalBridgeJsonChannel not available on web');
  }
}

/// Stub for [JsonTerminalBackend] on web/WASM.
final class JsonTerminalBackend implements TerminalBackend {
  /// Creates a stub JSON terminal backend.
  JsonTerminalBackend({
    required void Function(String message) sendMessage,
    required Stream<Object?> inboundMessages,
    Future<void> Function()? flushMessages,
    Future<void> Function()? closeTransport,
    ({int width, int height}) initialSize = const (width: 80, height: 24),
    bool supportsAnsi = true,
    bool isTerminal = true,
    ColorProfile colorProfile = ColorProfile.trueColor,
    ({bool useTabs, bool useBackspace}) movementCaps = const (
      useTabs: false,
      useBackspace: true,
    ),
  });

  Never _unsupported() =>
      throw UnsupportedError('JsonTerminalBackend not available on web');

  @override
  void writeRaw(String data) => _unsupported();

  @override
  Future<void> flush() => _unsupported();

  @override
  ({int width, int height}) get size => _unsupported();

  @override
  bool get supportsAnsi => _unsupported();

  @override
  bool get isTerminal => _unsupported();

  @override
  ColorProfile get colorProfile => _unsupported();

  @override
  Stream<List<int>>? get inputStream => _unsupported();

  @override
  Stream<({int height, int width})>? get resizeStream => _unsupported();

  @override
  Stream<void>? get shutdownStream => _unsupported();

  @override
  RawModeGuard enableRawMode() => _unsupported();

  @override
  void disableRawMode() => _unsupported();

  @override
  bool get isRawMode => _unsupported();

  @override
  ({bool useTabs, bool useBackspace}) optimizeMovements() => _unsupported();

  @override
  void dispose() => _unsupported();
}

/// Stub for [WebSocketTerminalBackend] on web/WASM.
final class WebSocketTerminalBackend implements TerminalBackend {
  /// Creates a stub websocket terminal backend.
  WebSocketTerminalBackend({
    required Object socket,
    ({int width, int height}) initialSize = const (width: 80, height: 24),
    bool supportsAnsi = true,
    bool isTerminal = true,
    ColorProfile colorProfile = ColorProfile.trueColor,
    ({bool useTabs, bool useBackspace}) movementCaps = const (
      useTabs: false,
      useBackspace: true,
    ),
  });

  Never _unsupported() =>
      throw UnsupportedError('WebSocketTerminalBackend not available on web');

  @override
  void writeRaw(String data) => _unsupported();

  @override
  Future<void> flush() => _unsupported();

  @override
  ({int width, int height}) get size => _unsupported();

  @override
  bool get supportsAnsi => _unsupported();

  @override
  bool get isTerminal => _unsupported();

  @override
  ColorProfile get colorProfile => _unsupported();

  @override
  Stream<List<int>>? get inputStream => _unsupported();

  @override
  Stream<({int height, int width})>? get resizeStream => _unsupported();

  @override
  Stream<void>? get shutdownStream => _unsupported();

  @override
  RawModeGuard enableRawMode() => _unsupported();

  @override
  void disableRawMode() => _unsupported();

  @override
  bool get isRawMode => _unsupported();

  @override
  ({bool useTabs, bool useBackspace}) optimizeMovements() => _unsupported();

  @override
  void dispose() => _unsupported();
}
