/// Stable text input and editor API for composable terminal UIs.
///
/// This is a convenience re-export of `package:artisanal_widgets/editors.dart`
/// so apps depending on `package:artisanal` can keep using the umbrella
/// package for the supported widget editing surface.
///
/// Prefer the direct `artisanal_widgets` package when editor widgets are the
/// only UI surface your app needs. Keep this umbrella entrypoint when the app
/// already depends on the wider Artisanal toolkit.
library;

export 'package:artisanal_widgets/editors.dart';
