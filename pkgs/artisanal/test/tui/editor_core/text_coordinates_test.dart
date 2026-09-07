import 'package:artisanal/editor_core.dart';
import 'package:test/test.dart';

void main() {
  group('UTF-8 document coordinates', () {
    final document = TextDocument(text: 'a😀e\u0301\n中x');

    test('maps UTF-8 points to grapheme positions and offsets', () {
      expect(
        textPositionForUtf8Point(
          document,
          const TextUtf8Point(row: 0, byteColumn: 5),
        ),
        const TextPosition(line: 0, column: 2),
      );
      expect(
        textOffsetForUtf8Point(
          document,
          const TextUtf8Point(row: 1, byteColumn: 3),
        ),
        5,
      );
    });

    test('rounds byte positions inside graphemes down', () {
      expect(
        textPositionForUtf8Point(
          document,
          const TextUtf8Point(row: 0, byteColumn: 3),
        ),
        const TextPosition(line: 0, column: 1),
      );
      expect(
        textPositionForUtf8Point(
          document,
          const TextUtf8Point(row: 0, byteColumn: 6),
        ),
        const TextPosition(line: 0, column: 2),
      );
    });

    test('maps grapheme positions back to UTF-8 points', () {
      expect(
        textUtf8PointForPosition(
          document,
          const TextPosition(line: 0, column: 2),
        ),
        const TextUtf8Point(row: 0, byteColumn: 5),
      );
      expect(
        textUtf8PointForOffset(document, 5),
        const TextUtf8Point(row: 1, byteColumn: 3),
      );
    });

    test('maps whole-document byte offsets in both directions', () {
      expect(textOffsetForUtf8ByteOffset(document, 3), 1);
      expect(textOffsetForUtf8ByteOffset(document, 9), 4);
      expect(textOffsetForUtf8ByteOffset(document, 12), 5);
      expect(textUtf8ByteOffsetForOffset(document, 4), 9);
      expect(textUtf8ByteOffsetForOffset(document, 5), 12);
    });

    test('reuses a coordinate index across parser ranges', () {
      final index = TextUtf8CoordinateIndex(document);

      expect(index.byteLength, 13);
      expect(
        index.positionForPoint(const TextUtf8Point(row: 0, byteColumn: 5)),
        const TextPosition(line: 0, column: 2),
      );
      expect(index.offsetForByteOffset(12), 5);
      expect(index.byteOffsetForOffset(5), 12);
    });

    test('clamps points and offsets to the document', () {
      expect(
        textPositionForUtf8Point(
          document,
          const TextUtf8Point(row: 99, byteColumn: 99),
        ),
        const TextPosition(line: 1, column: 2),
      );
      expect(textOffsetForUtf8ByteOffset(document, 999), document.length);
      expect(textUtf8ByteOffsetForOffset(document, 999), 13);
    });
  });
}
