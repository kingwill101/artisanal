import 'dart:async';

import 'package:artisanal/plugins.dart' as plugins;

const _surfaceId = 'demo.panel';

Future<void> main() async {
  final session = await plugins.RemotePluginGuestSession.bindStdio(
    pluginHello: const plugins.RemotePluginHello(
      pluginId: 'remote-surface-demo',
      pluginVersion: '0.1.0',
      displayName: 'Remote Surface Demo',
      capabilities: <String>['surfaces'],
    ),
  );

  try {
    await session.send(
      const plugins.RemotePluginSurfaceOpen(
        surfaceId: _surfaceId,
        kind: plugins.RemotePluginSurfaceKind.panel,
        width: 28,
        height: 5,
        title: 'Demo Panel',
        slot: 'main',
      ),
    );
    await session.send(
      _frame(hostName: session.hostHello.hostName, status: 'ready'),
    );

    await for (final message in session.messages) {
      switch (message) {
        case plugins.RemotePluginFocusInput(surfaceId: _surfaceId):
          await session.send(
            _frame(hostName: session.hostHello.hostName, status: 'focused'),
          );
          return;
        case plugins.RemotePluginBlurInput(surfaceId: _surfaceId):
          await session.send(
            _frame(hostName: session.hostHello.hostName, status: 'blurred'),
          );
        default:
          continue;
      }
    }
  } finally {
    await session.dispose();
  }
}

plugins.RemotePluginFrame _frame({
  required String hostName,
  required String status,
}) {
  const width = 28;
  const height = 5;
  final lines = <String>[
    'Remote Plugin Demo',
    'Host: $hostName',
    'State: $status',
    'Surface: $_surfaceId',
  ];

  final cells = <plugins.RemotePluginFrameCell>[];
  for (var row = 0; row < lines.length; row++) {
    final line = lines[row];
    for (var column = 0; column < line.length && column < width; column++) {
      cells.add(
        plugins.RemotePluginFrameCell(
          column: column,
          row: row,
          symbol: line[column],
          foreground: row == 0 ? '#7dd3fc' : null,
        ),
      );
    }
  }

  return plugins.RemotePluginFrame(
    surfaceId: _surfaceId,
    width: width,
    height: height,
    cells: cells,
    cursor: const plugins.RemotePluginCursor(column: 7, row: 2),
  );
}
