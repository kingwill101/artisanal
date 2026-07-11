/// Console Tag Parser + Console integration demo.
///
/// Demonstrates ConsoleTagParser features and Console class tag integration.
///
/// Run with: dart run example/lipgloss_console_tags.dart
library;

import 'package:artisanal/artisanal.dart';
import 'package:artisanal/style.dart';

void main() {
  parserDemo();
  integrationDemo();
}

// ═════════════════════════════════════════════════════════════════════════════
// ConsoleTagParser feature demo
// ═════════════════════════════════════════════════════════════════════════════

void parserDemo() {
  print('');
  print('=' * 70);
  print(' Console Tag Parser - Feature Demonstration');
  print('=' * 70);
  print('');

  final parser = ConsoleTagParser();

  section('1. Named Styles');
  print(parser.render('<info>Info: This is an informational message</info>'));
  print(parser.render('<comment>Comment: This is a comment or note</comment>'));
  print(parser.render('<question>Question: What is your name?</question>'));
  print(parser.render('<error>Error: Something went wrong</error>'));
  print(parser.render('<success>Success: Operation completed</success>'));
  print(parser.render('<warning>Warning: Proceed with caution</warning>'));
  print('');

  section('2. Inline Styles');
  print(parser.render('<fg=red>Red foreground text</>'));
  print(parser.render('<bg=blue>Blue background text</>'));
  print(parser.render('<options=bold>Bold text</>'));
  print(parser.render('<options=underline>Underlined text</>'));
  print(parser.render('<options=dim>Dim text</>'));
  print(parser.render('<options=italic>Italic text</>'));
  print(parser.render('<options=strikethrough>Strikethrough text</>'));
  print(parser.render('<options=bold,underline,italic>Multiple options</>'));
  print(
    parser.render('<fg=green;bg=black;options=bold>Combined inline style</>'),
  );
  print(parser.render('<fg=#ff5500>Hex color: Custom orange</>'));
  print(parser.render('<fg=#00ff00>Hex color: Bright green</>'));
  print('');

  section('3. Color Spectrum');
  final colors = ['red', 'green', 'yellow', 'blue', 'magenta', 'cyan', 'white'];
  for (final color in colors) {
    print(
      parser.render(
        '<fg=$color>${color.padLeft(7)}</>  '
        '<bg=$color>  </>  '
        '<fg=black;bg=$color>$color background</>',
      ),
    );
  }
  print('');

  section('4. Nested Tags');
  print(parser.render('<fg=green>Green text <options=bold>with bold</></>'));
  print(
    parser.render('<fg=red>Red <fg=yellow>yellow nested</> back to red</>'),
  );
  print(
    parser.render(
      '<info>Info <fg=red>red</> <fg=yellow>yellow</> inside info</>',
    ),
  );
  print(
    parser.render(
      '<fg=cyan;options=bold>Bold cyan <options=underline>underlined</> still bold cyan</>',
    ),
  );
  print('');

  section('5. Escape Sequences');
  print(parser.render(r'Literal tag: \<info>not a tag\</info>'));
  print(parser.render(r'Escaped brackets: \{hello\}'));
  print(parser.render(r'Mixed: \<info>escaped\</info> <info>real</info>'));
  print('');

  section('6. Deeply Nested Structures');
  print(
    parser.render(
      '<info>Level 1 <success>Level 2 <warning>Level 3 <error>Level 4'
      '</error> back to 3</warning> back to 2</success> back to 1</info>',
    ),
  );
  print('');

  section('7. Custom Styles');
  parser.registerStyle(
    'brand',
    Style().foreground(BasicColor('#ff5500')).bold().underline(),
  );
  parser.registerStyle(
    'highlight',
    Style().foreground(BasicColor('#ffff00')).background(BasicColor('#0000ff')),
  );
  parser.registerStyle('subtle', Style().foreground(AnsiColor(245)).italic());
  parser.registerStyle(
    'alert',
    Style()
        .foreground(BasicColor('#ffffff'))
        .background(BasicColor('#ff0000'))
        .bold(),
  );

  print(parser.render('<brand>Brand style - bold, underlined, orange</>'));
  print(parser.render('<highlight>Highlight - yellow on blue</>'));
  print(parser.render('<subtle>Subtle style - gray italic</>'));
  print(parser.render('<alert>Alert style - white on red bold</>'));
  print(
    parser.render(
      '<info>Built-in <brand>custom</> <highlight>styles</> in nested context</>',
    ),
  );
  print('');

  section('8. Hyperlinks');
  print(
    parser.render('Hyperlink: <href=https://example.com>Example Website</>'),
  );
  print(
    parser.render(
      'Styled hyperlink: <fg=cyan;options=underline;href=https://dart.dev>'
      'Dart Documentation</>',
    ),
  );
  print('');

  section('9. Performance');
  final stopwatch = Stopwatch()..start();
  for (var i = 0; i < 1000; i++) {
    parser.render('<info>Test <fg=red>$i</> <options=bold>iteration</></info>');
  }
  stopwatch.stop();
  print(
    '  Rendered 1000 complex templates in ${stopwatch.elapsedMilliseconds}ms',
  );
  print('');

  section('10. Edge Cases');
  print(parser.render('<info></info>'));
  print(
    parser.render(
      '<info><info><info>Triple nested same tag</info></info></info>',
    ),
  );
  print(
    parser.render(
      '<fg=red;bg=red;options=bold,underline,italic,strikethrough>All options at once</>',
    ),
  );
  print(
    parser.render('<fg=red>Unclosed tag (should auto-close at end of string)'),
  );
  print(parser.render(r'<fg=green>\<escaped inside\></>'));
  print('');

  section('11. Overlapping vs. Proper Nesting');
  print(parser.render('<info>Proper <success>nesting</success> works</info>'));
  print(
    parser.render(
      '<info>Overlapping <success>tags</info> may not work</success>',
    ),
  );
  print('');
}

