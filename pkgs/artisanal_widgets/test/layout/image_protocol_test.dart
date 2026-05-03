import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal/uv.dart' as uv;
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

List<int> _kittyDisplayLineIndexes(String view) {
  final lines = view.split('\n');
  return [
    for (var i = 0; i < lines.length; i++)
      if (lines[i].contains('\x1b_Ga=T')) i,
  ];
}

w.Widget _scrollProbeCard(String label, Uint8List bytes) {
  return w.Frame(
    child: w.Row(
      crossAxisAlignment: w.CrossAxisAlignment.start,
      gap: 1,
      children: [
        w.Image(
          image: w.MemoryImage(bytes),
          width: 8,
          height: 4,
          fit: w.BoxFit.cover,
          renderMode: w.ImageRenderMode.kitty,
        ),
        w.Column(
          crossAxisAlignment: w.CrossAxisAlignment.start,
          children: [
            w.Text('$label title'),
            w.Text('$label line 1'),
            w.Text('$label line 2'),
            w.Text('$label line 3'),
          ],
        ),
      ],
    ),
  );
}

void main() {
  test('NetworkImage resolves image bytes from an HTTP server', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));

    final bytes = _encodeTestImage();
    String? userAgent;
    server.listen((request) async {
      userAgent = request.headers.value(HttpHeaders.userAgentHeader);
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
    expect(userAgent, contains('artisanal-widgets-image'));
  });

  test('NetworkImage reuses cached data for the same URL', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));

    final bytes = _encodeTestImage();
    var requestCount = 0;
    server.listen((request) async {
      requestCount++;
      request.response.headers.contentType = ContentType('image', 'png');
      request.response.add(bytes);
      await request.response.close();
    });

    final url =
        'http://${server.address.address}:${server.port}/cached-image.png';
    final first = await w.NetworkImage(url).resolve();
    final second = await w.NetworkImage(url).resolve();

    expect(requestCount, 1);
    expect(identical(first, second), isTrue);
  });

  test('NetworkImage coalesces concurrent resolves for the same URL', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));

    final bytes = _encodeTestImage();
    var requestCount = 0;
    final firstRequestSeen = Completer<void>();
    final releaseResponse = Completer<void>();
    server.listen((request) async {
      requestCount++;
      if (!firstRequestSeen.isCompleted) {
        firstRequestSeen.complete();
      }
      await releaseResponse.future;
      request.response.headers.contentType = ContentType('image', 'png');
      request.response.add(bytes);
      await request.response.close();
    });

    final url =
        'http://${server.address.address}:${server.port}/coalesced-image.png';
    final firstFuture = w.NetworkImage(url).resolve();
    final secondFuture = w.NetworkImage(url).resolve();

    await firstRequestSeen.future;
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(requestCount, 1);

    releaseResponse.complete();
    final resolved = await Future.wait([firstFuture, secondFuture]);

    expect(requestCount, 1);
    expect(identical(resolved[0], resolved[1]), isTrue);
  });

  test('NetworkImage cache key keeps request headers distinct', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));

    final bytes = _encodeTestImage();
    final seenHeaders = <String>[];
    server.listen((request) async {
      seenHeaders.add(request.headers.value('x-test-header') ?? '');
      request.response.headers.contentType = ContentType('image', 'png');
      request.response.add(bytes);
      await request.response.close();
    });

    final url =
        'http://${server.address.address}:${server.port}/header-image.png';
    await w.NetworkImage(url, headers: {'x-test-header': 'first'}).resolve();
    await w.NetworkImage(url, headers: {'x-test-header': 'second'}).resolve();

    expect(seenHeaders, equals(<String>['first', 'second']));
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
    expect(tester.view, contains('C=1'));
    expect(tester.view, contains('\x1b_Ga=d,d=I,i='));

    final ids = RegExp(
      r'\x1b_Ga=(?:d|T)[^;\x1b]*i=(\d+)',
    ).allMatches(tester.view).map((match) => match.group(1)).toSet();
    expect(ids, hasLength(1));
  });

  test('image render cache invalidates when target size changes', () async {
    final tester = WidgetTester();
    addTearDown(() => tester.dispose());

    final bytes = _encodeTestImage();
    await tester.pumpWidget(
      w.Image(
        image: w.MemoryImage(bytes),
        width: 2,
        height: 1,
        fit: w.BoxFit.fill,
        renderMode: w.ImageRenderMode.kitty,
      ),
    );

    await _pumpUntil(tester, () => tester.view.contains('c=2'));
    final firstView = tester.view;
    expect(firstView, contains('c=2'));

    await tester.pumpWidget(
      w.Image(
        image: w.MemoryImage(bytes),
        width: 3,
        height: 1,
        fit: w.BoxFit.fill,
        renderMode: w.ImageRenderMode.kitty,
      ),
    );

    await _pumpUntil(tester, () => tester.view.contains('c=3'));
    expect(tester.view, contains('c=3'));
    expect(tester.view, isNot(equals(firstView)));
  });

  test('container preserves Kitty image payloads from child images', () async {
    final tester = WidgetTester();
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(
      w.Container(
        width: 8,
        height: 4,
        child: w.Image(
          image: w.MemoryImage(_encodeTestImage()),
          width: 8,
          height: 4,
          renderMode: w.ImageRenderMode.kitty,
        ),
      ),
    );

    await _pumpUntil(tester, () => tester.view.contains('\x1b_G'));
    expect(tester.view, contains('\x1b_Ga=T'));
    expect(tester.view, contains('C=1'));
  });

  test(
    'Kitty image reserves width on every row in horizontal layout',
    () async {
      final tester = WidgetTester(screenWidth: 20, screenHeight: 8);
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Row(
          children: [
            w.Image(
              image: w.MemoryImage(_encodeTestImage()),
              width: 4,
              height: 4,
              renderMode: w.ImageRenderMode.kitty,
            ),
            w.Text('A\nB\nC\nD'),
          ],
        ),
      );

      await _pumpUntil(tester, () => tester.view.contains('\x1b_G'));

      final screen = uv.ScreenBuffer(20, 8);
      final ss = uv.StyledString(tester.view)..wrap = true;
      ss.draw(screen, screen.bounds());

      int findColumn(String content, int row) {
        for (var x = 0; x < 20; x++) {
          if (screen.cellAt(x, row)?.content == content) return x;
        }
        return -1;
      }

      final aX = findColumn('A', 0);
      final bX = findColumn('B', 1);
      final cX = findColumn('C', 2);
      final dX = findColumn('D', 3);

      expect(aX, greaterThan(0));
      expect(bX, equals(aX));
      expect(cX, equals(aX));
      expect(dX, equals(aX));
    },
  );

  test('ScrollArea suppresses Kitty displays that would overflow', () async {
    final tester = WidgetTester(screenWidth: 60, screenHeight: 10);
    final controller = w.WidgetScrollController();
    addTearDown(() => tester.dispose());

    final bytes = _encodeTestImage();
    await tester.pumpWidget(
      w.ScrollArea(
        controller: controller,
        height: 6,
        showScrollbar: false,
        child: w.Column(
          crossAxisAlignment: w.CrossAxisAlignment.stretch,
          gap: 1,
          children: [
            _scrollProbeCard('first', bytes),
            _scrollProbeCard('second', bytes),
          ],
        ),
      ),
    );

    await _pumpUntil(tester, () => tester.view.contains('\x1b_Ga=T'));

    expect(_kittyDisplayLineIndexes(tester.view), equals(<int>[0]));

    controller.jumpTo(3);
    tester.pump();

    expect(_kittyDisplayLineIndexes(tester.view), equals(<int>[2]));
  });

  test(
    'Sixel image reserves width on every row in horizontal layout',
    () async {
      final tester = WidgetTester(screenWidth: 20, screenHeight: 8);
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Row(
          children: [
            w.Image(
              image: w.MemoryImage(_encodeTestImage()),
              width: 4,
              height: 4,
              renderMode: w.ImageRenderMode.sixel,
            ),
            w.Text('A\nB\nC\nD'),
          ],
        ),
      );

      await _pumpUntil(tester, () => tester.view.contains('\x1bPq'));

      final screen = uv.ScreenBuffer(20, 8);
      final ss = uv.StyledString(tester.view)..wrap = true;
      ss.draw(screen, screen.bounds());

      int findColumn(String content, int row) {
        for (var x = 0; x < 20; x++) {
          if (screen.cellAt(x, row)?.content == content) return x;
        }
        return -1;
      }

      final aX = findColumn('A', 0);
      final bX = findColumn('B', 1);
      final cX = findColumn('C', 2);
      final dX = findColumn('D', 3);

      expect(aX, greaterThan(0));
      expect(bX, equals(aX));
      expect(cX, equals(aX));
      expect(dX, equals(aX));
    },
  );

  test('sixel render mode honors configured cell pixel size', () async {
    final tester = WidgetTester(screenWidth: 20, screenHeight: 8);
    addTearDown(() => tester.dispose());

    await w.withImageAutoConfiguration(
      mode: w.ImageAutoMode.environment,
      cellPixelWidth: 2,
      cellPixelHeight: 3,
      callback: () async {
        await tester.pumpWidget(
          w.Image(
            image: w.MemoryImage(_encodeTestImage()),
            width: 4,
            height: 4,
            renderMode: w.ImageRenderMode.sixel,
          ),
        );

        await _pumpUntil(tester, () => tester.view.contains('\x1bPq'));
        expect(tester.view, contains('"1;1;8;6'));
      },
    );
  });

  test(
    'sixel render mode avoids upscaling without cell pixel reports',
    () async {
      final tester = WidgetTester(screenWidth: 20, screenHeight: 8);
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.Image(
          image: w.MemoryImage(_encodeTestImage()),
          width: 4,
          height: 4,
          renderMode: w.ImageRenderMode.sixel,
        ),
      );

      await _pumpUntil(tester, () => tester.view.contains('\x1bPq'));
      expect(tester.view, contains('"1;1;4;4'));
    },
  );

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

  test('auto render mode can be scoped to portable fallback', () async {
    final tester = WidgetTester();
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(
      w.Image(
        image: w.MemoryImage(_encodeTestImage()),
        width: 2,
        height: 1,
        renderMode: w.ImageRenderMode.auto,
      ),
      imageAutoMode: w.ImageAutoMode.portableFallback,
    );

    await _pumpUntil(tester, () => tester.view.contains('▀'));
    expect(tester.view, contains('▀'));
    expect(tester.view, isNot(contains('\x1b_G')));
    expect(tester.view, isNot(contains('\x1b]1337;File=')));
    expect(tester.view, isNot(contains('\x1bPq')));
  });

  test('WidgetTester defaults auto render mode to portable fallback', () async {
    final tester = WidgetTester();
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(
      w.Image(
        image: w.MemoryImage(_encodeTestImage()),
        width: 2,
        height: 1,
        renderMode: w.ImageRenderMode.auto,
      ),
    );

    await _pumpUntil(tester, () => tester.view.contains('▀'));
    expect(tester.view, contains('▀'));
    expect(tester.view, isNot(contains('\x1b_G')));
    expect(tester.view, isNot(contains('\x1b]1337;File=')));
    expect(tester.view, isNot(contains('\x1bPq')));
  });

  test('auto render mode can follow session terminal version hints', () async {
    final tester = WidgetTester();
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(
      w.Image(
        image: w.MemoryImage(_encodeTestImage()),
        width: 2,
        height: 1,
        renderMode: w.ImageRenderMode.auto,
      ),
      imageAutoMode: w.ImageAutoMode.sessionCapabilities,
    );

    tester.sendMsg(const tui.TerminalVersionMsg('xterm-kitty 0.40.0'));
    await _pumpUntil(tester, () => tester.view.contains('\x1b_G'));
    expect(tester.view, contains('\x1b_G'));
  });

  test('auto render mode can follow session device attribute hints', () async {
    final tester = WidgetTester();
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(
      w.Image(
        image: w.MemoryImage(_encodeTestImage()),
        width: 2,
        height: 1,
        renderMode: w.ImageRenderMode.auto,
      ),
      imageAutoMode: w.ImageAutoMode.sessionCapabilities,
    );

    tester.sendMsg(const tui.PrimaryDeviceAttributesMsg([1, 4, 18]));
    await _pumpUntil(tester, () => tester.view.contains('\x1bPq'));
    expect(tester.view, contains('\x1bPq'));
  });
}
