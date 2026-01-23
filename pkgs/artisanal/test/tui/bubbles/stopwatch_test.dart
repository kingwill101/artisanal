import 'package:artisanal/src/tui/bubbles/stopwatch.dart';
import 'package:artisanal/src/tui/cmd.dart';
import 'package:artisanal/src/tui/msg.dart';
import 'package:test/test.dart';

void main() {
  group('StopwatchModel', () {
    group('New', () {
      test('creates with default interval of 100ms', () {
        final stopwatch = StopwatchModel();
        expect(stopwatch.interval, Duration(milliseconds: 100));
        expect(stopwatch.elapsed, Duration.zero);
        expect(stopwatch.running, isFalse);
      });

      test('creates with custom interval', () {
        final stopwatch = StopwatchModel(interval: Duration(milliseconds: 50));
        expect(stopwatch.interval, Duration(milliseconds: 50));
      });

      test('has unique id', () {
        final s1 = StopwatchModel();
        final s2 = StopwatchModel();
        expect(s1.id, isNot(s2.id));
      });

      test('starts with tag 0', () {
        final stopwatch = StopwatchModel();
        expect(stopwatch.tag, 0);
      });

      test('starts with zero elapsed time', () {
        final stopwatch = StopwatchModel();
        expect(stopwatch.elapsed, Duration.zero);
      });
    });

    group('init', () {
      test('returns null command', () {
        final stopwatch = StopwatchModel();
        final cmd = stopwatch.init();
        expect(cmd, isNull);
      });
    });

    group('view', () {
      test('formats as MM:SS.cc', () {
        final stopwatch = StopwatchModel();
        expect(stopwatch.view(), '00:00.00');
      });

      test('formats minutes correctly', () {
        final stopwatch = StopwatchModel().copyWith(
          elapsed: Duration(minutes: 5, seconds: 30, milliseconds: 450),
        );
        expect(stopwatch.view(), '05:30.45');
      });

      test('formats single digits with padding', () {
        final stopwatch = StopwatchModel().copyWith(
          elapsed: Duration(seconds: 1, milliseconds: 50),
        );
        expect(stopwatch.view(), '00:01.05');
      });
    });

    group('start', () {
      test('returns batch command with start message and tick', () {
        final stopwatch = StopwatchModel();
        final cmd = stopwatch.start();
        expect(cmd, isNotNull);
      });
    });

    group('stop', () {
      test('returns stop message', () {
        final stopwatch = StopwatchModel();
        final cmd = stopwatch.stop();
        expect(cmd, isNotNull);
      });
    });

    group('toggle', () {
      test('starts when not running', () {
        final stopwatch = StopwatchModel();
        expect(stopwatch.running, isFalse);
        final cmd = stopwatch.toggle();
        expect(cmd, isNotNull);
      });
    });

    group('reset', () {
      test('returns reset message', () {
        final stopwatch = StopwatchModel();
        final cmd = stopwatch.reset();
        expect(cmd, isNotNull);
      });
    });

    group('update', () {
      group('StopwatchStartStopMsg', () {
        test('ignores messages with wrong id', () {
          final stopwatch = StopwatchModel();
          final (updated, cmd) = stopwatch.update(
            StopwatchStartStopMsg(true, 999, stopwatch.id + 1),
          );
          expect((updated).running, isFalse);
          expect(cmd, isNull);
        });

        test('starts stopwatch when running is true', () {
          final stopwatch = StopwatchModel();
          final (updated, cmd) = stopwatch.update(
            StopwatchStartStopMsg(true, stopwatch.tag, stopwatch.id),
          );
          expect((updated).running, isTrue);
          expect(cmd, isNull);
        });

        test('stops stopwatch when running is false', () {
          var stopwatch = StopwatchModel();
          var (updated, _) = stopwatch.update(
            StopwatchStartStopMsg(true, stopwatch.tag, stopwatch.id),
          );
          stopwatch = updated;
          expect(stopwatch.running, isTrue);

          (updated, _) = stopwatch.update(
            StopwatchStartStopMsg(false, stopwatch.tag, stopwatch.id),
          );
          expect((updated).running, isFalse);
        });
      });

      group('StopwatchResetMsg', () {
        test('ignores messages with wrong id', () {
          final stopwatch = StopwatchModel().copyWith(
            elapsed: Duration(seconds: 10),
          );
          final (updated, cmd) = stopwatch.update(
            StopwatchResetMsg(stopwatch.tag, stopwatch.id + 1),
          );
          expect((updated).elapsed, Duration(seconds: 10));
          expect(cmd, isNull);
        });

        test('resets elapsed time to zero', () {
          final stopwatch = StopwatchModel().copyWith(
            elapsed: Duration(seconds: 10),
          );
          final (updated, cmd) = stopwatch.update(
            StopwatchResetMsg(stopwatch.tag, stopwatch.id),
          );
          expect((updated).elapsed, Duration.zero);
          expect(cmd, isNull);
        });
      });

      group('StopwatchTickMsg', () {
        test('ignores messages with wrong id', () {
          final stopwatch = StopwatchModel();
          final (updated, cmd) = stopwatch.update(
            StopwatchTickMsg(DateTime.now(), stopwatch.tag, stopwatch.id + 1),
          );
          expect((updated).elapsed, Duration.zero);
          expect(cmd, isNull);
        });

        test('ignores ticks when not running', () {
          final stopwatch = StopwatchModel();
          final (updated, cmd) = stopwatch.update(
            StopwatchTickMsg(DateTime.now(), stopwatch.tag, stopwatch.id),
          );
          expect((updated).elapsed, Duration.zero);
          expect(cmd, isNull);
        });

        test('increments elapsed time when running', () {
          var stopwatch = StopwatchModel(interval: Duration(milliseconds: 100));
          // Start the stopwatch
          var (updated, _) = stopwatch.update(
            StopwatchStartStopMsg(true, stopwatch.tag, stopwatch.id),
          );
          stopwatch = updated;

          // Process a tick
          (updated, _) = stopwatch.update(
            StopwatchTickMsg(DateTime.now(), stopwatch.tag, stopwatch.id),
          );
          expect((updated).elapsed, Duration(milliseconds: 100));
        });

        test('returns tick command when running', () {
          var stopwatch = StopwatchModel(interval: Duration(milliseconds: 100));
          var (updated, _) = stopwatch.update(
            StopwatchStartStopMsg(true, stopwatch.tag, stopwatch.id),
          );
          stopwatch = updated;

          Cmd? cmd;
          (updated, cmd) = stopwatch.update(
            StopwatchTickMsg(DateTime.now(), stopwatch.tag, stopwatch.id),
          );
          expect(cmd, isNotNull);
        });
      });

      test('returns unchanged model for unknown messages', () {
        final stopwatch = StopwatchModel();
        final (updated, cmd) = stopwatch.update(_UnknownMsg());
        expect(updated, isA<StopwatchModel>());
        expect(cmd, isNull);
      });
    });

    group('copyWith', () {
      test('copies all fields', () {
        final stopwatch = StopwatchModel(interval: Duration(milliseconds: 100));
        final copied = stopwatch.copyWith(
          elapsed: Duration(seconds: 30),
          interval: Duration(milliseconds: 50),
          running: true,
        );
        expect(copied.elapsed, Duration(seconds: 30));
        expect(copied.interval, Duration(milliseconds: 50));
        expect(copied.running, isTrue);
        expect(copied.id, stopwatch.id);
        expect(copied.tag, stopwatch.tag);
      });

      test('preserves unchanged fields', () {
        final stopwatch = StopwatchModel(interval: Duration(milliseconds: 100));
        final copied = stopwatch.copyWith(elapsed: Duration(seconds: 30));
        expect(copied.elapsed, Duration(seconds: 30));
        expect(copied.interval, Duration(milliseconds: 100));
      });
    });

    group('elapsed time accumulation', () {
      test('accumulates time across multiple ticks', () {
        var stopwatch = StopwatchModel(interval: Duration(milliseconds: 100));
        var (updated, _) = stopwatch.update(
          StopwatchStartStopMsg(true, stopwatch.tag, stopwatch.id),
        );
        stopwatch = updated;

        // First tick
        (updated, _) = stopwatch.update(
          StopwatchTickMsg(DateTime.now(), stopwatch.tag, stopwatch.id),
        );
        stopwatch = updated;
        expect(stopwatch.elapsed, Duration(milliseconds: 100));

        // Second tick
        (updated, _) = stopwatch.update(
          StopwatchTickMsg(DateTime.now(), stopwatch.tag, stopwatch.id),
        );
        stopwatch = updated;
        expect(stopwatch.elapsed, Duration(milliseconds: 200));

        // Third tick
        (updated, _) = stopwatch.update(
          StopwatchTickMsg(DateTime.now(), stopwatch.tag, stopwatch.id),
        );
        stopwatch = updated;
        expect(stopwatch.elapsed, Duration(milliseconds: 300));
      });
    });
  });
}

class _UnknownMsg extends Msg {}
