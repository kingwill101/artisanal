import 'dart:io' as io;

import 'package:artisanal/plugins.dart' as plugins;
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('host connection starts a plugin process and forwards other messages', () async {
    final scriptPath = p.join(
      io.Directory.current.path,
      'pkgs',
      'artisanal',
      'test',
      'plugins',
      'fixtures',
      'echo_plugin.dart',
    );

    final connection = await plugins.RemotePluginHostConnection.startProcess(
      io.Platform.resolvedExecutable,
      <String>[scriptPath],
      hostHello: const plugins.RemotePluginHostHello(
        hostName: 'artisanal',
        hostVersion: '0.2.0',
      ),
      timeout: const Duration(seconds: 10),
    );
    addTearDown(() => connection.dispose(kill: true));

    expect(connection.pluginHello.pluginId, 'echo-plugin');
    expect(connection.surfaces.surfaces, isEmpty);

    await connection.send(
      const plugins.RemotePluginFocusInput(surfaceId: 'side'),
    );

    final echoed = await connection.otherMessages
        .firstWhere((message) => message is plugins.RemotePluginFocusInput)
        .timeout(const Duration(seconds: 2));
    expect(echoed, isA<plugins.RemotePluginFocusInput>());
  });
}
