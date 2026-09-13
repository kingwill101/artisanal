import 'package:artisanal/src/tui/markdown/ansi_renderer.dart' as legacy;
import 'package:artisanal/src/tui/markdown/backend.dart';
import 'package:artisanal/src/tui/markdown/options.dart';
import 'package:artisanal/src/tui/markdown/renderer.dart' as modern;
import 'package:test/test.dart';

void main() {
  for (final modernRenderer in [false, true]) {
    test('custom block text preserves source characters ($modernRenderer)', () {
      const code =
          'sequenceDiagram\n'
          '  A->>B: a < b & c\n'
          '  B-->>A: literal &gt; and &amp;\n';
      String? received;
      final options = AnsiRendererOptions(
        blockHandlers: [
          (context) {
            if (context.tag != 'pre') return null;
            expect(context.language, 'mermaid');
            received = context.text;
            return 'diagram handled\n';
          },
        ],
      );
      final nodes = parseMarkdownNodes('```mermaid\n$code```\n\nAfter');
      final rendered = modernRenderer
          ? modern.MarkdownRenderer(options: options).render(nodes)
          : legacy.AnsiRenderer(options: options).render(nodes);

      expect(received, code);
      expect(rendered, contains('diagram handled'));
      expect(rendered, contains('After'));
    });
  }
}