void section(String title) {
  print('  ${Style().bold().render(title)}');
}

// ═════════════════════════════════════════════════════════════════════════════
// Console integration demo
// ═════════════════════════════════════════════════════════════════════════════

void integrationDemo() {
  final console = Console();

  console.title('Console Tag Parser Integration Demo');

  console.section('Built-in Named Styles');
  console.writeln('<info>This is an info message</info>');
  console.writeln('<comment>This is a comment</comment>');
  console.writeln('<question>This is a question?</question>');
  console.writeln('<error>This is an error message</error>');
  console.writeln('<success>This is a success message</success>');
  console.writeln('<warning>This is a warning message</warning>');
  console.newLine();

  console.section('Inline Style Tags');
  console.writeln('<fg=red>Red text</>');
  console.writeln('<bg=blue>Blue background</>');
  console.writeln('<options=bold,underline>Bold and underlined</>');
  console.writeln('<fg=green;bg=black;options=bold>Combined styles</>');
  console.writeln('<fg=#ff5500>Hex color text</>');
  console.newLine();

  console.section('Nested Tags');
  console.writeln('<fg=green>Green <options=bold>bold green</> still green</>');
  console.writeln('<info>Info with <fg=yellow>yellow</> text</info>');
  console.newLine();

  console.section('Custom Registered Styles');
  console.registerStyle(
    'brand',
    Style().foreground(BasicColor('#ff5500')).bold(),
  );
  console.registerStyle(
    'highlight',
    Style().foreground(Colors.yellow).background(Colors.black).bold(),
  );
  console.writeln('<brand>This uses the custom brand style</brand>');
  console.writeln(
    '<highlight>This uses the custom highlight style</highlight>',
  );
  console.newLine();

  console.section('Tags in Message Blocks');
  console.info('This is <fg=yellow>info</> with <options=bold>tags</>');
  console.success(
    'This is <fg=cyan>success</> with <options=underline>tags</>',
  );
  console.warn('This is <fg=red>warning</> with <options=bold>tags</>');
  console.error('This is <fg=white>error</> with <options=bold>tags</>');
  console.newLine();

  console.section('Tags in Alert Box');
  console.alert('This is an <fg=red>alert</> with <options=bold>tags</>!');

  console.title('Title with <fg=cyan>colored</> text');
  console.section('Section with <fg=yellow>colored</> text');

  console.text('Indented text with <info>tags</info>');
  console.listing([
    'Item with <success>success</success> tag',
    'Item with <warning>warning</warning> tag',
    'Item with <fg=magenta>custom color</>',
  ]);

  console.section('All Registered Styles');
  console.writeln('Available style names:');
  for (final name in console.styleNames) {
    console.writeln('  - <$name>$name</$name>');
  }
  console.newLine();

  console.section('Escaping Tags');
  // ignore: avoid_print
  print(r'Use \<info> to output a literal tag');
  console.writeln('This will show: \\<info>literal tag\\</info>');
  console.newLine();

  console.success('Demo complete!');
}
