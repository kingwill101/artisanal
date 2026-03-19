/// Legacy broad widget entrypoint for composable TUI components.
///
/// Prefer `package:artisanal_widgets/widgets.dart` for the stabilized
/// high-level widget surface. This library remains available for backward
/// compatibility and continues to expose additional experimental internals
/// and modules.
@experimental
library;

import 'package:meta/meta.dart' show experimental;

export 'src/widgets/widgets.dart' hide StateSetter;
