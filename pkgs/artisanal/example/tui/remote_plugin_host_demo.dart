// tui:allow-stdout
import 'dart:async';
import 'dart:io' as io;

import 'package:artisanal/plugins.dart' as plugins;
import 'package:artisanal/uv.dart' as uv;

import '../_path_utils.dart';

const _surfaceId = 'demo.panel';
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
    await connection.send(const plugins.RemotePluginFocusInput(surfaceId: _surfaceId));

    await connection.surfaceMessages.drain<void>();

    final surface = connection.surfaces[_surfaceId];
    if (surface == null) {
      throw StateError('Plugin did not leave an open demo surface.');
    }

    io.stdout.writeln(
      'Connected plugin: '
      '${connection.pluginHello.pluginId} '
      '${connection.pluginHello.pluginVersion}',
    );
    io.stdout.writeln(
      'Surface ${surface.surfaceId} '
      '(${surface.kind.wireName}, ${surface.width}x${surface.height})',
    );
    for (final line in _renderSurface(surface)) {
      io.stdout.writeln(line);
    }
  } finally {
    await connection.dispose(kill: true);
  }
}

List<String> _renderSurface(plugins.RemotePluginSurfaceState surface) {
  final canvas = uv.Canvas(surface.width, surface.height);
  canvas.compose(plugins.RemotePluginSurfaceDrawable(surface));
  return canvas.render().split('\n');
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
    'remote_plugin_guest_demo.dart',
  ]);
}
