import 'package:artisanal/plugins.dart' as plugins;

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

  Future<void> publish() {
    return session.send(
      plugins.RemotePluginFrame(
        surfaceId: _surfaceId,
        width: 32,
        height: 4,
        cells: _cellsForLines(<String>[
          'Notification plugin',
          status,
        ]),
      ),
    );
  }

  await publish();
  await session.send(
    const plugins.RemotePluginNotificationRequest(
      requestId: 'notify-1',
      title: 'Plugin demo',
      message: 'Background task finished',
      level: plugins.RemotePluginNotificationLevel.success,
    ),
  );

  await for (final message in session.messages) {
    switch (message) {
      case plugins.RemotePluginNotificationResponse(
        requestId: 'notify-1',
        :final accepted,
        :final error,
      ):
        status =
            accepted && error == null
                ? 'notify:ok'
                : 'notify:error:${error ?? ""}';
        await publish();
        await session.dispose();
        return;
      default:
        break;
    }
  }
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
