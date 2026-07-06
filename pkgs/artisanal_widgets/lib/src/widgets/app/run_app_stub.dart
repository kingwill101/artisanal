/// Stub for `run_app.dart` when `dart:io` is not available.
library;

import 'package:artisanal/artisanal.dart' as hosts;
import 'package:artisanal/tui.dart' as runtime;
import '../layout/image.dart' show ImageAutoMode;
import 'artisanal_app.dart';
import 'reload.dart';
import 'reload_watcher.dart';
import '../theme/theme.dart';
import 'widget_app.dart';
import '../style.dart';

const runtime.ProgramOptions defaultWidgetProgramOptions =
    runtime.ProgramOptions(
      altScreen: true,
      mouseMode: runtime.MouseMode.allMotion,
      startupProbes: false,
    );

Never _unsupported() =>
    throw UnsupportedError('run_app.dart is not available on this platform');

Future<void> runWidgetApp(
  WidgetApp app, {
  runtime.ProgramOptions? options,
  hosts.ProgramHost? host,
  ImageAutoMode? imageAutoMode,
}) async => _unsupported();

Future<void> runArtisanalApp(
  ArtisanalApp app, {
  runtime.ProgramOptions? options,
  hosts.ProgramHost? host,
  ImageAutoMode? imageAutoMode,
}) async => _unsupported();

Future<void> runReloadableWidgetApp(
  ReloadWidgetBuilder builder, {
  required ReloadController controller,
  runtime.ProgramOptions? options,
  hosts.ProgramHost? host,
  ImageAutoMode? imageAutoMode,
}) async => _unsupported();

final class WatchedBrowserArtisanalAppHost {
  WatchedBrowserArtisanalAppHost._({
    required this.server,
    required this.controller,
    required this.watcher,
  });

  final hosts.BrowserTerminalHostServer server;
  final ReloadController controller;
  final ReloadFileWatcher? watcher;

  Future<void> close({bool force = false}) async => _unsupported();
}

final class WatchedSocketArtisanalAppHost {
  WatchedSocketArtisanalAppHost._({
    required this.server,
    required this.controller,
    required this.watcher,
  });

  final hosts.SocketTerminalHostServer server;
  final ReloadController controller;
  final ReloadFileWatcher? watcher;

  Future<void> close({bool force = false}) async => _unsupported();
}

Future<void> runReloadableArtisanalApp({
  required ReloadWidgetBuilder homeBuilder,
  required ReloadController controller,
  String? title,
  Theme? theme,
  Theme? darkTheme,
  ThemeMode themeMode = ThemeMode.system,
  Theme Function()? themeBuilder,
  runtime.ProgramOptions? options,
  hosts.ProgramHost? host,
  ImageAutoMode? imageAutoMode,
}) async => _unsupported();

Future<void> runWatchedWidgetApp(
  ReloadWidgetBuilder builder, {
  required Iterable<String> watchRoots,
  ReloadController? controller,
  ReloadMode watchMode = ReloadMode.reload,
  Duration watchDebounce = const Duration(milliseconds: 150),
  bool watchRecursive = true,
  bool watchIgnoreHidden = true,
  Iterable<String> watchExtensions = const <String>['.dart'],
  runtime.ProgramOptions? options,
  hosts.ProgramHost? host,
  ImageAutoMode? imageAutoMode,
}) async => _unsupported();

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
  runtime.ProgramOptions? options,
  hosts.ProgramHost? host,
  ImageAutoMode? imageAutoMode,
}) async => _unsupported();

Future<hosts.BrowserTerminalHostServer> serveReloadableArtisanalAppInBrowser({
  required ReloadWidgetBuilder homeBuilder,
  required ReloadController controller,
  Object? address,
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
  ImageAutoMode imageAutoMode = ImageAutoMode.sessionCapabilities,
  runtime.ProgramOptions? options,
}) async => _unsupported();

