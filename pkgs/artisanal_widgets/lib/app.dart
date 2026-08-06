/// Stable app-shell entrypoint for terminal widget apps.
///
/// Prefer this library when you want the supported hosting surface
/// without pulling in the full widget namespace:
///
/// - `WidgetApp`
/// - `ArtisanalApp`
/// - reload helpers and file-watcher support
///
/// Import `package:artisanal/artisanal.dart` for the public `runWidgetApp`
/// runner and hosted app entrypoints.
///
/// {@category TUI}
library;

export 'src/widgets/app/widget_app.dart';
export 'src/widgets/app/artisanal_app.dart';
export 'src/widgets/app/reload.dart';
export 'src/widgets/app/reload_watcher.dart';
