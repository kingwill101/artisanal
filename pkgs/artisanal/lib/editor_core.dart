/// Stable low-level text editing primitives for terminal editors.
///
/// This entrypoint exposes the reusable document, cursor/selection, view,
/// command, history, decoration, language-adapter, and syntax-tree layers
/// that power the higher-level editor widgets and TUI text areas.
/// Language-specific builtins (comment tables, indent policy, auto-pairs)
/// live in `code_extensions.dart` and are re-exported here for backwards
/// compatibility; new editors with custom languages or Tree-sitter-backed
/// tooling should depend on the core adapters directly and skip the builtins
/// when they want zero bundled languages.
///
/// It is intended for editor implementations, language tooling, and advanced
/// integrations that need lower-level editing surfaces than
/// `package:artisanal_widgets/editors.dart`.
library;

import 'src/tui/editor_core/editor_core.dart'
    show EditorState, TextDocument, TextView;

export 'src/tui/editor_core/editor_core.dart';
export 'src/tui/editor_core/code_extensions.dart';

/// Compatibility alias for a reusable text storage surface.
typedef TextBuffer = TextDocument;

/// Compatibility alias for the viewport/layout primitive over a [TextBuffer].
typedef EditorView = TextView;

/// Compatibility alias for cursor/selection editing state.
typedef EditBufferState = EditorState;
