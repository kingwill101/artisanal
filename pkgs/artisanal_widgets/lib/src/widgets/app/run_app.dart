import 'dart:io' as io;

import 'package:artisanal/style.dart' show ColorProfile;
import 'package:artisanal/tui.dart' as tui;

import 'artisanal_app.dart';
import 'reload.dart';
import 'reload_watcher.dart';
import '../theme/theme.dart';
import 'widget_app.dart';

/// Widget-friendly runtime defaults for [runWidgetApp] and [runArtisanalApp].
///
/// These defaults mirror how most interactive widget examples are launched:
/// fullscreen with mouse reporting enabled.
const tui.ProgramOptions defaultWidgetProgramOptions = tui.ProgramOptions(
  altScreen: true,
  mouseMode: tui.MouseMode.allMotion,
);

/// Runs a [WidgetApp] with widget-oriented runtime defaults.
///
/// Pass [options] to override the defaults, or [host] to target a custom
/// terminal/backend such as a bridge, websocket, or embedded terminal.
Future<void> runWidgetApp(
  WidgetApp app, {
  tui.ProgramOptions? options,
  tui.ProgramHost? host,
}) {
  return tui.runProgram(
    app,
    options: options ?? defaultWidgetProgramOptions,
    host: host,
  );
}

/// Runs an [ArtisanalApp] with widget-oriented runtime defaults.
///
/// When `ProgramOptions.startupTitle` is not provided, the app shell [ArtisanalApp.title]
/// is also published as the startup title so hosts that react before the first
/// render still get a sensible window label.
Future<void> runArtisanalApp(
  ArtisanalApp app, {
  tui.ProgramOptions? options,
  tui.ProgramHost? host,
}) {
  final resolvedOptions = (options ?? defaultWidgetProgramOptions).copyWith(
    startupTitle: options?.startupTitle ?? app.title,
  );
  return _runArtisanalAppWithDebugCapture(
    app,
    () => tui.runProgram(app, options: resolvedOptions, host: host),
  );
}

/// Runs a reloadable [WidgetApp] backed by [ReloadHost].
///
/// Pair the returned UI with a [ReloadController] and call `reload()` or
/// `restart()` from a file watcher, a signal handler, or an in-app shortcut.
Future<void> runReloadableWidgetApp(
  ReloadWidgetBuilder builder, {
  required ReloadController controller,
  tui.ProgramOptions? options,
  tui.ProgramHost? host,
}) {
  return runWidgetApp(
    WidgetApp(ReloadHost(controller: controller, builder: builder)),
    options: options,
    host: host,
  );
}

/// Browser host wrapper that owns the reload controller and optional watcher.
final class WatchedBrowserArtisanalAppHost {
  WatchedBrowserArtisanalAppHost._({
    required this.server,
    required this.controller,
    required this.watcher,
    required bool ownsController,
  }) : _ownsController = ownsController;

  /// Underlying browser host server.
  final tui.BrowserTerminalHostServer server;

  /// Shared reload controller used by all connected sessions.
  final ReloadController controller;

  /// Optional file watcher driving reloads.
  final ReloadFileWatcher? watcher;

  final bool _ownsController;

  /// Closes the host server and releases any owned reload resources.
  Future<void> close({bool force = false}) async {
    await server.close(force: force);
    await watcher?.dispose();
    if (_ownsController) {
      await controller.dispose();
    }
  }
}

/// Socket host wrapper that owns the reload controller and optional watcher.
final class WatchedSocketArtisanalAppHost {
  WatchedSocketArtisanalAppHost._({
    required this.server,
    required this.controller,
    required this.watcher,
    required bool ownsController,
  }) : _ownsController = ownsController;

  /// Underlying socket host server.
  final tui.SocketTerminalHostServer server;

  /// Shared reload controller used by all connected sessions.
  final ReloadController controller;

  /// Optional file watcher driving reloads.
  final ReloadFileWatcher? watcher;

  final bool _ownsController;

  /// Closes the host server and releases any owned reload resources.
  Future<void> close() async {
    await server.close();
    await watcher?.dispose();
    if (_ownsController) {
      await controller.dispose();
    }
  }
}

/// Runs an [ArtisanalApp] with a reloadable `home` widget.
///
/// This is the app-shell equivalent of [runReloadableWidgetApp]. It keeps the
/// `ArtisanalApp` conveniences such as title propagation, theming, and the
/// built-in debug console while still exposing a [ReloadHost]-managed home
/// subtree.
Future<void> runReloadableArtisanalApp({
  required ReloadWidgetBuilder homeBuilder,
  required ReloadController controller,
  String? title,
  Theme? theme,
  Theme? darkTheme,
  ThemeMode themeMode = ThemeMode.system,
  Theme Function()? themeBuilder,
  tui.ProgramOptions? options,
  tui.ProgramHost? host,
}) {
  return runArtisanalApp(
    ArtisanalApp(
      title: title,
      theme: theme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      themeBuilder: themeBuilder,
      home: ReloadHost(
        controller: controller,
        builder: homeBuilder,
      ),
    ),
    options: options,
    host: host,
  );
}

