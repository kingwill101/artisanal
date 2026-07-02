import 'dart:io' as io;

import 'package:path/path.dart' as p;

final String _artisanalRootDirectory = io.Directory.current.path;

final class CompiledPluginFixtures {
  CompiledPluginFixtures._(this._tempDirectory, this._compiledPaths);

  final io.Directory _tempDirectory;
  final Map<String, String> _compiledPaths;

  String path(String fixtureFileName) {
    final compiledPath = _compiledPaths[fixtureFileName];
    if (compiledPath == null) {
      throw ArgumentError.value(
        fixtureFileName,
        'fixtureFileName',
        'Fixture was not compiled.',
      );
    }
    return compiledPath;
  }

  Future<void> dispose() => _tempDirectory.delete(recursive: true);
}

Future<CompiledPluginFixtures> compilePluginFixtures(
  Iterable<String> fixtureFileNames,
) async {
  final tempDirectory = await io.Directory.systemTemp.createTemp(
    'artisanal-plugin-fixtures-',
  );
  final compiledPaths = <String, String>{};
  try {
    for (final fixtureFileName in fixtureFileNames.toSet()) {
      final sourcePath = _resolveArtisanalPath(<String>[
        'test',
        'plugins',
        'fixtures',
        fixtureFileName,
      ]);
      final outputPath = p.join(
        tempDirectory.path,
        '${p.basenameWithoutExtension(fixtureFileName)}.dill',
      );
      final result = await io.Process.run(
        io.Platform.resolvedExecutable,
        <String>['compile', 'kernel', sourcePath, '-o', outputPath],
        workingDirectory: _artisanalRootDirectory,
      );
      if (result.exitCode != 0) {
        throw StateError(
          'Failed to compile fixture $fixtureFileName:\n'
          '${result.stdout}\n${result.stderr}',
        );
      }
      compiledPaths[fixtureFileName] = outputPath;
    }
    return CompiledPluginFixtures._(tempDirectory, compiledPaths);
  } catch (_) {
    await tempDirectory.delete(recursive: true);
    rethrow;
  }
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
