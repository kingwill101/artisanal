import 'dart:io' as io;

import 'package:path/path.dart' as p;

import '_path_utils.dart';

final class CompiledRemotePluginDemoHarness {
  CompiledRemotePluginDemoHarness._({
    required this.tempDirectory,
    required this.hostKernelPath,
    required this.guestKernelPath,
  });

  final io.Directory tempDirectory;
  final String hostKernelPath;
  final String guestKernelPath;

  static Future<CompiledRemotePluginDemoHarness> create({
    required List<String> hostRelativePath,
    required List<String> guestRelativePath,
    required String hostKernelName,
    required String guestKernelName,
  }) async {
    final tempDirectory = await io.Directory.systemTemp.createTemp(
      'artisanal-remote-plugin-demo-',
    );
    try {
      final hostSourcePath = resolveArtisanalPath(hostRelativePath);
      final guestSourcePath = resolveArtisanalPath(guestRelativePath);
      final hostKernelPath = p.join(tempDirectory.path, hostKernelName);
      final guestKernelPath = p.join(tempDirectory.path, guestKernelName);
      await _compileKernel(hostSourcePath, hostKernelPath);
      await _compileKernel(guestSourcePath, guestKernelPath);
      return CompiledRemotePluginDemoHarness._(
        tempDirectory: tempDirectory,
        hostKernelPath: hostKernelPath,
        guestKernelPath: guestKernelPath,
      );
    } catch (_) {
      await tempDirectory.delete(recursive: true);
      rethrow;
    }
  }

  Future<io.ProcessResult> runHost([List<String> args = const <String>[]]) {
    return io.Process.run(
      io.Platform.resolvedExecutable,
      <String>[hostKernelPath, '--plugin', guestKernelPath, ...args],
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
