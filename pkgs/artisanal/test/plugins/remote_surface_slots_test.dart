import 'package:artisanal/plugins.dart';
import 'package:test/test.dart';

void main() {
  group('remote plugin slot bridge', () {
    test('resolves and groups slot entries with plugin ids', () {
      final store = RemotePluginSurfaceStore();
      store.applyAll([
        const RemotePluginSurfaceOpen(
          surfaceId: 'overview',
          kind: RemotePluginSurfaceKind.panel,
          width: 20,
          height: 4,
          title: 'Overview',
          slot: 'left',
        ),
        const RemotePluginSurfaceOpen(
          surfaceId: 'activity',
          kind: RemotePluginSurfaceKind.panel,
          width: 30,
          height: 6,
          title: 'Activity',
          slot: 'main',
        ),
        const RemotePluginSurfaceOpen(
          surfaceId: 'alerts',
          kind: RemotePluginSurfaceKind.overlay,
          width: 10,
          height: 3,
          title: 'Alerts',
          slot: 'main',
        ),
      ]);

      final entries = resolveRemotePluginSlotEntries(
        store,
        placements: const [
          RemotePluginSurfacePlacement(surfaceId: 'overview', x: 0, y: 0, z: 0),
          RemotePluginSurfacePlacement(
            surfaceId: 'activity',
            x: 20,
            y: 0,
            z: 0,
          ),
          RemotePluginSurfacePlacement(surfaceId: 'alerts', x: 22, y: 1, z: 50),
        ],
        pluginIdBySurfaceId: const {
          'overview': 'overview-plugin',
          'activity': 'activity-plugin',
          'alerts': 'alerts-plugin',
        },
      );

      expect(entries.map((entry) => entry.slot), ['left', 'main', 'main']);
      expect(entries.map((entry) => entry.surfaceId), [
        'overview',
        'activity',
        'alerts',
      ]);
      expect(entries.map((entry) => entry.pluginId), [
        'overview-plugin',
        'activity-plugin',
        'alerts-plugin',
      ]);

      final grouped = groupRemotePluginSlotEntries(
        store,
        placements: const [
          RemotePluginSurfacePlacement(surfaceId: 'overview', x: 0, y: 0, z: 0),
          RemotePluginSurfacePlacement(
            surfaceId: 'activity',
            x: 20,
            y: 0,
            z: 0,
          ),
          RemotePluginSurfacePlacement(surfaceId: 'alerts', x: 22, y: 1, z: 50),
        ],
        pluginIdBySurfaceId: const {
          'overview': 'overview-plugin',
          'activity': 'activity-plugin',
          'alerts': 'alerts-plugin',
        },
      );

      expect(grouped.keys, {'left', 'main'});
      expect(grouped['left']!.single.surfaceId, 'overview');
      expect(grouped['main']!.map((entry) => entry.surfaceId), [
        'activity',
        'alerts',
      ]);
    });

    test('ignores unslotted surfaces unless a default slot is provided', () {
      final store = RemotePluginSurfaceStore();
      store.apply(
        const RemotePluginSurfaceOpen(
          surfaceId: 'floating',
          kind: RemotePluginSurfaceKind.popup,
          width: 8,
          height: 4,
          title: 'Floating',
        ),
      );

      expect(resolveRemotePluginSlotEntries(store), isEmpty);

      final entries = resolveRemotePluginSlotEntries(
        store,
        defaultSlot: 'overlay',
      );
      expect(entries.single.slot, 'overlay');
      expect(entries.single.surfaceId, 'floating');
    });

    test('orders entries by slot, then z, then plugin id, then surface id', () {
      final store = RemotePluginSurfaceStore();
      store.applyAll([
        const RemotePluginSurfaceOpen(
          surfaceId: 'b-surface',
          kind: RemotePluginSurfaceKind.panel,
          width: 4,
          height: 2,
          slot: 'main',
        ),
        const RemotePluginSurfaceOpen(
          surfaceId: 'a-surface',
          kind: RemotePluginSurfaceKind.panel,
          width: 4,
          height: 2,
          slot: 'main',
        ),
      ]);

      final entries = resolveRemotePluginSlotEntries(
        store,
        placements: const [
          RemotePluginSurfacePlacement(
            surfaceId: 'b-surface',
            x: 0,
            y: 0,
            z: 3,
          ),
          RemotePluginSurfacePlacement(
            surfaceId: 'a-surface',
            x: 0,
            y: 0,
            z: 3,
          ),
        ],
        pluginIdBySurfaceId: const {
          'b-surface': 'plugin-b',
          'a-surface': 'plugin-a',
        },
      );

      expect(entries.map((entry) => entry.surfaceId), [
        'a-surface',
        'b-surface',
      ]);
    });
  });
}
