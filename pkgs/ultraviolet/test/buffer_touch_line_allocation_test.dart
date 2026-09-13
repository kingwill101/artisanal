import 'package:test/test.dart';
import 'package:ultraviolet/src/uv/uv.dart';

void main() {
  group('Buffer.touchLine reuse', () {
    test('reuses metadata for repeated touches within a full row', () {
      final buffer = Buffer.create(20, 1);
      addTearDown(buffer.dispose);
      buffer.touchLine(0, 0, 20);
      final metadata = buffer.touched[0];

      for (var i = 0; i < 20; i++) {
        buffer.touchLine(i, 0, 1);
      }

      expect(identical(buffer.touched[0], metadata), isTrue);
      expect(buffer.dirtyRows[0], isTrue);
    });

    test('reuses metadata for a range contained in an earlier sparse span', () {
      final buffer = Buffer.create(30, 1);
      addTearDown(buffer.dispose);
      buffer.touchLine(8, 0, 6);
      buffer.touchLine(20, 0, 2);
      final metadata = buffer.touched[0];
      buffer.dirtyBits[0][0] = 0;

      buffer.touchLine(9, 0, 2);

      expect(identical(buffer.touched[0], metadata), isTrue);
      expect(buffer.touched[0]!.spans, [
        DirtySpan(start: 8, end: 14),
        DirtySpan(start: 20, end: 22),
      ]);
      expect(buffer.isCellDirty(9, 0), isTrue);
    });

    test('reuses metadata for a range contained in an overflow range', () {
      final buffer = Buffer.create(40, 1);
      addTearDown(buffer.dispose);
      for (final x in [1, 5, 9, 13, 17]) {
        buffer.touchLine(x, 0, 1);
      }
      final metadata = buffer.touched[0];

      expect(buffer.isCellDirty(6, 0), isFalse);
      buffer.touchLine(6, 0, 2);

      expect(identical(buffer.touched[0], metadata), isTrue);
      expect(buffer.isCellDirty(6, 0), isTrue);
      expect(buffer.isCellDirty(7, 0), isTrue);
      expect(buffer.touched[0]!.overflowed, isTrue);
      expect(buffer.touched[0]!.spans, [DirtySpan(start: 1, end: 18)]);
    });

    test('extensions and gaps still merge correctly', () {
      final buffer = Buffer.create(30, 1);
      addTearDown(buffer.dispose);
      buffer.touchLine(4, 0, 3);
      buffer.touchLine(10, 0, 2);
      buffer.touchLine(6, 0, 9);

      expect(buffer.touched[0]!.spans, [DirtySpan(start: 4, end: 15)]);
      expect(buffer.touched[0]!.firstCell, 4);
      expect(buffer.touched[0]!.lastCell, 15);
    });

    test('clearDirtyLine resets metadata before the next touch', () {
      final buffer = Buffer.create(10, 1);
      addTearDown(buffer.dispose);
      buffer.touchLine(2, 0, 4);
      final metadata = buffer.touched[0];

      buffer.clearDirtyLine(0);
      expect(buffer.touched[0], LineData.clean);
      expect(buffer.dirtyRows[0], isFalse);
      expect(buffer.dirtyBitSpans(0), isEmpty);

      buffer.touchLine(3, 0, 1);
      expect(identical(buffer.touched[0], metadata), isFalse);
      expect(buffer.touched[0]!.spans, [DirtySpan(start: 3, end: 4)]);
    });

    test('a sentinel coarse bound still normalizes on a covered touch', () {
      final buffer = Buffer.create(20, 1);
      addTearDown(buffer.dispose);
      final metadata = LineData(
        firstCell: -1,
        lastCell: 12,
        spans: [DirtySpan(start: 0, end: 12)],
      );
      buffer.touched[0] = metadata;
      buffer.touchLine(9, 0, 1);

      expect(buffer.touched[0], isNot(same(metadata)));
      expect(buffer.touched[0]!.firstCell, 9);
      expect(buffer.touched[0]!.lastCell, 12);
      expect(buffer.isCellDirty(9, 0), isTrue);
    });

    test('a covering span does not prevent extending coarse bounds', () {
      final buffer = Buffer.create(20, 1);
      addTearDown(buffer.dispose);
      final metadata = LineData(
        firstCell: 5,
        lastCell: 6,
        spans: [DirtySpan(start: 0, end: 10)],
      );
      buffer.touched[0] = metadata;
      buffer.touchLine(4, 0, 2);

      expect(buffer.touched[0], isNot(same(metadata)));
      expect(buffer.touched[0]!.firstCell, 4);
      expect(buffer.touched[0]!.lastCell, 6);
      expect(buffer.isCellDirty(4, 0), isTrue);
    });
  });
}
