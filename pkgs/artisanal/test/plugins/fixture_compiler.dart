import 'dart:io' as io;

import 'package:artisanal/src/plugins/remote_plugin_kernel_cache.dart';
import 'package:path/path.dart' as p;

final String _artisanalRootDirectory = _resolveArtisanalPackageRoot();
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
    final sourcePath = p.join(
      _artisanalRootDirectory,
      'test',
      'plugins',
      'fixtures',
      fixtureFileName,
    );
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

String _resolveArtisanalPackageRoot() {
  final current = io.Directory.current.path;
  final candidates = <String>[current, p.join(current, 'pkgs', 'artisanal')];
  for (final candidate in candidates) {
    final packageFile = p.join(candidate, 'pubspec.yaml');
    final fixtureDirectory = p.join(candidate, 'test', 'plugins', 'fixtures');
    if (io.File(packageFile).existsSync() &&
        io.Directory(fixtureDirectory).existsSync()) {
      return candidate;
    }
  }
  throw StateError(
    'Could not resolve the artisanal package root from $current.',
  );
}
