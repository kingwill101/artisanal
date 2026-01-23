import 'package:artisanal/src/tui/bubbles/timer.dart';
import 'package:artisanal/src/tui/msg.dart';
import 'package:test/test.dart';

void main() {
  group('TimerModel', () {
    group('New', () {
      test('creates with default interval of 1 second', () {
        final timer = TimerModel(timeout: Duration(seconds: 30));
        expect(timer.timeout, Duration(seconds: 30));
        expect(timer.interval, Duration(seconds: 1));
        expect(timer.running, isFalse);
        expect(timer.timedOut, isFalse);
      });

      test('creates with custom interval', () {
        final timer = TimerModel(
          timeout: Duration(minutes: 1),
          interval: Duration(milliseconds: 500),
        );
        expect(timer.timeout, Duration(minutes: 1));
        expect(timer.interval, Duration(milliseconds: 500));
      });

      test('has unique id', () {
        final timer1 = TimerModel(timeout: Duration(seconds: 10));
        final timer2 = TimerModel(timeout: Duration(seconds: 20));
        expect(timer1.id, isNot(timer2.id));
      });

      test('starts with tag 0', () {
        final timer = TimerModel(timeout: Duration(seconds: 10));
        expect(timer.tag, 0);
      });
    });

    group('init', () {
      test('returns null command', () {
        final timer = TimerModel(timeout: Duration(seconds: 30));
        final cmd = timer.init();
        expect(cmd, isNull);
      });
    });

    group('view', () {
      test('formats as MM:SS', () {
        final timer = TimerModel(timeout: Duration(minutes: 5, seconds: 30));
        expect(timer.view(), '05:30');
      });

      test('shows 00:00 when timed out', () {
        final timer = TimerModel(timeout: Duration.zero);
        expect(timer.view(), '00:00');
      });

      test('handles hours correctly', () {
        final timer = TimerModel(timeout: Duration(hours: 1, minutes: 30));
        expect(timer.view(), '90:00'); // 90 minutes total
      });
    });

    group('timedOut', () {
      test('returns false when timeout is positive', () {
        final timer = TimerModel(timeout: Duration(seconds: 10));
        expect(timer.timedOut, isFalse);
      });

      test('returns true when timeout is zero', () {
        final timer = TimerModel(timeout: Duration.zero);
        expect(timer.timedOut, isTrue);
      });
    });

    group('start', () {
      test('returns batch command with start message and tick', () {
        final timer = TimerModel(timeout: Duration(seconds: 10));
        final cmd = timer.start();
        expect(cmd, isNotNull);
      });
    });

    group('stop', () {
      test('returns stop message', () {
        final timer = TimerModel(timeout: Duration(seconds: 10));
        final cmd = timer.stop();
        expect(cmd, isNotNull);
      });
    });

    group('toggle', () {
      test('starts when not running', () {
        final timer = TimerModel(timeout: Duration(seconds: 10));
        expect(timer.running, isFalse);
        final cmd = timer.toggle();
        expect(cmd, isNotNull);
      });
    });

    group('update', () {
      group('TimerStartStopMsg', () {
        test('ignores messages with wrong tag', () {
          final timer = TimerModel(timeout: Duration(seconds: 10));
          final (updated, cmd) = timer.update(TimerStartStopMsg(true, 999));
          expect((updated).running, isFalse);
          expect(cmd, isNull);
        });

        test('starts timer when running is true', () {
          final timer = TimerModel(timeout: Duration(seconds: 10));
          final (updated, cmd) = timer.update(
            TimerStartStopMsg(true, timer.tag),
          );
          expect((updated).running, isTrue);
          expect(cmd, isNull);
        });

        test('stops timer when running is false', () {
          // First start the timer
          var timer = TimerModel(timeout: Duration(seconds: 10));
          var (updated, _) = timer.update(TimerStartStopMsg(true, timer.tag));
          timer = updated;
          expect(timer.running, isTrue);

          // Then stop it
          (updated, _) = timer.update(TimerStartStopMsg(false, timer.tag));
          expect((updated).running, isFalse);
        });
      });

      group('TimerTickMsg', () {
        test('ignores messages with wrong tag', () {
          final timer = TimerModel(timeout: Duration(seconds: 10));
          final (updated, cmd) = timer.update(
            TimerTickMsg(DateTime.now(), 999, false),
          );
          expect((updated).timeout, Duration(seconds: 10));
          expect(cmd, isNull);
        });

        test('ignores ticks when not running', () {
          final timer = TimerModel(timeout: Duration(seconds: 10));
          final (updated, cmd) = timer.update(
            TimerTickMsg(DateTime.now(), timer.tag, false),
          );
          expect((updated).timeout, Duration(seconds: 10));
          expect(cmd, isNull);
        });

        test('decrements timeout when running', () {
          var timer = TimerModel(timeout: Duration(seconds: 10));
          // Start the timer
          var (updated, _) = timer.update(TimerStartStopMsg(true, timer.tag));
          timer = updated;

          // Process a tick
          (updated, _) = timer.update(
            TimerTickMsg(DateTime.now(), timer.tag, false),
          );
          expect((updated).timeout, Duration(seconds: 9));
        });

        test('stops and sets timeout to zero when reaching zero', () {
          var timer = TimerModel(
            timeout: Duration(seconds: 1),
            interval: Duration(seconds: 1),
          );
          // Start the timer
          var (updated, cmd) = timer.update(TimerStartStopMsg(true, timer.tag));
          timer = updated;

          // Process a tick that brings it to zero
          (updated, cmd) = timer.update(
            TimerTickMsg(DateTime.now(), timer.tag, false),
          );
          timer = updated;
          expect(timer.timeout, Duration.zero);
          expect(timer.running, isFalse);
          expect(cmd, isNotNull); // timeout command
        });

        test('handles timeout flag', () {
          var timer = TimerModel(timeout: Duration(seconds: 5));
          // Start the timer
          var (updated, _) = timer.update(TimerStartStopMsg(true, timer.tag));
          timer = updated;

          // Process a timeout tick
          (updated, _) = timer.update(
            TimerTickMsg(DateTime.now(), timer.tag, true),
          );
          timer = updated;
          expect(timer.timeout, Duration.zero);
          expect(timer.running, isFalse);
        });
      });

      test('returns unchanged model for unknown messages', () {
        final timer = TimerModel(timeout: Duration(seconds: 10));
        final (updated, cmd) = timer.update(_UnknownMsg());
        expect(updated, isA<TimerModel>());
        expect((updated).timeout, Duration(seconds: 10));
        expect(cmd, isNull);
      });
    });

    group('copyWith', () {
      test('copies all fields', () {
        final timer = TimerModel(
          timeout: Duration(seconds: 30),
          interval: Duration(milliseconds: 500),
        );
        final copied = timer.copyWith(
          timeout: Duration(seconds: 60),
          interval: Duration(seconds: 2),
          running: true,
        );
        expect(copied.timeout, Duration(seconds: 60));
        expect(copied.interval, Duration(seconds: 2));
        expect(copied.running, isTrue);
        expect(copied.id, timer.id);
        expect(copied.tag, timer.tag);
      });

      test('preserves unchanged fields', () {
        final timer = TimerModel(
          timeout: Duration(seconds: 30),
          interval: Duration(milliseconds: 500),
        );
        final copied = timer.copyWith(timeout: Duration(seconds: 60));
        expect(copied.timeout, Duration(seconds: 60));
        expect(copied.interval, Duration(milliseconds: 500));
      });
    });
  });
}

class _UnknownMsg extends Msg {}
