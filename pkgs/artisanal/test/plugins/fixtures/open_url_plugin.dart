import 'package:artisanal/plugins.dart' as plugins;

const _surfaceId = 'url.panel';

Future<void> main() async {
  final session = await plugins.RemotePluginGuestSession.bindStdio(
    pluginHello: const plugins.RemotePluginHello(
      pluginId: 'url-plugin',
      pluginVersion: '0.0.1',
      capabilities: <String>['open-url'],
    ),
    timeout: const Duration(seconds: 10),
  );

  await session.send(
    const plugins.RemotePluginSurfaceOpen(
      surfaceId: _surfaceId,
      kind: plugins.RemotePluginSurfaceKind.panel,
      width: 30,
      height: 4,
      title: 'Open URL',
    ),
  );

  var status = 'url:pending';

  Future<void> publish() {
    return session.send(
      plugins.RemotePluginFrame(
        surfaceId: _surfaceId,
        width: 30,
        height: 4,
        cells: _cellsForLines(<String>[
          'Open URL plugin',
          status,
        ]),
      ),
    );
  }

  await publish();
  await session.send(
    const plugins.RemotePluginOpenUrlRequest(
      requestId: 'url-1',
      url: 'https://example.com/plugin',
    ),
  );

  await for (final message in session.messages) {
    switch (message) {
      case plugins.RemotePluginOpenUrlResponse(
        requestId: 'url-1',
        :final accepted,
        :final error,
      ):
        status =
            accepted && error == null ? 'url:ok' : 'url:error:${error ?? ""}';
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
