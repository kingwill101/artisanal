library;

import 'text_language.dart';

final class CodeBlockCommentDelimiters {
  const CodeBlockCommentDelimiters({required this.start, required this.end});

  final String start;
  final String end;
}

final class CodeLanguageProfile extends EditorLanguageAdapter {
  const CodeLanguageProfile({
    required this.lineCommentPrefix,
    this.blockCommentDelimiters,
    this.autoPairs = defaultCodeAutoPairs,
    this.closingToOpening = defaultCodeClosingToOpening,
    this.languageId = 'default',
    this.aliases = const <String>[],
  });

  final String lineCommentPrefix;
  final CodeBlockCommentDelimiters? blockCommentDelimiters;
  final Map<String, String> autoPairs;
  final Map<String, String> closingToOpening;
  @override
  final String languageId;
  @override
  final List<String> aliases;

  @override
  EditorCommentConfig get comments => EditorCommentConfig(
        linePrefix: lineCommentPrefix,
        blockStart: blockCommentDelimiters?.start,
        blockEnd: blockCommentDelimiters?.end,
      );

  @override
  EditorPairConfig get pairs => EditorPairConfig(
        autoPairs: autoPairs,
        closingToOpening: closingToOpening,
      );

  @override
  bool shouldIncreaseIndent(EditorIndentContext context) {
    final trimmed = context.lineBeforeCursor.trimRight();
    if (trimmed.isEmpty) return false;
    final last = trimmed[trimmed.length - 1];
    if (last == '{' || last == '[' || last == '(') return true;
    // Colon rule is a per-language override (Python/YAML-likes), not a
    // core rule. It lives on the registered adapters below.
    if (last != ':') return false;
    final id = languageId.toLowerCase();
    return id == 'python' ||
        id == 'yaml' ||
        aliases.any(
          (alias) =>
              alias == 'py' ||
              alias == 'yaml' ||
              alias == 'yml',
        );
  }
}

const defaultCodeAutoPairs = <String, String>{
  '(': ')',
  '[': ']',
  '{': '}',
  '"': '"',
  "'": "'",
  '`': '`',
};

const defaultCodeClosingToOpening = <String, String>{
  ')': '(',
  ']': '[',
  '}': '{',
  '"': '"',
  "'": "'",
  '`': '`',
};

/// Builtin language registrations.
///
/// These are opt-in data, not core rules. Apps that want zero builtins can
/// ignore [registerBuiltinEditorLanguages] and register only their own
/// [EditorLanguageAdapter]s (Tree-sitter grammars, LSP-provided configs,
/// etc.) on any [EditorLanguageRegistry].
List<CodeLanguageProfile> builtinCodeLanguageProfiles() =>
    const <CodeLanguageProfile>[
      CodeLanguageProfile(
        languageId: 'default',
        lineCommentPrefix: '//',
        blockCommentDelimiters: CodeBlockCommentDelimiters(
          start: '/*',
          end: '*/',
        ),
      ),
      CodeLanguageProfile(
        languageId: 'python',
        aliases: ['py'],
        lineCommentPrefix: '#',
      ),
      CodeLanguageProfile(
        languageId: 'yaml',
        aliases: ['yml'],
        lineCommentPrefix: '#',
      ),
      CodeLanguageProfile(languageId: 'toml', lineCommentPrefix: '#'),
      CodeLanguageProfile(
        languageId: 'make',
        aliases: ['makefile'],
        lineCommentPrefix: '#',
      ),
      CodeLanguageProfile(
        languageId: 'ruby',
        aliases: ['rb'],
        lineCommentPrefix: '#',
        blockCommentDelimiters: CodeBlockCommentDelimiters(
          start: '/*',
          end: '*/',
        ),
      ),
      CodeLanguageProfile(
        languageId: 'shell',
        aliases: ['sh', 'bash', 'zsh'],
        lineCommentPrefix: '#',
        blockCommentDelimiters: CodeBlockCommentDelimiters(
          start: '/*',
          end: '*/',
        ),
      ),
      CodeLanguageProfile(
        languageId: 'sql',
        aliases: ['lua', 'haskell', 'hs'],
        lineCommentPrefix: '--',
        blockCommentDelimiters: CodeBlockCommentDelimiters(
          start: '/*',
          end: '*/',
        ),
      ),
      CodeLanguageProfile(
        languageId: 'html',
        aliases: ['xml', 'svg', 'markdown', 'md', 'mdx'],
        lineCommentPrefix: '//',
        blockCommentDelimiters: CodeBlockCommentDelimiters(
          start: '<!--',
          end: '-->',
        ),
      ),
    ];

/// Registers the builtin profiles on [registry] (defaults to the shared
/// registry). Safe to call multiple times.
void registerBuiltinEditorLanguages([
  EditorLanguageRegistry? registry,
]) {
  final target = registry ?? EditorLanguageRegistry.shared;
  for (final profile in builtinCodeLanguageProfiles()) {
    target.register(profile);
  }
  target.fallback ??= const CodeLanguageProfile(
    languageId: 'default',
    lineCommentPrefix: '//',
    blockCommentDelimiters: CodeBlockCommentDelimiters(
      start: '/*',
      end: '*/',
    ),
  );
}

bool _builtinLanguagesRegistered = false;

void _ensureBuiltinLanguagesRegistered() {
  if (_builtinLanguagesRegistered) return;
  _builtinLanguagesRegistered = true;
  registerBuiltinEditorLanguages(EditorLanguageRegistry.shared);
}

CodeLanguageProfile _profileFromAdapter(EditorLanguageAdapter adapter) {
  if (adapter is CodeLanguageProfile) return adapter;
  return CodeLanguageProfile(
    languageId: adapter.languageId,
    aliases: adapter.aliases,
    lineCommentPrefix: adapter.comments.linePrefix,
    blockCommentDelimiters: adapter.comments.hasBlockComment
        ? CodeBlockCommentDelimiters(
            start: adapter.comments.blockStart!,
            end: adapter.comments.blockEnd!,
          )
        : null,
    autoPairs: adapter.pairs.autoPairs,
    closingToOpening: adapter.pairs.closingToOpening,
  );
}

CodeLanguageProfile resolveCodeLanguageProfile(String? language) {
  _ensureBuiltinLanguagesRegistered();
  final adapter = EditorLanguageRegistry.shared.lookup(language);
  if (adapter == null) {
    return const CodeLanguageProfile(
      lineCommentPrefix: '//',
      blockCommentDelimiters: CodeBlockCommentDelimiters(
        start: '/*',
        end: '*/',
      ),
    );
  }
  return _profileFromAdapter(adapter);
}
