import 'dart:async';
import 'dart:io' as io;

import 'package:artisanal/plugins.dart' as plugins;

const _surfaceId = 'demo.panel';

Future<void> main(List<String> args) async {
  final pluginPath = _parsePluginPath(args);
  final plugin = await plugins.RemotePluginProcess.start(
    io.Platform.resolvedExecutable,
    <String>[pluginPath],
  );

  plugins.RemotePluginSession? session;
  try {
    session = await plugin.connect(
      hostHello: const plugins.RemotePluginHostHello(
        hostName: 'artisanal',
        hostVersion: '0.2.0',
        capabilities: <String>['surfaces'],
      ),
    );

    final store = plugins.RemotePluginSurfaceStore();
    await session.send(const plugins.RemotePluginFocusInput(surfaceId: _surfaceId));

    await for (final message in session.messages) {
      if (_isSurfaceMessage(message)) {
        store.apply(message);
      }
    }

    final surface = store[_surfaceId];
    if (surface == null) {
      throw StateError('Plugin did not leave an open demo surface.');
    }

    io.stdout.writeln(
      'Connected plugin: '
      '${session.pluginHello.pluginId} '
      '${session.pluginHello.pluginVersion}',
    );
    io.stdout.writeln(
      'Surface ${surface.surfaceId} '
      '(${surface.kind.wireName}, ${surface.width}x${surface.height})',
    );
    for (final line in _renderSurface(surface)) {
      io.stdout.writeln(line);
    }
  } finally {
    await session?.dispose();
    await plugin.dispose(kill: true);
  }
}

bool _isSurfaceMessage(plugins.RemotePluginMessage message) {
  return switch (message) {
    plugins.RemotePluginSurfaceOpen() ||
    plugins.RemotePluginSurfaceResize() ||
    plugins.RemotePluginFrame() ||
    plugins.RemotePluginSurfaceClose() => true,
    _ => false,
  };
}

List<String> _renderSurface(plugins.RemotePluginSurfaceState surface) {
  return List<String>.generate(surface.height, (row) {
    final buffer = StringBuffer();
    for (var column = 0; column < surface.width; column++) {
      buffer.write(surface.cellAt(column, row).symbol);
    }
    return buffer.toString().replaceFirst(RegExp(r'\s+$'), '');
  });
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

  return io.Directory.current.uri
      .resolve('pkgs/artisanal/example/tui/remote_plugin_guest_demo.dart')
      .toFilePath();
}
