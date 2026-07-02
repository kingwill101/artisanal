import 'dart:convert';
import 'dart:io' as io;

import 'package:artisanal/src/plugins/remote_plugin_kernel_cache.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'package:artisanal/src/plugins/remote_plugin_kernel_cache.dart';

final String _artisanalRootDirectory = io.Directory.current.path;
final _kernelCache = RemotePluginKernelCache(packageRoot: _artisanalRootDirectory);
final String _precompiledWorkspaceDirectory = p.join(
  _artisanalRootDirectory,
  '.dart_tool',
  'artisanal',
  'precompiled-plugins',
  'remote-plugin-workspace',
);

void main() {
  late _CompiledWorkspaceHarness harness;

  setUpAll(() async {
    harness = await _CompiledWorkspaceHarness.create();
  });

  tearDownAll(() async {
    await harness.dispose();
  });

  test(
    'remote plugin workspace snapshot renders all example plugins',
    () async {
      final result = await harness.runHost(<String>['--snapshot']);

      expect(result.exitCode, 0, reason: '${result.stderr}');

      final stdout = result.stdout as String;
      expect(stdout, contains('Remote Plugin Workspace'));
      expect(stdout, contains('Overview'));
      expect(stdout, contains('Activity'));
      expect(stdout, contains('Alerts'));
      expect(stdout, contains('Hint'));
    },
    timeout: const Timeout(Duration(seconds: 90)),
  );

  test(
    'remote plugin workspace snapshot click focuses the clicked plugin',
    () async {
      final result = await harness.runHost(<String>[
        '--snapshot',
        '--snapshot-click=37,6',
      ]);

      expect(result.exitCode, 0, reason: '${result.stderr}');

      final stdout = result.stdout as String;
      expect(stdout, contains('Selected: activity'));
      expect(stdout, contains('Activity [focused]'));
      expect(stdout, contains('click 37,6'));
    },
    timeout: const Timeout(Duration(seconds: 90)),
  );

  test(
    'remote plugin workspace snapshot key routes into the focused plugin',
    () async {
      final result = await harness.runHost(<String>[
        '--snapshot',
        '--snapshot-click=37,6',
        '--snapshot-key=a',
      ]);

      expect(result.exitCode, 0, reason: '${result.stderr}');

      final stdout = result.stdout as String;
      expect(stdout, contains('Selected: activity'));
      expect(stdout, contains('Activity [focused]'));
      expect(stdout, contains('Last key: a'));
      expect(stdout, contains('key a'));
    },
    timeout: const Timeout(Duration(seconds: 90)),
  );

  test(
    'remote plugin workspace snapshot key can call host clipboard service',
    () async {
      final result = await harness.runHost(<String>[
        '--snapshot',
        '--snapshot-click=37,6',
        '--snapshot-key=c',
      ]);

      expect(result.exitCode, 0, reason: '${result.stderr}');

      final stdout = result.stdout as String;
      expect(stdout, contains('Selected: activity'));
      expect(stdout, contains('Clipboard: workspace clipboard'));
      expect(stdout, contains('key c'));
    },
    timeout: const Timeout(Duration(seconds: 90)),
  );

  test(
    'remote plugin workspace snapshot key can call host open-url service',
    () async {
      final result = await harness.runHost(<String>[
        '--snapshot',
        '--snapshot-click=37,6',
        '--snapshot-key=o',
      ]);

      expect(result.exitCode, 0, reason: '${result.stderr}');

      final stdout = result.stdout as String;
      expect(stdout, contains('Selected: activity'));
      expect(stdout, contains('URL: opened'));
      expect(stdout, contains('key o'));
    },
    timeout: const Timeout(Duration(seconds: 90)),
  );

  test(
    'remote plugin workspace snapshot key can call host notification service',
    () async {
      final result = await harness.runHost(<String>[
        '--snapshot',
        '--snapshot-click=37,6',
        '--snapshot-key=n',
      ]);

      expect(result.exitCode, 0, reason: '${result.stderr}');

      final stdout = result.stdout as String;
      expect(stdout, contains('Selected: activity'));
      expect(stdout, contains('Notice: sent'));
      expect(stdout, contains('key n'));
    },
    timeout: const Timeout(Duration(seconds: 90)),
  );

  test(
    'remote plugin workspace snapshot key can call host file-picker service',
    () async {
      final result = await harness.runHost(<String>[
        '--snapshot',
        '--snapshot-click=37,6',
        '--snapshot-key=p',
      ]);

      expect(result.exitCode, 0, reason: '${result.stderr}');

      final stdout = result.stdout as String;
      expect(stdout, contains('Selected: activity'));
      expect(stdout, contains('Picker: /tmp/workspace.txt'));
      expect(stdout, contains('key p'));
    },
    timeout: const Timeout(Duration(seconds: 90)),
  );

  test(
    'remote plugin workspace snapshot motion routes into plugin surfaces',
    () async {
      final result = await harness.runHost(<String>[
        '--snapshot',
        '--snapshot-motion=5,18',
      ]);

      expect(result.exitCode, 0, reason: '${result.stderr}');

      final stdout = result.stdout as String;
      expect(stdout, contains('Hover: 2,1'));
      expect(stdout, contains('motion 5,18'));
      expect(stdout, contains('Alerts'));
    },
    timeout: const Timeout(Duration(seconds: 90)),
  );
}

