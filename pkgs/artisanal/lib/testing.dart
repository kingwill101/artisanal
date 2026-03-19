/// Stable widget testing API for composable terminal UIs.
///
/// This is a convenience re-export of `package:artisanal_widgets/testing.dart`
/// so apps depending on `package:artisanal` can keep using the umbrella
/// package for the supported widget testing surface.
///
/// Prefer the direct `artisanal_widgets` package when widget testing helpers
/// are the only UI surface your app needs. Keep this umbrella entrypoint when
/// the app already depends on the wider Artisanal toolkit.
library;

export 'package:artisanal_widgets/testing.dart';
