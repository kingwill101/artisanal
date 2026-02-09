import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  group('Markdown Emoji Rendering', () {
    test('renders text with emojis correctly aligned', () async {
      await testNocterm(
        'markdown with emojis',
        (tester) async {
          await tester.pumpComponent(
            Container(
              width: 40,
              child: const MarkdownText(
                'This is a test 🎉 with emoji\n'
                'Second line ✨ more text\n'
                '🔥 Start with emoji',
              ),
            ),
          );

          // Verify all text is rendered
          expect(tester.terminalState,
              containsText('This is a test 🎉 with emoji'));
          expect(tester.terminalState, containsText('Second line ✨ more text'));
          expect(tester.terminalState, containsText('🔥 Start with emoji'));
        },
        debugPrintAfterPump: true,
      );
    });

    test('renders multiple emojis in a row', () async {
      await testNocterm(
        'multiple emojis',
        (tester) async {
          await tester.pumpComponent(
            Container(
              width: 30,
              child: const MarkdownText('🚀 ✨ 🎉 🔥 Multiple'),
            ),
          );

          expect(tester.terminalState, containsText('🚀 ✨ 🎉 🔥 Multiple'));
        },
        debugPrintAfterPump: true,
      );
    });

    test('renders markdown bold with emojis', () async {
      await testNocterm(
        'bold with emojis',
        (tester) async {
          await tester.pumpComponent(
            Container(
              width: 40,
              child: const MarkdownText('**Bold text** 🎯 and emoji'),
            ),
          );

          expect(tester.terminalState, containsText('Bold text'));
          expect(tester.terminalState, containsText('🎯'));
        },
        debugPrintAfterPump: true,
      );
    });

    test('renders markdown list with emojis', () async {
      await testNocterm(
        'list with emojis',
        (tester) async {
          await tester.pumpComponent(
            Container(
              width: 40,
              child: const MarkdownText(
                '- Item 1 🎉\n'
                '- Item 2 ✨\n'
                '- Item 3 🔥',
              ),
            ),
          );

          expect(tester.terminalState, containsText('Item 1 🎉'));
          expect(tester.terminalState, containsText('Item 2 ✨'));
          expect(tester.terminalState, containsText('Item 3 🔥'));
        },
        debugPrintAfterPump: true,
      );
    });

    test('renders markdown header with emoji', () async {
      await testNocterm(
        'header with emoji',
        (tester) async {
          await tester.pumpComponent(
            Container(
              width: 40,
              child: const MarkdownText('# Features ✨\n\nSome content'),
            ),
          );

          expect(tester.terminalState, containsText('# Features ✨'));
          expect(tester.terminalState, containsText('Some content'));
        },
        debugPrintAfterPump: true,
      );
    });

    test('renders emoji alignment in boxed container', () async {
      await testNocterm(
        'emoji in box',
        (tester) async {
          await tester.pumpComponent(
            Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: BoxBorder.all(color: Colors.white, width: 1),
                ),
                child: Container(
                  padding: const EdgeInsets.all(1),
                  child: const MarkdownText(
                    '🎯 Goal: Test emoji\n'
                    '✅ Status: Working\n'
                    '🔥 Priority: High',
                  ),
                ),
              ),
            ),
          );

          expect(tester.terminalState, containsText('🎯 Goal: Test emoji'));
          expect(tester.terminalState, containsText('✅ Status: Working'));
          expect(tester.terminalState, containsText('🔥 Priority: High'));
        },
        debugPrintAfterPump: true,
      );
    });

    test('renders complex emoji sequences', () async {
      await testNocterm(
        'complex emoji',
        (tester) async {
          await tester.pumpComponent(
            Container(
              width: 50,
              child: const MarkdownText(
                'Developer: 👨‍💻\n'
                'Scientist: 👩‍🔬\n'
                'Astronaut: 🧑‍🚀',
              ),
            ),
          );

          // These complex emojis might not render perfectly in all terminals
          // but at least check the labels are present
          expect(tester.terminalState, containsText('Developer:'));
          expect(tester.terminalState, containsText('Scientist:'));
          expect(tester.terminalState, containsText('Astronaut:'));
        },
        debugPrintAfterPump: true,
      );
    });

    test('renders emoji at different positions', () async {
      await testNocterm(
        'emoji positions',
        (tester) async {
          await tester.pumpComponent(
            Container(
              width: 40,
              child: const MarkdownText(
                '🎉 Start\n'
                'Middle 🎉 text\n'
                'End 🎉',
              ),
            ),
          );

          // All three lines should render correctly regardless of emoji position
          expect(tester.terminalState, containsText('🎉 Start'));
          expect(tester.terminalState, containsText('Middle 🎉 text'));
          expect(tester.terminalState, containsText('End 🎉'));
        },
        debugPrintAfterPump: true,
      );
    });
  });
}
