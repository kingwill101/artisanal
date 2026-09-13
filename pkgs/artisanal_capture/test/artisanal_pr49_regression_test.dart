import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:artisanal/markdown.dart';
import 'package:artisanal_capture/artisanal_capture.dart';
import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

Future<File> _fixture() async {
  final library = await Isolate.resolvePackageUri(
    Uri.parse('package:artisanal_capture/artisanal_capture.dart'),
  );
  return File.fromUri(
    library!.resolve('../example/scenarios/artisanal_pr49.md'),
  );
}

String _text(TerminalCapture capture) {
  final buffer = capture.toBuffer();
  return [
    for (var y = 0; y < capture.rows; y++)
      [
        for (var x = 0; x < capture.columns; x++)
          buffer.cellAt(x, y)?.content ?? '',
      ].join(),
  ].join('\n');
}

void main() {
  test(
    'PR 49 fixture is attributed and preserves the exact public body',
    () async {
      final file = await _fixture();
      final metadata =
          jsonDecode(
                await File(
                  '${file.parent.path}/artisanal_pr49.source.json',
                ).readAsString(),
              )
              as Map<String, dynamic>;
      expect(metadata['source'], endsWith('/pull/49'));
      expect(metadata['api_source'], endsWith('/pulls/49'));
      expect(
        sha256.convert(await file.readAsBytes()).toString(),
        metadata['sha256'],
      );
      final source = await file.readAsString();
      expect(source, contains('901 tests passed'));
      expect(source, contains('```sh\n'));
      expect(source, isNot(contains('END_PR49')));
    },
  );

  for (final width in [80, 112]) {
    test(
      'fenced verification command follows its prose at $width columns',
      () async {
        final source = await (await _fixture()).readAsString();
        final ansi = MarkdownRenderer(
          options: AnsiRendererOptions(width: width),
        ).renderToAnsi(source);
        final text = _text(
          TerminalCapture.fromAnsi(
            ansi,
            columns: width,
            rows: ansi.split('\n').length,
          ),
        );
        final lines = text.split('\n');
        final prose = lines.indexWhere(
          (line) => line.contains('901 tests passed'),
        );
        final command = lines.indexWhere((line) => line.contains('dart test'));
        final nextItem = lines.indexWhere(
          (line) => line.contains('Targeted dart analyze'),
        );
        expect(prose, greaterThanOrEqualTo(0));
        expect(command, greaterThan(prose));
        expect(nextItem, greaterThan(command));
        final closingBorder = lines
            .sublist(command, nextItem)
            .lastWhere(
              (line) => RegExp(r'[╰└]').hasMatch(line),
              orElse: () => '',
            );
        expect(closingBorder, isNotEmpty);
      },
    );
  }
}
