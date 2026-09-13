import 'dart:convert';
import 'dart:io';

import 'package:artisanal_capture/cli.dart';
import 'package:artisanal_capture/src/cli/gallery_html.dart';
import 'package:image/image.dart' as img;
import 'package:test/test.dart';

import 'support/font_fixture.dart';

void main() {
  late Directory root;
  late Directory input;
  late Directory output;
  late File font;
  late int code;
  late CaptureCommandRunner runner;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('markdown-gallery-test-');
    input = await Directory('${root.path}/input').create();
    output = Directory('${root.path}/output');
    font = File('${root.path}/mono.ttf');
    await font.writeAsBytes(testFontBytes());
    await File('${input.path}/a.md').writeAsString('A');
    code = 0;
    runner = CaptureCommandRunner(
      out: (_) {},
      err: (_) {},
      setExitCode: (value) => code = value,
    );
  });
  tearDown(() => root.delete(recursive: true));

  List<String> arguments() => [
    'gallery',
    input.path,
    '--output',
    output.path,
    '--widths',
    '4,6,4',
    '--font',
    font.path,
    '--font-size',
    '10',
    '--foreground',
    '#ffffff',
  ];
  Future<Map<String, dynamic>> manifest() async =>
      jsonDecode(await File('${output.path}/manifest.json').readAsString())
          as Map<String, dynamic>;

  test(
    'writes a deterministic matrix, evidence, profile, and native PNGs',
    () async {
      await File('${input.path}/README.md').writeAsString('Not a scenario');
      await File('${input.path}/z.md').writeAsString('O');
      await runner.run(arguments());
      expect(code, 0);
      final data = await manifest();
      expect(data['scenarioCount'], 2);
      expect(data['widths'], [4, 6]);
      expect(data['failedRenders'], 0);
      final entries = data['entries'] as List;
      expect(entries.length, 4);
      expect(entries.first['scenario'], 'a.md');
      expect((data['profile'] as Map)['font-size'], '10');
      for (final entry in entries) {
        for (final kind in ['source', 'png', 'html', 'ansi', 'capture']) {
          expect(await File('${output.path}/${entry[kind]}').exists(), isTrue);
        }
        final image = img.decodePng(
          await File('${output.path}/${entry['png']}').readAsBytes(),
        )!;
        expect(image.width, (entry['columns'] as int) * 6);
        expect(image.height, 10);
        expect(image.any((p) => p.r == 255), isTrue);
      }
      final index = await File('${output.path}/index.html').readAsString();
      expect(index, contains('4 width variants'));
      expect(index, contains('a.md'));
      expect(index, contains('manifest.json'));
      expect(index, isNot(contains('<script')));
    },
  );

  test(
    'records strict failures, keeps cell evidence, and continues the matrix',
    () async {
      await File(
        '${input.path}/a.md',
      ).writeAsString('Z'); // Missing font glyph.
      await File('${input.path}/z.md').writeAsString('A');
      await runner.run(arguments());
      expect(code, 1);
      final data = await manifest();
      expect(data['failedRenders'], 2);
      final entries = data['entries'] as List;
      expect(entries.first['error'], contains('missing-glyph'));
      expect(entries.first['png'], isNull);
      expect(entries.first['capture'], isNotNull);
      expect(entries.last['png'], isNotNull);
    },
  );

  test('non-strict mode visibly reports partial images', () async {
    await File('${input.path}/a.md').writeAsString('Z');
    await runner.run([...arguments(), '--no-strict']);
    expect(code, 0);
    final data = await manifest();
    expect(data['flaggedRenders'], 2);
    expect((data['entries'] as List).first['warnings'], isNotEmpty);
    expect(
      await File('${output.path}/index.html').readAsString(),
      contains('Inspect diagnostics'),
    );
  });

  test(
    'flags overflowing output instead of declaring a clipped frame correct',
    () async {
      await File('${input.path}/a.md').writeAsString('# AAAAAAAAAAA');
      await runner.run([...arguments(), '--font-bold', font.path]);
      expect(code, 0);
      final entry = ((await manifest())['entries'] as List).first;
      expect(entry['overflowRows'], isNotEmpty);
      expect((entry['warnings'] as List).join(), contains('clipped'));
    },
  );

  test('matches repeated END markers like String.contains', () async {
    await File(
      '${input.path}/a.md',
    ).writeAsString(List<String>.filled(100, 'END_A').join('\n'));
    final args = arguments();
    args[args.indexOf('--widths') + 1] = '32';
    args.add('--no-strict');
    await runner.run(args);
    final entry = ((await manifest())['entries'] as List).first;
    final warnings = (entry['warnings'] as List).cast<String>();
    expect(warnings.where((warning) => warning.contains('END_A')), isEmpty);
  });

  test('does not overwrite a populated directory without force', () async {
    await output.create();
    final sentinel = File('${output.path}/keep.txt');
    await sentinel.writeAsString('keep');
    await runner.run(arguments());
    expect(code, 64);
    expect(await File('${output.path}/index.html').exists(), isFalse);
    code = 0;
    await runner.run([...arguments(), '--force']);
    expect(code, 0);
    expect(await sentinel.readAsString(), 'keep');
  });

  test(
    'rejects invalid widths and same-directory output before writes',
    () async {
      final args = arguments();
      args[args.indexOf('--widths') + 1] = '0,32';
      await runner.run(args);
      expect(code, 64);
      expect(await output.exists(), isFalse);
      code = 0;
      final same = arguments();
      same[same.indexOf('--output') + 1] = input.path;
      await runner.run([...same, '--force']);
      expect(code, 64);
      expect(await File('${input.path}/a.md').readAsString(), 'A');
    },
  );

  test('escapes untrusted titles and diagnostics in the index', () {
    final html = galleryHtml([
      const GalleryEntry(
        scenario: '<script>alert(1)</script>.md',
        sourceFile: 'source.md',
        stem: 'safe',
        columns: 4,
        rows: null,
        imageWidth: null,
        imageHeight: null,
        hasAnsi: false,
        hasCapture: false,
        warnings: ['<img onerror="bad">'],
        overflowRows: [],
        error: 'bad <input>',
      ),
    ]);
    expect(html, isNot(contains('<script>')));
    expect(html, isNot(contains('<img onerror')));
    expect(html, contains('&lt;input&gt;'));
  });
}
