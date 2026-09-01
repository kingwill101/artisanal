// @TestOn('vm')

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:artisanal/artisanal.dart' as hosts;
import 'package:artisanal/terminal.dart' show Ansi;
import 'package:artisanal/tui.dart' as runtime;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:image/image.dart' as img;
import 'package:test/test.dart';

Uint8List _encodeTestImage() {
  final image = img.Image(width: 4, height: 4);
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      image.setPixelRgba(x, y, x * 50, y * 50, 180, 255);
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}

Future<String> _readSocketUntil(
  Socket socket,
  bool Function(String output) predicate, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final buffer = StringBuffer();
  final completer = Completer<String>();
  late final StreamSubscription<List<int>> subscription;
  Timer? timer;

  void finish([Object? error]) {
    timer?.cancel();
    subscription.cancel();
    if (error != null) {
      if (!completer.isCompleted) {
        completer.completeError(error);
      }
      return;
    }
    if (!completer.isCompleted) {
      completer.complete(buffer.toString());
    }
  }

  timer = Timer(timeout, () {
    finish(TimeoutException('Timed out waiting for socket output', timeout));
  });

  subscription = socket.listen(
    (chunk) {
      buffer.write(utf8.decode(chunk, allowMalformed: true));
      if (predicate(buffer.toString())) {
        finish();
      }
    },
    onError: finish,
    onDone: () => finish(),
    cancelOnError: true,
  );

  return completer.future;
}

Future<String> _readWebSocketOutputUntil(
  WebSocket socket,
  bool Function(String output) predicate, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final buffer = StringBuffer();
  final completer = Completer<String>();
  late final StreamSubscription<dynamic> subscription;
  Timer? timer;

  void finish([Object? error]) {
    timer?.cancel();
    subscription.cancel();
    if (error != null) {
      if (!completer.isCompleted) {
        completer.completeError(error);
      }
      return;
    }
    if (!completer.isCompleted) {
      completer.complete(buffer.toString());
    }
  }

  timer = Timer(timeout, () {
    finish(TimeoutException('Timed out waiting for websocket output', timeout));
  });

  subscription = socket.listen(
    (event) {
      final message = hosts.TerminalBridgeMessage.decodeJson(event as String);
      if (message.type != hosts.TerminalBridgeMessageType.output) {
        return;
      }
      buffer.write(message.data);
      if (predicate(buffer.toString())) {
        finish();
      }
    },
    onError: finish,
    onDone: () => finish(),
    cancelOnError: true,
  );

  return completer.future;
}

String _terminalOperationsText(runtime.StringTerminal terminal) =>
    terminal.operations.join('\n');

