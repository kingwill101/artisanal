import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:ultraviolet/raster.dart';

import 'support/raster_test_font.dart';

void main() {
  test('rejects loca offsets outside glyf and backwards offsets', () {
    final font = rasterTestFont();
    final loca = _table(font, 'loca');
    final bytes = ByteData.sublistView(font);
    bytes.setUint32(loca, 0xffffffff);
    expect(() => RasterFont.fromTtf(font), throwsArgumentError);
  });

  test('rejects malformed simple glyph endpoints and coordinate streams', () {
    final font = rasterTestFont();
    final glyph = _glyphRange(font, 2);
    final bytes = ByteData.sublistView(font);
    bytes.setUint16(glyph.start + 10, 0xffff);
    expect(() => RasterFont.fromTtf(font), throwsArgumentError);
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
