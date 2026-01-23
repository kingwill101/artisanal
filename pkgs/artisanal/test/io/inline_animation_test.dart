import 'dart:async';

import 'package:artisanal/src/io/inline_animation.dart';
import 'package:artisanal/src/terminal/terminal.dart';
import 'package:artisanal/src/tui/bubbles/spinner.dart';
import 'package:test/test.dart';

void main() {
  group('InlineAnimation', () {
    late StringTerminal terminal;
    late InlineAnimation animation;

    setUp(() {
      terminal = StringTerminal();
      animation = InlineAnimation(terminal: terminal);
    });

    group('spin', () {
      test('executes task and returns result', () async {
        final result = await animation.spin(
          message: 'Loading',
          task: () async {
            await Future.delayed(Duration(milliseconds: 10));
            return 42;
          },
          spinner: Spinners.line,
        );

        expect(result, equals(42));
      });

      test('shows spinner frame and message', () async {
        await animation.spin(
          message: 'Test',
          task: () async => 'done',
          spinner: Spinners.line,
        );

        // Should have written at least the initial frame
        expect(terminal.output, contains('Test'));
      });

      test('clearOnDone clears the line', () async {
        await animation.spin(
          message: 'Loading',
          task: () async => 'result',
          spinner: Spinners.line,
          clearOnDone: true,
        );

        // Check that clearLine operation was called
        expect(terminal.operations, contains('clearLine'));
      });

      test('doneMessage replaces spinner on completion', () async {
        await animation.spin(
          message: 'Loading',
          task: () async => 'result',
          spinner: Spinners.line,
          doneMessage: '✓ Complete!',
        );

        expect(terminal.output, contains('✓ Complete!'));
      });

      test('rethrows on task error', () async {
        expect(
          () => animation.spin(
            message: 'Failing',
            task: () async => throw Exception('oops'),
            spinner: Spinners.line,
          ),
          throwsException,
        );
      });

      test('clears line on error when clearOnDone is true', () async {
        try {
          await animation.spin(
            message: 'Failing',
            task: () async => throw Exception('oops'),
            spinner: Spinners.line,
            clearOnDone: true,
          );
        } catch (_) {}

        expect(terminal.operations, contains('clearLine'));
      });

      test('shows errorMessage on error', () async {
        try {
          await animation.spin(
            message: 'Failing',
            task: () async => throw Exception('oops'),
            spinner: Spinners.line,
            errorMessage: '✗ Failed!',
          );
        } catch (_) {}

        expect(terminal.output, contains('✗ Failed!'));
      });

      test('handles empty spinner frames gracefully', () async {
        final emptySpinner = Spinner(frames: []);
        final result = await animation.spin(
          message: 'Test',
          task: () async => 123,
          spinner: emptySpinner,
        );

        expect(result, equals(123));
      });

      test('hides and shows cursor', () async {
        await animation.spin(
          message: 'Loading',
          task: () async => 'done',
          spinner: Spinners.line,
        );

        // Should hide cursor at start and show at end
        expect(terminal.operations, contains('hideCursor'));
        expect(terminal.operations, contains('showCursor'));
      });
    });

    group('progress', () {
      test('executes task with progress callback', () async {
        var progressValues = <double>[];

        final result = await animation.progress(
          message: 'Downloading',
          task: (setProgress) async {
            for (var i = 0; i <= 10; i++) {
              setProgress(i / 10);
              progressValues.add(i / 10);
            }
            return 'complete';
          },
        );

        expect(result, equals('complete'));
        expect(progressValues, hasLength(11));
        expect(progressValues.first, equals(0.0));
        expect(progressValues.last, equals(1.0));
      });

      test('shows progress bar with message', () async {
        await animation.progress(
          message: 'Test',
          task: (setProgress) async {
            setProgress(0.5);
            return null;
          },
        );

        expect(terminal.output, contains('Test'));
        expect(terminal.output, contains('['));
        expect(terminal.output, contains(']'));
      });

      test('clearOnDone clears the line', () async {
        await animation.progress(
          message: 'Downloading',
          task: (setProgress) async {
            setProgress(1.0);
            return null;
          },
          clearOnDone: true,
        );

        expect(terminal.operations, contains('clearLine'));
      });

      test('doneMessage replaces progress bar on completion', () async {
        await animation.progress(
          message: 'Downloading',
          task: (setProgress) async {
            setProgress(1.0);
            return null;
          },
          doneMessage: '✓ Download complete',
        );

        expect(terminal.output, contains('✓ Download complete'));
      });

      test('rethrows on task error', () async {
        expect(
          () => animation.progress(
            message: 'Failing',
            task: (setProgress) async => throw Exception('oops'),
          ),
          throwsException,
        );
      });

      test('hides and shows cursor', () async {
        await animation.progress(
          message: 'Loading',
          task: (setProgress) async => null,
        );

        expect(terminal.operations, contains('hideCursor'));
        expect(terminal.operations, contains('showCursor'));
      });
    });

    group('progressIterate', () {
      test('yields all items', () {
        final items = [1, 2, 3, 4, 5];
        final results = animation.progressIterate(items).toList();

        expect(results, equals([1, 2, 3, 4, 5]));
      });

      test('shows progress bar', () {
        final items = [1, 2, 3];
        animation.progressIterate(items, message: 'Processing').toList();

        expect(terminal.output, contains('Processing'));
        expect(terminal.output, contains('['));
      });

      test('clearOnDone clears the line', () {
        final items = [1, 2, 3];
        animation
            .progressIterate(items, message: 'Processing', clearOnDone: true)
            .toList();

        // Should have clear line at the end
        expect(terminal.operations, contains('clearLine'));
      });

      test('doneMessage shows after iteration', () {
        final items = [1, 2, 3];
        animation
            .progressIterate(
              items,
              message: 'Processing',
              doneMessage: '✓ All done',
            )
            .toList();

        expect(terminal.output, contains('✓ All done'));
      });

      test('handles empty iterable', () {
        final results = animation.progressIterate(<int>[]).toList();
        expect(results, isEmpty);
      });

      test('uses total parameter when provided', () {
        // Create an iterable without a known length
        Iterable<int> generator() sync* {
          yield 1;
          yield 2;
        }

        final results = animation
            .progressIterate(generator(), message: 'Test', total: 2)
            .toList();

        expect(results, equals([1, 2]));
      });
    });

    group('spinAll', () {
      test('executes all tasks and returns results', () async {
        final results = await animation.spinAll(
          tasks: [
            ('Task 1', () async => 1),
            ('Task 2', () async => 2),
            ('Task 3', () async => 3),
          ],
        );

        expect(results, equals([1, 2, 3]));
      });

      test('stops on first error', () async {
        expect(
          () => animation.spinAll(
            tasks: [
              ('Task 1', () async => 1),
              ('Task 2', () async => throw Exception('fail')),
              ('Task 3', () async => 3),
            ],
          ),
          throwsException,
        );
      });

      test('shows checkmarks when showCheckmarks is true', () async {
        await animation.spinAll(
          tasks: [('Task 1', () async => 1)],
          showCheckmarks: true,
          clearOnDone: false,
        );

        expect(terminal.output, contains('✓'));
      });
    });
  });

  group('Spinners', () {
    test('line spinner has 4 frames', () {
      expect(Spinners.line.frames, hasLength(4));
      expect(Spinners.line.frames, equals(['|', '/', '-', '\\']));
    });

    test('miniDot spinner has 10 frames', () {
      expect(Spinners.miniDot.frames, hasLength(10));
    });

    test('dot spinner has 8 frames', () {
      expect(Spinners.dot.frames, hasLength(8));
    });

    test('each spinner has fps duration', () {
      expect(Spinners.line.fps, isA<Duration>());
      expect(Spinners.miniDot.fps, isA<Duration>());
      expect(Spinners.dot.fps, isA<Duration>());
    });

    test('custom spinner can be created', () {
      final custom = Spinner(
        frames: ['⠋', '⠙', '⠸'],
        fps: Duration(milliseconds: 50),
      );

      expect(custom.frames, hasLength(3));
      expect(custom.fps, equals(Duration(milliseconds: 50)));
    });
  });
}
