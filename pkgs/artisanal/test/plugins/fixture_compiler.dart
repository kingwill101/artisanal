import 'dart:io' as io;

import 'package:artisanal/src/plugins/remote_plugin_kernel_cache.dart';
import 'package:path/path.dart' as p;

final String _artisanalRootDirectory = io.Directory.current.path;
final _kernelCache = RemotePluginKernelCache(
  packageRoot: _artisanalRootDirectory,
);
final String _precompiledFixturesDirectory = p.join(
  _artisanalRootDirectory,
  '.dart_tool',
  'artisanal',
  'precompiled-plugins',
  'test-fixtures',
);

final class CompiledPluginFixtures {
  CompiledPluginFixtures._(this._compiledPaths);

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

  Future<void> dispose() async {}
}

Future<CompiledPluginFixtures> compilePluginFixtures(
  Iterable<String> fixtureFileNames,
) async {
  final compiledPaths = <String, String>{};
  for (final fixtureFileName in fixtureFileNames.toSet()) {
    final sourcePath = _resolveArtisanalPath(<String>[
      'test',
      'plugins',
      'fixtures',
      fixtureFileName,
    ]);
    compiledPaths[fixtureFileName] = await _kernelCache.ensureKernelSnapshot(
      entrypointPath: sourcePath,
      outputPath: p.join(
        _precompiledFixturesDirectory,
        '${p.basenameWithoutExtension(fixtureFileName)}.dill',
      ),
    );
  }
  return CompiledPluginFixtures._(compiledPaths);
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
