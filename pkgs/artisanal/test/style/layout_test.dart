import 'package:artisanal/style.dart';
import 'package:test/test.dart';

void main() {
  group('Layout', () {
    group('visibleLength', () {
      test('returns length of plain text', () {
        expect(Layout.visibleLength('Hello'), equals(5));
      });

      test('ignores ANSI escape codes', () {
        const ansi = '\x1B[1;32mHello\x1B[0m';
        expect(Layout.visibleLength(ansi), equals(5));
      });

      test('handles empty string', () {
        expect(Layout.visibleLength(''), equals(0));
      });

      test('handles multiple ANSI codes', () {
        const ansi = '\x1B[1m\x1B[32mBold Green\x1B[0m';
        expect(Layout.visibleLength(ansi), equals(10));
      });

      test('counts Kitty image APC width from c= param', () {
        const kitty = '\x1b_Ga=T,q=2,c=8,r=4;DATA\x1b\\';
        expect(Layout.visibleLength(kitty), equals(8));
      });

      test('counts text adjacent to Kitty image APC', () {
        const kitty = '\x1b_Ga=T,q=2,c=8,r=4;DATA\x1b\\';
        expect(Layout.visibleLength('${kitty}OK'), equals(10));
      });

      test('counts sixel payload cell width', () {
        const sixel = '\x1bPq#0;2;0;0;0!1~\x1b\\';
        expect(Layout.visibleLength(sixel), equals(1));
      });
    });

    group('stripAnsi', () {
      test('removes ANSI codes', () {
        const ansi = '\x1B[1;32mHello\x1B[0m';
        expect(Layout.stripAnsi(ansi), equals('Hello'));
      });

      test('returns plain text unchanged', () {
        expect(Layout.stripAnsi('Hello'), equals('Hello'));
      });

      test('handles empty string', () {
        expect(Layout.stripAnsi(''), equals(''));
      });
    });

    group('pad', () {
      test('pads text to width on right', () {
        expect(Layout.pad('Hi', 5), equals('Hi   '));
      });

      test('returns text unchanged if already at width', () {
        expect(Layout.pad('Hello', 5), equals('Hello'));
      });

      test('returns text unchanged if wider than width', () {
        expect(Layout.pad('Hello World', 5), equals('Hello World'));
      });

      test('uses custom pad character', () {
        expect(Layout.pad('Hi', 5, '.'), equals('Hi...'));
      });

      test('handles ANSI codes correctly', () {
        const ansi = '\x1B[32mHi\x1B[0m';
        final padded = Layout.pad(ansi, 5);
        expect(Layout.visibleLength(padded), equals(5));
      });
    });

    group('padLeft', () {
      test('pads text to width on left', () {
        expect(Layout.padLeft('Hi', 5), equals('   Hi'));
      });

      test('returns text unchanged if already at width', () {
        expect(Layout.padLeft('Hello', 5), equals('Hello'));
      });

      test('uses custom pad character', () {
        expect(Layout.padLeft('Hi', 5, '0'), equals('000Hi'));
      });
    });

    group('center', () {
      test('centers text within width', () {
        expect(Layout.center('Hi', 6), equals('  Hi  '));
      });

      test('handles odd difference', () {
        // 'Hi' (2) in width 5 = 3 extra = 1 left, 2 right
        expect(Layout.center('Hi', 5), equals(' Hi  '));
      });

      test('returns text unchanged if already at width', () {
        expect(Layout.center('Hello', 5), equals('Hello'));
      });

      test('uses custom pad character', () {
        expect(Layout.center('X', 5, '-'), equals('--X--'));
      });
    });

    group('alignText', () {
      test('left alignment pads on right', () {
        expect(
          Layout.alignText('Hi', 5, HorizontalAlign.left),
          equals('Hi   '),
        );
      });

      test('center alignment centers text', () {
        expect(
          Layout.alignText('Hi', 6, HorizontalAlign.center),
          equals('  Hi  '),
        );
      });

      test('right alignment pads on left', () {
        expect(
          Layout.alignText('Hi', 5, HorizontalAlign.right),
          equals('   Hi'),
        );
      });
    });

    group('alignLines', () {
      test('aligns all lines', () {
        final lines = ['A', 'BB', 'CCC'];
        final aligned = Layout.alignLines(lines, 5, HorizontalAlign.left);

        expect(aligned[0], equals('A    '));
        expect(aligned[1], equals('BB   '));
        expect(aligned[2], equals('CCC  '));
      });
    });

    group('joinHorizontal', () {
      test('joins two blocks side by side', () {
        const left = 'A\nB';
        const right = '1\n2';

        final result = Layout.joinHorizontal(VerticalAlign.top, [left, right]);

        expect(result, equals('A1\nB2'));
      });

      test('aligns blocks at top', () {
        const short = 'A';
        const tall = '1\n2\n3';

        final result = Layout.joinHorizontal(VerticalAlign.top, [short, tall]);
        final lines = result.split('\n');

        expect(lines.length, equals(3));
        expect(lines[0], startsWith('A'));
      });

      test('aligns blocks at center', () {
        const short = 'X';
        const tall = '1\n2\n3';

        final result = Layout.joinHorizontal(VerticalAlign.center, [
          short,
          tall,
        ]);
        final lines = result.split('\n');

        expect(lines.length, equals(3));
        // 'X' should be in middle row
        expect(lines[1], startsWith('X'));
      });

      test('aligns blocks at bottom', () {
        const short = 'X';
        const tall = '1\n2\n3';

        final result = Layout.joinHorizontal(VerticalAlign.bottom, [
          short,
          tall,
        ]);
        final lines = result.split('\n');

        expect(lines.length, equals(3));
        // 'X' should be in last row
        expect(lines[2], startsWith('X'));
      });

      test('handles empty list', () {
        expect(Layout.joinHorizontal(VerticalAlign.top, []), equals(''));
      });

      test('handles single block', () {
        expect(
          Layout.joinHorizontal(VerticalAlign.top, ['Hello']),
          equals('Hello'),
        );
      });

      test('respects gap parameter', () {
        const left = 'A';
        const right = 'B';

        final result = Layout.joinHorizontal(VerticalAlign.top, [
          left,
          right,
        ], gap: 3);

        expect(result, equals('A   B'));
      });

      test('uses custom gap character', () {
        const left = 'A';
        const right = 'B';

        final result = Layout.joinHorizontal(
          VerticalAlign.top,
          [left, right],
          gap: 3,
          gapChar: '.',
        );

        expect(result, equals('A...B'));
      });

      test('joins multiple blocks', () {
        const a = 'A';
        const b = 'B';
        const c = 'C';

        final result = Layout.joinHorizontal(VerticalAlign.top, [a, b, c]);

        expect(result, equals('ABC'));
      });
    });

    group('joinVertical', () {
      test('stacks blocks vertically', () {
        const top = 'Top';
        const bottom = 'Bottom';

        final result = Layout.joinVertical(HorizontalAlign.left, [top, bottom]);

        expect(result, contains('Top'));
        expect(result, contains('Bottom'));
        expect(result.split('\n').length, equals(2));
      });

      test('aligns blocks at left', () {
        const short = 'Hi';
        const long = 'Hello';

        final result = Layout.joinVertical(HorizontalAlign.left, [short, long]);
        final lines = result.split('\n');

        expect(lines[0], startsWith('Hi'));
        expect(lines[1], equals('Hello'));
      });

      test('aligns blocks at center', () {
        const short = 'X';
        const long = 'Hello';

        final result = Layout.joinVertical(HorizontalAlign.center, [
          short,
          long,
        ]);
        final lines = result.split('\n');

        // 'X' should be centered within 5 chars
        expect(lines[0], equals('  X  '));
      });

      test('aligns blocks at right', () {
        const short = 'Hi';
        const long = 'Hello';

        final result = Layout.joinVertical(HorizontalAlign.right, [
          short,
          long,
        ]);
        final lines = result.split('\n');

        expect(lines[0], equals('   Hi'));
        expect(lines[1], equals('Hello'));
      });

      test('handles empty list', () {
        expect(Layout.joinVertical(HorizontalAlign.left, []), equals(''));
      });

      test('handles single block', () {
        expect(
          Layout.joinVertical(HorizontalAlign.left, ['Hello']),
          equals('Hello'),
        );
      });

      test('respects gap parameter', () {
        const a = 'A';
        const b = 'B';

        final result = Layout.joinVertical(HorizontalAlign.left, [
          a,
          b,
        ], gap: 2);
        final lines = result.split('\n');

        expect(lines.length, equals(4)); // A, empty, empty, B
      });

      test('handles multi-line blocks', () {
        const block1 = 'A1\nA2';
        const block2 = 'B1\nB2';

        final result = Layout.joinVertical(HorizontalAlign.left, [
          block1,
          block2,
        ]);
        final lines = result.split('\n');

        expect(lines.length, equals(4));
      });
    });

    group('place', () {
      test('places content at center', () {
        final result = Layout.place(
          width: 10,
          height: 5,
          horizontal: HorizontalAlign.center,
          vertical: VerticalAlign.center,
          content: 'Hi',
        );

        final lines = result.split('\n');

        expect(lines.length, equals(5));
        expect(Layout.visibleLength(lines[0]), equals(10));
        // Content should be in middle line
        expect(lines[2], contains('Hi'));
      });

      test('places content at top-left', () {
        final result = Layout.place(
          width: 5,
          height: 3,
          horizontal: HorizontalAlign.left,
          vertical: VerticalAlign.top,
          content: 'X',
        );

        final lines = result.split('\n');

        expect(lines[0], startsWith('X'));
      });

      test('places content at bottom-right', () {
        final result = Layout.place(
          width: 5,
          height: 3,
          horizontal: HorizontalAlign.right,
          vertical: VerticalAlign.bottom,
          content: 'X',
        );

        final lines = result.split('\n');

        expect(lines[2], endsWith('X'));
      });

      test('handles multi-line content', () {
        final result = Layout.place(
          width: 10,
          height: 5,
          horizontal: HorizontalAlign.center,
          vertical: VerticalAlign.center,
          content: 'AB\nCD',
        );

        final lines = result.split('\n');

        expect(lines.length, equals(5));
      });

      test('respects custom fill character', () {
        final result = Layout.place(
          width: 5,
          height: 3,
          horizontal: HorizontalAlign.center,
          vertical: VerticalAlign.center,
          content: 'X',
          whitespace: WhitespaceOptions(chars: '.'),
        );

        expect(result, contains('.'));
      });
    });

    group('placeWidth', () {
      test('places content horizontally', () {
        final result = Layout.placeWidth(
          width: 10,
          align: HorizontalAlign.center,
          content: 'Hi',
        );

        expect(Layout.visibleLength(result), equals(10));
        expect(result, contains('Hi'));
      });

      test('handles multi-line content', () {
        final result = Layout.placeWidth(
          width: 5,
          align: HorizontalAlign.right,
          content: 'A\nBB',
        );

        final lines = result.split('\n');

        expect(lines[0], equals('    A'));
        expect(lines[1], equals('   BB'));
      });
    });

    group('placeHeight', () {
      test('places content vertically', () {
        final result = Layout.placeHeight(
          height: 5,
          align: VerticalAlign.center,
          content: 'X',
        );

        final lines = result.split('\n');

        expect(lines.length, equals(5));
      });

      test('aligns at top', () {
        final result = Layout.placeHeight(
          height: 3,
          align: VerticalAlign.top,
          content: 'X',
        );

        final lines = result.split('\n');

        expect(lines[0], equals('X'));
      });

      test('aligns at bottom', () {
        final result = Layout.placeHeight(
          height: 3,
          align: VerticalAlign.bottom,
          content: 'X',
        );

        final lines = result.split('\n');

        expect(lines[2], equals('X'));
      });
    });

    group('getSize', () {
      test('returns correct dimensions', () {
        final size = Layout.getSize('Hello\nWorld\n!!!');

        expect(size.width, equals(5));
        expect(size.height, equals(3));
      });

      test('handles empty string', () {
        final size = Layout.getSize('');

        expect(size.width, equals(0));
        expect(size.height, equals(1)); // Empty string still has 1 "line"
      });

      test('handles single line', () {
        final size = Layout.getSize('Hello');

        expect(size.width, equals(5));
        expect(size.height, equals(1));
      });

      test('ignores ANSI codes in width calculation', () {
        const ansi = '\x1B[32mHello\x1B[0m';
        final size = Layout.getSize(ansi);

        expect(size.width, equals(5));
      });
    });

    group('getWidth', () {
      test('returns maximum line width', () {
        expect(Layout.getWidth('Hi\nHello\nHi'), equals(5));
      });

      test('handles empty string', () {
        expect(Layout.getWidth(''), equals(0));
      });
    });

    group('getHeight', () {
      test('returns number of lines', () {
        expect(Layout.getHeight('A\nB\nC'), equals(3));
      });

      test('handles single line', () {
        expect(Layout.getHeight('Hello'), equals(1));
      });
    });

    group('truncate', () {
      test('truncates text with ellipsis', () {
        final result = Layout.truncate('Hello World', 8);

        expect(Layout.visibleLength(result), lessThanOrEqualTo(8));
        expect(result, endsWith('…'));
      });

      test('returns text unchanged if within width', () {
        expect(Layout.truncate('Hello', 10), equals('Hello'));
      });

      test('uses custom ellipsis', () {
        final result = Layout.truncate('Hello World', 8, ellipsis: '...');

        expect(result, endsWith('...'));
      });

      test('handles very short max width', () {
        final result = Layout.truncate('Hello', 1);

        expect(result.length, lessThanOrEqualTo(1));
      });
    });

    group('truncateLines', () {
      test('truncates each line', () {
        final result = Layout.truncateLines('Hello World\nFoo Bar', 6);
        final lines = result.split('\n');

        expect(Layout.visibleLength(lines[0]), lessThanOrEqualTo(6));
        expect(Layout.visibleLength(lines[1]), lessThanOrEqualTo(6));
      });
    });

    group('truncateHeight', () {
      test('truncates to max lines', () {
        final result = Layout.truncateHeight('A\nB\nC\nD', 2);
        final lines = result.split('\n');

        expect(lines.length, equals(2));
      });

      test('returns text unchanged if within height', () {
        expect(Layout.truncateHeight('A\nB', 5), equals('A\nB'));
      });

      test('uses last line indicator', () {
        final result = Layout.truncateHeight(
          'A\nB\nC\nD',
          2,
          lastLineIndicator: '...',
        );
        final lines = result.split('\n');

        expect(lines.last, equals('...'));
      });
    });

    group('wrap', () {
      test('wraps text at word boundaries', () {
        final result = Layout.wrap('Hello World', 6);
        final lines = result.split('\n');

        expect(lines.length, equals(2));
        expect(lines[0], equals('Hello'));
        expect(lines[1], equals('World'));
      });

      test('handles long words', () {
        final result = Layout.wrap('Supercalifragilisticexpialidocious', 10);

        // Long word won't wrap, but shouldn't crash
        expect(result, contains('Supercalifragilisticexpialidocious'));
      });

      test('handles zero max width', () {
        final result = Layout.wrap('Hello', 0);
        expect(result, equals('Hello'));
      });

      test('handles single word', () {
        expect(Layout.wrap('Hello', 10), equals('Hello'));
      });

      test('handles multiple spaces correctly', () {
        final result = Layout.wrap('A B C D', 3);
        final lines = result.split('\n');

        // Each letter should be on its own line (or paired)
        expect(lines.length, greaterThan(1));
      });
    });

    group('wrapLines', () {
      test('wraps each line independently', () {
        final result = Layout.wrapLines('Hello World\nFoo Bar', 6);
        final lines = result.split('\n');

        expect(lines.length, equals(4));
      });
    });

    group('placeHorizontal', () {
      test('centers content in width', () {
        final result = Layout.placeHorizontal(10, HorizontalAlign.center, 'Hi');
        expect(Layout.visibleLength(result), equals(10));
        expect(result, contains('Hi'));
      });

      test('right-aligns content', () {
        final result = Layout.placeHorizontal(10, HorizontalAlign.right, 'Hi');
        expect(result.startsWith('        Hi'), isTrue);
      });

      test('left-aligns content', () {
        final result = Layout.placeHorizontal(10, HorizontalAlign.left, 'Hi');
        expect(result.startsWith('Hi'), isTrue);
        expect(result.endsWith('        '), isTrue);
      });

      test('handles multiline content', () {
        final result = Layout.placeHorizontal(
          10,
          HorizontalAlign.center,
          'A\nBC',
        );
        final lines = result.split('\n');
        expect(lines.length, equals(2));
        // Each line should be padded to width 10
        for (final line in lines) {
          expect(Layout.visibleLength(line), equals(10));
        }
      });

      test('returns content unchanged if wider than width', () {
        final result = Layout.placeHorizontal(
          3,
          HorizontalAlign.center,
          'Hello',
        );
        expect(result, equals('Hello'));
      });

      test('supports whitespace options', () {
        final result = Layout.placeHorizontal(
          10,
          HorizontalAlign.center,
          'Hi',
          whitespace: WhitespaceOptions(chars: '.'),
        );
        expect(result, contains('.'));
        expect(result, contains('Hi'));
      });
    });

    group('placeVertical', () {
      test('centers content in height', () {
        final result = Layout.placeVertical(5, VerticalAlign.center, 'Hi');
        final lines = result.split('\n');
        expect(lines.length, equals(5));
      });

      test('top-aligns content', () {
        final result = Layout.placeVertical(5, VerticalAlign.top, 'Hi');
        final lines = result.split('\n');
        expect(lines.length, equals(5));
        expect(lines[0], equals('Hi'));
      });

      test('bottom-aligns content', () {
        final result = Layout.placeVertical(5, VerticalAlign.bottom, 'Hi');
        final lines = result.split('\n');
        expect(lines.length, equals(5));
        expect(lines[4], equals('Hi'));
      });

      test('handles multiline content', () {
        final result = Layout.placeVertical(5, VerticalAlign.center, 'A\nB');
        final lines = result.split('\n');
        expect(lines.length, equals(5));
      });

      test('returns content unchanged if taller than height', () {
        final result = Layout.placeVertical(
          2,
          VerticalAlign.center,
          'A\nB\nC\nD',
        );
        final lines = result.split('\n');
        expect(lines.length, equals(4)); // Content height is 4, target is 2
      });

      test('supports whitespace options', () {
        final result = Layout.placeVertical(
          3,
          VerticalAlign.top,
          'Hi',
          whitespace: WhitespaceOptions(chars: '.'),
        );
        final lines = result.split('\n');
        expect(lines.length, equals(3));
        // Empty lines should contain dots
        expect(lines[1], contains('.'));
      });
    });

    group('Dingbats and Misc Symbols Layout', () {
      test('alignText correctly handles width 1 symbols', () {
        // Checkmark (U+2713) is width 1
        expect(Layout.alignText('✓', 3, HorizontalAlign.left), equals('✓  '));
        expect(Layout.alignText('✓', 3, HorizontalAlign.right), equals('  ✓'));
      });

      test('alignLines correctly pads mixed content', () {
        final lines = ['✓', 'AB']; // Width 1 and 2
        // Max width is 2.
        // alignLines will pad '✓' to 2.
        final aligned = Layout.alignLines(lines, 2, HorizontalAlign.left);
        expect(aligned[0], equals('✓ '));
        expect(aligned[1], equals('AB'));
      });

      test('joinVertical aligns based on correct width', () {
        // If Block 1 is "✓" (width 1) and Block 2 is "AB" (width 2).
        // It should pad Block 1 to width 2.
        final result = Layout.joinVertical(HorizontalAlign.left, ['✓', 'AB']);
        final lines = result.split('\n');
        expect(lines[0], equals('✓ '));
        expect(lines[1], equals('AB'));
      });

      test('Chess pieces layout width 1', () {
        expect(Layout.visibleLength('♔'), equals(1));
        expect(Layout.alignText('♔', 3, HorizontalAlign.left), equals('♔  '));
      });
    });
  });
}
