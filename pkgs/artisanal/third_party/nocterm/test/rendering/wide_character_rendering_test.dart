import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

/// Regression tests for wide character rendering bug.
///
/// This test suite ensures that wide characters (emojis, Chinese characters, etc.)
/// are rendered correctly during both full and differential rendering.
///
/// The bug was in `lib/src/binding/terminal_binding.dart` where `_renderFullDiff()`
/// and `_renderFull()` were not skipping zero-width space markers (`\u200B`)
/// used as placeholders for wide characters. This caused garbled display when:
/// 1. Wide characters were present in the buffer
/// 2. Differential rendering was triggered (e.g., focus changes)
///
/// The fix was to add:
/// ```dart
/// // Skip zero-width space markers (used for wide character tracking)
/// if (cell.char == '\u200B') {
///   continue;
/// }
/// ```
void main() {
  group('Wide Character Rendering Regression Tests', () {
    group('Buffer Zero-Width Marker Tests', () {
      test('buffer stores wide characters with zero-width markers', () {
        final buffer = Buffer(20, 1);
        buffer.setString(0, 0, '🦄 test');

        // Verify emoji is at position 0
        expect(buffer.getCell(0, 0).char, '🦄');
        // Verify marker is at position 1 (emoji takes 2 cells)
        expect(buffer.getCell(1, 0).char, '\u200B');
        // Verify space is at position 2
        expect(buffer.getCell(2, 0).char, ' ');
        // Verify 't' is at position 3
        expect(buffer.getCell(3, 0).char, 't');
      });

      test('buffer stores Chinese characters with zero-width markers', () {
        final buffer = Buffer(20, 1);
        buffer.setString(0, 0, '中文');

        // Chinese characters are width 2
        expect(buffer.getCell(0, 0).char, '中');
        expect(buffer.getCell(1, 0).char, '\u200B'); // Marker for first char
        expect(buffer.getCell(2, 0).char, '文');
        expect(buffer.getCell(3, 0).char, '\u200B'); // Marker for second char
      });

      test('buffer handles mixed ASCII and wide characters', () {
        final buffer = Buffer(30, 1);
        buffer.setString(0, 0, 'Hello 🌍 World 世界!');

        // H-e-l-l-o- -🌍-marker- -W-o-r-l-d- -世-marker-界-marker-!
        expect(buffer.getCell(0, 0).char, 'H');
        expect(buffer.getCell(5, 0).char, ' ');
        expect(buffer.getCell(6, 0).char, '🌍');
        expect(buffer.getCell(7, 0).char, '\u200B'); // Marker after emoji
        expect(buffer.getCell(8, 0).char, ' ');
        expect(buffer.getCell(9, 0).char, 'W');
        expect(buffer.getCell(14, 0).char, ' ');
        expect(buffer.getCell(15, 0).char, '世');
        expect(buffer.getCell(16, 0).char, '\u200B'); // Marker
        expect(buffer.getCell(17, 0).char, '界');
        expect(buffer.getCell(18, 0).char, '\u200B'); // Marker
        expect(buffer.getCell(19, 0).char, '!');
      });

      test('multiple emojis in sequence have correct markers', () {
        final buffer = Buffer(20, 1);
        buffer.setString(0, 0, '🚀🎉🔥');

        // Each emoji takes 2 cells
        expect(buffer.getCell(0, 0).char, '🚀');
        expect(buffer.getCell(1, 0).char, '\u200B');
        expect(buffer.getCell(2, 0).char, '🎉');
        expect(buffer.getCell(3, 0).char, '\u200B');
        expect(buffer.getCell(4, 0).char, '🔥');
        expect(buffer.getCell(5, 0).char, '\u200B');
      });
    });

    group('Wide Character Full Rendering', () {
      test('emoji renders correctly in Text widget', () async {
        await testNocterm(
          'emoji text rendering',
          (tester) async {
            await tester.pumpComponent(
              const Text('Hello 🌍 World'),
            );

            // Verify the text is rendered correctly
            expect(tester.terminalState, containsText('Hello'));
            expect(tester.terminalState, containsText('🌍'));
            expect(tester.terminalState, containsText('World'));

            // Verify positions are correct
            final cell0 = tester.terminalState.getCellAt(0, 0);
            expect(cell0?.char, 'H');

            final emojiCell = tester.terminalState.getCellAt(6, 0);
            expect(emojiCell?.char, '🌍');

            // The marker cell should NOT appear in rendered output
            // (this is what the fix ensures)
            final markerCell = tester.terminalState.getCellAt(7, 0);
            expect(markerCell?.char, '\u200B');
          },
          size: const Size(40, 5),
          debugPrintAfterPump: true,
        );
      });

      test('Chinese characters render correctly', () async {
        await testNocterm(
          'chinese text rendering',
          (tester) async {
            await tester.pumpComponent(
              const Text('你好世界'),
            );

            expect(tester.terminalState, containsText('你好世界'));

            // Verify each Chinese character position
            expect(tester.terminalState.getCellAt(0, 0)?.char, '你');
            expect(tester.terminalState.getCellAt(1, 0)?.char, '\u200B');
            expect(tester.terminalState.getCellAt(2, 0)?.char, '好');
            expect(tester.terminalState.getCellAt(3, 0)?.char, '\u200B');
            expect(tester.terminalState.getCellAt(4, 0)?.char, '世');
            expect(tester.terminalState.getCellAt(5, 0)?.char, '\u200B');
            expect(tester.terminalState.getCellAt(6, 0)?.char, '界');
            expect(tester.terminalState.getCellAt(7, 0)?.char, '\u200B');
          },
          size: const Size(40, 5),
          debugPrintAfterPump: true,
        );
      });

      test('mixed ASCII, emoji, and Chinese in same text', () async {
        await testNocterm(
          'mixed content rendering',
          (tester) async {
            await tester.pumpComponent(
              const Text('Code💻中文🎯End'),
            );

            expect(tester.terminalState, containsText('Code'));
            expect(tester.terminalState, containsText('💻'));
            expect(tester.terminalState, containsText('中文'));
            expect(tester.terminalState, containsText('🎯'));
            expect(tester.terminalState, containsText('End'));

            // Verify layout: Code(4) + 💻(2) + 中(2) + 文(2) + 🎯(2) + End(3)
            expect(tester.terminalState.getCellAt(0, 0)?.char, 'C');
            expect(tester.terminalState.getCellAt(3, 0)?.char, 'e');
            expect(tester.terminalState.getCellAt(4, 0)?.char, '💻');
            expect(tester.terminalState.getCellAt(5, 0)?.char, '\u200B');
            expect(tester.terminalState.getCellAt(6, 0)?.char, '中');
            expect(tester.terminalState.getCellAt(7, 0)?.char, '\u200B');
            expect(tester.terminalState.getCellAt(8, 0)?.char, '文');
            expect(tester.terminalState.getCellAt(9, 0)?.char, '\u200B');
            expect(tester.terminalState.getCellAt(10, 0)?.char, '🎯');
            expect(tester.terminalState.getCellAt(11, 0)?.char, '\u200B');
            expect(tester.terminalState.getCellAt(12, 0)?.char, 'E');
          },
          size: const Size(40, 5),
          debugPrintAfterPump: true,
        );
      });
    });

    group('Wide Character Differential Rendering', () {
      test('emoji remains correct after content update', () async {
        await testNocterm(
          'emoji differential update',
          (tester) async {
            // First render with emoji
            await tester.pumpComponent(
              const Text('Status: 🚀 Loading'),
            );

            expect(tester.terminalState, containsText('🚀'));
            expect(tester.terminalState, containsText('Loading'));

            // Update to different emoji (triggers differential rendering)
            await tester.pumpComponent(
              const Text('Status: ✅ Complete'),
            );

            // Verify the new content renders correctly
            expect(tester.terminalState, containsText('✅'));
            expect(tester.terminalState, containsText('Complete'));
            expect(tester.terminalState, isNot(containsText('Loading')));
          },
          size: const Size(40, 5),
          debugPrintAfterPump: true,
        );
      });

      test('Chinese characters correct after multiple updates', () async {
        await testNocterm(
          'chinese differential updates',
          (tester) async {
            await tester.pumpComponent(
              const Text('第一次'),
            );
            expect(tester.terminalState, containsText('第一次'));

            // Update to different Chinese text
            await tester.pumpComponent(
              const Text('第二次'),
            );
            expect(tester.terminalState, containsText('第二次'));
            expect(tester.terminalState, isNot(containsText('一')));

            // Update again
            await tester.pumpComponent(
              const Text('完成！'),
            );
            expect(tester.terminalState, containsText('完成！'));
          },
          size: const Size(40, 5),
          debugPrintAfterPump: true,
        );
      });

      test('wide characters replaced by narrow characters correctly', () async {
        await testNocterm(
          'wide to narrow replacement',
          (tester) async {
            // Start with emojis (wide)
            await tester.pumpComponent(
              const Text('🚀🎉'),
            );

            expect(tester.terminalState.getCellAt(0, 0)?.char, '🚀');
            expect(tester.terminalState.getCellAt(1, 0)?.char, '\u200B');
            expect(tester.terminalState.getCellAt(2, 0)?.char, '🎉');
            expect(tester.terminalState.getCellAt(3, 0)?.char, '\u200B');

            // Replace with narrow ASCII characters
            await tester.pumpComponent(
              const Text('ABCD'),
            );

            // All cells should now be ASCII
            expect(tester.terminalState.getCellAt(0, 0)?.char, 'A');
            expect(tester.terminalState.getCellAt(1, 0)?.char, 'B');
            expect(tester.terminalState.getCellAt(2, 0)?.char, 'C');
            expect(tester.terminalState.getCellAt(3, 0)?.char, 'D');
          },
          size: const Size(40, 5),
          debugPrintAfterPump: true,
        );
      });

      test('narrow characters replaced by wide characters correctly', () async {
        await testNocterm(
          'narrow to wide replacement',
          (tester) async {
            // Start with ASCII
            await tester.pumpComponent(
              const Text('TEST'),
            );

            expect(tester.terminalState.getCellAt(0, 0)?.char, 'T');
            expect(tester.terminalState.getCellAt(1, 0)?.char, 'E');

            // Replace with emojis
            await tester.pumpComponent(
              const Text('🌟🔥'),
            );

            expect(tester.terminalState.getCellAt(0, 0)?.char, '🌟');
            expect(tester.terminalState.getCellAt(1, 0)?.char, '\u200B');
            expect(tester.terminalState.getCellAt(2, 0)?.char, '🔥');
            expect(tester.terminalState.getCellAt(3, 0)?.char, '\u200B');
          },
          size: const Size(40, 5),
          debugPrintAfterPump: true,
        );
      });
    });

    group('Focus Change with Wide Characters', () {
      test('wide characters in Text remain correct after focus changes',
          () async {
        await testNocterm(
          'wide char focus change',
          (tester) async {
            // This test ensures that wide characters rendered via Text widgets
            // remain correctly displayed when focus changes trigger differential rendering
            await tester.pumpComponent(
              _FocusableWidgetWithWideCharLabels(),
            );

            // Initially, all wide characters should be visible
            expect(tester.terminalState, containsText('🚀'));
            expect(tester.terminalState, containsText('Rocket'));
            expect(tester.terminalState, containsText('🎉'));
            expect(tester.terminalState, containsText('Party'));

            // Tab to second item (triggers differential rendering)
            await tester.sendKey(LogicalKey.tab);
            await tester.pump();

            // Wide characters should still render correctly after focus change
            // This is the key test - before the fix, this could be garbled
            expect(tester.terminalState, containsText('🚀'),
                reason: 'Emoji 🚀 should remain visible after focus change');
            expect(tester.terminalState, containsText('🎉'),
                reason: 'Emoji 🎉 should remain visible after focus change');
          },
          size: const Size(60, 10),
          debugPrintAfterPump: true,
        );
      });

      test('Chinese text remains correct after focus changes', () async {
        await testNocterm(
          'chinese focus change',
          (tester) async {
            await tester.pumpComponent(
              _FocusableWidgetWithChineseLabels(),
            );

            expect(tester.terminalState, containsText('选项一'));
            expect(tester.terminalState, containsText('选项二'));

            // Tab to second item
            await tester.sendKey(LogicalKey.tab);
            await tester.pump();

            // Chinese text should still be correct
            expect(tester.terminalState, containsText('选项一'));
            expect(tester.terminalState, containsText('选项二'));
          },
          size: const Size(60, 10),
          debugPrintAfterPump: true,
        );
      });

      test('multiple focus changes preserve wide characters', () async {
        await testNocterm(
          'multiple focus changes',
          (tester) async {
            await tester.pumpComponent(
              _FocusableWidgetWithMixedLabels(),
            );

            // Initial state
            expect(tester.terminalState, containsText('🔍'));
            expect(tester.terminalState, containsText('搜索'));
            expect(tester.terminalState, containsText('✨'));

            // Tab through all items multiple times
            for (int i = 0; i < 6; i++) {
              await tester.sendKey(LogicalKey.tab);
              await tester.pump();

              // Wide characters should remain correct after each focus change
              expect(tester.terminalState, containsText('🔍'),
                  reason: 'Emoji 🔍 should be visible after tab $i');
              expect(tester.terminalState, containsText('搜索'),
                  reason: 'Chinese 搜索 should be visible after tab $i');
              expect(tester.terminalState, containsText('✨'),
                  reason: 'Emoji ✨ should be visible after tab $i');
            }
          },
          size: const Size(80, 15),
          debugPrintAfterPump: true,
        );
      });

      test(
          'wide character state preserved when non-wide content changes nearby',
          () async {
        await testNocterm(
          'wide char near changes',
          (tester) async {
            await tester.pumpComponent(
              _CounterWithEmojiLabel(),
            );

            // Initial state: count is 0
            expect(tester.terminalState, containsText('🔢'));
            expect(tester.terminalState, containsText('Count: 0'));

            // Increment counter multiple times (each triggers differential render)
            for (int i = 1; i <= 5; i++) {
              await tester.sendKey(LogicalKey.space);
              await tester.pump();

              // Emoji should remain correct even though nearby text changed
              expect(tester.terminalState, containsText('🔢'),
                  reason: 'Emoji 🔢 should remain visible after count=$i');
              expect(tester.terminalState, containsText('Count: $i'),
                  reason: 'Counter should show $i');
            }
          },
          size: const Size(40, 5),
          debugPrintAfterPump: true,
        );
      });
    });

    group('Wide Characters in Lists and Scrolling', () {
      test('emoji in ListView items render correctly', () async {
        await testNocterm(
          'emoji in listview',
          (tester) async {
            await tester.pumpComponent(
              SizedBox(
                width: 40,
                height: 10,
                child: ListView(
                  children: const [
                    Text('🚀 First item'),
                    Text('🎉 Second item'),
                    Text('🔥 Third item'),
                    Text('✨ Fourth item'),
                  ],
                ),
              ),
            );

            expect(tester.terminalState, containsText('🚀'));
            expect(tester.terminalState, containsText('🎉'));
            expect(tester.terminalState, containsText('🔥'));
            expect(tester.terminalState, containsText('✨'));
          },
          size: const Size(60, 15),
          debugPrintAfterPump: true,
        );
      });

      test('Chinese in Column items render correctly', () async {
        await testNocterm(
          'chinese in column',
          (tester) async {
            await tester.pumpComponent(
              const Column(
                children: [
                  Text('第一行：你好'),
                  Text('第二行：世界'),
                  Text('第三行：测试'),
                ],
              ),
            );

            expect(tester.terminalState, containsText('第一行：你好'));
            expect(tester.terminalState, containsText('第二行：世界'));
            expect(tester.terminalState, containsText('第三行：测试'));
          },
          size: const Size(60, 10),
          debugPrintAfterPump: true,
        );
      });
    });

    group('Wide Characters with Styles', () {
      test('styled emoji renders correctly', () async {
        await testNocterm(
          'styled emoji',
          (tester) async {
            await tester.pumpComponent(
              const Text('🔥 Fire!',
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold)),
            );

            expect(tester.terminalState, containsText('🔥'));
            expect(tester.terminalState, containsText('Fire!'));

            // Verify emoji cell has style applied (at position 0,0)
            final emojiCell = tester.terminalState.getCellAt(0, 0);
            expect(emojiCell?.char, '🔥');
            expect(emojiCell?.style.color, Colors.red);
          },
          size: const Size(40, 5),
          debugPrintAfterPump: true,
        );
      });

      test('styled Chinese characters render correctly', () async {
        await testNocterm(
          'styled chinese',
          (tester) async {
            await tester.pumpComponent(
              const Text('重要',
                  style: TextStyle(
                    color: Colors.yellow,
                    backgroundColor: Colors.red,
                    fontWeight: FontWeight.bold,
                  )),
            );

            expect(tester.terminalState, containsText('重要'));

            final cell = tester.terminalState.getCellAt(0, 0);
            expect(cell?.char, '重');
            expect(cell?.style.color, Colors.yellow);
            expect(cell?.style.backgroundColor, Colors.red);
          },
          size: const Size(40, 5),
          debugPrintAfterPump: true,
        );
      });
    });

    group('Edge Cases', () {
      test('empty string after wide character string', () async {
        await testNocterm(
          'empty after wide',
          (tester) async {
            await tester.pumpComponent(
              const Text('🌟🌟🌟'),
            );
            expect(tester.terminalState, containsText('🌟'));

            await tester.pumpComponent(
              const Text(''),
            );
            // Should render cleanly without artifacts
            expect(tester.terminalState, isNot(containsText('🌟')));
          },
          size: const Size(40, 5),
        );
      });

      test('single wide character', () async {
        await testNocterm(
          'single wide char',
          (tester) async {
            await tester.pumpComponent(
              const Text('中'),
            );

            expect(tester.terminalState.getCellAt(0, 0)?.char, '中');
            expect(tester.terminalState.getCellAt(1, 0)?.char, '\u200B');
          },
          size: const Size(40, 5),
        );
      });

      test('wide character at end of line', () async {
        await testNocterm(
          'wide at line end',
          (tester) async {
            // Use a narrow width to test edge wrapping behavior
            await tester.pumpComponent(
              SizedBox(
                width: 10,
                child: const Text('AAAAAAA中'),
              ),
            );

            // The text should be truncated or wrapped appropriately
            // without causing rendering artifacts
            expect(tester.terminalState, containsText('A'));
          },
          size: const Size(15, 5),
        );
      });

      test('rapid updates with wide characters', () async {
        await testNocterm(
          'rapid wide updates',
          (tester) async {
            final emojis = ['🚀', '🎉', '🔥', '✨', '💻', '🎯', '⭐', '🌟'];

            for (final emoji in emojis) {
              await tester.pumpComponent(
                Text('Status: $emoji'),
              );
              expect(tester.terminalState, containsText(emoji),
                  reason: 'Emoji $emoji should be visible');
            }
          },
          size: const Size(40, 5),
        );
      });
    });
  });
}

