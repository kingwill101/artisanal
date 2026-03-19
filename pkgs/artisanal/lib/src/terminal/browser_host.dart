import 'dart:async';
import 'dart:io' as io;

import '../tui/model.dart';
import '../tui/program.dart';

/// Session handler invoked for each accepted browser websocket connection.
typedef BrowserTerminalSessionHandler =
    Future<void> Function(io.WebSocket socket);

/// Reusable browser host server for remote TUI sessions.
///
/// This helper serves a default xterm.js client page and upgrades websocket
/// connections for terminal sessions. Use [bind] for custom session handling
/// or [serveProgram] to host a [Model] directly.
final class BrowserTerminalHostServer {
  BrowserTerminalHostServer._({
    required this.server,
    required this.pagePath,
    required this.webSocketPath,
    required this.pageHtml,
    required this.onSession,
  });

  /// The underlying HTTP server.
  final io.HttpServer server;

  /// Path used for the client page.
  final String pagePath;

  /// Path used for websocket upgrades.
  final String webSocketPath;

  /// HTML served at [pagePath].
  final String pageHtml;

  final BrowserTerminalSessionHandler onSession;
  late final StreamSubscription<io.HttpRequest> _subscription;
  final Set<io.WebSocket> _activeSockets = <io.WebSocket>{};
  final Set<Future<void>> _activeRequests = <Future<void>>{};
  final Set<Future<void>> _activeSessions = <Future<void>>{};
  bool _closed = false;

  /// Binds a browser host server.
  static Future<BrowserTerminalHostServer> bind({
    io.InternetAddress? address,
    int port = 8080,
    String pagePath = '/',
    String webSocketPath = '/ws',
    String title = 'Artisanal Browser Host',
    String? pageHtml,
    required BrowserTerminalSessionHandler onSession,
  }) async {
    final normalizedPagePath = _normalizePath(pagePath, allowRoot: true);
    final normalizedWebSocketPath = _normalizePath(webSocketPath);
    final server = await io.HttpServer.bind(
      address ?? io.InternetAddress.loopbackIPv4,
      port,
    );
    final host = BrowserTerminalHostServer._(
      server: server,
      pagePath: normalizedPagePath,
      webSocketPath: normalizedWebSocketPath,
      pageHtml:
          pageHtml ??
          defaultPageHtml(
            title: title,
            webSocketPath: normalizedWebSocketPath,
          ),
      onSession: onSession,
    );
    host._subscription = server.listen(
      (request) {
        unawaited(host._handleRequestSafely(request));
      },
      cancelOnError: false,
    );
    return host;
  }

  /// Binds a browser host server that runs a fresh program per websocket.
  static Future<BrowserTerminalHostServer> serveProgram<M extends Model>({
    io.InternetAddress? address,
    int port = 8080,
    String pagePath = '/',
    String webSocketPath = '/ws',
    String title = 'Artisanal Browser Host',
    String? pageHtml,
    required M Function() modelBuilder,
    ProgramOptions options = const ProgramOptions(
      altScreen: false,
      frameTick: false,
      signalHandlers: false,
    ),
  }) {
    return bind(
      address: address,
      port: port,
      pagePath: pagePath,
      webSocketPath: webSocketPath,
      title: title,
      pageHtml: pageHtml,
      onSession: (socket) async {
        await runProgram(
          modelBuilder(),
          options: options,
          host: ProgramHost.webSocket(socket),
        );
      },
    );
  }

  /// URL for the served browser page.
  Uri get pageUri => Uri(
    scheme: 'http',
    host: server.address.address,
    port: server.port,
    path: pagePath,
  );

  /// URL for websocket terminal sessions.
  Uri get webSocketUri => Uri(
    scheme: 'ws',
    host: server.address.address,
    port: server.port,
    path: webSocketPath,
  );

  Future<void> _handleRequest(io.HttpRequest request) async {
    final path = request.uri.path.isEmpty ? '/' : request.uri.path;
    if (path == webSocketPath) {
      final socket = await io.WebSocketTransformer.upgrade(request);
      unawaited(_handleSession(socket));
      return;
    }

    final isPageRequest =
        path == pagePath || (pagePath == '/' && path == '/index.html');
    if (isPageRequest) {
      request.response.headers.contentType = io.ContentType.html;
      request.response.write(pageHtml);
      await request.response.close();
      return;
    }

    request.response.statusCode = io.HttpStatus.notFound;
    request.response.write('Not found');
    await request.response.close();
  }

  Future<void> _handleRequestSafely(io.HttpRequest request) async {
    Future<void>? task;
    try {
      task = Future<void>.sync(() => _handleRequest(request));
      _activeRequests.add(task);
      await task;
    } catch (error) {
      final response = request.response;
      try {
        response.statusCode =
            error is io.WebSocketException
                ? io.HttpStatus.badRequest
                : io.HttpStatus.internalServerError;
        response.write(
          error is io.WebSocketException
              ? 'Bad websocket upgrade'
              : 'Internal server error',
        );
        await response.close();
      } catch (_) {
        // Best-effort only: a dropped client should not poison the host.
      }
    } finally {
      if (task != null) {
        _activeRequests.remove(task);
      }
    }
  }

