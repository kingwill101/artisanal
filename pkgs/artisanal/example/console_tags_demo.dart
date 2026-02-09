/// Comprehensive demonstration of Console Tag Parser features.
///
/// This example showcases all the capabilities of the [ConsoleTagParser],
/// including:
/// - Named styles
/// - Inline styles with colors and options
/// - Proper nested tag inheritance
/// - Escape sequences
/// - Hyperlinks
/// - Custom registered styles
///
/// Run with: dart run example/console_tags_demo.dart
library;

import 'package:artisanal/style.dart';

void main() {
  print('');
  print('=' * 70);
  print(' Console Tag Parser - Feature Demonstration');
  print('=' * 70);
  print('');

  // Create a parser instance
  final parser = ConsoleTagParser();

  section('1. Named Styles');

  print(parser.render('<info>Info: This is an informational message</info>'));
  print(parser.render('<comment>Comment: This is a comment or note</comment>'));
  print(
    parser.render(
      '<question>Question: Would you like to continue? [Y/n]</question>',
    ),
  );
  print(parser.render('<error>Error: Something went wrong!</error>'));
  print(parser.render('<success>Success: Operation completed!</success>'));
  print(
    parser.render(
      '<warning>Warning: Please review before proceeding</warning>',
    ),
  );
  print(
    parser.render('<danger>Danger: This action cannot be undone!</danger>'),
  );
  print(parser.render('<muted>Muted: Less important information</muted>'));

  // Built-in text decoration styles
  print('');
  print(parser.render('<bold>Bold text</bold>'));
  print(parser.render('<dim>Dim/faint text</dim>'));
  print(parser.render('<italic>Italic text</italic>'));
  print(parser.render('<underline>Underlined text</underline>'));
  print(parser.render('<strikethrough>Strikethrough text</strikethrough>'));

  // 2. INLINE STYLES - FOREGROUND COLORS
  section('2. Foreground Colors');

  // Basic named colors
  print('Basic ANSI colors:');
  print(
    parser.render(
      '  <fg=black>black</> <fg=red>red</> <fg=green>green</> <fg=yellow>yellow</> '
      '<fg=blue>blue</> <fg=magenta>magenta</> <fg=cyan>cyan</> <fg=white>white</>',
    ),
  );

  // Bright colors
  print('');
  print('Bright ANSI colors:');
  print(
    parser.render(
      '  <fg=bright-black>bright-black</> <fg=bright-red>bright-red</> '
      '<fg=bright-green>bright-green</> <fg=bright-yellow>bright-yellow</>',
    ),
  );
  print(
    parser.render(
      '  <fg=bright-blue>bright-blue</> <fg=bright-magenta>bright-magenta</> '
      '<fg=bright-cyan>bright-cyan</> <fg=bright-white>bright-white</>',
    ),
  );

  // Hex colors (TrueColor)
  print('');
  print('Hex colors (TrueColor):');
  print(
    parser.render(
      '  <fg=#ff5500>Orange #ff5500</> '
      '<fg=#00ff88>Mint #00ff88</> '
      '<fg=#ff00ff>Fuchsia #ff00ff</> '
      '<fg=#00ccff>Sky #00ccff</>',
    ),
  );

  // ANSI 256 colors
  print('');
  print('ANSI 256 palette:');
  final ansi256 = StringBuffer('  ');
  for (var i = 16; i < 52; i++) {
    ansi256.write('<fg=$i>\u2588</>');
  }
  print(parser.render(ansi256.toString()));

  // 3. INLINE STYLES - BACKGROUND COLORS
  section('3. Background Colors');

  print(
    parser.render(
      '  <bg=red> Red </> <bg=green> Green </> <bg=blue> Blue </> '
      '<bg=yellow><fg=black> Yellow </></> <bg=magenta> Magenta </> <bg=cyan><fg=black> Cyan </>',
    ),
  );

  print('');
  print(
    parser.render(
      '  <bg=#ff5500><fg=white> Hex Orange </></> '
      '<bg=#00ff88><fg=black> Hex Mint </></> '
      '<bg=#6366f1><fg=white> Hex Indigo </>',
    ),
  );

  // 4. TEXT OPTIONS
  section('4. Text Options');

  print(parser.render('<options=bold>Bold text</>'));
  print(parser.render('<options=dim>Dim/faint text</>'));
  print(parser.render('<options=italic>Italic text</>'));
  print(parser.render('<options=underline>Underlined text</>'));
  print(
    parser.render('<options=blink>Blinking text</> (if terminal supports)'),
  );
  print(parser.render('<options=reverse>Reverse video</>'));
  print(parser.render('<options=strikethrough>Strikethrough text</>'));

  print('');
  print('Multiple options:');
  print(parser.render('  <options=bold,underline>Bold + Underline</>'));
  print(
    parser.render('  <options=italic,strikethrough>Italic + Strikethrough</>'),
  );
  print(
    parser.render(
      '  <options=bold,italic,underline>Bold + Italic + Underline</>',
    ),
  );

  // 5. COMBINED STYLES
  section('5. Combined Styles');

  print(parser.render('<fg=white;bg=blue> White on Blue </>'));
  print(
    parser.render('<fg=black;bg=yellow;options=bold> Bold Black on Yellow </>'),
  );
  print(
    parser.render(
      '<fg=#ff5500;bg=#1a1a2e;options=bold,underline> Custom Styled Text </>',
    ),
  );

  print('');
  print('Status badges:');
  print(
    parser.render(
      '  <fg=white;bg=green;options=bold> PASS </> All tests passed',
    ),
  );
  print(
    parser.render('  <fg=white;bg=red;options=bold> FAIL </> 3 tests failed'),
  );
  print(
    parser.render(
      '  <fg=black;bg=yellow;options=bold> WARN </> Deprecated API usage',
    ),
  );
  print(
    parser.render(
      '  <fg=white;bg=blue;options=bold> INFO </> Build completed in 2.3s',
    ),
  );

  // 6. NESTED TAGS (Key Feature!)
  section('6. Nested Tags with Style Inheritance');

  print('The key improvement over the old parser - proper nesting:');
  print('');

  // Simple nesting
  print(
    parser.render(
      '<fg=green>Green text, <options=bold>bold green</>, still green</>',
    ),
  );

  // Deep nesting
  print(
    parser.render(
      '<fg=blue>Blue <options=bold>bold <options=underline>bold+underline</> bold</> blue</>',
    ),
  );

  // Color override in nested tag
  print(
    parser.render(
      '<fg=cyan>Cyan, <fg=yellow>yellow override</>, back to cyan</>',
    ),
  );

  // Named style with nested inline
  print(
    parser.render(
      '<info>Info message with <options=bold>emphasized</> word</info>',
    ),
  );

  // Complex nesting example
  print('');
  print('Complex example:');
  print(
    parser.render(
      '<fg=white;bg=#2d2d2d> File: <fg=cyan>main.dart</> | '
      'Line: <fg=yellow>42</> | '
      '<fg=red;options=bold>Error:</> <fg=#ff6b6b>Unexpected token</> </>',
    ),
  );

  // 7. Escape Sequences
  section('7. Escape Sequences');

  print(r'Use \< to output literal < characters:');
  print('');
  print(parser.render(r'  Syntax: \<tagname>content\</tagname>'));
  print(parser.render(r'  Example: \<info>This is info\</info>'));
  print(parser.render(r'  Mixed: \<escaped> but <info>this is styled</info>'));

  // 8. Hyperlinks (OSC 8)
  section('8. Hyperlinks (OSC 8)');

  print('Clickable links (terminal support required):');
  print('');
  print(parser.render('  <href=https://dart.dev>Dart Programming Language</>'));
  print(parser.render('  <href=https://github.com>GitHub</>'));

  // Styled hyperlinks
  print('');
  print('Styled hyperlinks:');
  print(
    parser.render(
      '  <fg=blue;options=underline;href=https://pub.dev>pub.dev</>',
    ),
  );
  print(
    parser.render(
      '  <fg=#ff5500;options=bold;href=https://artisanal.dev>Artisanal Docs</>',
    ),
  );

  // 9. Custom Registered Styles
  section('9. Custom Registered Styles');

  // Register custom styles
  parser.registerStyle(
    'brand',
    Style().foreground(BasicColor('#ff5500')).bold(),
  );

  parser.registerStyle(
    'code',
    Style().foreground(BasicColor('#e06c75')).background(BasicColor('#282c34')),
  );

  parser.registerStyle(
    'highlight',
    Style().foreground(Colors.black).background(BasicColor('#ffd700')).bold(),
  );

  parser.registerStyle(
    'link',
    Style().foreground(BasicColor('#61afef')).underline(),
  );

  print('Custom styles registered:');
  print('');
  print(parser.render('  <brand>Artisanal Framework</brand>'));
  print(parser.render('  <code> void main() { } </code>'));
  print(parser.render('  <highlight> IMPORTANT </highlight>'));
  print(parser.render('  <link>Click here for more</link>'));

  // 10. Practical Examples
  section('10. Practical Examples');

  // Git status output
  print('Git-style output:');
  print(parser.render('  <fg=green>+</> <fg=green>lib/src/new_file.dart</>'));
  print(parser.render('  <fg=red>-</> <fg=red>lib/src/old_file.dart</>'));
  print(parser.render('  <fg=yellow>M</> <fg=yellow>lib/src/modified.dart</>'));

  print('');

  // Log output
  print('Log output:');
  print(
    parser.render(
      '  <muted>2024-01-20 10:30:15</muted> <fg=white;bg=blue;options=bold> INFO </> '
      'Server started on <fg=cyan>http://localhost:8080</>',
    ),
  );
  print(
    parser.render(
      '  <muted>2024-01-20 10:30:16</muted> <fg=white;bg=yellow;options=bold> WARN </> '
      'Deprecated API endpoint <fg=yellow>/api/v1/old</> called',
    ),
  );
  print(
    parser.render(
      '  <muted>2024-01-20 10:30:17</muted> <fg=white;bg=red;options=bold> ERR  </> '
      'Connection failed: <fg=red>timeout after 30s</>',
    ),
  );

  print('');

  // CLI help text
  print('CLI help text:');
  print(
    parser.render(
      '  <options=bold>artisanal</> <fg=cyan>create</> <muted>[options]</muted> <fg=green><name></>',
    ),
  );
  print(parser.render(''));
  print(parser.render('  <options=bold>Options:</>'));
  print(
    parser.render(
      '    <fg=cyan>-t, --template</> <muted><name></>   Template to use <muted>(default: "default")</>',
    ),
  );
  print(
    parser.render(
      '    <fg=cyan>-f, --force</>              Overwrite existing files',
    ),
  );
  print(
    parser.render(
      '    <fg=cyan>-h, --help</>               Show this help message',
    ),
  );

  // 11. Color Profiles
  section('11. Color Profiles');

  final text = '<fg=#ff5500;options=bold>Colored Text</>';

  print('Same text with different color profiles:');
  print('');

  final trueColorParser = ConsoleTagParser(
    colorProfile: ColorProfile.trueColor,
  );
  print('  TrueColor: ${trueColorParser.render(text)}');

  final ansi256Parser = ConsoleTagParser(colorProfile: ColorProfile.ansi256);
  print('  ANSI 256:  ${ansi256Parser.render(text)}');

  final ansiParser = ConsoleTagParser(colorProfile: ColorProfile.ansi);
  print('  ANSI 16:   ${ansiParser.render(text)}');

  final asciiParser = ConsoleTagParser(colorProfile: ColorProfile.ascii);
  print('  ASCII:     ${asciiParser.render(text)}');

  // 12. Parser API
  section('12. Parser API');

  print('Available named styles:');
  print('  ${parser.styleNames.join(", ")}');

  print('');
  print('Parse into segments (AST):');
  final segments = parser.parse('<info>Hello</info> <fg=red>World</>');
  for (final segment in segments) {
    print('  $segment');
  }

  print('');
  print('=' * 70);
  print(' End of Console Tag Parser Demo');
  print('=' * 70);
  print('');
}

void section(String title) {
  print('');
  print('\u2500' * 70);
  print(' $title');
  print('\u2500' * 70);
  print('');
}
