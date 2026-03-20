import 'package:artisanal/plugins.dart' as plugins;

const _surfaceId = 'clipboard.panel';

Future<void> main() async {
  final session = await plugins.RemotePluginGuestSession.bindStdio(
    pluginHello: const plugins.RemotePluginHello(
      pluginId: 'clipboard-plugin',
      pluginVersion: '0.0.1',
      capabilities: <String>['clipboard'],
    ),
    timeout: const Duration(seconds: 10),
  );

  await session.send(
    const plugins.RemotePluginSurfaceOpen(
      surfaceId: _surfaceId,
      kind: plugins.RemotePluginSurfaceKind.panel,
      width: 28,
      height: 4,
      title: 'Clipboard',
    ),
  );

  var readStatus = 'read:pending';
  var writeStatus = 'write:pending';

  Future<void> publish() {
    return session.send(
      plugins.RemotePluginFrame(
        surfaceId: _surfaceId,
        width: 28,
        height: 4,
        cells: _cellsForLines(<String>[
          'Clipboard plugin',
          readStatus,
          writeStatus,
        ]),
      ),
    );
  }

  await publish();
  await session.send(
    const plugins.RemotePluginClipboardReadRequest(requestId: 'read-1'),
  );

  await for (final message in session.messages) {
    switch (message) {
      case plugins.RemotePluginClipboardReadResponse(
        requestId: 'read-1',
        :final text,
        :final error,
      ):
        readStatus = error != null ? 'read:error' : 'read:${text ?? ''}';
        await publish();
        await session.send(
          const plugins.RemotePluginClipboardWriteRequest(
            requestId: 'write-1',
            text: 'plugin-copy',
          ),
        );
      case plugins.RemotePluginClipboardWriteResponse(
        requestId: 'write-1',
        :final accepted,
        :final error,
      ):
        writeStatus = accepted && error == null ? 'write:ok' : 'write:error';
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
