import 'dart:io' as io;

import 'package:artisanal/style.dart' show ColorProfile;
import 'package:artisanal/terminal.dart'
    show
        BrowserTerminalHostServer,
        SocketTerminalHostServer,
        TerminalDimensions,
        TerminalHostServer;
import 'package:artisanal/tui.dart'
    show ProgramHost, ProgramOptions, runProgram;

import 'artisanal_app.dart' show ArtisanalApp;
import 'transport.dart' show Transport, defaultWidgetProgramOptions;
import 'widget_app.dart' show WidgetApp;
import '../layout/image.dart' show ImageAutoMode;

T _configureImageAutoMode<T extends WidgetApp>(
  T app, {
  ImageAutoMode? imageAutoMode,
}) {
  if (imageAutoMode == null) return app;
  app.imageAutoMode = imageAutoMode;
  return app;
}

Future<T> _runWithDebugCapture<T>(ArtisanalApp app, Future<T> Function() body) {
  final controller = app.debugConsoleController;
  if (controller == null) return body();
  if (!app.debugConsoleCapturePrint && !app.debugConsoleCaptureErrors) {
    return body();
  }
  return controller.runZoned(
    body,
    capturePrint: app.debugConsoleCapturePrint,
    captureErrors: app.debugConsoleCaptureErrors,
  );
}

/// Runs a [WidgetApp] in the local terminal.
///
/// Pass [options] to override widget-oriented defaults, or [host] to target
/// a custom terminal/backend such as a bridge, websocket, or embedded terminal.
///
/// If [app] is an [ArtisanalApp], its debug console capture and startup title
/// are applied automatically.
Future<void> runWidgetApp(
  WidgetApp app, {
  ProgramOptions? options,
  ProgramHost? host,
  ImageAutoMode? imageAutoMode,
}) {
  if (app is ArtisanalApp) {
    final resolvedOptions = (options ?? defaultWidgetProgramOptions).copyWith(
      startupTitle: options?.startupTitle ?? app.title,
    );
    return _runWithDebugCapture(
      app,
      () => runProgram(
        _configureImageAutoMode(app, imageAutoMode: imageAutoMode),
        options: resolvedOptions,
        host: host,
      ),
    );
  }
  return runProgram(
    _configureImageAutoMode(app, imageAutoMode: imageAutoMode),
    options: options ?? defaultWidgetProgramOptions,
    host: host,
  );
}

/// Serves a [WidgetApp] over the network using the given [transport].
///
/// [appBuilder] is called per connection to create a fresh app instance.
///
/// On [Transport.browser] a [BrowserTerminalHostServer] is started on [port]
/// serving an xterm.js-compatible client page over HTTP with WebSocket upgrades.
///
/// On [Transport.socket] a [SocketTerminalHostServer] is started on [port]
/// accepting raw TCP connections with terminal-resize control sequences.
///
/// Returns a [TerminalHostServer] that can be [close]d to shut down the server
/// and release resources.
Future<TerminalHostServer> serveWidgetApp({
  required WidgetApp Function() appBuilder,
  Transport transport = Transport.browser,
  int port = 2323,
  ImageAutoMode imageAutoMode = ImageAutoMode.sessionCapabilities,
  ProgramOptions? options,
  // Browser-specific
  io.InternetAddress? address,
  String pagePath = '/',
  String webSocketPath = '/ws',
  String browserTitle = 'Artisanal Widget Host',
  String? pageHtml,
  // Socket-specific
  bool v6Only = false,
  bool shared = false,
  TerminalDimensions initialSize = const (width: 80, height: 24),
  bool supportsAnsi = true,
  ColorProfile colorProfile = ColorProfile.trueColor,
}) async {
  final resolvedOptions = options ?? defaultWidgetProgramOptions;
  switch (transport) {
    case Transport.browser:
      return await BrowserTerminalHostServer.serveProgram<WidgetApp>(
        address: address,
        port: port,
        pagePath: pagePath,
        webSocketPath: webSocketPath,
        title: browserTitle,
        pageHtml: pageHtml,
        modelBuilder: () =>
            _configureImageAutoMode(appBuilder(), imageAutoMode: imageAutoMode),
        options: resolvedOptions,
      );
    case Transport.socket:
      return await SocketTerminalHostServer.serveProgram<WidgetApp>(
        address: address,
        port: port,
        v6Only: v6Only,
        shared: shared,
        initialSize: initialSize,
        supportsAnsi: supportsAnsi,
        colorProfile: colorProfile,
        modelBuilder: () =>
            _configureImageAutoMode(appBuilder(), imageAutoMode: imageAutoMode),
        options: resolvedOptions,
      );
  }
}
