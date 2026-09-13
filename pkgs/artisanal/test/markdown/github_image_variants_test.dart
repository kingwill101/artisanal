import 'package:artisanal/markdown.dart';
import 'package:artisanal/src/tui/markdown/ansi_renderer.dart' as legacy;
import 'package:artisanal/src/tui/markdown/backend.dart';
import 'package:test/test.dart';

const _lightHref = 'https://example.test/button#gh-light-mode-only';
const _darkHref = 'https://example.test/button-dark#gh-dark-mode-only';
const _image =
    '<img src="https://example.test/button.svg" alt="Review Change Stack">';

String _render(String source, {required bool modern, required bool dark}) {
  final options = AnsiRendererOptions(
    hasDarkBackground: dark,
    hyperlinks: true,
  );
  final nodes = parseMarkdownNodes(source);
  return modern
      ? MarkdownRenderer(options: options).render(nodes)
      : legacy.AnsiRenderer(options: options).render(nodes);
}

void main() {
  for (final modern in [false, true]) {
    test('selects the GitHub light/dark linked image variant ($modern)', () {
      final source =
          '<a href="$_lightHref">$_image</a>'
          '<a href="$_darkHref"><img src="https://example.test/button-dark.svg"'
          ' alt="Review Change Stack"></a>';

      final light = _render(source, modern: modern, dark: false);
      expect(light, contains(_lightHref));
      expect(light, contains('[Image: Review Change Stack]'));
      expect(light, isNot(contains(_darkHref)));
      expect(light, isNot(contains('button-dark.svg')));

      final dark = _render(source, modern: modern, dark: true);
      expect(dark, contains(_darkHref));
      expect(dark, contains('[Image: Review Change Stack]'));
      expect(dark, isNot(contains(_lightHref)));
      expect(dark, isNot(contains('button.svg')));
    });

    test('does not apply mode fragments to ordinary text links ($modern)', () {
      final source = '[link]($_lightHref)';
      final output = _render(source, modern: modern, dark: true);
      expect(output, contains('link'));
      expect(output, contains(_lightHref));
    });

    test('image source mode fragments are selected and stripped for fallback '
        '($modern)', () {
      final source =
          '![light](https://example.test/light.svg#gh-light-mode-only) '
          '![dark](https://example.test/dark.svg#gh-dark-mode-only)';
      final output = _render(source, modern: modern, dark: false);
      expect(output, contains('[Image: light]'));
      expect(output, isNot(contains('[Image: dark]')));
      expect(output, isNot(contains('gh-light-mode-only')));
    });

    test('literal code is not treated as a conditional image ($modern)', () {
      final output = _render(
        '`<a href="$_lightHref">$_image</a>`',
        modern: modern,
        dark: true,
      );
      expect(output, contains(_lightHref));
      expect(output, contains('gh-light-mode-only'));
    });
  }
}
