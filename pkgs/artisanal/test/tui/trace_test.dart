import 'dart:io';

import 'package:artisanal/runtime.dart';
import 'package:test/test.dart';

void main() {
  group('TuiTrace writer', () {
    test(
      'date-based trace path and header can be driven by an injected clock',
      () async {
        final tempDir = await Directory.systemTemp.createTemp('tui-trace-');
        addTearDown(() async {
          await tempDir.delete(recursive: true);
        });

        final fixedTime = DateTime.utc(2026, 3, 29, 9, 10, 11, 123, 456);
        TuiTrace.configureForTest(
          enabled: true,
          baseDirectory: tempDir.path,
          nowProvider: () => fixedTime,
        );
        addTearDown(() {
          TuiTrace.clearTestOverrides();
        });

        TuiTrace.log('hello trace', tag: TraceTag.render);
        TuiTrace.close();

        final traceDir = Directory('${tempDir.path}/traces');
        expect(await traceDir.exists(), isTrue);
        final files = <File>[];
        await for (final entity in traceDir.list()) {
          if (entity is File) {
            files.add(entity);
          }
        }

        expect(files, hasLength(1));
        expect(
          files.single.uri.pathSegments.last,
          equals('artisanal-2026-03-29T09-10-11.log'),
        );

        final lines = await files.single.readAsLines();
        expect(lines, isNotEmpty);
        expect(
          lines.first,
          equals('# trace start: 2026-03-29T09:10:11.123456Z'),
        );
        expect(lines, contains(contains('[render] hello trace')));
      },
    );
  });
}