/// Runs a reloadable [WidgetApp] and watches filesystem roots for changes.
///
/// This is a convenience wrapper around [ReloadController], [ReloadHost], and
/// [ReloadFileWatcher] for local development loops.
Future<void> runWatchedWidgetApp(
  ReloadWidgetBuilder builder, {
  required Iterable<String> watchRoots,
  ReloadController? controller,
  ReloadMode watchMode = ReloadMode.reload,
  Duration watchDebounce = const Duration(milliseconds: 150),
  bool watchRecursive = true,
  bool watchIgnoreHidden = true,
  Iterable<String> watchExtensions = const <String>['.dart'],
  tui.ProgramOptions? options,
  tui.ProgramHost? host,
}) async {
  final reloadController = controller ?? ReloadController();
  final ownsController = controller == null;
  final watcher = await ReloadFileWatcher.watch(
    controller: reloadController,
    roots: watchRoots,
    mode: watchMode,
    debounce: watchDebounce,
    recursive: watchRecursive,
    ignoreHidden: watchIgnoreHidden,
    extensions: watchExtensions,
  );

  try {
    await runReloadableWidgetApp(
      builder,
      controller: reloadController,
      options: options,
      host: host,
    );
  } finally {
    await watcher.dispose();
    if (ownsController) {
      await reloadController.dispose();
    }
  }
}

/// Runs an [ArtisanalApp] with a watched, reloadable `home` widget.
///
/// This uses [ReloadHost] under the hood and automatically disposes the
/// watcher and controller when the program exits.
Future<void> runWatchedArtisanalApp({
  required ReloadWidgetBuilder homeBuilder,
  required Iterable<String> watchRoots,
  String? title,
  Theme? theme,
  Theme? darkTheme,
  ThemeMode themeMode = ThemeMode.system,
  Theme Function()? themeBuilder,
  ReloadController? controller,
  ReloadMode watchMode = ReloadMode.reload,
  Duration watchDebounce = const Duration(milliseconds: 150),
  bool watchRecursive = true,
  bool watchIgnoreHidden = true,
  Iterable<String> watchExtensions = const <String>['.dart'],
  tui.ProgramOptions? options,
  tui.ProgramHost? host,
}) async {
  final reloadController = controller ?? ReloadController();
  final ownsController = controller == null;
  final watcher = await ReloadFileWatcher.watch(
    controller: reloadController,
    roots: watchRoots,
    mode: watchMode,
    debounce: watchDebounce,
    recursive: watchRecursive,
    ignoreHidden: watchIgnoreHidden,
    extensions: watchExtensions,
  );

  try {
    await runReloadableArtisanalApp(
      title: title,
      theme: theme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      themeBuilder: themeBuilder,
      controller: reloadController,
      homeBuilder: homeBuilder,
      options: options,
      host: host,
    );
  } finally {
    await watcher.dispose();
    if (ownsController) {
      await reloadController.dispose();
    }
  }
}

/// Serves a reloadable [ArtisanalApp] in the browser.
///
/// All connected sessions share [controller], so `reload()` or `restart()`
/// broadcasts across every active browser client.
Future<tui.BrowserTerminalHostServer> serveReloadableArtisanalAppInBrowser({
  required ReloadWidgetBuilder homeBuilder,
  required ReloadController controller,
  io.InternetAddress? address,
  int port = 8080,
  String pagePath = '/',
  String webSocketPath = '/ws',
  String browserTitle = 'Artisanal Widget Host',
  String? pageHtml,
  String? title,
  Theme? theme,
  Theme? darkTheme,
  ThemeMode themeMode = ThemeMode.system,
  Theme Function()? themeBuilder,
  tui.ProgramOptions? options,
}) {
  return serveArtisanalAppInBrowser(
    address: address,
    port: port,
    pagePath: pagePath,
    webSocketPath: webSocketPath,
    browserTitle: browserTitle,
    pageHtml: pageHtml,
    options: options,
    appBuilder: () => ArtisanalApp(
      title: title,
      theme: theme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      themeBuilder: themeBuilder,
      home: ReloadHost(
        controller: controller,
        builder: homeBuilder,
      ),
    ),
  );
}

