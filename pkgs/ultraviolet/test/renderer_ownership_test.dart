import 'package:test/test.dart';
import 'package:ultraviolet/src/uv/uv.dart';

void main() {
  test('renderer reset and disposal release only owned frame cells', () {
    const link = Link(url: 'https://renderer-ownership.example/frame');
    final input = Buffer.create(3, 1);
    final cell = Cell(content: 'A', link: link);
    final id = cell.linkId!;
    input.setCellOwned(0, 0, cell);
    final renderer = UvTerminalRenderer(
      StringBuffer(),
      env: const ['TERM=xterm-256color'],
    );
    addTearDown(renderer.dispose);
    addTearDown(input.dispose);

    expect(debugLinkRefCount(id), 1);
    renderer.render(input);
    renderer.flush();
    expect(debugLinkRefCount(id), greaterThan(1));

    renderer.resetForResize(3, 1);
    expect(debugLinkRefCount(id), 1);
    expect(input.cellAt(0, 0)!.link, link);
    renderer.render(input);
    renderer.flush();
    expect(debugLinkRefCount(id), greaterThan(1));

    renderer.dispose();
    renderer.dispose();
    expect(debugLinkRefCount(id), 1);
    expect(input.cellAt(0, 0)!.content, 'A');
    expect(input.cellAt(0, 0)!.link, link);
    expect(() => renderer.render(input), throwsStateError);

    input.dispose();
    expect(debugLinkRefCount(id), 0);
    expect(debugLinkPayload(id), const Link());
  });

  test('canvas disposal preserves borrowed input cells and rendered text', () {
    const link = Link(url: 'https://renderer-ownership.example/canvas');
    final source = Cell(content: 'A', link: link);
    final id = source.linkId!;
    final canvas = Canvas(2, 1);
    addTearDown(source.dispose);
    addTearDown(canvas.dispose);
    canvas.setCell(0, 0, source);
    expect(debugLinkRefCount(id), 2);

    final rendered = canvas.render();
    canvas.dispose();
    canvas.dispose();
    expect(debugLinkRefCount(id), 1);
    expect(source.content, 'A');
    expect(source.link, link);
    expect(rendered, contains(link.url));
    expect(rendered, contains('A'));
  });
}
