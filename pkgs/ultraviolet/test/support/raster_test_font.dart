import 'dart:typed_data';

/// A tiny, original static TrueType font for deterministic pixel tests.
///
/// Glyphs: space, a rectangular A, an O with a counter, and a two-cell 界.
/// All coordinates and metrics are deliberately integral at size 10. This
/// fixture needs no installed fonts, network access, or third-party font asset.
Uint8List rasterTestFont({int inkWidth = 400, bool curved = false}) {
  final glyphs = <Uint8List>[
    Uint8List(0), // .notdef
    Uint8List(0), // space
    _glyph([
      [(100, 0), (inkWidth + 100, 0), (inkWidth + 100, 700), (100, 700)],
    ], onCurve: curved ? [true, false, false, true] : null),
    _glyph([
      [(0, 0), (600, 0), (600, 700), (0, 700)],
      [(200, 200), (200, 500), (400, 500), (400, 200)],
    ]),
    _glyph([
      [(0, 0), (1200, 0), (1200, 700), (0, 700)],
    ]),
  ];
  final glyf = BytesBuilder();
  final loca = ByteData((glyphs.length + 1) * 4);
  for (var i = 0; i < glyphs.length; i++) {
    loca.setUint32(i * 4, glyf.length);
    glyf.add(glyphs[i]);
  }
  loca.setUint32(glyphs.length * 4, glyf.length);

  final head = ByteData(54)
    ..setUint32(0, 0x00010000)
    ..setUint32(12, 0x5f0f3cf5)
    ..setUint16(18, 1000)
    ..setInt16(50, 1);
  final hhea = ByteData(36)
    ..setUint32(0, 0x00010000)
    ..setInt16(4, 800)
    ..setInt16(6, -200)
    ..setUint16(34, glyphs.length);
  final maxp = ByteData(32)
    ..setUint32(0, 0x00010000)
    ..setUint16(4, glyphs.length);
  final hmtx = ByteData(glyphs.length * 4);
  for (var i = 0; i < glyphs.length; i++) {
    hmtx.setUint16(i * 4, i == 4 ? 1200 : 600);
  }
  const mappings = [(32, 1), (65, 2), (79, 3), (0x754c, 4)];
  final cmap = ByteData(12 + 16 + mappings.length * 12)
    ..setUint16(2, 1)
    ..setUint16(4, 3)
    ..setUint16(6, 10)
    ..setUint32(8, 12)
    ..setUint16(12, 12)
    ..setUint32(16, 16 + mappings.length * 12)
    ..setUint32(24, mappings.length);
  for (var i = 0; i < mappings.length; i++) {
    final offset = 28 + i * 12;
    cmap
      ..setUint32(offset, mappings[i].$1)
      ..setUint32(offset + 4, mappings[i].$1)
      ..setUint32(offset + 8, mappings[i].$2);
  }
  final tables = <String, Uint8List>{
    'cmap': cmap.buffer.asUint8List(),
    'glyf': glyf.takeBytes(),
    'head': head.buffer.asUint8List(),
    'hhea': hhea.buffer.asUint8List(),
    'hmtx': hmtx.buffer.asUint8List(),
    'loca': loca.buffer.asUint8List(),
    'maxp': maxp.buffer.asUint8List(),
  };
  final header = ByteData(12 + tables.length * 16)
    ..setUint32(0, 0x00010000)
    ..setUint16(4, tables.length)
    ..setUint16(6, 64)
    ..setUint16(8, 2)
    ..setUint16(10, tables.length * 16 - 64);
  var offset = header.lengthInBytes;
  final body = BytesBuilder();
  var index = 0;
  for (final entry in tables.entries) {
    final directory = 12 + index++ * 16;
    for (var i = 0; i < 4; i++) {
      header.setUint8(directory + i, entry.key.codeUnitAt(i));
    }
    header
      ..setUint32(directory + 8, offset)
      ..setUint32(directory + 12, entry.value.length);
    body.add(entry.value);
    final padding = (4 - entry.value.length % 4) % 4;
    body.add(Uint8List(padding));
    offset += entry.value.length + padding;
  }
  return (BytesBuilder()
        ..add(header.buffer.asUint8List())
        ..add(body.takeBytes()))
      .takeBytes();
}

Uint8List _glyph(List<List<(int, int)>> contours, {List<bool>? onCurve}) {
  final points = contours.expand((contour) => contour).toList();
  final data = ByteData(12 + contours.length * 2 + points.length * 5);
  data.setInt16(0, contours.length);
  var last = -1;
  for (var i = 0; i < contours.length; i++) {
    last += contours[i].length;
    data.setUint16(10 + i * 2, last);
  }
  var offset = 12 + contours.length * 2;
  for (var i = 0; i < points.length; i++) {
    data.setUint8(offset++, onCurve == null || onCurve[i] ? 1 : 0);
  }
  var previous = 0;
  for (final point in points) {
    data.setInt16(offset, point.$1 - previous);
    previous = point.$1;
    offset += 2;
  }
  previous = 0;
  for (final point in points) {
    data.setInt16(offset, point.$2 - previous);
    previous = point.$2;
    offset += 2;
  }
  return data.buffer.asUint8List();
}
