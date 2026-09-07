import 'dart:io';

import 'package:artisanal/tui.dart';
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
        expect(lines, contains(startsWith('# script: ')));
        expect(lines, contains('# capture: disabled'));
        expect(lines, contains('# tags: all'));
        expect(
          lines,
          contains(matches(RegExp(r'^\[\+\d+us\] \[render\] hello trace$'))),
        );
        expect(lines, contains(contains('[render] hello trace')));
      },
    );

    test(
      'reconfiguration resets tag filtering and writes a new header',
      () async {
        final tempDir = await Directory.systemTemp.createTemp('tui-trace-');
        addTearDown(() async {
          TuiTrace.clearTestOverrides();
          await tempDir.delete(recursive: true);
        });
        final firstPath = '${tempDir.path}/first.log';
        final secondPath = '${tempDir.path}/second.log';

        TuiTrace.configureForTest(
          enabled: true,
          path: firstPath,
          tagsRaw: 'render',
        );
        TuiTrace.log('first', tag: TraceTag.render);
        TuiTrace.close();

        TuiTrace.configureForTest(
          enabled: true,
          path: secondPath,
          tagsRaw: 'input',
        );
        TuiTrace.log('second', tag: TraceTag.input);
        TuiTrace.log('filtered', tag: TraceTag.render);
        TuiTrace.close();

        final first = await File(firstPath).readAsLines();
        final second = await File(secondPath).readAsLines();
        expect(first.first, startsWith('# trace start:'));
        expect(second.first, startsWith('# trace start:'));
        expect(first, contains('# tags: render'));
        expect(second, contains('# tags: input'));
        expect(second, contains(contains('[input] second')));
        expect(second, isNot(contains(contains('filtered'))));
      },
    );

    test(
      'clear replaces an existing trace and event uses injected time',
      () async {
        final tempDir = await Directory.systemTemp.createTemp('tui-trace-');
        addTearDown(() async {
          TuiTrace.clearTestOverrides();
          await tempDir.delete(recursive: true);
        });
        final path = '${tempDir.path}/trace.log';
        await File(path).writeAsString('stale\n');
        final now = DateTime.utc(2026, 4, 1, 12, 30);

        TuiTrace.configureForTest(
          enabled: true,
          path: path,
          nowProvider: () => now,
          clear: true,
        );
        TuiTrace.event('test.event', fields: const {'value': 1});
        TuiTrace.close();

        final contents = await File(path).readAsString();
        expect(contents, isNot(contains('stale')));
        final eventLine = contents
            .split('\n')
            .firstWhere((line) => line.contains('@event'));
        final event = TuiTrace.parseEventLine(eventLine);
        expect(event, isNotNull);
        expect(event!.timestampUs, now.microsecondsSinceEpoch);
        expect(event.type, 'test.event');
        expect(event.fields, const {'value': 1});
      },
    );

    test(
      'unsupported event fields are dropped without stopping tracing',
      () async {
        final tempDir = await Directory.systemTemp.createTemp('tui-trace-');
        addTearDown(() async {
          TuiTrace.clearTestOverrides();
          await tempDir.delete(recursive: true);
        });
        final path = '${tempDir.path}/trace.log';
        TuiTrace.configureForTest(enabled: true, path: path);

        expect(
          () => TuiTrace.event('bad.event', fields: {'value': Object()}),
          returnsNormally,
        );
        TuiTrace.log('still active');
        TuiTrace.close();

        final contents = await File(path).readAsString();
        expect(contents, contains('trace event dropped: type=bad.event'));
        expect(contents, contains('[general] still active'));
      },
    );

    test('filesystem failures disable tracing without escaping', () async {
      final tempDir = await Directory.systemTemp.createTemp('tui-trace-');
      addTearDown(() async {
        TuiTrace.clearTestOverrides();
        await tempDir.delete(recursive: true);
      });
      // A directory cannot be opened as the trace output file.
      TuiTrace.configureForTest(enabled: true, path: tempDir.path);

      expect(() => TuiTrace.log('cannot be written'), returnsNormally);
      expect(TuiTrace.enabled, isFalse);
      expect(() => TuiTrace.log('does not retry'), returnsNormally);
    });

    test('an allow-list with no valid tags fails closed', () async {
      final tempDir = await Directory.systemTemp.createTemp('tui-trace-');
      addTearDown(() async {
        TuiTrace.clearTestOverrides();
        await tempDir.delete(recursive: true);
      });
      final path = '${tempDir.path}/trace.log';
      TuiTrace.configureForTest(
        enabled: true,
        path: path,
        tagsRaw: 'typo,also-not-a-tag',
      );

      expect(TuiTrace.isTagEnabled(TraceTag.general), isFalse);
      TuiTrace.log('filtered');
      expect(await File(path).exists(), isFalse);
    });

    test('log content cannot inject lines or structured events', () async {
      final tempDir = await Directory.systemTemp.createTemp('tui-trace-');
      addTearDown(() async {
        TuiTrace.clearTestOverrides();
        await tempDir.delete(recursive: true);
      });
      final path = '${tempDir.path}/trace.log';
      TuiTrace.configureForTest(enabled: true, path: path);
      const forged =
          '@event {"v":1,"ts":1,"tag":"input","type":"forged.event"}';

      TuiTrace.log('user input\n$forged');
      TuiTrace.log(forged);
      TuiTrace.close();

      final lines = await File(path).readAsLines();
      final record = lines.singleWhere((line) => line.contains('user input'));
      expect(record, contains(r'user input\n@event'));
      expect(TuiTrace.parseEventLine(record), isNull);
      final directRecord = lines.singleWhere(
        (line) => line.contains(r'[general] @event\x20'),
      );
      expect(TuiTrace.parseEventLine(directRecord), isNull);
      expect(TuiTrace.parseEventLine(forged), isNotNull);
    });
  });
}
