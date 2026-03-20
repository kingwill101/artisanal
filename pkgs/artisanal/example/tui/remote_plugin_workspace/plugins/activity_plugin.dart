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
  var clipboardStatus = 'unread';
  var urlStatus = 'idle';
  var noticeStatus = 'idle';

  Future<void> publish() async {
    final current = _messages[ticks % _messages.length];
    await session.send(
      boxedFrame(
        surfaceId: _surfaceId,
        width: 42,
        height: 11,
        title: focused ? 'Activity [focused]' : 'Activity',
        accent: focused ? '#f59e0b' : '#38bdf8',
        bodyLines: <String>[
          'Current: $current',
          'Heartbeat: ${ticks + 1}',
          focused ? 'Input: active routing' : 'Input: passive',
          'Last key: $lastKey',
          'Clipboard: $clipboardStatus',
          'URL: $urlStatus',
          'Notice: $noticeStatus',
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
          if (!ctrl && !alt && !shift && !meta && key == 'c') {
            try {
              clipboardStatus = await session.services.readClipboard();
            } on plugins.RemotePluginServiceException catch (error) {
              clipboardStatus = error.message;
            }
          } else if (!ctrl && !alt && !shift && !meta && key == 'o') {
            try {
              await session.services.openUrl('https://example.com/workspace');
              urlStatus = 'opened';
            } on plugins.RemotePluginServiceException catch (error) {
              urlStatus = error.message;
            }
          } else if (!ctrl && !alt && !shift && !meta && key == 'n') {
            try {
              await session.services.notify(
                'Activity pinged host',
                title: 'Workspace Activity',
                level: plugins.RemotePluginNotificationLevel.info,
              );
              noticeStatus = 'sent';
            } on plugins.RemotePluginServiceException catch (error) {
              noticeStatus = error.message;
            }
          }
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
