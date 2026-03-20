import 'dart:async';
import 'dart:io' as io;

import 'package:artisanal/plugins.dart' as plugins;
import 'package:test/test.dart';

import 'fixture_compiler.dart';

void main() {
  late CompiledPluginFixtures fixtures;

  setUpAll(() async {
    fixtures = await compilePluginFixtures(<String>['echo_plugin.dart']);
  });

  tearDownAll(() async {
    await fixtures.dispose();
  });

  test('process wrapper exchanges typed messages over stdio', () async {
    final plugin = await plugins.RemotePluginProcess.start(
      io.Platform.resolvedExecutable,
      <String>[fixtures.path('echo_plugin.dart')],
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

  test('process wrapper can complete the plugin hello handshake', () async {
    final plugin = await plugins.RemotePluginProcess.start(
      io.Platform.resolvedExecutable,
      <String>[fixtures.path('echo_plugin.dart')],
    );

    addTearDown(() async {
      await plugin.dispose(kill: true);
    });

    final session = await plugin.connect(
      hostHello: const plugins.RemotePluginHostHello(
        hostName: 'artisanal',
        hostVersion: '0.2.0',
      ),
    );
    addTearDown(session.dispose);

    expect(session.pluginHello, isA<plugins.RemotePluginHello>());

    await session.send(const plugins.RemotePluginFocusInput(surfaceId: 'side'));

    final echoed = await session.messages
        .firstWhere((message) => message is plugins.RemotePluginFocusInput)
        .timeout(const Duration(seconds: 2));
    expect(echoed, isA<plugins.RemotePluginFocusInput>());
  });
}
