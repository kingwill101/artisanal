import 'dart:async';

import 'package:artisanal/artisanal.dart' as plugins;

const _surfaceId = 'generic.panel';
const _width = 38;
const _height = 6;

Future<void> main() async {
  final session = await plugins.RemotePluginGuestSession.bindStdio(
    pluginHello: const plugins.RemotePluginHello(
      pluginId: 'remote-generic-service-demo',
      pluginVersion: '0.1.0',
      displayName: 'Remote Generic Service Demo',
      capabilities: <String>['surfaces', 'services'],
    ),
  );

  var status = 'generic:pending';
  try {
    await session.send(
      const plugins.RemotePluginSurfaceOpen(
        surfaceId: _surfaceId,
        kind: plugins.RemotePluginSurfaceKind.panel,
        width: _width,
        height: _height,
        title: 'Generic Service Panel',
        slot: 'main',
      ),
    );
    await _publish(session, status);

    try {
      final result = await session.services.call(
        'host',
        'ping',
        params: const <String, Object?>{'value': 'demo'},
      );
      status = 'generic:${result['reply']}';
    } on plugins.RemotePluginServiceException catch (error) {
      status = 'generic:error:${error.message}';
    }
    await _publish(session, status);
  } finally {
    await session.dispose();
  }
}

Future<void> _publish(plugins.RemotePluginGuestSession session, String status) {
  final lines = <String>[
    'Generic Service Demo',
    'Host: ${session.hostHello.hostName}',
    'Call: host.ping(value="demo")',
    'State: $status',
    'Supports host.ping: ${session.services.supports('host', 'ping')}',
  ];
  final cells = <plugins.RemotePluginFrameCell>[];
  for (var row = 0; row < lines.length; row++) {
    final line = lines[row];
    for (var column = 0; column < line.length && column < _width; column++) {
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

  return session.send(
    plugins.RemotePluginFrame(
      surfaceId: _surfaceId,
      width: _width,
      height: _height,
      cells: cells,
      cursor: const plugins.RemotePluginCursor(column: 7, row: 3),
    ),
  );
}
