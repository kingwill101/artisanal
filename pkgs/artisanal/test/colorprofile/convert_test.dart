import 'package:artisanal/src/colorprofile/convert.dart';
import 'package:test/test.dart';

void main() {
  group('colorprofile.rgbToAnsi256', () {
    test('matches upstream test vectors', () {
      final cases = <String, ({String hex, int expected})>{
        'white': (hex: '#ffffff', expected: 231),
        'offwhite': (hex: '#eeeeee', expected: 255),
        'slightly brighter than offwhite': (hex: '#f2f2f2', expected: 255),
        'red': (hex: '#ff0000', expected: 196),
        'silver foil': (hex: '#afafaf', expected: 145),
        'silver chalice': (hex: '#b2b2b2', expected: 249),
        'slightly closer to silver foil': (hex: '#b0b0b0', expected: 145),
        'slightly closer to silver chalice': (hex: '#b1b1b1', expected: 249),
        'gray': (hex: '#808080', expected: 244),
      };

      for (final entry in cases.entries) {
        final name = entry.key;
        final hex = entry.value.hex;
        final expected = entry.value.expected;
        final (r, g, b) = _parseHex(hex);
        final idx = rgbToAnsi256(r, g, b);
        expect(idx, expected, reason: name);
      }
    });
  });

  group('colorprofile.ansi256ToAnsi16', () {
    test('returns stable mappings', () {
      expect(ansi256ToAnsi16(196), isIn(<int>[1, 9]));
      expect(ansi256ToAnsi16(21), isIn(<int>[4, 12]));
      expect(ansi256ToAnsi16(244), isIn(<int>[0, 7, 8, 15]));
    });
  });
}

(int, int, int) _parseHex(String hex) {
  final h = hex.startsWith('#') ? hex.substring(1) : hex;
  final r = int.parse(h.substring(0, 2), radix: 16);
  final g = int.parse(h.substring(2, 4), radix: 16);
  final b = int.parse(h.substring(4, 6), radix: 16);
  return (r, g, b);
}
