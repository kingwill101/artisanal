import 'dart:io' as io;

import 'package:test/test.dart';

import '_path_utils.dart';

void main() {
  test('remote plugin host demo renders the guest surface', () async {
    final result = await io.Process.run(
      io.Platform.resolvedExecutable,
      <String>[
        'run',
        resolveArtisanalPath(<String>[
          'example',
          'tui',
          'remote_plugin_host_demo.dart',
        ]),
      ],
      workingDirectory: io.Directory.current.path,
    );

    expect(result.exitCode, 0, reason: '${result.stderr}');

    final stdout = result.stdout as String;
    expect(stdout, contains('Connected plugin: remote-surface-demo 0.1.0'));
    expect(stdout, contains('Surface demo.panel (panel, 28x5)'));
    expect(stdout, contains('Remote Plugin Demo'));
    expect(stdout, contains('Host: artisanal'));
    expect(stdout, contains('State: focused'));
  });
}