final class _CompiledWorkspaceHarness {
  _CompiledWorkspaceHarness._({
    required this.tempDirectory,
    required this.hostKernelPath,
    required this.pluginDirectoryPath,
  });

  final io.Directory tempDirectory;
  final String hostKernelPath;
  final String pluginDirectoryPath;

  static Future<_CompiledWorkspaceHarness> create() async {
    final tempDirectory = await io.Directory.systemTemp.createTemp(
      'artisanal-workspace-harness-',
    );
    try {
      final hostSource = _resolveArtisanalPath(<String>[
        'example',
        'tui',
        'remote_plugin_workspace',
        'host',
        'main.dart',
      ]);
      final hostKernelPath = await _kernelCache.ensureKernelSnapshot(
        entrypointPath: hostSource,
        outputPath: p.join(_precompiledWorkspaceDirectory, 'host.dill'),
      );

      final manifestDirectory = io.Directory(
        p.join(tempDirectory.path, 'plugins'),
      );
      await manifestDirectory.create(recursive: true);

      for (final plugin in const <(String, String)>[
        ('activity', 'activity_plugin.dart'),
        ('alerts', 'alerts_plugin.dart'),
        ('overview', 'overview_plugin.dart'),
      ]) {
        final sourcePath = _resolveArtisanalPath(<String>[
          'example',
          'tui',
          'remote_plugin_workspace',
          'plugins',
          plugin.$2,
        ]);
        final outputPath = await _kernelCache.ensureKernelSnapshot(
          entrypointPath: sourcePath,
          outputPath: p.join(
            _precompiledWorkspaceDirectory,
            '${plugin.$1}.dill',
          ),
        );
        final compiledPluginPath = p.join(
          manifestDirectory.path,
          '${plugin.$1}.dill',
        );
        await io.File(outputPath).copy(compiledPluginPath);

        final manifestSource = io.File(
          _resolveArtisanalPath(<String>[
            'example',
            'tui',
            'remote_plugin_workspace',
            'plugins',
            '${plugin.$1}.plugin.json',
          ]),
        );
        final manifestJson =
            jsonDecode(await manifestSource.readAsString())
                as Map<String, Object?>;
        manifestJson['entrypoint'] = p.basename(compiledPluginPath);
        final manifestTarget = io.File(
          p.join(manifestDirectory.path, '${plugin.$1}.plugin.json'),
        );
        await manifestTarget.writeAsString(
          const JsonEncoder.withIndent('  ').convert(manifestJson),
        );
      }

      return _CompiledWorkspaceHarness._(
        tempDirectory: tempDirectory,
        hostKernelPath: hostKernelPath,
        pluginDirectoryPath: manifestDirectory.path,
      );
    } catch (_) {
      await tempDirectory.delete(recursive: true);
      rethrow;
    }
  }

  Future<io.ProcessResult> runHost(List<String> args) {
    return io.Process.run(
      io.Platform.resolvedExecutable,
      <String>[hostKernelPath, ...args],
      workingDirectory: _artisanalRootDirectory,
      environment: <String, String>{
        'ARTISANAL_REMOTE_PLUGIN_WORKSPACE_PLUGIN_DIR': pluginDirectoryPath,
      },
    );
  }

  Future<void> dispose() => tempDirectory.delete(recursive: true);
}

String _resolveArtisanalPath(List<String> relativeSegments) {
  final candidates = <String>[
    p.joinAll(<String>[_artisanalRootDirectory, ...relativeSegments]),
    p.joinAll(<String>[
      _artisanalRootDirectory,
      'pkgs',
      'artisanal',
      ...relativeSegments,
    ]),
  ];
  for (final candidate in candidates) {
    if (io.FileSystemEntity.typeSync(candidate) !=
        io.FileSystemEntityType.notFound) {
      return candidate;
    }
  }
  throw StateError(
    'Could not resolve artisanal path: ${p.joinAll(relativeSegments)}',
  );
}
