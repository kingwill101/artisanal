/// Text-input and editor primitives for terminal applications.
///
/// This focused entrypoint combines Artisanal's reusable editor core with the
/// cursor, single-line input, and multi-line text-area models. It avoids
/// loading unrelated Bubbles components.
///
/// {@category TUI}
library;

export 'editor_core.dart';
export 'src/tui/bubbles/cursor.dart';
export 'src/tui/bubbles/textarea.dart';
export 'src/tui/bubbles/textinput.dart';
export 'src/tui/runtime.dart' show keyMatchesSingle;
