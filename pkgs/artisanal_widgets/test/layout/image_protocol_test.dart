import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:artisanal_widgets/testing.dart';
import 'package:image/image.dart' as img;
import 'package:test/test.dart';

Uint8List _encodeTestImage() {
  final image = img.Image(width: 4, height: 4);
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      image.setPixelRgba(x, y, x * 50, y * 50, 180, 255);
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() predicate, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final stopwatch = Stopwatch()..start();
  while (stopwatch.elapsed < timeout) {
    tester.pump();
    if (predicate()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Timed out waiting for image render');
}

void main() {
  test('NetworkImage resolves image bytes from an HTTP server', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));

    final bytes = _encodeTestImage();
    server.listen((request) async {
      request.response.headers.contentType = ContentType('image', 'png');
      request.response.add(bytes);
      await request.response.close();
    });

    final provider = w.NetworkImage(
      'http://${server.address.address}:${server.port}/image.png',
    );
    final data = await provider.resolve();

    expect(data.width, 4);
    expect(data.height, 4);
  });

  test('kitty render mode emits Kitty graphics escape sequence', () async {
    final tester = WidgetTester();
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(
      w.Image(
        image: w.MemoryImage(_encodeTestImage()),
        width: 2,
        height: 1,
        renderMode: w.ImageRenderMode.kitty,
      ),
    );

    await _pumpUntil(tester, () => tester.view.contains('\x1b_G'));
    expect(tester.view, contains('\x1b_G'));
  });

  test('iterm2 render mode emits iTerm2 image escape sequence', () async {
    final tester = WidgetTester();
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(
      w.Image(
        image: w.MemoryImage(_encodeTestImage()),
        width: 2,
        height: 1,
        renderMode: w.ImageRenderMode.iterm2,
      ),
    );

    await _pumpUntil(tester, () => tester.view.contains('\x1b]1337;File='));
    expect(tester.view, contains('\x1b]1337;File='));
  });

  test('sixel render mode emits sixel escape sequence', () async {
    final tester = WidgetTester();
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(
      w.Image(
        image: w.MemoryImage(_encodeTestImage()),
        width: 2,
        height: 1,
        renderMode: w.ImageRenderMode.sixel,
      ),
    );

    await _pumpUntil(tester, () => tester.view.contains('\x1bPq'));
    expect(tester.view, contains('\x1bPq'));
  });

  test('unicodeBlocks render mode keeps half-block fallback', () async {
    final tester = WidgetTester();
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(
      w.Image(
        image: w.MemoryImage(_encodeTestImage()),
        width: 2,
        height: 1,
        renderMode: w.ImageRenderMode.unicodeBlocks,
      ),
    );

    await _pumpUntil(tester, () => tester.view.contains('▀'));
    expect(tester.view, contains('▀'));
  });
}
