import 'package:artisanal/artisanal.dart';

/// Demonstrates the integration of ConsoleTagParser with Console class.
///
/// This example shows how to use Symfony/Laravel-style tags in console output
/// and how to register custom styles.
void main() {
  final console = Console();

  console.title('Console Tag Parser Integration Demo');

  // Basic tag usage with built-in styles
  console.section('Built-in Named Styles');
  console.writeln('<info>This is an info message</info>');
  console.writeln('<comment>This is a comment</comment>');
  console.writeln('<question>This is a question?</question>');
  console.writeln('<error>This is an error message</error>');
  console.writeln('<success>This is a success message</success>');
  console.writeln('<warning>This is a warning message</warning>');
  console.newLine();

  // Inline style tags
  console.section('Inline Style Tags');
  console.writeln('<fg=red>Red text</>');
  console.writeln('<bg=blue>Blue background</>');
  console.writeln('<options=bold,underline>Bold and underlined</>');
  console.writeln('<fg=green;bg=black;options=bold>Combined styles</>');
  console.writeln('<fg=#ff5500>Hex color text</>');
  console.newLine();

  // Nested tags
  console.section('Nested Tags');
  console.writeln('<fg=green>Green <options=bold>bold green</> still green</>');
  console.writeln('<info>Info with <fg=yellow>yellow</> text</info>');
  console.newLine();

  // Register custom styles
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

  // Using tags in message block methods
  console.section('Tags in Message Blocks');
  console.info('This is <fg=yellow>info</> with <options=bold>tags</>');
  console.success(
    'This is <fg=cyan>success</> with <options=underline>tags</>',
  );
  console.warn('This is <fg=red>warning</> with <options=bold>tags</>');
  console.error('This is <fg=white>error</> with <options=bold>tags</>');
  console.newLine();

  // Using tags in alert
  console.section('Tags in Alert Box');
  console.alert('This is an <fg=red>alert</> with <options=bold>tags</>!');

  // Using tags in title and section
  console.title('Title with <fg=cyan>colored</> text');
  console.section('Section with <fg=yellow>colored</> text');

  // Using tags in text and listing
  console.text('Indented text with <info>tags</info>');
  console.listing([
    'Item with <success>success</success> tag',
    'Item with <warning>warning</warning> tag',
    'Item with <fg=magenta>custom color</>',
  ]);

  // Show all registered styles
  console.section('All Registered Styles');
  console.writeln('Available style names:');
  for (final name in console.styleNames) {
    console.writeln('  - <$name>$name</$name>');
  }
  console.newLine();

  // Escaping tags
  console.section('Escaping Tags');
  console.writeln(r'Use \<info> to output a literal tag');
  console.writeln('This will show: \\<info>literal tag\\</info>');
  console.newLine();

  console.success('Demo complete!');
}
