/// Tests for HotReloadMixin integration with Program.
///
/// These tests verify the hot reload initialization flow, status callbacks,
/// and performReassemble behavior without needing a live VM service.
@TestOn('vm')
library;

import 'dart:async';

import 'package:artisanal/tui.dart';
import 'package:test/test.dart';

import 'program_test.dart' show MockTerminal;

/// A model that tracks hot reload status messages.
class _HotReloadModel implements Model {
  const _HotReloadModel({this.statuses = const [], this.quitAfterStatus});

  final List<HotReloadStatus> statuses;
  final HotReloadStatus? quitAfterStatus;

  @override
  Cmd? init() =>
      Cmd.tick(const Duration(seconds: 2), (_) => const _TimeoutMsg());

  @override
  (Model, Cmd?) update(Msg msg) {
    switch (msg) {
      case HotReloadStatusMsg(:final status):
        final next = _HotReloadModel(
          statuses: [...statuses, status],
          quitAfterStatus: quitAfterStatus,
        );
        if (status == quitAfterStatus) {
          return (next, Cmd.quit());
        }
        return (next, null);
      case _TimeoutMsg():
        return (this, Cmd.quit());
      default:
        return (this, null);
    }
  }

  @override
  String view() => 'statuses: $statuses';
}

class _TimeoutMsg extends Msg {
  const _TimeoutMsg();
}

void main() {
  late MockTerminal terminal;

  setUp(() {
    terminal = MockTerminal();
  });

  group('HotReloadMixin', () {
    test(
      'hotReload null auto-detects and skips when VM service is unavailable',
      () async {
        final program = Program(
          const _HotReloadModel(),
          options: const ProgramOptions(altScreen: false),
          terminal: terminal,
        );

        // hotReload defaults to null (auto-detect). In tests, VM service is not
        // available, so _shouldInitializeHotReload() returns false and
        // initializeHotReload is never called. No status messages are emitted.
        await program.run();

        final model = program.finalModel as _HotReloadModel;
        expect(
          model.statuses,
          isEmpty,
          reason:
              'Auto-detect should skip hot reload entirely when VM service is '
              'unavailable — no status messages should be emitted',
        );
      },
    );

    test('hotReload false disables hot reload entirely', () async {
      final program = Program(
        const _HotReloadModel(quitAfterStatus: HotReloadStatus.ready),
        options: const ProgramOptions(altScreen: false, hotReload: false),
        terminal: terminal,
      );

      // hotReload: false means no initialization at all.
      // The program should time out (no hot reload status messages).
      await program.run();

      final model = program.finalModel as _HotReloadModel;
      expect(
        model.statuses,
        isEmpty,
        reason:
            'No hot reload statuses should be emitted when hotReload is false',
      );
    });

    test('initializeHotReload is called when hotReload is true', () async {
      final program = Program(
        const _HotReloadModel(quitAfterStatus: HotReloadStatus.unavailable),
        options: const ProgramOptions(altScreen: false, hotReload: true),
        terminal: terminal,
      );

      // In tests, VM service is not available (no --enable-vm-service).
      // So initializeHotReload should emit: initializing, then unavailable.
      await program.run();

      final model = program.finalModel as _HotReloadModel;
      expect(model.statuses, contains(HotReloadStatus.initializing));
      expect(model.statuses, contains(HotReloadStatus.unavailable));
    });

    test('performReassemble clears caches and re-renders', () async {
      var renderCount = 0;
      final model = _CallbackModel(
        onView: () {
          renderCount++;
          return 'render #$renderCount';
        },
        onInit: () => null,
        onUpdate: (msg) {
          if (msg is _ReassembleDoneMsg) return Cmd.quit();
          return null;
        },
      );

      final program = Program(
        model,
        options: const ProgramOptions(altScreen: false),
        terminal: terminal,
      );

      final runFuture = program.run();

      // Wait for initial render
      await Future.delayed(const Duration(milliseconds: 100));
      final countAfterInit = renderCount;

      // Trigger reassemble
      await program.performReassemble();
      // performReassemble() schedules a render via scheduleRender() which
      // queues a microtask. Yield to the event loop so the microtask fires.
      await Future<void>.delayed(Duration.zero);
      expect(
        renderCount,
        greaterThan(countAfterInit),
        reason: 'performReassemble should trigger a re-render',
      );

      // Quit
      program.send(const _ReassembleDoneMsg());
      await runFuture;
    });
  });
}

class _ReassembleDoneMsg extends Msg {
  const _ReassembleDoneMsg();
}

class _CallbackModel implements Model {
  _CallbackModel({
    required String Function() onView,
    required Cmd? Function() onInit,
    required Cmd? Function(Msg) onUpdate,
  })  : _onView = onView,
        _onInit = onInit,
        _onUpdate = onUpdate;

  final String Function() _onView;
  final Cmd? Function() _onInit;
  final Cmd? Function(Msg) _onUpdate;

  @override
  Cmd? init() => _onInit();

  @override
  (Model, Cmd?) update(Msg msg) {
    final cmd = _onUpdate(msg);
    return (this, cmd);
  }

  @override
  String view() => _onView();
}
