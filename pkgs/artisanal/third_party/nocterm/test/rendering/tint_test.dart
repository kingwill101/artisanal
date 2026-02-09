import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  group('Tint widget', () {
    test('Tint dims child content', () async {
      await testNocterm(
        'tint dims content',
        (tester) async {
          // First, render some colored text without tint
          await tester.pumpComponent(
            Container(
              color: Colors.blue,
              child: Text(
                'Hello World',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );

          final initialCell = tester.terminalState.getCellAt(0, 0);
          print('Before tint - fg: ${initialCell?.style.color}');

          // Now wrap with Tint widget
          await tester.pumpComponent(
            Tint(
              color: Colors.black.withOpacity(0.6),
              child: Container(
                color: Colors.blue,
                child: Text(
                  'Hello World',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          );

          final tintedCell = tester.terminalState.getCellAt(0, 0);
          print('After tint - fg: ${tintedCell?.style.color}');

          // Text should be preserved
          expect(tintedCell?.char, equals('H'));

          // Colors should be darker
          if (initialCell?.style.color != null &&
              tintedCell?.style.color != null) {
            final initialFg = initialCell!.style.color!;
            final tintedFg = tintedCell!.style.color!;

            expect(
              tintedFg.red < initialFg.red ||
                  tintedFg.green < initialFg.green ||
                  tintedFg.blue < initialFg.blue,
              isTrue,
              reason: 'Tinted foreground should be darker than initial',
            );
          }
        },
        debugPrintAfterPump: true,
      );
    });

    test('Tint with zero alpha has no effect', () async {
      await testNocterm(
        'transparent tint',
        (tester) async {
          // Render with transparent tint
          await tester.pumpComponent(
            Tint(
              color: Colors.black.withOpacity(0.0),
              child: Container(
                color: Colors.blue,
                child: Text(
                  'Hello',
                  style: TextStyle(color: Colors.cyan),
                ),
              ),
            ),
          );

          final cell = tester.terminalState.getCellAt(0, 0);

          // Color should be unchanged (cyan)
          expect(cell?.style.color?.red, equals(Colors.cyan.red));
          expect(cell?.style.color?.green, equals(Colors.cyan.green));
          expect(cell?.style.color?.blue, equals(Colors.cyan.blue));
        },
      );
    });

    test('Tint can apply colored overlay', () async {
      await testNocterm(
        'colored tint',
        (tester) async {
          // Apply a red tint
          await tester.pumpComponent(
            Tint(
              color: Colors.red.withOpacity(0.5),
              child: Container(
                color: Colors.white,
                child: Text(
                  'Test',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          );

          final cell = tester.terminalState.getCellAt(0, 0);

          // Should have reddish tint (red channel higher than others)
          if (cell?.style.color != null) {
            final fg = cell!.style.color!;
            print('Tinted color: (${fg.red}, ${fg.green}, ${fg.blue})');
            // Red channel should be significant due to red tint
            expect(fg.red, greaterThan(fg.green));
            expect(fg.red, greaterThan(fg.blue));
          }
        },
        debugPrintAfterPump: true,
      );
    });
  });

  group('ColoredBox (legacy)', () {
    test('ColoredBox with alpha uses applyTint', () async {
      await testNocterm(
        'coloredbox tint',
        (tester) async {
          // Use Stack to layer ColoredBox over content
          await tester.pumpComponent(
            Stack(
              children: [
                Container(
                  color: Colors.blue,
                  child: Text(
                    'Hello World',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ColoredBox(
                  color: Colors.black.withOpacity(0.6),
                ),
              ],
            ),
          );

          final cell = tester.terminalState.getCellAt(0, 0);

          // Text should be preserved
          expect(cell?.char, equals('H'));

          // Should be dimmed
          if (cell?.style.color != null) {
            final fg = cell!.style.color!;
            // White (248,248,242) dimmed should be significantly darker
            expect(fg.red, lessThan(200));
            expect(fg.green, lessThan(200));
            expect(fg.blue, lessThan(200));
          }
        },
        debugPrintAfterPump: true,
      );
    });
  });
}
