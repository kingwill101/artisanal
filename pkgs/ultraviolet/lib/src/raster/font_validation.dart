part of 'raster.dart';

/// Checks the complete outline graph before pure_ui parses it.
void _validateFontDirectory(Uint8List bytes) {
  if (bytes.length < 12 || bytes.length > 32 * 1024 * 1024) {
    throw const FormatException('Font size is invalid');
  }
  final data = ByteData.sublistView(bytes);
  if (data.getUint32(0) != 0x00010000) {
    throw const FormatException(
      'Only static TrueType sfnt fonts are supported',
    );
  }
  final count = data.getUint16(4);
  if (count == 0 || count > 128 || 12 + count * 16 > bytes.length) {
    throw const FormatException('Invalid font table directory');
  }
  final tables = <String, (int, int)>{};
  for (var i = 0; i < count; i++) {
    final at = 12 + i * 16;
    final tag = String.fromCharCodes(bytes.sublist(at, at + 4));
    final offset = data.getUint32(at + 8), length = data.getUint32(at + 12);
    if (offset < 12 + count * 16 ||
        offset + length > bytes.length ||
        tables.containsKey(tag)) {
      throw const FormatException('Invalid font table bounds');
    }
    tables[tag] = (offset, length);
  }
  for (final tag in ['head', 'hhea', 'maxp', 'cmap', 'hmtx', 'glyf', 'loca']) {
    if (!tables.containsKey(tag)) {
      throw FormatException('Missing $tag font table');
    }
  }
  for (final tag in ['CFF ', 'CFF2', 'fvar', 'COLR', 'CBDT', 'sbix', 'SVG ']) {
    if (tables.containsKey(tag)) {
      throw FormatException('Unsupported $tag font table');
    }
  }
  _validateTrueTypeOutlines(data, tables);
  final (cmap, length) = tables['cmap']!;
  if (length < 4) throw const FormatException('Truncated cmap');
  final records = data.getUint16(cmap + 2);
  if (4 + records * 8 > length) {
    throw const FormatException('Invalid cmap directory');
  }
  var coverage = 0;
  for (var i = 0; i < records; i++) {
    final offset = data.getUint32(cmap + 8 + i * 8);
    if (offset + 2 > length) {
      throw const FormatException('Invalid cmap subtable');
    }
    final subtable = cmap + offset;
    final format = data.getUint16(subtable);
    if (format == 12) {
      if (offset + 16 > length) throw const FormatException('Truncated cmap12');
      final groups = data.getUint32(subtable + 12);
      if (offset + 16 + groups * 12 > length) {
        throw const FormatException('Invalid cmap12 groups');
      }
      for (var j = 0; j < groups; j++) {
        final start = data.getUint32(subtable + 16 + j * 12);
        final end = data.getUint32(subtable + 20 + j * 12);
        if (start > end || end > 0x10ffff) {
          throw const FormatException('Invalid Unicode range');
        }
        coverage += end - start + 1;
      }
    } else if (format == 4) {
      if (offset + 14 > length) throw const FormatException('Truncated cmap4');
      final segments = data.getUint16(subtable + 6) ~/ 2;
      if (offset + 16 + segments * 8 > length) {
        throw const FormatException('Invalid cmap4 segments');
      }
      for (var j = 0; j < segments; j++) {
        final end = data.getUint16(subtable + 14 + j * 2);
        final start = data.getUint16(subtable + 16 + segments * 2 + j * 2);
        if (start > end) throw const FormatException('Invalid cmap4 range');
        coverage += end - start + 1;
      }
    }
    if (coverage > 0x220000) {
      throw const FormatException('Excessive cmap expansion');
    }
  }
}

