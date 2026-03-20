import 'dart:async';
import 'dart:io' as io;

import 'package:artisanal/plugins.dart' as plugins;
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('process wrapper exchanges typed messages over stdio', () async {
    final scriptPath = p.join(
      io.Directory.current.path,
      'pkgs',
      'artisanal',
      'test',
      'plugins',
      'fixtures',
      'echo_plugin.dart',
    );

    final plugin = await plugins.RemotePluginProcess.start(
      io.Platform.resolvedExecutable,
      <String>[scriptPath],
    );

    addTearDown(() async {
      await plugin.dispose(kill: true);
    });

    final iterator = StreamIterator(plugin.messages);
    addTearDown(iterator.cancel);

    final sawHello = await iterator.moveNext().timeout(
      const Duration(seconds: 2),
    );
    expect(sawHello, isTrue);
    final hello = iterator.current;
    expect(hello, isA<plugins.RemotePluginHello>());

    await plugin.send(const plugins.RemotePluginFocusInput(surfaceId: 'side'));

    final sawEcho = await iterator.moveNext().timeout(
      const Duration(seconds: 2),
    );
    expect(sawEcho, isTrue);
    final echoed = iterator.current;
    expect(echoed, isA<plugins.RemotePluginFocusInput>());
  });
}
