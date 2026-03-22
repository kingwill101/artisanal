import 'dart:async';

import 'package:artisanal/plugins.dart' as plugins;

const _panelId = 'demo.panel';
const _popupId = 'demo.popup';

Future<void> main() async {
  final session = await plugins.RemotePluginGuestSession.bindStdio(
    pluginHello: const plugins.RemotePluginHello(
      pluginId: 'remote-popup-demo',
      pluginVersion: '0.1.0',
      displayName: 'Remote Popup Demo',
      capabilities: <String>['surfaces'],
    ),
  );

  try {
    await session.send(
      const plugins.RemotePluginSurfaceOpen(
        surfaceId: _panelId,
        kind: plugins.RemotePluginSurfaceKind.panel,
        width: 24,
        height: 5,
        title: 'Popup Demo',
        slot: 'main',
      ),
    );
    await session.send(
      const plugins.RemotePluginSurfaceOpen(
        surfaceId: _popupId,
        kind: plugins.RemotePluginSurfaceKind.popup,
        width: 14,
        height: 3,
        title: 'Hint',
        parentSurfaceId: _panelId,
        anchor: plugins.RemotePluginAnchorRect(
          column: 7,
          row: 1,
          width: 8,
          height: 1,
        ),
      ),
    );
    await session.send(
      _frame(
        surfaceId: _panelId,
        width: 24,
        height: 5,
        lines: <String>[
          'Remote Popup Demo',
          'Host: ${session.hostHello.hostName}',
          'State: ready',
        ],
      ),
    );
    await session.send(
      _frame(
        surfaceId: _popupId,
        width: 14,
        height: 3,
        lines: const <String>['Hint', 'Waiting...'],
        accent: '#f59e0b',
      ),
    );

    await for (final message in session.messages) {
      switch (message) {
        case plugins.RemotePluginFocusInput(surfaceId: _panelId):
          await session.send(
            _frame(
              surfaceId: _panelId,
              width: 24,
              height: 5,
              lines: <String>[
                'Remote Popup Demo',
                'Host: ${session.hostHello.hostName}',
                'State: focused',
              ],
            ),
          );
          await session.send(
            _frame(
              surfaceId: _popupId,
              width: 14,
              height: 3,
              lines: const <String>['Hint', 'Focused popup'],
              accent: '#22c55e',
            ),
          );
          return;
        default:
          continue;
      }
    }
  } finally {
    await session.dispose();
  }
}

plugins.RemotePluginFrame _frame({
  required String surfaceId,
  required int width,
  required int height,
  required List<String> lines,
  String? accent,
}) {
  final cells = <plugins.RemotePluginFrameCell>[];
  for (var row = 0; row < lines.length && row < height; row++) {
    final line = lines[row];
    for (var column = 0; column < line.length && column < width; column++) {
      cells.add(
        plugins.RemotePluginFrameCell(
          column: column,
          row: row,
          symbol: line[column],
          foreground: row == 0 ? accent ?? '#7dd3fc' : null,
        ),
      );
    }
  }

  return plugins.RemotePluginFrame(
    surfaceId: surfaceId,
    width: width,
    height: height,
    cells: cells,
  );
}
