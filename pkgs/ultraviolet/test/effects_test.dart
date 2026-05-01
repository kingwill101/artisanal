import 'package:test/test.dart';
import 'package:ultraviolet/ultraviolet.dart';

void main() {
  group('ColorMatrix', () {
    test('invert preserves rgb alpha and flips color channels', () {
      final color = ColorMatrix.invert().transformColor(
        const UvRgb(10, 20, 30, a: 40),
      );

      expect(color, const UvRgb(245, 235, 225, a: 40));
    });

    test('grayscale converts palette colors to truecolor', () {
      final color = ColorMatrix.grayscale().transformColor(const UvBasic16(1));

      expect(color, isA<UvRgb>());
      expect((color as UvRgb).r, equals(color.g));
      expect(color.g, equals(color.b));
    });

    test('multiply scales color channels by multiplier color', () {
      final color = ColorMatrix.multiply(
        const UvRgb(255, 128, 64),
      ).transformColor(const UvRgb(100, 200, 240));

      expect(color, const UvRgb(100, 100, 60));
    });

    test('followedBy composes transforms in application order', () {
      final matrix = ColorMatrix.compose([
        ColorMatrix.tint(const UvRgb(255, 0, 0), amount: 0.5),
        ColorMatrix.gain(0.5),
      ]);

      final color = matrix.transformColor(const UvRgb(0, 0, 200));

      expect(color, const UvRgb(64, 0, 50));
    });
  });

  group('ColorMatrixFilter', () {
    test('transforms foreground and background through BufferRenderSink', () {
      final source = Buffer.create(1, 1);
      source.lines[0].replace(
        0,
        Cell(
          content: 'A',
          width: 1,
          style: const UvStyle(fg: UvRgb(10, 20, 30), bg: UvRgb(100, 110, 120)),
        ),
      );

      final sink = BufferRenderSink(width: 1, height: 1);
      final filtered = sink.render(source, [
        ColorMatrixFilter(ColorMatrix.invert()),
      ]);
      final cell = filtered.cellAt(0, 0)!;

      expect(cell.content, 'A');
      expect(
        cell.style,
        const UvStyle(fg: UvRgb(245, 235, 225), bg: UvRgb(155, 145, 135)),
      );
    });

    test('named constructors expose built-in effects directly', () {
      final source = Buffer.create(1, 1);
      source.lines[0].replace(
        0,
        Cell(
          content: 'C',
          width: 1,
          style: const UvStyle(fg: UvRgb(0, 0, 255), bg: UvRgb(10, 20, 30)),
        ),
      );

      final sink = BufferRenderSink(width: 1, height: 1);
      final filtered = sink.render(source, [
        ColorMatrixFilter.tint(const UvRgb(255, 0, 0), amount: 0.5),
      ]);
      final cell = filtered.cellAt(0, 0)!;

      expect(cell.style.fg, const UvRgb(128, 0, 128));
      expect(cell.style.bg, const UvRgb(133, 10, 15));
    });

    test('can skip background transforms', () {
      final source = Buffer.create(1, 1);
      source.lines[0].replace(
        0,
        Cell(
          content: 'B',
          width: 1,
          style: const UvStyle(fg: UvRgb(10, 20, 30), bg: UvRgb(100, 110, 120)),
        ),
      );

      final sink = BufferRenderSink(width: 1, height: 1);
      final filtered = sink.render(source, [
        ColorMatrixFilter.invert(background: false),
      ]);
      final cell = filtered.cellAt(0, 0)!;

      expect(
        cell.style,
        const UvStyle(fg: UvRgb(245, 235, 225), bg: UvRgb(100, 110, 120)),
      );
    });

    test('AmberTerminalFilter produces warm monochrome output', () {
      final source = Buffer.create(1, 1);
      source.setCell(
        0,
        0,
        Cell(
          content: '@',
          width: 1,
          style: const UvStyle(fg: UvRgb(40, 120, 240)),
        ),
      );

      final sink = BufferRenderSink(width: 1, height: 1);
      final filtered = sink.render(source, [AmberTerminalFilter()], dt: 0.2);
      final color = filtered.cellAt(0, 0)!.style.fg as UvRgb;

      expect(color.r, greaterThan(color.g));
      expect(color.g, greaterThan(color.b));
    });

    test('PhosphorFilter produces green-biased output', () {
      final source = Buffer.create(3, 3);
      for (var y = 0; y < 3; y++) {
        for (var x = 0; x < 3; x++) {
          source.setCell(
            x,
            y,
            Cell(
              content: '#',
              width: 1,
              style: const UvStyle(fg: UvRgb(220, 120, 60)),
            ),
          );
        }
      }

      final sink = BufferRenderSink(width: 3, height: 3);
      final filtered = sink.render(source, [PhosphorFilter()], dt: 0.2);
      final center = filtered.cellAt(1, 1)!.style.fg as UvRgb;

      expect(center.g, greaterThan(center.r));
      expect(center.g, greaterThan(center.b));
    });

    test('PhosphorTrailFilter leaves a phosphor-colored ghost trail', () {
      final source = Buffer.create(2, 1);
      source.setCell(
        0,
        0,
        Cell(
          content: '#',
          width: 1,
          style: const UvStyle(fg: UvRgb(220, 120, 60)),
        ),
      );

      final sink = BufferRenderSink(width: 2, height: 1);
      final filter = PhosphorTrailFilter(persistence: 0.5);

      sink.render(source, [filter], dt: 0.2);
      source.clear();
      final trailed = sink.render(source, [filter], dt: 0.2);
      final ghost = trailed.cellAt(0, 0)!;
      final color = ghost.style.fg as UvRgb;

      expect(ghost.content, '#');
      expect(color.g, greaterThan(color.r));
      expect(color.g, greaterThan(color.b));
    });

    test('AmberTrailFilter leaves a warm monochrome ghost trail', () {
      final source = Buffer.create(2, 1);
      source.setCell(
        0,
        0,
        Cell(
          content: '#',
          width: 1,
          style: const UvStyle(fg: UvRgb(60, 120, 220)),
        ),
      );

      final sink = BufferRenderSink(width: 2, height: 1);
      final filter = AmberTrailFilter(persistence: 0.45);

      sink.render(source, [filter], dt: 0.2);
      source.clear();
      final trailed = sink.render(source, [filter], dt: 0.2);
      final ghost = trailed.cellAt(0, 0)!;
      final color = ghost.style.fg as UvRgb;

      expect(ghost.content, '#');
      expect(color.r, greaterThan(color.g));
      expect(color.g, greaterThan(color.b));
    });

    test('CrtTrailFilter leaves a dimmed structural ghost trail', () {
      final source = Buffer.create(2, 1);
      source.setCell(
        0,
        0,
        Cell(
          content: '#',
          width: 1,
          style: const UvStyle(fg: UvRgb(180, 180, 180)),
        ),
      );

      final sink = BufferRenderSink(width: 2, height: 1);
      final filter = CrtTrailFilter(
        distortion: 0.0,
        vignette: 0.0,
        scanline: 0.0,
        rollingBar: 0.0,
        persistence: 0.5,
      );

      final first = sink.render(source, [filter], dt: 0.2);
      final firstColor = first.cellAt(0, 0)!.style.fg as UvRgb;

      source.clear();
      final trailed = sink.render(source, [filter], dt: 0.2);
      final ghost = trailed.cellAt(0, 0)!;
      final ghostColor = ghost.style.fg as UvRgb;

      expect(ghost.content, '#');
      expect(ghostColor.r, lessThan(firstColor.r));
      expect(ghostColor.g, lessThan(firstColor.g));
      expect(ghostColor.b, lessThan(firstColor.b));
    });
  });

  group('Higher-level filters', () {
    test('VignetteFilter darkens edges more than the center', () {
      final source = Buffer.create(5, 5);
      for (var y = 0; y < 5; y++) {
        for (var x = 0; x < 5; x++) {
          source.setCell(
            x,
            y,
            Cell(
              content: '#',
              width: 1,
              style: const UvStyle(fg: UvRgb(200, 200, 200)),
            ),
          );
        }
      }

      final sink = BufferRenderSink(width: 5, height: 5);
      final filtered = sink.render(source, [VignetteFilter(strength: 0.5)]);

      final center = filtered.cellAt(2, 2)!.style.fg as UvRgb;
      final corner = filtered.cellAt(0, 0)!.style.fg as UvRgb;

      expect(center, const UvRgb(200, 200, 200));
      expect(corner.r, lessThan(center.r));
      expect(corner.g, lessThan(center.g));
      expect(corner.b, lessThan(center.b));
    });

    test('ScanlineFilter attenuates alternating rows', () {
      final source = Buffer.create(2, 4);
      for (var y = 0; y < 4; y++) {
        for (var x = 0; x < 2; x++) {
          source.setCell(
            x,
            y,
            Cell(
              content: '=',
              width: 1,
              style: const UvStyle(fg: UvRgb(180, 180, 180)),
            ),
          );
        }
      }

      final sink = BufferRenderSink(width: 2, height: 4);
      final filtered = sink.render(source, [
        ScanlineFilter(lineStrength: 0.5, barStrength: 0.0),
      ]);

      final even = filtered.cellAt(0, 0)!.style.fg as UvRgb;
      final odd = filtered.cellAt(0, 1)!.style.fg as UvRgb;

      expect(even, const UvRgb(180, 180, 180));
      expect(odd, const UvRgb(90, 90, 90));
    });

    test('ScanlineFilter rolling bar shifts brightness over time', () {
      final source = Buffer.create(1, 6);
      for (var y = 0; y < 6; y++) {
        source.setCell(
          0,
          y,
          Cell(
            content: '|',
            width: 1,
            style: const UvStyle(fg: UvRgb(100, 100, 100)),
          ),
        );
      }

      final filter = ScanlineFilter(
        lineStrength: 0.0,
        barStrength: 0.6,
        barSpeed: 1.0,
        barHeightFraction: 0.2,
      );
      final sink = BufferRenderSink(width: 1, height: 6);

      final first = sink.render(source, [filter], dt: 0.0);
      final firstTop = (first.cellAt(0, 0)!.style.fg as UvRgb).r;
      final firstMiddle = (first.cellAt(0, 3)!.style.fg as UvRgb).r;

      final second = sink.render(source, [filter], dt: 0.5);
      final secondTop = (second.cellAt(0, 0)!.style.fg as UvRgb).r;
      final secondMiddle = (second.cellAt(0, 3)!.style.fg as UvRgb).r;

      expect(firstTop, greaterThan(firstMiddle));
      expect(secondMiddle, greaterThan(secondTop));
    });

    test('WaveDistortionFilter deterministically shifts sampled cells', () {
      final source = Buffer.create(4, 3);
      source.setCell(0, 0, Cell(content: 'A', width: 1));
      source.setCell(1, 0, Cell(content: 'B', width: 1));
      source.setCell(2, 0, Cell(content: 'C', width: 1));
      source.setCell(3, 0, Cell(content: 'D', width: 1));
      source.setCell(0, 1, Cell(content: 'E', width: 1));
      source.setCell(1, 1, Cell(content: 'F', width: 1));
      source.setCell(2, 1, Cell(content: 'G', width: 1));
      source.setCell(3, 1, Cell(content: 'H', width: 1));

      final sink = BufferRenderSink(width: 4, height: 3);
      final filtered = sink.render(source, [
        WaveDistortionFilter(
          xAmplitude: 1.0,
          yAmplitude: 0.0,
          xFrequency: 0.0,
          speed: 0.0,
          phase: 0.0,
        ),
      ]);

      expect(filtered.cellAt(0, 0)!.content, 'A');
      expect(filtered.cellAt(0, 1)!.content, 'E');

      final shifted = sink.render(source, [
        WaveDistortionFilter(
          xAmplitude: 1.0,
          yAmplitude: 0.0,
          xFrequency: 1.5707963267948966,
          speed: 0.0,
          phase: 0.0,
        ),
      ]);

      expect(shifted.cellAt(0, 1)!.content, 'F');
      expect(shifted.cellAt(1, 1)!.content, 'G');
    });

    test('CompositeFilter applies child filters in order', () {
      final source = Buffer.create(1, 2);
      for (var y = 0; y < 2; y++) {
        source.setCell(
          0,
          y,
          Cell(
            content: y == 0 ? 'A' : 'B',
            width: 1,
            style: const UvStyle(fg: UvRgb(200, 200, 200)),
          ),
        );
      }

      final sink = BufferRenderSink(width: 1, height: 2);
      final filtered = sink.render(source, [
        CompositeFilter([
          ScanlineFilter(lineStrength: 0.5, barStrength: 0.0),
          VignetteFilter(strength: 0.5),
        ]),
      ]);

      final top = filtered.cellAt(0, 0)!.style.fg as UvRgb;
      final bottom = filtered.cellAt(0, 1)!.style.fg as UvRgb;
      expect(top.r, lessThan(200));
      expect(bottom.r, lessThan(top.r));
    });

    test('CrtFilter combines distortion and scanline-style attenuation', () {
      final source = Buffer.create(3, 3);
      for (var y = 0; y < 3; y++) {
        for (var x = 0; x < 3; x++) {
          source.setCell(
            x,
            y,
            Cell(
              content: '${x + y}',
              width: 1,
              style: const UvStyle(fg: UvRgb(180, 180, 180)),
            ),
          );
        }
      }

      final sink = BufferRenderSink(width: 3, height: 3);
      final filtered = sink.render(source, [CrtFilter()], dt: 0.25);

      final center = filtered.cellAt(1, 1)!;
      final edge = filtered.cellAt(0, 0)!;
      expect(
        (edge.style.fg as UvRgb).r,
        lessThan((center.style.fg as UvRgb).r),
      );
    });

    test(
      'AtmosphereFilter preserves content while applying gentle falloff',
      () {
        final source = Buffer.create(3, 3);
        for (var y = 0; y < 3; y++) {
          for (var x = 0; x < 3; x++) {
            source.setCell(
              x,
              y,
              Cell(
                content: '*',
                width: 1,
                style: const UvStyle(fg: UvRgb(160, 200, 220)),
              ),
            );
          }
        }

        final sink = BufferRenderSink(width: 3, height: 3);
        final filtered = sink.render(source, [AtmosphereFilter()], dt: 0.3);

        expect(filtered.cellAt(1, 1)!.content, isNotEmpty);
        expect(filtered.cellAt(1, 1)!.style.fg, isA<UvRgb>());
      },
    );

    test(
      'GhostingFilter preserves a fading glyph trail without trailing background',
      () {
        final source = Buffer.create(2, 1);
        source.setCell(
          0,
          0,
          Cell(
            content: '@',
            width: 1,
            style: const UvStyle(
              fg: UvRgb(200, 180, 120),
              bg: UvRgb(40, 20, 10),
            ),
          ),
        );

        final sink = BufferRenderSink(width: 2, height: 1);
        final filter = GhostingFilter(persistence: 0.5, currentBoost: 0.0);

        final first = sink.render(source, [filter], dt: 0.1);
        expect(first.cellAt(0, 0)!.content, '@');

        source.clear();
        final second = sink.render(source, [filter], dt: 0.1);
        final ghost = second.cellAt(0, 0)!;

        expect(ghost.content, '@');
        expect(ghost.style.bg, isNull);
        expect(ghost.style.fg, const UvRgb(100, 90, 60));
      },
    );
  });
}
