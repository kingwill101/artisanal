import 'package:artisanal_capture/artisanal_capture.dart';
import 'package:artisanal_capture/rendering.dart';
import 'package:test/test.dart';
import 'package:ultraviolet/ultraviolet.dart' as uv;

import 'support/font_fixture.dart';

void main() {
  test('buffer copies retain exactly one cell per owned result', () {
    final source = uv.Buffer.create(1, 1);
    source.setCellOwned(
      0,
      0,
      uv.Cell(
        content: 'A',
        link: const uv.Link(url: 'https://owned.test/buffer'),
      ),
    );
    final id = source.cellAt(0, 0)!.linkId!;
    final capture = TerminalCapture.fromBuffer(source);
    expect(uv.debugLinkRefCount(id), 2);
    source.dispose();
    expect(uv.debugLinkRefCount(id), 1);

    final copy = capture.toBuffer();
    expect(uv.debugLinkRefCount(id), 2);
    copy.dispose();
    copy.dispose();
    expect(uv.debugLinkRefCount(id), 1);
    expect(capture.toJson()['columns'], 1);
  });

  test('ANSI capture releases its parsing screen before returning', () {
    const link = uv.Link(url: 'https://owned.test/ansi', params: 'id=1');
    final anchor = uv.Cell(link: link);
    addTearDown(anchor.dispose);
    final id = anchor.linkId!;
    final capture = TerminalCapture.fromAnsi(
      '\x1b]8;${link.params};${link.url}\x1b\\A\x1b]8;;\x1b\\',
      columns: 1,
      rows: 1,
    );
    expect(uv.debugLinkRefCount(id), 2);
    final copy = capture.toBuffer();
    expect(copy.cellAt(0, 0)!.link, link);
    copy.dispose();
    expect(uv.debugLinkRefCount(id), 2);
  });

  test('failed JSON construction releases previously decoded cells', () {
    const link = uv.Link(url: 'https://owned.test/json');
    final anchor = uv.Cell(link: link);
    addTearDown(anchor.dispose);
    final id = anchor.linkId!;
    final json = TerminalCapture.fromAnsi('AB', columns: 2, rows: 1).toJson();
    final row = (json['cells'] as List).single as List;
    (row[0] as Map)['link'] = {'url': link.url, 'params': ''};
    (row[1] as Map)['width'] = -1;

    expect(() => TerminalCapture.fromJson(json), throwsFormatException);
    expect(uv.debugLinkRefCount(id), 1);
  });

  test('raster export releases its buffer on success and setup failure', () {
    const link = uv.Link(url: 'https://owned.test/raster');
    final anchor = uv.Cell(link: link);
    addTearDown(anchor.dispose);
    final id = anchor.linkId!;
    final capture = TerminalCapture.fromAnsi(
      '\x1b]8;;${link.url}\x1b\\A\x1b]8;;\x1b\\',
      columns: 1,
      rows: 1,
    );
    final font = RasterFont.fromTtf(testFontBytes());
    final image = CaptureRasterizer(font: font).render(capture);
    expect(image.png, isNotEmpty);
    expect(uv.debugLinkRefCount(id), 2);
    expect(
      () => CaptureRasterizer(
        font: font,
        options: const RasterRenderOptions(fontSize: 0),
      ).render(capture),
      throwsArgumentError,
    );
    expect(uv.debugLinkRefCount(id), 2);
  });
}
