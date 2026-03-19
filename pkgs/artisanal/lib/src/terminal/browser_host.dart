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
  }) {
    final reportedColorScheme = _prefersDarkColorScheme(background) ? 1 : 2;
    final cssColorScheme = reportedColorScheme == 1 ? 'dark' : 'light';
    final reportedForegroundColor = _oscColorReply(10, foreground);
    final reportedBackgroundColor = _oscColorReply(11, background);
    final reportedCursorColor = _oscColorReply(12, cursor);
    return '''
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>${_escapeHtml(title)}</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@xterm/xterm@5.5.0/css/xterm.css">
    <style>
      :root { color-scheme: $cssColorScheme; }
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
      const requestColorScheme = '\\x1b[?996n';
      const requestPrimaryDeviceAttributes = '\\x1b[?c';
      const requestSecondaryDeviceAttributes = '\\x1b[>c';
      const requestTerminalVersion = '\\x1b[>0q';
      const requestTermcapPrefix = '\\x1bP+q';
      const stringTerminator = '\\x1b\\\\';
      const requestKittyKeyboard = '\\x1b[?u';
      const requestCursorPosition = '\\x1b[6n';
      const requestExtendedCursorPosition = '\\x1b[?6n';
      const requestWindowSize = '\\x1b[18t';
      const requestWindowPixelSize = '\\x1b[14t';
      const requestCellSize = '\\x1b[16t';
      const requestClipboardPrefix = '\\x1b]52;';
      const oscBell = '\\x07';
      const requestForegroundColor = '\\x1b]10;?\\x07';
      const requestBackgroundColor = '\\x1b]11;?\\x07';
      const requestCursorColor = '\\x1b]12;?\\x07';
      const enableFocusReporting = '\\x1b[?1004h';
      const disableFocusReporting = '\\x1b[?1004l';
      const enableBracketedPaste = '\\x1b[?2004h';
      const disableBracketedPaste = '\\x1b[?2004l';
      const reportedColorScheme = $reportedColorScheme;
      const reportedForegroundColor = ${_javaScriptStringLiteral(reportedForegroundColor)};
      const reportedBackgroundColor = ${_javaScriptStringLiteral(reportedBackgroundColor)};
      const reportedCursorColor = ${_javaScriptStringLiteral(reportedCursorColor)};
      const reportedPrimaryDeviceAttributes = '\\x1b[?1;2c';
      const reportedSecondaryDeviceAttributes = '\\x1b[>0;0;0c';
      const reportedKittyKeyboard = '\\x1b[?u';
      const reportedTerminalVersion = '\\x1bP>|xterm.js browser host\\x1b\\\\';
      const focusInReport = '\\x1b[I';
      const focusOutReport = '\\x1b[O';
      endpointNode.textContent = wsUrl;
      const ws = new WebSocket(wsUrl);
      let focusReportingEnabled = false;
      let bracketedPasteEnabled = false;

      function sendMessage(message) {
        if (ws.readyState === WebSocket.OPEN) {
          ws.send(JSON.stringify(message));
        }
      }

      function publishFocusState(hasFocus) {
        if (!focusReportingEnabled) {
          return;
        }
        sendMessage({
          type: 'input.text',
          data: hasFocus ? focusInReport : focusOutReport
        });
      }

      function terminalPixelSize() {
        const rect = terminalNode.getBoundingClientRect();
        return {
          width: Math.max(0, Math.round(rect.width)),
          height: Math.max(0, Math.round(rect.height))
        };
      }

      function terminalCellSize() {
        const pixels = terminalPixelSize();
        return {
          width: term.cols > 0 ? Math.max(0, Math.round(pixels.width / term.cols)) : 0,
          height: term.rows > 0 ? Math.max(0, Math.round(pixels.height / term.rows)) : 0
        };
      }

      function cursorPositionReport(extended) {
        const cursorX =
          term.buffer && term.buffer.active
            ? term.buffer.active.cursorX
            : 0;
        const cursorY =
          term.buffer && term.buffer.active
            ? term.buffer.active.cursorY
            : 0;
        const row = cursorY + 1;
        const col = cursorX + 1;
        return extended
          ? `\\x1b[?\${row};\${col}R`
          : `\\x1b[\${row};\${col}R`;
      }

      function decodeHexBytes(hex) {
        if (!hex || (hex.length % 2) !== 0) {
          return null;
        }
        let text = '';
        for (let i = 0; i < hex.length; i += 2) {
          const value = Number.parseInt(hex.slice(i, i + 2), 16);
          if (Number.isNaN(value)) {
            return null;
          }
          text += String.fromCharCode(value);
        }
        return text;
      }

      function encodeHexBytes(text) {
        let hex = '';
        for (let i = 0; i < text.length; i += 1) {
          hex += text.charCodeAt(i).toString(16).padStart(2, '0');
        }
        return hex;
      }

      function termcapResponsePayload(requestPayload) {
        const parts = [];
        for (const encodedName of requestPayload.split(';')) {
          if (!encodedName) {
            continue;
          }
          const name = decodeHexBytes(encodedName);
          if (name === null) {
            return null;
          }
          if (name === 'RGB') {
            parts.push(encodeHexBytes('RGB'));
            continue;
          }
          if (name === 'TN') {
            parts.push(encodeHexBytes('TN') + '=' + encodeHexBytes('xterm.js'));
          }
        }
        return parts.length > 0 ? parts.join(';') : null;
      }

      function encodeBase64Utf8(text) {
        const bytes = new TextEncoder().encode(text);
        let binary = '';
        for (const byte of bytes) {
          binary += String.fromCharCode(byte);
        }
        return btoa(binary);
      }

      function decodeBase64Utf8(text) {
        try {
          const binary = atob(text);
          const bytes = Uint8Array.from(binary, (char) => char.charCodeAt(0));
          return new TextDecoder().decode(bytes);
        } catch (_) {
          return text;
        }
      }

      function clipboardResponse(selection, text) {
        return `\\x1b]52;\${selection};\${encodeBase64Utf8(text)}\\x07`;
      }

      function writeClipboardText(text) {
        if (!window.isSecureContext ||
            !navigator.clipboard ||
            !navigator.clipboard.writeText) {
          return;
        }
        navigator.clipboard.writeText(text).catch(() => {});
      }

      function readClipboardText(selection) {
        if (!window.isSecureContext ||
            !navigator.clipboard ||
            !navigator.clipboard.readText) {
          sendMessage({
            type: 'input.text',
            data: clipboardResponse(selection, '')
          });
          return;
        }
        navigator.clipboard.readText()
          .then((text) => {
            sendMessage({
              type: 'input.text',
              data: clipboardResponse(selection, text)
            });
          })
          .catch(() => {
            sendMessage({
              type: 'input.text',
              data: clipboardResponse(selection, '')
            });
          });
      }

      function clipboardQueryInfo(data) {
        if (!data.startsWith(requestClipboardPrefix)) {
          return null;
        }

        const start = requestClipboardPrefix.length;
        const bellIndex = data.indexOf(oscBell, start);
        const stIndex = data.indexOf(stringTerminator, start);
        let end = -1;
        let terminatorLength = 0;

        if (bellIndex !== -1 && (stIndex === -1 || bellIndex < stIndex)) {
          end = bellIndex;
          terminatorLength = oscBell.length;
        } else if (stIndex !== -1) {
          end = stIndex;
          terminatorLength = stringTerminator.length;
        }

        if (end === -1) {
          return null;
        }

        const payload = data.slice(start, end);
        const separator = payload.indexOf(';');
        if (separator === -1 || separator === 0) {
          return null;
        }

        return {
          selection: payload.slice(0, separator)[0],
          content: payload.slice(separator + 1),
          consumed: end + terminatorLength,
        };
      }

      function stripAndReplyTerminalQueries(data) {
        let remaining = data || '';
        let visible = '';

        while (remaining.length > 0) {
          const clipboard = clipboardQueryInfo(remaining);
          if (clipboard !== null) {
            if (clipboard.content === '?') {
              readClipboardText(clipboard.selection);
            } else {
              writeClipboardText(decodeBase64Utf8(clipboard.content));
            }
            remaining = remaining.slice(clipboard.consumed);
            continue;
          }
          if (remaining.startsWith(requestColorScheme)) {
            sendMessage({
              type: 'input.text',
              data: `\\x1b[?997;${reportedColorScheme}n`
            });
            remaining = remaining.slice(requestColorScheme.length);
            continue;
          }
          if (remaining.startsWith(requestPrimaryDeviceAttributes)) {
            sendMessage({
              type: 'input.text',
              data: reportedPrimaryDeviceAttributes
            });
            remaining = remaining.slice(requestPrimaryDeviceAttributes.length);
            continue;
          }
          if (remaining.startsWith(requestSecondaryDeviceAttributes)) {
            sendMessage({
              type: 'input.text',
              data: reportedSecondaryDeviceAttributes
            });
            remaining = remaining.slice(requestSecondaryDeviceAttributes.length);
            continue;
          }
          if (remaining.startsWith(requestTerminalVersion)) {
            sendMessage({
              type: 'input.text',
              data: reportedTerminalVersion
            });
            remaining = remaining.slice(requestTerminalVersion.length);
            continue;
          }
          if (remaining.startsWith(requestTermcapPrefix)) {
            const terminatorIndex = remaining.indexOf(
              stringTerminator,
              requestTermcapPrefix.length
            );
            if (terminatorIndex !== -1) {
              const requestPayload = remaining.slice(
                requestTermcapPrefix.length,
                terminatorIndex
              );
              const responsePayload = termcapResponsePayload(requestPayload);
              if (responsePayload !== null) {
                sendMessage({
                  type: 'input.text',
                  data: '\\x1bP1+r' + responsePayload + '\\x1b\\\\'
                });
              }
              remaining = remaining.slice(
                terminatorIndex + stringTerminator.length
              );
              continue;
            }
          }
          if (remaining.startsWith(requestKittyKeyboard)) {
            sendMessage({
              type: 'input.text',
              data: reportedKittyKeyboard
            });
            remaining = remaining.slice(requestKittyKeyboard.length);
            continue;
          }
          if (remaining.startsWith(requestCursorPosition)) {
            sendMessage({
              type: 'input.text',
              data: cursorPositionReport(false)
            });
            remaining = remaining.slice(requestCursorPosition.length);
            continue;
          }
          if (remaining.startsWith(requestExtendedCursorPosition)) {
            sendMessage({
              type: 'input.text',
              data: cursorPositionReport(true)
            });
            remaining = remaining.slice(requestExtendedCursorPosition.length);
            continue;
          }
          if (remaining.startsWith(requestWindowSize)) {
            sendMessage({
              type: 'input.text',
              data: `\\x1b[8;\${term.rows};\${term.cols}t`
            });
            remaining = remaining.slice(requestWindowSize.length);
            continue;
          }
          if (remaining.startsWith(requestWindowPixelSize)) {
            const pixels = terminalPixelSize();
            sendMessage({
              type: 'input.text',
              data: `\\x1b[4;\${pixels.height};\${pixels.width}t`
            });
            remaining = remaining.slice(requestWindowPixelSize.length);
            continue;
          }
          if (remaining.startsWith(requestCellSize)) {
            const cell = terminalCellSize();
            sendMessage({
              type: 'input.text',
              data: `\\x1b[6;\${cell.height};\${cell.width}t`
            });
            remaining = remaining.slice(requestCellSize.length);
            continue;
          }
          if (remaining.startsWith(requestForegroundColor)) {
            if (reportedForegroundColor !== null) {
              sendMessage({
                type: 'input.text',
                data: reportedForegroundColor
              });
            }
            remaining = remaining.slice(requestForegroundColor.length);
            continue;
          }
          if (remaining.startsWith(requestBackgroundColor)) {
            if (reportedBackgroundColor !== null) {
              sendMessage({
                type: 'input.text',
                data: reportedBackgroundColor
              });
            }
            remaining = remaining.slice(requestBackgroundColor.length);
            continue;
          }
          if (remaining.startsWith(requestCursorColor)) {
            if (reportedCursorColor !== null) {
              sendMessage({
                type: 'input.text',
                data: reportedCursorColor
              });
            }
            remaining = remaining.slice(requestCursorColor.length);
            continue;
          }
          if (remaining.startsWith(enableFocusReporting)) {
            focusReportingEnabled = true;
            if (document.hasFocus()) {
              publishFocusState(true);
            }
            remaining = remaining.slice(enableFocusReporting.length);
            continue;
          }
          if (remaining.startsWith(disableFocusReporting)) {
            focusReportingEnabled = false;
            remaining = remaining.slice(disableFocusReporting.length);
            continue;
          }
          if (remaining.startsWith(enableBracketedPaste)) {
            bracketedPasteEnabled = true;
            remaining = remaining.slice(enableBracketedPaste.length);
            continue;
          }
          if (remaining.startsWith(disableBracketedPaste)) {
            bracketedPasteEnabled = false;
            remaining = remaining.slice(disableBracketedPaste.length);
            continue;
          }

          visible += remaining[0];
          remaining = remaining.slice(1);
        }

        return visible;
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
          const renderable = stripAndReplyTerminalQueries(message.data || '');
          if (renderable.length > 0) {
            term.write(renderable);
          }
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
      window.addEventListener('focus', () => publishFocusState(true));
      window.addEventListener('blur', () => publishFocusState(false));
      window.addEventListener('paste', (event) => {
        if (!bracketedPasteEnabled) {
          return;
        }
        const text = event.clipboardData
          ? event.clipboardData.getData('text/plain')
          : '';
        if (!text) {
          return;
        }
        event.preventDefault();
        sendMessage({
          type: 'input.text',
          data: `\\x1b[200~\${text}\\x1b[201~`
        });
      });
    </script>
  </body>
</html>
''';
  }
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

