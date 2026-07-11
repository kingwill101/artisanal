import 'package:artisanal/tui.dart';
import 'package:test/test.dart';

void main() {
  group('ProgramRenderMonitor', () {
    test('aggregates render activity and native change counts', () async {
      final monitor = ProgramRenderMonitor();
      final terminal = StringTerminal(terminalWidth: 12, terminalHeight: 4);
      final program = Program<_InteractiveCounterModel>(
        const _InteractiveCounterModel(),
        options: ProgramOptions(
          signalHandlers: false,
          altScreen: false,
          interceptor: monitor,
        ),
        terminal: terminal,
      );

      final runFuture = program.run();
      await Future<void>.delayed(Duration.zero);
      program.send(const KeyMsg(Key(KeyType.runes, runes: <int>[0x2b])));
      program.send(const QuitMsg());
      await runFuture;

      final stats = monitor.stats;
      expect(stats.totalRenders, equals(2));
      expect(stats.changedRenders, equals(2));
      expect(stats.unchangedRenders, equals(0));
      expect(stats.totalChangedCells, greaterThan(0));
      expect(stats.totalChangedSpans, greaterThan(0));
      expect(stats.maxDirtyLines, greaterThan(0));
      expect(stats.maxChangedCells, greaterThan(0));
      expect(stats.maxChangedSpans, greaterThan(0));
      expect(stats.lastRenderGeneration, equals(2));
      expect(stats.lastDegradationLevel, equals(DegradationLevel.full));
      expect(stats.lastChangeSummary, isNotNull);
      expect(stats.lastChangeSummary!.hasChanges, isTrue);
      expect(stats.averageRenderDuration, isNot(Duration.zero));
      expect(stats.changedRenderRatio, equals(1.0));

      final entries = stats.toMetricEntries(prefix: 'Monitor');
      expect(entries['Monitor renders'], contains('2 (2 changed, 100%)'));
      expect(entries['Monitor avg'], contains('ms'));
      expect(entries['Monitor cells'], contains('total /'));
      expect(entries['Monitor spans'], contains('total /'));
      expect(entries['Monitor dirty'], isNotEmpty);
      expect(entries['Monitor level'], equals('full'));
    });

    test('reset clears accumulated render activity', () {
      final monitor = ProgramRenderMonitor();

      monitor.onRendered(
        renderGeneration: 1,
        view: const View(content: 'x'),
        degradationLevel: DegradationLevel.full,
        renderDuration: const Duration(milliseconds: 3),
        nativeDelta: const TerminalNativeDeltaFrame(
          width: 1,
          height: 1,
          lines: <TerminalNativeLine>[
            TerminalNativeLine(index: 0, cells: <TerminalNativeCell>[]),
          ],
        ),
      );

      expect(monitor.stats.totalRenders, equals(1));

      monitor.reset();

      final stats = monitor.stats;
      expect(stats.totalRenders, equals(0));
      expect(stats.changedRenders, equals(0));
      expect(stats.totalChangedCells, equals(0));
      expect(stats.totalChangedSpans, equals(0));
      expect(stats.maxDirtyLines, equals(0));
      expect(stats.maxChangedCells, equals(0));
      expect(stats.maxChangedSpans, equals(0));
      expect(stats.totalRenderDuration, equals(Duration.zero));
      expect(stats.lastRenderGeneration, isNull);
      expect(stats.lastDegradationLevel, isNull);
      expect(stats.lastChangeSummary, isNull);
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
