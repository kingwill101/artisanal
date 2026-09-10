import 'dart:io';

import 'package:path/path.dart' as p;

/// A discoverable source file in an editor workspace.
final class EditorFileEntry {
  const EditorFileEntry({
    required this.path,
    required this.relativePath,
    required this.language,
  });

  final String path;
  final String relativePath;
  final String language;

  String get name => p.basename(path);
}

/// Filesystem boundary for the editor application.
class EditorFileRepository {
  const EditorFileRepository();

  static const _ignoredDirectories = {
    '.dart_tool',
    '.git',
    '.idea',
    '.vscode',
    'build',
    'coverage',
    'node_modules',
  };

  static const _languages = <String, String>{
    '.c': 'c',
    '.cc': 'cpp',
    '.cpp': 'cpp',
    '.css': 'css',
    '.dart': 'dart',
    '.go': 'go',
    '.h': 'c',
    '.hpp': 'cpp',
    '.html': 'html',
    '.java': 'java',
    '.js': 'javascript',
    '.json': 'json',
    '.md': 'markdown',
    '.py': 'python',
    '.rs': 'rust',
    '.sh': 'bash',
    '.toml': 'toml',
    '.ts': 'typescript',
    '.yaml': 'yaml',
    '.yml': 'yaml',
  };

  Future<List<EditorFileEntry>> discover(
    String root, {
    bool includeHidden = false,
    int limit = 500,
  }) async {
    final canonicalRoot = p.canonicalize(root);
    final directory = Directory(canonicalRoot);
    if (!await directory.exists()) return const [];

    final files = <EditorFileEntry>[];
    final pendingDirectories = <Directory>[directory];
    while (pendingDirectories.isNotEmpty && files.length < limit) {
      final current = pendingDirectories.removeLast();
      try {
        await for (final entity in current.list(followLinks: false)) {
          final relativePath = p.relative(entity.path, from: canonicalRoot);
          final name = p.basename(entity.path);
          if (entity is Directory) {
            if (_ignoredDirectories.contains(name)) continue;
            if (!includeHidden && name.startsWith('.')) continue;
            pendingDirectories.add(entity);
            continue;
          }
          if (entity is! File) continue;
          if (!includeHidden && name.startsWith('.')) continue;

          final language = languageForPath(entity.path);
          if (language == null) continue;
          files.add(
            EditorFileEntry(
              path: p.canonicalize(entity.path),
              relativePath: relativePath,
              language: language,
            ),
          );
          if (files.length >= limit) break;
        }
      } on FileSystemException {
        // An unreadable directory should not prevent the rest of the
        // workspace from opening.
      }
    }
    files.sort(
      (left, right) => left.relativePath.compareTo(right.relativePath),
    );
    return List.unmodifiable(files);
  }

  Future<String> read(EditorFileEntry file) => File(file.path).readAsString();

  Future<void> write(EditorFileEntry file, String contents) =>
      File(file.path).writeAsString(contents, flush: true);

  EditorFileEntry entryForPath(String path, {required String root}) {
    final canonicalPath = p.canonicalize(path);
    return EditorFileEntry(
      path: canonicalPath,
      relativePath: p.relative(canonicalPath, from: p.canonicalize(root)),
      language: languageForPath(canonicalPath) ?? 'text',
    );
  }

  String? languageForPath(String path) =>
      _languages[p.extension(path).toLowerCase()];
}
