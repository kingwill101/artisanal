import 'package:artisanal/artisanal.dart';
import 'package:test/test.dart';

void main() {
  for (final (opener, branch, kind) in [
    ('alt', 'else', SequenceFragmentKind.elsePart),
    ('par', 'and', SequenceFragmentKind.andPart),
    ('critical', 'option', SequenceFragmentKind.optionPart),
  ]) {
    test('nested $branch uses the enclosing $opener depth', () {
      final source =
          '''
sequenceDiagram
loop outer
  $opener inner
    A->>B: first
  $branch fallback
    B-->>A: second
  end
end
''';
      final diagram = parseSequenceDiagram(source)!;
      final fragment = diagram.steps
          .whereType<SequenceStepFragment>()
          .singleWhere((step) => step.fragment.kind == kind)
          .fragment;
      expect(fragment.depth, 1);

      final lines = Style.stripAnsi(
        renderSequenceDiagram(source, maxWidth: 80),
      ).split('\n');
      final opening = lines.singleWhere(
        (line) => line.contains('$opener: inner'),
      );
      final branching = lines.singleWhere(
        (line) => line.contains('$branch: fallback'),
      );
      expect(branching.indexOf('├'), opening.indexOf('├'));
      expect(branching.indexOf('├'), 1);
    });
  }
}
