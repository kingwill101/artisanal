/// Resolves markdown fence labels and filename-style hints to highlight.dart
/// grammar names.
library;

final class FenceLanguageResolver {
  const FenceLanguageResolver._();

  static const Map<String, String> _languageAliases = {
    'js': 'javascript',
    'mjs': 'javascript',
    'cjs': 'javascript',
    'jsx': 'javascript',
    'ts': 'typescript',
    'mts': 'typescript',
    'cts': 'typescript',
    'tsx': 'typescript',
    'py': 'python',
    'rb': 'ruby',
    'rs': 'rust',
    'sh': 'bash',
    'shell': 'bash',
    'zsh': 'bash',
    'fish': 'bash',
    'yml': 'yaml',
    'md': 'markdown',
    'mdx': 'markdown',
    'objc': 'objectivec',
    'c++': 'cpp',
    'cxx': 'cpp',
    'cc': 'cpp',
    'hpp': 'cpp',
    'hxx': 'cpp',
    'c#': 'cs',
    'csx': 'cs',
    'f#': 'fsharp',
    'docker': 'dockerfile',
    'htm': 'xml',
    'xhtml': 'xml',
    'svg': 'xml',
    'plist': 'xml',
    'proto': 'protobuf',
  };

  static const Map<String, String> _specialFilenames = {
    'dockerfile': 'dockerfile',
    'containerfile': 'dockerfile',
    'makefile': 'makefile',
    'gnumakefile': 'makefile',
    'cmakelists.txt': 'cmake',
    'pubspec.yaml': 'yaml',
    'pubspec.yml': 'yaml',
    'pnpm-workspace.yaml': 'yaml',
    'pnpm-workspace.yml': 'yaml',
    'docker-compose.yaml': 'yaml',
    'docker-compose.yml': 'yaml',
    'compose.yaml': 'yaml',
    'compose.yml': 'yaml',
    'package.json': 'json',
    'tsconfig.json': 'json',
    'jsconfig.json': 'json',
    'deno.json': 'json',
    'deno.jsonc': 'json',
    '.eslintrc.json': 'json',
    '.babelrc': 'json',
    '.swcrc': 'json',
    'cargo.toml': 'ini',
    'gemfile': 'ruby',
    'rakefile': 'ruby',
    'podfile': 'ruby',
    '.bashrc': 'bash',
    '.bash_profile': 'bash',
    '.zshrc': 'bash',
    '.zprofile': 'bash',
    '.envrc': 'bash',
    'build.gradle': 'gradle',
    'settings.gradle': 'gradle',
    'build.gradle.kts': 'kotlin',
    'settings.gradle.kts': 'kotlin',
  };

  static const Map<String, String> _extensionAliases = {
    '.js': 'javascript',
    '.mjs': 'javascript',
    '.cjs': 'javascript',
    '.jsx': 'javascript',
    '.ts': 'typescript',
    '.mts': 'typescript',
    '.cts': 'typescript',
    '.tsx': 'typescript',
    '.py': 'python',
    '.rb': 'ruby',
    '.rs': 'rust',
    '.sh': 'bash',
    '.zsh': 'bash',
    '.fish': 'bash',
    '.yml': 'yaml',
    '.yaml': 'yaml',
    '.md': 'markdown',
    '.mdx': 'markdown',
    '.m': 'objectivec',
    '.mm': 'objectivec',
    '.c': 'cpp',
    '.cc': 'cpp',
    '.cpp': 'cpp',
    '.cxx': 'cpp',
    '.h': 'cpp',
    '.hh': 'cpp',
    '.hpp': 'cpp',
    '.hxx': 'cpp',
    '.cs': 'cs',
    '.fs': 'fsharp',
    '.fsx': 'fsharp',
    '.dockerfile': 'dockerfile',
    '.htm': 'xml',
    '.html': 'xml',
    '.xhtml': 'xml',
    '.xml': 'xml',
    '.svg': 'xml',
    '.plist': 'xml',
    '.json': 'json',
    '.jsonc': 'json',
    '.ini': 'ini',
    '.cfg': 'ini',
    '.conf': 'ini',
    '.properties': 'ini',
    '.cmake': 'cmake',
    '.gradle': 'gradle',
    '.kts': 'kotlin',
    '.kt': 'kotlin',
    '.swift': 'swift',
    '.go': 'go',
    '.java': 'java',
    '.php': 'php',
    '.sql': 'sql',
    '.css': 'css',
    '.scss': 'scss',
    '.proto': 'protobuf',
  };

  /// Resolves a fence label such as `js`, `main.rs`, `Dockerfile`, or
  /// `{.typescript}` to the best matching highlight.dart grammar name.
  static String? resolve(String? label) {
    final token = _canonicalFenceToken(label);
    if (token == null) return null;

    final filenameMatch = resolveFilename(token);
    if (filenameMatch != null) {
      return filenameMatch;
    }

    final normalized = token.toLowerCase();
    return _languageAliases[normalized] ?? normalized;
  }

  /// Resolves a filename or extension hint such as `main.rs`,
  /// `pubspec.yaml`, or `Dockerfile`.
  static String? resolveFilename(String? filename) {
    if (filename == null || filename.trim().isEmpty) return null;

    final trimmed = filename.trim();
    final slashIndex = trimmed.lastIndexOf(RegExp(r'[\\/]'));
    final basename =
        (slashIndex >= 0 ? trimmed.substring(slashIndex + 1) : trimmed).trim();
    if (basename.isEmpty) return null;

    final lower = basename.toLowerCase();
    final special = _specialFilenames[lower];
    if (special != null) {
      return special;
    }

    for (final entry in _extensionAliases.entries) {
      if (lower.endsWith(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }

  static String? _canonicalFenceToken(String? label) {
    if (label == null) return null;

    final trimmed = label.trim();
    if (trimmed.isEmpty) return null;

    var token = trimmed.split(RegExp(r'\s+')).first;
    if (token.startsWith('{') && token.endsWith('}')) {
      token = token.substring(1, token.length - 1);
    }
    if (token.startsWith('.')) {
      token = token.substring(1);
    }
    if (token.startsWith('lang-')) {
      token = token.substring(5);
    }
    if (token.startsWith('language-')) {
      token = token.substring(9);
    }

    token = token.trim();
    return token.isEmpty ? null : token;
  }
}
