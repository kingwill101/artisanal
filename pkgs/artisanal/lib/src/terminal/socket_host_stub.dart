/// Stub for `socket_host.dart` when `dart:io` is not available.
library;

import 'host_server.dart' show TerminalHostServer;

/// Stub for [SocketTerminalSessionHandler] on web/WASM.
typedef SocketTerminalSessionHandler = Future<void> Function(Never socket);

/// Stub for the native `InternetAddress` type.
abstract class StubInternetAddress {
  String get address;
}

/// Stub for the native `ServerSocket` type exposed via [SocketTerminalHostServer.server].
abstract class StubServerSocket {
  StubInternetAddress get address;
  int get port;
}

/// Stub for [SocketTerminalHostServer] on web/WASM.
abstract final class SocketTerminalHostServer implements TerminalHostServer {
  SocketTerminalHostServer._();

  /// Stub: returns a resize control sequence string (not available on web).
  static String resizeControlSequence({
    required int width,
    required int height,
  }) => throw UnsupportedError('SocketTerminalHostServer not available on web');

  /// Stub: not available on web.
  static Future<SocketTerminalHostServer> serveProgram<M>({
    Object? address,
    int port = 2323,
    bool v6Only = false,
    bool shared = false,
    Object? initialSize,
    bool supportsAnsi = true,
    Object? colorProfile,
    required M Function() modelBuilder,
    Object? options,
  }) => throw UnsupportedError('SocketTerminalHostServer not available on web');

  /// Stub: not available on web.
  StubServerSocket get server =>
      throw UnsupportedError('SocketTerminalHostServer not available on web');

  /// Stub: not available on web.
  @override
  Future<void> close({bool force = false}) =>
      throw UnsupportedError('SocketTerminalHostServer not available on web');
}
