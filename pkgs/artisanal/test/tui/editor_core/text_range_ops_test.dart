import 'package:artisanal/editor_core.dart';
import 'package:test/test.dart';

void main() {
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

    test('extend keeps the start and maps the end', () {
      final selections = TextSelectionSet.collapsed(3);
      final extended = mapSelectionEnds(
        selections,
        forward: false,
        extend: true,
        mapEnd: (offset, _) => offset - 2,
      );

      expect(
        extended.ranges.single,
        const TextSelectionRange(startOffset: 1, endOffset: 3),
      );
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
