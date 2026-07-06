import 'package:artisanal/artisanal.dart' as plugins;
import 'package:artisanal/uv.dart' as uv;
import 'package:test/test.dart';

void main() {
  group('RemotePluginSurfaceDrawable', () {
    test('draws remote surface cells into a UV canvas', () {
      final store = plugins.RemotePluginSurfaceStore();
      store.apply(
        const plugins.RemotePluginSurfaceOpen(
          surfaceId: 'panel',
          kind: plugins.RemotePluginSurfaceKind.panel,
          width: 3,
          height: 2,
          title: 'Panel',
        ),
      );
      store.apply(
        const plugins.RemotePluginFrame(
          surfaceId: 'panel',
          width: 3,
          height: 2,
          cells: <plugins.RemotePluginFrameCell>[
            plugins.RemotePluginFrameCell(
              column: 0,
              row: 0,
              symbol: 'A',
              foreground: '#7dd3fc',
              background: '#112233',
              attributes: plugins.RemotePluginCellAttributes(
                bold: true,
                italic: true,
                underline: true,
                inverse: true,
              ),
            ),
            plugins.RemotePluginFrameCell(
              column: 1,
              row: 0,
              symbol: 'B',
              foreground: '#abcd',
              width: 1,
            ),
          ],
          cursor: plugins.RemotePluginCursor(column: 1, row: 0),
        ),
      );

      final surface = store['panel']!;
      final drawable = plugins.RemotePluginSurfaceDrawable(surface);
      final canvas = uv.Canvas(surface.width, surface.height);

      canvas.compose(drawable);

      final first = canvas.cellAt(0, 0)!;
      final second = canvas.cellAt(1, 0)!;

      expect(drawable.bounds().width, 3);
      expect(drawable.bounds().height, 2);
      expect(first.content, 'A');
      expect(first.style.fg, const uv.UvRgb(0x7d, 0xd3, 0xfc));
      expect(first.style.bg, const uv.UvRgb(0x11, 0x22, 0x33));
      expect(first.style.underline, uv.UnderlineStyle.single);
      expect(first.style.attrs & uv.Attr.bold, isNonZero);
      expect(first.style.attrs & uv.Attr.italic, isNonZero);
      expect(first.style.attrs & uv.Attr.reverse, isNonZero);
      expect(second.content, 'B');
      expect(second.style.fg, const uv.UvRgb(0xaa, 0xbb, 0xcc, a: 0xdd));
    });
  });
}
