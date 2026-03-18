import 'dart:convert';
import 'dart:io';

import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:test/test.dart';

void main() {
  group('runWidgetApp', () {
    test('uses widget-friendly defaults', () async {
      final terminal = tui.StringTerminal();

      await w.runWidgetApp(
        tui.WidgetApp(_QuitOnInitWidget()),
        host: tui.ProgramHost.terminal(terminal),
      );

      expect(terminal.operations, contains('enterAltScreen'));
      expect(terminal.operations, contains('enableMouseAllMotion'));
    });

    test('explicit options can disable the widget defaults', () async {
      final terminal = tui.StringTerminal();

      await w.runWidgetApp(
        tui.WidgetApp(_QuitOnInitWidget()),
        host: tui.ProgramHost.terminal(terminal),
        options: const tui.ProgramOptions(
          altScreen: false,
          mouseMode: tui.MouseMode.none,
          signalHandlers: false,
          frameTick: false,
        ),
      );

      expect(terminal.operations, isNot(contains('enterAltScreen')));
      expect(terminal.operations, isNot(contains('enableMouse')));
      expect(terminal.operations, isNot(contains('enableMouseCellMotion')));
      expect(terminal.operations, isNot(contains('enableMouseAllMotion')));
    });
  });

  group('runArtisanalApp', () {
    test('propagates the app title to startup output by default', () async {
      final terminal = tui.StringTerminal();

      await w.runArtisanalApp(
        w.ArtisanalApp(title: 'Run App Test', home: _QuitOnInitWidget()),
        host: tui.ProgramHost.terminal(terminal),
      );

      expect(terminal.operations, contains('setTitle(Run App Test)'));
    });

    test('captures print output into the debug console when enabled', () async {
      final terminal = tui.StringTerminal();
      final controller = w.DebugConsoleController(initiallyVisible: true);

      await w.runArtisanalApp(
        w.ArtisanalApp(
          title: 'Captured Logs',
          debugConsoleController: controller,
          debugConsoleCapturePrint: true,
          home: _PrintAndQuitWidget(),
        ),
        host: tui.ProgramHost.terminal(terminal),
      );

      final messages = controller.entries.map((entry) => entry.message).join('\n');
      expect(messages, contains('captured print'));
    });
  });

  group('reloadable runners', () {
    test('runReloadableArtisanalApp keeps the app shell title', () async {
      final terminal = tui.StringTerminal();
      final controller = w.ReloadController();

      addTearDown(controller.dispose);

      await w.runReloadableArtisanalApp(
        title: 'Reloadable App',
        controller: controller,
        host: tui.ProgramHost.terminal(terminal),
        homeBuilder: (context, revision) => _QuitOnInitWidget(),
      );

      expect(terminal.operations, contains('setTitle(Reloadable App)'));
    });
  });

  group('watched runners', () {
    test('runWatchedWidgetApp wires a file watcher around the reload host', () async {
      final terminal = tui.StringTerminal();
      final tempDir = await Directory.systemTemp.createTemp('run-watched-widget-');

      addTearDown(() async {
        await tempDir.delete(recursive: true);
      });

      await w.runWatchedWidgetApp(
        (context, revision) => _QuitOnInitWidget(),
        watchRoots: [tempDir.path],
        host: tui.ProgramHost.terminal(terminal),
      );

      expect(terminal.operations, contains('enterAltScreen'));
      expect(terminal.operations, contains('enableMouseAllMotion'));
    });

    test('runWatchedArtisanalApp applies the app shell title', () async {
      final terminal = tui.StringTerminal();
      final tempDir = await Directory.systemTemp.createTemp('run-watched-artisanal-');

      addTearDown(() async {
        await tempDir.delete(recursive: true);
      });

      await w.runWatchedArtisanalApp(
        title: 'Watched App',
        watchRoots: [tempDir.path],
        host: tui.ProgramHost.terminal(terminal),
        homeBuilder: (context, revision) => _QuitOnInitWidget(),
      );

      expect(terminal.operations, contains('setTitle(Watched App)'));
    });
  });

  group('hosted runners', () {
    test('serveWidgetAppInBrowser exposes the browser page', () async {
      final server = await w.serveWidgetAppInBrowser(
        port: 0,
        browserTitle: 'Widget Browser Test',
        appBuilder: () => tui.WidgetApp(_QuitOnInitWidget()),
      );

      addTearDown(server.close);

      final client = HttpClient();
      addTearDown(client.close);

      final request = await client.getUrl(server.pageUri);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      expect(response.statusCode, HttpStatus.ok);
      expect(body, contains('Widget Browser Test'));
    });

    test('serveWatchedArtisanalAppInBrowser watches files and serves the page', () async {
      final tempDir = await Directory.systemTemp.createTemp('watched-browser-app-');
      final host = await w.serveWatchedArtisanalAppInBrowser(
        port: 0,
        browserTitle: 'Watched Browser Test',
        watchRoots: [tempDir.path],
        homeBuilder: (context, revision) => _QuitOnInitWidget(),
      );

      addTearDown(() async {
        await host.close();
        await tempDir.delete(recursive: true);
      });

      final client = HttpClient();
      addTearDown(client.close);

      final request = await client.getUrl(host.server.pageUri);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      expect(response.statusCode, HttpStatus.ok);
      expect(body, contains('Watched Browser Test'));

      final signalFuture = host.controller.stream.first;
      await File('${tempDir.path}/main.dart').writeAsString('void main() {}\n');
      final signal = await signalFuture.timeout(const Duration(seconds: 5));
      expect(signal.mode, w.ReloadMode.reload);
    });

    test('serveArtisanalAppOnSocket exposes app output over tcp', () async {
      final server = await w.serveArtisanalAppOnSocket(
        port: 0,
        options: const tui.ProgramOptions(
          altScreen: false,
          mouseMode: tui.MouseMode.none,
          signalHandlers: false,
          frameTick: false,
        ),
        appBuilder: () => w.ArtisanalApp(
          title: 'Socket App',
          home: _QuitOnInitWidget(),
        ),
      );

      addTearDown(server.close);

      final socket = await Socket.connect(
        server.server.address.address,
        server.server.port,
      );
      addTearDown(socket.close);

      final chunk = await socket.first.timeout(const Duration(seconds: 5));
      final output = utf8.decode(chunk, allowMalformed: true);

      expect(output, contains('ready'));
    });

    test('serveWatchedArtisanalAppOnSocket watches files and serves tcp output', () async {
      final tempDir = await Directory.systemTemp.createTemp('watched-socket-app-');
      final server = await w.serveWatchedArtisanalAppOnSocket(
        port: 0,
        watchRoots: [tempDir.path],
        options: const tui.ProgramOptions(
          altScreen: false,
          mouseMode: tui.MouseMode.none,
          signalHandlers: false,
          frameTick: false,
        ),
        homeBuilder: (context, revision) => _QuitOnInitWidget(),
      );

      addTearDown(() async {
        await server.close();
        await tempDir.delete(recursive: true);
      });

      final socket = await Socket.connect(
        server.server.server.address.address,
        server.server.server.port,
      );
      addTearDown(socket.close);

      final chunk = await socket.first.timeout(const Duration(seconds: 5));
      final output = utf8.decode(chunk, allowMalformed: true);
      expect(output, contains('ready'));

      final signalFuture = server.controller.stream.first;
      await File('${tempDir.path}/main.dart').writeAsString('void main() {}\n');
      final signal = await signalFuture.timeout(const Duration(seconds: 5));
      expect(signal.mode, w.ReloadMode.reload);
    });
  });
}

final class _QuitOnInitWidget extends w.StatefulWidget {
  @override
  w.State<_QuitOnInitWidget> createState() => _QuitOnInitWidgetState();
}

final class _QuitOnInitWidgetState extends w.State<_QuitOnInitWidget> {
  @override
  tui.Cmd? handleInit() => tui.Cmd.quit();

  @override
  w.Widget build(w.BuildContext context) => w.Text('ready');
}

final class _PrintAndQuitWidget extends w.StatefulWidget {
  @override
  w.State<_PrintAndQuitWidget> createState() => _PrintAndQuitWidgetState();
}

final class _PrintAndQuitWidgetState extends w.State<_PrintAndQuitWidget> {
  @override
  tui.Cmd? handleInit() {
    print('captured print');
    return tui.Cmd.quit();
  }

  @override
  w.Widget build(w.BuildContext context) => w.Text('printed');
}
