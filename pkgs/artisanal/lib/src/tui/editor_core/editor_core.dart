library;

export 'editor_core_config.dart';
export 'documents.dart';
export 'document_persistence.dart';
export 'editing.dart';
export 'viewing.dart';
// Versatile seams: language adapters (no builtins, no FFI) and
// Tree-sitter-style syntax-tree DTOs. Future advanced editing features
// (motions, text objects, modal layers) build on these without touching core.
export 'text_language.dart';
export 'syntax_tree.dart';
// Prompt-composer helpers: tracked paste placeholders, prompt
// normalization + external-editor resolution, and IDE selection ingestion.
export 'text_placeholders.dart';
export 'prompt_content.dart';
export 'editor_selection.dart';
export 'editor_commands.dart';
export 'completion.dart';
export 'code_actions.dart';
// Advanced editing capabilities: bracket matching, regex search, multi-
// selection sets, workspace edits, snippets, and folding.
export 'text_brackets.dart';
export 'text_search.dart';
export 'text_selection_set.dart';
export 'workspace_edits.dart';
export 'text_snippets.dart';
export 'text_folding.dart';
// Inline media: typed chip elements plus the attachment lifecycle
// (preview pipeline, viewer state, capability-gated affordances).
export 'text_inline_elements.dart';
export 'media_attachments.dart';
export 'media_paths.dart';
