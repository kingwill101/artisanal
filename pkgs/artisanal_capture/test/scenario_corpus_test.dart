import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:artisanal/markdown.dart';
import 'package:artisanal_capture/artisanal_capture.dart';
import 'package:test/test.dart';

void main() {
  test('all visual fixtures follow marker policy at review widths', () async {
    final library = await Isolate.resolvePackageUri(
      Uri.parse('package:artisanal_capture/artisanal_capture.dart'),
    );
    final directory = Directory.fromUri(
      library!.resolve('../example/scenarios/'),
    );
    final fixtures = await directory
        .list()
        .where(
          (entry) =>
              entry is File &&
              entry.path.endsWith('.md') &&
              !entry.path.endsWith('README.md'),
        )
        .cast<File>()
        .toList();
    expect(fixtures.length, greaterThanOrEqualTo(21));
    for (final file in fixtures) {
      final metadata = File(
        file.path.replaceFirst(RegExp(r'\.md$'), '.source.json'),
      );
      final attributed = await metadata.exists();
      var sdkIssue = false;
      if (attributed) {
        final metadataJson =
            jsonDecode(await metadata.readAsString()) as Map<String, dynamic>;
        expect(metadataJson['sha256'], isA<String>());
        sdkIssue =
            metadataJson['source'] ==
            'https://github.com/dart-lang/sdk/issues/64170';
      }
      final source = await file.readAsString();
      final markers = RegExp(
        r'^END_[A-Z0-9_]+$',
        multiLine: true,
      ).allMatches(source).map((match) => match.group(0)!).toList();
      if (!attributed && !file.path.endsWith('nested_quotes.md')) {
        expect(markers, hasLength(1));
      }
      for (final width in [32, 64, 96]) {
        final ansi = MarkdownRenderer(
          options: AnsiRendererOptions(width: width),
        ).renderToAnsi(source);
        final capture = TerminalCapture.fromAnsi(
          ansi,
          columns: width,
          rows: ansi.split('\n').length,
        );
        final buffer = capture.toBuffer();
        final text = StringBuffer();
        for (var y = 0; y < capture.rows; y++) {
          for (var x = 0; x < capture.columns; x++) {
            text.write(buffer.cellAt(x, y)?.content ?? '');
          }
          text.writeln();
        }
        for (final marker in markers) {
          expect(
            text.toString(),
            contains(marker),
            reason: '${file.path} @ $width',
          );
        }
        if (sdkIssue) {
          expect(
            text.toString(),
            contains('Vectorized search over bytes'),
            reason: '${file.path} @ $width',
          );
          expect(text.toString(), contains('#63821'));
          expect(text.toString(), isNot(contains('Supporting CLs')));
          expect(text.toString(), isNot(contains('-->')));
        }
      }
    }
  });
}
