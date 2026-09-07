library;

/// Opt-in code/language extensions built on the versatile core.
///
/// These are *not* part of the minimal core exported by `editor_core.dart`:
/// they bundle opinionated defaults (builtin language table, C-style indent
/// policy, auto-pair handlers) for hosts that want them. Hosts building a
/// Vim-like experience with Tree-sitter grammars or custom languages can skip
/// this barrel entirely and register their own [EditorLanguageAdapter]s.
export 'code_edit_policy.dart';
export 'code_editing.dart';
export 'code_language_profile.dart';