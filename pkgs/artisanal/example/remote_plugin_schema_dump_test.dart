import 'dart:convert';
import 'dart:io' as io;

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '_path_utils.dart';

void main() {
  late _CompiledSchemaDumpHarness harness;

  setUpAll(() async {
    harness = await _CompiledSchemaDumpHarness.create();
  });

  tearDownAll(() async {
    await harness.dispose();
  });

  test('remote plugin schema dump prints the top-level protocol schema', () async {
    final result = await harness.run();

    expect(result.exitCode, 0, reason: '${result.stderr}');

    final json = jsonDecode(result.stdout as String) as Map<String, Object?>;
    expect(
      json[r'$id'],
      'https://artisanal.dev/schemas/remote-surface-plugin-message.json',
    );
    expect(json['title'], 'Artisanal Remote Surface Plugin Message');
    expect(json['oneOf'], isA<List<Object?>>());
  });

  test('remote plugin schema dump prints service descriptors with schemas', () async {
    final result = await harness.run(<String>['--built-in-services']);

    expect(result.exitCode, 0, reason: '${result.stderr}');

    final json = jsonDecode(result.stdout as String) as Map<String, Object?>;
    final services = json['services'] as List<Object?>;
    expect(
      services,
      contains(
        allOf(
          isA<Map<Object?, Object?>>(),
          containsPair('service', 'clipboard'),
          containsPair('method', 'read'),
          contains('paramsSchema'),
          contains('resultSchema'),
        ),
      ),
    );
    expect(
      services,
      contains(
        allOf(
          isA<Map<Object?, Object?>>(),
          containsPair('service', 'filePicker'),
          containsPair('method', 'open'),
        ),
      ),
    );
  });
}

final class _CompiledSchemaDumpHarness {
  _CompiledSchemaDumpHarness._({
    required this.tempDirectory,
    required this.kernelPath,
  });

  final io.Directory tempDirectory;
  final String kernelPath;

  static Future<_CompiledSchemaDumpHarness> create() async {
    final tempDirectory = await io.Directory.systemTemp.createTemp(
      'artisanal-schema-dump-',
    );
    try {
      final sourcePath = resolveArtisanalPath(<String>[
        'example',
        'tui',
        'remote_plugin_schema_dump.dart',
      ]);
      final kernelPath = p.join(tempDirectory.path, 'remote_plugin_schema_dump.dill');
      await _compileKernel(sourcePath, kernelPath);
      return _CompiledSchemaDumpHarness._(
        tempDirectory: tempDirectory,
        kernelPath: kernelPath,
      );
    } catch (_) {
      await tempDirectory.delete(recursive: true);
      rethrow;
    }
  }

  Future<io.ProcessResult> run([List<String> args = const <String>[]]) {
    return io.Process.run(
      io.Platform.resolvedExecutable,
      <String>[kernelPath, ...args],
      workingDirectory: io.Directory.current.path,
    );
  }

  Future<void> dispose() => tempDirectory.delete(recursive: true);
}

Future<void> _compileKernel(String sourcePath, String outputPath) async {
  final result = await io.Process.run(io.Platform.resolvedExecutable, <String>[
    'compile',
    'kernel',
    sourcePath,
    '-o',
    outputPath,
  ], workingDirectory: io.Directory.current.path);
  if (result.exitCode != 0) {
    throw StateError(
      'Failed to compile $sourcePath:\n${result.stdout}\n${result.stderr}',
    );
  }
}
