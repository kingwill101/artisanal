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
          defaultPageHtml(title: title, webSocketPath: normalizedWebSocketPath),
      onSession: onSession,
    );
    host._subscription = server.listen((request) {
      unawaited(host._handleRequestSafely(request));
    }, cancelOnError: false);
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
        response.statusCode = error is io.WebSocketException
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
    String lightBackground = '#f8fafc',
    String lightForeground = '#0f172a',
    String lightCursor = '#2563eb',
    String lightSelectionBackground = '#cbd5e1',
  }) {
    final cssColorScheme = _prefersDarkColorScheme(background)
        ? 'dark light'
        : 'light dark';
    final darkToolbarStart =
        _blendHexColor(background, foreground, 0.08) ?? '#161c25';
    final darkToolbarEnd =
        _blendHexColor(background, foreground, 0.04) ?? '#121720';
    final darkToolbarBorder =
        _blendHexColor(background, foreground, 0.18) ?? '#202938';
    final darkBadgeBackground =
        _blendHexColor(background, foreground, 0.12) ?? '#1f2937';
    final darkBadgeForeground =
        _blendHexColor(foreground, background, 0.22) ?? '#9fb3c8';
    final lightToolbarStart =
        _blendHexColor(lightBackground, lightForeground, 0.08) ?? '#e8edf3';
    final lightToolbarEnd =
        _blendHexColor(lightBackground, lightForeground, 0.04) ?? '#eef2f7';
    final lightToolbarBorder =
        _blendHexColor(lightBackground, lightForeground, 0.18) ?? '#cbd5e1';
    final lightBadgeBackground =
        _blendHexColor(lightBackground, lightForeground, 0.12) ?? '#e2e8f0';
    final lightBadgeForeground =
        _blendHexColor(lightForeground, lightBackground, 0.22) ?? '#334155';
    return '''
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>${_escapeHtml(title)}</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@xterm/xterm@5.5.0/css/xterm.css">
    <style>
      :root {
        color-scheme: $cssColorScheme;
        --page-background: $background;
        --page-foreground: $foreground;
        --toolbar-start: $darkToolbarStart;
        --toolbar-end: $darkToolbarEnd;
        --toolbar-border: $darkToolbarBorder;
        --badge-background: $darkBadgeBackground;
        --badge-foreground: $darkBadgeForeground;
      }
      @media (prefers-color-scheme: light) {
        :root {
          --page-background: $lightBackground;
          --page-foreground: $lightForeground;
          --toolbar-start: $lightToolbarStart;
          --toolbar-end: $lightToolbarEnd;
          --toolbar-border: $lightToolbarBorder;
          --badge-background: $lightBadgeBackground;
          --badge-foreground: $lightBadgeForeground;
        }
      }
      html, body {
        margin: 0;
        height: 100%;
        background: var(--page-background);
        color: var(--page-foreground);
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
        border-bottom: 1px solid var(--toolbar-border, #202938);
        background: linear-gradient(
          180deg,
          var(--toolbar-start, #161c25),
          var(--toolbar-end, #121720)
        );
      }
      .badge {
        padding: 4px 8px;
        border-radius: 999px;
        font-size: 12px;
        background: var(--badge-background, #1f2937);
        color: var(--badge-foreground, #9fb3c8);
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
      <strong id="title">${_escapeHtml(title)}</strong>
      <span class="badge" id="endpoint"></span>
      <span class="badge" id="status">connecting</span>
    </div>
    <div id="terminal"></div>

    <script src="https://cdn.jsdelivr.net/npm/@xterm/xterm@5.5.0/lib/xterm.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/@xterm/addon-fit@0.10.0/lib/addon-fit.js"></script>
    <script>
      const terminalNode = document.getElementById('terminal');
      const toolbarNode = document.querySelector('.toolbar');
      const titleNode = document.getElementById('title');
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
      const requestModifyOtherKeys = '\\x1b[?4m';
      const requestPrivateModePrefix = '\\x1b[?';
      const requestModeSuffix = '\$p';
      const requestPrimaryDeviceAttributes = '\\x1b[?c';
      const requestSecondaryDeviceAttributes = '\\x1b[>c';
      const requestTertiaryDeviceAttributes = '\\x1b[=c';
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
      const requestPalettePrefix = '\\x1b]4;';
      const resetPalettePrefix = '\\x1b]104;';
      const titleOsc0Prefix = '\\x1b]0;';
      const titleOsc2Prefix = '\\x1b]2;';
      const setForegroundPrefix = '\\x1b]10;';
      const setBackgroundPrefix = '\\x1b]11;';
      const setCursorPrefix = '\\x1b]12;';
      const resetForegroundSequence = '\\x1b]110\\x07';
      const resetBackgroundSequence = '\\x1b]111\\x07';
      const resetCursorSequence = '\\x1b]112\\x07';
      const oscBell = '\\x07';
      const requestForegroundColor = '\\x1b]10;?\\x07';
      const requestBackgroundColor = '\\x1b]11;?\\x07';
      const requestCursorColor = '\\x1b]12;?\\x07';
      const enableFocusReporting = '\\x1b[?1004h';
      const disableFocusReporting = '\\x1b[?1004l';
      const enableBracketedPaste = '\\x1b[?2004h';
      const disableBracketedPaste = '\\x1b[?2004l';
      const enableMouseNormal = '\\x1b[?1000h';
      const disableMouseNormal = '\\x1b[?1000l';
      const enableMouseButton = '\\x1b[?1002h';
      const disableMouseButton = '\\x1b[?1002l';
      const enableMouseAny = '\\x1b[?1003h';
      const disableMouseAny = '\\x1b[?1003l';
      const enableMouseSgr = '\\x1b[?1006h';
      const disableMouseSgr = '\\x1b[?1006l';
      const reportedPrimaryDeviceAttributes = '\\x1b[?1;2c';
      const reportedSecondaryDeviceAttributes = '\\x1b[>0;0;0c';
      const reportedTertiaryDeviceAttributes = '\\x1bP!|787465726d2e6a73\\x1b\\\\';
      const reportedKittyKeyboard = '\\x1b[?u';
      const reportedTerminalVersion = '\\x1bP>|xterm.js browser host\\x1b\\\\';
      const focusInReport = '\\x1b[I';
      const focusOutReport = '\\x1b[O';
      endpointNode.textContent = wsUrl;
      const ws = new WebSocket(wsUrl);
      let focusReportingEnabled = false;
      let bracketedPasteEnabled = false;
      let mouseNormalEnabled = false;
      let mouseButtonEnabled = false;
      let mouseAnyEnabled = false;
      let mouseSgrEnabled = false;
      let modifyOtherKeysMode = 0;
      const darkTheme = {
        background: '$background',
        foreground: '$foreground',
        cursor: '$cursor',
        selectionBackground: '$selectionBackground'
      };
      const lightTheme = {
        background: '$lightBackground',
        foreground: '$lightForeground',
        cursor: '$lightCursor',
        selectionBackground: '$lightSelectionBackground'
      };
      const colorSchemeMedia =
        typeof window.matchMedia === 'function'
          ? window.matchMedia('(prefers-color-scheme: dark)')
          : null;
      let activeDefaultTheme = darkTheme;
      let currentBackground = darkTheme.background;
      let currentForeground = darkTheme.foreground;
      let currentCursor = darkTheme.cursor;
      let currentSelectionBackground = darkTheme.selectionBackground;
      const darkPalette = {
        0: '#000000',
        1: '#cd0000',
        2: '#00cd00',
        3: '#cdcd00',
        4: '#0000ee',
        5: '#cd00cd',
        6: '#00cdcd',
        7: '#e5e5e5',
        8: '#7f7f7f',
        9: '#ff0000',
        10: '#00ff00',
        11: '#ffff00',
        12: '#5c5cff',
        13: '#ff00ff',
        14: '#00ffff',
        15: '#ffffff'
      };
      const lightPalette = {
        0: '#333333',
        1: '#cd3131',
        2: '#00bc00',
        3: '#949800',
        4: '#0451a5',
        5: '#bc05bc',
        6: '#0598bc',
        7: '#555555',
        8: '#666666',
        9: '#cd3131',
        10: '#14ce14',
        11: '#b5ba00',
        12: '#0451a5',
        13: '#bc05bc',
        14: '#0598bc',
        15: '#a5a5a5'
      };
      let activeDefaultPalette = darkPalette;
      const currentPalette = new Map();

      function sendMessage(message) {
        if (ws.readyState === WebSocket.OPEN) {
          ws.send(JSON.stringify(message));
        }
      }

      function setBrowserTitle(title) {
        document.title = title;
        if (titleNode) {
          titleNode.textContent = title;
        }
      }

      function prefersDarkBackground(color) {
        if (!color || !color.startsWith('#')) {
          return true;
        }
        const normalized =
          color.length === 4
            ? '#' + color[1] + color[1] + color[2] + color[2] + color[3] + color[3]
            : color;
        if (normalized.length !== 7) {
          return true;
        }
        const red = Number.parseInt(normalized.slice(1, 3), 16);
        const green = Number.parseInt(normalized.slice(3, 5), 16);
        const blue = Number.parseInt(normalized.slice(5, 7), 16);
        if ([red, green, blue].some((value) => Number.isNaN(value))) {
          return true;
        }
        const luminance =
          ((0.2126 * red) + (0.7152 * green) + (0.0722 * blue)) / 255;
        return luminance < 0.5;
      }

      function normalizeOscColor(value) {
        if (!value) {
          return null;
        }
        const trimmed = value.trim();
        if (trimmed.startsWith('#')) {
          if (trimmed.length === 4) {
            return (
              '#' +
              trimmed[1] + trimmed[1] +
              trimmed[2] + trimmed[2] +
              trimmed[3] + trimmed[3]
            ).toLowerCase();
          }
          if (trimmed.length === 7) {
            return trimmed.toLowerCase();
          }
          return null;
        }
        if (trimmed.startsWith('rgb:')) {
          const parts = trimmed.slice(4).split('/');
          if (parts.length !== 3) {
            return null;
          }
          const channels = [];
          for (const part of parts) {
            if (part.length < 2 || part.length > 4) {
              return null;
            }
            const expanded =
              part.length === 2
                ? part
                : part.slice(0, 2);
            const value = Number.parseInt(expanded, 16);
            if (Number.isNaN(value)) {
              return null;
            }
            channels.push(expanded.toLowerCase());
          }
          return '#' + channels.join('');
        }
        return null;
      }

      function hexChannels(color) {
        const normalized = normalizeOscColor(color);
        if (normalized === null) {
          return null;
        }
        return {
          red: Number.parseInt(normalized.slice(1, 3), 16),
          green: Number.parseInt(normalized.slice(3, 5), 16),
          blue: Number.parseInt(normalized.slice(5, 7), 16)
        };
      }

      function mixHexColors(start, end, amount) {
        const left = hexChannels(start);
        const right = hexChannels(end);
        if (left === null || right === null) {
          return start;
        }
        const ratio = Math.max(0, Math.min(1, amount));
        const mixChannel = (from, to) =>
          Math.round(from + ((to - from) * ratio))
            .toString(16)
            .padStart(2, '0');
        return (
          '#' +
          mixChannel(left.red, right.red) +
          mixChannel(left.green, right.green) +
          mixChannel(left.blue, right.blue)
        );
      }

      function applyTerminalTheme() {
        term.options.theme = {
          ...(term.options.theme || {}),
          background: currentBackground,
          foreground: currentForeground,
          cursor: currentCursor,
          selectionBackground: currentSelectionBackground
        };
        document.body.style.background = currentBackground;
        document.body.style.color = currentForeground;
        document.documentElement.style.colorScheme =
          prefersDarkBackground(currentBackground) ? 'dark' : 'light';
        document.documentElement.style.setProperty(
          '--toolbar-start',
          mixHexColors(currentBackground, currentForeground, 0.08)
        );
        document.documentElement.style.setProperty(
          '--toolbar-end',
          mixHexColors(currentBackground, currentForeground, 0.04)
        );
        document.documentElement.style.setProperty(
          '--toolbar-border',
          mixHexColors(currentBackground, currentForeground, 0.18)
        );
        document.documentElement.style.setProperty(
          '--badge-background',
          mixHexColors(currentBackground, currentForeground, 0.12)
        );
        document.documentElement.style.setProperty(
          '--badge-foreground',
          mixHexColors(currentForeground, currentBackground, 0.22)
        );
        if (toolbarNode) {
          toolbarNode.style.color = currentForeground;
        }
      }

      function preferredTheme() {
        return colorSchemeMedia && !colorSchemeMedia.matches
          ? lightTheme
          : darkTheme;
      }

      function preferredPalette() {
        return colorSchemeMedia && !colorSchemeMedia.matches
          ? lightPalette
          : darkPalette;
      }

      function sameTheme(left, right) {
        return (
          left.background === right.background &&
          left.foreground === right.foreground &&
          left.cursor === right.cursor &&
          left.selectionBackground === right.selectionBackground
        );
      }

      function usingDefaultTheme() {
        return sameTheme(
          {
            background: currentBackground,
            foreground: currentForeground,
            cursor: currentCursor,
            selectionBackground: currentSelectionBackground
          },
          activeDefaultTheme
        );
      }

      function applyDefaultTheme(theme) {
        activeDefaultTheme = theme;
        currentBackground = theme.background;
        currentForeground = theme.foreground;
        currentCursor = theme.cursor;
        currentSelectionBackground = theme.selectionBackground;
        applyTerminalTheme();
      }

      function samePalette(current, target) {
        const targetEntries = Object.entries(target);
        if (current.size !== targetEntries.length) {
          return false;
        }
        for (const [index, color] of targetEntries) {
          if ((current.get(index) || '').toLowerCase() !== color.toLowerCase()) {
            return false;
          }
        }
        return true;
      }

      function usingDefaultPalette() {
        return samePalette(currentPalette, activeDefaultPalette);
      }

      function applyDefaultPalette(palette) {
        activeDefaultPalette = palette;
        currentPalette.clear();
        for (const [index, color] of Object.entries(palette)) {
          currentPalette.set(index, color);
        }
      }

      function currentColorSchemeReport() {
        return prefersDarkBackground(currentBackground) ? 1 : 2;
      }

      function publishColorSchemeReport() {
        sendMessage({
          type: 'input.text',
          data: `\\x1b[?997;\${currentColorSchemeReport()}n`
        });
      }

      function handlePreferredColorSchemeChange() {
        const nextTheme = preferredTheme();
        const nextPalette = preferredPalette();
        if (usingDefaultTheme()) {
          applyDefaultTheme(nextTheme);
          publishColorSchemeReport();
        } else {
          activeDefaultTheme = nextTheme;
        }
        if (usingDefaultPalette()) {
          applyDefaultPalette(nextPalette);
        } else {
          activeDefaultPalette = nextPalette;
        }
      }

      function modifyOtherKeysReport() {
        return `\\x1b[>4;\${modifyOtherKeysMode}m`;
      }

      function oscColorReply(index, color) {
        const normalized = normalizeOscColor(color);
        if (normalized === null || normalized.length !== 7) {
          return null;
        }
        const red = normalized.slice(1, 3);
        const green = normalized.slice(3, 5);
        const blue = normalized.slice(5, 7);
        return (
          `\\x1b]\${index};rgb:` +
          `\${red}\${red}/\${green}\${green}/\${blue}\${blue}\\x07`
        );
      }

      function oscPaletteReply(index, color) {
        return oscColorReply('4;' + index, color);
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

      function paletteQueryInfo(data, prefix) {
        if (!data.startsWith(prefix)) {
          return null;
        }

        const start = prefix.length;
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

        const indexText = payload.slice(0, separator);
        if (Array.from(indexText).some((ch) => ch < '0' || ch > '9')) {
          return null;
        }

        return {
          index: indexText,
          content: payload.slice(separator + 1),
          consumed: end + terminatorLength,
        };
      }

      function paletteResetInfo(data) {
        if (!data.startsWith(resetPalettePrefix)) {
          return null;
        }

        const start = resetPalettePrefix.length;
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

        const payload = data.slice(start, end).trim();
        if (payload.length === 0) {
          return {
            index: null,
            consumed: end + terminatorLength,
          };
        }
        if (Array.from(payload).some((ch) => ch < '0' || ch > '9')) {
          return null;
        }

        return {
          index: payload,
          consumed: end + terminatorLength,
        };
      }

      function modeReportInfo(data) {
        if (!data.startsWith(requestPrivateModePrefix)) {
          return null;
        }

        const suffixIndex = data.indexOf(
          requestModeSuffix,
          requestPrivateModePrefix.length
        );
        if (suffixIndex === -1) {
          return null;
        }

        const digits = data.slice(requestPrivateModePrefix.length, suffixIndex);
        if (!digits || Array.from(digits).some((ch) => ch < '0' || ch > '9')) {
          return null;
        }

        return {
          mode: Number.parseInt(digits, 10),
          consumed: suffixIndex + requestModeSuffix.length,
        };
      }

      function modeReportValue(mode) {
        switch (mode) {
          case 1000:
            return mouseNormalEnabled ? 1 : 2;
          case 1002:
            return mouseButtonEnabled ? 1 : 2;
          case 1003:
            return mouseAnyEnabled ? 1 : 2;
          case 1004:
            return focusReportingEnabled ? 1 : 2;
          case 1006:
            return mouseSgrEnabled ? 1 : 2;
          case 2004:
            return bracketedPasteEnabled ? 1 : 2;
          default:
            return 0;
        }
      }

      function modifyOtherKeysInfo(data) {
        if (!data.startsWith('\\x1b[>4')) {
          return null;
        }
        if (data.startsWith('\\x1b[>4m')) {
          return {
            mode: 0,
            consumed: '\\x1b[>4m'.length,
          };
        }
        if (!data.startsWith('\\x1b[>4;')) {
          return null;
        }

        const suffixIndex = data.indexOf('m', '\\x1b[>4;'.length);
        if (suffixIndex === -1) {
          return null;
        }

        const digits = data.slice('\\x1b[>4;'.length, suffixIndex);
        if (!digits || Array.from(digits).some((ch) => ch < '0' || ch > '9')) {
          return null;
        }

        return {
          mode: Number.parseInt(digits, 10),
          consumed: suffixIndex + 1,
        };
      }

      function oscTitleInfo(data) {
        let prefix = null;
        if (data.startsWith(titleOsc0Prefix)) {
          prefix = titleOsc0Prefix;
        } else if (data.startsWith(titleOsc2Prefix)) {
          prefix = titleOsc2Prefix;
        }
        if (prefix === null) {
          return null;
        }

        const start = prefix.length;
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

        return {
          title: data.slice(start, end),
          consumed: end + terminatorLength,
        };
      }

      function oscColorInfo(data, prefix) {
        if (!data.startsWith(prefix)) {
          return null;
        }

        const start = prefix.length;
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

        return {
          value: data.slice(start, end),
          consumed: end + terminatorLength,
        };
      }

      function stripAndReplyTerminalQueries(data) {
        let remaining = data || '';
        let visible = '';

        while (remaining.length > 0) {
          if (remaining.startsWith(resetForegroundSequence)) {
            currentForeground = activeDefaultTheme.foreground;
            applyTerminalTheme();
            remaining = remaining.slice(resetForegroundSequence.length);
            continue;
          }
          if (remaining.startsWith(resetBackgroundSequence)) {
            currentBackground = activeDefaultTheme.background;
            applyTerminalTheme();
            remaining = remaining.slice(resetBackgroundSequence.length);
            continue;
          }
          if (remaining.startsWith(resetCursorSequence)) {
            currentCursor = activeDefaultTheme.cursor;
            applyTerminalTheme();
            remaining = remaining.slice(resetCursorSequence.length);
            continue;
          }
          const foreground = oscColorInfo(remaining, setForegroundPrefix);
          if (foreground !== null) {
            const color = normalizeOscColor(foreground.value);
            if (color !== null) {
              currentForeground = color;
              applyTerminalTheme();
            }
            remaining = remaining.slice(foreground.consumed);
            continue;
          }
          const background = oscColorInfo(remaining, setBackgroundPrefix);
          if (background !== null) {
            const color = normalizeOscColor(background.value);
            if (color !== null) {
              currentBackground = color;
              applyTerminalTheme();
            }
            remaining = remaining.slice(background.consumed);
            continue;
          }
          const cursor = oscColorInfo(remaining, setCursorPrefix);
          if (cursor !== null) {
            const color = normalizeOscColor(cursor.value);
            if (color !== null) {
              currentCursor = color;
              applyTerminalTheme();
            }
            remaining = remaining.slice(cursor.consumed);
            continue;
          }
          const title = oscTitleInfo(remaining);
          if (title !== null) {
            setBrowserTitle(title.title);
            remaining = remaining.slice(title.consumed);
            continue;
          }
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
          const paletteReset = paletteResetInfo(remaining);
          if (paletteReset !== null) {
            if (paletteReset.index === null) {
              applyDefaultPalette(activeDefaultPalette);
            } else {
              currentPalette.set(
                paletteReset.index,
                activeDefaultPalette[paletteReset.index] ?? '#000000'
              );
            }
            remaining = remaining.slice(paletteReset.consumed);
            continue;
          }
          const palette = paletteQueryInfo(remaining, requestPalettePrefix);
          if (palette !== null) {
            if (palette.content === '?') {
              const reply = oscPaletteReply(
                palette.index,
                currentPalette.get(palette.index) ?? '#000000'
              );
              if (reply !== null) {
                sendMessage({
                  type: 'input.text',
                  data: reply
                });
              }
            } else {
              const color = normalizeOscColor(palette.content);
              if (color !== null) {
                currentPalette.set(palette.index, color);
              }
            }
            remaining = remaining.slice(palette.consumed);
            continue;
          }
          const modeReport = modeReportInfo(remaining);
          if (modeReport !== null) {
            sendMessage({
              type: 'input.text',
              data:
                `\\x1b[?\${modeReport.mode};\${modeReportValue(modeReport.mode)}\$y`
            });
            remaining = remaining.slice(modeReport.consumed);
            continue;
          }
          if (remaining.startsWith(requestColorScheme)) {
            publishColorSchemeReport();
            remaining = remaining.slice(requestColorScheme.length);
            continue;
          }
          if (remaining.startsWith(requestModifyOtherKeys)) {
            sendMessage({
              type: 'input.text',
              data: modifyOtherKeysReport()
            });
            remaining = remaining.slice(requestModifyOtherKeys.length);
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
          if (remaining.startsWith(requestTertiaryDeviceAttributes)) {
            sendMessage({
              type: 'input.text',
              data: reportedTertiaryDeviceAttributes
            });
            remaining = remaining.slice(requestTertiaryDeviceAttributes.length);
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
            const reply = oscColorReply(10, currentForeground);
            if (reply !== null) {
              sendMessage({
                type: 'input.text',
                data: reply
              });
            }
            remaining = remaining.slice(requestForegroundColor.length);
            continue;
          }
          if (remaining.startsWith(requestBackgroundColor)) {
            const reply = oscColorReply(11, currentBackground);
            if (reply !== null) {
              sendMessage({
                type: 'input.text',
                data: reply
              });
            }
            remaining = remaining.slice(requestBackgroundColor.length);
            continue;
          }
          if (remaining.startsWith(requestCursorColor)) {
            const reply = oscColorReply(12, currentCursor);
            if (reply !== null) {
              sendMessage({
                type: 'input.text',
                data: reply
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
          if (remaining.startsWith(enableMouseNormal)) {
            mouseNormalEnabled = true;
            remaining = remaining.slice(enableMouseNormal.length);
            continue;
          }
          if (remaining.startsWith(disableMouseNormal)) {
            mouseNormalEnabled = false;
            remaining = remaining.slice(disableMouseNormal.length);
            continue;
          }
          if (remaining.startsWith(enableMouseButton)) {
            mouseButtonEnabled = true;
            remaining = remaining.slice(enableMouseButton.length);
            continue;
          }
          if (remaining.startsWith(disableMouseButton)) {
            mouseButtonEnabled = false;
            remaining = remaining.slice(disableMouseButton.length);
            continue;
          }
          if (remaining.startsWith(enableMouseAny)) {
            mouseAnyEnabled = true;
            remaining = remaining.slice(enableMouseAny.length);
            continue;
          }
          if (remaining.startsWith(disableMouseAny)) {
            mouseAnyEnabled = false;
            remaining = remaining.slice(disableMouseAny.length);
            continue;
          }
          if (remaining.startsWith(enableMouseSgr)) {
            mouseSgrEnabled = true;
            remaining = remaining.slice(enableMouseSgr.length);
            continue;
          }
          if (remaining.startsWith(disableMouseSgr)) {
            mouseSgrEnabled = false;
            remaining = remaining.slice(disableMouseSgr.length);
            continue;
          }
          const modifyOtherKeys = modifyOtherKeysInfo(remaining);
          if (modifyOtherKeys !== null) {
            modifyOtherKeysMode = modifyOtherKeys.mode;
            remaining = remaining.slice(modifyOtherKeys.consumed);
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

      let resizeTimer = null;
      function scheduleResize() {
        clearTimeout(resizeTimer);
        resizeTimer = setTimeout(sendResize, 50);
      }

      if (typeof ResizeObserver !== 'undefined') {
        const resizeObserver = new ResizeObserver(() => {
          scheduleResize();
        });
        resizeObserver.observe(terminalNode);
      }

      if (colorSchemeMedia) {
        if (typeof colorSchemeMedia.addEventListener === 'function') {
          colorSchemeMedia.addEventListener('change', handlePreferredColorSchemeChange);
        } else if (typeof colorSchemeMedia.addListener === 'function') {
          colorSchemeMedia.addListener(handlePreferredColorSchemeChange);
        }
      }

      if (document.fonts && document.fonts.ready) {
        document.fonts.ready.then(() => {
          scheduleResize();
        }).catch(() => {});
      }

      applyDefaultTheme(preferredTheme());
      applyDefaultPalette(preferredPalette());

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

      window.addEventListener('resize', scheduleResize);
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

String? _blendHexColor(String start, String end, double amount) {
  final left = _normalizedHexColor(start);
  final right = _normalizedHexColor(end);
  if (left == null || right == null) {
    return null;
  }

  int channel(String hex, int offset) =>
      int.parse(hex.substring(offset, offset + 2), radix: 16);
  int mix(int from, int to) =>
      (from + ((to - from) * amount)).round().clamp(0, 255);
  final red = mix(channel(left, 0), channel(right, 0));
  final green = mix(channel(left, 2), channel(right, 2));
  final blue = mix(channel(left, 4), channel(right, 4));
  final hex =
      red.toRadixString(16).padLeft(2, '0') +
      green.toRadixString(16).padLeft(2, '0') +
      blue.toRadixString(16).padLeft(2, '0');
  return '#$hex';
}
