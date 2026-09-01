/// Stub for `browser_host.dart` when `dart:io` is not available.
library;

import 'host_server.dart' show TerminalHostServer;

/// Stub for [BrowserTerminalSessionHandler] on web/WASM.
typedef BrowserTerminalSessionHandler = Future<void> Function(Never socket);

/// Stub for [BrowserTerminalHostServer] on web/WASM.
abstract final class BrowserTerminalHostServer implements TerminalHostServer {
  BrowserTerminalHostServer._();

  /// Stub: not available on web.
  static Future<BrowserTerminalHostServer> serveProgram<M>({
    Object? address,
    int port = 8080,
    String pagePath = '/',
    String webSocketPath = '/ws',
    String title = 'Artisanal Browser Host',
    String? pageHtml,
    required M Function() modelBuilder,
    Object? options,
  }) =>
      throw UnsupportedError('BrowserTerminalHostServer not available on web');

  /// Stub: not available on web.
  Uri get pageUri =>
      throw UnsupportedError('BrowserTerminalHostServer not available on web');

  /// Stub: not available on web.
  Uri get webSocketUri =>
      throw UnsupportedError('BrowserTerminalHostServer not available on web');

  /// Stub: not available on web.
  @override
  Future<void> close({bool force = false}) =>
      throw UnsupportedError('BrowserTerminalHostServer not available on web');
}
