import 'package:artisanal/tui.dart';
import 'package:test/test.dart';

void main() {
  group('ProgramRenderRecorder', () {
    test(
      'records deterministic snapshots with parsed frame metadata',
      () async {
        final recorder = ProgramRenderRecorder();
        final terminal = StringTerminal(terminalWidth: 12, terminalHeight: 4);
        final program = Program<_InteractiveCounterModel>(
          const _InteractiveCounterModel(),
          options: ProgramOptions(
            signalHandlers: false,
            altScreen: false,
            interceptor: recorder,
          ),
          terminal: terminal,
        );

        final runFuture = program.run();
        await Future<void>.delayed(Duration.zero);
        program.send(const KeyMsg(Key(KeyType.runes, runes: <int>[0x2b])));
        program.send(const QuitMsg());
        await runFuture;

        expect(recorder.snapshots, hasLength(2));

        final initial = recorder.snapshots.first;
        final updated = recorder.snapshots.last;

        expect(initial.sequence, equals(0));
        expect(initial.renderGeneration, equals(1));
        expect(initial.width, equals(12));
        expect(initial.height, equals(4));
        expect(initial.lines.first.trimRight(), equals('count: 0'));
        expect(initial.nativeFrame, isNotNull);

        expect(updated.sequence, equals(1));
        expect(updated.renderGeneration, equals(2));
        expect(
          updated.frame.lines.first.plainText.trimRight(),
          equals('count: 1'),
        );
        expect(updated.nativeCellDelta, isNotNull);
        expect(updated.nativeSpanDelta, isNotNull);
        expect(updated.nativeSpanDelta, isNotEmpty);
        expect(updated.changeSummary.hasChanges, isTrue);
        expect(updated.changeSummary.changedLineCount, greaterThan(0));
        expect(updated.changeSummary.changedCellCount, greaterThan(0));
        expect(updated.changeSummary.changedSpanCount, greaterThan(0));

        expect(
          recorder.snapshotsSince(initial.renderGeneration),
          equals(<ProgramRenderSnapshot>[updated]),
        );
        expect(recorder.lastSnapshot, same(updated));
      },
    );

    test('clear resets snapshots and local sequence', () async {
      final recorder = ProgramRenderRecorder();
      final terminal = StringTerminal(terminalWidth: 10, terminalHeight: 3);
      final program = Program<_QuitOnlyModel>(
        const _QuitOnlyModel(),
        options: ProgramOptions(
          signalHandlers: false,
          altScreen: false,
          interceptor: recorder,
        ),
        terminal: terminal,
      );

      await program.run();
      expect(recorder.snapshots, hasLength(1));

      recorder.clear();
      expect(recorder.snapshots, isEmpty);

      final secondProgram = Program<_QuitOnlyModel>(
        const _QuitOnlyModel(),
        options: ProgramOptions(
          signalHandlers: false,
          altScreen: false,
          interceptor: recorder,
        ),
        terminal: terminal,
      );

      await secondProgram.run();
      expect(recorder.snapshots, hasLength(1));
      expect(recorder.snapshots.single.sequence, equals(0));
    });
  });

  group('ProgramRenderCapture', () {
    test('captures snapshots and aggregate stats together', () async {
      final capture = ProgramRenderCapture();
      final terminal = StringTerminal(terminalWidth: 12, terminalHeight: 4);
      final program = Program<_InteractiveCounterModel>(
        const _InteractiveCounterModel(),
        options: ProgramOptions(
          signalHandlers: false,
          altScreen: false,
          interceptor: capture,
        ),
        terminal: terminal,
      );

      final runFuture = program.run();
      await Future<void>.delayed(Duration.zero);
      program.send(const KeyMsg(Key(KeyType.runes, runes: <int>[0x2b])));
      program.send(const QuitMsg());
      await runFuture;

      expect(capture.snapshots, hasLength(2));
      expect(capture.lastSnapshot, isNotNull);
      expect(
        capture.lastSnapshot!.frame.lines.first.plainText.trimRight(),
        'count: 1',
      );

      final stats = capture.stats;
      expect(stats.totalRenders, equals(2));
      expect(stats.changedRenders, equals(2));
      expect(stats.totalChangedCells, greaterThan(0));
      expect(stats.totalChangedSpans, greaterThan(0));

      final newer = capture.snapshotsSince(1);
      expect(newer, hasLength(1));
      expect(newer.single.renderGeneration, equals(2));

      final entries = capture.toMetricEntries(prefix: 'Capture');
      expect(entries['Capture renders'], contains('2 (2 changed, 100%)'));

      final structured = capture.report(prefix: 'Capture', maxFrameLines: 1);
      expect(structured.prefix, equals('Capture'));
      expect(structured.lastRenderGeneration, equals(2));
      expect(structured.lastWidth, equals(12));
      expect(structured.lastHeight, equals(4));
      expect(structured.frameLines, equals(<String>['count: 1']));
      expect(structured.lastChangeSummary, isNotNull);
      expect(structured.lastChangeSummary!.hasChanges, isTrue);
      expect(
        structured.metricEntries['Capture renders'],
        contains('2 (2 changed, 100%)'),
      );
      final lastSummary = capture.lastSnapshotSummary(maxFrameLines: 1);
      expect(lastSummary, isNotNull);
      expect(lastSummary!.renderGeneration, equals(2));
      expect(lastSummary.sequence, equals(1));
      expect(lastSummary.frameLines, equals(<String>['count: 1']));
      expect(lastSummary.changeSummary.hasChanges, isTrue);
      expect(lastSummary.toJson()['renderGeneration'], equals(2));

      final json = structured.toJson();
      expect(json['prefix'], equals('Capture'));
      expect(json['lastRenderGeneration'], equals(2));
      expect(json['lastWidth'], equals(12));
      expect(json['lastHeight'], equals(4));
      expect(json['frameLines'], equals(<String>['count: 1']));
      expect(json['lastChangeSummary'], isA<Map<String, Object?>>());
      expect(
        (json['lastChangeSummary'] as Map<String, Object?>)['hasChanges'],
        isTrue,
      );
      expect(
        (json['metricEntries'] as Map<String, String>)['Capture renders'],
        contains('2 (2 changed, 100%)'),
      );

      final report = capture.toReportLines(prefix: 'Capture', maxFrameLines: 1);
      expect(report.first, contains('Capture last: generation 2'));
      expect(report[1], contains('Capture frame: count: 1'));
      expect(report[2], contains('Capture changes: dirty'));
      expect(
        report.any(
          (line) => line.contains('Capture renders: 2 (2 changed, 100%)'),
        ),
        isTrue,
      );

      final snapshotJson = capture.lastSnapshot!.toJson();
      expect(snapshotJson['renderGeneration'], equals(2));
      expect(snapshotJson['lines'], equals(<String>['count: 1']));
      expect(snapshotJson['changeSummary'], isA<Map<String, Object?>>());
      expect(
        (snapshotJson['changeSummary'] as Map<String, Object?>)['hasChanges'],
        isTrue,
      );

      final captureJson = capture.toJson(prefix: 'Capture', maxFrameLines: 1);
      expect(captureJson['stats'], isA<Map<String, Object?>>());
      expect(captureJson['report'], isA<Map<String, Object?>>());
      expect(captureJson['lastSnapshot'], isA<Map<String, Object?>>());
      expect(captureJson['lastSnapshotSummary'], isA<Map<String, Object?>>());
      expect(
        ((captureJson['stats'] as Map<String, Object?>)['totalRenders']),
        equals(2),
      );
      expect(
        ((captureJson['stats'] as Map<String, Object?>)['changedRenderRatio']),
        equals(1.0),
      );
      expect(
        ((captureJson['report'] as Map<String, Object?>)['prefix']),
        equals('Capture'),
      );

      final payload = capture.payload(prefix: 'Capture', maxFrameLines: 1);
      expect(payload.stats.totalRenders, equals(2));
      expect(payload.report.prefix, equals('Capture'));
      expect(payload.lastSnapshot, isNotNull);
      expect(payload.lastSnapshotSummary, isNotNull);
      expect(
        payload.lastSnapshotSummary!.frameLines,
        equals(<String>['count: 1']),
      );
      expect(payload.toJson(), equals(captureJson));

      capture.clear();
      expect(capture.snapshots, isEmpty);
      expect(capture.stats.totalRenders, equals(0));
      expect(capture.stats.changedRenders, equals(0));
      expect(capture.stats.lastRenderGeneration, isNull);
    });

    test('payload can round-trip from serialized json', () async {
      final capture = ProgramRenderCapture();
      final terminal = StringTerminal(terminalWidth: 12, terminalHeight: 4);
      final program = Program<_InteractiveCounterModel>(
        const _InteractiveCounterModel(),
        options: ProgramOptions(
          signalHandlers: false,
          altScreen: false,
          interceptor: capture,
        ),
        terminal: terminal,
      );

      final runFuture = program.run();
      await Future<void>.delayed(Duration.zero);
      program.send(const KeyMsg(Key(KeyType.runes, runes: <int>[0x2b])));
      program.send(const QuitMsg());
      await runFuture;

      final payload = capture.payload(prefix: 'Capture', maxFrameLines: 1);
      final decoded = ProgramRenderCapturePayload.fromJson(payload.toJson());

      expect(decoded.stats.totalRenders, equals(2));
      expect(decoded.stats.changedRenders, equals(2));
      expect(decoded.report.prefix, equals('Capture'));
      expect(decoded.report.lastRenderGeneration, equals(2));
      expect(decoded.report.frameLines, equals(<String>['count: 1']));
      expect(decoded.lastSnapshot, isNotNull);
      expect(decoded.lastSnapshot!.renderGeneration, equals(2));
      expect(decoded.lastSnapshot!.width, equals(12));
      expect(decoded.lastSnapshot!.height, equals(4));
      expect(decoded.lastSnapshotSummary, isNotNull);
      expect(
        decoded.lastSnapshotSummary!.frameLines,
        equals(<String>['count: 1']),
      );
      expect(decoded.lastSnapshotSummary!.changeSummary.hasChanges, isTrue);
    });
  });
}

final class _InteractiveCounterModel implements Model {
  const _InteractiveCounterModel([this.count = 0]);

  final int count;

  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) {
    return switch (msg) {
      KeyMsg(:final key) when key.char == '+' => (
        _InteractiveCounterModel(count + 1),
        null,
      ),
      _ => (this, null),
    };
  }

  @override
  Object view() => View(content: 'count: $count');
}

final class _QuitOnlyModel implements Model {
  const _QuitOnlyModel();

  @override
  Cmd? init() => Cmd.quit();

  @override
  (Model, Cmd?) update(Msg msg) => (this, null);

  @override
  Object view() => const View(content: 'done');
}
