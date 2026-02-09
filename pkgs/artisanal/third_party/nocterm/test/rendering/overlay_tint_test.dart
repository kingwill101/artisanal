import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  group('Overlay tint effect', () {
    test('FadeModalBarrier dims background content in overlay', () async {
      await testNocterm(
        'overlay dimming',
        (tester) async {
          // Simulate the overlay demo structure
          await tester.pumpComponent(
            Overlay(
              initialEntries: [
                // Base content (like the main screen)
                OverlayEntry(
                  builder: (context) => Container(
                    color: Colors.blue,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Overlay Demo',
                            style: TextStyle(
                              color: Colors.cyan,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text('This is the background content'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );

          // Record colors BEFORE overlay
          print('=== BEFORE OVERLAY ===');
          // Find the cyan text "Overlay Demo" - should be centered
          final centerY = 12; // Roughly center of 24 row terminal

          // Find a cell with content
          Cell? beforeCell;
          for (int x = 0; x < 80; x++) {
            final cell = tester.terminalState.getCellAt(x, centerY - 2);
            if (cell != null && cell.char != ' ') {
              beforeCell = cell;
              print('Found cell at ($x, ${centerY - 2}): "${cell.char}"');
              print('  fg: ${cell.style.color}');
              print('  bg: ${cell.style.backgroundColor}');
              break;
            }
          }

          // Now add the overlay with barrier
          final overlayState = tester.findState<OverlayState>();

          // Insert overlay entry with FadeModalBarrier
          overlayState.insert(
            OverlayEntry(
              builder: (context) => Stack(
                children: [
                  // The dimming barrier
                  FadeModalBarrier(
                    color: Colors.black.withOpacity(0.6),
                    dismissible: false,
                    duration: Duration.zero, // No animation for testing
                  ),
                  // A dialog on top
                  Positioned(
                    left: 10,
                    top: 5,
                    child: Container(
                      width: 20,
                      height: 5,
                      color: Colors.black,
                      child: const Center(child: Text('Dialog')),
                    ),
                  ),
                ],
              ),
            ),
          );

          // Pump a few frames to let animation complete
          await tester.pump(const Duration(milliseconds: 50));
          await tester.pump(const Duration(milliseconds: 50));
          await tester.pump(const Duration(milliseconds: 50));

          print('\n=== AFTER OVERLAY ===');
          // Find the same cell position
          Cell? afterCell;
          for (int x = 0; x < 80; x++) {
            final cell = tester.terminalState.getCellAt(x, centerY - 2);
            if (cell != null && cell.char != ' ' && cell.char != 'D') {
              afterCell = cell;
              print('Found cell at ($x, ${centerY - 2}): "${cell.char}"');
              print('  fg: ${cell.style.color}');
              print('  bg: ${cell.style.backgroundColor}');
              break;
            }
          }

          print('\n=== COMPARISON ===');
          if (beforeCell != null && afterCell != null) {
            print('Before fg: ${beforeCell.style.color}');
            print('After fg:  ${afterCell.style.color}');
            print('Before bg: ${beforeCell.style.backgroundColor}');
            print('After bg:  ${afterCell.style.backgroundColor}');

            // Character should be preserved
            expect(afterCell.char, equals(beforeCell.char),
                reason: 'Character should be preserved through tint');

            // Colors should be different (darker)
            if (beforeCell.style.color != null &&
                afterCell.style.color != null) {
              final beforeFg = beforeCell.style.color!;
              final afterFg = afterCell.style.color!;

              print(
                  '\nFg RGB before: (${beforeFg.red}, ${beforeFg.green}, ${beforeFg.blue})');
              print(
                  'Fg RGB after:  (${afterFg.red}, ${afterFg.green}, ${afterFg.blue})');

              // At least one channel should be darker
              final isDarker = afterFg.red < beforeFg.red ||
                  afterFg.green < beforeFg.green ||
                  afterFg.blue < beforeFg.blue;

              expect(isDarker, isTrue,
                  reason: 'Foreground color should be darker after overlay');
            }
          }
        },
        debugPrintAfterPump: true,
      );
    });
  });
}
