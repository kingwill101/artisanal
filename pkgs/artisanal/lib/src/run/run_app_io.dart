import 'dart:io' as io;

import 'package:artisanal_widgets/widgets.dart'
    show ArtisanalApp, ImageAutoMode, WidgetApp;

import '../style/color.dart' show ColorProfile;
import '../terminal/browser_host.dart' show BrowserTerminalHostServer;
import '../terminal/socket_host.dart' show SocketTerminalHostServer;
import '../terminal/terminal.dart' show TerminalDimensions;
import '../tui/runtime.dart' show ProgramHost, ProgramOptions, runProgram;
import 'transport.dart'
    show Transport, WidgetAppHostServer, defaultWidgetProgramOptions;

T _configureImageAutoMode<T extends WidgetApp>(
  T app, {
  ImageAutoMode? imageAutoMode,
}) {
  if (imageAutoMode == null) return app;
  app.imageAutoMode = imageAutoMode;
  return app;
}

Future<T> _runArtisanalAppWithDebugCapture<T>(
  ArtisanalApp app,
  Future<T> Function() body,
) {
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
    return _runArtisanalAppWithDebugCapture(
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
/// Returns a [WidgetAppHostServer] that can be [close]d to shut down the server
/// and release resources.
Future<WidgetAppHostServer> serveWidgetApp({
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
            modelBuilder: () => _configureImageAutoMode(
              appBuilder(),
              imageAutoMode: imageAutoMode,
            ),
            options: resolvedOptions,
          )
          as WidgetAppHostServer;
    case Transport.socket:
      return await SocketTerminalHostServer.serveProgram<WidgetApp>(
            address: address,
            port: port,
            v6Only: v6Only,
            shared: shared,
            initialSize: initialSize,
            supportsAnsi: supportsAnsi,
            colorProfile: colorProfile,
            modelBuilder: () => _configureImageAutoMode(
              appBuilder(),
              imageAutoMode: imageAutoMode,
            ),
            options: resolvedOptions,
          )
          as WidgetAppHostServer;
  }
}
