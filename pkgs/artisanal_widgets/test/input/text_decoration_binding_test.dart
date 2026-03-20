import 'package:artisanal_widgets/editors.dart';
import 'package:test/test.dart';

void main() {
  group('TextDecorationLayerBinding', () {
    test('seeds range decorations immediately', () {
      final controller = TextAreaController(text: 'TODO one');
      final binding = TextDecorationLayerBinding(
        controller: controller,
        layerKey: 'search',
        buildDecorations: (String text) => text.contains('TODO')
            ? const [
                TextDecorationRange(
                  startOffset: 0,
                  endOffset: 4,
                  styleKey: 'match',
                ),
              ]
            : const [],
      );
      addTearDown(binding.dispose);

      expect(controller.decorationsForLayer('search'), hasLength(1));
    });

    test('updates and clears range decorations as text changes', () {
      final controller = TextAreaController(text: 'TODO one');
      final binding = TextDecorationLayerBinding(
        controller: controller,
        layerKey: 'search',
        buildDecorations: (String text) => text.contains('TODO')
            ? const [
                TextDecorationRange(
                  startOffset: 0,
                  endOffset: 4,
                  styleKey: 'match',
                ),
              ]
            : const [],
      );
      addTearDown(binding.dispose);

      expect(controller.decorationsForLayer('search'), hasLength(1));

      controller.text = 'clean';

      expect(controller.decorationsForLayer('search'), isEmpty);
    });

    test('inactive bindings do not clear externally-managed layers', () {
      final controller = TextAreaController(text: 'TODO one');
      final binding = TextDecorationLayerBinding(
        controller: controller,
        layerKey: 'search',
        buildDecorations: (String text) => text.contains('TODO')
            ? const [
                TextDecorationRange(
                  startOffset: 0,
                  endOffset: 4,
                  styleKey: 'match',
                ),
              ]
            : const [],
        isActive: () => false,
        syncImmediately: false,
      );
      addTearDown(binding.dispose);

      controller.setDecorationLayer('search', const [
        TextDecorationRange(startOffset: 1, endOffset: 3, styleKey: 'external'),
      ]);

      expect(controller.decorationsForLayer('search'), hasLength(1));
      expect(
        controller.decorationsForLayer('search').single.styleKey,
        'external',
      );
    });
  });

  group('TextLineDecorationLayerBinding', () {
    test('seeds whole-line decorations immediately', () {
      final controller = TextAreaController(text: 'TODO one\nok');
      final binding = TextLineDecorationLayerBinding(
        controller: controller,
        layerKey: 'review',
        buildDecorations: (String text) => text.contains('TODO')
            ? const [
                TextLineDecoration(
                  lineIndex: 0,
                  styleKey: 'review.line',
                  lineNumberStyleKey: 'review.number',
                ),
              ]
            : const [],
      );
      addTearDown(binding.dispose);

      expect(controller.lineDecorationsForLayer('review'), hasLength(1));
    });

    test('clear removes managed whole-line decorations', () {
      final controller = TextAreaController(text: 'TODO one\nok');
      final binding = TextLineDecorationLayerBinding(
        controller: controller,
        layerKey: 'review',
        buildDecorations: (String text) => text.contains('TODO')
            ? const [
                TextLineDecoration(
                  lineIndex: 0,
                  styleKey: 'review.line',
                  lineNumberStyleKey: 'review.number',
                ),
              ]
            : const [],
      );
      addTearDown(binding.dispose);

      expect(controller.lineDecorationsForLayer('review'), hasLength(1));

      binding.clear();

      expect(controller.lineDecorationsForLayer('review'), isEmpty);
    });
  });
}
