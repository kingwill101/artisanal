import 'dart:async';

import 'package:artisanal/artisanal.dart' as plugins;

import 'support.dart';

const _surfaceId = 'overview.panel';

Future<void> main() async {
  final session = await plugins.RemotePluginGuestSession.bindStdio(
    pluginHello: const plugins.RemotePluginHello(
      pluginId: 'workspace-overview',
      pluginVersion: '0.1.0',
      displayName: 'Workspace Overview',
      capabilities: <String>['surfaces'],
    ),
  );

  var ticks = 0;
  var focused = false;

  Future<void> publish() async {
    await session.send(
      boxedFrame(
        surfaceId: _surfaceId,
        width: 30,
        height: 9,
        title: focused ? 'Overview [focused]' : 'Overview',
        accent: focused ? '#22c55e' : '#7dd3fc',
        bodyLines: <String>[
          'Host: ${session.hostHello.hostName}',
          'Protocol: remote surfaces',
          'Ticks: $ticks',
          focused ? 'State: selected' : 'State: idle',
          'Plugin: workspace-overview',
        ],
      ),
    );
  }

  final timer = Timer.periodic(const Duration(seconds: 1), (_) {
    ticks += 1;
    unawaited(publish());
  });

  try {
    await session.send(
      const plugins.RemotePluginSurfaceOpen(
        surfaceId: _surfaceId,
        kind: plugins.RemotePluginSurfaceKind.panel,
        width: 30,
        height: 9,
        title: 'Overview',
        slot: 'left',
      ),
    );
    await publish();

    await for (final message in session.messages) {
      switch (message) {
        case plugins.RemotePluginFocusInput(surfaceId: _surfaceId):
          focused = true;
          await publish();
        case plugins.RemotePluginBlurInput(surfaceId: _surfaceId):
          focused = false;
          await publish();
        default:
          continue;
      }
    }
  } finally {
    timer.cancel();
    await session.dispose();
  }
}
