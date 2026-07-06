import 'package:artisanal/artisanal.dart' as plugins;

const _surfaceId = 'picker.panel';

Future<void> main() async {
  final session = await plugins.RemotePluginGuestSession.bindStdio(
    pluginHello: const plugins.RemotePluginHello(
      pluginId: 'file-picker-plugin',
      pluginVersion: '0.0.1',
      capabilities: <String>['file-picker'],
    ),
    timeout: const Duration(seconds: 10),
  );

  await session.send(
    const plugins.RemotePluginSurfaceOpen(
      surfaceId: _surfaceId,
      kind: plugins.RemotePluginSurfaceKind.panel,
      width: 34,
      height: 4,
      title: 'Pick File',
    ),
  );

  var status = 'pick:pending';
  final services = session.services;

  Future<void> publish() {
    return session.send(
      plugins.RemotePluginFrame(
        surfaceId: _surfaceId,
        width: 34,
        height: 4,
        cells: _cellsForLines(<String>['File picker plugin', status]),
      ),
    );
  }

  await publish();
  try {
    final paths = await services.pickPaths(
      title: 'Select a demo file',
      initialPath: '/tmp',
    );
    status = paths.isEmpty ? 'pick:none' : 'pick:${paths.first}';
  } on plugins.RemotePluginServiceException catch (error) {
    status = 'pick:error:${error.message}';
  }
  await publish();
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
