import 'dart:async';

import 'package:artisanal/artisanal.dart' as plugins;

import 'support.dart';

const _panelId = 'alerts.panel';
const _popupId = 'alerts.popup';

Future<void> main() async {
  final session = await plugins.RemotePluginGuestSession.bindStdio(
    pluginHello: const plugins.RemotePluginHello(
      pluginId: 'workspace-alerts',
      pluginVersion: '0.1.0',
      displayName: 'Workspace Alerts',
      capabilities: <String>['surfaces'],
    ),
  );

  var ticks = 0;
  var focused = false;
  var hoveredCell = 'none';

  Future<void> publish() async {
    final severity = switch (ticks % 3) {
      0 => 'Info',
      1 => 'Warn',
      _ => 'Watch',
    };
    final accent = switch ((focused, ticks % 3)) {
      (true, _) => '#ef4444',
      (false, 1) => '#f59e0b',
      _ => '#7dd3fc',
    };

    await session.send(
      boxedFrame(
        surfaceId: _panelId,
        width: 30,
        height: 8,
        title: focused ? 'Alerts [focused]' : 'Alerts',
        accent: accent,
        bodyLines: <String>[
          'Severity: $severity',
          'Host: ${session.hostHello.hostName}',
          focused ? 'Popup: armed' : 'Popup: passive',
          'Tick: ${ticks + 1}',
        ],
      ),
    );

    await session.send(
      boxedFrame(
        surfaceId: _popupId,
        width: 20,
        height: 5,
        title: 'Hint',
        accent: accent,
        bodyLines: <String>[
          hoveredCell == 'none' ? 'Hover nearby' : 'Hover: $hoveredCell',
          'Remote popup',
        ],
      ),
    );
  }

  final timer = Timer.periodic(const Duration(seconds: 2), (_) {
    ticks += 1;
    unawaited(publish());
  });

  try {
    await session.send(
      const plugins.RemotePluginSurfaceOpen(
        surfaceId: _panelId,
        kind: plugins.RemotePluginSurfaceKind.panel,
        width: 30,
        height: 8,
        title: 'Alerts',
        slot: 'bottom',
      ),
    );
    await session.send(
      const plugins.RemotePluginSurfaceOpen(
        surfaceId: _popupId,
        kind: plugins.RemotePluginSurfaceKind.popup,
        width: 20,
        height: 5,
        title: 'Hint',
        parentSurfaceId: _panelId,
        anchor: plugins.RemotePluginAnchorRect(
          column: 8,
          row: 1,
          width: 10,
          height: 1,
        ),
      ),
    );
    await publish();

    await for (final message in session.messages) {
      switch (message) {
        case plugins.RemotePluginFocusInput(surfaceId: _panelId):
          focused = true;
          await publish();
        case plugins.RemotePluginBlurInput(surfaceId: _panelId):
          focused = false;
          await publish();
        case plugins.RemotePluginMouseInput(
          surfaceId: _panelId,
          action: plugins.RemotePluginMouseAction.motion,
          :final column,
          :final row,
        ):
          hoveredCell = '$column,$row';
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
