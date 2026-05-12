/// Stub for `bridge_protocol.dart` when `dart:io` is not available.
library;

import 'backend.dart' show TerminalBackend;

/// Stub for [TerminalBridgeMessageType] on web/WASM.
enum TerminalBridgeMessageType { output, inputText, inputBytes, resize, shutdown }

/// Stub for [TerminalBridgeMessage] on web/WASM.
abstract final class TerminalBridgeMessage {
  TerminalBridgeMessage._();

  /// Stub: not available on web.
  TerminalBridgeMessageType get type =>
      throw UnsupportedError('TerminalBridgeMessage not available on web');

  /// Stub: not available on web.
  String get data =>
      throw UnsupportedError('TerminalBridgeMessage not available on web');

  /// Stub: not available on web.
  static TerminalBridgeMessage decodeJson(String source) =>
      throw UnsupportedError('TerminalBridgeMessage not available on web');
}

/// Stub for [TerminalBridgeJsonChannel] on web/WASM.
abstract final class TerminalBridgeJsonChannel {
  TerminalBridgeJsonChannel._();
}

/// Stub for [JsonTerminalBackend] on web/WASM.
abstract final class JsonTerminalBackend implements TerminalBackend {
  JsonTerminalBackend._();
}

/// Stub for [WebSocketTerminalBackend] on web/WASM.
abstract final class WebSocketTerminalBackend implements TerminalBackend {
  WebSocketTerminalBackend._();
}
