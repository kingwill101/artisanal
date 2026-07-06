import 'package:artisanal_widgets/editors.dart';
import 'package:artisanal_widgets/artisanal_widgets.dart' as widgets;
import 'package:test/test.dart';

void main() {
  group('TextDiagnosticsBinding', () {
    test('pattern rules seed diagnostics immediately', () {
      final controller = TextAreaController(text: 'TODO one\nok');
      final binding = TextDiagnosticsBinding.patternRules(
        controller: controller,
        rules: const [
          TextPatternDiagnosticRule(
            pattern: 'TODO',
            severity: TextDiagnosticSeverity.warning,
            code: 'TODO001',
            wholeWord: true,
          ),
        ],
      );
      addTearDown(binding.dispose);

      expect(controller.diagnostics, hasLength(1));
      expect(controller.diagnostics.single.code, equals('TODO001'));
      expect(
        controller.diagnostics.single.severity,
        equals(TextDiagnosticSeverity.warning),
      );
    });

    test('updates diagnostics as controller text changes', () {
      final controller = TextAreaController(text: 'clean');
      final binding = TextDiagnosticsBinding.patternRules(
        controller: controller,
        rules: const [
          TextPatternDiagnosticRule(
            pattern: 'FIXME',
            severity: TextDiagnosticSeverity.error,
            code: 'FIX001',
            wholeWord: true,
          ),
        ],
      );
      addTearDown(binding.dispose);

      expect(controller.diagnostics, isEmpty);

      controller.text = 'FIXME later';

      expect(controller.diagnostics, hasLength(1));
      expect(controller.diagnostics.single.code, equals('FIX001'));
      expect(
        controller.diagnostics.single.severity,
        equals(TextDiagnosticSeverity.error),
      );
    });

    test('clear removes managed diagnostics for the current text', () {
      final controller = TextAreaController(text: 'NOTE later');
      final binding = TextDiagnosticsBinding.patternRules(
        controller: controller,
        rules: const [
          TextPatternDiagnosticRule(
            pattern: 'NOTE',
            severity: TextDiagnosticSeverity.info,
            code: 'NOTE001',
            wholeWord: true,
          ),
        ],
      );
      addTearDown(binding.dispose);

      expect(controller.diagnostics, hasLength(1));

      binding.clear();

      expect(controller.diagnostics, isEmpty);
    });

    test('dispose detaches the binding from future controller edits', () {
      final controller = TextAreaController(text: 'TODO one');
      final binding = TextDiagnosticsBinding.patternRules(
        controller: controller,
        rules: const [
          TextPatternDiagnosticRule(
            pattern: 'TODO',
            severity: TextDiagnosticSeverity.warning,
            code: 'TODO001',
            wholeWord: true,
          ),
        ],
      );

      expect(controller.diagnostics, hasLength(1));

      binding.dispose();
      controller.text = 'clean';

      expect(controller.diagnostics, hasLength(1));
      expect(controller.diagnostics.single.code, equals('TODO001'));
    });

    test('can swap controllers and resync on the new target', () {
      final first = TextAreaController(text: 'TODO first');
      final second = TextAreaController(text: 'FIXME second');
      final binding = TextDiagnosticsBinding(
        controller: first,
        buildDiagnostics: (String text) => text.contains('FIXME')
            ? const [
                TextPositionDiagnosticRange(
                  startLine: 0,
                  startColumn: 0,
                  endLine: 0,
                  endColumn: 5,
                  severity: TextDiagnosticSeverity.error,
                  code: 'FIX001',
                ),
              ]
            : const [],
      );
      addTearDown(binding.dispose);

      expect(first.diagnostics, isEmpty);

      binding.controller = second;

      expect(second.diagnostics, hasLength(1));
      expect(second.diagnostics.single.code, equals('FIX001'));
    });

    test('syncs directly from external range diagnostics', () {
      final controller = TextAreaController(text: 'alpha');
      final source = widgets.ValueNotifier<Iterable<TextDiagnosticRange>>(
        const [],
      );
      final binding = TextDiagnosticsBinding.fromRangeListenable(
        controller: controller,
        diagnostics: source,
      );
      addTearDown(binding.dispose);

      expect(controller.diagnostics, isEmpty);

      source.value = const [
        TextDiagnosticRange(
          startOffset: 1,
          endOffset: 4,
          severity: TextDiagnosticSeverity.error,
          code: 'EXT001',
        ),
      ];

      expect(controller.diagnostics, hasLength(1));
      expect(controller.diagnostics.single.code, equals('EXT001'));
      expect(
        controller.diagnostics.single.severity,
        equals(TextDiagnosticSeverity.error),
      );
    });

    test('syncs directly from external positional diagnostics', () {
      final controller = TextAreaController(text: 'alpha\nbeta');
      final source =
          widgets.ValueNotifier<Iterable<TextPositionDiagnosticRange>>(
            const [],
          );
      final binding = TextDiagnosticsBinding.fromPositionListenable(
        controller: controller,
        diagnostics: source,
      );
      addTearDown(binding.dispose);

      source.value = const [
        TextPositionDiagnosticRange(
          startLine: 1,
          startColumn: 1,
          endLine: 1,
          endColumn: 3,
          severity: TextDiagnosticSeverity.warning,
          code: 'POS001',
        ),
      ];

      expect(controller.diagnostics, hasLength(1));
      expect(controller.diagnostics.single.code, equals('POS001'));
      expect(controller.diagnostics.single.startOffset, equals(7));
      expect(controller.diagnostics.single.endOffset, equals(9));
    });
  });
}
