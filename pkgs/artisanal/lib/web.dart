/// Web/WASM support for artisanal.
///
/// Provides browser-compatible backends, renderers, and entry points for
/// running TUI applications on HTML5 canvas.
///
/// ## Usage
///
/// ```dart
/// import 'package:artisanal/web.dart';
///
/// void main() {
///   await runWidgetAppInBrowser(MyApp());
/// }
/// ```
library;

export 'src/web/web.dart';
