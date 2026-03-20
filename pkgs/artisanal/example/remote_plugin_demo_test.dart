import 'package:test/test.dart';

import '_compiled_remote_plugin_demo_harness.dart';

void main() {
  late CompiledRemotePluginDemoHarness harness;

  setUpAll(() async {
    harness = await CompiledRemotePluginDemoHarness.create(
      hostRelativePath: <String>[
        'example',
        'tui',
        'remote_plugin_host_demo.dart',
      ],
      guestRelativePath: <String>[
        'example',
        'tui',
        'remote_plugin_guest_demo.dart',
      ],
      hostKernelName: 'remote_plugin_host_demo.dill',
      guestKernelName: 'remote_plugin_guest_demo.dill',
    );
  });

  tearDownAll(() async {
    await harness.dispose();
  });

  test('remote plugin host demo renders the guest surface', () async {
    final result = await harness.runHost();

    expect(result.exitCode, 0, reason: '${result.stderr}');

    final stdout = result.stdout as String;
    expect(stdout, contains('Connected plugin: remote-surface-demo 0.1.0'));
    expect(stdout, contains('Surface demo.panel (panel, 28x5)'));
    expect(stdout, contains('Remote Plugin Demo'));
    expect(stdout, contains('Host: artisanal'));
    expect(stdout, contains('State: focused'));
  });
}
