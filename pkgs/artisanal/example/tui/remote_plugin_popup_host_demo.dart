// tui:allow-stdout
import 'dart:async';
import 'dart:io' as io;

import 'package:artisanal/artisanal.dart' as plugins;
import 'package:artisanal/uv.dart' as uv;

import '../_path_utils.dart';

const _panelId = 'demo.panel';
const _connectTimeout = Duration(seconds: 15);

Future<void> main(List<String> args) async {
  final pluginPath = _parsePluginPath(args);
  final connection = await plugins.RemotePluginHostConnection.startProcess(
    io.Platform.resolvedExecutable,
    <String>[pluginPath],
    hostHello: const plugins.RemotePluginHostHello(
      hostName: 'artisanal',
      hostVersion: '0.2.0',
      capabilities: <String>['surfaces'],
    ),
    timeout: _connectTimeout,
  );
  try {
    await connection.send(
      const plugins.RemotePluginFocusInput(surfaceId: _panelId),
    );
    await connection.surfaceMessages.drain<void>();

    final layers = plugins.buildRemotePluginSurfaceLayers(
      connection.surfaces,
      placements: const <plugins.RemotePluginSurfacePlacement>[
        plugins.RemotePluginSurfacePlacement(
          surfaceId: _panelId,
          x: 1,
          y: 1,
          z: 10,
        ),
      ],
    );
    final compositor = uv.Compositor(layers);

    io.stdout.writeln(
      'Connected plugin: '
      '${connection.pluginHello.pluginId} '
      '${connection.pluginHello.pluginVersion}',
    );
    io.stdout.writeln(
      'Open surfaces: ${layers.map((layer) => layer.id).join(', ')}',
    );
    for (final line in compositor.render().split('\n')) {
      io.stdout.writeln(line);
    }
  } finally {
    await connection.dispose(kill: true);
  }
}

String _parsePluginPath(List<String> args) {
  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (arg == '--plugin' && index + 1 < args.length) {
      return args[index + 1];
    }
    if (arg.startsWith('--plugin=')) {
      return arg.substring('--plugin='.length);
    }
  }

  return resolveArtisanalPath(<String>[
    'example',
    'tui',
    'remote_plugin_popup_guest_demo.dart',
  ]);
}
