import 'dart:io';

import 'package:artisanal/markdown.dart';
import 'package:artisanal/src/tui/markdown/ansi_renderer.dart' as legacy;
import 'package:artisanal/src/tui/markdown/backend.dart' as markdown_backend;
import 'package:markdown/markdown.dart' as md;
import 'package:test/test.dart';

void main() {
  group('renderMathInline', () {
    test('maps a digit superscript to unicode', () {
      final result = renderMathInline('x^2');
      expect(result, isA<MathInlineRendered>());
      expect((result as MathInlineRendered).line, contains('x'));
      expect(result.line, contains('²'));
    });

    test('slashes a simple fraction', () {
      final result = renderMathInline(r'\frac{a}{b}');
      expect(result, isA<MathInlineRendered>());
      expect((result as MathInlineRendered).line, contains('/'));
    });

    test('falls back on malformed tex', () {
      final result = renderMathInline(r'\frac{');
      expect(result, isA<MathInlineParseFailed>());
    });
  });

  group('renderMath', () {
    test('lays a fraction on more than one row', () {
      final result = renderMath(r'\frac{a}{b}', displayMode: true);
      expect(result, isA<MathRendered>());
      final fragment = (result as MathRendered).fragment;
      expect(fragment.height, greaterThan(1));
      final pictured = fragment.render();
      expect(pictured, contains('a'));
      expect(pictured, contains('b'));
      fragment.dispose();
    });

    test('reports a parse failure', () {
      final result = renderMath(r'\unknown{x}');
      expect(result, isA<MathParseFailed>());
    });

    test('draws a radical around its radicand', () {
      final result = renderMath(r'\sqrt{x}', displayMode: true);
      expect(result, isA<MathRendered>());
      final fragment = (result as MathRendered).fragment;
      final pictured = fragment.render();
      expect(pictured, contains('x'));
      expect(pictured, contains('┌'));
      fragment.dispose();
    });

    test('stretches parentheses around a fraction', () {
      final result = renderMath(r'\left(\frac{a}{b}\right)', displayMode: true);
      expect(result, isA<MathRendered>());
      final fragment = (result as MathRendered).fragment;
      expect(fragment.height, greaterThan(1));
      final pictured = fragment.render();
      expect(pictured, contains('a'));
      expect(pictured, contains('b'));
      fragment.dispose();
    });

    test('keeps sum limits around the operator', () {
      final result = renderMath(r'\sum_{i=0}^{n} i', displayMode: true);
      expect(result, isA<MathRendered>());
      final fragment = (result as MathRendered).fragment;
      final pictured = fragment.render();
      expect(pictured, contains('n'));
      expect(pictured, contains('i=0'));
      fragment.dispose();
    });

    test('stretchy parens cover the fraction bar', () {
      final result = renderMath(r'\left(\frac{a}{b}\right)', displayMode: true);
      expect(result, isA<MathRendered>());
      final fragment = (result as MathRendered).fragment;
      expect(fragment.height, greaterThanOrEqualTo(3));
      final pictured = fragment.render();
      expect(pictured, contains('a'));
      expect(pictured, contains('─'));
      expect(pictured, contains('b'));
      fragment.dispose();
    });

    test('places a hat above its base', () {
      final result = renderMath(r'\hat{x}', displayMode: true);
      expect(result, isA<MathRendered>());
      final fragment = (result as MathRendered).fragment;
      expect(fragment.height, greaterThan(1));
      expect(fragment.render(), contains('x'));
      fragment.dispose();
    });
  });

  group('markdown math syntax', () {
    test(r'recognizes \(…\) as inline math', () {
      final nodes = markdown_backend.parseMarkdownNodes(r'energy \(E=mc^2\)');
      expect(_hasTag(nodes, 'math'), isTrue);
    });

    test('leaves single-dollar currency literal', () {
      final nodes = markdown_backend.parseMarkdownNodes(r'costs $5 and $10');
      expect(_hasTag(nodes, 'math'), isFalse);
      expect(_flatten(nodes), contains(r'$5'));
    });

    test('recognizes dollar math when the body is not currency', () {
      final nodes = markdown_backend.parseMarkdownNodes(r'energy $E=mc^2$');
      expect(_hasTag(nodes, 'math'), isTrue);
    });

    test(r'recognizes a $$ display block', () {
      final nodes = markdown_backend.parseMarkdownNodes(r'''
$$
\frac{a}{b}
$$
''');
      expect(_hasTag(nodes, 'mathBlock'), isTrue);
    });

    test('does not parse math inside a fence', () {
      final nodes = markdown_backend.parseMarkdownNodes(r'''
```
\(x^2\)
```
''');
      expect(_hasTag(nodes, 'math'), isFalse);
    });

    test('renders inline math in markdownToAnsi', () {
      final out = markdownToAnsi(r'see \(x^2\)');
      expect(out, contains('x'));
      expect(out, contains('²'));
    });

    test('editor math preview file renders scripts and accents', () {
      final md = File(_mathPreviewPath()).readAsStringSync();
      final out = markdownToAnsi(
        md,
        options: const AnsiRendererOptions(width: 40),
      );
      expect(out, contains('E=mc²'));
      expect(out, contains('a²+b²=c²'));
      expect(out, contains('b²'));
      expect(out, isNot(contains('x_^')));
    });

    test('legacy AnsiRenderer uses the shared math plugin', () {
      final nodes = markdown_backend.parseMarkdownNodes(r'see \(x^2\)');
      final out = legacy.AnsiRenderer().render(nodes);
      expect(out, contains('²'));
    });
  });
}

bool _hasTag(List<md.Node> nodes, String tag) {
  for (final node in nodes) {
    if (node is md.Element) {
      if (node.tag == tag) return true;
      if (_hasTag(node.children ?? const [], tag)) return true;
    }
  }
  return false;
}

String _flatten(List<md.Node> nodes) =>
    nodes.map((node) => node.textContent).join();

String _mathPreviewPath() {
  const relative = 'apps/artisanal_editor/examples/math_preview.md';
  for (final path in [relative, '../../$relative']) {
    if (File(path).existsSync()) return path;
  }
  return relative;
}
