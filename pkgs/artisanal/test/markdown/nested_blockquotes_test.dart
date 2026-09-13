import 'package:artisanal/markdown.dart';
import 'package:artisanal/style.dart';
import 'package:artisanal/src/tui/markdown/backend.dart' as backend;
import 'package:test/test.dart';

void main() {
  for (final modern in [false, true]) {
    group(modern ? 'MarkdownRenderer' : 'AnsiRenderer', () {
      String render(String source, {int? width = 32}) {
        final options = AnsiRendererOptions(width: width);
        return Style.stripAnsi(
          modern
              ? MarkdownRenderer(options: options).renderToAnsi(source)
              : AnsiRenderer(options: options)
                    .render(backend.parseMarkdownNodes(source)),
        );
      }

      test('keeps all nested block content inside its quote', () {
        const source = '''
> Outer
>
> > ## Inner heading
> >
> > First paragraph.
> >
> > Second paragraph.
> >
> > ```dart
> > final value = 1;
> > ```
> >
> > | Name | Value |
> > | --- | --- |
> > | a | b |
>
> Outer again

Outside
''';
        final lines = render(source).split('\n');
        final innerStart = lines.indexWhere((line) => line.contains('Inner heading'));
        final innerEnd = lines.indexWhere((line) => line.contains('Outer again'));
        expect(innerStart, greaterThan(0));
        expect(innerEnd, greaterThan(innerStart));
        for (final line in lines.sublist(innerStart, innerEnd)) {
          if (line.trim().isEmpty) continue;
          expect(line, startsWith('│'), reason: 'Escaped quote row: $line');
        }
        expect(lines, contains('Outside'));
        expect(lines.where((line) => line.contains('Inner heading')).single,
            startsWith('│ │ '));
      });

      test('prefixes every wrapped list line without exceeding width', () {
        final lines = render(
          '> > - alpha beta gamma delta epsilon zeta eta theta iota kappa',
          width: 20,
        ).trimRight().split('\n');
        expect(lines.length, greaterThan(2));
        expect(lines.first, startsWith('│ │ • '));
        for (final line in lines) {
          expect(line, startsWith('│ │ '));
          expect(Style.visibleLength(line), lessThanOrEqualTo(20));
        }
      });

      test('hard breaks preserve inline content order', () {
        for (final width in <int?>[null, 20]) {
          final lines = render('> first **bold**  \n> second', width: width)
              .trimRight()
              .split('\n');
          expect(lines, ['│ first bold', '│ second']);
        }
      });

      test('quote inside list stays after the item and before its tail', () {
        final output = render('- Before\n\n  > Quoted\n\n  After\n\n- Next');
        expect(output.indexOf('Before'), lessThan(output.indexOf('Quoted')));
        expect(output.indexOf('Quoted'), lessThan(output.indexOf('After')));
        expect(output.indexOf('After'), lessThan(output.indexOf('Next')));
        expect(output.split('\n'), contains('  │ Quoted'));
      });
    });
  }
}
