import 'dart:async';
import 'dart:io' as io;

import 'package:artisanal/tui.dart';
import 'package:test/test.dart';

void main() {
  group('BrowserTerminalHostServer', () {
    test('defaultPageHtml wires the websocket path and browser terminal helpers', () {
      final html = BrowserTerminalHostServer.defaultPageHtml(
        title: 'Browser Test',
        webSocketPath: '/custom-ws',
      );

      expect(html, contains('Browser Test'));
      expect(html, contains('<strong id="title">Browser Test</strong>'));
      expect(html, contains('/custom-ws'));
      expect(html, contains('convertEol: true'));
      expect(html, contains('@xterm/xterm'));
      expect(html, contains('stripAndReplyTerminalQueries'));
      expect(html, contains('xterm.js browser host'));
      expect(html, contains(r"const requestCursorPosition = '\x1b[6n';"));
      expect(
        html,
        contains(r"const requestExtendedCursorPosition = '\x1b[?6n';"),
      );
      expect(
        html,
        contains(r"const requestSecondaryDeviceAttributes = '\x1b[>c';"),
      );
      expect(
        html,
        contains(r"const requestTertiaryDeviceAttributes = '\x1b[=c';"),
      );
      expect(html, contains(r"const requestTermcapPrefix = '\x1bP+q';"));
      expect(html, contains(r"const stringTerminator = '\x1b\\';"));
      expect(html, contains(r"const requestKittyKeyboard = '\x1b[?u';"));
      expect(html, contains(r"const requestWindowSize = '\x1b[18t';"));
      expect(html, contains(r"const requestWindowPixelSize = '\x1b[14t';"));
      expect(html, contains(r"const requestCellSize = '\x1b[16t';"));
      expect(html, contains(r"const requestModifyOtherKeys = '\x1b[?4m';"));
      expect(html, contains(r"const requestClipboardPrefix = '\x1b]52;';"));
      expect(html, contains(r"const requestPalettePrefix = '\x1b]4;';"));
      expect(html, contains(r"const resetPalettePrefix = '\x1b]104;';"));
      expect(html, contains(r"const titleOsc0Prefix = '\x1b]0;';"));
      expect(html, contains(r"const titleOsc2Prefix = '\x1b]2;';"));
      expect(html, contains(r"const setForegroundPrefix = '\x1b]10;';"));
      expect(html, contains(r"const setBackgroundPrefix = '\x1b]11;';"));
      expect(html, contains(r"const setCursorPrefix = '\x1b]12;';"));
      expect(html, contains(r"const resetForegroundSequence = '\x1b]110\x07';"));
      expect(html, contains(r"const resetBackgroundSequence = '\x1b]111\x07';"));
      expect(html, contains(r"const resetCursorSequence = '\x1b]112\x07';"));
      expect(html, contains(r"const oscBell = '\x07';"));
      expect(html, contains(r"const requestPrivateModePrefix = '\x1b[?';"));
      expect(html, contains(r"const requestModeSuffix = '$p';"));
      expect(
        html,
        contains("window.matchMedia('(prefers-color-scheme: dark)')"),
      );
      expect(html, contains('const darkTheme = {'));
      expect(html, contains('const lightTheme = {'));
      expect(html, contains(r"const enableMouseNormal = '\x1b[?1000h';"));
      expect(html, contains(r"const disableMouseNormal = '\x1b[?1000l';"));
      expect(html, contains(r"const enableMouseButton = '\x1b[?1002h';"));
      expect(html, contains(r"const disableMouseButton = '\x1b[?1002l';"));
      expect(html, contains(r"const enableMouseAny = '\x1b[?1003h';"));
      expect(html, contains(r"const disableMouseAny = '\x1b[?1003l';"));
      expect(html, contains(r"const enableMouseSgr = '\x1b[?1006h';"));
      expect(html, contains(r"const disableMouseSgr = '\x1b[?1006l';"));
      expect(html, contains(r"const reportedSecondaryDeviceAttributes = '\x1b[>0;0;0c';"));
      expect(
        html,
        contains(r"const reportedTertiaryDeviceAttributes = '\x1bP!|787465726d2e6a73\x1b\\';"),
      );
      expect(html, contains(r"const reportedKittyKeyboard = '\x1b[?u';"));
      expect(html, contains('function terminalPixelSize()'));
      expect(html, contains('function terminalCellSize()'));
      expect(html, contains('function cursorPositionReport(extended)'));
      expect(html, contains('function decodeHexBytes(hex)'));
      expect(html, contains('function encodeHexBytes(text)'));
      expect(html, contains('function termcapResponsePayload(requestPayload)'));
      expect(html, contains('function encodeBase64Utf8(text)'));
      expect(html, contains('function decodeBase64Utf8(text)'));
      expect(html, contains('function clipboardResponse(selection, text)'));
      expect(html, contains('function writeClipboardText(text)'));
      expect(html, contains('function readClipboardText(selection)'));
      expect(html, contains('function clipboardQueryInfo(data)'));
      expect(html, contains('const defaultPalette = {'));
      expect(html, contains('const currentPalette = new Map(Object.entries(defaultPalette));'));
      expect(html, contains('function oscPaletteReply(index, color)'));
      expect(html, contains('function paletteQueryInfo(data, prefix)'));
      expect(html, contains('function paletteResetInfo(data)'));
      expect(html, contains('function modeReportInfo(data)'));
      expect(html, contains('function modeReportValue(mode)'));
      expect(html, contains('function modifyOtherKeysReport()'));
      expect(html, contains('function modifyOtherKeysInfo(data)'));
      expect(html, contains('function setBrowserTitle(title)'));
      expect(html, contains('function prefersDarkBackground(color)'));
      expect(html, contains('function normalizeOscColor(value)'));
      expect(html, contains('function applyTerminalTheme()'));
      expect(html, contains('function preferredTheme()'));
      expect(html, contains('function sameTheme(left, right)'));
      expect(html, contains('function usingDefaultTheme()'));
      expect(html, contains('function applyDefaultTheme(theme)'));
      expect(html, contains('function currentColorSchemeReport()'));
      expect(html, contains('function publishColorSchemeReport()'));
      expect(html, contains('function handlePreferredColorSchemeChange()'));
      expect(html, contains('function oscColorReply(index, color)'));
      expect(html, contains('function oscTitleInfo(data)'));
      expect(html, contains('function oscColorInfo(data, prefix)'));
      expect(html, contains('function scheduleResize()'));
      expect(html, contains("if (typeof ResizeObserver !== 'undefined') {"));
      expect(html, contains('const resizeObserver = new ResizeObserver(() => {'));
      expect(html, contains('resizeObserver.observe(terminalNode);'));
      expect(html, contains('if (document.fonts && document.fonts.ready) {'));
      expect(html, contains('document.fonts.ready.then(() => {'));
      expect(html, contains('data: reportedSecondaryDeviceAttributes'));
      expect(html, contains('data: reportedTertiaryDeviceAttributes'));
      expect(html, contains(r"data: '\x1bP1+r' + responsePayload + '\x1b\\'"));
      expect(html, contains('data: reportedKittyKeyboard'));
      expect(html, contains("encodeHexBytes('TN') + '=' + encodeHexBytes('xterm.js')"));
      expect(html, contains('navigator.clipboard.readText()'));
      expect(html, contains('navigator.clipboard.writeText(text).catch(() => {});'));
      expect(html, contains("if (clipboard.content === '?')"));
      expect(html, contains("const reply = oscPaletteReply("));
      expect(html, contains("currentPalette.set(palette.index, color);"));
      expect(html, contains("currentPalette.clear();"));
      expect(html, contains('setBrowserTitle(title.title);'));
      expect(html, contains('currentForeground = activeDefaultTheme.foreground;'));
      expect(html, contains('currentBackground = activeDefaultTheme.background;'));
      expect(html, contains('currentCursor = activeDefaultTheme.cursor;'));
      expect(html, contains('currentForeground = color;'));
      expect(html, contains('currentBackground = color;'));
      expect(html, contains('currentCursor = color;'));
      expect(
        html,
        contains(r"data: `\x1b[?997;${currentColorSchemeReport()}n`"),
      );
      expect(html, contains('const reply = oscColorReply(10, currentForeground);'));
      expect(html, contains('const reply = oscColorReply(11, currentBackground);'));
      expect(html, contains('const reply = oscColorReply(12, currentCursor);'));
      expect(html, contains('currentSelectionBackground = theme.selectionBackground;'));
      expect(html, contains('currentForeground = activeDefaultTheme.foreground;'));
      expect(html, contains('currentBackground = activeDefaultTheme.background;'));
      expect(html, contains('currentCursor = activeDefaultTheme.cursor;'));
      expect(html, contains('document.documentElement.style.colorScheme ='));
      expect(html, contains('case 1004:'));
      expect(html, contains('case 1000:'));
      expect(html, contains('case 1002:'));
      expect(html, contains('case 1003:'));
      expect(html, contains('case 1006:'));
      expect(html, contains('case 2004:'));
      expect(html, contains('mouseNormalEnabled = true;'));
      expect(html, contains('mouseButtonEnabled = true;'));
      expect(html, contains('mouseAnyEnabled = true;'));
      expect(html, contains('mouseSgrEnabled = true;'));
      expect(html, contains('let modifyOtherKeysMode = 0;'));
      expect(html, contains(r"`\x1b[?${modeReport.mode};${modeReportValue(modeReport.mode)}$y`"));
      expect(html, contains('data: modifyOtherKeysReport()'));
      expect(html, contains('modifyOtherKeysMode = modifyOtherKeys.mode;'));
      expect(html, contains("data: cursorPositionReport(false)"));
      expect(html, contains("data: cursorPositionReport(true)"));
      expect(html, contains(r"data: `\x1b[8;${term.rows};${term.cols}t`"));
      expect(
        html,
        contains(r"data: `\x1b[4;${pixels.height};${pixels.width}t`"),
      );
      expect(
        html,
        contains(r"data: `\x1b[6;${cell.height};${cell.width}t`"),
      );
      expect(html, contains("window.addEventListener('resize', scheduleResize);"));
      expect(html, contains("window.addEventListener('focus'"));
      expect(html, contains("window.addEventListener('blur'"));
      expect(html, contains("window.addEventListener('paste'"));
      expect(html, contains('colorSchemeMedia.addEventListener(\'change\', handlePreferredColorSchemeChange);'));
      expect(html, contains('colorSchemeMedia.addListener(handlePreferredColorSchemeChange);'));
      expect(html, contains('applyDefaultTheme(preferredTheme());'));
      expect(html, contains('focusReportingEnabled = true;'));
      expect(html, contains('bracketedPasteEnabled = true;'));
    });

    test('defaultPageHtml advertises support for both color schemes', () {
      final html = BrowserTerminalHostServer.defaultPageHtml(
        title: 'Light Browser Test',
        webSocketPath: '/ws',
        background: '#f8fafc',
      );

      expect(html, contains(":root { color-scheme: light dark; }"));
    });

    test('defaultPageHtml exposes a light fallback theme for browser hosts', () {
      final html = BrowserTerminalHostServer.defaultPageHtml(
        title: 'Adaptive Browser Test',
        webSocketPath: '/ws',
      );

      expect(html, contains("background: '#f8fafc'"));
      expect(html, contains("foreground: '#0f172a'"));
      expect(html, contains("cursor: '#2563eb'"));
      expect(html, contains("selectionBackground: '#cbd5e1'"));
    });

    test('bind serves the page and a 404 for unknown routes', () async {
      final server = await BrowserTerminalHostServer.bind(
        port: 0,
        title: 'Bind Test',
        onSession: (_) async {},
      );
      addTearDown(() => server.close(force: true));

      final client = io.HttpClient();
      addTearDown(() => client.close(force: true));

      final pageRequest = await client.getUrl(server.pageUri);
      final pageResponse = await pageRequest.close();
      final pageBody = await pageResponse.transform(io.systemEncoding.decoder).join();

      expect(pageResponse.statusCode, io.HttpStatus.ok);
      expect(pageBody, contains('Bind Test'));

      final notFoundRequest = await client.getUrl(
        server.pageUri.replace(path: '/missing'),
      );
      final notFoundResponse = await notFoundRequest.close();
      expect(notFoundResponse.statusCode, io.HttpStatus.notFound);
    });

    test('failed websocket upgrades return bad request and keep the host alive', () async {
      final server = await BrowserTerminalHostServer.bind(
        port: 0,
        title: 'Bad Upgrade Test',
        onSession: (_) async {},
      );
      addTearDown(() => server.close(force: true));

      final client = io.HttpClient();
      addTearDown(() => client.close(force: true));

      final badUpgradeRequest = await client.getUrl(
        server.pageUri.replace(path: server.webSocketPath),
      );
      final badUpgradeResponse = await badUpgradeRequest.close();
      await badUpgradeResponse.drain<void>();
      expect(badUpgradeResponse.statusCode, io.HttpStatus.badRequest);

      final pageRequest = await client.getUrl(server.pageUri);
      final pageResponse = await pageRequest.close();
      final pageBody = await pageResponse.transform(io.systemEncoding.decoder).join();

      expect(pageResponse.statusCode, io.HttpStatus.ok);
      expect(pageBody, contains('Bad Upgrade Test'));
    });

    test('serveProgram runs a TUI session over websocket', () async {
      final server = await BrowserTerminalHostServer.serveProgram(
        port: 0,
        title: 'Browser Host Test',
        modelBuilder: () => const _BrowserHostModel(),
        options: const ProgramOptions(
          altScreen: false,
          frameTick: false,
          signalHandlers: false,
        ),
      );
      addTearDown(() => server.close(force: true));

      final socket = await io.WebSocket.connect(server.webSocketUri.toString());
      addTearDown(() => socket.close());

      final outputReady = Completer<void>();
      final outputBuffer = StringBuffer();
      late final StreamSubscription<dynamic> subscription;
      subscription = socket.listen((event) {
        final message = TerminalBridgeMessage.decodeJson(event as String);
        if (message.type == TerminalBridgeMessageType.output) {
          outputBuffer.write(message.data ?? '');
          if (!outputReady.isCompleted &&
              outputBuffer.toString().contains('Browser Host Test Model')) {
            outputReady.complete();
          }
        }
      });
      addTearDown(subscription.cancel);

      await outputReady.future.timeout(const Duration(seconds: 5));
      socket.add(const TerminalBridgeMessage.inputText('q').encodeJson());
      await socket.done.timeout(const Duration(seconds: 5));
    });

    test(
      'websocket disconnect delivers InterruptMsg to the hosted program',
      () async {
        final interrupted = Completer<void>();
        final server = await BrowserTerminalHostServer.serveProgram(
          port: 0,
          title: 'Disconnect Test',
          modelBuilder: () => _BrowserDisconnectAwareModel(interrupted),
          options: const ProgramOptions(
            altScreen: false,
            frameTick: false,
            signalHandlers: false,
          ),
        );
        addTearDown(() => server.close(force: true));

        final socket = await io.WebSocket.connect(server.webSocketUri.toString());
        final outputReady = Completer<void>();
        late final StreamSubscription<dynamic> subscription;
        subscription = socket.listen((event) {
          final message = TerminalBridgeMessage.decodeJson(event as String);
          if (message.type == TerminalBridgeMessageType.output &&
              (message.data ?? '').contains('Browser Disconnect Model') &&
              !outputReady.isCompleted) {
            outputReady.complete();
          }
        });
        addTearDown(subscription.cancel);

        await outputReady.future.timeout(const Duration(seconds: 5));
        await socket.close();
        await interrupted.future.timeout(const Duration(seconds: 5));
      },
    );

    test('close(force: true) tears down active websocket sessions', () async {
      final sessionStarted = Completer<void>();
      final sessionDone = Completer<void>();
      final server = await BrowserTerminalHostServer.bind(
        port: 0,
        title: 'Force Close Test',
        onSession: (socket) async {
          if (!sessionStarted.isCompleted) {
            sessionStarted.complete();
          }
          try {
            await socket.done;
          } finally {
            if (!sessionDone.isCompleted) {
              sessionDone.complete();
            }
          }
        },
      );

      final socket = await io.WebSocket.connect(server.webSocketUri.toString());
      final socketClosed = Completer<void>();
      final subscription = socket.listen(
        (_) {},
        onDone: () {
          if (!socketClosed.isCompleted) {
            socketClosed.complete();
          }
        },
      );
      addTearDown(subscription.cancel);
      await sessionStarted.future.timeout(const Duration(seconds: 5));
      await server.close(force: true);
      await sessionDone.future.timeout(const Duration(seconds: 5));
      await socketClosed.future.timeout(const Duration(seconds: 5));
    });

    test('close(force: true) waits for websocket session cleanup', () async {
      final sessionStarted = Completer<void>();
      final cleanupStarted = Completer<void>();
      final allowCleanup = Completer<void>();
      final cleanupFinished = Completer<void>();
      final server = await BrowserTerminalHostServer.bind(
        port: 0,
        title: 'Force Close Wait Test',
        onSession: (socket) async {
          if (!sessionStarted.isCompleted) {
            sessionStarted.complete();
          }
          await socket.done;
          if (!cleanupStarted.isCompleted) {
            cleanupStarted.complete();
          }
          await allowCleanup.future;
          if (!cleanupFinished.isCompleted) {
            cleanupFinished.complete();
          }
        },
      );

      final socket = await io.WebSocket.connect(server.webSocketUri.toString());
      addTearDown(socket.close);

      await sessionStarted.future.timeout(const Duration(seconds: 5));
      var closeCompleted = false;
      final closeFuture = server.close(force: true).then((_) {
        closeCompleted = true;
      });

      await cleanupStarted.future.timeout(const Duration(seconds: 5));
      await Future<void>.delayed(Duration.zero);
      expect(closeCompleted, isFalse);

      allowCleanup.complete();
      await closeFuture.timeout(const Duration(seconds: 5));
      await cleanupFinished.future.timeout(const Duration(seconds: 5));
    });

    test('close is idempotent after serving requests', () async {
      final server = await BrowserTerminalHostServer.bind(
        port: 0,
        title: 'Idempotent Close Test',
        onSession: (_) async {},
      );

      final client = io.HttpClient();
      addTearDown(() => client.close(force: true));
      final request = await client.getUrl(server.pageUri);
      final response = await request.close();
      await response.drain<void>();

      await server.close();
      await server.close(force: true);
    });

    test('synchronous session handler errors still clean up websockets', () async {
      var accepted = 0;
      final server = await BrowserTerminalHostServer.bind(
        port: 0,
        title: 'Sync Error Test',
        onSession: (socket) {
          accepted++;
          throw StateError('boom');
        },
      );
      addTearDown(() => server.close(force: true));

      Future<void> expectDisconnect() async {
        final socket = await io.WebSocket.connect(server.webSocketUri.toString());
        final closed = Completer<void>();
        final subscription = socket.listen(
          (_) {},
          onDone: () {
            if (!closed.isCompleted) {
              closed.complete();
            }
          },
        );
        addTearDown(subscription.cancel);
        addTearDown(socket.close);
        await closed.future.timeout(const Duration(seconds: 5));
      }

      await expectDisconnect();
      await expectDisconnect();
      expect(accepted, 2);
    });
  });
}

class _BrowserHostModel implements Model {
  const _BrowserHostModel();

  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) {
    return switch (msg) {
      KeyMsg(key: Key(type: KeyType.runes, runes: [0x71])) => (this, Cmd.quit()),
      _ => (this, null),
    };
  }

  @override
  String view() => '''
Browser Host Test Model
=======================

Press q to close.
''';
}

class _BrowserDisconnectAwareModel implements Model {
  const _BrowserDisconnectAwareModel(this.interrupted);

  final Completer<void> interrupted;

  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) {
    return switch (msg) {
      InterruptMsg() => (
        this,
        Cmd(() async {
          if (!interrupted.isCompleted) {
            interrupted.complete();
          }
          return QuitMsg();
        }),
      ),
      _ => (this, null),
    };
  }

  @override
  String view() => 'Browser Disconnect Model';
}
