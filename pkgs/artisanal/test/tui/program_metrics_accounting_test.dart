import 'dart:async';

import 'package:artisanal/tui.dart';
import 'package:test/test.dart';

void main() {
  test(
    'custom diagnostics updates do not count as application frames',
    () async {
      final ready = Completer<void>();
      final terminal = StringTerminal(terminalWidth: 80, terminalHeight: 24);
      final renderer = UltravioletTuiRenderer(
        terminal: terminal,
        options: const TuiRendererOptions(altScreen: true),
      );
      final program = Program(
        _Model(ready: ready),
        terminal: terminal,
        renderer: renderer,
        options: ProgramOptions(
          altScreen: true,
          startupProbes: false,
          metricsInterval: Duration.zero,
          diagnostics: ProgramDiagnosticsOptions(initiallyVisible: true),
        ),
      );
      addTearDown(ProgramDiagnosticsMetrics.clear);
      final run = program.run();
      try {
        await ready.future.timeout(const Duration(seconds: 2));
        await Future<void>.delayed(Duration.zero);
        final metrics = renderer.metrics!;
        final frames = metrics.frameCount;
        for (var i = 0; i < 3; i++) {
          ProgramDiagnosticsMetrics.setMetric('jobs', i);
          await Future<void>.delayed(Duration.zero);
          expect(metrics.frameCount, frames);
          expect(metrics.metricsOnlyFrame, isFalse);
        }
        program.send(const KeyMsg(Key(KeyType.runes, runes: [120])));
        expect(metrics.frameCount, frames + 1);
      } finally {
        program.quit();
        await run;
      }
    },
  );

  for (final buffered in [false, true]) {
    test(
      'admitted bookkeeping frames stay excluded (buffered=$buffered)',
      () async {
        final ready = Completer<void>();
        final terminal = StringTerminal(terminalWidth: 40, terminalHeight: 8);
        final inner = UltravioletTuiRenderer(
          terminal: terminal,
          options: const TuiRendererOptions(altScreen: true),
        );
        final TuiRenderer renderer = buffered
            ? BufferedTuiRenderer(inner: inner)
            : inner;
        final program = Program(
          _Model(ready: ready, freshView: true),
          terminal: terminal,
          renderer: renderer,
          options: const ProgramOptions(
            altScreen: true,
            startupProbes: false,
            metricsInterval: Duration.zero,
          ),
        );
        final run = program.run();
        try {
          await ready.future.timeout(const Duration(seconds: 2));
          await Future<void>.delayed(Duration.zero);
          final metrics = renderer.metrics!;
          final frames = metrics.frameCount;
          renderer.invalidate();
          program.send(RenderMetricsMsg(metrics));
          expect(metrics.frameCount, frames);
          expect(metrics.metricsOnlyFrame, isFalse);
          program.send(const KeyMsg(Key(KeyType.runes, runes: [120])));
          expect(metrics.frameCount, frames + 1);
        } finally {
          program.quit();
          await run;
        }
      },
    );
  }

  for (final freshView in [false, true]) {
    test('skipped metrics refresh does not consume next real frame '
        '(freshView=$freshView)', () async {
      final ready = Completer<void>();
      final terminal = StringTerminal(terminalWidth: 40, terminalHeight: 8);
      final renderer = UltravioletTuiRenderer(
        terminal: terminal,
        options: const TuiRendererOptions(altScreen: true, fps: 1),
      );
      final program = Program(
        _Model(ready: ready, freshView: freshView),
        terminal: terminal,
        renderer: renderer,
        options: const ProgramOptions(
          altScreen: true,
          startupProbes: false,
          metricsInterval: Duration.zero,
        ),
      );
      final run = program.run();
      try {
        await ready.future.timeout(const Duration(seconds: 2));
        await Future<void>.delayed(Duration.zero);
        final metrics = renderer.metrics!;
        final frames = metrics.frameCount;
        expect(frames, greaterThan(0));

        program.send(RenderMetricsMsg(metrics));
        expect(metrics.frameCount, frames);
        expect(metrics.metricsOnlyFrame, isFalse);
        program.send(const KeyMsg(Key(KeyType.runes, runes: [120])));
        expect(metrics.frameCount, frames + 1);
        expect(metrics.metricsOnlyFrame, isFalse);
      } finally {
        program.quit();
        await run;
      }
    });
  }

  for (final metricsFirst in [false, true]) {
    test('coalesced real render takes precedence over metrics refresh '
        '(metricsFirst=$metricsFirst)', () async {
      final ready = Completer<void>();
      final terminal = StringTerminal(terminalWidth: 40, terminalHeight: 8);
      final renderer = UltravioletTuiRenderer(
        terminal: terminal,
        options: const TuiRendererOptions(altScreen: true),
      );
      late Program<_Model> program;
      program = Program(
        _Model(
          ready: ready,
          onBatch: () {
            final refresh = RenderMetricsMsg(renderer.metrics!);
            const key = KeyMsg(Key(KeyType.runes, runes: [120]));
            program.send(metricsFirst ? refresh : key);
            program.send(metricsFirst ? key : refresh);
          },
        ),
        terminal: terminal,
        renderer: renderer,
        options: const ProgramOptions(
          altScreen: true,
          startupProbes: false,
          metricsInterval: Duration.zero,
        ),
      );
      final run = program.run();
      try {
        await ready.future.timeout(const Duration(seconds: 2));
        await Future<void>.delayed(Duration.zero);
        final metrics = renderer.metrics!;
        final frames = metrics.frameCount;
        program.send(const _Batch());
        expect(metrics.frameCount, frames + 1);
        expect(metrics.metricsOnlyFrame, isFalse);
      } finally {
        program.quit();
        await run;
      }
    });
  }
}

class _Ready extends Msg {
  const _Ready();
}

class _Batch extends Msg {
  const _Batch();
}

class _Model implements Model, FrameTickModel {
  _Model({
    required this.ready,
    this.freshView = false,
    this.onBatch,
    this.count = 0,
  }) : cachedView = 'count: $count';

  final Completer<void> ready;
  final bool freshView;
  final void Function()? onBatch;
  final int count;
  final String cachedView;

  @override
  bool get wantsFrameTicks => false;

  @override
  Cmd? init() => Cmd.message(const _Ready());

  @override
  (Model, Cmd?) update(Msg msg) {
    if (msg is _Ready && !ready.isCompleted) ready.complete();
    if (msg is _Batch) onBatch?.call();
    if (msg is KeyMsg) {
      return (
        _Model(
          ready: ready,
          freshView: freshView,
          onBatch: onBatch,
          count: count + 1,
        ),
        null,
      );
    }
    return (this, null);
  }

  @override
  Object view() => freshView ? View(content: cachedView) : cachedView;
}
