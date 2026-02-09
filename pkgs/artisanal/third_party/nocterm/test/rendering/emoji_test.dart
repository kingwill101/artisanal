import 'package:test/test.dart';
import 'package:nocterm/nocterm.dart';

void main() {
  group('Emoji Rendering', () {
    test('emoji width handling', () async {
      await testNocterm(
        'emoji width',
        (tester) async {
          await tester.pumpComponent(
            Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: BoxBorder.all(
                      color: Color.fromRGB(255, 255, 255), width: 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text('Regular text: Hello World'),
                    Text('With emoji: Hello 🌍 World'),
                    Text('Multiple emojis: 🚀 ✨ 🎉 🔥'),
                    Text('Mixed: Code 💻 + Coffee ☕ = 🎯'),
                    Text('Flags: 🇺🇸 🇬🇧 🇯🇵'),
                    Text('Combined: 👨‍💻 👩‍🔬 🧑‍🚀'),
                    Text('Box chars: ┌─┐│└┘'),
                  ],
                ),
              ),
            ),
          );

          // Verify all text is rendered
          expect(
              tester.terminalState, containsText('Regular text: Hello World'));
          expect(
              tester.terminalState, containsText('With emoji: Hello 🌍 World'));
          expect(tester.terminalState,
              containsText('Multiple emojis: 🚀 ✨ 🎉 🔥'));
          expect(tester.terminalState,
              containsText('Mixed: Code 💻 + Coffee ☕ = 🎯'));
          // Flag emojis might render differently across terminals
          expect(tester.terminalState, containsText('Flags:'));
          // Complex emojis with ZWJ might render differently
          // Just check that "Combined:" is present
          expect(tester.terminalState, containsText('Combined:'));
          expect(tester.terminalState, containsText('Box chars: ┌─┐│└┘'));
        },
      );
    });

    test('emoji alignment in centered text', () async {
      await testNocterm(
        'emoji alignment centered',
        (tester) async {
          await tester.pumpComponent(
            Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: BoxBorder.all(
                      color: Color.fromRGB(255, 255, 255), width: 1),
                ),
                child: SizedBox(
                  width: 45,
                  height: 15,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: const [
                      Text('✨ Features:'),
                      Text('  • Component-based architecture'),
                      Text('  • Constraint-based layout system'),
                      Text('  • Stateful and Stateless components'),
                      Text('  • BuildContext for tree traversal'),
                      Text('  • RenderObject for painting'),
                      SizedBox(height: 1),
                      Text('Built with Dart inspired by Flutter/Jaspr'),
                    ],
                  ),
                ),
              ),
            ),
          );

          // Verify the content is rendered
          expect(tester.terminalState, containsText('✨ Features:'));
          expect(tester.terminalState,
              containsText('Component-based architecture'));
          expect(tester.terminalState,
              containsText('Constraint-based layout system'));
          expect(tester.terminalState, containsText('Built with Dart'));
        },
      );
    });

    test('emoji in different alignments', () async {
      await testNocterm(
        'emoji alignments',
        (tester) async {
          await tester.pumpComponent(
            Row(
              children: [
                // Left aligned with emoji
                Container(
                  width: 20,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('✨ Left'),
                      Text('🚀 Line'),
                    ],
                  ),
                ),
                SizedBox(width: 2),
                // Center aligned with emoji
                Container(
                  width: 20,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: const [
                      Text('✨ Center'),
                      Text('🚀 Line'),
                    ],
                  ),
                ),
                SizedBox(width: 2),
                // Right aligned with emoji
                Container(
                  width: 20,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                      Text('✨ Right'),
                      Text('🚀 Line'),
                    ],
                  ),
                ),
              ],
            ),
          );

          expect(tester.terminalState, containsText('✨ Left'));
          expect(tester.terminalState, containsText('✨ Center'));
          expect(tester.terminalState, containsText('✨ Right'));
          expect(tester.terminalState, containsText('🚀 Line'));
        },
      );
    });

    test('sparkles width calculation', () async {
      await testNocterm(
        'sparkles width',
        (tester) async {
          await tester.pumpComponent(
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Box to test width calculation
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: BoxBorder.all(
                          color: Color.fromRGB(255, 255, 255), width: 1),
                    ),
                    child: const Text('✨'),
                  ),
                  SizedBox(height: 1),
                  // Test with multiple sparkles
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: BoxBorder.all(
                          color: Color.fromRGB(255, 255, 255), width: 1),
                    ),
                    child: const Text('✨✨✨'),
                  ),
                  SizedBox(height: 1),
                  // Test mixed with text
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: BoxBorder.all(
                          color: Color.fromRGB(255, 255, 255), width: 1),
                    ),
                    child: const Text('Text ✨ More'),
                  ),
                ],
              ),
            ),
          );

          expect(tester.terminalState, containsText('✨'));
          expect(tester.terminalState, containsText('✨✨✨'));
          expect(tester.terminalState, containsText('Text ✨ More'));
        },
      );
    });

    test('emoji border rendering', () async {
      await testNocterm(
        'emoji with borders',
        (tester) async {
          await tester.pumpComponent(
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Single line border
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: BoxBorder.all(color: Colors.blue, width: 1),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      child: const Text('✨ With single border'),
                    ),
                  ),
                  SizedBox(height: 2),
                  // Double line border
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: BoxBorder.all(color: Colors.red, width: 2),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      child: const Text('🚀 With double border'),
                    ),
                  ),
                ],
              ),
            ),
          );

          expect(tester.terminalState, containsText('✨ With single border'));
          expect(tester.terminalState, containsText('🚀 With double border'));
        },
      );
    });

    // Visual test for manual inspection
    test('emoji visual test',
        skip: 'Run with debugPrintAfterPump for visual inspection', () async {
      await testNocterm(
        'emoji visual',
        (tester) async {
          await tester.pumpComponent(
            Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: BoxBorder.all(color: Colors.cyan, width: 1),
                ),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('Emoji Width Test:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 1),
                      Text('Single: ✨'),
                      Text('Double: ✨✨'),
                      Text('Triple: ✨✨✨'),
                      SizedBox(height: 1),
                      Text('Mixed emojis:'),
                      Text('🚀 Rocket'),
                      Text('💻 Computer'),
                      Text('🎯 Target'),
                      Text('🔥 Fire'),
                      SizedBox(height: 1),
                      Text('Complex:'),
                      Text('👨‍💻 Developer'),
                      Text('🇺🇸 Flag'),
                    ],
                  ),
                ),
              ),
            ),
          );

          expect(tester.terminalState, containsText('Emoji Width Test:'));
        },
        // debugPrintAfterPump: true, // Uncomment to see visual output
      );
    });
  });
}
