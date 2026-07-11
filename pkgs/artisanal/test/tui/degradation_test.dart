import 'dart:async';

import 'package:artisanal/tui.dart';
import 'package:test/test.dart';

void main() {
  group('RenderBudgetController', () {
    test('degrades after sustained over-budget frames', () {
      final controller = RenderBudgetController(
        options: const RenderBudgetOptions(
          enabled: true,
          overBudgetFrames: 2,
          recoveryFrames: 3,
          maxLevel: DegradationLevel.noStyling,
        ),
        frameBudget: const Duration(milliseconds: 16),
      );

      expect(controller.level, DegradationLevel.full);
      expect(controller.recordFrame(const Duration(milliseconds: 20)), isFalse);
      expect(controller.level, DegradationLevel.full);
      expect(controller.recordFrame(const Duration(milliseconds: 20)), isTrue);
      expect(controller.level, DegradationLevel.simpleBorders);
      expect(controller.recordFrame(const Duration(milliseconds: 20)), isFalse);
      expect(controller.recordFrame(const Duration(milliseconds: 20)), isTrue);
      expect(controller.level, DegradationLevel.noStyling);
    });

    test('recovers after sustained within-budget frames', () {
      final controller = RenderBudgetController(
        options: const RenderBudgetOptions(
          enabled: true,
          overBudgetFrames: 1,
          recoveryFrames: 2,
          maxLevel: DegradationLevel.essentialOnly,
        ),
        frameBudget: const Duration(milliseconds: 16),
      );

      controller.recordFrame(const Duration(milliseconds: 20));
      controller.recordFrame(const Duration(milliseconds: 20));
      expect(controller.level, DegradationLevel.noStyling);

      expect(controller.recordFrame(const Duration(milliseconds: 4)), isFalse);
      expect(controller.recordFrame(const Duration(milliseconds: 4)), isTrue);
      expect(controller.level, DegradationLevel.simpleBorders);
      expect(controller.recordFrame(const Duration(milliseconds: 4)), isFalse);
      expect(controller.recordFrame(const Duration(milliseconds: 4)), isTrue);
      expect(controller.level, DegradationLevel.full);
    });

    test('respects the configured max degradation level', () {
      final controller = RenderBudgetController(
        options: const RenderBudgetOptions(
          enabled: true,
          overBudgetFrames: 1,
          recoveryFrames: 2,
          maxLevel: DegradationLevel.simpleBorders,
        ),
        frameBudget: const Duration(milliseconds: 16),
      );

      controller.recordFrame(const Duration(milliseconds: 20));
      controller.recordFrame(const Duration(milliseconds: 20));

      expect(controller.level, DegradationLevel.simpleBorders);
    });

    test('does nothing when disabled', () {
      final controller = RenderBudgetController(
        options: const RenderBudgetOptions(enabled: false),
        frameBudget: const Duration(milliseconds: 16),
      );

      final changed = controller.recordFrame(const Duration(milliseconds: 999));

      expect(changed, isFalse);
      expect(controller.level, DegradationLevel.full);
    });
  });

  group('ViewDegradation', () {
    test('resolves progressively more degraded fallbacks', () {
      const degradation = ViewDegradation(
        simpleBordersContent: 'simple',
        noStylingContent: 'unstyled',
        skeletonContent: 'skeleton',
      );

      expect(degradation.resolve('full', DegradationLevel.full), 'full');
      expect(
        degradation.resolve('full', DegradationLevel.simpleBorders),
        'simple',
      );
      expect(
        degradation.resolve('full', DegradationLevel.noStyling),
        'unstyled',
      );
      expect(
        degradation.resolve('full', DegradationLevel.essentialOnly),
        'unstyled',
      );
      expect(
        degradation.resolve('full', DegradationLevel.skeleton),
        'skeleton',
      );
    });
  });

  group('View degradation integration', () {
    test('View.degraded preserves metadata while swapping content', () {
      const view = View(
        content: 'full fidelity',
        windowTitle: 'Budget Demo',
        reportFocus: true,
        degradation: ViewDegradation(
          simpleBordersContent: 'simple borders',
          skeletonContent: 'skeleton only',
        ),
      );

      final degraded = view.degraded(DegradationLevel.simpleBorders);
      final skeleton = view.degraded(DegradationLevel.skeleton);

      expect(degraded.content, 'simple borders');
      expect(degraded.windowTitle, 'Budget Demo');
      expect(degraded.reportFocus, isTrue);
      expect(skeleton.content, 'skeleton only');
    });

    test(
      'Program exposes degradation level changes after over-budget renders',
      () async {
        final terminal = _SlowStringTerminal(
          terminalWidth: 80,
          terminalHeight: 24,
        );
        final program = Program<_StaticViewModel>(
          const _StaticViewModel(),
          options: const ProgramOptions(
            altScreen: false,
            hideCursor: false,
            frameTick: false,
            startupProbes: false,
            useUltravioletRenderer: false,
            renderBudget: RenderBudgetOptions(
              enabled: true,
              frameBudget: Duration(microseconds: 1),
              overBudgetFrames: 1,
              recoveryFrames: 2,
              maxLevel: DegradationLevel.simpleBorders,
            ),
          ),
          terminal: terminal,
        );

        final runFuture = program.run();
        await _waitUntil(
          () =>
              program.renderBudgetState.level == DegradationLevel.simpleBorders,
        );
        program.send(const QuitMsg());
        await runFuture;

        expect(program.renderBudgetState.level, DegradationLevel.simpleBorders);
      },
    );

    test('Program delivers RenderBudgetMsg when degradation changes', () async {
      final terminal = _SlowStringTerminal(
        terminalWidth: 80,
        terminalHeight: 24,
      );
      final budgetChange = Completer<RenderBudgetState>();
      final program = Program<_BudgetAwareModel>(
        _BudgetAwareModel(
          onBudgetChange: (state) {
            if (!budgetChange.isCompleted) budgetChange.complete(state);
          },
        ),
        options: const ProgramOptions(
          altScreen: false,
          hideCursor: false,
          frameTick: false,
          startupProbes: false,
          useUltravioletRenderer: false,
          renderBudget: RenderBudgetOptions(
            enabled: true,
            frameBudget: Duration(microseconds: 1),
            overBudgetFrames: 1,
            recoveryFrames: 2,
            maxLevel: DegradationLevel.simpleBorders,
          ),
        ),
        terminal: terminal,
      );

      final runFuture = program.run();
      final state = await budgetChange.future.timeout(
        const Duration(milliseconds: 250),
      );
      program.send(const QuitMsg());
      await runFuture;

      expect(state.level, DegradationLevel.simpleBorders);
    });
  });
}

