/// Legacy broad widget entrypoint for composable TUI components.
///
/// Prefer the focused stable entrypoints for supported APIs:
///
/// - `package:artisanal_widgets/widgets.dart`
/// - `package:artisanal_widgets/charting.dart`
/// - `package:artisanal_widgets/selection.dart`
/// - `package:artisanal_widgets/testing.dart`
///
/// This library remains available for backward compatibility and continues to
/// expose additional experimental internals and modules.
///
/// {@category TUI}
library;

export 'app.dart';
export 'src/widgets/widgets.dart' hide StateSetter;
