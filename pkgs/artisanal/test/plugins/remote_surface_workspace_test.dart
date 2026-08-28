import 'dart:async';
import 'dart:io' as io;

import 'package:artisanal/artisanal.dart' as plugins;
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
        p.join(
          p.dirname(fixtures.path('clipboard_plugin.dart')),
          'workspace-manifests',
        ),
      )..createSync(recursive: true);
      final clipboardManifestPath = p.join(
        manifestDirectory.path,
        'workspace_clipboard.plugin.json',
      );
      final notificationManifestPath = p.join(
        manifestDirectory.path,
        'workspace_notification.plugin.json',
      );
      addTearDown(() async {
        if (await manifestDirectory.exists()) {
          await manifestDirectory.delete(recursive: true);
        }
      });

      await _writeManifest(
        clipboardManifestPath,
        id: 'clipboard',
        entrypoint: p.relative(
          fixtures.path('clipboard_plugin.dart'),
          from: manifestDirectory.path,
        ),
        primarySurfaceId: 'clipboard.panel',
        surfaceIds: const <String>['clipboard.panel'],
        x: 0,
        y: 0,
      );
      await _writeManifest(
        notificationManifestPath,
        id: 'notification',
        entrypoint: p.relative(
          fixtures.path('notification_plugin.dart'),
          from: manifestDirectory.path,
        ),
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
            timeout: const Duration(seconds: 60),
          );
      addTearDown(() async {
        await workspace.dispose(kill: true);
        // Windows cannot delete a directory a dying child still holds as its
        // working directory, so wait for every plugin process to be gone.
        await Future.wait(<Future<int>>[
          for (final connection in workspace.connections.values)
            connection.process.exitCode,
        ]);
      });

      expect(
        workspace.manifests.map((manifest) => manifest.id).toList(),
        <String>['clipboard', 'notification'],
      );
      expect(workspace.pluginIdForSurface('clipboard.panel'), 'clipboard');
      expect(
        workspace.pluginIdForSurface('notification.panel'),
        'notification',
      );

      // Both fixtures serve until the host hangs up, so focusing the
      // already-published notification surface cannot race its process exit.
      await workspace.focusPlugin('notification');
      expect(workspace.router.focusedSurfaceId, 'notification.panel');

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

      expect(
        workspace.manifestForPlugin('notification')?.displayName ??
            'notification',
        'notification',
      );

      final notificationEntries = workspace.slotEntriesFor(
        'notification',
        defaultSlot: 'notification',
      );
      expect(
        notificationEntries.any((entry) => entry.pluginId == 'notification'),
        isTrue,
      );
      expect(
        notificationEntries.any(
          (entry) => entry.surfaceId == 'notification.panel',
        ),
        isTrue,
      );

      final notificationRouter = workspace.slotInputRouterFor(
        'notification',
        originX: 40,
        originY: 0,
        defaultSlot: 'notification',
      );
      final hit = notificationRouter.hitTest(0, 0);
      expect(hit, isNotNull);
      expect(hit!.surfaceId, 'notification.panel');
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
  Duration timeout = const Duration(seconds: 15),
}) async {
  final stopwatch = Stopwatch()..start();
  while (stopwatch.elapsed < timeout) {
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
