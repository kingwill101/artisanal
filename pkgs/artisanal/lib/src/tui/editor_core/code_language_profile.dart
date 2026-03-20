library;

final class CodeBlockCommentDelimiters {
  const CodeBlockCommentDelimiters({required this.start, required this.end});

  final String start;
  final String end;
}

final class CodeLanguageProfile {
  const CodeLanguageProfile({
    required this.lineCommentPrefix,
    this.blockCommentDelimiters,
    this.autoPairs = defaultCodeAutoPairs,
    this.closingToOpening = defaultCodeClosingToOpening,
  });

  final String lineCommentPrefix;
  final CodeBlockCommentDelimiters? blockCommentDelimiters;
  final Map<String, String> autoPairs;
  final Map<String, String> closingToOpening;
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

CodeLanguageProfile resolveCodeLanguageProfile(String? language) {
  final normalizedLanguage = (language ?? '').toLowerCase();
  return switch (normalizedLanguage) {
    'python' ||
    'py' ||
    'yaml' ||
    'yml' ||
    'toml' ||
    'make' ||
    'makefile' => const CodeLanguageProfile(lineCommentPrefix: '#'),
    'ruby' ||
    'rb' ||
    'shell' ||
    'sh' ||
    'bash' ||
    'zsh' => const CodeLanguageProfile(
      lineCommentPrefix: '#',
      blockCommentDelimiters: CodeBlockCommentDelimiters(
        start: '/*',
        end: '*/',
      ),
    ),
    'sql' || 'lua' || 'haskell' || 'hs' => const CodeLanguageProfile(
      lineCommentPrefix: '--',
      blockCommentDelimiters: CodeBlockCommentDelimiters(
        start: '/*',
        end: '*/',
      ),
    ),
    'html' ||
    'xml' ||
    'svg' ||
    'markdown' ||
    'md' ||
    'mdx' => const CodeLanguageProfile(
      lineCommentPrefix: '//',
      blockCommentDelimiters: CodeBlockCommentDelimiters(
        start: '<!--',
        end: '-->',
      ),
    ),
    _ => const CodeLanguageProfile(
      lineCommentPrefix: '//',
      blockCommentDelimiters: CodeBlockCommentDelimiters(
        start: '/*',
        end: '*/',
      ),
    ),
  };
}
