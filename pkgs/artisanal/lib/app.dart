/// Stable widget app-shell and runner API for composable terminal UIs.
///
/// This is a convenience re-export of `package:artisanal_widgets/app.dart` so
/// apps depending on `package:artisanal` can keep using the umbrella package
/// for the supported widget hosting surface.
///
/// Prefer the direct `artisanal_widgets` package when widget hosting is the
/// only surface you need. Keep this umbrella entrypoint when the app already
/// depends on the wider Artisanal toolkit.
library;

export 'package:artisanal_widgets/app.dart';
