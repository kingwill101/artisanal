import 'package:artisanal/src/tui/editor_core/editor_core.dart';
import 'package:test/test.dart';

void main() {
  group('TextExtmarksController', () {
    test('creates typed extmarks and supports basic queries', () {
      final controller = TextExtmarksController();

      final syntaxId = controller.create(
        const TextExtmarkOptions(
          startOffset: 0,
          endOffset: 5,
          type: 'syntax',
          styleKey: 'keyword',
        ),
      );
      final virtualId = controller.create(
        const TextExtmarkOptions(
          startOffset: 6,
          endOffset: 10,
          type: 'inlay',
          virtual: true,
          data: 'hint',
        ),
      );

      expect(
        controller.get(syntaxId),
        const TextExtmark(
          id: 1,
          type: 'syntax',
          startOffset: 0,
          endOffset: 5,
          styleKey: 'keyword',
        ),
      );
      expect(controller.getAllForType('syntax').map((mark) => mark.id), [1]);
      expect(controller.getVirtual().map((mark) => mark.id), [2]);
      expect(controller.getAtOffset(7).map((mark) => mark.id), [2]);
      expect(controller.get(virtualId)?.data, 'hint');
    });

    test('adjusts extmarks for insertions', () {
      final controller = TextExtmarksController();
      final leadingId = controller.create(
        const TextExtmarkOptions(startOffset: 0, endOffset: 2, type: 'a'),
      );
      final overlappingId = controller.create(
        const TextExtmarkOptions(startOffset: 1, endOffset: 4, type: 'b'),
      );
      final trailingId = controller.create(
        const TextExtmarkOptions(startOffset: 5, endOffset: 7, type: 'c'),
      );

      controller.applyInsertion(offset: 2, text: 'xy');

      expect(
        controller.get(leadingId),
        const TextExtmark(id: 1, type: 'a', startOffset: 0, endOffset: 2),
      );
      expect(
        controller.get(overlappingId),
        const TextExtmark(id: 2, type: 'b', startOffset: 1, endOffset: 6),
      );
      expect(
        controller.get(trailingId),
        const TextExtmark(id: 3, type: 'c', startOffset: 7, endOffset: 9),
      );
    });

    test('adjusts extmarks for deletions across all overlap cases', () {
      final controller = TextExtmarksController();
      final beforeId = controller.create(
        const TextExtmarkOptions(startOffset: 0, endOffset: 2, type: 'before'),
      );
      final insideId = controller.create(
        const TextExtmarkOptions(startOffset: 3, endOffset: 5, type: 'inside'),
      );
      final spanningId = controller.create(
        const TextExtmarkOptions(startOffset: 1, endOffset: 8, type: 'span'),
      );
      final leftOverlapId = controller.create(
        const TextExtmarkOptions(startOffset: 0, endOffset: 4, type: 'left'),
      );
      final rightOverlapId = controller.create(
        const TextExtmarkOptions(startOffset: 6, endOffset: 10, type: 'right'),
      );
      final afterId = controller.create(
        const TextExtmarkOptions(startOffset: 10, endOffset: 12, type: 'after'),
      );

      controller.applyDeletion(startOffset: 2, endOffset: 7);

      expect(
        controller.get(beforeId),
        const TextExtmark(id: 1, type: 'before', startOffset: 0, endOffset: 2),
      );
      expect(controller.get(insideId), isNull);
      expect(
        controller.get(spanningId),
        const TextExtmark(id: 3, type: 'span', startOffset: 1, endOffset: 3),
      );
      expect(
        controller.get(leftOverlapId),
        const TextExtmark(id: 4, type: 'left', startOffset: 0, endOffset: 2),
      );
      expect(
        controller.get(rightOverlapId),
        const TextExtmark(id: 5, type: 'right', startOffset: 2, endOffset: 5),
      );
      expect(
        controller.get(afterId),
        const TextExtmark(id: 6, type: 'after', startOffset: 5, endOffset: 7),
      );
    });

    test('applies replacements as delete plus insert at the same anchor', () {
      final controller = TextExtmarksController();
      final spanningId = controller.create(
        const TextExtmarkOptions(startOffset: 1, endOffset: 8, type: 'span'),
      );
      final trailingId = controller.create(
        const TextExtmarkOptions(startOffset: 8, endOffset: 10, type: 'tail'),
      );

      controller.applyReplacement(startOffset: 3, endOffset: 6, text: 'xyz');

      expect(
        controller.get(spanningId),
        const TextExtmark(id: 1, type: 'span', startOffset: 1, endOffset: 8),
      );
      expect(
        controller.get(trailingId),
        const TextExtmark(id: 2, type: 'tail', startOffset: 8, endOffset: 10),
      );
    });

    test('maps extmark offsets back to document positions', () {
      final document = TextDocument(text: 'ab\ncdef');
      final controller = TextExtmarksController();
      final id = controller.create(
        const TextExtmarkOptions(startOffset: 1, endOffset: 5, type: 'range'),
      );

      final positions = textExtmarkPositionRange(document, controller.get(id)!);

      expect(
        positions,
        const TextExtmarkPositionRange(
          start: TextPosition(line: 0, column: 1),
          end: TextPosition(line: 1, column: 2),
        ),
      );
    });
  });
}