  Future<void> _handleSession(io.WebSocket socket) async {
    _activeSockets.add(socket);
    Future<void>? session;
    try {
      session = Future<void>.sync(() => onSession(socket));
      _activeSessions.add(session);
      await session;
    } catch (_) {
      // Keep the host alive when a single session handler fails.
    } finally {
      if (session != null) {
        _activeSessions.remove(session);
      }
      _activeSockets.remove(socket);
      if (socket.closeCode == null) {
        await socket.close();
      }
    }
  }

  /// Closes the underlying HTTP server.
  Future<void> close({bool force = false}) async {
    if (_closed) return;
    _closed = true;
    await _subscription.cancel();
    await server.close(force: force);

    if (_activeRequests.isNotEmpty) {
      await Future.wait(
        _activeRequests.toList(growable: false),
        eagerError: false,
      );
    }

    if (force) {
      await Future.wait(
        _activeSockets.toList(growable: false).map((socket) => socket.close()),
        eagerError: false,
      );
    }

    if (_activeSessions.isNotEmpty) {
      await Future.wait(
        _activeSessions.toList(growable: false),
        eagerError: false,
      );
    }
  }

  /// Builds a default xterm.js browser page for websocket-backed terminal
  /// sessions.
  static String defaultPageHtml({
    required String title,
    required String webSocketPath,
    String background = '#101318',
    String foreground = '#e6edf3',
    String cursor = '#58a6ff',
    String selectionBackground = '#334155',
  }) => '''
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>${_escapeHtml(title)}</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@xterm/xterm@5.5.0/css/xterm.css">
    <style>
      :root { color-scheme: dark; }
      html, body {
        margin: 0;
        height: 100%;
        background: $background;
        color: $foreground;
        font-family: ui-sans-serif, system-ui, sans-serif;
      }
      body {
        display: grid;
        grid-template-rows: auto 1fr;
      }
      .toolbar {
        display: flex;
        gap: 16px;
        align-items: center;
        padding: 10px 14px;
        border-bottom: 1px solid #202938;
        background: linear-gradient(180deg, #161c25, #121720);
      }
      .badge {
        padding: 4px 8px;
        border-radius: 999px;
        font-size: 12px;
        background: #1f2937;
        color: #9fb3c8;
      }
      #terminal {
        height: 100%;
        width: 100%;
        padding: 12px;
        box-sizing: border-box;
      }
    </style>
  </head>
  <body>
    <div class="toolbar">
      <strong>${_escapeHtml(title)}</strong>
      <span class="badge" id="endpoint"></span>
      <span class="badge" id="status">connecting</span>
    </div>
    <div id="terminal"></div>

    <script src="https://cdn.jsdelivr.net/npm/@xterm/xterm@5.5.0/lib/xterm.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/@xterm/addon-fit@0.10.0/lib/addon-fit.js"></script>
    <script>
      const terminalNode = document.getElementById('terminal');
      const statusNode = document.getElementById('status');
      const endpointNode = document.getElementById('endpoint');
      const term = new Terminal({
        cursorBlink: true,
        convertEol: true,
        fontFamily: 'ui-monospace, SFMono-Regular, Menlo, monospace',
        theme: {
          background: '$background',
          foreground: '$foreground',
          cursor: '$cursor',
          selectionBackground: '$selectionBackground'
        }
      });
      const fitAddon = new FitAddon.FitAddon();
      term.loadAddon(fitAddon);
      term.open(terminalNode);
      fitAddon.fit();
      term.focus();

      const wsProtocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
      const wsUrl = wsProtocol + '//' + window.location.host + '$webSocketPath';
      endpointNode.textContent = wsUrl;
      const ws = new WebSocket(wsUrl);

      function sendMessage(message) {
        if (ws.readyState === WebSocket.OPEN) {
          ws.send(JSON.stringify(message));
        }
      }

      function sendResize() {
        fitAddon.fit();
        sendMessage({
          type: 'resize',
          width: term.cols,
          height: term.rows
        });
      }

      ws.addEventListener('open', () => {
        statusNode.textContent = 'connected';
        sendResize();
      });

      ws.addEventListener('message', (event) => {
        const message = JSON.parse(event.data);
        if (message.type === 'output') {
          term.write(message.data || '');
          return;
        }
        if (message.type === 'shutdown') {
          term.writeln('\\r\\n[session ended]');
        }
      });

      ws.addEventListener('close', () => {
        statusNode.textContent = 'closed';
        term.writeln('\\r\\n[connection closed]');
      });

      ws.addEventListener('error', () => {
        statusNode.textContent = 'error';
      });

      term.onData((data) => {
        sendMessage({type: 'input.text', data});
      });

      let resizeTimer = null;
      window.addEventListener('resize', () => {
        clearTimeout(resizeTimer);
        resizeTimer = setTimeout(sendResize, 50);
      });
    </script>
  </body>
</html>
''';
}

String _normalizePath(String path, {bool allowRoot = false}) {
  final trimmed = path.trim();
  if (trimmed.isEmpty) {
    return allowRoot ? '/' : '/ws';
  }
  if (trimmed == '/') return '/';
  return trimmed.startsWith('/') ? trimmed : '/$trimmed';
}

String _escapeHtml(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}