void _validateTrueTypeOutlines(ByteData data, Map<String, (int, int)> tables) {
  (int, int) table(String name, int minimum) {
    final entry = tables[name]!;
    if (entry.$2 < minimum) throw FormatException('Truncated $name table');
    return entry;
  }

  final head = table('head', 54);
  final hhea = table('hhea', 36);
  final maxp = table('maxp', 6);
  final hmtx = tables['hmtx']!;
  final glyf = tables['glyf']!;
  final loca = tables['loca']!;
  final maxpVersion = data.getUint32(maxp.$1);
  if (maxpVersion != 0x00010000 || maxp.$2 < 32) {
    throw const FormatException('Unsupported maxp table');
  }
  final unitsPerEm = data.getUint16(head.$1 + 18);
  if (unitsPerEm < 16 || unitsPerEm > 16384) {
    throw const FormatException('Invalid head units per em');
  }
  final glyphCount = data.getUint16(maxp.$1 + 4);
  if (glyphCount == 0) throw const FormatException('Font has no glyphs');
  final longMetrics = data.getUint16(hhea.$1 + 34);
  if (longMetrics == 0 || longMetrics > glyphCount) {
    throw const FormatException('Invalid hhea metrics count');
  }
  final requiredHmtx = longMetrics * 4 + (glyphCount - longMetrics) * 2;
  if (hmtx.$2 < requiredHmtx) {
    throw const FormatException('Truncated hmtx table');
  }

  final locaFormat = data.getInt16(head.$1 + 50);
  if (locaFormat != 0 && locaFormat != 1) {
    throw const FormatException('Invalid loca format');
  }
  final locaCount = glyphCount + 1;
  final locaBytes = locaFormat == 0 ? locaCount * 2 : locaCount * 4;
  if (loca.$2 < locaBytes) throw const FormatException('Truncated loca table');
  final offsets = List<int>.generate(locaCount, (i) {
    final value = locaFormat == 0
        ? data.getUint16(loca.$1 + i * 2) * 2
        : data.getUint32(loca.$1 + i * 4);
    if (value > glyf.$2) {
      throw const FormatException('loca offset exceeds glyf');
    }
    return value;
  });
  for (var i = 1; i < offsets.length; i++) {
    if (offsets[i] < offsets[i - 1]) {
      throw const FormatException('loca offsets are not monotonic');
    }
  }

  final validator = _GlyphSafetyValidator(data, glyf.$1, offsets);
  for (var i = 0; i < glyphCount; i++) {
    validator.validate(i);
  }
}

/// The limits are deliberately generous for ordinary text fonts, while
/// bounding the recursive work pure_ui performs for hostile component graphs.
final class _GlyphSafetyValidator {
  _GlyphSafetyValidator(this.data, this.glyfOffset, this.offsets);

  static const _maxDepth = 32;
  static const _maxPoints = 4096;
  static const _maxComponents = 1024;
  static const _maxContours = 256;

  final ByteData data;
  final int glyfOffset;
  final List<int> offsets;
  final Map<int, (int, int, int, int)> memo = {};
  final Set<int> active = {};

  void validate(int glyph) => _visit(glyph, 0);

  (int, int, int, int) _visit(int glyph, int depth) {
    if (depth > _maxDepth) {
      throw const FormatException('Glyph composite nesting is too deep');
    }
    final cached = memo[glyph];
    if (cached != null) {
      if (depth + cached.$4 > _maxDepth) {
        throw const FormatException('Glyph composite nesting is too deep');
      }
      return cached;
    }
    if (!active.add(glyph)) {
      throw const FormatException('Cyclic glyph composite');
    }
    final start = offsets[glyph], end = offsets[glyph + 1];
    final result = start == end
        ? (0, 0, 0, 0)
        : _parseGlyph(glyfOffset + start, glyfOffset + end, depth);
    active.remove(glyph);
    if (result.$1 > _maxPoints ||
        result.$2 > _maxComponents ||
        result.$3 > _maxContours ||
        depth + result.$4 > _maxDepth) {
      throw const FormatException('Glyph composite expansion is excessive');
    }
    memo[glyph] = result;
    return result;
  }

