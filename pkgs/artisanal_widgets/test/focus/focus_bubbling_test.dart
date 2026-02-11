import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:artisanal_widgets/testing.dart';
import 'package:artisanal/tui.dart' as tui;
import 'package:test/test.dart';

void main() {
  group('Focus Bubbling', () {
    test('focused child handles key, parent is skipped', () async {
      final tester = WidgetTester();
      try {
        String? handledBy;

        await tester.pumpWidget(
          w.FocusScope(
            child: w.Focusable(
              focusId: 'parent',
              onKey: (msg) {
                handledBy = 'parent';
                return tui.Cmd.none();
              },
              child: w.Focusable(
                focusId: 'child',
                autofocus: true,
                onKey: (msg) {
                  handledBy = 'child';
                  return tui.Cmd.none();
                },
                child: w.Text('focused'),
              ),
            ),
          ),
        );

        tester.sendKey('a');
        expect(handledBy, equals('child'));
      } finally {
        await tester.dispose();
      }
    });

    test('focused child returns null, parent bubbles up', () async {
      final tester = WidgetTester();
      try {
        String? handledBy;

        await tester.pumpWidget(
          w.FocusScope(
            child: w.Focusable(
              focusId: 'parent',
              onKey: (msg) {
                handledBy = 'parent';
                return tui.Cmd.none();
              },
              child: w.Focusable(
                focusId: 'child',
                autofocus: true,
                onKey: (msg) => null, // Bubble up
                child: w.Text('focused'),
              ),
            ),
          ),
        );

        tester.sendKey('a');
        expect(handledBy, equals('parent'));
      } finally {
        await tester.dispose();
      }
    });
  });

  group('KeyboardListener Interception', () {
    test('parent KeyboardListener intercepts before focused child', () async {
      final tester = WidgetTester();
      try {
        String? handledBy;

        await tester.pumpWidget(
          w.KeyboardListener(
            onKey: (msg) {
              handledBy = 'listener';
              return tui.Cmd.none(); // Intercept!
            },
            child: w.FocusScope(
              child: w.Focusable(
                autofocus: true,
                onKey: (msg) {
                  handledBy = 'focusable';
                  return tui.Cmd.none();
                },
                child: w.Text('focused'),
              ),
            ),
          ),
        );

        tester.sendKey('a');
        expect(handledBy, equals('listener'));
      } finally {
        await tester.dispose();
      }
    });

    test('KeyboardListener passes through if it returns null', () async {
      final tester = WidgetTester();
      try {
        String? handledBy;

        await tester.pumpWidget(
          w.KeyboardListener(
            onKey: (msg) => null, // Pass through
            child: w.FocusScope(
              child: w.Focusable(
                autofocus: true,
                onKey: (msg) {
                  handledBy = 'focusable';
                  return tui.Cmd.none();
                },
                child: w.Text('focused'),
              ),
            ),
          ),
        );

        tester.sendKey('a');
        expect(handledBy, equals('focusable'));
      } finally {
        await tester.dispose();
      }
    });
  });
}
