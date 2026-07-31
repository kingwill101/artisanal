import 'dart:io' as io;

/// Small helper for fixed-path kernel snapshots used by remote plugin tests.
final class RemotePluginKernelCache {
  RemotePluginKernelCache({required this.packageRoot});

  final String packageRoot;

  Future<String> ensureKernelSnapshot({
    required String entrypointPath,
    required String outputPath,
    String? workingDirectory,
  }) async {
    final cachedFile = io.File(outputPath);
    final fingerprintFile = io.File('$outputPath.sdk-fingerprint');
    final fingerprint =
        '${io.Platform.resolvedExecutable}\n${io.Platform.version}';
    if (await cachedFile.exists() &&
        await fingerprintFile.exists() &&
        await fingerprintFile.readAsString() == fingerprint) {
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
    await fingerprintFile.writeAsString(fingerprint, flush: true);

    return outputPath;
  }
}
