library;

/// Versatile language abstraction for the editor core.
///
/// This module defines the seams that let editor features (indentation,
/// auto-pairs, comments) vary per language without hardcoding language tables
/// in the core. Builtin registrations live in `code_language_profile.dart` as
/// opt-in data; alternative backends (Tree-sitter grammars, LSP servers,
/// custom DSLs) implement [EditorLanguageAdapter] and register via
/// [EditorLanguageRegistry] without touching core or adding FFI dependencies.
///
/// The core never imports `dart:ffi`. External packages (for example an
/// `artisanal_treesitter` bridge) depend on this package and implement these
/// interfaces using whatever native bindings they need.

/// Comment configuration for a language.
final class EditorCommentConfig {
  const EditorCommentConfig({
    required this.linePrefix,
    this.blockStart,
    this.blockEnd,
  });

  /// Line comment prefix, e.g. `//` or `#`.
  final String linePrefix;

  /// Block comment delimiters, when the language has them.
  final String? blockStart;
  final String? blockEnd;

  bool get hasBlockComment => blockStart != null && blockEnd != null;
}

/// Bracket/pair configuration for a language.
final class EditorPairConfig {
  const EditorPairConfig({
    this.autoPairs = const <String, String>{
      '(': ')',
      '[': ']',
      '{': '}',
      '"': '"',
      "'": "'",
      '`': '`',
    },
    this.closingToOpening = const <String, String>{
      ')': '(',
      ']': '[',
      '}': '{',
      '"': '"',
      "'": "'",
      '`': '`',
    },
  });

  final Map<String, String> autoPairs;
  final Map<String, String> closingToOpening;
}

/// Indent request passed to a language adapter.
final class EditorIndentContext {
  const EditorIndentContext({
    required this.lineBeforeCursor,
    required this.lineAfterCursor,
    required this.baseIndent,
    required this.indentWidth,
  });

  /// Text on the current line before the cursor (untrimmed).
  final String lineBeforeCursor;

  /// Text on the current line after the cursor (untrimmed).
  final String lineAfterCursor;

  /// Leading whitespace of the current line.
  final String baseIndent;

  /// Indent width in spaces.
  final int indentWidth;
}

/// Adapter that customizes editing behavior per language.
///
/// Implementations must be pure Dart interfaces: they receive plain strings
/// and offsets and return plain data. A Tree-sitter or LSP backend implements
/// this interface in its own package and registers itself; the core stays
/// FFI-free.
abstract class EditorLanguageAdapter {
  const EditorLanguageAdapter();

  /// Stable language identifier, e.g. `dart`, `python`, `markdown`.
  String get languageId;

  /// Alternate identifiers that resolve to this adapter (e.g. `py`, `yml`).
  List<String> get aliases => const <String>[];

  EditorCommentConfig get comments;
  EditorPairConfig get pairs => const EditorPairConfig();

  /// Whether a newline after [context.lineBeforeCursor] should add one indent
  /// level. The default covers C-style `{[(` openers; languages with extra
  /// rules (Python/YAML `:`) override this.
  bool shouldIncreaseIndent(EditorIndentContext context) {
    final trimmed = context.lineBeforeCursor.trimRight();
    if (trimmed.isEmpty) return false;
    final last = trimmed[trimmed.length - 1];
    return last == '{' || last == '[' || last == '(';
  }

  /// Optional extra indent string (beyond [EditorIndentContext.baseIndent])
  /// for a newline at [context]. Returns `''` for no extra indent.
  String extraIndentForNewline(EditorIndentContext context) {
    if (!shouldIncreaseIndent(context)) return '';
    final width = context.indentWidth < 1 ? 1 : context.indentWidth;
    return ' ' * width;
  }
}

/// Mutable registry mapping language identifiers to adapters.
///
/// The core ships with an empty registry; builtin registrations are opt-in
/// via `registerBuiltinEditorLanguages()` in `code_language_profile.dart` so
/// apps that need zero builtins can skip them entirely.
final class EditorLanguageRegistry {
  EditorLanguageRegistry({EditorLanguageAdapter? fallback});

  final Map<String, EditorLanguageAdapter> _byId = <String, EditorLanguageAdapter>{};
  EditorLanguageAdapter? _fallback;

  EditorLanguageRegistry._shared() : _fallback = null;

  /// Process-wide registry used by legacy string-based helpers.
  static final EditorLanguageRegistry shared =
      EditorLanguageRegistry._shared();

  EditorLanguageAdapter? get fallback => _fallback;
  set fallback(EditorLanguageAdapter? adapter) => _fallback = adapter ?? _fallback;

  void register(EditorLanguageAdapter adapter) {
    _byId[adapter.languageId.toLowerCase()] = adapter;
    for (final alias in adapter.aliases) {
      _byId[alias.toLowerCase()] = adapter;
    }
    _fallback ??= adapter;
  }

  bool unregister(String languageId) =>
      _byId.remove(languageId.toLowerCase()) != null;

  void clear() => _byId.clear();

  EditorLanguageAdapter? lookup(String? languageId) {
    if (languageId == null || languageId.isEmpty) return _fallback;
    return _byId[languageId.toLowerCase()] ?? _fallback;
  }

  EditorLanguageAdapter require(String? languageId) {
    final adapter = lookup(languageId);
    if (adapter == null) {
      throw StateError('No editor language registered for "$languageId".');
    }
    return adapter;
  }

  List<String> get languageIds => List<String>.unmodifiable(
        _byId.keys.toList(growable: false)..sort(),
      );
}
