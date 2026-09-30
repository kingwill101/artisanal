import 'dart:io';
import 'dart:typed_data';

import 'package:artisanal_widgets/widgets.dart' as widgets;
import 'package:image/image.dart' as image;
import 'package:test/test.dart';

void main() {
  final bytes = Uint8List.fromList(
    image.encodePng(image.Image(width: 2, height: 2)),
  );
  Matcher tooLarge(int limit) => isA<widgets.ImageByteLimitException>()
      .having((error) => error.maximumBytes, 'maximumBytes', limit)
      .having(
        (error) => error.observedBytes,
        'observedBytes',
        greaterThan(limit),
      );

  test('memory rejects oversized invalid data before decoding', () async {
    await expectLater(
      widgets.MemoryImage(Uint8List(64), maximumBytes: 8).resolve(),
      throwsA(tooLarge(8)),
    );
    final decoded = await widgets.MemoryImage(
      bytes,
      maximumBytes: bytes.length,
    ).resolve();
    expect(decoded.width, 2);
    expect(decoded.height, 2);
  });

  test(
    'file loading rejects oversized content and accepts an exact budget',
    () async {
      final directory = await Directory.systemTemp.createTemp('image-budget-');
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/image.png');
      await file.writeAsBytes(bytes);
      await expectLater(
        widgets.FileImage(file.path, maximumBytes: bytes.length - 1).resolve(),
        throwsA(tooLarge(bytes.length - 1)),
      );
      expect(
        (await widgets.FileImage(
          file.path,
          maximumBytes: bytes.length,
        ).resolve()).width,
        2,
      );
      final oversized = await file.open(mode: FileMode.write);
      await oversized.truncate(2 * 1024 * 1024);
      await oversized.close();
      await expectLater(
        widgets.FileImage(file.path, maximumBytes: 8).resolve(),
        throwsA(tooLarge(8)),
      );
    },
  );

  test('invalid budgets fail before filesystem or network access', () async {
    for (final provider in <widgets.ImageProvider>[
      widgets.MemoryImage(bytes, maximumBytes: -1),
      const widgets.FileImage('missing-image', maximumBytes: -1),
      const widgets.NetworkImage('not-a-url', maximumBytes: -1),
    ]) {
      await expectLater(provider.resolve(), throwsArgumentError);
    }
  });

  test('file and memory provider identity includes the byte budget', () {
    expect(
      widgets.MemoryImage(bytes, maximumBytes: 8),
      widgets.MemoryImage(bytes, maximumBytes: 8),
    );
    expect(
      widgets.MemoryImage(bytes, maximumBytes: 8),
      isNot(widgets.MemoryImage(bytes)),
    );
    expect(
      const widgets.FileImage('image', maximumBytes: 8),
      const widgets.FileImage('image', maximumBytes: 8),
    );
    expect(
      const widgets.FileImage('image', maximumBytes: 8),
      isNot(const widgets.FileImage('image')),
    );
  });

  test('network cache cannot bypass a stricter byte budget', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    var requests = 0;
    server.listen((request) async {
      requests++;
      request.response.contentLength = bytes.length;
      request.response.add(bytes);
      await request.response.close();
    });
    final url = 'http://127.0.0.1:${server.port}/image';
    final loose = await widgets.NetworkImage(url).resolve();
    await expectLater(
      widgets.NetworkImage(url, maximumBytes: 8).resolve(),
      throwsA(tooLarge(8)),
    );
    expect(await widgets.NetworkImage(url).resolve(), same(loose));
    expect(requests, 2);
  });

  test('chunked responses use the same typed byte-limit failure', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      request.response.bufferOutput = false;
      request.response.add(bytes);
      await request.response.close();
    });
    await expectLater(
      widgets.NetworkImage(
        'http://127.0.0.1:${server.port}/chunked',
        maximumBytes: 8,
      ).resolve(),
      throwsA(tooLarge(8)),
    );
  });
}
