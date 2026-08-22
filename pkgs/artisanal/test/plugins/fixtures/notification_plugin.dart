import 'package:artisanal/artisanal.dart' as plugins;

const _surfaceId = 'notification.panel';

Future<void> main() async {
  final session = await plugins.RemotePluginGuestSession.bindStdio(
    pluginHello: const plugins.RemotePluginHello(
      pluginId: 'notification-plugin',
      pluginVersion: '0.0.1',
      capabilities: <String>['notify'],
    ),
    timeout: const Duration(seconds: 10),
  );

  await session.send(
    const plugins.RemotePluginSurfaceOpen(
      surfaceId: _surfaceId,
      kind: plugins.RemotePluginSurfaceKind.panel,
      width: 32,
      height: 4,
      title: 'Notify',
    ),
  );

  var status = 'notify:pending';
  final services = session.services;

  Future<void> publish() {
    return session.send(
      plugins.RemotePluginFrame(
        surfaceId: _surfaceId,
        width: 32,
        height: 4,
        cells: _cellsForLines(<String>['Notification plugin', status]),
      ),
    );
  }

  await publish();
  try {
    await services.notify(
      'Background task finished',
      title: 'Plugin demo',
      level: plugins.RemotePluginNotificationLevel.success,
    );
    status = 'notify:ok';
  } on plugins.RemotePluginServiceException catch (error) {
    status = 'notify:error:${error.message}';
  }
  await publish();
  // Serve until the host hangs up instead of exiting after the final frame;
  // a self-exit races the host's focus and service replies into dead-stdin
  // errors on Windows.
  await session.messages.drain<void>();
  await session.dispose();
}

List<plugins.RemotePluginFrameCell> _cellsForLines(List<String> lines) {
  final cells = <plugins.RemotePluginFrameCell>[];
  for (var row = 0; row < lines.length; row++) {
    final line = lines[row];
    for (var column = 0; column < line.length; column++) {
      cells.add(
        plugins.RemotePluginFrameCell(
          column: column,
          row: row,
          symbol: line[column],
        ),
      );
    }
  }
  return cells;
}
