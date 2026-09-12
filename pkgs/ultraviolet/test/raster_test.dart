import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:test/test.dart';
import 'package:ultraviolet/raster.dart';
import 'package:ultraviolet/ultraviolet.dart';

import 'support/raster_test_font.dart';

const _black = UvRgb(0, 0, 0);
const _white = UvRgb(255, 255, 255);
const _red = UvRgb(255, 0, 0);

RasterTerminalRenderer _renderer({
  RasterRenderOptions options = const RasterRenderOptions(
    fontSize: 10,
    foreground: _white,
    background: _black,
  ),
  bool strict = true,
}) {
  final configured = RasterRenderOptions(
    fontSize: options.fontSize,
    cellWidth: options.cellWidth,
    cellHeight: options.cellHeight,
    padding: options.padding,
    foreground: options.foreground,
    background: options.background,
    palette: options.palette,
    strict: strict,
  );
  return RasterTerminalRenderer(
    font: RasterFont.fromTtf(rasterTestFont()),
    options: configured,
  );
}

img.Image _render(RasterTerminalRenderer renderer, Buffer buffer) {
  renderer.render(buffer);
  return renderer.image!;
}

void _expectPixel(img.Image image, int x, int y, UvRgb color) {
  final pixel = image.getPixel(x, y);
  expect(
    (pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt(), pixel.a.toInt()),
    (color.r, color.g, color.b, color.a),
    reason: 'unexpected pixel at ($x, $y)',
  );
}

Cell _cell(
  String content, {
  UvStyle style = const UvStyle(),
  int? width,
  CellDiffOption diffOption = CellDiffOption.normal,
}) =>
    Cell(content: content, style: style, width: width, diffOption: diffOption);

