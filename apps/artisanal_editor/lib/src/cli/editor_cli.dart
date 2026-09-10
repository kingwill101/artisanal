import 'dart:io';

import 'package:artisanal/args.dart';
import 'package:path/path.dart' as p;

import '../lsp/dart_language_service.dart';
import '../syntax/tree_sitter_highlighter.dart';
import '../ui/editor_app.dart';
import '../workspace/editor_file_repository.dart';
import '../workspace/editor_workspace.dart';

typedef EditorLauncher = Future<void> Function(EditorLaunchRequest request);

/// A startup problem that should be presented as a command usage error.
final class EditorLaunchException implements Exception {
  const EditorLaunchException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Immutable startup request produced by Artisanal's command runner.
final class EditorLaunchRequest {
  const EditorLaunchRequest({
    required this.workspace,
    required this.paths,
    required this.includeHidden,
    required this.enableLsp,
  });

  final String workspace;
  final List<String> paths;
  final bool includeHidden;
  final bool enableLsp;
}

/// Runs the editor CLI through Artisanal's styled [CommandRunner].
Future<void> runArtisanalEditor(
  List<String> arguments, {
  EditorLauncher launcher = launchEditor,
  String? workingDirectory,
}) async {
  final runner =
      CommandRunner<void>(
        CommandRunner.detectExecutableName(),
        'A modal terminal code editor built with Artisanal.',
      )..addCommand(
        _EditCommand(
          launcher: launcher,
          workingDirectory: workingDirectory ?? Directory.current.path,
        ),
      );

  await runner.run(_normalizeArguments(arguments));
}

List<String> _normalizeArguments(List<String> arguments) {
  if (arguments.isEmpty) return const ['edit'];
  final first = arguments.first;
  if (first == '--workspace' ||
      first.startsWith('--workspace=') ||
      first == '-w' ||
      first == '--hidden' ||
      first == '--lsp' ||
      first == '--no-lsp') {
    return ['edit', ...arguments];
  }
  if (first == 'edit' ||
      first == 'help' ||
      first == 'completion' ||
      first.startsWith('-')) {
    return arguments;
  }
  return ['edit', ...arguments];
}

final class _EditCommand extends Command<void> {
  _EditCommand({
    required EditorLauncher launcher,
    required String workingDirectory,
  }) : _launcher = launcher,
       _workingDirectory = workingDirectory {
    argParser
      ..addOption(
        'workspace',
        abbr: 'w',
        help: 'Workspace root. Defaults to the current directory.',
        valueHelp: 'directory',
      )
      ..addFlag(
        'hidden',
        negatable: false,
        help: 'Include hidden source files in the explorer.',
      )
      ..addFlag(
        'lsp',
        defaultsTo: true,
        help: 'Start language-server support for recognized files.',
      );
  }

  final EditorLauncher _launcher;
  final String _workingDirectory;

  @override
  String get name => 'edit';

  @override
  String get description => 'Open files or a workspace in the editor.';

  @override
  String get invocation => '${runner!.executableName} edit [files...]';

  @override
  Future<void> run() async {
    final positionalPaths = List<String>.unmodifiable(
      arguments.map((path) => p.absolute(_workingDirectory, path)),
    );
    final workspaceOption = option('workspace') as String?;
    final workspace = workspaceOption == null
        ? _inferWorkspace(positionalPaths)
        : p.absolute(_workingDirectory, workspaceOption);
    if (!Directory(workspace).existsSync()) {
      usageException('Workspace does not exist: $workspace');
    }
    for (final path in positionalPaths) {
      if (!File(path).existsSync()) {
        usageException('File does not exist: $path');
      }
    }

    try {
      await _launcher(
        EditorLaunchRequest(
          workspace: p.canonicalize(workspace),
          paths: [for (final path in positionalPaths) p.canonicalize(path)],
          includeHidden: option('hidden') as bool,
          enableLsp: option('lsp') as bool,
        ),
      );
    } on EditorLaunchException catch (error) {
      usageException(error.message);
    }
  }

  String _inferWorkspace(List<String> paths) {
    if (paths.isEmpty) return _workingDirectory;
    return p.dirname(paths.first);
  }
}

Future<void> launchEditor(EditorLaunchRequest request) async {
  const repository = EditorFileRepository();
  final discovered = await repository.discover(
    request.workspace,
    includeHidden: request.includeHidden,
  );
  final byPath = {for (final file in discovered) file.path: file};
  for (final path in request.paths) {
    byPath.putIfAbsent(
      path,
      () => repository.entryForPath(path, root: request.workspace),
    );
  }
  final files = byPath.values.toList()
    ..sort((left, right) => left.relativePath.compareTo(right.relativePath));
  if (files.isEmpty) {
    throw EditorLaunchException(
      'No supported source files found in ${request.workspace}.',
    );
  }

  TreeSitterSyntaxHighlighter? syntaxHighlighter;
  try {
    try {
      syntaxHighlighter = await TreeSitterSyntaxHighlighter.initialize();
    } on Object {
      // Syntax highlighting is an enhancement. CodeEditor retains its built-in
      // highlighter if the native runtime is unavailable on this platform.
    }
    final workspace = EditorWorkspace(
      root: request.workspace,
      files: List.unmodifiable(files),
      repository: repository,
      languageService: request.enableLsp
          ? DartLanguageService(workspaceRoot: request.workspace)
          : null,
      syntaxHighlighter: syntaxHighlighter,
    );
    final initialPath = request.paths.firstOrNull;
    final initialFile = initialPath == null
        ? files.first
        : byPath[initialPath]!;
    await workspace.open(initialFile);
    await runEditorApp(workspace);
  } finally {
    TreeSitterSyntaxHighlighter.disposeRuntime();
  }
}
