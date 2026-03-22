import 'package:artisanal/plugins.dart' as plugins;
import 'package:test/test.dart';

void main() {
  group('RemotePluginSurfaceStore', () {
    test('applies open, frame, resize, and close lifecycle', () {
      final store = plugins.RemotePluginSurfaceStore();

      store.apply(
        const plugins.RemotePluginSurfaceOpen(
          surfaceId: 'sidebar',
          kind: plugins.RemotePluginSurfaceKind.panel,
          width: 4,
          height: 2,
          title: 'Sidebar',
          slot: 'left',
        ),
      );

      final surface = store['sidebar'];
      expect(surface, isNotNull);
      expect(surface!.width, 4);
      expect(surface.height, 2);
      expect(surface.title, 'Sidebar');
      expect(surface.slot, 'left');
      expect(surface.cellAt(0, 0).isBlank, isTrue);

      store.apply(
        const plugins.RemotePluginFrame(
          surfaceId: 'sidebar',
          width: 4,
          height: 2,
          cells: <plugins.RemotePluginFrameCell>[
            plugins.RemotePluginFrameCell(
              column: 1,
              row: 0,
              symbol: 'A',
              foreground: '#ffffff',
            ),
          ],
          cursor: plugins.RemotePluginCursor(column: 2, row: 1),
        ),
      );

      expect(surface.cellAt(1, 0).symbol, 'A');
      expect(surface.cellAt(1, 0).foreground, '#ffffff');
      expect(surface.cursor, isNotNull);
      expect(surface.cursor!.column, 2);
      expect(surface.cursor!.row, 1);

      store.apply(
        const plugins.RemotePluginSurfaceResize(
          surfaceId: 'sidebar',
          width: 2,
          height: 2,
        ),
      );

      expect(surface.width, 2);
      expect(surface.height, 2);
      expect(surface.cellAt(1, 0).symbol, 'A');
      expect(surface.cursor, isNull);

      store.apply(
        const plugins.RemotePluginFrame(
          surfaceId: 'sidebar',
          width: 2,
          height: 2,
          cells: <plugins.RemotePluginFrameCell>[
            plugins.RemotePluginFrameCell(column: 0, row: 1, symbol: 'B'),
          ],
        ),
      );

      expect(surface.cellAt(1, 0).isBlank, isTrue);
      expect(surface.cellAt(0, 1).symbol, 'B');

      store.apply(const plugins.RemotePluginSurfaceClose(surfaceId: 'sidebar'));
      expect(store['sidebar'], isNull);
    });

    test('rejects duplicate opens and unknown surface updates', () {
      final store = plugins.RemotePluginSurfaceStore();

      store.apply(
        const plugins.RemotePluginSurfaceOpen(
          surfaceId: 'sidebar',
          kind: plugins.RemotePluginSurfaceKind.panel,
          width: 4,
          height: 2,
        ),
      );

      expect(
        () => store.apply(
          const plugins.RemotePluginSurfaceOpen(
            surfaceId: 'sidebar',
            kind: plugins.RemotePluginSurfaceKind.panel,
            width: 4,
            height: 2,
          ),
        ),
        throwsA(isA<StateError>()),
      );

      expect(
        () => store.apply(
          const plugins.RemotePluginFrame(
            surfaceId: 'missing',
            width: 1,
            height: 1,
            cells: <plugins.RemotePluginFrameCell>[],
          ),
        ),
        throwsA(isA<StateError>()),
      );

      expect(
        () => store.apply(
          const plugins.RemotePluginSurfaceClose(surfaceId: 'missing'),
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
