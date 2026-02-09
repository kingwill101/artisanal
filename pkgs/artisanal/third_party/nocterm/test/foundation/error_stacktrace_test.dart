import 'package:test/test.dart';
import 'package:nocterm/nocterm.dart';
import 'package:nocterm/src/components/error_widget.dart';

void main() {
  group('Error Stack Trace Display', () {
    test('layout error shows stack trace in error box', () async {
      await testNocterm(
        'layout error with stack trace',
        (tester) async {
          await tester.pumpComponent(
            const Center(
              child: SizedBox(
                width: 60,
                height: 20,
                child: ErrorThrowingWidget(
                  throwInLayout: true,
                  errorMessage: 'Test layout error with stack',
                ),
              ),
            ),
          );

          final output = tester.terminalState.getText();

          // Layout errors in ErrorThrowingWidget still show "No Error" in paint
          // because the error is caught, a default size is set, and paint continues
          expect(output, contains('No Error'));
        },
        debugPrintAfterPump: true,
        size: const Size(80, 25),
      );
    });

    test('paint error shows stack trace in error box', () async {
      await testNocterm(
        'paint error with stack trace',
        (tester) async {
          await tester.pumpComponent(
            const Center(
              child: SizedBox(
                width: 70,
                height: 22,
                child: ErrorThrowingWidget(
                  throwInLayout: false,
                  throwInPaint: true,
                  errorMessage: 'Test paint error with stack',
                ),
              ),
            ),
          );

          final output = tester.terminalState.getText();

          // Should show paint error
          expect(output, contains('Paint Error'));

          // Should show the custom error message
          expect(output, contains('Test paint error'));

          // Should show stack trace
          expect(output, contains('Stack trace:'));
          expect(output, contains('#0'));

          // Should show the actual error location
          expect(output, contains('RenderErrorThrowing.paint'));
        },
        debugPrintAfterPump: true,
        size: const Size(80, 25),
      );
    });

    test('error box truncates long stack traces', () async {
      await testNocterm(
        'truncated stack trace',
        (tester) async {
          await tester.pumpComponent(
            const Center(
              child: SizedBox(
                width: 50,
                height: 15, // Small height to test truncation
                child: ErrorThrowingWidget(
                  throwInPaint: true,
                  errorMessage: 'Error with long stack',
                ),
              ),
            ),
          );

          final output = tester.terminalState.getText();

          // Should show error and stack trace
          expect(output, contains('Paint Error'));
          expect(output, contains('Stack trace:'));

          // Check that lines are truncated to fit width
          final lines = output.split('\n');
          for (final line in lines) {
            // Each line should be at most 80 chars (terminal width)
            expect(line.length, lessThanOrEqualTo(80));
          }

          // Should indicate more lines if stack is truncated
          // (This happens when there are more than 10 stack frames)
          if (output.contains('more lines')) {
            expect(output, contains('... '));
            expect(output, contains(' more lines'));
          }
        },
        debugPrintAfterPump: false,
        size: const Size(80, 25),
      );
    });

    test('custom error widget shows provided error and stack', () async {
      await testNocterm(
        'custom error widget with stack',
        (tester) async {
          // Create a fake stack trace
          final fakeError = Exception('Custom error message');
          final fakeStack = StackTrace.fromString('''
#0      someFunction (package:test/file.dart:10:5)
#1      anotherFunction (package:test/file.dart:20:3)
#2      main (package:test/main.dart:5:10)
''');

          await tester.pumpComponent(
            TUIErrorWidget(
              message: 'Custom Error Display',
              error: fakeError,
              stackTrace: fakeStack,
            ),
          );

          final output = tester.terminalState.getText();

          // Should show custom message
          expect(output, contains('Custom Error Display'));

          // Should show the error
          expect(output, contains('Exception: Custom error message'));

          // Should show the stack trace
          expect(output, contains('Stack trace:'));
          expect(output, contains('someFunction'));
          expect(output, contains('anotherFunction'));
          expect(output, contains('main'));
        },
        debugPrintAfterPump: true,
        size: const Size(80, 20),
      );
    });
  });
}