void main() {
  group('runWidgetApp', () {
    test('uses widget-friendly defaults', () async {
      final terminal = runtime.StringTerminal();

      await w.runWidgetApp(
        w.WidgetApp(_QuitOnInitWidget()),
        host: runtime.ProgramHost.terminal(terminal),
      );

      expect(terminal.operations, contains('enterAltScreen'));
      expect(terminal.operations, contains('enableMouseAllMotion'));
    });

    test('default widget program options disable startup probes', () {
      expect(w.defaultWidgetProgramOptions.startupProbes, isFalse);
    });

    test('explicit options can disable the widget defaults', () async {
      final terminal = runtime.StringTerminal();

      await w.runWidgetApp(
        w.WidgetApp(_QuitOnInitWidget()),
        host: runtime.ProgramHost.terminal(terminal),
        options: const runtime.ProgramOptions(
          altScreen: false,
          mouseMode: runtime.MouseMode.none,
          signalHandlers: false,
          frameTick: false,
        ),
      );

      expect(terminal.operations, isNot(contains('enterAltScreen')));
      expect(terminal.operations, isNot(contains('enableMouse')));
      expect(terminal.operations, isNot(contains('enableMouseCellMotion')));
      expect(terminal.operations, isNot(contains('enableMouseAllMotion')));
    });

    test('can override imageAutoMode for local runs', () async {
      final terminal = runtime.StringTerminal();
      final app = w.WidgetApp(_QuitOnInitWidget());

      await w.runWidgetApp(
        app,
        host: runtime.ProgramHost.terminal(terminal),
        imageAutoMode: w.ImageAutoMode.portableFallback,
      );

      expect(app.imageAutoMode, w.ImageAutoMode.portableFallback);
    });
  });

  group('runWidgetApp (ArtisanalApp)', () {
    test('propagates the app title to startup output by default', () async {
      final terminal = runtime.StringTerminal();

      await w.runWidgetApp(
        w.ArtisanalApp(title: 'Run App Test', home: _QuitOnInitWidget()),
        host: runtime.ProgramHost.terminal(terminal),
      );

      expect(
        _terminalOperationsText(terminal),
        contains('write: \x1B]0;Run App Test\x07'),
      );
    });

    test('captures print output into the debug console when enabled', () async {
      final terminal = runtime.StringTerminal();
      final controller = w.DebugConsoleController(initiallyVisible: true);

      await w.runWidgetApp(
        w.ArtisanalApp(
          title: 'Captured Logs',
          debugConsoleController: controller,
          debugConsoleCapturePrint: true,
          home: _PrintAndQuitWidget(),
        ),
        host: runtime.ProgramHost.terminal(terminal),
      );

      final messages =
          controller.entries.map((entry) => entry.message).join('\n');
      expect(messages, contains('captured print'));
    });

    test('can override imageAutoMode for local app-shell runs', () async {
      final terminal = runtime.StringTerminal();
      final app = w.ArtisanalApp(
        title: 'Image Mode',
        home: _QuitOnInitWidget(),
      );

      await w.runWidgetApp(
        app,
        host: runtime.ProgramHost.terminal(terminal),
        imageAutoMode: w.ImageAutoMode.portableFallback,
      );

      expect(app.imageAutoMode, w.ImageAutoMode.portableFallback);
    });
  });

  group('reloadable runners', () {
    test(
      'runWidgetApp + ArtisanalApp(child: ReloadHost) keeps the app shell title',
      () async {
        final terminal = runtime.StringTerminal();
        final controller = w.ReloadController();

        addTearDown(controller.dispose);

        await w.runWidgetApp(
          w.ArtisanalApp(
            title: 'Reloadable App',
            child: w.ReloadHost(
              controller: controller,
              builder: (context, revision) => _QuitOnInitWidget(),
            ),
          ),
          host: runtime.ProgramHost.terminal(terminal),
        );

        expect(
          _terminalOperationsText(terminal),
          contains('write: \x1B]0;Reloadable App\x07'),
        );
      },
    );
  });

  group('watched runners', () {
    test(
      'runWidgetApp + external watcher wires a file watcher around the reload host',
      () async {
        final terminal = runtime.StringTerminal();
        final tempDir = await Directory.systemTemp.createTemp(
          'run-watched-widget-',
        );

        addTearDown(() async {
          await tempDir.delete(recursive: true);
        });

        final controller = w.ReloadController();
        addTearDown(controller.dispose);
        final watcher = await w.ReloadFileWatcher.watch(
          controller: controller,
          roots: [tempDir.path],
        );
        addTearDown(watcher.dispose);

        await w.runWidgetApp(
          w.WidgetApp(
            w.ReloadHost(
              controller: controller,
              builder: (context, revision) => _QuitOnInitWidget(),
            ),
          ),
          host: runtime.ProgramHost.terminal(terminal),
        );

        expect(terminal.operations, contains('enterAltScreen'));
        expect(terminal.operations, contains('enableMouseAllMotion'));
      },
    );

    test(
      'runWidgetApp + ArtisanalApp + external watcher applies the app shell title',
      () async {
        final terminal = runtime.StringTerminal();
        final tempDir = await Directory.systemTemp.createTemp(
          'run-watched-artisanal-',
        );

        addTearDown(() async {
          await tempDir.delete(recursive: true);
        });

        final controller = w.ReloadController();
        addTearDown(controller.dispose);
        final watcher = await w.ReloadFileWatcher.watch(
          controller: controller,
          roots: [tempDir.path],
        );
        addTearDown(watcher.dispose);

        await w.runWidgetApp(
          w.ArtisanalApp(
            title: 'Watched App',
            child: w.ReloadHost(
              controller: controller,
              builder: (context, revision) => _QuitOnInitWidget(),
            ),
          ),
          host: runtime.ProgramHost.terminal(terminal),
        );

        expect(
          _terminalOperationsText(terminal),
          contains('write: \x1B]0;Watched App\x07'),
        );
      },
    );
  });

  group('hosted runners', () {
    test(
      'serveWidgetApp + browser transport exposes the browser page',
      () async {
        final server = await w.serveWidgetApp(
          transport: w.Transport.browser,
          port: 0,
          browserTitle: 'Widget Browser Test',
          appBuilder: () => w.WidgetApp(_QuitOnInitWidget()),
        ) as hosts.BrowserTerminalHostServer;

        addTearDown(server.close);

        final client = HttpClient();
        addTearDown(client.close);

        final request = await client.getUrl(server.pageUri);
        final response = await request.close();
        final body = await response.transform(utf8.decoder).join();

        expect(response.statusCode, HttpStatus.ok);
        expect(body, contains('Widget Browser Test'));
      },
    );

    test(
      'serveWidgetApp + browser transport uses session capability image mode by default',
      () async {
        late w.ArtisanalApp app;
        final server = await w.serveWidgetApp(
          transport: w.Transport.browser,
          port: 0,
          options: const runtime.ProgramOptions(
            altScreen: false,
            mouseMode: runtime.MouseMode.none,
            signalHandlers: false,
            frameTick: false,
          ),
          appBuilder: () => app = w.ArtisanalApp(
            home: w.Image(
              image: w.MemoryImage(_encodeTestImage()),
              width: 2,
              height: 1,
              renderMode: w.ImageRenderMode.auto,
            ),
          ),
        ) as hosts.BrowserTerminalHostServer;

        addTearDown(server.close);

        final socket = await WebSocket.connect(server.webSocketUri.toString());
        addTearDown(socket.close);

        await socket.first.timeout(const Duration(seconds: 5));

        expect(app.imageAutoMode, w.ImageAutoMode.sessionCapabilities);
      },
    );

    test(
      'serveWidgetApp + browser transport requests image capability reports by default',
      () async {
        final server = await w.serveWidgetApp(
          transport: w.Transport.browser,
          port: 0,
          options: const runtime.ProgramOptions(
            altScreen: false,
            mouseMode: runtime.MouseMode.none,
            signalHandlers: false,
            frameTick: false,
          ),
          appBuilder: () => w.ArtisanalApp(
            home: w.Image(
              image: w.MemoryImage(_encodeTestImage()),
              width: 2,
              height: 1,
              renderMode: w.ImageRenderMode.auto,
            ),
          ),
        ) as hosts.BrowserTerminalHostServer;

        addTearDown(server.close);

        final socket = await WebSocket.connect(server.webSocketUri.toString());
        addTearDown(socket.close);

        final output = await _readWebSocketOutputUntil(
          socket,
          (output) =>
              output.contains(Ansi.requestPrimaryDeviceAttributes) &&
              output.contains(Ansi.requestTerminalVersion),
        );

        expect(output, contains(Ansi.requestPrimaryDeviceAttributes));
        expect(output, contains(Ansi.requestTerminalVersion));
      },
    );

    test(
      'serveWidgetApp + browser transport + external watcher watches files',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'watched-browser-app-',
        );
        final controller = w.ReloadController();
        addTearDown(controller.dispose);
        final watcher = await w.ReloadFileWatcher.watch(
          controller: controller,
          roots: [tempDir.path],
        );
        addTearDown(watcher.dispose);

        final host = await w.serveWidgetApp(
          transport: w.Transport.browser,
          port: 0,
          browserTitle: 'Watched Browser Test',
          appBuilder: () => w.WidgetApp(
            w.ReloadHost(
              controller: controller,
              builder: (context, revision) => _QuitOnInitWidget(),
            ),
          ),
        ) as hosts.BrowserTerminalHostServer;

        addTearDown(() => host.close());

        final client = HttpClient();
        addTearDown(client.close);

        final request = await client.getUrl(host.pageUri);
        final response = await request.close();
        final body = await response.transform(utf8.decoder).join();

        expect(response.statusCode, HttpStatus.ok);
        expect(body, contains('Watched Browser Test'));

        final signalFuture = controller.stream.first;
        await File(
          '${tempDir.path}/main.dart',
        ).writeAsString('void main() {}\n');
        final signal = await signalFuture.timeout(const Duration(seconds: 5));
        expect(signal.mode, w.ReloadMode.reload);
      },
    );

    test(
      'serveWidgetApp + socket transport exposes app output over tcp',
      () async {
        final server = await w.serveWidgetApp(
          transport: w.Transport.socket,
          port: 0,
          options: const runtime.ProgramOptions(
            altScreen: false,
            mouseMode: runtime.MouseMode.none,
            signalHandlers: false,
            frameTick: false,
          ),
          appBuilder: () =>
              w.ArtisanalApp(title: 'Socket App', home: _ReadyWidget()),
        ) as hosts.SocketTerminalHostServer;

        addTearDown(server.close);

        final socket = await Socket.connect(
          server.server.address.address,
          server.server.port,
        );
        addTearDown(socket.close);

        final output = await _readSocketUntil(
          socket,
          (output) => output.contains('ready'),
        );

        expect(output, contains('ready'));
      },
    );

    test(
      'serveWidgetApp + socket transport uses session capability image mode by default',
      () async {
        late w.WidgetApp app;
        final server = await w.serveWidgetApp(
          transport: w.Transport.socket,
          port: 0,
          options: const runtime.ProgramOptions(
            altScreen: false,
            mouseMode: runtime.MouseMode.none,
            signalHandlers: false,
            frameTick: false,
          ),
          appBuilder: () => app = w.WidgetApp(
            w.Image(
              image: w.MemoryImage(_encodeTestImage()),
              width: 2,
              height: 1,
              renderMode: w.ImageRenderMode.auto,
            ),
          ),
        ) as hosts.SocketTerminalHostServer;

        addTearDown(server.close);

        final socket = await Socket.connect(
          server.server.address.address,
          server.server.port,
        );
        addTearDown(socket.close);

        final output = await _readSocketUntil(
          socket,
          (output) => output.contains('▀'),
        );

        expect(app.imageAutoMode, w.ImageAutoMode.sessionCapabilities);
        expect(output, contains('▀'));
        expect(output, isNot(contains('\x1b_G')));
        expect(output, isNot(contains('\x1b]1337;File=')));
        expect(output, isNot(contains('\x1bPq')));
      },
    );

    test(
      'serveWidgetApp + socket transport portable image mode skips session capability probes',
      () async {
        final server = await w.serveWidgetApp(
          transport: w.Transport.socket,
          port: 0,
          imageAutoMode: w.ImageAutoMode.portableFallback,
          options: const runtime.ProgramOptions(
            altScreen: false,
            mouseMode: runtime.MouseMode.none,
            signalHandlers: false,
            frameTick: false,
          ),
          appBuilder: () => w.WidgetApp(
            w.Image(
              image: w.MemoryImage(_encodeTestImage()),
              width: 2,
              height: 1,
              renderMode: w.ImageRenderMode.auto,
            ),
          ),
        ) as hosts.SocketTerminalHostServer;

        addTearDown(server.close);

        final socket = await Socket.connect(
          server.server.address.address,
          server.server.port,
        );
        addTearDown(socket.close);

        final output = await _readSocketUntil(
          socket,
          (output) => output.contains('▀'),
        );

        expect(output, contains('▀'));
        expect(output, isNot(contains(Ansi.requestPrimaryDeviceAttributes)));
        expect(output, isNot(contains(Ansi.requestTerminalVersion)));
      },
    );

    test(
      'serveWidgetApp + socket transport suppresses startup probes for non-ANSI clients',
      () async {
        final server = await w.serveWidgetApp(
          transport: w.Transport.socket,
          port: 0,
          supportsAnsi: false,
          options: const runtime.ProgramOptions(
            altScreen: false,
            mouseMode: runtime.MouseMode.none,
            signalHandlers: false,
            frameTick: false,
          ),
          appBuilder: () => w.ArtisanalApp(home: w.Text('plain socket client')),
        ) as hosts.SocketTerminalHostServer;

        addTearDown(server.close);

        final socket = await Socket.connect(
          server.server.address.address,
          server.server.port,
        );
        addTearDown(socket.close);

        final output = await _readSocketUntil(
          socket,
          (output) => output.contains('plain socket client'),
        );

        expect(output, contains('plain socket client'));
        expect(output, isNot(contains('\x1b]11;?\x07')));
        expect(output, isNot(contains('\x1b[?996n')));
        expect(output, isNot(contains('\x1b[?c')));
        expect(output, isNot(contains('\x1b[>0q')));
      },
    );

    test(
      'serveWidgetApp + socket transport + external watcher watches files',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'watched-socket-app-',
        );
        final controller = w.ReloadController();
        addTearDown(controller.dispose);
        final watcher = await w.ReloadFileWatcher.watch(
          controller: controller,
          roots: [tempDir.path],
        );
        addTearDown(watcher.dispose);

        final server = await w.serveWidgetApp(
          transport: w.Transport.socket,
          port: 0,
          options: const runtime.ProgramOptions(
            altScreen: false,
            mouseMode: runtime.MouseMode.none,
            signalHandlers: false,
            frameTick: false,
          ),
          appBuilder: () => w.WidgetApp(
            w.ReloadHost(
              controller: controller,
              builder: (context, revision) => _ReadyWidget(),
            ),
          ),
        ) as hosts.SocketTerminalHostServer;

        addTearDown(() => server.close());

        final socket = await Socket.connect(
          server.server.address.address,
          server.server.port,
        );
        addTearDown(socket.close);

        final output = await _readSocketUntil(
          socket,
          (output) => output.contains('ready'),
        );
        expect(output, contains('ready'));

        final signalFuture = controller.stream.first;
        await File(
          '${tempDir.path}/main.dart',
        ).writeAsString('void main() {}\n');
        final signal = await signalFuture.timeout(const Duration(seconds: 5));
        expect(signal.mode, w.ReloadMode.reload);
      },
    );

    test(
      'serveWidgetApp + socket transport + watcher close(force: true) tears down clients',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'watched-socket-force-close-',
        );
        final controller = w.ReloadController();
        addTearDown(controller.dispose);
        final watcher = await w.ReloadFileWatcher.watch(
          controller: controller,
          roots: [tempDir.path],
        );
        addTearDown(watcher.dispose);

        final host = await w.serveWidgetApp(
          transport: w.Transport.socket,
          port: 0,
          options: const runtime.ProgramOptions(
            altScreen: false,
            mouseMode: runtime.MouseMode.none,
            signalHandlers: false,
            frameTick: false,
          ),
          appBuilder: () => w.WidgetApp(
            w.ReloadHost(
              controller: controller,
              builder: (context, revision) => _IdleWidget(),
            ),
          ),
        ) as hosts.SocketTerminalHostServer;

        addTearDown(() async {
          await host.close(force: true);
          await tempDir.delete(recursive: true);
        });

        final socket = await Socket.connect(
          host.server.address.address,
          host.server.port,
        );

        final firstOutput = Completer<void>();
        final closed = Completer<void>();
        late final StreamSubscription<List<int>> subscription;
        subscription = socket.listen(
          (_) {
            if (!firstOutput.isCompleted) {
              firstOutput.complete();
            }
          },
          onDone: () {
            if (!closed.isCompleted) {
              closed.complete();
            }
          },
        );
        addTearDown(() async {
          await subscription.cancel();
          await socket.close();
        });

        await firstOutput.future.timeout(const Duration(seconds: 5));
        await host.close(force: true);
        await closed.future.timeout(const Duration(seconds: 5));
      },
    );

    test(
      'serveWidgetApp + browser transport + watcher close(force: true) tears down clients',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'watched-browser-force-close-',
        );
        final controller = w.ReloadController();
        addTearDown(controller.dispose);
        final watcher = await w.ReloadFileWatcher.watch(
          controller: controller,
          roots: [tempDir.path],
        );
        addTearDown(watcher.dispose);

        final host = await w.serveWidgetApp(
          transport: w.Transport.browser,
          port: 0,
          options: const runtime.ProgramOptions(
            altScreen: false,
            mouseMode: runtime.MouseMode.none,
            signalHandlers: false,
            frameTick: false,
          ),
          appBuilder: () => w.WidgetApp(
            w.ReloadHost(
              controller: controller,
              builder: (context, revision) => _IdleWidget(),
            ),
          ),
        ) as hosts.BrowserTerminalHostServer;

        addTearDown(() async {
          await host.close(force: true);
          await tempDir.delete(recursive: true);
        });

        final socket = await WebSocket.connect(host.webSocketUri.toString());
        final firstOutput = Completer<void>();
        final closed = Completer<void>();
        late final StreamSubscription<dynamic> subscription;
        subscription = socket.listen(
          (_) {
            if (!firstOutput.isCompleted) {
              firstOutput.complete();
            }
          },
          onDone: () {
            if (!closed.isCompleted) {
              closed.complete();
            }
          },
        );
        addTearDown(() async {
          await subscription.cancel();
          await socket.close();
        });

        await firstOutput.future.timeout(const Duration(seconds: 5));
        await host.close(force: true);
        await closed.future.timeout(const Duration(seconds: 5));
      },
    );
  });
}

final class _QuitOnInitWidget extends w.StatefulWidget {
  @override
  w.State<_QuitOnInitWidget> createState() => _QuitOnInitWidgetState();
}

final class _QuitOnInitWidgetState extends w.State<_QuitOnInitWidget> {
  @override
  runtime.Cmd? handleInit() => runtime.Cmd.quit();

  @override
  w.Widget build(w.BuildContext context) => w.Text('ready');
}

final class _PrintAndQuitWidget extends w.StatefulWidget {
  @override
  w.State<_PrintAndQuitWidget> createState() => _PrintAndQuitWidgetState();
}

final class _PrintAndQuitWidgetState extends w.State<_PrintAndQuitWidget> {
  @override
  runtime.Cmd? handleInit() {
    print('captured print');
    return runtime.Cmd.quit();
  }

  @override
  w.Widget build(w.BuildContext context) => w.Text('printed');
}

final class _IdleWidget extends w.StatelessWidget {
  @override
  w.Widget build(w.BuildContext context) => w.Text('idle');
}

final class _ReadyWidget extends w.StatelessWidget {
  @override
  w.Widget build(w.BuildContext context) => w.Text('ready');
}
