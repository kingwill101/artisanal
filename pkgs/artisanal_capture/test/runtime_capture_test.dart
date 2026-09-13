import 'package:artisanal/runtime.dart';
import 'package:artisanal_capture/runtime.dart';
import 'package:test/test.dart';
import 'package:ultraviolet/ultraviolet.dart' as uv;
import 'package:ultraviolet/src/uv/uv.dart' as uv_debug;

void main() {
  test('runtime adapter refuses diagnostic-only snapshots', () {
    final snapshot = ProgramRenderSnapshot(
      sequence: 0,
      renderGeneration: 1,
      view: const View(content: 'text'),
      frame: TerminalRenderFrame.inspect(const View(content: 'text')),
      degradationLevel: DegradationLevel.full,
      renderDuration: Duration.zero,
    );
    expect(() => captureProgramFrame(snapshot), throwsStateError);
  });

  test('runtime adapter preserves cell metadata in a detached capture', () {
    final source = uv.Buffer.fromCells([
      [
        uv.Cell(
          content: 'A',
          style: const uv.UvStyle(fg: uv.UvColor.rgb(10, 20, 30)),
          link: const uv.Link(url: 'https://example.test', params: 'id=1'),
          diffOption: uv.CellDiffOption.alwaysUpdate,
        ),
      ],
    ]);
    final nativeFrame = TerminalNativeFrame.fromBuffer(source);
    final snapshot = ProgramRenderSnapshot(
      sequence: 0,
      renderGeneration: 1,
      view: const View(content: 'A'),
      frame: TerminalRenderFrame.inspect(const View(content: 'A')),
      degradationLevel: DegradationLevel.full,
      renderDuration: Duration.zero,
      nativeFrame: nativeFrame,
    );

    final capture = captureProgramFrame(snapshot);
    source.cellAt(0, 0)!.content = 'X';
    final cell = capture.toBuffer().cellAt(0, 0)!;
    expect(cell.content, 'A');
    expect(cell.style.fg, const uv.UvColor.rgb(10, 20, 30));
    expect(
      cell.link,
      const uv.Link(url: 'https://example.test', params: 'id=1'),
    );
    expect(cell.diffOption, uv.CellDiffOption.alwaysUpdate);
  });

  test('runtime adapter releases its owned intermediate before GC', () {
    final source = uv.Buffer.create(1, 1);
    source.setCellOwned(
      0,
      0,
      uv.Cell(
        content: 'A',
        link: const uv.Link(url: 'https://example.test/runtime-owned'),
      ),
    );
    final linkId = source.cellAt(0, 0)!.linkId!;
    final nativeFrame = TerminalNativeFrame.fromBuffer(source);

    final capture = captureProgramFrame(
      ProgramRenderSnapshot(
        sequence: 0,
        renderGeneration: 1,
        view: const View(content: 'A'),
        frame: TerminalRenderFrame.inspect(const View(content: 'A')),
        degradationLevel: DegradationLevel.full,
        renderDuration: Duration.zero,
        nativeFrame: nativeFrame,
      ),
    );
    // Only the capture owns a linked cell after releasing the source.
    source.dispose();
    expect(uv_debug.debugLinkRefCount(linkId), 1);

    final detached = capture.toBuffer();
    expect(uv_debug.debugLinkRefCount(linkId), 2);
    expect(detached.cellAt(0, 0)!.content, 'A');
    detached.dispose();
    expect(uv_debug.debugLinkRefCount(linkId), 1);
  });
}