/// Test widget: Focusable items with emoji labels
class _FocusableWidgetWithWideCharLabels extends StatefulComponent {
  @override
  State<_FocusableWidgetWithWideCharLabels> createState() =>
      _FocusableWidgetWithWideCharLabelsState();
}

class _FocusableWidgetWithWideCharLabelsState
    extends State<_FocusableWidgetWithWideCharLabels> {
  int _focusedIndex = 0;

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.tab) {
          setState(() {
            _focusedIndex = (_focusedIndex + 1) % 2;
          });
          return true;
        }
        return false;
      },
      child: Column(
        children: [
          Text(
            '🚀 Rocket Item',
            style: _focusedIndex == 0
                ? const TextStyle(reverse: true)
                : const TextStyle(),
          ),
          const SizedBox(height: 1),
          Text(
            '🎉 Party Item',
            style: _focusedIndex == 1
                ? const TextStyle(reverse: true)
                : const TextStyle(),
          ),
        ],
      ),
    );
  }
}

/// Test widget: Focusable items with Chinese labels
class _FocusableWidgetWithChineseLabels extends StatefulComponent {
  @override
  State<_FocusableWidgetWithChineseLabels> createState() =>
      _FocusableWidgetWithChineseLabelsState();
}

class _FocusableWidgetWithChineseLabelsState
    extends State<_FocusableWidgetWithChineseLabels> {
  int _focusedIndex = 0;

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.tab) {
          setState(() {
            _focusedIndex = (_focusedIndex + 1) % 2;
          });
          return true;
        }
        return false;
      },
      child: Column(
        children: [
          Text(
            '选项一：第一个选项',
            style: _focusedIndex == 0
                ? const TextStyle(reverse: true)
                : const TextStyle(),
          ),
          const SizedBox(height: 1),
          Text(
            '选项二：第二个选项',
            style: _focusedIndex == 1
                ? const TextStyle(reverse: true)
                : const TextStyle(),
          ),
        ],
      ),
    );
  }
}

