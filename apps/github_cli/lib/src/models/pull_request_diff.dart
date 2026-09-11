import '../client/json.dart';

const githubPullRequestDiffMaxFiles = int.fromEnvironment(
  'GITHUB_CLI_DIFF_MAX_FILES',
  defaultValue: 500,
);

const githubPullRequestDiffMaxBytes = int.fromEnvironment(
  'GITHUB_CLI_DIFF_MAX_BYTES',
  defaultValue: 2 * 1024 * 1024,
);

const githubPullRequestDiffMaxFileBytes = int.fromEnvironment(
  'GITHUB_CLI_DIFF_MAX_FILE_BYTES',
  defaultValue: 128 * 1024,
);

const githubPullRequestDiffChunkBytes = int.fromEnvironment(
  'GITHUB_CLI_DIFF_CHUNK_BYTES',
  defaultValue: 512 * 1024,
);

final class GithubPullRequestDiffChunk {
  const GithubPullRequestDiffChunk({
    required this.text,
    required this.loadedFiles,
    required this.renderedFiles,
    required this.omittedFiles,
    required this.truncated,
    this.files = const <GithubPullRequestDiffFile>[],
  });

  final String text;
  final int loadedFiles;
  final int renderedFiles;
  final int omittedFiles;
  final bool truncated;
  final List<GithubPullRequestDiffFile> files;

  GithubPullRequestDiffChunk withText(String value) {
    return GithubPullRequestDiffChunk(
      text: value,
      loadedFiles: loadedFiles,
      renderedFiles: renderedFiles,
      omittedFiles: omittedFiles,
      truncated: truncated,
      files: files,
    );
  }
}

final class GithubPullRequestDiffFile {
  const GithubPullRequestDiffFile({
    required this.filename,
    this.previousFilename,
    this.status = '',
    this.patch,
    this.additions = 0,
    this.deletions = 0,
    this.changes = 0,
    this.collapsedReason,
  });

  final String filename;
  final String? previousFilename;
  final String status;
  final String? patch;
  final int additions;
  final int deletions;
  final int changes;
  final String? collapsedReason;

  static GithubPullRequestDiffFile fromJson(Map<String, Object?> json) {
    final previous = ghString(json['previous_filename']);
    final rawPatch = ghString(json['patch']).trimRight();
    return GithubPullRequestDiffFile(
      filename: ghString(json['filename']),
      previousFilename: previous.isEmpty ? null : previous,
      status: ghString(json['status']),
      patch: rawPatch.isEmpty ? null : rawPatch,
      additions: ghInt(json['additions']),
      deletions: ghInt(json['deletions']),
      changes: ghInt(json['changes']),
    );
  }

  bool get hasPatch => (patch ?? '').trimRight().isNotEmpty;

  bool get isCollapsed => collapsedReason != null;

  bool get isBinary => !isCollapsed && !hasPatch;

  int get displayChanges => changes == 0 ? additions + deletions : changes;

  GithubPullRequestDiffFile collapsed(String reason) {
    return GithubPullRequestDiffFile(
      filename: filename,
      previousFilename: previousFilename,
      status: status,
      additions: additions,
      deletions: deletions,
      changes: changes,
      collapsedReason: reason,
    );
  }

  String toUnifiedPatch() {
    final oldPath = previousFilename ?? filename;
    final newPath = filename;
    final oldRef = status == 'added'
        ? '/dev/null'
        : _prefixedDiffPath('a', oldPath);
    final newRef = status == 'removed'
        ? '/dev/null'
        : _prefixedDiffPath('b', newPath);
    final lines = <String>[
      'diff --git ${_prefixedDiffPath('a', oldPath)} ${_prefixedDiffPath('b', newPath)}',
      if (status == 'renamed' && previousFilename != null) ...[
        'rename from $oldPath',
        'rename to $newPath',
      ],
      '--- $oldRef',
      '+++ $newRef',
    ];

    final body = patch?.trimRight() ?? '';
    if (collapsedReason != null) {
      lines
        ..add('@@ -0,0 +1,4 @@')
        ..add('+Diff body collapsed to keep the terminal responsive.')
        ..add('+$collapsedReason')
        ..add('+File: $filename')
        ..add('+Changes: +$additions -$deletions');
    } else if (body.isNotEmpty) {
      lines.add(body);
    } else {
      lines.add('Binary files $oldRef and $newRef differ');
    }
    return lines.join('\n');
  }
}

final class GithubPullRequestDiffBuffer {
  GithubPullRequestDiffBuffer({
    this.maxFiles = githubPullRequestDiffMaxFiles,
    this.maxBytes = githubPullRequestDiffMaxBytes,
  });

  final int maxFiles;
  final int maxBytes;
  final int maxFileBytes = githubPullRequestDiffMaxFileBytes;

