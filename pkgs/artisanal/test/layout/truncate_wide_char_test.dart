import 'package:artisanal/style.dart';
import 'package:test/test.dart';

void main() {
  group('Layout.truncate deep dive', () {
    test('emoji code unit lengths', () {
      // Check how many UTF-16 code units each emoji uses
      final emojis = ['😀', '😎', '🤔', '😱', '💩', '✨', '🚀', '🌍'];
      for (final e in emojis) {
        print(
          '$e  codeUnits=${e.length}  runes=${e.runes.length}  '
          'visibleLen=${Layout.visibleLength(e)}',
        );
      }

      // Characters with variation selectors
      final withVS = ['✌️', '☀️', '⚠️', '♻️'];
      for (final e in withVS) {
        print(
          '$e  codeUnits=${e.length}  runes=${e.runes.length}  '
          'visibleLen=${Layout.visibleLength(e)}',
        );
      }
    });

    test('truncate with surrogate pair emoji - code unit counting bug', () {
      // Each 😀 is 2 UTF-16 code units (surrogate pair) and 2 display cells wide
      // The bug in truncate: currentLen++ treats each text[i] as 1 unit
      // text[i] for a surrogate pair would be the high surrogate, then low surrogate
      // So '😀' at text[i] gives you '\uD83D' (high surrogate) followed by '\uDE00' (low surrogate)
      // truncate counts each as 1 "character", so for maxWidth=20 it would
      // process 20 UTF-16 code units, which is ~10 emoji

      // Build a line with many emoji, no spaces
      // 15 emoji × 2 code units = 30 code units
      // 15 emoji × 2 display width = 30 display cells
      final line = '😀😎🤔😱💩🎉🔥✨🚀🌍👍👎👋🙏💪';
      print('Line: $line');
      print('codeUnits: ${line.length}');
      print('visibleLength: ${Layout.visibleLength(line)}');

      // Truncate to 10 display cells (should be 5 emoji)
      final truncated = Layout.truncate(line, 10, ellipsis: '');
      print('Truncated to 10: $truncated');
      print('Truncated codeUnits: ${truncated.length}');
      print('Truncated visibleLength: ${Layout.visibleLength(truncated)}');

      // BUG: truncate processes 10 code units (= 5 emoji) but each emoji
      // is 2 cells, so the result should be 10 cells. But it might be
      // different because it outputs text[i] which is a single surrogate...

      // Actually wait - result.write(text[i]) writes the high surrogate,
      // then i++ and currentLen++, then next iteration writes low surrogate,
      // i++ and currentLen++ again. So each emoji consumes 2 of the currentLen
      // budget. For targetLen=10, it processes 10 code units = 5 emoji = 10 cells.
      // That happens to be correct by accident!

      // The bug would manifest when we have mixed content: ASCII (1 code unit,
      // 1 display cell) mixed with emoji (2 code units, 2 display cells).
      // In that case, for every emoji the budget is consumed by 2 instead of 2,
      // which is coincidentally correct.

      // Actually, the real bug is with characters that have DIFFERENT ratios
      // of code units to display width. For example:
      // - ASCII: 1 code unit, 1 display cell → ratio 1:1, no bug
      // - Emoji: 2 code units, 2 display cells → ratio 1:1, no bug
      // - CJK: 1 code unit, 2 display cells → ratio 1:2, BUG!
      // - Variation selector emoji: 2-3 code units, 2 display cells → might bug

      expect(Layout.visibleLength(truncated), lessThanOrEqualTo(10));
    });

    test('truncate with CJK characters - actual bug case', () {
      // CJK characters: 1 code unit each, but 2 display cells each
      // This is where the bug should manifest clearly
      final line = '你好世界测试中文字符串渲染';
      print('CJK Line: $line');
      print('codeUnits: ${line.length}');
      print('visibleLength: ${Layout.visibleLength(line)}');

      // Truncate to 10 display cells (should be 5 CJK chars)
      final truncated = Layout.truncate(line, 10, ellipsis: '');
      print('Truncated to 10: $truncated');
      print('Truncated codeUnits: ${truncated.length}');
      print('Truncated visibleLength: ${Layout.visibleLength(truncated)}');

      // BUG: truncate counts 1 per code unit, but CJK chars are 1 code unit
      // with 2 display cells. So it processes 10 code units = 10 CJK chars
      // = 20 display cells. That's TWICE the target!
      expect(
        Layout.visibleLength(truncated),
        lessThanOrEqualTo(10),
        reason: 'CJK truncation should respect display width, not code units',
      );
    });

    test('truncate with variation selector emoji', () {
      // ☀️ = ☀ (U+2600, 1 code unit) + ️ (U+FE0F variation selector, 1 code unit)
      // Display width should be 2 (emoji presentation)
      // truncate would count 2 code units for this
      final line = '☀️🌤️⛅🌧️⛈️❄️🌈🌪️🌡️☔';
      print('Weather line: $line');
      print('codeUnits: ${line.length}');
      print('visibleLength: ${Layout.visibleLength(line)}');

      final truncated = Layout.truncate(line, 10, ellipsis: '');
      print('Truncated to 10: $truncated');
      print('Truncated visibleLength: ${Layout.visibleLength(truncated)}');

      expect(Layout.visibleLength(truncated), lessThanOrEqualTo(10));
    });

    test('truncate mixed ASCII + emoji spacing', () {
      // "Faces: " = 7 code units, 7 display cells
      // "😀 😎 🤔 😱 💩" = each emoji 2 code units + 1 space = 3 code units per,
      //   5 emoji + 4 spaces = 5*2 + 4*1 = 14 code units, display = 5*2 + 4 = 14 cells
      // Total: 21 code units, 21 display cells
      // Wait, let me count: "Faces: " is 7. Then "😀 " is 3 code units (high, low, space).
      // 5 emoji with spaces between = "😀 😎 🤔 😱 💩"
      // = 5*2 + 4 = 14 code units
      // Display = 5*2 + 4 = 14 cells
      // Total = 7 + 14 = 21 code units, 7 + 14 = 21 display cells
      // So the ratio is 1:1 overall -- the bug doesn't manifest!

      // For the bug to manifest, we need a mismatch between code units and display width
      final line = 'Faces: 😀 😎 🤔 😱 💩';
      print('Line codeUnits: ${line.length}');
      print('Line visibleLength: ${Layout.visibleLength(line)}');

      // These should be equal for this specific line
      // confirming the bug doesn't affect this case
    });
  });
}
