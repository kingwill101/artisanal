import 'package:artisanal/web.dart' show BrowserRunOptions, runBrowserProgram;

import 'widget_app.dart' show WidgetApp;

export 'package:artisanal/web.dart' show BrowserRunOptions;

/// Runs a [WidgetApp] in a browser canvas.
Future<void> runWidgetApp(
  WidgetApp app, {
  BrowserRunOptions options = const BrowserRunOptions(),
}) =>
    runBrowserProgram(app, options: options);

/// Network hosting is unavailable inside a browser tab.
Future<Never> serveWidgetApp({
  required Object Function() appBuilder,
  Object? transport,
  int port = 2323,
  Object? imageAutoMode,
  Object? options,
  Object? address,
  String pagePath = '/',
  String webSocketPath = '/ws',
  String browserTitle = 'Artisanal Widget Host',
  String? pageHtml,
  bool v6Only = false,
  bool shared = false,
  Object? initialSize,
  bool supportsAnsi = true,
  Object? colorProfile,
}) =>
    throw UnsupportedError('serveWidgetApp is not available on web.');
