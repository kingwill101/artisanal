import 'dart:io' as io;

import 'package:path/path.dart' as p;

/// Small helper for fixed-path kernel snapshots used by remote plugin tests.
final class RemotePluginKernelCache {
  RemotePluginKernelCache({
    required this.packageRoot,
  });

  final String packageRoot;

  Future<String> ensureKernelSnapshot({
    required String entrypointPath,
    required String outputPath,
    String? workingDirectory,
  }) async {
    final cachedFile = io.File(outputPath);
    if (await cachedFile.exists()) {
      return outputPath;
    }

    await cachedFile.parent.create(recursive: true);
    final result = await io.Process.run(
      io.Platform.resolvedExecutable,
      <String>['compile', 'kernel', entrypointPath, '-o', outputPath],
      workingDirectory: workingDirectory ?? packageRoot,
    );
    if (result.exitCode != 0) {
      throw StateError(
        'Failed to compile $entrypointPath:\n${result.stdout}\n${result.stderr}',
      );
    }

    return outputPath;
  }
}