  (int, int, int, int) _parseGlyph(int start, int end, int depth) {
    if (end - start < 10) throw const FormatException('Truncated glyf glyph');
    final contours = data.getInt16(start);
    if (contours >= 0) return _simple(start, end, contours);
    if (contours != -1) {
      throw const FormatException('Invalid glyph contour count');
    }
    var at = start + 10;
    var components = 0;
    var points = 0;
    var childContours = 0;
    var height = 0;
    var lastFlags = 0;
    while (true) {
      if (end - at < 4) {
        throw const FormatException('Truncated composite glyph');
      }
      final flags = data.getUint16(at);
      final child = data.getUint16(at + 2);
      if ((flags & 2) == 0) {
        throw const FormatException(
          'Point-matched composite glyphs are unsupported',
        );
      }
      final transforms = [
        8,
        0x40,
        0x80,
      ].where((flag) => (flags & flag) != 0).length;
      if (transforms > 1) {
        throw const FormatException('Conflicting composite transforms');
      }
      if (child >= offsets.length - 1) {
        throw const FormatException('Composite glyph index is out of range');
      }
      at += 4;
      final wordArgs = (flags & 1) != 0;
      at += wordArgs ? 4 : 2;
      if ((flags & 8) != 0) at += 2;
      if ((flags & 0x40) != 0) at += 4;
      if ((flags & 0x80) != 0) at += 8;
      if (at > end) {
        throw const FormatException('Truncated composite component');
      }
      final stats = _visit(child, depth + 1);
      height = math.max(height, stats.$4 + 1);
      points += stats.$1;
      components += stats.$2 + 1;
      childContours += stats.$3;
      if (points > _maxPoints ||
          components > _maxComponents ||
          childContours > _maxContours) {
        throw const FormatException('Glyph composite expansion is excessive');
      }
      lastFlags = flags;
      if ((flags & 0x20) == 0) break;
    }
    if ((lastFlags & 0x100) != 0) {
      if (end - at < 2) {
        throw const FormatException('Truncated composite instructions');
      }
      final length = data.getUint16(at);
      at += 2 + length;
      if (at > end) {
        throw const FormatException('Truncated composite instructions');
      }
    }
    return (points, components, childContours, height);
  }

  (int, int, int, int) _simple(int start, int end, int contourCount) {
    final endpointEnd = start + 10 + contourCount * 2;
    if (endpointEnd > end) {
      throw const FormatException('Truncated glyph endpoints');
    }
    var points = contourCount == 0 ? 0 : data.getUint16(endpointEnd - 2) + 1;
    if (points > _maxPoints || contourCount > _maxContours) {
      throw const FormatException('Too many glyph points');
    }
    var previous = -1;
    for (var i = 0; i < contourCount; i++) {
      final point = data.getUint16(start + 10 + i * 2);
      if (point <= previous || point >= points) {
        throw const FormatException('Invalid glyph contour endpoint');
      }
      previous = point;
    }
    var at = endpointEnd;
    if (end - at < 2) {
      throw const FormatException('Truncated glyph instructions');
    }
    final instructionLength = data.getUint16(at);
    at += 2;
    if (instructionLength > end - at) {
      throw const FormatException('Truncated glyph instructions');
    }
    at += instructionLength;
    var flagsRead = 0;
    while (flagsRead < points) {
      if (at >= end) throw const FormatException('Truncated glyph flags');
      final flag = data.getUint8(at++);
      flagsRead++;
      if ((flag & 8) != 0) {
        if (at >= end) {
          throw const FormatException('Truncated glyph flag repeat');
        }
        final repeat = data.getUint8(at++);
        if (repeat > points - flagsRead) {
          throw const FormatException('Invalid glyph flag repeat');
        }
        flagsRead += repeat;
      }
    }
    var coordinateBytes = 0;
    // Flags are reread to count the two variable-length coordinate streams.
    var flagAt = endpointEnd + 2 + instructionLength;
    var seen = 0;
    while (seen < points) {
      final flag = data.getUint8(flagAt++);
      final repeat = (flag & 8) == 0 ? 0 : data.getUint8(flagAt++);
      final count = repeat + 1;
      coordinateBytes += (flag & 2) != 0
          ? count
          : ((flag & 16) != 0 ? 0 : count * 2);
      coordinateBytes += (flag & 4) != 0
          ? count
          : ((flag & 32) != 0 ? 0 : count * 2);
      seen += count;
    }
    if (at + coordinateBytes > end) {
      throw const FormatException('Truncated glyph coordinates');
    }
    return (points, 0, contourCount, 0);
  }
}
