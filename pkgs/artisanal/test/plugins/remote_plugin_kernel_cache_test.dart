import 'dart:io' as io;

import 'package:artisanal/src/plugins/remote_plugin_kernel_cache.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late io.Directory tempDirectory;
  late RemotePluginKernelCache cache;

  setUp(() async {
    tempDirectory = await io.Directory.systemTemp.createTemp(
      'artisanal-kernel-cache-',
    );
    cache = RemotePluginKernelCache(packageRoot: tempDirectory.path);
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('kernel snapshot recompiles when its source changes', () async {
    final entrypoint = io.File(p.join(tempDirectory.path, 'plugin.dart'));
    Future<String> runSnapshot() async {
      final output = p.join(tempDirectory.path, 'plugin.dill');
      final result = await io.Process.run(io.Platform.resolvedExecutable, [
        output,
      ]);
      return '${result.stdout}'.trim();
    }

    Future<String> ensure() => cache.ensureKernelSnapshot(
      entrypointPath: entrypoint.path,
      outputPath: p.join(tempDirectory.path, 'plugin.dill'),
    );

    await entrypoint.writeAsString("void main() { print('v1'); }\n");
    await ensure();
    expect(await runSnapshot(), 'v1');

    // A later mtime plus a different size defeats same-tick filesystems.
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await entrypoint.writeAsString("void main() { print('v22'); }\n");
    await ensure();
    expect(await runSnapshot(), 'v22');
  });
}