void main() {
  group('RasterFont validation', () {
    test('rejects empty font data', () {
      expect(() => RasterFont.fromTtf(Uint8List(0)), throwsArgumentError);
    });

    test('rejects truncated font data', () {
      expect(
        () => RasterFont.fromTtf(Uint8List.fromList(<int>[0, 1, 0, 0])),
        throwsArgumentError,
      );
    });
  });

  group('RasterTerminalRenderer pixels', () {
    test('preserves glyph counters and antialiases quadratic contours', () {
      final hole = _render(
        _renderer(),
        Buffer.fromCells([
          [_cell('O')],
        ]),
      );
      _expectPixel(hole, 1, 4, _white);
      _expectPixel(hole, 3, 4, _black);
      final curved = RasterTerminalRenderer(
        font: RasterFont.fromTtf(rasterTestFont(curved: true)),
        options: const RasterRenderOptions(
          fontSize: 10,
          foreground: _white,
          background: _black,
        ),
      );
      final pixels = _render(
        curved,
        Buffer.fromCells([
          [_cell('A')],
        ]),
      );
      expect(pixels.any((p) => p.r > 0 && p.r < 255), isTrue);
      expect(pixels.any((p) => p.r == 255), isTrue);
    });

    test('diagnoses huge decoration widths without an unbounded loop', () {
      final renderer = _renderer();
      expect(
        () => renderer.render(
          Buffer.fromCells([
            [
              _cell(
                'A',
                width: 1 << 40,
                style: const UvStyle(underline: UnderlineStyle.single),
              ),
            ],
          ]),
        ),
        throwsStateError,
      );
      expect(renderer.diagnostics.single.code, 'invalid-cell-width');
    });

    test('uses actual supplied bold glyphs without synthesizing ink', () {
      final font = RasterFont.fromTtf(
        rasterTestFont(inkWidth: 200),
        bold: rasterTestFont(inkWidth: 500),
      );
      final renderer = RasterTerminalRenderer(
        font: font,
        options: const RasterRenderOptions(fontSize: 10, foreground: _white),
      );
      final image = _render(
        renderer,
        Buffer.fromCells([
          [_cell('A'), _cell('A', style: const UvStyle(attrs: Attr.bold))],
        ]),
      );
      _expectPixel(image, 4, 4, _black);
      _expectPixel(image, 10, 4, _white);
    });

    test('rejects style variants with incompatible baseline metrics', () {
      final variant = rasterTestFont();
      final data = ByteData.sublistView(variant);
      for (var i = 0; i < data.getUint16(4); i++) {
        final at = 12 + i * 16;
        if (String.fromCharCodes(variant.sublist(at, at + 4)) == 'hhea') {
          data.setInt16(data.getUint32(at + 8) + 4, 700);
        }
      }
      expect(
        () => RasterFont.fromTtf(rasterTestFont(), bold: variant),
        throwsArgumentError,
      );
    });

    test('allocates cell geometry and renders positive glyph coverage', () {
      final renderer = _renderer(
        options: const RasterRenderOptions(
          fontSize: 10,
          padding: 2,
          foreground: _white,
          background: _black,
        ),
      );
      final image = _render(
        renderer,
        Buffer.fromCells([
          [_cell('A')],
        ]),
      );

      expect(image.width, 10); // 6-pixel cell plus 2 pixels on each side.
      expect(image.height, 14);
      _expectPixel(image, 0, 4, _black); // padding is outside the ink.
      _expectPixel(image, 4, 4, _white); // robustly inside the rectangle.
      expect(renderer.width(), 1);
      expect(renderer.height(), 1);
    });

    test('fills backgrounds before drawing a wide glyph tail', () {
      final image = _render(
        _renderer(),
        Buffer.fromCells([
          [_cell('界', width: 2), _cell('', style: const UvStyle(bg: _red))],
        ]),
      );

      // The two-cell glyph is 12 pixels wide. The second cell's background
      // must not paint over its right half.
      _expectPixel(image, 8, 4, _white);
      _expectPixel(image, 11, 4, _white);
      expect(image.width, 12);
    });

    test('applies palette colors, reverse, faint, and conceal exactly', () {
      final palette = List<UvRgb>.filled(16, _black);
      palette[1] = _red;
      final renderer = _renderer(
        options: RasterRenderOptions(
          fontSize: 10,
          background: const UvRgb(20, 40, 60),
          palette: palette,
        ),
      );
      final buffer = Buffer.fromCells([
        [
          _cell(
            'A',
            style: const UvStyle(fg: UvBasic16(1), bg: UvRgb(20, 40, 60)),
          ),
          _cell(
            'A',
            style: const UvStyle(
              fg: UvBasic16(1),
              bg: UvRgb(20, 40, 60),
              attrs: Attr.reverse,
            ),
          ),
          _cell(
            'A',
            style: const UvStyle(
              fg: UvRgb(255, 255, 255),
              bg: UvRgb(0, 0, 0),
              attrs: Attr.faint,
            ),
          ),
          _cell('A', style: const UvStyle(attrs: Attr.conceal)),
        ],
      ]);
      final image = _render(renderer, buffer);

      _expectPixel(image, 0, 0, const UvRgb(20, 40, 60));
      _expectPixel(image, 2, 4, _red);
      _expectPixel(image, 8, 4, const UvRgb(20, 40, 60));
      _expectPixel(image, 14, 4, const UvRgb(128, 128, 128));
      _expectPixel(image, 18, 4, const UvRgb(20, 40, 60));
    });

    test('renders every underline mode and underline color on spaces', () {
      for (final mode in UnderlineStyle.values.skip(1)) {
        final renderer = _renderer();
        final image = _render(
          renderer,
          Buffer.fromCells([
            [
              _cell(
                ' ',
                style: UvStyle(underline: mode, underlineColor: _red),
              ),
            ],
          ]),
        );
        bool isRed(int x, int y) {
          final pixel = image.getPixel(x, y);
          return pixel.r.toInt() == 255 && pixel.g.toInt() == 0;
        }

        final expected = switch (mode) {
          UnderlineStyle.single => <(int, int)>[
            for (var x = 0; x < 6; x++) (x, 9),
          ],
          UnderlineStyle.double => <(int, int)>[
            for (var x = 0; x < 6; x++) (x, 9),
            for (var x = 0; x < 6; x++) (x, 7),
          ],
          UnderlineStyle.dotted => <(int, int)>[(0, 9), (2, 9), (4, 9)],
          UnderlineStyle.dashed => <(int, int)>[(0, 9), (1, 9), (2, 9), (3, 9)],
          UnderlineStyle.curly => <(int, int)>[
            (0, 9),
            (1, 8),
            (2, 7),
            (3, 8),
            (4, 9),
            (5, 8),
          ],
          UnderlineStyle.none => const <(int, int)>[],
        };
        for (final point in expected) {
          expect(
            isRed(point.$1, point.$2),
            isTrue,
            reason: '$mode missing underline pixel at $point',
          );
        }
        expect([
          for (var y = 0; y < image.height; y++)
            for (var x = 0; x < image.width; x++)
              if (isRed(x, y)) (x, y),
        ], unorderedEquals(expected));
      }
    });

    test('clears diagnostics and pixels on repeated render', () {
      final renderer = _renderer(strict: false);
      final bad = Buffer.fromCells([
        [_cell('Z')],
      ]);
      _render(renderer, bad);
      expect(renderer.diagnostics, hasLength(1));
      expect(renderer.image!.getPixel(2, 4).r, 0);

      final good = Buffer.fromCells([
        [_cell('A')],
      ]);
      final image = _render(renderer, good);
      expect(renderer.diagnostics, isEmpty);
      _expectPixel(image, 3, 4, _white);
    });
  });

  group('RasterTerminalRenderer diagnostics and API', () {
    test('reports missing glyphs and missing variants in non-strict mode', () {
      final renderer = _renderer(strict: false);
      _render(
        renderer,
        Buffer.fromCells([
          [_cell('Z')],
        ]),
      );
      expect(renderer.diagnostics.single.code, 'missing-glyph');

      final bold = _renderer(strict: false);
      _render(
        bold,
        Buffer.fromCells([
          [_cell('A', style: const UvStyle(attrs: Attr.bold))],
        ]),
      );
      expect(bold.diagnostics.single.code, 'missing-variant');
    });

    test('strict mode rejects unsupported graphemes and graphics cells', () {
      expect(
        () => _render(
          _renderer(),
          Buffer.fromCells([
            [_cell('AO')],
          ]),
        ),
        throwsStateError,
      );
      expect(
        () => _render(
          _renderer(),
          Buffer.fromCells([
            [_cell('', diffOption: CellDiffOption.skip)],
          ]),
        ),
        throwsStateError,
      );
    });

    test('validates options and dimensions', () {
      final font = RasterFont.fromTtf(rasterTestFont());
      expect(
        () => RasterTerminalRenderer(
          font: font,
          options: const RasterRenderOptions(fontSize: 0),
        ),
        throwsArgumentError,
      );
      expect(
        () => RasterTerminalRenderer(
          font: font,
          options: const RasterRenderOptions(padding: -1),
        ),
        throwsArgumentError,
      );
      final renderer = _renderer();
      expect(() => renderer.resize(-1, 1), throwsArgumentError);
      expect(() => renderer.resize(3000, 3000), throwsArgumentError);
    });

    test('detaches font bytes from the caller', () {
      final bytes = rasterTestFont();
      final font = RasterFont.fromTtf(bytes);
      bytes.fillRange(0, bytes.length, 0);
      final renderer = RasterTerminalRenderer(
        font: font,
        options: const RasterRenderOptions(
          fontSize: 10,
          foreground: _white,
          background: _black,
        ),
      );
      final image = _render(
        renderer,
        Buffer.fromCells([
          [_cell('A')],
        ]),
      );
      _expectPixel(image, 3, 4, _white);
    });
  });
}
