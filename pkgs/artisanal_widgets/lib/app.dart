/// Stable app-shell and runner entrypoint for terminal widget apps.
///
/// Prefer this library when you want the supported hosting surface
/// without pulling in the full widget namespace:
///
/// - `WidgetApp`
/// - `ArtisanalApp`
/// - local runners such as `runWidgetApp(...)` and `runArtisanalApp(...)`
/// - reload helpers and watched/browser/socket host wrappers
///
/// {@category TUI}
library;

export 'src/widgets/app/widget_app.dart';
export 'src/widgets/app/artisanal_app.dart';
export 'src/widgets/app/reload.dart';
export 'src/widgets/app/reload_watcher.dart';
