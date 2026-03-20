import 'package:artisanal/plugins.dart' as plugins;
import 'package:artisanal/uv.dart' as uv;
import 'package:test/test.dart';

void main() {
  group('buildRemotePluginSurfaceLayers', () {
    test('builds positioned layers for root surfaces', () {
      final store = plugins.RemotePluginSurfaceStore();
      store.apply(
        const plugins.RemotePluginSurfaceOpen(
          surfaceId: 'panel',
          kind: plugins.RemotePluginSurfaceKind.panel,
          width: 4,
          height: 2,
        ),
      );

      final layers = plugins.buildRemotePluginSurfaceLayers(
        store,
        placements: const <plugins.RemotePluginSurfacePlacement>[
          plugins.RemotePluginSurfacePlacement(
            surfaceId: 'panel',
            x: 3,
            y: 2,
            z: 7,
          ),
        ],
      );

      expect(layers, hasLength(1));
      expect(layers.single.id, 'panel');
      expect(layers.single.x, 3);
      expect(layers.single.y, 2);
      expect(layers.single.z, 7);
    });

    test('anchors child popup surfaces relative to their parent', () {
      final store = plugins.RemotePluginSurfaceStore();
      store.apply(
        const plugins.RemotePluginSurfaceOpen(
          surfaceId: 'panel',
          kind: plugins.RemotePluginSurfaceKind.panel,
          width: 6,
          height: 3,
        ),
      );
      store.apply(
        const plugins.RemotePluginFrame(
          surfaceId: 'panel',
          width: 6,
          height: 3,
          cells: <plugins.RemotePluginFrameCell>[
            plugins.RemotePluginFrameCell(column: 0, row: 0, symbol: 'P'),
          ],
        ),
      );
      store.apply(
        const plugins.RemotePluginSurfaceOpen(
          surfaceId: 'popup',
          kind: plugins.RemotePluginSurfaceKind.popup,
          width: 2,
          height: 1,
          parentSurfaceId: 'panel',
          anchor: plugins.RemotePluginAnchorRect(
            column: 3,
            row: 1,
            width: 2,
            height: 1,
          ),
        ),
      );
      store.apply(
        const plugins.RemotePluginFrame(
          surfaceId: 'popup',
          width: 2,
          height: 1,
          cells: <plugins.RemotePluginFrameCell>[
            plugins.RemotePluginFrameCell(column: 0, row: 0, symbol: 'X'),
          ],
        ),
      );

      final layers = plugins.buildRemotePluginSurfaceLayers(
        store,
        placements: const <plugins.RemotePluginSurfacePlacement>[
          plugins.RemotePluginSurfacePlacement(
            surfaceId: 'panel',
            x: 2,
            y: 1,
            z: 5,
          ),
        ],
      );
      final compositor = uv.Compositor(layers);

      final panel = compositor.getLayer('panel');
      final popup = compositor.getLayer('popup');

      expect(panel, isNotNull);
      expect(popup, isNotNull);
      expect(panel!.x, 2);
      expect(panel.y, 1);
      expect(panel.z, 5);
      expect(popup!.x, 5);
      expect(popup.y, 2);
      expect(popup.z, 105);
      expect(compositor.hit(2, 1).id, 'panel');
      expect(compositor.hit(5, 2).id, 'popup');
    });

    test('resolves host placements and hit tests topmost surfaces', () {
      final store = plugins.RemotePluginSurfaceStore();
      store.apply(
        const plugins.RemotePluginSurfaceOpen(
          surfaceId: 'panel',
          kind: plugins.RemotePluginSurfaceKind.panel,
          width: 6,
          height: 3,
        ),
      );
      store.apply(
        const plugins.RemotePluginSurfaceOpen(
          surfaceId: 'popup',
          kind: plugins.RemotePluginSurfaceKind.popup,
          width: 2,
          height: 1,
          parentSurfaceId: 'panel',
          anchor: plugins.RemotePluginAnchorRect(
            column: 2,
            row: 1,
            width: 2,
            height: 1,
          ),
        ),
      );

      final resolved = plugins.resolveRemotePluginSurfacePlacements(
        store,
        placements: const <plugins.RemotePluginSurfacePlacement>[
          plugins.RemotePluginSurfacePlacement(
            surfaceId: 'panel',
            x: 4,
            y: 3,
            z: 9,
          ),
        ],
      );

      final panel = resolved.firstWhere(
        (surface) => surface.surfaceId == 'panel',
      );
      final popup = resolved.firstWhere(
        (surface) => surface.surfaceId == 'popup',
      );
      final panelHit = plugins.hitTestRemotePluginSurface(
        store,
        placements: const <plugins.RemotePluginSurfacePlacement>[
          plugins.RemotePluginSurfacePlacement(
            surfaceId: 'panel',
            x: 4,
            y: 3,
            z: 9,
          ),
        ],
        column: 4,
        row: 3,
      );
      final popupHit = plugins.hitTestRemotePluginSurface(
        store,
        placements: const <plugins.RemotePluginSurfacePlacement>[
          plugins.RemotePluginSurfacePlacement(
            surfaceId: 'panel',
            x: 4,
            y: 3,
            z: 9,
          ),
        ],
        column: 6,
        row: 4,
      );

      expect(panel.x, 4);
      expect(panel.y, 3);
      expect(panel.z, 9);
      expect(popup.x, 6);
      expect(popup.y, 4);
      expect(popup.z, 109);
      expect(panelHit, isNotNull);
      expect(panelHit!.surface.surfaceId, 'panel');
      expect(panelHit.column, 0);
      expect(panelHit.row, 0);
      expect(popupHit, isNotNull);
      expect(popupHit!.surface.surfaceId, 'popup');
      expect(popupHit.column, 0);
      expect(popupHit.row, 0);
    });
  });
}
