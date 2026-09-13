import 'dart:typed_data';

import 'package:artisanal/markdown.dart';
import 'package:artisanal/src/tui/markdown/ansi_renderer.dart' as legacy;
import 'package:artisanal/src/tui/markdown/backend.dart';
import 'package:artisanal/src/tui/markdown/github_html_tags.dart';
import 'package:artisanal/style.dart';
import 'package:image/image.dart' as img;
import 'package:test/test.dart';

String _render(
  String source, {
  required bool modern,
  int? width,
  Map<String, Uint8List> images = const {},
}) {
  final options = AnsiRendererOptions(
    width: width,
    renderImages: true,
    imageProtocol: ImageProtocol.kitty,
    imageMaxWidth: 2,
    imageMaxHeight: 1,
  );
  final nodes = parseMarkdownNodes(source);
  if (modern) {
    return MarkdownRenderer(options: options).render(nodes, imageCache: images);
  }
  final renderer = legacy.AnsiRenderer(options: options);
  renderer.imageCache.addAll(images);
  return renderer.render(nodes);
}

void main() {
  for (final modern in [false, true]) {
    for (final width in <int?>[null, 48]) {
      for (final cached in [false, true]) {
        test(
          'inline list image keeps order: modern $modern width $width cached $cached',
          () {
            final bytes = Uint8List.fromList(
              img.encodePng(
                img.Image(width: 1, height: 1)..setPixelRgb(0, 0, 255, 0, 0),
              ),
            );
            final rendered = _render(
              '- BEFORE ![NEEDLE](https://example.test/pixel.png) AFTER',
              modern: modern,
              width: width,
              images: cached
                  ? {'https://example.test/pixel.png': bytes}
                  : const {},
            );
            final marker = cached ? '\x1b_G' : '[Image: NEEDLE]';
            expect(
              rendered.indexOf(marker),
              greaterThan(rendered.indexOf('BEFORE')),
            );
            expect(
              rendered.indexOf('AFTER'),
              greaterThan(rendered.indexOf(marker)),
            );
          },
        );
      }
    }

    for (final width in [0, -3]) {
      test('blockquote accepts nonpositive width $width, modern $modern', () {
        final text = Style.stripAnsi(
          _render(
            '> alpha beta\n>\n>> gamma delta',
            modern: modern,
            width: width,
          ),
        );
        expect(text, contains('│ alpha beta'));
        expect(text, contains('│ │ gamma delta'));
      });
    }

    test('nested quotes preserve preloaded images, modern $modern', () {
      final pixels = img.Image(width: 1, height: 1)
        ..setPixelRgb(0, 0, 255, 0, 0);
      final bytes = Uint8List.fromList(img.encodePng(pixels));
      final rendered = _render(
        '>> ![cached](https://example.test/pixel.png)',
        modern: modern,
        images: {'https://example.test/pixel.png': bytes},
      );
      expect(rendered, contains('\x1b_G'));
    });

    for (final child in [
      '   | H |\n   | --- |\n   | cell |',
      '   > quote',
      '   - nested',
    ]) {
      test('unbounded list resumes after $child, modern $modern', () {
        final text = Style.stripAnsi(
          _render('1. BEFORE\n\n$child\n\n   AFTER\n', modern: modern),
        );
        expect(text.split('\n'), contains('   AFTER'), reason: text);
        expect(text.indexOf('AFTER'), greaterThan(text.indexOf('BEFORE')));
      });
    }
  }

  test(
    'opaque HTML scanning preserves offsets after many adjacent elements',
    () {
      final prefix = [
        for (var i = 0; i < 500; i++)
          for (final tag in ['code', 'pre', 'style', 'script', 'textarea'])
            '<$tag><details>literal</details></${tag.toUpperCase()} >',
      ].join();
      const visible = '<details><summary>Real</summary>Body</details>';
      final tags = githubHtmlTags('$prefix$visible').toList();
      expect(tags.map((tag) => tag.group(1)), [
        'details',
        'summary',
        'summary',
        'details',
      ]);
      expect(tags.first.start, prefix.length);
      expect(tags.last.end, prefix.length + visible.length);
    },
  );
}