/// Serves a reloadable [ArtisanalApp] on the raw socket host.
///
/// All connected sessions share [controller], so `reload()` or `restart()`
/// broadcasts across every active socket client.
Future<tui.SocketTerminalHostServer> serveReloadableArtisanalAppOnSocket({
  required ReloadWidgetBuilder homeBuilder,
  required ReloadController controller,
  io.InternetAddress? address,
  int port = 2323,
  bool v6Only = false,
  bool shared = false,
  tui.TerminalDimensions initialSize = const (width: 80, height: 24),
  bool supportsAnsi = true,
  ColorProfile colorProfile = ColorProfile.trueColor,
  String? title,
  Theme? theme,
  Theme? darkTheme,
  ThemeMode themeMode = ThemeMode.system,
  Theme Function()? themeBuilder,
  tui.ProgramOptions? options,
}) {
  return serveArtisanalAppOnSocket(
    address: address,
    port: port,
    v6Only: v6Only,
    shared: shared,
    initialSize: initialSize,
    supportsAnsi: supportsAnsi,
    colorProfile: colorProfile,
    options: options,
    appBuilder: () => ArtisanalApp(
      title: title,
      theme: theme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      themeBuilder: themeBuilder,
      home: ReloadHost(
        controller: controller,
        builder: homeBuilder,
      ),
    ),
  );
}

/// Serves a watched, reloadable [ArtisanalApp] in the browser.
///
/// The returned host owns the browser server plus the optional file watcher
/// and controller lifecycle.
Future<WatchedBrowserArtisanalAppHost> serveWatchedArtisanalAppInBrowser({
  required ReloadWidgetBuilder homeBuilder,
  required Iterable<String> watchRoots,
  ReloadController? controller,
  ReloadMode watchMode = ReloadMode.reload,
  Duration watchDebounce = const Duration(milliseconds: 150),
  bool watchRecursive = true,
  bool watchIgnoreHidden = true,
  Iterable<String> watchExtensions = const <String>['.dart'],
  io.InternetAddress? address,
  int port = 8080,
  String pagePath = '/',
  String webSocketPath = '/ws',
  String browserTitle = 'Artisanal Widget Host',
  String? pageHtml,
  String? title,
  Theme? theme,
  Theme? darkTheme,
  ThemeMode themeMode = ThemeMode.system,
  Theme Function()? themeBuilder,
  tui.ProgramOptions? options,
}) async {
  final reloadController = controller ?? ReloadController();
  final ownsController = controller == null;
  final watcher = await ReloadFileWatcher.watch(
    controller: reloadController,
    roots: watchRoots,
    mode: watchMode,
    debounce: watchDebounce,
    recursive: watchRecursive,
    ignoreHidden: watchIgnoreHidden,
    extensions: watchExtensions,
  );

  try {
    final server = await serveReloadableArtisanalAppInBrowser(
      controller: reloadController,
      homeBuilder: homeBuilder,
      address: address,
      port: port,
      pagePath: pagePath,
      webSocketPath: webSocketPath,
      browserTitle: browserTitle,
      pageHtml: pageHtml,
      title: title,
      theme: theme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      themeBuilder: themeBuilder,
      options: options,
    );

    return WatchedBrowserArtisanalAppHost._(
      server: server,
      controller: reloadController,
      watcher: watcher,
      ownsController: ownsController,
    );
  } catch (_) {
    await watcher.dispose();
    if (ownsController) {
      await reloadController.dispose();
    }
    rethrow;
  }
}

/// Serves a watched, reloadable [ArtisanalApp] on the raw socket host.
Future<WatchedSocketArtisanalAppHost> serveWatchedArtisanalAppOnSocket({
  required ReloadWidgetBuilder homeBuilder,
  required Iterable<String> watchRoots,
  ReloadController? controller,
  ReloadMode watchMode = ReloadMode.reload,
  Duration watchDebounce = const Duration(milliseconds: 150),
  bool watchRecursive = true,
  bool watchIgnoreHidden = true,
  Iterable<String> watchExtensions = const <String>['.dart'],
  io.InternetAddress? address,
  int port = 2323,
  bool v6Only = false,
  bool shared = false,
  tui.TerminalDimensions initialSize = const (width: 80, height: 24),
  bool supportsAnsi = true,
  ColorProfile colorProfile = ColorProfile.trueColor,
  String? title,
  Theme? theme,
  Theme? darkTheme,
  ThemeMode themeMode = ThemeMode.system,
  Theme Function()? themeBuilder,
  tui.ProgramOptions? options,
}) async {
  final reloadController = controller ?? ReloadController();
  final ownsController = controller == null;
  final watcher = await ReloadFileWatcher.watch(
    controller: reloadController,
    roots: watchRoots,
    mode: watchMode,
    debounce: watchDebounce,
    recursive: watchRecursive,
    ignoreHidden: watchIgnoreHidden,
    extensions: watchExtensions,
  );

  try {
    final server = await serveReloadableArtisanalAppOnSocket(
      controller: reloadController,
      homeBuilder: homeBuilder,
      address: address,
      port: port,
      v6Only: v6Only,
      shared: shared,
      initialSize: initialSize,
      supportsAnsi: supportsAnsi,
      colorProfile: colorProfile,
      title: title,
      theme: theme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      themeBuilder: themeBuilder,
      options: options,
    );

    return WatchedSocketArtisanalAppHost._(
      server: server,
      controller: reloadController,
      watcher: watcher,
      ownsController: ownsController,
    );
  } catch (_) {
    await watcher.dispose();
    if (ownsController) {
      await reloadController.dispose();
    }
    rethrow;
  }
}

