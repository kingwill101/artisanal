import 'package:artisanal_widgets/editors.dart';
import 'package:artisanal_widgets/widgets.dart' as widgets;
import 'package:test/test.dart';

void main() {
  group('TextPositionDiagnosticsSource', () {
    test('pattern rules seed diagnostics immediately', () {
      final text = widgets.ValueNotifier<String>('TODO one\nok');
      final source = TextPositionDiagnosticsSource.patternRules(
        text: text,
        rules: const [
          TextPatternDiagnosticRule(
            pattern: 'TODO',
            severity: TextDiagnosticSeverity.warning,
            code: 'TODO001',
            wholeWord: true,
          ),
        ],
      );
      addTearDown(source.dispose);

      expect(source.value, hasLength(1));
      expect(source.value.single.code, equals('TODO001'));
      expect(
        source.value.single.severity,
        equals(TextDiagnosticSeverity.warning),
      );
    });

    test('updates diagnostics as the source text changes', () {
      final text = widgets.ValueNotifier<String>('clean');
      final source = TextPositionDiagnosticsSource.patternRules(
        text: text,
        rules: const [
          TextPatternDiagnosticRule(
            pattern: 'FIXME',
            severity: TextDiagnosticSeverity.error,
            code: 'FIX001',
            wholeWord: true,
          ),
        ],
      );
      addTearDown(source.dispose);

      expect(source.value, isEmpty);

      text.value = 'FIXME later';

      expect(source.value, hasLength(1));
      expect(source.value.single.code, equals('FIX001'));
    });

    test('force sync recomputes when external state changes', () {
      final text = widgets.ValueNotifier<String>('TODO one');
      var enabled = true;
      final source = TextPositionDiagnosticsSource(
        text: text,
        buildDiagnostics: (String text) => enabled
            ? textPatternDiagnostics(
                text: text,
                rules: const [
                  TextPatternDiagnosticRule(
                    pattern: 'TODO',
                    severity: TextDiagnosticSeverity.warning,
                    code: 'TODO001',
                    wholeWord: true,
                  ),
                ],
              )
            : const [],
      );
      addTearDown(source.dispose);

      expect(source.value, hasLength(1));

      enabled = false;
      source.sync(force: true);

      expect(source.value, isEmpty);
    });

    test('can swap text sources and resync on the new source', () {
      final first = widgets.ValueNotifier<String>('clean');
      final second = widgets.ValueNotifier<String>('NOTE later');
      final source = TextPositionDiagnosticsSource.patternRules(
        text: first,
        rules: const [
          TextPatternDiagnosticRule(
            pattern: 'NOTE',
            severity: TextDiagnosticSeverity.info,
            code: 'NOTE001',
            wholeWord: true,
          ),
        ],
      );
      addTearDown(source.dispose);

      expect(source.value, isEmpty);

      source.text = second;

      expect(source.value, hasLength(1));
      expect(source.value.single.code, equals('NOTE001'));
    });
  });
}
