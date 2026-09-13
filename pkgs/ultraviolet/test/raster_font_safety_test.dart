import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:ultraviolet/raster.dart';

import 'support/raster_test_font.dart';

void main() {
  test('rejects loca offsets outside glyf bounds', () {
    final font = rasterTestFont();
    final loca = _table(font, 'loca');
    final bytes = ByteData.sublistView(font);
    bytes.setUint32(loca, 0xffffffff);
    _expectFormatError(font, 'loca offset exceeds glyf');
  });

  test('rejects nonmonotonic loca offsets', () {
    final font = rasterTestFont();
    final loca = _table(font, 'loca');
    final bytes = ByteData.sublistView(font);
    final thirdGlyphEnd = bytes.getUint32(loca + 3 * 4);
    bytes.setUint32(loca + 4 * 4, thirdGlyphEnd - 1);
    _expectFormatError(font, 'loca offsets are not monotonic');
  });

  test('rejects truncated simple glyph endpoints', () {
    final font = rasterTestFont();
    final range = _glyphRange(font, 2);
    final bytes = ByteData.sublistView(font);
    bytes.setInt16(range.start, 100);
    _expectFormatError(font, 'Truncated glyph endpoints');
  });

  test('rejects invalid simple glyph contour endpoints', () {
    final font = rasterTestFont();
    final range = _glyphRange(font, 3);
    final bytes = ByteData.sublistView(font);
    final lastEndpoint = bytes.getUint16(range.start + 12);
    bytes.setUint16(range.start + 10, lastEndpoint);
    _expectFormatError(font, 'Invalid glyph contour endpoint');
  });

  test('rejects truncated simple glyph coordinates', () {
    final font = rasterTestFont();
    final glyph = _glyphRange(font, 2);
    final loca = _table(font, 'loca');
    final bytes = ByteData.sublistView(font);
    final end = bytes.getUint32(loca + 3 * 4);
    bytes.setUint32(loca + 3 * 4, end - 1);
    expect(glyph.end, greaterThan(end));
    _expectFormatError(font, 'Truncated glyph coordinates');
  });

  test('rejects a self-referencing composite without entering pure_ui', () {
    final font = rasterTestFont();
    _makeComposite(font, 2, 2);
    expect(() => RasterFont.fromTtf(font), throwsArgumentError);
  });

  test('rejects mutually recursive composite glyphs', () {
    final font = rasterTestFont();
    _makeComposite(font, 2, 3);
    _makeComposite(font, 3, 2);
    expect(() => RasterFont.fromTtf(font), throwsArgumentError);
  });
}

void _expectFormatError(Uint8List font, String message) {
  expect(
    () => RasterFont.fromTtf(font),
    throwsA(
      isA<ArgumentError>().having(
        (error) => error.message,
        'message',
        contains('FormatException: $message'),
      ),
    ),
  );
}

({int start, int end}) _glyphRange(Uint8List font, int glyph) {
  final loca = _table(font, 'loca');
  final data = ByteData.sublistView(font);
  final start = data.getUint32(loca + glyph * 4);
  final end = data.getUint32(loca + (glyph + 1) * 4);
  final glyf = _table(font, 'glyf');
  return (start: glyf + start, end: glyf + end);
}

int _table(Uint8List font, String tag) {
  final data = ByteData.sublistView(font);
  final count = data.getUint16(4);
  for (var i = 0; i < count; i++) {
    final at = 12 + i * 16;
    if (String.fromCharCodes(font.sublist(at, at + 4)) == tag) {
      return data.getUint32(at + 8);
    }
  }
  throw StateError('missing $tag');
}

void _makeComposite(Uint8List font, int glyph, int child) {
  final range = _glyphRange(font, glyph);
  if (range.end - range.start < 16) fail('fixture glyph is too small');
  final data = ByteData.sublistView(font);
  data.setInt16(range.start, -1);
  // Signed word-sized XY offsets, with no transform.
  data
    ..setUint16(range.start + 10, 3)
    ..setUint16(range.start + 12, child)
    ..setInt16(range.start + 14, 0)
    ..setInt16(range.start + 16, 0);
}
