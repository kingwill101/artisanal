import 'package:artisanal/markdown.dart';
import 'package:test/test.dart';

void main() {
  group('display goldens', () {
    test('fraction', () {
      expect(_picture(r'\frac{a}{b}'), 'a\n─\nb');
    });

    test('square root', () {
      expect(_picture(r'\sqrt{x}'), ' ┌─\n╲│x');
    });

    test('stretchy parens', () {
      expect(_picture(r'\left(\frac{a}{b}\right)'), '⎛a⎞\n⎜─⎟\n⎝b⎠');
    });

    test('boxed', () {
      expect(_picture(r'\boxed{x}'), '┌───┐\n│ x │\n└───┘');
    });

    test('hat', () {
      expect(_picture(r'\hat{x}'), '^\nx');
    });

    test('compact display scripts stay on one row', () {
      expect(_picture('x^2'), 'x²');
    });

    test('limit sits on the fraction baseline', () {
      final pictured = _picture(r'\lim_{x \to 0} \frac{\sin x}{x}');
      final lines = pictured.split('\n');
      expect(pictured, contains('sin'), reason: pictured);
      expect(pictured, contains('lim'), reason: pictured);
      expect(lines.length, greaterThanOrEqualTo(3), reason: pictured);
    });

    test('quadratic fraction bar spans the numerator', () {
      final pictured = _picture(r'\frac{-b \pm \sqrt{b^2 - 4ac}}{2a}');
      expect(pictured, contains('b²'));
      expect(pictured, contains('2a'));
      final bar = pictured.split('\n').firstWhere((line) => line.contains('─'));
      expect(bar.trim().length, greaterThan(6), reason: pictured);
    });
  });

  group('inline goldens', () {
    test('script', () {
      expect(_inline('x^2'), 'x²');
    });

    test('braced multi-digit scripts follow TeX grouping', () {
      expect(_inline('x^{22}'), 'x²²');
      expect(_inline('a_{10}'), 'a₁₀');
      // Unbraced `x^22` is TeX for (x^2)2, not x^{22}.
      expect(_inline('x^22'), 'x²2');
    });

    test('fraction', () {
      expect(_inline(r'\frac{a}{b}'), 'a/b');
    });

    test('sqrt', () {
      expect(_inline(r'\sqrt{x}'), '√x');
    });

    test('hat', () {
      expect(_inline(r'\hat{x}'), contains('x'));
      expect(_inline(r'\hat{x}'), isNot(contains('x_^')));
    });

    test('boxed', () {
      expect(_inline(r'\boxed{x}'), '[x]');
    });
  });

  test('unclosed inline math does not swallow the rest of a document', () {
    final out = markdownToAnsi(r'''
pending \(E=mc

# Still here
''');
    expect(out, contains('Still here'));
    expect(out, isNot(contains('…')));
  });

  test('unclosed display math does not swallow later headings', () {
    final out = markdownToAnsi(r'''
$$
\frac{a}{b}

# After
''');
    expect(out, contains('After'));
  });
}

String _picture(String tex) {
  final result = renderMath(tex, displayMode: true);
  expect(result, isA<MathRendered>());
  final fragment = (result as MathRendered).fragment;
  final pictured = fragment.render();
  fragment.dispose();
  return pictured;
}

String _inline(String tex) {
  final result = renderMathInline(tex);
  expect(result, isA<MathInlineRendered>());
  return (result as MathInlineRendered).line;
}