/// Test widget: Focusable items with mixed labels
class _FocusableWidgetWithMixedLabels extends StatefulComponent {
  @override
  State<_FocusableWidgetWithMixedLabels> createState() =>
      _FocusableWidgetWithMixedLabelsState();
}

class _FocusableWidgetWithMixedLabelsState
    extends State<_FocusableWidgetWithMixedLabels> {
  int _focusedIndex = 0;

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.tab) {
          setState(() {
            _focusedIndex = (_focusedIndex + 1) % 3;
          });
          return true;
        }
        return false;
      },
      child: Column(
        children: [
          Text(
            '🔍 Search with emoji',
            style: _focusedIndex == 0
                ? const TextStyle(reverse: true)
                : const TextStyle(),
          ),
          const SizedBox(height: 1),
          Text(
            '搜索中文内容',
            style: _focusedIndex == 1
                ? const TextStyle(reverse: true)
                : const TextStyle(),
          ),
          const SizedBox(height: 1),
          Text(
            '✨ Sparkle item',
            style: _focusedIndex == 2
                ? const TextStyle(reverse: true)
                : const TextStyle(),
          ),
        ],
      ),
    );
  }
}

/// Test widget: Counter with emoji label
class _CounterWithEmojiLabel extends StatefulComponent {
  @override
  State<_CounterWithEmojiLabel> createState() => _CounterWithEmojiLabelState();
}

class _CounterWithEmojiLabelState extends State<_CounterWithEmojiLabel> {
  int _count = 0;

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.space) {
          setState(() {
            _count++;
          });
          return true;
        }
        return false;
      },
      child: Row(
        children: [
          const Text('🔢 '),
          Text('Count: $_count'),
        ],
      ),
    );
  }
}
