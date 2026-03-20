import 'dart:async';
import 'dart:convert';

import 'remote_surface_protocol.dart';

/// Newline-delimited JSON framing for remote plugin messages.
///
/// This is intentionally transport-agnostic so callers can reuse it over
/// stdio, Unix sockets, TCP sockets, or deterministic tests.
final class RemotePluginJsonTransport {
  const RemotePluginJsonTransport._();

  /// Encodes [message] as one newline-delimited JSON object.
  static String encodeLine(RemotePluginMessage message) {
    return '${message.encodeJson()}\n';
  }

  /// Encodes [messages] as newline-delimited JSON strings.
  static Stream<String> encodeLines(
    Stream<RemotePluginMessage> messages,
  ) async* {
    await for (final message in messages) {
      yield encodeLine(message);
    }
  }

  /// Decodes newline-delimited JSON [lines] into typed protocol messages.
  static Stream<RemotePluginMessage> decodeLines(
    Stream<String> lines, {
    RemotePluginProtocolValidator validator =
        const RemotePluginProtocolValidator(),
  }) async* {
    await for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        continue;
      }
      yield await RemotePluginMessage.decodeJson(line, validator: validator);
    }
  }

  /// Decodes UTF-8 bytes containing newline-delimited JSON messages.
  static Stream<RemotePluginMessage> decodeBytes(
    Stream<List<int>> bytes, {
    RemotePluginProtocolValidator validator =
        const RemotePluginProtocolValidator(),
  }) {
    return decodeLines(
      bytes.transform(utf8.decoder).transform(const LineSplitter()),
      validator: validator,
    );
  }
}
