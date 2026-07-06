import 'package:artisanal/artisanal.dart' as plugins;

Future<void> main() async {
  final session = await plugins.RemotePluginGuestSession.bindStdio(
    pluginHello: const plugins.RemotePluginHello(
      pluginId: 'generic-service-plugin',
      pluginVersion: '0.0.1',
      capabilities: <String>['surfaces', 'services'],
    ),
  );

  var status = 'generic:pending';

  Future<void> publish() async {
    await session.send(
      plugins.RemotePluginFrame(
        surfaceId: 'generic.panel',
        width: 36,
        height: 5,
        cells: <plugins.RemotePluginFrameCell>[
          ..._text(0, 0, '┌──────────────────────────────────┐'),
          ..._text(0, 1, '│Generic Service                   │'),
          ..._text(0, 2, '├──────────────────────────────────┤'),
          ..._text(0, 3, '${'│$status'.padRight(35)}│'),
          ..._text(0, 4, '└──────────────────────────────────┘'),
        ],
      ),
    );
  }

  try {
    await session.send(
      const plugins.RemotePluginSurfaceOpen(
        surfaceId: 'generic.panel',
        kind: plugins.RemotePluginSurfaceKind.panel,
        width: 36,
        height: 5,
      ),
    );
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
    await publish();
  } finally {
    await session.dispose();
  }
}

Iterable<plugins.RemotePluginFrameCell> _text(
  int column,
  int row,
  String text,
) sync* {
  for (var index = 0; index < text.length; index++) {
    yield plugins.RemotePluginFrameCell(
      column: column + index,
      row: row,
      symbol: text[index],
    );
  }
}
