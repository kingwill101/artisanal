import 'dart:io' as io;

import 'package:test/test.dart';

void main() {
  test(
    'remote plugin workspace snapshot renders all example plugins',
    () async {
      final result = await io.Process.run(
        io.Platform.resolvedExecutable,
        <String>[
          'pkgs/artisanal/example/tui/remote_plugin_workspace/host/main.dart',
          '--snapshot',
        ],
        workingDirectory: io.Directory.current.path,
      );

      expect(result.exitCode, 0, reason: '${result.stderr}');

      final stdout = result.stdout as String;
      expect(stdout, contains('Remote Plugin Workspace'));
      expect(stdout, contains('Overview'));
      expect(stdout, contains('Activity'));
      expect(stdout, contains('Alerts'));
      expect(stdout, contains('Hint'));
    },
    timeout: const Timeout(Duration(seconds: 90)),
  );

  test(
    'remote plugin workspace snapshot click focuses the clicked plugin',
    () async {
      final result = await io.Process.run(
        io.Platform.resolvedExecutable,
        <String>[
          'pkgs/artisanal/example/tui/remote_plugin_workspace/host/main.dart',
          '--snapshot',
          '--snapshot-click=37,6',
        ],
        workingDirectory: io.Directory.current.path,
      );

      expect(result.exitCode, 0, reason: '${result.stderr}');

      final stdout = result.stdout as String;
      expect(stdout, contains('Selected: activity'));
      expect(stdout, contains('Activity [focused]'));
      expect(stdout, contains('click 37,6'));
    },
    timeout: const Timeout(Duration(seconds: 90)),
  );

  test(
    'remote plugin workspace snapshot key routes into the focused plugin',
    () async {
      final result = await io.Process.run(
        io.Platform.resolvedExecutable,
        <String>[
          'pkgs/artisanal/example/tui/remote_plugin_workspace/host/main.dart',
          '--snapshot',
          '--snapshot-click=37,6',
          '--snapshot-key=a',
        ],
        workingDirectory: io.Directory.current.path,
      );

      expect(result.exitCode, 0, reason: '${result.stderr}');

      final stdout = result.stdout as String;
      expect(stdout, contains('Selected: activity'));
      expect(stdout, contains('Activity [focused]'));
      expect(stdout, contains('Last key: a'));
      expect(stdout, contains('key a'));
    },
    timeout: const Timeout(Duration(seconds: 90)),
  );
}
