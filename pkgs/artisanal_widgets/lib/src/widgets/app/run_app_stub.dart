/// Stub for `run_app.dart` when neither `dart:io` nor `dart:html` is available.
library;

Never _throw() => throw UnsupportedError(
      'Widget app entrypoints are not available on this platform.',
    );

Future<void> runWidgetApp(
  Object app, {
  Object? options,
  Object? host,
  Object? imageAutoMode,
  Object? browserOptions,
}) async =>
    _throw();

Future<void> serveWidgetApp({
  required Object Function() appBuilder,
  Object transport = Object,
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
}) async =>
    _throw();
