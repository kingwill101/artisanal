import 'package:artisanal/editor_core.dart';
import 'package:test/test.dart';

void main() {
  group('textOffsetOnAdjacentVisibleLine', () {
    test('restores a preferred column after crossing a short line', () {
      final document = TextDocument(text: 'abcdef\nxy\nabcdef');
      final start = document.offsetForPosition(
        const TextPosition(line: 0, column: 5),
      );

      final shortLine = textOffsetOnAdjacentVisibleLine(
        document: document,
        offset: start,
        below: true,
        preferredColumn: 5,
      );
      final restored = textOffsetOnAdjacentVisibleLine(
        document: document,
        offset: shortLine,
        below: true,
        preferredColumn: 5,
      );

      expect(
        document.positionForOffset(shortLine),
        const TextPosition(line: 1, column: 2),
      );
      expect(
        document.positionForOffset(restored),
        const TextPosition(line: 2, column: 5),
      );
    });

    test('skips hidden lines and stops at document boundaries', () {
      final document = TextDocument(text: 'ab\nhidden\ncd');
      final start = document.offsetForPosition(
        const TextPosition(line: 0, column: 1),
      );
      final moved = textOffsetOnAdjacentVisibleLine(
        document: document,
        offset: start,
        below: true,
        isLineHidden: (line) => line == 1,
      );

      expect(
        document.positionForOffset(moved),
        const TextPosition(line: 2, column: 1),
      );
      expect(
        textOffsetOnAdjacentVisibleLine(
          document: document,
          offset: moved,
          below: true,
        ),
        moved,
      );
    });
  });

  group('mapSelectionRanges', () {
    test('maps every range and preserves the primary range', () {
      final selections = TextSelectionSet(const [
        TextSelectionRange(startOffset: 1, endOffset: 1),
        TextSelectionRange(startOffset: 5, endOffset: 5),
      ], primaryOffset: 1);

      final moved = mapSelectionRanges(
        selections,
        transform: (range) => TextSelectionRange(
          startOffset: range.startOffset + 2,
          endOffset: range.endOffset + 2,
        ),
      );

      expect(moved.ranges, [
        const TextSelectionRange(startOffset: 3, endOffset: 3),
        const TextSelectionRange(startOffset: 7, endOffset: 7),
      ]);
      expect(moved.primary, moved.ranges.first);
    });
  });

  group('mapSelectionEnds', () {
    test('moves collapsed cursors and collapses non-collapsed ranges', () {
      final selections = TextSelectionSet(const [
        TextSelectionRange(startOffset: 1, endOffset: 1),
        TextSelectionRange(startOffset: 4, endOffset: 7),
      ], primaryOffset: 7);

      final moved = mapSelectionEnds(
        selections,
        forward: true,
        mapEnd: (offset, _) => offset + 1,
      );

      expect(moved.ranges, [
        const TextSelectionRange(startOffset: 2, endOffset: 2),
        const TextSelectionRange(startOffset: 7, endOffset: 7),
      ]);
    });

    test('extend retains the anchor and maps the active edge', () {
      final selections = TextSelectionSet.collapsed(3);
      final extended = mapSelectionEnds(
        selections,
        forward: false,
        extend: true,
        mapEnd: (offset, _) => offset - 2,
      );

      expect(
        extended.ranges.single,
        const TextSelectionRange(
          startOffset: 1,
          endOffset: 3,
          isReversed: true,
        ),
      );
      expect(extended.ranges.single.anchorOffset, 3);
      expect(extended.ranges.single.activeOffset, 1);
    });

    test('repeated backward extension moves every active edge', () {
      final selections = TextSelectionSet(const [
        TextSelectionRange(startOffset: 3, endOffset: 3),
        TextSelectionRange(startOffset: 8, endOffset: 8),
      ], primaryOffset: 3);

      TextSelectionSet extendLeft(TextSelectionSet current) {
        return mapSelectionEnds(
          current,
          forward: false,
          extend: true,
          mapEnd: (offset, _) => offset - 1,
        );
      }

      final extended = extendLeft(extendLeft(selections));

      expect(extended.ranges.map((range) => range.anchorOffset), [3, 8]);
      expect(extended.ranges.map((range) => range.activeOffset), [1, 6]);
      expect(extended.ranges.every((range) => range.isReversed), isTrue);
      expect(extended.primary, extended.ranges.first);
    });

    test('extension can cross the anchor and change direction', () {
      final reversed = TextSelectionSet([
        TextSelectionRange.directional(anchorOffset: 3, activeOffset: 1),
      ], primaryOffset: 1);

      final crossed = mapSelectionEnds(
        reversed,
        forward: true,
        extend: true,
        mapEnd: (offset, _) => offset + 4,
      );

      expect(crossed.ranges.single.startOffset, 3);
      expect(crossed.ranges.single.endOffset, 5);
      expect(crossed.ranges.single.isReversed, isFalse);
      expect(crossed.ranges.single.anchorOffset, 3);
      expect(crossed.ranges.single.activeOffset, 5);
    });

    test('returns the original set when mapping is a no-op', () {
      final selections = TextSelectionSet.collapsed(0);
      final next = mapSelectionEnds(
        selections,
        forward: false,
        mapEnd: (offset, _) => offset,
      );
      expect(identical(next, selections), isTrue);
    });
  });
}
