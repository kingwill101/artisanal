import 'dart:async';
import 'dart:io' as io;

import 'package:artisanal/plugins.dart' as plugins;
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'fixture_compiler.dart';

void main() {
  late CompiledPluginFixtures fixtures;

  setUpAll(() async {
    fixtures = await compilePluginFixtures(<String>[
      'clipboard_plugin.dart',
      'notification_plugin.dart',
    ]);
  });

  tearDownAll(() async {
    await fixtures.dispose();
  });

  test(
    'workspace starts manifest-backed plugins with shared services and routing',
    () async {
      var clipboard = 'workspace clipboard';
      plugins.RemotePluginNotificationRequest? notification;
      final manifestDirectory = io.Directory(
        p.dirname(fixtures.path('clipboard_plugin.dart')),
      );
      final clipboardManifestPath = p.join(
        manifestDirectory.path,
        'workspace_clipboard.plugin.json',
      );
      final notificationManifestPath = p.join(
        manifestDirectory.path,
        'workspace_notification.plugin.json',
      );
      addTearDown(() async {
        for (final path in <String>[
          clipboardManifestPath,
          notificationManifestPath,
        ]) {
          final file = io.File(path);
          if (await file.exists()) {
            await file.delete();
          }
        }
      });

      await _writeManifest(
        clipboardManifestPath,
        id: 'clipboard',
        entrypoint: p.basename(fixtures.path('clipboard_plugin.dart')),
        primarySurfaceId: 'clipboard.panel',
        surfaceIds: const <String>['clipboard.panel'],
        x: 0,
        y: 0,
      );
      await _writeManifest(
        notificationManifestPath,
        id: 'notification',
        entrypoint: p.basename(fixtures.path('notification_plugin.dart')),
        primarySurfaceId: 'notification.panel',
        surfaceIds: const <String>['notification.panel'],
        x: 40,
        y: 0,
      );

      final workspace =
          await plugins.RemotePluginWorkspace.startManifestDirectory(
            manifestDirectory.path,
            executable: io.Platform.resolvedExecutable,
            hostHello: const plugins.RemotePluginHostHello(
              hostName: 'artisanal',
              hostVersion: '0.2.0',
            ),
            genericServices: plugins.RemotePluginGenericServiceCatalog.builtIns(
              readClipboard: (_) => clipboard,
              writeClipboard: (_, text) {
                clipboard = text;
              },
              notify: (request) {
                notification = request;
              },
            ),
            timeout: const Duration(seconds: 20),
          );
      addTearDown(() => workspace.dispose(kill: true));

      expect(
        workspace.manifests.map((manifest) => manifest.id).toList(),
        <String>['clipboard', 'notification'],
      );
      expect(workspace.pluginIdForSurface('clipboard.panel'), 'clipboard');
      expect(
        workspace.pluginIdForSurface('notification.panel'),
        'notification',
      );

      await _waitForSurfaceText(
        workspace,
        'clipboard',
        contains: 'read:workspace clipboard',
      );
      await _waitForSurfaceText(workspace, 'clipboard', contains: 'write:ok');
      await _waitForSurfaceText(
        workspace,
        'notification',
        contains: 'notify:ok',
      );

      expect(clipboard, 'plugin-copy');
      expect(notification, isNotNull);
      expect(notification!.message, 'Background task finished');

      await workspace.focusPlugin('notification');
      expect(workspace.router.focusedSurfaceId, 'notification.panel');
      expect(
        workspace.manifestForPlugin('notification')?.displayName ??
            'notification',
        'notification',
      );
    },
  );
}

Future<void> _writeManifest(
  String path, {
  required String id,
  required String entrypoint,
  required String primarySurfaceId,
  required List<String> surfaceIds,
  required int x,
  required int y,
}) {
  final manifest = plugins.RemotePluginManifest(
    id: id,
    entrypoint: entrypoint,
    primarySurfaceId: primarySurfaceId,
    surfaceIds: surfaceIds,
    placement: plugins.RemotePluginManifestPlacement(
      surfaceId: primarySurfaceId,
      x: x,
      y: y,
    ),
    manifestPath: path,
  );
  return io.File(path).writeAsString(manifest.encodeJson());
}

Future<void> _waitForSurfaceText(
  plugins.RemotePluginWorkspace workspace,
  String pluginId, {
  required String contains,
  Duration timeout = const Duration(seconds: 5),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    final manifest = workspace.manifestForPlugin(pluginId);
    if (manifest != null) {
      final surface = workspace.surfaces[manifest.primarySurfaceId];
      if (surface != null) {
        for (var row = 0; row < surface.height; row++) {
          final line = <String>[
            for (var column = 0; column < surface.width; column++)
              surface.cellAt(column, row).symbol,
          ].join();
          if (line.contains(contains)) {
            return;
          }
        }
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }

  throw TimeoutException(
    'Timed out waiting for "$contains" in plugin "$pluginId".',
    timeout,
  );
}