/// Serves a [WidgetApp] in the browser through the shared websocket host.
Future<tui.BrowserTerminalHostServer> serveWidgetAppInBrowser({
  required WidgetApp Function() appBuilder,
  io.InternetAddress? address,
  int port = 8080,
  String pagePath = '/',
  String webSocketPath = '/ws',
  String browserTitle = 'Artisanal Widget Host',
  String? pageHtml,
  tui.ProgramOptions? options,
}) {
  return tui.BrowserTerminalHostServer.serveProgram(
    address: address,
    port: port,
    pagePath: pagePath,
    webSocketPath: webSocketPath,
    title: browserTitle,
    pageHtml: pageHtml,
    modelBuilder: appBuilder,
    options: options ?? defaultWidgetProgramOptions,
  );
}

/// Serves an [ArtisanalApp] in the browser through the shared websocket host.
Future<tui.BrowserTerminalHostServer> serveArtisanalAppInBrowser({
  required ArtisanalApp Function() appBuilder,
  io.InternetAddress? address,
  int port = 8080,
  String pagePath = '/',
  String webSocketPath = '/ws',
  String browserTitle = 'Artisanal Widget Host',
  String? pageHtml,
  tui.ProgramOptions? options,
}) {
  return tui.BrowserTerminalHostServer.serveProgram(
    address: address,
    port: port,
    pagePath: pagePath,
    webSocketPath: webSocketPath,
    title: browserTitle,
    pageHtml: pageHtml,
    modelBuilder: appBuilder,
    options: options ?? defaultWidgetProgramOptions,
  );
}

/// Serves a [WidgetApp] on the reusable raw TCP socket host.
Future<tui.SocketTerminalHostServer> serveWidgetAppOnSocket({
  required WidgetApp Function() appBuilder,
  io.InternetAddress? address,
  int port = 2323,
  bool v6Only = false,
  bool shared = false,
  tui.TerminalDimensions initialSize = const (width: 80, height: 24),
  bool supportsAnsi = true,
  ColorProfile colorProfile = ColorProfile.trueColor,
  tui.ProgramOptions? options,
}) {
  return tui.SocketTerminalHostServer.serveProgram(
    address: address,
    port: port,
    v6Only: v6Only,
    shared: shared,
    initialSize: initialSize,
    supportsAnsi: supportsAnsi,
    colorProfile: colorProfile,
    modelBuilder: appBuilder,
    options: options ?? defaultWidgetProgramOptions,
  );
}

/// Serves an [ArtisanalApp] on the reusable raw TCP socket host.
Future<tui.SocketTerminalHostServer> serveArtisanalAppOnSocket({
  required ArtisanalApp Function() appBuilder,
  io.InternetAddress? address,
  int port = 2323,
  bool v6Only = false,
  bool shared = false,
  tui.TerminalDimensions initialSize = const (width: 80, height: 24),
  bool supportsAnsi = true,
  ColorProfile colorProfile = ColorProfile.trueColor,
  tui.ProgramOptions? options,
}) {
  return tui.SocketTerminalHostServer.serveProgram(
    address: address,
    port: port,
    v6Only: v6Only,
    shared: shared,
    initialSize: initialSize,
    supportsAnsi: supportsAnsi,
    colorProfile: colorProfile,
    modelBuilder: appBuilder,
    options: options ?? defaultWidgetProgramOptions,
  );
}

Future<T> _runArtisanalAppWithDebugCapture<T>(
  ArtisanalApp app,
  Future<T> Function() body,
) {
  final controller = app.debugConsoleController;
  if (controller == null) {
    return body();
  }
  if (!app.debugConsoleCapturePrint && !app.debugConsoleCaptureErrors) {
    return body();
  }
  return controller.runZoned(
    body,
    capturePrint: app.debugConsoleCapturePrint,
    captureErrors: app.debugConsoleCaptureErrors,
  );
}