class _SlowStringTerminal extends StringTerminal {
  _SlowStringTerminal({
    required super.terminalWidth,
    required super.terminalHeight,
  });

  @override
  void write(String text) {
    final sw = Stopwatch()..start();
    while (sw.elapsedMilliseconds < 10) {}
    super.write(text);
  }
}

class _StaticViewModel implements Model {
  const _StaticViewModel();

  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) => (this, null);

  @override
  Object view() => const View(
    content: 'full fidelity',
    degradation: ViewDegradation(simpleBordersContent: 'simple borders'),
  );
}

class _BudgetAwareModel implements Model {
  const _BudgetAwareModel({
    this.level = DegradationLevel.full,
    required this.onBudgetChange,
  });

  final DegradationLevel level;
  final void Function(RenderBudgetState state) onBudgetChange;

  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) {
    return switch (msg) {
      RenderBudgetMsg(:final state) => (
        _BudgetAwareModel(level: state.level, onBudgetChange: onBudgetChange)
          ..onBudgetChange(state),
        null,
      ),
      _ => (this, null),
    };
  }

  @override
  Object view() => View(content: 'budget:$level');
}

Future<void> _waitUntil(
  bool Function() condition, {
  Duration timeout = const Duration(milliseconds: 250),
  Duration poll = const Duration(milliseconds: 5),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out waiting for test condition');
    }
    await Future<void>.delayed(poll);
  }
}