  int loadedFiles = 0;
  int renderedFiles = 0;
  int omittedFiles = 0;
  int renderedBytes = 0;
  bool truncated = false;
  bool _needsSeparator = false;

  bool get shouldStop => truncated;

  GithubPullRequestDiffChunk addFiles(
    Iterable<GithubPullRequestDiffFile> files,
  ) {
    final buffer = StringBuffer();
    final chunkFiles = <GithubPullRequestDiffFile>[];
    for (final file in files) {
      loadedFiles++;
      if (file.filename.isEmpty) {
        omittedFiles++;
        continue;
      }

      final patch = file.toUnifiedPatch();
      if (patch.length > maxFileBytes) {
        omittedFiles++;
        final collapsed = file.collapsed(
          'File diff is ${patch.length} bytes; limit is $maxFileBytes bytes.',
        );
        final collapsedPatch = collapsed.toUnifiedPatch();
        final separatorBytes = _needsSeparator ? 1 : 0;
        final nextBytes =
            renderedBytes + separatorBytes + collapsedPatch.length;
        if (renderedFiles < maxFiles && nextBytes <= maxBytes) {
          if (_needsSeparator) buffer.writeln();
          buffer.write(collapsedPatch);
          _needsSeparator = true;
          renderedFiles++;
          renderedBytes = nextBytes;
        } else {
          truncated = true;
        }
        chunkFiles.add(collapsed);
        continue;
      }

      final separatorBytes = _needsSeparator ? 1 : 0;
      final nextBytes = renderedBytes + separatorBytes + patch.length;
      if (renderedFiles >= maxFiles || nextBytes > maxBytes) {
        omittedFiles++;
        truncated = true;
        chunkFiles.add(
          file.collapsed(
            'Overall diff preview limit reached before this file.',
          ),
        );
        continue;
      }

      if (_needsSeparator) buffer.writeln();
      buffer.write(patch);
      _needsSeparator = true;
      renderedFiles++;
      renderedBytes = nextBytes;
      chunkFiles.add(file);
    }

    return GithubPullRequestDiffChunk(
      text: buffer.toString(),
      loadedFiles: loadedFiles,
      renderedFiles: renderedFiles,
      omittedFiles: omittedFiles,
      truncated: truncated,
      files: List.unmodifiable(chunkFiles),
    );
  }

  GithubPullRequestDiffChunk finish() {
    final text = truncated ? _truncationPatch() : '';
    return GithubPullRequestDiffChunk(
      text: text,
      loadedFiles: loadedFiles,
      renderedFiles: renderedFiles,
      omittedFiles: omittedFiles,
      truncated: truncated,
      files: truncated
          ? <GithubPullRequestDiffFile>[
              GithubPullRequestDiffFile(
                filename: '.github-cli-diff-limit',
                status: 'added',
                additions: 5,
                changes: 5,
                patch:
                    '@@ -0,0 +1,5 @@\n'
                    '+Diff preview truncated to keep the terminal responsive.\n'
                    '+Fetched files before stopping: $loadedFiles\n'
                    '+Rendered files: $renderedFiles\n'
                    '+Skipped fetched files: $omittedFiles\n'
                    '+Limits: $maxFiles files, $maxBytes bytes',
              ),
            ]
          : const <GithubPullRequestDiffFile>[],
    );
  }

  String _truncationPatch() {
    final buffer = StringBuffer();
    if (_needsSeparator) buffer.writeln();
    buffer
      ..writeln('diff --git a/.github-cli-diff-limit b/.github-cli-diff-limit')
      ..writeln('--- /dev/null')
      ..writeln('+++ b/.github-cli-diff-limit')
      ..writeln('@@ -0,0 +1,5 @@')
      ..writeln('+Diff preview truncated to keep the terminal responsive.')
      ..writeln('+Fetched files before stopping: $loadedFiles')
      ..writeln('+Rendered files: $renderedFiles')
      ..writeln('+Skipped fetched files: $omittedFiles')
      ..write('+Limits: $maxFiles files, $maxBytes bytes');
    return buffer.toString();
  }
}

String githubPullRequestFilesToPatch(
  Iterable<GithubPullRequestDiffFile> files, {
  int maxFiles = githubPullRequestDiffMaxFiles,
  int maxBytes = githubPullRequestDiffMaxBytes,
}) {
  final buffer = GithubPullRequestDiffBuffer(
    maxFiles: maxFiles,
    maxBytes: maxBytes,
  );
  final chunk = buffer.addFiles(files);
  final done = buffer.finish();
  return '${chunk.text}${done.text}';
}

String _prefixedDiffPath(String prefix, String path) {
  return _diffPath('$prefix/$path');
}

String _diffPath(String path) {
  if (!path.contains(RegExp(r'\s|"'))) return path;
  return '"${path.replaceAll('\\', r'\\').replaceAll('"', r'\"')}"';
}