Future<hosts.SocketTerminalHostServer> serveReloadableArtisanalAppOnSocket({
  required ReloadWidgetBuilder homeBuilder,
  required ReloadController controller,
  Object? address,
  int port = 2323,
  bool v6Only = false,
  bool shared = false,
  hosts.TerminalDimensions initialSize = const (width: 80, height: 24),
  bool supportsAnsi = true,
  ColorProfile colorProfile = ColorProfile.trueColor,
  String? title,
  Theme? theme,
  Theme? darkTheme,
  ThemeMode themeMode = ThemeMode.system,
  Theme Function()? themeBuilder,
  ImageAutoMode imageAutoMode = ImageAutoMode.sessionCapabilities,
  runtime.ProgramOptions? options,
}) async => _unsupported();

Future<WatchedBrowserArtisanalAppHost> serveWatchedArtisanalAppInBrowser({
  required ReloadWidgetBuilder homeBuilder,
  required Iterable<String> watchRoots,
  ReloadController? controller,
  ReloadMode watchMode = ReloadMode.reload,
  Duration watchDebounce = const Duration(milliseconds: 150),
  bool watchRecursive = true,
  bool watchIgnoreHidden = true,
  Iterable<String> watchExtensions = const <String>['.dart'],
  Object? address,
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
  ImageAutoMode imageAutoMode = ImageAutoMode.sessionCapabilities,
  runtime.ProgramOptions? options,
}) async => _unsupported();

Future<WatchedSocketArtisanalAppHost> serveWatchedArtisanalAppOnSocket({
  required ReloadWidgetBuilder homeBuilder,
  required Iterable<String> watchRoots,
  ReloadController? controller,
  ReloadMode watchMode = ReloadMode.reload,
  Duration watchDebounce = const Duration(milliseconds: 150),
  bool watchRecursive = true,
  bool watchIgnoreHidden = true,
  Iterable<String> watchExtensions = const <String>['.dart'],
  Object? address,
  int port = 2323,
  bool v6Only = false,
  bool shared = false,
  hosts.TerminalDimensions initialSize = const (width: 80, height: 24),
  bool supportsAnsi = true,
  ColorProfile colorProfile = ColorProfile.trueColor,
  String? title,
  Theme? theme,
  Theme? darkTheme,
  ThemeMode themeMode = ThemeMode.system,
  Theme Function()? themeBuilder,
  ImageAutoMode imageAutoMode = ImageAutoMode.sessionCapabilities,
  runtime.ProgramOptions? options,
}) async => _unsupported();

Future<hosts.BrowserTerminalHostServer> serveWidgetAppInBrowser({
  required WidgetApp Function() appBuilder,
  Object? address,
  int port = 8080,
  String pagePath = '/',
  String webSocketPath = '/ws',
  String browserTitle = 'Artisanal Widget Host',
  String? pageHtml,
  ImageAutoMode imageAutoMode = ImageAutoMode.sessionCapabilities,
  runtime.ProgramOptions? options,
}) async => _unsupported();

Future<hosts.BrowserTerminalHostServer> serveArtisanalAppInBrowser({
  required ArtisanalApp Function() appBuilder,
  Object? address,
  int port = 8080,
  String pagePath = '/',
  String webSocketPath = '/ws',
  String browserTitle = 'Artisanal Widget Host',
  String? pageHtml,
  ImageAutoMode imageAutoMode = ImageAutoMode.sessionCapabilities,
  runtime.ProgramOptions? options,
}) async => _unsupported();

Future<hosts.SocketTerminalHostServer> serveWidgetAppOnSocket({
  required WidgetApp Function() appBuilder,
  Object? address,
  int port = 2323,
  bool v6Only = false,
  bool shared = false,
  hosts.TerminalDimensions initialSize = const (width: 80, height: 24),
  bool supportsAnsi = true,
  ColorProfile colorProfile = ColorProfile.trueColor,
  ImageAutoMode imageAutoMode = ImageAutoMode.sessionCapabilities,
  runtime.ProgramOptions? options,
}) async => _unsupported();

Future<hosts.SocketTerminalHostServer> serveArtisanalAppOnSocket({
  required ArtisanalApp Function() appBuilder,
  Object? address,
  int port = 2323,
  bool v6Only = false,
  bool shared = false,
  hosts.TerminalDimensions initialSize = const (width: 80, height: 24),
  bool supportsAnsi = true,
  ColorProfile colorProfile = ColorProfile.trueColor,
  ImageAutoMode imageAutoMode = ImageAutoMode.sessionCapabilities,
  runtime.ProgramOptions? options,
}) async => _unsupported();
