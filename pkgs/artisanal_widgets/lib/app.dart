/// Stable app-shell entrypoint for terminal widget apps.
///
/// Prefer this library when you want the supported hosting surface
/// without pulling in the full widget namespace:
///
/// - `WidgetApp`
/// - `ArtisanalApp`
/// - reload helpers and file-watcher support
///
/// This entrypoint also exposes `runWidgetApp`, `serveWidgetApp`, transport
/// selection, and widget-oriented program defaults.
///
/// {@category TUI}
library;

export 'src/widgets/app/widget_app.dart';
export 'src/widgets/app/artisanal_app.dart';
export 'src/widgets/app/reload.dart';
export 'src/widgets/app/reload_watcher.dart';
export 'src/widgets/app/run_app.dart';
export 'src/widgets/app/transport.dart';
export 'src/widgets/layout/image.dart' show ImageAutoMode;