bool _prefersDarkColorScheme(String background) {
  final hex = _normalizedHexColor(background);
  if (hex == null) return true;

  final red = int.parse(hex.substring(0, 2), radix: 16);
  final green = int.parse(hex.substring(2, 4), radix: 16);
  final blue = int.parse(hex.substring(4, 6), radix: 16);
  final luminance = ((0.2126 * red) + (0.7152 * green) + (0.0722 * blue)) / 255;
  return luminance < 0.5;
}

String? _oscColorReply(int slot, String color) {
  final hex = _normalizedHexColor(color);
  if (hex == null) return null;

  final red = hex.substring(0, 2);
  final green = hex.substring(2, 4);
  final blue = hex.substring(4, 6);
  return '\\x1b]$slot;rgb:$red$red/$green$green/$blue$blue\\x07';
}

String? _normalizedHexColor(String color) {
  final normalized = color.trim();
  final hex = switch (normalized.length) {
    4 when normalized.startsWith('#') =>
      '${normalized[1]}${normalized[1]}'
      '${normalized[2]}${normalized[2]}'
      '${normalized[3]}${normalized[3]}',
    7 when normalized.startsWith('#') => normalized.substring(1),
    _ => null,
  };
  if (hex == null) return null;

  final red = int.tryParse(hex.substring(0, 2), radix: 16);
  final green = int.tryParse(hex.substring(2, 4), radix: 16);
  final blue = int.tryParse(hex.substring(4, 6), radix: 16);
  if (red == null || green == null || blue == null) {
    return null;
  }

  return hex.toLowerCase();
}

String _javaScriptStringLiteral(String? value) {
  if (value == null) return 'null';
  final escaped = value
      .replaceAll('\\', r'\\')
      .replaceAll("'", r"\'");
  return "'$escaped'";
}
