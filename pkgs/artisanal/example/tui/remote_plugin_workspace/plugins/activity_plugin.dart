import 'dart:async';

import 'package:artisanal/plugins.dart' as plugins;

import 'support.dart';

const _surfaceId = 'activity.panel';
const _messages = <String>[
  'Watching surface lifecycle',
  'Forwarding frame updates',
  'Binding host connection',
  'Tracking plugin heartbeats',
];

Future<void> main() async {
  final session = await plugins.RemotePluginGuestSession.bindStdio(
    pluginHello: const plugins.RemotePluginHello(
      pluginId: 'workspace-activity',
      pluginVersion: '0.1.0',
      displayName: 'Workspace Activity',
      capabilities: <String>['surfaces'],
    ),
  );

  var ticks = 0;
  var focused = false;
  var lastKey = 'none';

  Future<void> publish() async {
    final current = _messages[ticks % _messages.length];
    await session.send(
      boxedFrame(
        surfaceId: _surfaceId,
        width: 42,
        height: 9,
        title: focused ? 'Activity [focused]' : 'Activity',
        accent: focused ? '#f59e0b' : '#38bdf8',
        bodyLines: <String>[
          'Current: $current',
          'Heartbeat: ${ticks + 1}',
          focused ? 'Input: active routing' : 'Input: passive',
          'Last key: $lastKey',
          'Plugin: workspace-activity',
        ],
      ),
    );
  }

  final timer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
    ticks += 1;
    unawaited(publish());
  });

  try {
    await session.send(
      const plugins.RemotePluginSurfaceOpen(
        surfaceId: _surfaceId,
        kind: plugins.RemotePluginSurfaceKind.panel,
        width: 42,
        height: 9,
        title: 'Activity',
        slot: 'main',
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
        case plugins.RemotePluginKeyInput(
          surfaceId: _surfaceId,
          :final key,
          :final ctrl,
          :final alt,
          :final shift,
          :final meta,
        ):
          lastKey = _formatKey(
            key,
            ctrl: ctrl,
            alt: alt,
            shift: shift,
            meta: meta,
          );
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

String _formatKey(
  String key, {
  required bool ctrl,
  required bool alt,
  required bool shift,
  required bool meta,
}) {
  final modifiers = <String>[
    if (ctrl) 'Ctrl',
    if (alt) 'Alt',
    if (shift) 'Shift',
    if (meta) 'Meta',
  ];
  if (modifiers.isEmpty) {
    return key;
  }
  return '${modifiers.join('+')}+$key';
}
