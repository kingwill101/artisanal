import 'dart:io' as io;

import 'package:artisanal/src/plugins/remote_plugin_kernel_cache.dart';
import 'package:path/path.dart' as p;

Future<void> main() async {
  final packageRoot = _resolveArtisanalPackageRoot();
  final cache = RemotePluginKernelCache(packageRoot: packageRoot);

  final tasks = <({String entrypoint, String outputPath})>[
    ..._fixtureTasks(packageRoot),
    ..._exampleTasks(packageRoot),
  ];

  for (final task in tasks) {
    final outputPath = await cache.ensureKernelSnapshot(
      entrypointPath: task.entrypoint,
      outputPath: task.outputPath,
    );
    io.stdout.writeln(outputPath);
  }
}

List<({String entrypoint, String outputPath})>
_fixtureTasks(String packageRoot) {
  final fixturesDir = p.join(packageRoot, 'test', 'plugins', 'fixtures');
  final outputDir = p.join(
    packageRoot,
    '.dart_tool',
    'artisanal',
    'precompiled-plugins',
    'test-fixtures',
  );
  return <({String entrypoint, String outputPath})>[
    for (final name in <String>[
      'echo_plugin.dart',
      'clipboard_plugin.dart',
      'open_url_plugin.dart',
      'notification_plugin.dart',
      'file_picker_plugin.dart',
      'generic_service_plugin.dart',
    ])
      (
        entrypoint: p.join(fixturesDir, name),
        outputPath: p.join(outputDir, '${p.basenameWithoutExtension(name)}.dill'),
      ),
  ];
}

List<({String entrypoint, String outputPath})>
_exampleTasks(String packageRoot) {
  final workspaceDir = p.join(
    packageRoot,
    'example',
    'tui',
    'remote_plugin_workspace',
  );
  final workspacePluginsDir = p.join(workspaceDir, 'plugins');
  final workspaceOutputDir = p.join(
    packageRoot,
    '.dart_tool',
    'artisanal',
    'precompiled-plugins',
    'remote-plugin-workspace',
  );
  final schemaDumpOutputDir = p.join(
    packageRoot,
    '.dart_tool',
    'artisanal',
    'precompiled-plugins',
    'schema-dump',
  );
  return <({String entrypoint, String outputPath})>[
    (
      entrypoint: p.join(workspaceDir, 'host', 'main.dart'),
      outputPath: p.join(workspaceOutputDir, 'host.dill'),
    ),
    for (final name in <String>[
      'activity_plugin.dart',
      'alerts_plugin.dart',
      'overview_plugin.dart',
    ])
      (
        entrypoint: p.join(workspacePluginsDir, name),
        outputPath: p.join(
          workspaceOutputDir,
          '${p.basenameWithoutExtension(name)}.dill',
        ),
      ),
    (
      entrypoint: p.join(packageRoot, 'example', 'tui', 'remote_plugin_schema_dump.dart'),
      outputPath: p.join(schemaDumpOutputDir, 'remote_plugin_schema_dump.dill'),
    ),
  ];
}

String _resolveArtisanalPackageRoot() {
  final current = io.Directory.current.path;
  final candidates = <String>[
    current,
    p.join(current, 'pkgs', 'artisanal'),
  ];
  for (final candidate in candidates) {
    if (io.FileSystemEntity.typeSync(
          p.join(candidate, 'pubspec.yaml'),
        ) !=
        io.FileSystemEntityType.notFound) {
      return candidate;
    }
  }
  throw StateError('Could not resolve the artisanal package root.');
}
