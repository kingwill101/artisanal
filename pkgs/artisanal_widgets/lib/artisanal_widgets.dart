/// Widget system for composable TUI components.
///
/// This library exposes the widget API (including [Key]) without pulling in
/// the full TUI runtime exports.
@experimental
library;

import 'package:meta/meta.dart' show experimental;

export 'src/widgets/widgets.dart' hide StateSetter;
