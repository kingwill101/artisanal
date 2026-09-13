import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:image/image.dart' as img;
import 'package:test/test.dart';

import 'support/font_fixture.dart';

void main() {
  test('real CLI writes styled PNG and an identical HTML image', () async {
    final temp = await Directory.systemTemp.createTemp('native-capture-test-');
    addTearDown(() => temp.delete(recursive: true));
    final font = File('${temp.path}/mono.ttf');
    await font.writeAsBytes(testFontBytes());
    final input = File('${temp.path}/source.ansi');
    await input.writeAsString('\x1b[38;2;255;0;0mA\x1b[0m A');
    final library = await Isolate.resolvePackageUri(
      Uri.parse('package:artisanal_capture/cli.dart'),
    );
    final entry = library!
        .resolve('../bin/artisanal_capture.dart')
        .toFilePath();
    final png = File('${temp.path}/capture.png');
    final html = File('${temp.path}/capture.html');
    final args = [
      'run',
      entry,
      '--no-ansi',
      'render',
      input.path,
      '--input-format',
      'ansi',
      '--columns',
      '3',
      '--font',
      font.path,
      '--font-size',
      '10',
      '--padding',
      '2',
      '--foreground',
      '#ffffff',
    ];
    final pngResult = await Process.run(Platform.resolvedExecutable, [
      ...args,
      '--output',
      png.path,
    ]);
    expect(
      pngResult.exitCode,
      0,
      reason: '${pngResult.stdout}\n${pngResult.stderr}',
    );
    final bytes = await png.readAsBytes();
    final image = img.decodePng(bytes)!;
    expect((image.width, image.height), (22, 14));
    expect(image.getPixel(4, 6).r, 255);
    expect(image.getPixel(4, 6).g, 0);
    expect(image.getPixel(16, 6).g, 255);
    final htmlResult = await Process.run(Platform.resolvedExecutable, [
      ...args,
      '--format',
      'html',
      '--output',
      html.path,
    ]);
    expect(
      htmlResult.exitCode,
      0,
      reason: '${htmlResult.stdout}\n${htmlResult.stderr}',
    );
    expect(await html.readAsString(), contains(base64Encode(bytes)));
  }, timeout: const Timeout(Duration(minutes: 2)));
}
