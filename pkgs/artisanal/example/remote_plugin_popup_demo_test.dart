import 'dart:io' as io;

import 'package:test/test.dart';

import '_path_utils.dart';

void main() {
  test('remote plugin popup host demo renders anchored child surfaces', () async {
    final result = await io.Process.run(
      io.Platform.resolvedExecutable,
      <String>[
        'run',
        resolveArtisanalPath(<String>[
          'example',
          'tui',
          'remote_plugin_popup_host_demo.dart',
        ]),
      ],
      workingDirectory: io.Directory.current.path,
    );

    expect(result.exitCode, 0, reason: '${result.stderr}');

    final stdout = result.stdout as String;
    expect(stdout, contains('Connected plugin: remote-popup-demo 0.1.0'));
    expect(stdout, contains('Open surfaces: demo.panel, demo.popup'));
    expect(stdout, contains('Remote Popup Demo'));
    expect(stdout, contains('Focused popup'));
  });
}
