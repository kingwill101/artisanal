import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:artisanal/markdown.dart';
import 'package:artisanal_capture/artisanal_capture.dart';
import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

Future<File> _fixture(String name) async {
  final library = await Isolate.resolvePackageUri(
    Uri.parse('package:artisanal_capture/artisanal_capture.dart'),
  );
  return File.fromUri(library!.resolve('../example/scenarios/$name'));
}

String _capturedText(TerminalCapture capture) {
  final buffer = capture.toBuffer();
  final text = StringBuffer();
  for (var y = 0; y < capture.rows; y++) {
    for (var x = 0; x < capture.columns; x++) {
      text.write(buffer.cellAt(x, y)?.content ?? '');
    }
    text.writeln();
  }
  return text.toString();
}

void main() {
  test(
    'matches the attributed GitHub issue and keeps its external shape',
    () async {
      final file = await _fixture('dart_sdk_64170.md');
      final metadata =
          jsonDecode(
                await File(
                  '${file.parent.path}/dart_sdk_64170.source.json',
                ).readAsString(),
              )
              as Map<String, dynamic>;
      final source = await file.readAsString();
      expect(
        sha256.convert(await file.readAsBytes()).toString(),
        metadata['sha256'],
      );

      expect(metadata['issue_id'], 5292087450);
      expect(
        metadata['source'],
        'https://github.com/dart-lang/sdk/issues/64170',
      );
      expect(metadata['title'], 'SIMD tracking issue.');
      expect(metadata['author'], 'modulovalue');
      expect(metadata['updated_at'], '2026-09-12T14:41:21Z');
      expect(metadata['normalization']['line_endings'], 'LF');
      expect(source, contains('## [`Int32x4`]'));
      expect(source, contains('## [`Float32x4`]'));
      expect(source, contains('## [`Float64x2`]'));
      expect(source, contains('## Use cases'));
      expect(source, contains('Optimal 4x4 matrix multiplication: #64238'));
      expect(source, contains('<!--\n<details>'));
      expect(source, contains('<summary><b>Supporting CLs</b></summary>'));
      expect(source, contains('</details>\n-->'));
      expect(source, contains(r'`\|`'));
      expect(source, contains('Int32x4/operator_bitwise_or.html'));
      expect(
        RegExp(r'^\| Operation \|', multiLine: true).allMatches(source),
        hasLength(3),
      );
      expect(
        source.split('\n').where((line) => line.startsWith('| ')).length,
        111,
      );
    },
  );

  test(
    'renders all review widths without losing cells, links, styles, or tail',
    () async {
      final source = await (await _fixture('dart_sdk_64170.md')).readAsString();
      for (final width in [32, 64, 80, 96, 120]) {
        final ansi = MarkdownRenderer(
          options: AnsiRendererOptions(width: width),
        ).renderToAnsi(source);
        final capture = TerminalCapture.fromAnsi(
          ansi,
          columns: width,
          rows: ansi.split('\n').length,
        );
        final buffer = capture.toBuffer();
        final text = _capturedText(capture);

        expect(text, contains('Int32x4'));
        expect(text, contains('Float32x4'));
        expect(text, contains('Float64x2'));
        expect(text, contains('Third-party blockers'));
        expect(text, contains('Use cases'));
        expect(text, contains('Optimal 4x4 matrix'));
        expect(text, contains('#64238'));
        expect(text, isNot(contains('Supporting CLs')));
        expect(text, isNot(contains('<!--')));
        expect(text, isNot(contains('-->')));
        expect(
          text,
          contains('Vectorized search over bytes'),
          reason: 'tail was truncated at width $width',
        );
        expect(text, contains('#63821'));

        final cells = [
          for (var y = 0; y < capture.rows; y++)
            for (var x = 0; x < capture.columns; x++) buffer.cellAt(x, y)!,
        ];
        expect(cells.any((cell) => cell.link.url.contains('dart.dev')), isTrue);
        expect(cells.any((cell) => cell.style.attrs != 0), isTrue);
        for (final status in ['✅', '🚧', '❓']) {
          expect(
            cells.where((cell) => cell.content == status).length,
            RegExp(RegExp.escape(status)).allMatches(source).length,
            reason: 'status count changed for $status at width $width',
          );
        }
        expect(
          cells.any(
            (cell) =>
                cell.link.url.contains('Int32x4/operator_bitwise_or.html'),
          ),
          isTrue,
        );
        expect(
          cells.any((cell) => cell.link.url.endsWith('/543040/1')),
          isFalse,
          reason: 'Links inside the Supporting CLs comment must remain hidden.',
        );
      }
    },
  );
}
