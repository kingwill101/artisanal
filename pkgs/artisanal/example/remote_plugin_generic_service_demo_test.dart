import 'package:test/test.dart';

import '_compiled_remote_plugin_demo_harness.dart';

void main() {
  late CompiledRemotePluginDemoHarness harness;

  setUpAll(() async {
    harness = await CompiledRemotePluginDemoHarness.create(
      hostRelativePath: <String>[
        'example',
        'tui',
        'remote_plugin_generic_service_host_demo.dart',
      ],
      guestRelativePath: <String>[
        'example',
        'tui',
        'remote_plugin_generic_service_guest_demo.dart',
      ],
      hostKernelName: 'remote_plugin_generic_service_host_demo.dill',
      guestKernelName: 'remote_plugin_generic_service_guest_demo.dill',
    );
  });

  tearDownAll(() async {
    await harness.dispose();
  });

  test('remote generic service demo renders the ping response', () async {
    final result = await harness.runHost();

    expect(result.exitCode, 0, reason: '${result.stderr}');

    final stdout = result.stdout as String;
    expect(
      stdout,
      contains('Connected plugin: remote-generic-service-demo 0.1.0'),
    );
    expect(stdout, contains('Generic service: host.ping'));
    expect(stdout, contains('Surface generic.panel (panel, 38x6)'));
    expect(stdout, contains('Generic Service Demo'));
    expect(stdout, contains('Call: host.ping(value="demo")'));
    expect(stdout, contains('State: generic:pong demo'));
    expect(stdout, contains('Supports host.ping: true'));
  });
}
