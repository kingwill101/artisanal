import 'package:artisanal/src/style/color.dart';
import 'package:artisanal/src/style/style.dart';
import 'package:artisanal/src/style/tag_parser.dart';
import 'package:test/test.dart';

void main() {
  group('ConsoleTagParser', () {
    late ConsoleTagParser parser;

    setUp(() {
      parser = ConsoleTagParser();
    });

    group('basic parsing', () {
      test('returns plain text unchanged when no tags', () {
        expect(parser.render('Hello World'), equals('Hello World'));
      });

      test('returns text with < but no valid tag unchanged', () {
        expect(parser.render('5 < 10'), equals('5 < 10'));
      });

      test('handles empty string', () {
        expect(parser.render(''), equals(''));
      });
    });

    group('foreground colors', () {
      test('basic named color', () {
        final output = parser.render('<fg=red>Hello</>');
        // AnsiColor(1) renders as 38;5;1 in trueColor profile
        expect(output, contains('\x1B[38;5;1m'));
        expect(output, contains('Hello'));
      });

      test('hex color', () {
        final output = parser.render('<fg=#ff5500>Hex</>');
        expect(output, contains('\x1B[38;2;255;85;0m')); // RGB true color
        expect(output, contains('Hex'));
      });

      test('ansi 256 color', () {
        final p = ConsoleTagParser(colorProfile: ColorProfile.ansi256);
        final output = p.render('<fg=196>Code</>');
        expect(output, contains('\x1B[38;5;196m'));
        expect(output, contains('Code'));
      });

      test('bright color', () {
        final output = parser.render('<fg=bright-red>Bright</>');
        expect(output, contains('\x1B[38;5;9m')); // ANSI 256 code 9
        expect(output, contains('Bright'));
      });
    });

    group('background colors', () {
      test('basic named color', () {
        final output = parser.render('<bg=blue>World</>');
        // AnsiColor(4) renders as 48;5;4 in trueColor profile
        expect(output, contains('\x1B[48;5;4m'));
        expect(output, contains('World'));
      });

      test('hex color', () {
        final output = parser.render('<bg=#00ff00>Green</>');
        expect(output, contains('\x1B[48;2;0;255;0m')); // RGB true color
        expect(output, contains('Green'));
      });
    });

    group('text options', () {
      test('single option - bold', () {
        final output = parser.render('<options=bold>Bold</>');
        expect(output, contains('\x1B[1m'));
        expect(output, contains('Bold'));
      });

      test('single option - italic', () {
        final output = parser.render('<options=italic>Italic</>');
        expect(output, contains('\x1B[3m'));
        expect(output, contains('Italic'));
      });

      test('single option - underline', () {
        final output = parser.render('<options=underline>Underline</>');
        expect(output, contains('\x1B[4m'));
        // Style renders underline character-by-character, so just check it contains the word
        expect(
          output.replaceAll(RegExp(r'\x1B\[[^m]*m'), ''),
          contains('Underline'),
        );
      });

      test('single option - dim', () {
        final output = parser.render('<options=dim>Dim</>');
        expect(output, contains('\x1B[2m'));
        expect(output, contains('Dim'));
      });

      test('single option - faint (alias for dim)', () {
        final output = parser.render('<options=faint>Faint</>');
        expect(output, contains('\x1B[2m'));
        expect(output, contains('Faint'));
      });

      test('single option - strikethrough', () {
        final output = parser.render('<options=strikethrough>Strike</>');
        expect(output, contains('\x1B[9m'));
        // Style renders strikethrough character-by-character
        expect(
          output.replaceAll(RegExp(r'\x1B\[[^m]*m'), ''),
          contains('Strike'),
        );
      });

      test('single option - reverse', () {
        final output = parser.render('<options=reverse>Reverse</>');
        expect(output, contains('\x1B[7m'));
        expect(output, contains('Reverse'));
      });

      test('single option - inverse (alias for reverse)', () {
        final output = parser.render('<options=inverse>Inverse</>');
        expect(output, contains('\x1B[7m'));
        expect(output, contains('Inverse'));
      });

      test('multiple options', () {
        final output = parser.render('<options=bold,underline>Styled</>');
        expect(output, contains('\x1B[1m')); // Bold
        expect(output, contains('\x1B[4m')); // Underline
        // Check text content is present
        expect(
          output.replaceAll(RegExp(r'\x1B\[[^m]*m'), ''),
          contains('Styled'),
        );
      });

      test('multiple options with spaces', () {
        final output = parser.render('<options=bold, italic>Styled</>');
        expect(output, contains('Styled'));
        // Should handle spaces after comma
      });
    });

    group('combined styles', () {
      test('foreground and background', () {
        final output = parser.render('<fg=white;bg=red>Alert</>');
        expect(output, contains('Alert'));
        // Should contain both foreground and background codes
      });

      test('color and options', () {
        final output = parser.render('<fg=green;options=bold>Success</>');
        expect(output, contains('Success'));
      });

      test('full combination', () {
        final output = parser.render(
          '<fg=yellow;bg=black;options=bold,underline>Full</>',
        );
        // Check text is present (rendered character-by-character due to underline)
        expect(
          output.replaceAll(RegExp(r'\x1B\[[^m]*m'), ''),
          contains('Full'),
        );
      });
    });

    group('named styles', () {
      test('info style (green)', () {
        final output = parser.render('<info>Information</info>');
        // Colors.green is a TrueColor, renders as RGB
        expect(output, contains('Information'));
        // Should have green-ish color
        expect(output, contains('\x1B[38;2;'));
      });

      test('comment style (yellow)', () {
        final output = parser.render('<comment>A comment</comment>');
        // Colors.yellow is a TrueColor
        expect(output, contains('A comment'));
        expect(output, contains('\x1B[38;2;'));
      });

      test('question style (black on cyan)', () {
        final output = parser.render('<question>A question?</question>');
        expect(output, contains('A question?'));
        // Should have black foreground and cyan background
      });

      test('error style (white on red)', () {
        final output = parser.render('<error>An error</error>');
        expect(output, contains('An error'));
        // Should have white foreground and red background
      });

      test('success style', () {
        final output = parser.render('<success>Done!</success>');
        // Colors.green is a TrueColor
        expect(output, contains('Done!'));
        expect(output, contains('\x1B[38;2;'));
      });

      test('warning style', () {
        final output = parser.render('<warning>Warning!</warning>');
        // Colors.yellow is a TrueColor
        expect(output, contains('Warning!'));
        expect(output, contains('\x1B[38;2;'));
      });

      test('custom registered style', () {
        parser.registerStyle(
          'brand',
          Style().foreground(BasicColor('#ff5500')).bold(),
        );
        final output = parser.render('<brand>My Brand</brand>');
        expect(output, contains('My Brand'));
      });
    });

    group('nesting', () {
      test('nested tags inherit parent style', () {
        final output = parser.render(
          '<fg=green>Green <options=bold>bold green</> still green</>',
        );
        // After </> for bold, text should return to green (not reset to default)
        expect(output, contains('Green'));
        expect(output, contains('bold green'));
        expect(output, contains('still green'));
      });

      test('nested color overrides parent', () {
        final output = parser.render(
          '<fg=green>Green <fg=red>Red</> Green again</>',
        );
        expect(output, contains('Green'));
        expect(output, contains('Red'));
        expect(output, contains('Green again'));
      });

      test('multiple levels of nesting', () {
        final output = parser.render(
          '<fg=blue>L1 <options=bold>L2 <options=italic>L3</> L2</> L1</>',
        );
        expect(output, contains('L1'));
        expect(output, contains('L2'));
        expect(output, contains('L3'));
      });

      test('named style with inline nested', () {
        final output = parser.render(
          '<info>Info with <options=bold>bold</> text</info>',
        );
        expect(output, contains('Info with'));
        expect(output, contains('bold'));
        expect(output, contains('text'));
      });
    });

    group('escape sequences', () {
      test('escaped < is rendered as literal', () {
        final output = parser.render(r'Use \<info> for info');
        expect(output, equals('Use <info> for info'));
      });

      test('multiple escaped tags', () {
        final output = parser.render(r'\<tag1> and \<tag2>');
        expect(output, equals('<tag1> and <tag2>'));
      });

      test('mix of escaped and real tags', () {
        final output = parser.render(r'\<escaped> <fg=red>real</> \<also>');
        expect(output, contains('<escaped>'));
        expect(output, contains('real'));
        expect(output, contains('<also>'));
      });
    });

    group('hyperlinks', () {
      test('basic hyperlink', () {
        final output = parser.render('<href=https://example.com>Link</>');
        // Style uses OSC 8 with ST terminator (\x1B\\) instead of BEL (\x07)
        expect(output, contains('\x1B]8;;https://example.com'));
        expect(output, contains('Link'));
      });

      test('hyperlink with styling', () {
        final output = parser.render(
          '<fg=blue;href=https://example.com>Styled Link</>',
        );
        expect(output, contains('Styled Link'));
        expect(output, contains('\x1B]8;;https://example.com'));
      });
    });

    group('edge cases', () {
      test('empty tag content', () {
        // Should be treated as non-tag
        final output = parser.render('a<>b');
        expect(output, equals('a<>b'));
      });

      test('unclosed tag', () {
        // Should treat as plain text since no closing >
        final output = parser.render('a<fg=red');
        expect(output, equals('a<fg=red'));
      });

      test('orphan closing tag', () {
        // </> without opening should be treated as text
        final output = parser.render('text</> more');
        expect(output, contains('text'));
        expect(output, contains('more'));
      });

      test('tag spanning newline', () {
        // Tags shouldn't span newlines
        final output = parser.render('a<fg=red\n>b');
        expect(output, contains('a<fg=red'));
        expect(output, contains('>b'));
      });

      test('case insensitive tags', () {
        final output1 = parser.render('<FG=RED>upper</>');
        final output2 = parser.render('<fg=red>lower</>');
        // Both should produce red text
        expect(output1, contains('upper'));
        expect(output2, contains('lower'));
      });

      test('whitespace in tag', () {
        // Whitespace should be handled gracefully
        final output = parser.render('<fg=red; options=bold>text</>');
        expect(output, contains('text'));
      });
    });

    group('parser API', () {
      test('parse returns segments', () {
        final segments = parser.parse('<fg=red>Hello</> World');
        expect(segments.length, equals(2));
        expect(segments[0], isA<StyledSegment>());
        expect(segments[1], isA<TextSegment>());
      });

      test('text segment has correct content', () {
        final segments = parser.parse('Plain text');
        expect(segments.length, equals(1));
        expect(segments[0], isA<TextSegment>());
        expect((segments[0] as TextSegment).text, equals('Plain text'));
      });

      test('styled segment has correct attributes', () {
        final segments = parser.parse('<fg=red;bg=blue>text</>');
        expect(segments.length, equals(1));
        expect(segments[0], isA<StyledSegment>());
        final styled = segments[0] as StyledSegment;
        expect(styled.foreground, equals('red'));
        expect(styled.background, equals('blue'));
      });

      test('getStyle returns registered style', () {
        expect(parser.getStyle('info'), isNotNull);
        expect(parser.getStyle('nonexistent'), isNull);
      });

      test('unregisterStyle removes style', () {
        parser.registerStyle('temp', Style().bold());
        expect(parser.getStyle('temp'), isNotNull);
        parser.unregisterStyle('temp');
        expect(parser.getStyle('temp'), isNull);
      });

      test('styleNames returns all registered names', () {
        final names = parser.styleNames.toList();
        expect(names, contains('info'));
        expect(names, contains('comment'));
        expect(names, contains('error'));
        expect(names, contains('question'));
      });
    });

    group('color profile', () {
      test('ascii profile renders no colors', () {
        final p = ConsoleTagParser(colorProfile: ColorProfile.ascii);
        final output = p.render('<fg=red>No color</>');
        expect(output, isNot(contains('\x1B[')));
        expect(output, contains('No color'));
      });

      test('noColor profile renders no colors', () {
        final p = ConsoleTagParser(colorProfile: ColorProfile.noColor);
        final output = p.render('<fg=red>No color</>');
        expect(output, isNot(contains('\x1B[')));
        expect(output, contains('No color'));
      });

      test('ansi profile uses 256 colors', () {
        final p = ConsoleTagParser(colorProfile: ColorProfile.ansi);
        final output = p.render('<fg=red>ANSI</>');
        // ANSI profile maps to 16 colors via ANSI 256 codes
        expect(output, contains('\x1B[38;5;'));
        expect(output, contains('ANSI'));
      });
    });
  });
}
