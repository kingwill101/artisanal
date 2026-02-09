import 'dart:async';
import 'dart:io' as dartio;
import 'package:artisanal/artisanal.dart';
import 'package:artisanal/bubbles.dart' as bubbles;
import 'package:artisanal/tui.dart';

// #region verbosity_usage
void demonstrateVerbosity(Console console) {
  console.writeln('This is a normal message');

  console.info('This is an info message (shown in normal/verbose/debug)');

  // The following only show if verbosity is set appropriately
  console.verbose('This is a verbose message (shown in verbose/debug)');
  console.debug('This is a debug message (only shown in debug)');
}
// #endregion

// #region ansi_usage
void demonstrateAnsi() {
  dartio.stdout.write(Ansi.cursorTo(0, 0));
  dartio.stdout.write(Ansi.bold);
  dartio.stdout.write('Top Left Bold');
  dartio.stdout.write(Ansi.reset);
  dartio.stdout.writeln();
}
// #endregion

// #region command_runner_usage
Future<void> main(List<String> args) async {
  final runner = CommandRunner<void>('artisanal-demo', 'artisanal demo CLI')
    ..addCommand(DemoCommand())
    ..addCommand(UiTaskCommand())
    ..addCommand(UiTaskGroupCommand())
    ..addCommand(UiStepsCommand())
    ..addCommand(UiCountdownCommand())
    ..addCommand(UiTableCommand())
    ..addCommand(UiPromptsCommand())
    ..addCommand(UiProgressCommand())
    ..addCommand(UiComponentsCommand())
    ..addCommand(UiSecretCommand())
    ..addCommand(UiSelectCommand())
    ..addCommand(UiMultiSelectCommand())
    ..addCommand(UiSpinCommand())
    ..addCommand(UiSpinnerCommand())
    ..addCommand(UiSpinnerStylesCommand())
    ..addCommand(UiPanelCommand())
    ..addCommand(UiTreeCommand())
    ..addCommand(UiTreeConvenienceCommand())
    ..addCommand(UiSearchCommand())
    ..addCommand(UiSearchConvenienceCommand())
    ..addCommand(UiPauseCommand())
    ..addCommand(UiChalkCommand())
    ..addCommand(UiValidatorsCommand())
    ..addCommand(UiExceptionCommand())
    ..addCommand(UiHorizontalTableCommand())
    ..addCommand(UiPasswordCommand())
    ..addCommand(UiBlockCommand())
    ..addCommand(UiColumnsCommand())
    ..addCommand(UiTerminalCommand())
    ..addCommand(UiAnticipateCommand())
    ..addCommand(UiTextareaCommand())
    ..addCommand(UiWizardCommand())
    ..addCommand(UiLinkCommand())
    ..addCommand(UiComponentSystemCommand())
    ..addCommand(UiAllCommand());

  await runner.run(args);
}
// #endregion

// #region command_definition_usage
class DemoCommand extends Command<void> {
  @override
  String get name => 'demo';

  @override
  String get description =>
      'Showcase basic output helpers (title/section/blocks/listing).';

  @override
  Future<void> run() async {
    io.title('artisanal');

    io.section('Messages');
    io.info('Info message');
    io.success('Success message');
    io.warn('Warning message');
    io.error('Error message');
    io.note('Note message');
    io.caution('Caution message');

    io.section('Listing');
    io.listing(['one', 'two', 'three']);

    io.section('Two Column Detail');
    io.twoColumnDetail('Driver', 'sqlite');
    io.twoColumnDetail('Database', 'example.sqlite');
    io.newLine();

    io.section('Task');
    await io.task(
      'Run a sample task',
      run: () async {
        await Future<void>.delayed(const Duration(milliseconds: 40));
        return TaskResult.success;
      },
    );
  }
}
// #endregion

class UiTaskCommand extends Command<void> {
  UiTaskCommand() {
    argParser
      ..addFlag('fail', negatable: false, help: 'Return FAIL instead of DONE.')
      ..addFlag(
        'skip',
        negatable: false,
        help: 'Return SKIPPED instead of DONE.',
      );
  }

  @override
  String get name => 'ui:task';

  @override
  String get description => 'Render a task line.';

  @override
  Future<void> run() async {
    final fail = argResults?['fail'] == true;
    final skip = argResults?['skip'] == true;

    await io.task(
      'Build something',
      run: () async {
        await Future<void>.delayed(const Duration(milliseconds: 80));
        if (fail) return TaskResult.failure;
        if (skip) return TaskResult.skipped;
        return TaskResult.success;
      },
    );
  }
}

/// Demonstrate taskGroup - running multiple tasks with progress tracking.
class UiTaskGroupCommand extends Command<void> {
  UiTaskGroupCommand() {
    argParser
      ..addFlag('fail', negatable: false, help: 'Make one task fail.')
      ..addFlag(
        'parallel',
        abbr: 'p',
        negatable: false,
        help: 'Run tasks in parallel (simulated).',
      );
  }

  @override
  String get name => 'ui:taskgroup';

  @override
  String get description =>
      'Demonstrate taskGroup for running multiple tasks with progress.';

  @override
  Future<void> run() async {
    final shouldFail = argResults?['fail'] == true;

    io.title('Task Group Demo');
    io.text('Running multiple tasks with progress tracking.');
    io.newLine();

    final result = await io.taskGroup(
      title: 'Deployment Pipeline',
      tasks: [
        (
          'Compile assets',
          () async {
            await Future<void>.delayed(const Duration(milliseconds: 400));
          },
        ),
        (
          'Run tests',
          () async {
            await Future<void>.delayed(const Duration(milliseconds: 600));
            if (shouldFail) throw Exception('Test suite failed');
          },
        ),
        (
          'Build Docker image',
          () async {
            await Future<void>.delayed(const Duration(milliseconds: 500));
          },
        ),
        (
          'Push to registry',
          () async {
            await Future<void>.delayed(const Duration(milliseconds: 300));
          },
        ),
        (
          'Deploy to staging',
          () async {
            await Future<void>.delayed(const Duration(milliseconds: 400));
          },
        ),
      ],
      continueOnError: false,
    );

    io.newLine();
    io.section('Result');
    io.twoColumnDetail('Completed', result.completed.length.toString());
    io.twoColumnDetail('Failed', result.failed.length.toString());
    io.twoColumnDetail('Skipped', result.skipped.length.toString());
    io.twoColumnDetail('Duration', '${result.duration?.inMilliseconds ?? 0}ms');
  }
}

/// Demonstrate steps - multi-step workflows with numbered progress.
class UiStepsCommand extends Command<void> {
  UiStepsCommand() {
    argParser.addFlag('fail', negatable: false, help: 'Make one step fail.');
  }

  @override
  String get name => 'ui:steps';

  @override
  String get description =>
      'Demonstrate steps for multi-step workflows with numbered progress.';

  @override
  Future<void> run() async {
    final shouldFail = argResults?['fail'] == true;

    io.title('Steps Demo');
    io.text('Running a multi-step workflow with numbered progress.');
    io.newLine();

    final result = await io.steps(
      title: 'Project Setup',
      steps: [
        (
          'Create directory structure',
          () async {
            await Future<void>.delayed(const Duration(milliseconds: 300));
          },
        ),
        (
          'Initialize Git repository',
          () async {
            await Future<void>.delayed(const Duration(milliseconds: 200));
          },
        ),
        (
          'Install dependencies',
          () async {
            await Future<void>.delayed(const Duration(milliseconds: 500));
            if (shouldFail) throw Exception('Failed to install dependencies');
          },
        ),
        (
          'Generate configuration files',
          () async {
            await Future<void>.delayed(const Duration(milliseconds: 250));
          },
        ),
        (
          'Run initial build',
          () async {
            await Future<void>.delayed(const Duration(milliseconds: 400));
          },
        ),
      ],
      continueOnError: false,
    );

    io.newLine();
    io.section('Workflow Result');
    io.twoColumnDetail('Steps completed', result.completed.length.toString());
    io.twoColumnDetail('Steps failed', result.failed.length.toString());
    io.twoColumnDetail('Steps skipped', result.skipped.length.toString());
    io.twoColumnDetail(
      'Total time',
      '${result.duration?.inMilliseconds ?? 0}ms',
    );
  }
}

/// Demonstrate countdown timer for destructive operations.
class UiCountdownCommand extends Command<void> {
  UiCountdownCommand() {
    argParser.addOption(
      'seconds',
      abbr: 's',
      defaultsTo: '5',
      help: 'Number of seconds to count down.',
    );
  }

  @override
  String get name => 'ui:countdown';

  @override
  String get description =>
      'Demonstrate countdown timer (useful before destructive operations).';

  @override
  Future<void> run() async {
    final seconds = int.tryParse(argResults?['seconds'] as String? ?? '5') ?? 5;

    io.title('Countdown Demo');
    io.text('This shows a countdown timer before an action.');
    io.warn('Commonly used before destructive operations.');
    io.newLine();

    await io.countdown('Proceeding in', seconds: seconds);

    io.newLine();
    io.success('Action executed!');
  }
}

class UiTableCommand extends Command<void> {
  @override
  String get name => 'ui:table';

  @override
  String get description => 'Render a simple ASCII table.';

  @override
  Future<void> run() async {
    io.table(
      headers: ['id', 'name', 'status'],
      rows: [
        [
          1,
          'create_users_table',
          io.style.foreground(Colors.success).render('DONE'),
        ],
        [
          2,
          'add_posts_table',
          io.style.foreground(Colors.warning).render('PENDING'),
        ],
      ],
    );
  }
}

class UiPromptsCommand extends Command<void> {
  UiPromptsCommand() {
    argParser.addFlag(
      'defaults',
      negatable: false,
      help: 'Use defaults so --no-interaction can run.',
    );
  }

  @override
  String get name => 'ui:prompts';

  @override
  String get description => 'Demonstrate confirm/ask/choice prompts.';

  @override
  Future<void> run() async {
    final useDefaults = argResults?['defaults'] == true;

    io.title('Prompts');

    final confirmed = io.confirm('Continue?', defaultValue: true);
    io.twoColumnDetail('confirm', confirmed.toString());

    final name = io.ask(
      'Your name',
      defaultValue: useDefaults ? 'Anonymous' : null,
      validator: (value) =>
          value.trim().isEmpty ? 'Name cannot be empty' : null,
    );
    io.twoColumnDetail('ask', name);

    final selected = io.choice(
      'Pick a driver',
      choices: const ['sqlite', 'postgres', 'mysql'],
      defaultIndex: useDefaults ? 0 : null,
    );
    io.twoColumnDetail('choice', selected.toString());
  }
}

class UiProgressCommand extends Command<void> {
  UiProgressCommand() {
    argParser.addOption(
      'count',
      defaultsTo: '25',
      help: 'How many steps to run.',
    );
  }

  @override
  String get name => 'ui:progress';

  @override
  String get description => 'Render a simple progress bar.';

  @override
  Future<void> run() async {
    final countRaw = argResults?['count'] as String? ?? '25';
    final count = int.tryParse(countRaw) ?? 25;

    for (final _ in io.progressIterate(
      List<int>.filled(count, 0),
      max: count,
    )) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }
}

/// Demonstrate the components facade
class UiComponentsCommand extends Command<void> {
  @override
  String get name => 'ui:components';

  @override
  String get description =>
      'Demonstrate the components facade (bulletList, definitionList, rule, etc).';

  @override
  Future<void> run() async {
    io.title('Components Facade');

    io.section('Bullet List');
    io.components.bulletList([
      'First item in the list',
      'Second item in the list',
      'Third item in the list',
    ]);

    io.section('Definition List');
    io.components.definitionList({
      'Application Name': 'artisanal Demo',
      'Version': '1.0.0',
      'Environment': 'development',
      'Debug Mode': 'enabled',
    });

    io.section('Horizontal Rule');
    io.components.rule();
    io.components.rule('Section Divider');

    io.section('Line Separator');
    io.components.line();
    io.components.line(40);

    io.section('Titled Messages');
    io.components.info('Information', 'This is an informational message.');
    io.components.success('Success', 'Operation completed successfully!');
    io.components.warn('Warning', 'Please review before proceeding.');
    io.components.error('Error', 'Something went wrong.');

    io.section('Alert Box');
    io.components.alert('This is an important alert message!');

    io.section('Two Column Detail');
    io.components.twoColumnDetail('Database', 'SQLite');
    io.components.twoColumnDetail('Host', 'localhost');
    io.components.twoColumnDetail('Port', '5432');

    io.section('Task (via components)');
    await io.components.task(
      'Running migrations',
      run: () async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return TaskResult.success;
      },
    );
  }
}

/// Demonstrate secret/password input (no echo).
class UiSecretCommand extends Command<void> {
  UiSecretCommand() {
    argParser.addFlag(
      'defaults',
      negatable: false,
      help: 'Use fallback value for non-interactive mode.',
    );
  }

  @override
  String get name => 'ui:secret';

  @override
  String get description => 'Demonstrate secret/password input (no echo).';

  @override
  Future<void> run() async {
    final useDefaults = argResults?['defaults'] == true;

    io.title('Secret Input');
    io.text('Characters will not be echoed as you type.');
    io.newLine();

    final password = await io.secret(
      'Enter your password',
      fallback: useDefaults ? '***hidden***' : null,
    );

    io.newLine();
    io.success('Password received (${password.length} characters)');
    io.twoColumnDetail('Length', '${password.length} chars');
  }
}

/// Demonstrate interactive single-select with arrow-key navigation.
class UiSelectCommand extends Command<void> {
  UiSelectCommand() {
    argParser.addFlag(
      'defaults',
      negatable: false,
      help: 'Use default selection for non-interactive mode.',
    );
  }

  @override
  String get name => 'ui:select';

  @override
  String get description =>
      'Demonstrate interactive single-select with arrow-key navigation.';

  @override
  Future<void> run() async {
    final useDefaults = argResults?['defaults'] == true;

    io.title('Interactive Single Select');
    io.text('Use arrow keys to navigate, Enter to select, q to cancel.');
    io.newLine();

    final databases = [
      'SQLite (lightweight, file-based)',
      'PostgreSQL (powerful, ACID-compliant)',
      'MySQL (popular, widely deployed)',
      'MongoDB (document-oriented, NoSQL)',
    ];

    final selected = await io.selectChoice(
      'Choose your database',
      choices: databases,
      defaultIndex: useDefaults ? 1 : 0,
    );

    io.newLine();
    if (selected != null) {
      io.success('Selected: $selected');
    } else {
      io.warn('Selection cancelled');
    }
  }
}

/// Demonstrate interactive multi-select with arrow-key navigation.
class UiMultiSelectCommand extends Command<void> {
  UiMultiSelectCommand() {
    argParser.addFlag(
      'defaults',
      negatable: false,
      help: 'Use default selections for non-interactive mode.',
    );
  }

  @override
  String get name => 'ui:multiselect';

  @override
  String get description =>
      'Demonstrate interactive multi-select with arrow-key navigation.';

  @override
  Future<void> run() async {
    final useDefaults = argResults?['defaults'] == true;

    io.title('Interactive Multi Select');
    io.text('Use arrow keys to navigate, Space to toggle, Enter to confirm.');
    io.newLine();

    final features = [
      'Authentication',
      'Database ORM',
      'REST API',
      'GraphQL',
      'WebSocket Support',
      'Email Service',
      'Queue System',
      'Cache Layer',
    ];

    final selected = await io.multiSelectChoice(
      'Select features to enable',
      choices: features,
      defaultSelected: useDefaults ? [0, 1, 2] : [],
    );

    io.newLine();
    if (selected.isEmpty) {
      io.warn('No features selected');
    } else {
      io.success('Selected ${selected.length} feature(s):');
      io.components.bulletList(selected);
    }
  }
}

/// Demonstrate the spin component (spinner with success/fail indicator).
class UiSpinCommand extends Command<void> {
  UiSpinCommand() {
    argParser.addFlag('fail', negatable: false, help: 'Simulate a failure.');
  }

  @override
  String get name => 'ui:spin';

  @override
  String get description =>
      'Demonstrate the spin component (processing indicator).';

  @override
  Future<void> run() async {
    final shouldFail = argResults?['fail'] == true;

    io.title('Spin Component');
    io.text('Shows a processing indicator with success/fail status.');
    io.newLine();

    try {
      final result = await io.components.spin(
        'Connecting to database',
        run: () async {
          await Future<void>.delayed(const Duration(milliseconds: 500));
          return 'Connection established';
        },
      );
      io.twoColumnDetail('Result', result);
    } catch (e) {
      io.error('Connection failed');
    }

    try {
      await io.components.spin(
        'Running migrations',
        run: () async {
          await Future<void>.delayed(const Duration(milliseconds: 300));
          if (shouldFail) {
            throw Exception('Migration failed');
          }
          return null;
        },
      );
      io.success('Migrations completed');
    } catch (e) {
      io.error('Migration error: $e');
    }

    try {
      final count = await io.components.spin(
        'Seeding database',
        run: () async {
          await Future<void>.delayed(const Duration(milliseconds: 400));
          return 42;
        },
      );
      io.twoColumnDetail('Records seeded', count.toString());
    } catch (e) {
      io.error('Seeding failed');
    }
  }
}

/// Demonstrate animated spinner.
class UiSpinnerCommand extends Command<void> {
  UiSpinnerCommand() {
    argParser.addOption(
      'frames',
      abbr: 'f',
      defaultsTo: 'dots',
      help: 'Spinner frame style (dots, line, circle, arc, arrows)',
    );
  }

  @override
  String get name => 'ui:spinner';

  @override
  String get description =>
      'Demonstrate animated spinner with different styles.';

  @override
  Future<void> run() async {
    final frameStyle = argResults?['frames'] as String? ?? 'dots';

    final spinner = switch (frameStyle) {
      'line' => Spinners.line,
      'circle' => Spinners.circle,
      'arc' => Spinners.arc,
      'arrows' => Spinners.arrows,
      _ => Spinners.miniDot,
    };

    io.title('Animated Spinner');
    io.text('This demonstrates a real animated spinner.');
    io.newLine();

    final terminal = StdioTerminal(stdout: dartio.stdout, stdin: dartio.stdin);
    final result = await runSpinnerTask(
      message: 'Processing your request...',
      spinner: spinner,
      terminal: terminal,
      task: () async {
        await Future<void>.delayed(const Duration(seconds: 2));
        return 'Completed successfully!';
      },
    );

    io.success('Result: $result');
  }
}

/// Demonstrate all the new spinner styles.
class UiSpinnerStylesCommand extends Command<void> {
  @override
  String get name => 'ui:spinner-styles';

  @override
  String get description => 'Showcase all available spinner styles.';

  @override
  Future<void> run() async {
    io.title('Spinner Styles Gallery');
    io.text('Showcasing 25+ spinner animation styles.');
    io.newLine();

    final terminal = StdioTerminal(stdout: dartio.stdout, stdin: dartio.stdin);

    // Classic spinners
    io.section('Classic Spinners');

    final classicSpinners = [
      ('miniDot', Spinners.miniDot),
      ('dot', Spinners.dot),
      ('line', Spinners.line),
      ('circle', Spinners.circle),
      ('arc', Spinners.arc),
      ('arrows', Spinners.arrows),
      ('bounce', Spinners.bounce),
    ];

    for (final (name, spinner) in classicSpinners) {
      await runSpinnerTask(
        message: 'Spinner: $name',
        spinner: spinner,
        terminal: terminal,
        task: () async {
          await Future<void>.delayed(const Duration(milliseconds: 800));
        },
      );
    }

    io.newLine();
    io.section('New Spinner Styles');

    final newSpinners = [
      ('boxBounce', Spinners.boxBounce),
      ('boxBounce2', Spinners.boxBounce2),
      ('triangle', Spinners.triangle),
      ('binary', Spinners.binary),
      ('flip', Spinners.flip),
      ('toggle', Spinners.toggle),
      ('toggle2', Spinners.toggle2),
      ('toggle3', Spinners.toggle3),
      ('toggle4', Spinners.toggle4),
      ('star', Spinners.star),
      ('star2', Spinners.star2),
      ('layer', Spinners.layer),
      ('point', Spinners.point),
      ('noise', Spinners.noise),
      ('simpleDots', Spinners.simpleDots),
      ('simpleDotsScrolling', Spinners.simpleDotsScrolling),
    ];

    for (final (name, spinner) in newSpinners) {
      await runSpinnerTask(
        message: 'Spinner: $name',
        spinner: spinner,
        terminal: terminal,
        task: () async {
          await Future<void>.delayed(const Duration(milliseconds: 800));
        },
      );
    }

    io.newLine();
    io.section('Fun & Expressive Spinners');

    final funSpinners = [
      ('aesthetic', Spinners.aesthetic),
      ('weather', Spinners.weather),
      ('christmas', Spinners.christmas),
      ('grenade', Spinners.grenade),
      ('fingerDance', Spinners.fingerDance),
      ('fistBump', Spinners.fistBump),
      ('mindblown', Spinners.mindblown),
      ('speaker', Spinners.speaker),
      ('orangePulse', Spinners.orangePulse),
      ('bluePulse', Spinners.bluePulse),
      ('betaWave', Spinners.betaWave),
      ('sand', Spinners.sand),
    ];

    for (final (name, spinner) in funSpinners) {
      await runSpinnerTask(
        message: 'Spinner: $name',
        spinner: spinner,
        terminal: terminal,
        task: () async {
          await Future<void>.delayed(const Duration(milliseconds: 800));
        },
      );
    }

    io.newLine();
    io.success('All spinner styles demonstrated!');
  }
}

/// Demonstrate panels with box drawing.
class UiPanelCommand extends Command<void> {
  UiPanelCommand() {
    argParser.addOption(
      'style',
      abbr: 's',
      defaultsTo: 'rounded',
      help: 'Box style (rounded, single, double, heavy, ascii)',
    );
  }

  @override
  String get name => 'ui:panel';

  @override
  String get description => 'Demonstrate boxed panels with different styles.';

  @override
  Future<void> run() async {
    final boxStyle = argResults?['style'] as String? ?? 'rounded';

    final chars = switch (boxStyle) {
      'single' => PanelBoxChars.single,
      'double' => PanelBoxChars.double,
      'heavy' => PanelBoxChars.heavy,
      'ascii' => PanelBoxChars.ascii,
      _ => PanelBoxChars.rounded,
    };

    final renderConfig = RenderConfig.fromRenderer(
      defaultRenderer,
      terminalWidth: io.terminalWidth,
    );

    io.title('Panels');

    // Simple panel
    PanelComponent(
      content:
          'This is a simple panel with some content.\nIt can have multiple lines.',
      title: 'Info',
      chars: chars,
      renderConfig: renderConfig,
    ).writelnTo(io);
    io.newLine();

    // Success panel
    PanelComponent(
      content: 'Your operation completed successfully!',
      title: 'Success',
      chars: chars,
      renderConfig: renderConfig,
    ).writelnTo(io);
    io.newLine();

    // Warning panel
    PanelComponent(
      content: 'Please review your configuration before proceeding.',
      title: 'Warning',
      titleAlign: PanelAlignment.center,
      chars: chars,
      renderConfig: renderConfig,
    ).writelnTo(io);
    io.newLine();

    // Columns demo
    io.section('Multi-Column Layout');
    ColumnsComponent(
      items: [
        'apple',
        'banana',
        'cherry',
        'date',
        'elderberry',
        'fig',
        'grape',
        'honeydew',
        'kiwi',
        'lemon',
        'mango',
        'nectarine',
      ],
      columnCount: 4,
      renderConfig: renderConfig,
    ).writelnTo(io);
  }
}

/// Demonstrate tree rendering.
class UiTreeCommand extends Command<void> {
  @override
  String get name => 'ui:tree';

  @override
  String get description => 'Demonstrate tree structure rendering.';

  @override
  Future<void> run() async {
    io.title('Tree Structure');

    final renderConfig = RenderConfig.fromRenderer(
      defaultRenderer,
      terminalWidth: io.terminalWidth,
    );

    TreeComponent(
      data: {
        'lib': {
          'src': {
            'io': ['console.dart', 'components.dart', 'prompts.dart'],
            'output': ['progress_bar.dart', 'spinner.dart', 'table.dart'],
            'runner': ['command.dart', 'command_runner.dart'],
            'style': ['artisanal_style.dart', 'chalk.dart'],
          },
          'artisanal.dart': null,
        },
        'test': ['artisanal_io_test.dart', 'command_runner_test.dart'],
        'example': ['main.dart'],
        'pubspec.yaml': null,
        'README.md': null,
      },
      renderConfig: renderConfig,
    ).writelnTo(io);
  }
}

/// Demonstrate the new Console.tree() convenience method.
class UiTreeConvenienceCommand extends Command<void> {
  UiTreeConvenienceCommand() {
    argParser.addOption(
      'style',
      abbr: 's',
      defaultsTo: 'normal',
      help: 'Tree style (normal, rounded, ascii, bullet, arrow)',
    );
  }

  @override
  String get name => 'ui:tree-convenience';

  @override
  String get description =>
      'Demonstrate the Console.tree() convenience method with different styles.';

  @override
  Future<void> run() async {
    final styleArg = argResults?['style'] as String? ?? 'normal';
    final style = switch (styleArg) {
      'rounded' => TreeStyle.rounded,
      'ascii' => TreeStyle.ascii,
      'bullet' => TreeStyle.bullet,
      'arrow' => TreeStyle.arrow,
      _ => TreeStyle.normal,
    };

    io.title('Console.tree() Convenience Method');
    io.text('Using TreeStyle.$styleArg');
    io.newLine();

    io.tree(
      {
        'src': {
          'lib': ['main.dart', 'utils.dart', 'config.dart'],
          'test': ['main_test.dart', 'utils_test.dart'],
        },
        'docs': ['README.md', 'API.md'],
        'pubspec.yaml': null,
        '.gitignore': null,
      },
      root: 'my_project',
      style: style,
    );

    io.section('All Tree Styles');
    for (final s in TreeStyle.values) {
      io.writeln(io.style.bold().render('TreeStyle.${s.name}:'));
      io.tree({
        'folder': ['file1.txt', 'file2.txt'],
        'other': null,
      }, style: s);
    }
  }
}

/// Demonstrate search prompt.
class UiSearchCommand extends Command<void> {
  UiSearchCommand() {
    argParser.addFlag(
      'defaults',
      negatable: false,
      help: 'Use default for non-interactive mode.',
    );
  }

  @override
  String get name => 'ui:search';

  @override
  String get description => 'Demonstrate searchable selection prompt.';

  @override
  Future<void> run() async {
    io.title('Search Prompt');
    io.text('Type to filter, use arrow keys to navigate, Enter to select.');
    io.newLine();

    final packages = [
      'flutter',
      'dart',
      'args',
      'path',
      'http',
      'json_annotation',
      'build_runner',
      'test',
      'mockito',
      'provider',
      'bloc',
      'riverpod',
      'get_it',
      'dio',
      'sqflite',
      'shared_preferences',
      'hive',
      'drift',
    ];

    final terminal = StdioTerminal(stdout: dartio.stdout, stdin: dartio.stdin);
    final selected = await runSearchPrompt<String>(
      SearchModel<String>(items: packages, title: 'Select a package'),
      terminal,
    );

    io.newLine();
    if (selected != null) {
      io.success('Selected: $selected');
    } else {
      io.warn('Selection cancelled');
    }
  }
}

/// Demonstrate the new Console.search() convenience method.
class UiSearchConvenienceCommand extends Command<void> {
  @override
  String get name => 'ui:search-convenience';

  @override
  String get description =>
      'Demonstrate the Console.search() convenience method.';

  @override
  Future<void> run() async {
    io.title('Console.search() Convenience Method');
    io.text('This uses the simplified console.search() API.');
    io.newLine();

    final files = [
      'lib/src/main.dart',
      'lib/src/utils/helpers.dart',
      'lib/src/utils/validators.dart',
      'lib/src/models/user.dart',
      'lib/src/models/post.dart',
      'lib/src/services/api_service.dart',
      'lib/src/services/auth_service.dart',
      'lib/src/widgets/button.dart',
      'lib/src/widgets/card.dart',
      'test/main_test.dart',
      'test/utils_test.dart',
      'pubspec.yaml',
      'README.md',
    ];

    final selected = await io.search<String>(
      'Select a file to open:',
      items: files,
      placeholder: 'Type to filter files...',
      noResultsText: 'No matching files',
    );

    io.newLine();
    if (selected != null) {
      io.success('Opening: $selected');
    } else {
      io.warn('No file selected');
    }
  }
}

/// Demonstrate pause and countdown.
class UiPauseCommand extends Command<void> {
  UiPauseCommand() {
    argParser.addFlag(
      'countdown',
      abbr: 'c',
      negatable: false,
      help: 'Show countdown instead of pause.',
    );
  }

  @override
  String get name => 'ui:pause';

  @override
  String get description => 'Demonstrate pause and countdown.';

  @override
  Future<void> run() async {
    final showCountdown = argResults?['countdown'] == true;

    io.title('Pause & Countdown');

    final terminal = StdioTerminal(stdout: dartio.stdout, stdin: dartio.stdin);

    if (showCountdown) {
      io.text('Starting countdown...');
      io.newLine();

      await Program(
        CountdownModel(
          duration: const Duration(seconds: 5),
          message: 'Continuing in',
        ),
        options: promptProgramOptions,
        terminal: terminal,
      ).run();
      io.success('Countdown complete!');
    } else {
      io.text('Press any key to continue after this message.');
      io.newLine();

      await Program(
        PauseModel(message: 'Press any key to continue...'),
        options: promptProgramOptions,
        terminal: terminal,
      ).run();

      io.success('You pressed a key!');
    }
  }
}

/// Demonstrate advanced chalk styling.
class UiChalkCommand extends Command<void> {
  @override
  String get name => 'ui:chalk';

  @override
  String get description => 'Demonstrate advanced color styling with Style.';

  @override
  Future<void> run() async {
    final style = io.style;

    io.title('Advanced Styling with Style');

    io.section('Basic Colors');
    io.writeln(
      '  ${style.foreground(Colors.red).render('Red')} ${style.foreground(Colors.green).render('Green')} ${style.foreground(Colors.blue).render('Blue')} ${style.foreground(Colors.yellow).render('Yellow')}',
    );
    io.writeln(
      '  ${style.foreground(Colors.magenta).render('Magenta')} ${style.foreground(Colors.cyan).render('Cyan')} ${style.foreground(Colors.white).render('White')} ${style.foreground(Colors.black).render('Black (on light bg)')}',
    );
    io.newLine();

    io.section('Bright Colors');
    io.writeln(
      '  ${style.foreground(Colors.brightRed).render('Bright Red')} ${style.foreground(Colors.brightGreen).render('Bright Green')} ${style.foreground(Colors.brightBlue).render('Bright Blue')}',
    );
    io.writeln(
      '  ${style.foreground(Colors.brightYellow).render('Bright Yellow')} ${style.foreground(Colors.brightMagenta).render('Bright Magenta')} ${style.foreground(Colors.brightCyan).render('Bright Cyan')}',
    );
    io.newLine();

    io.section('Text Styles');
    io.writeln(
      '  ${style.bold().render('Bold')} ${style.dim().render('Dim')} ${style.italic().render('Italic')} ${style.underline().render('Underline')}',
    );
    io.writeln(
      '  ${style.inverse().render('Inverse')} ${style.strikethrough().render('Strikethrough')}',
    );
    io.newLine();

    io.section('Hex Colors');
    io.writeln('  ${style.foreground(BasicColor('#ff6b6b')).render('Coral')}');
    io.writeln(
      '  ${style.foreground(BasicColor('#4ecdc4')).render('Turquoise')}',
    );
    io.writeln('  ${style.foreground(BasicColor('#ffe66d')).render('Lemon')}');
    io.newLine();

    io.section('Semantic Styles');
    io.writeln(
      '  ${style.foreground(Colors.success).render('Success message')}',
    );
    io.writeln('  ${style.foreground(Colors.error).render('Error message')}');
    io.writeln(
      '  ${style.foreground(Colors.warning).render('Warning message')}',
    );
    io.writeln('  ${style.foreground(Colors.info).render('Info message')}');
    io.writeln('  ${style.foreground(Colors.muted).render('Muted message')}');
    io.writeln(
      '  ${style.bold().foreground(Colors.yellow).render('Highlighted text')}',
    );
  }
}

/// Demonstrate validators.
class UiValidatorsCommand extends Command<void> {
  UiValidatorsCommand() {
    argParser.addFlag(
      'defaults',
      negatable: false,
      help: 'Use defaults for non-interactive mode.',
    );
  }

  @override
  String get name => 'ui:validators';

  @override
  String get description => 'Demonstrate built-in input validators.';

  @override
  Future<void> run() async {
    io.title('Input Validators (powered by Acanthis)');

    io.section('Email Validator');
    try {
      final email = io.ask(
        'Enter your email',
        defaultValue: 'test@example.com',
        validator: Validators.combine([
          Validators.required(),
          Validators.email(),
        ]),
      );
      io.success('Valid email: $email');
    } catch (e) {
      io.error('Validation failed: $e');
    }

    io.section('Numeric Validator');
    try {
      final age = io.ask(
        'Enter your age',
        defaultValue: '25',
        validator: Validators.combine([
          Validators.required(),
          Validators.integer(min: 0, max: 150),
        ]),
      );
      io.success('Valid age: $age');
    } catch (e) {
      io.error('Validation failed: $e');
    }

    io.section('URL Validator');
    try {
      final url = io.ask(
        'Enter a URL',
        defaultValue: 'https://example.com',
        validator: Validators.url(),
      );
      io.success('Valid URL: $url');
    } catch (e) {
      io.error('Validation failed: $e');
    }

    io.section('UUID Validator');
    try {
      final uuid = io.ask(
        'Enter a UUID',
        defaultValue: '550e8400-e29b-41d4-a716-446655440000',
        validator: Validators.uuid(),
      );
      io.success('Valid UUID: $uuid');
    } catch (e) {
      io.error('Validation failed: $e');
    }

    io.section('Using Acanthis Schema Directly');
    io.components.comment('You can also use Acanthis schemas directly:');
    io.writeln('');
    io.writeln('  // Create schema');
    io.writeln('  final schema = string().email().min(5).max(100);');
    io.writeln('');
    io.writeln('  // Use as validator');
    io.writeln('  validator: schema.toValidator()');
    io.writeln('');
    io.writeln('  // Or parse directly');
    io.writeln('  final result = schema.tryParse(value);');
    io.writeln('  if (result.success) { ... }');
    io.newLine();

    io.section('Available Validators');
    io.components.bulletList([
      'Validators.required() - non-empty input',
      'Validators.email() - valid email format',
      'Validators.url() / uri() - valid URL/URI',
      'Validators.uuid() - valid UUID format',
      'Validators.jwt() / base64() - token formats',
      'Validators.hexColor() - hex color codes',
      'Validators.dateTime() - date-time strings',
      'Validators.numeric() / integer() - number validation',
      'Validators.positive() / negative() - sign validation',
      'Validators.between(min, max) - range validation',
      'Validators.minLength(n) / maxLength(n) - length constraints',
      'Validators.pattern(regex) - custom regex',
      'Validators.letters() / digits() / alphanumeric()',
      'Validators.uppercase() / lowercase()',
      'Validators.startsWith() / endsWith() / contains()',
      'Validators.inList(values) / notIn(values)',
      'Validators.ip() / port() - network validation',
      'Validators.identifier() - valid identifier format',
      'Validators.combine([...]) - chain validators',
      'Validators.fromSchema(acanthisSchema) - use Acanthis directly',
    ]);
  }
}

/// Demonstrate exception rendering.
class UiExceptionCommand extends Command<void> {
  @override
  String get name => 'ui:exception';

  @override
  String get description => 'Demonstrate pretty exception rendering.';

  @override
  Future<void> run() async {
    io.title('Exception Rendering');

    io.section('Simple Exception');
    try {
      throw FormatException('Invalid input format: expected JSON');
    } catch (e, stack) {
      io.components.renderException(e, stack);
    }

    io.section('Custom Exception');
    try {
      throw StateError('Cannot perform operation while loading');
    } catch (e, stack) {
      io.components.renderException(e, stack);
    }

    io.section('Using ExceptionComponent directly');
    final renderConfig = RenderConfig.fromRenderer(
      defaultRenderer,
      terminalWidth: io.terminalWidth,
    );
    try {
      throw ArgumentError.value('invalid', 'name', 'Name cannot be "invalid"');
    } catch (e, stack) {
      ExceptionComponent(
        exception: e,
        stackTrace: stack,
        maxStackFrames: 5,
        renderConfig: renderConfig,
      ).writelnTo(io);
    }
  }
}

/// Demonstrate horizontal table.
class UiHorizontalTableCommand extends Command<void> {
  @override
  String get name => 'ui:htable';

  @override
  String get description => 'Demonstrate horizontal table (row-as-headers).';

  @override
  Future<void> run() async {
    io.title('Horizontal Table');

    io.section('Application Info');
    io.components.horizontalTable({
      'Name': 'artisanal Demo',
      'Version': '1.0.0',
      'Environment': 'development',
      'Debug': 'enabled',
      'Dart SDK': dartio.Platform.version.split(' ').first,
    });

    io.section('Database Configuration');
    io.components.horizontalTable({
      'Driver': 'PostgreSQL',
      'Host': 'localhost',
      'Port': '5432',
      'Database': 'myapp_dev',
      'Username': 'postgres',
      'SSL': 'disabled',
    });

    io.section('Using HorizontalTableComponent directly');
    final renderConfig = RenderConfig.fromRenderer(
      defaultRenderer,
      terminalWidth: io.terminalWidth,
    );
    HorizontalTableComponent(
      data: {
        'Status': io.style.foreground(Colors.success).render('● Online'),
        'Uptime': '3 days, 14 hours',
        'Memory': '256 MB / 1 GB',
        'CPU': '12%',
      },
      renderConfig: renderConfig,
    ).writelnTo(io);
  }
}

/// Demonstrate password with confirmation.
class UiPasswordCommand extends Command<void> {
  UiPasswordCommand() {
    argParser.addFlag(
      'confirm',
      abbr: 'c',
      negatable: false,
      help: 'Require password confirmation.',
    );
    argParser.addFlag(
      'defaults',
      negatable: false,
      help: 'Use defaults for non-interactive mode.',
    );
  }

  @override
  String get name => 'ui:password';

  @override
  String get description => 'Demonstrate password input with confirmation.';

  @override
  Future<void> run() async {
    final confirm = argResults?['confirm'] == true;

    io.title('Password Input');
    io.text(
      confirm
          ? 'Enter a password (will be asked to confirm)'
          : 'Enter a password (no confirmation)',
    );
    io.newLine();

    final terminal = StdioTerminal(stdout: dartio.stdout, stdin: dartio.stdin);

    try {
      final password = confirm
          ? await runPasswordConfirmPrompt(
              PasswordConfirmModel(
                prompt: 'Password',
                confirmPrompt: 'Confirm password',
              ),
              terminal,
            )
          : await runPasswordPrompt(
              PasswordModel(prompt: 'Password'),
              terminal,
            );

      if (password == null) {
        io.warn('Password prompt cancelled');
        return;
      }
      io.newLine();
      io.success('Password set successfully!');
      io.twoColumnDetail('Length', '${password.length} characters');
    } catch (e) {
      io.newLine();
      io.error('$e');
    }
  }
}

/// Demonstrate styled blocks (Symfony-style).
class UiBlockCommand extends Command<void> {
  UiBlockCommand() {
    argParser.addFlag(
      'large',
      abbr: 'l',
      negatable: false,
      help: 'Show large block style.',
    );
  }

  @override
  String get name => 'ui:block';

  @override
  String get description => 'Demonstrate styled block output (Symfony-style).';

  @override
  Future<void> run() async {
    final large = argResults?['large'] == true;

    io.title('Styled Blocks');
    final renderConfig = RenderConfig.fromRenderer(
      defaultRenderer,
      terminalWidth: io.terminalWidth,
    );

    io.section('Info Block');
    StyledBlockComponent(
      message: 'This is an informational message that provides context.',
      blockStyle: BlockStyleType.info,
      large: large,
      renderConfig: renderConfig,
    ).writelnTo(io);

    io.section('Success Block');
    StyledBlockComponent(
      message:
          'Operation completed successfully!\nAll tasks finished without errors.',
      blockStyle: BlockStyleType.success,
      large: large,
      renderConfig: renderConfig,
    ).writelnTo(io);

    io.section('Warning Block');
    StyledBlockComponent(
      message: 'Please review the configuration before proceeding.',
      blockStyle: BlockStyleType.warning,
      large: large,
      renderConfig: renderConfig,
    ).writelnTo(io);

    io.section('Error Block');
    StyledBlockComponent(
      message: 'An error occurred during the operation.',
      blockStyle: BlockStyleType.error,
      large: large,
      renderConfig: renderConfig,
    ).writelnTo(io);

    io.section('Note Block');
    StyledBlockComponent(
      message: 'This is a note with additional information.',
      blockStyle: BlockStyleType.note,
      large: large,
      renderConfig: renderConfig,
    ).writelnTo(io);

    io.section('Comment Style');
    CommentComponent(
      text: [
        'This is a comment block.',
        'It displays text in a dimmed, code-comment style.',
        'Useful for showing hints or secondary information.',
      ],
      renderConfig: renderConfig,
    ).writelnTo(io);
  }
}

/// Demonstrate multi-column layout.
class UiColumnsCommand extends Command<void> {
  UiColumnsCommand() {
    argParser.addOption(
      'cols',
      abbr: 'c',
      defaultsTo: '4',
      help: 'Number of columns.',
    );
  }

  @override
  String get name => 'ui:columns';

  @override
  String get description => 'Demonstrate multi-column layout.';

  @override
  Future<void> run() async {
    final colCount = int.tryParse(argResults?['cols'] as String? ?? '4') ?? 4;

    io.title('Multi-Column Layout');
    final renderConfig = RenderConfig.fromRenderer(
      defaultRenderer,
      terminalWidth: io.terminalWidth,
    );

    io.section('Fruits ($colCount columns)');
    ColumnsComponent(
      items: [
        'Apple',
        'Banana',
        'Cherry',
        'Date',
        'Elderberry',
        'Fig',
        'Grape',
        'Honeydew',
        'Kiwi',
        'Lemon',
        'Mango',
        'Nectarine',
        'Orange',
        'Papaya',
        'Quince',
        'Raspberry',
      ],
      columnCount: colCount,
      renderConfig: renderConfig,
    ).writelnTo(io);
    io.newLine();

    io.section('Commands (auto columns)');
    ColumnsComponent(
      items: [
        'make:model',
        'make:controller',
        'make:migration',
        'make:seeder',
        'db:migrate',
        'db:seed',
        'db:rollback',
        'db:fresh',
        'serve',
        'build',
        'test',
        'lint',
        'cache:clear',
        'config:cache',
        'route:list',
        'queue:work',
      ],
      renderConfig: renderConfig,
    ).writelnTo(io);
    io.newLine();

    io.section('Status Items');
    ColumnsComponent(
      items: [
        '${io.style.foreground(Colors.success).render("●")} Online',
        '${io.style.foreground(Colors.error).render("●")} Offline',
        '${io.style.foreground(Colors.warning).render("●")} Degraded',
        '${io.style.foreground(Colors.info).render("●")} Maintenance',
        '${io.style.foreground(Colors.success).render("●")} Healthy',
        '${io.style.foreground(Colors.error).render("●")} Critical',
      ],
      columnCount: 3,
      renderConfig: renderConfig,
    ).writelnTo(io);
  }
}

/// Demonstrate terminal utilities.
class UiTerminalCommand extends Command<void> {
  @override
  String get name => 'ui:terminal';

  @override
  String get description => 'Demonstrate terminal utilities and info.';

  @override
  Future<void> run() async {
    final terminal = StdioTerminal(stdout: dartio.stdout, stdin: dartio.stdin);

    io.title('Terminal Utilities');

    io.section('Terminal Information');
    io.components.horizontalTable({
      'Width': '${terminal.width} columns',
      'Height': '${terminal.height} rows',
      'Supports ANSI': terminal.supportsAnsi ? 'Yes' : 'No',
      'Is Terminal': terminal.isTerminal ? 'Yes' : 'No',
    });

    io.section('Available Operations');
    io.components.bulletList([
      'terminal.hideCursor() / showCursor() - cursor visibility',
      'terminal.cursorUp(n) / cursorDown(n) - move cursor vertically',
      'terminal.cursorLeft(n) / cursorRight(n) - move cursor horizontally',
      'terminal.cursorTo(row, col) - absolute positioning',
      'terminal.saveCursor() / restoreCursor() - save/restore position',
      'terminal.clearScreen() - clear entire screen',
      'terminal.clearLine() - clear current line',
      'terminal.clearPreviousLines(n) - clear n lines above',
      'terminal.scrollUp(n) / scrollDown(n) - scroll viewport',
      'terminal.enterAlternateScreen() / exitAlternateScreen()',
      'terminal.bell() - ring terminal bell',
      'terminal.setTitle(title) - set terminal window title',
      'terminal.enableRawMode() - character-by-character input',
    ]);

    io.section('Key Codes');
    io.components.definitionList({
      'KeyCode.enter': '10 (\\n)',
      'KeyCode.escape': '27',
      'KeyCode.space': '32',
      'KeyCode.backspace': '127',
      'KeyCode.tab': '9',
      'KeyCode.ctrlC': '3',
      'KeyCode.arrowUp/Down/Left/Right': '65/66/67/68 (after ESC[)',
    });

    io.section('Demo: Bell');
    io.text('Ringing terminal bell...');
    terminal.bell();
    io.success('Bell rang! (you may have heard a beep)');
  }
}

/// Run all UI demos in sequence.
class UiAllCommand extends Command<void> {
  @override
  String get name => 'ui:all';

  @override
  String get description => 'Run all UI component demos in sequence.';

  @override
  Future<void> run() async {
    io.title('Complete artisanal Demo');
    io.text('This demo showcases all available UI components.');
    io.newLine();

    // Basic output
    io.section('1. Basic Output');
    io.info('Info message');
    io.success('Success message');
    io.warn('Warning message');
    io.error('Error message');
    io.note('Note message');
    io.caution('Caution message');
    io.newLine();

    // Listing
    io.section('2. Listing');
    io.listing(['First item', 'Second item', 'Third item']);

    // Two column detail
    io.section('3. Two Column Detail');
    io.twoColumnDetail('Application', 'artisanal');
    io.twoColumnDetail('Version', '1.0.0');
    io.twoColumnDetail('Environment', 'development');
    io.newLine();

    // Table
    io.section('4. Table');
    io.table(
      headers: ['ID', 'Name', 'Status'],
      rows: [
        ['1', 'users', io.style.foreground(Colors.success).render('migrated')],
        ['2', 'posts', io.style.foreground(Colors.success).render('migrated')],
        [
          '3',
          'comments',
          io.style.foreground(Colors.warning).render('pending'),
        ],
      ],
    );

    // Horizontal table
    io.section('5. Horizontal Table');
    io.components.horizontalTable({
      'Database': 'PostgreSQL',
      'Host': 'localhost',
      'Port': '5432',
    });

    // Components
    io.section('6. Components');

    io.writeln('Bullet List:');
    io.components.bulletList(['Item A', 'Item B', 'Item C']);

    io.writeln('Definition List:');
    io.components.definitionList({'Key 1': 'Value 1', 'Key 2': 'Value 2'});

    io.writeln('Rule:');
    io.components.rule('Section');

    io.writeln('Comment:');
    io.components.comment('This is a comment');
    io.newLine();

    io.writeln('Alert:');
    io.components.alert('Important alert message!');

    // Panel
    io.section('7. Panel');
    final renderConfig = RenderConfig.fromRenderer(
      defaultRenderer,
      terminalWidth: io.terminalWidth,
    );
    PanelComponent(
      content: 'This is a boxed panel with a title.',
      title: 'Panel Title',
      renderConfig: renderConfig,
    ).writelnTo(io);
    io.newLine();

    // Tree
    io.section('8. Tree');
    TreeComponent(
      data: {
        'src': {
          'lib': ['main.dart'],
          'test': ['main_test.dart'],
        },
        'pubspec.yaml': null,
      },
      renderConfig: renderConfig,
    ).writelnTo(io);
    io.newLine();

    // Columns
    io.section('9. Columns');
    ColumnsComponent(
      items: ['one', 'two', 'three', 'four', 'five', 'six'],
      columnCount: 3,
      renderConfig: renderConfig,
    ).writelnTo(io);
    io.newLine();

    // Progress bar
    io.section('10. Progress Bar');
    for (final _ in io.progressIterate(List<int>.filled(20, 0), max: 20)) {
      await Future<void>.delayed(const Duration(milliseconds: 30));
    }
    io.newLine();

    // Task
    io.section('11. Task');
    await io.task(
      'Running task',
      run: () async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return TaskResult.success;
      },
    );

    // Spin
    io.section('12. Spin Component');
    await io.components.spin(
      'Processing',
      run: () async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return null;
      },
    );
    io.newLine();

    // Colors
    io.section('13. Colors');
    final style = io.style;
    io.writeln(
      '  ${style.foreground(Colors.red).render("Red")} ${style.foreground(Colors.green).render("Green")} ${style.foreground(Colors.blue).render("Blue")} ${style.foreground(Colors.yellow).render("Yellow")}',
    );
    io.writeln(
      '  ${style.bold().render("Bold")} ${style.italic().render("Italic")} ${style.underline().render("Underline")}',
    );
    io.writeln(
      '  ${style.foreground(BasicColor("#ff6b6b")).render("Coral")} ${style.foreground(BasicColor("#4ecdc4")).render("Turquoise")} ${style.foreground(BasicColor("#ff6432")).render("Orange")}',
    );
    io.newLine();

    // Terminal info
    io.section('14. Terminal Info');
    final terminalInfo = StdioTerminal(stdout: dartio.stdout);
    io.twoColumnDetail('Size', '${terminalInfo.width}x${terminalInfo.height}');
    io.twoColumnDetail('ANSI', terminalInfo.supportsAnsi ? 'Yes' : 'No');
    io.newLine();

    // Summary
    io.section('Summary');
    io.success('All demos completed!');
    io.newLine();
    io.text('Run individual commands to see interactive demos:');
    io.components.bulletList([
      'ui:prompts - interactive prompts (confirm/ask/choice)',
      'ui:secret - password input',
      'ui:password - password with confirmation',
      'ui:select - arrow-key selection',
      'ui:multiselect - multi-select with checkboxes',
      'ui:search - searchable selection',
      'ui:search-convenience - Console.search() API',
      'ui:spinner - animated spinner',
      'ui:spinner-styles - 25+ spinner animation styles',
      'ui:pause - press any key / countdown',
      'ui:countdown - countdown timer for destructive ops',
      'ui:taskgroup - run multiple tasks with progress',
      'ui:steps - multi-step workflow with numbered steps',
      'ui:tree-convenience - Console.tree() with styles',
      'ui:validators - input validation',
      'ui:anticipate - autocomplete suggestions',
      'ui:textarea - multi-line editor input',
      'ui:wizard - multi-step wizard flow',
      'ui:link - clickable terminal links',
    ]);
  }
}

/// Demonstrate autocomplete/anticipate prompt.
class UiAnticipateCommand extends Command<void> {
  @override
  String get name => 'ui:anticipate';

  @override
  String get description => 'Demonstrate autocomplete input with suggestions.';

  @override
  Future<void> run() async {
    io.title('Autocomplete / Anticipate');
    io.text('Type to see matching suggestions. Use arrow keys to navigate.');
    io.newLine();

    final terminal = StdioTerminal(stdout: dartio.stdout, stdin: dartio.stdin);

    // Country selection
    final countries = [
      'United States',
      'United Kingdom',
      'Canada',
      'Australia',
      'Germany',
      'France',
      'Japan',
      'China',
      'India',
      'Brazil',
      'Mexico',
      'Spain',
      'Italy',
      'Netherlands',
      'Sweden',
      'Norway',
      'Denmark',
      'Finland',
      'Switzerland',
      'Austria',
    ];

    final country = await runAnticipatePrompt(
      AnticipateModel(
        prompt: 'Select your country: ',
        suggestions: countries,
        defaultValue: 'United States',
      ),
      terminal,
    );

    io.newLine();
    if (country != null) {
      io.success('Selected: $country');
    } else {
      io.warn('Selection cancelled');
    }

    io.newLine();

    // Package selection
    final packages = [
      'flutter',
      'dart',
      'http',
      'dio',
      'provider',
      'bloc',
      'riverpod',
      'get_it',
      'injectable',
      'freezed',
      'json_serializable',
      'equatable',
      'dartz',
      'rxdart',
      'stream_transform',
    ];

    final package = await runAnticipatePrompt(
      AnticipateModel(prompt: 'Select a package: ', suggestions: packages),
      terminal,
    );

    io.newLine();
    if (package != null) {
      io.success('Selected: $package');
    } else {
      io.warn('Selection cancelled');
    }
  }
}

/// Demonstrate textarea (multi-line editor input).
class UiTextareaCommand extends Command<void> {
  @override
  String get name => 'ui:textarea';

  @override
  String get description =>
      'Demonstrate multi-line text input via external editor.';

  @override
  Future<void> run() async {
    io.title('Textarea / Editor Input');
    io.text('Multi-line input bubble (Ctrl+S to submit, Esc to cancel).');
    io.newLine();

    io.section('Simple Text Input');
    try {
      final model = TextAreaModel()
        ..value = 'This is the default content.\nYou can edit it.';
      final text = await io.components.textArea(model);

      if (text != null && text.isNotEmpty) {
        io.success('Received ${text.split('\n').length} line(s):');
        io.newLine();
        for (final line in text.split('\n')) {
          io.writeln('  $line');
        }
      } else {
        io.warn('No content entered');
      }
    } catch (e) {
      io.error('Editor not available: $e');
      io.note('Set the \$EDITOR environment variable to use this feature.');
    }
  }
}

/// Demonstrate wizard (multi-step flow).
class UiWizardCommand extends Command<void> {
  UiWizardCommand() {
    argParser.addFlag(
      'non-interactive',
      abbr: 'n',
      negatable: false,
      help: 'Use defaults for all prompts.',
    );
  }

  @override
  String get name => 'ui:wizard';

  @override
  String get description => 'Demonstrate multi-step wizard flow.';

  @override
  Future<void> run() async {
    final nonInteractive = argResults?['non-interactive'] == true;

    io.title('Wizard / Multi-Step Flow');
    if (nonInteractive || !io.interactive) {
      io.note('Wizard prompt skipped in non-interactive mode.');
      return;
    }

    final terminal = StdioTerminal(stdout: dartio.stdout, stdin: dartio.stdin);
    final results = await runWizardPrompt(
      WizardModel(
        title: 'Create New Project',
        steps: [
          WizardStep.textInput(
            key: 'name',
            prompt: 'Project name',
            defaultValue: 'my_project',
            validate: (value) {
              if (value.isEmpty) return 'Name is required';
              if (!RegExp(r'^[a-z_][a-z0-9_]*$').hasMatch(value)) {
                return 'Name must be a valid Dart identifier';
              }
              return null;
            },
          ),
          WizardStep.select(
            key: 'template',
            prompt: 'Project template',
            options: ['console', 'package', 'server', 'flutter'],
            defaultIndex: 0,
          ),
          WizardStep.confirm(
            key: 'git',
            prompt: 'Initialize Git repository?',
            defaultValue: true,
          ),
          WizardStep.conditional(
            step: WizardStep.textInput(
              key: 'git_remote',
              prompt: 'Git remote URL (optional)',
            ),
            condition: (answers) => answers['git'] == true,
          ),
          WizardStep.multiSelect(
            key: 'features',
            prompt: 'Select features to include',
            options: ['Testing', 'CI/CD', 'Documentation', 'Linting', 'Docker'],
            defaultSelected: [0, 3],
          ),
          WizardStep.group(
            key: 'author',
            title: 'Author Information',
            steps: [
              WizardStep.textInput(
                key: 'author_name',
                prompt: 'Author name',
                defaultValue: 'Anonymous',
              ),
              WizardStep.textInput(key: 'author_email', prompt: 'Author email'),
            ],
          ),
        ],
      ),
      terminal,
    );

    if (results == null) {
      io.warn('Wizard cancelled');
      return;
    }

    io.section('Wizard Results');
    io.components.horizontalTable({
      'Name': results['name'],
      'Template': results['template'],
      'Git': results['git'] == true ? 'Yes' : 'No',
      'Git Remote': results['git_remote'] ?? '-',
      'Features': (results['features'] as List?)?.join(', ') ?? '-',
      'Author': results['author_name'] ?? '-',
      'Email': results['author_email'] ?? '-',
    });
  }
}

/// Demonstrate clickable terminal links.
class UiLinkCommand extends Command<void> {
  @override
  String get name => 'ui:link';

  @override
  String get description =>
      'Demonstrate clickable terminal hyperlinks (OSC 8).';

  @override
  Future<void> run() async {
    io.title('Terminal Hyperlinks (OSC 8)');
    io.text('Modern terminals support clickable links.');
    io.newLine();

    final renderConfig = RenderConfig.fromRenderer(
      defaultRenderer,
      terminalWidth: io.terminalWidth,
    );

    io.section('Link Support');
    io.twoColumnDetail(
      'OSC 8 Supported',
      LinkComponent.isSupported ? 'Yes' : 'No',
    );
    io.newLine();

    io.section('Basic Links');
    io.write('  Visit ');
    io.write(
      LinkComponent(
        url: 'https://dart.dev',
        text: 'Dart',
        renderConfig: renderConfig,
      ).render(),
    );
    io.writeln(' for more information.');

    io.write('  Check out ');
    io.write(
      LinkComponent(
        url: 'https://flutter.dev',
        text: 'Flutter',
        renderConfig: renderConfig,
      ).render(),
    );
    io.writeln(' for mobile development.');

    io.write('  Read the ');
    io.write(
      LinkComponent(
        url: 'https://pub.dev/packages/artisanal',
        text: 'artisanal docs',
        renderConfig: renderConfig,
      ).render(),
    );
    io.writeln('.');
    io.newLine();

    io.section('Styled Links');
    io.writeln(
      '  ${LinkComponent(url: 'https://github.com', text: 'GitHub (underlined & blue)', styled: true, renderConfig: renderConfig).render()}',
    );
    io.newLine();

    io.section('Using LinkComponent');
    io.writeln(
      '  ${LinkComponent(url: 'https://google.com', text: 'Google', renderConfig: renderConfig).render()}',
    );
    io.writeln(
      '  ${LinkComponent(url: 'https://dart.dev/guides', text: 'Dart Guides', styled: true, renderConfig: renderConfig).render()}',
    );
    io.newLine();

    io.section('Link Group (for footnotes)');
    final links = LinkGroupComponent(prefix: 'ref');
    io.writeln(
      '  Dart${links.add('https://dart.dev', text: '[1]')} is great for building ',
    );
    io.writeln(
      '  Flutter${links.add('https://flutter.dev', text: '[2]')} apps.',
    );
    io.newLine();
    io.writeln('  References:');
    links.writelnTo(io);
    io.newLine();

    io.note('Links may not be clickable in all terminals.');
    io.text('Supported: iTerm2, Windows Terminal, VS Code, Hyper, WezTerm');
  }
}

/// Demonstrate the new component system.
class UiComponentSystemCommand extends Command<void> {
  @override
  String get name => 'ui:system';

  @override
  String get description =>
      'Demonstrate the structured component system (Flutter-like).';

  @override
  Future<void> run() async {
    final renderConfig = RenderConfig.fromRenderer(
      defaultRenderer,
      terminalWidth: io.terminalWidth,
    );

    io.title('Component System Demo');
    io.text('A structured way to build CLI UIs, similar to Flutter widgets.');
    io.newLine();

    // ─────────────────────────────────────────────────────────────────────────
    io.section('Static Components');

    // Text components
    io.writeln('Text components:');
    bubbles.Text('  Plain text').writelnTo(io);
    StyledText.info(
      '  Info styled text',
      renderConfig: renderConfig,
    ).writelnTo(io);
    StyledText.success(
      '  Success styled text',
      renderConfig: renderConfig,
    ).writelnTo(io);
    StyledText.warning(
      '  Warning styled text',
      renderConfig: renderConfig,
    ).writelnTo(io);
    StyledText.error(
      '  Error styled text',
      renderConfig: renderConfig,
    ).writelnTo(io);
    io.newLine();

    // Rule component
    io.writeln('Rule component:');
    Rule(renderConfig: renderConfig).writelnTo(io);
    Rule(text: 'Section', renderConfig: renderConfig).writelnTo(io);
    io.newLine();

    // Lists
    io.writeln('List components:');
    BulletList(
      items: ['Apple', 'Banana', 'Cherry'],
      renderConfig: renderConfig,
    ).writelnTo(io);
    io.newLine();
    NumberedList(
      items: ['First', 'Second', 'Third'],
      renderConfig: renderConfig,
    ).writelnTo(io);
    io.newLine();

    // Key-value
    io.writeln('KeyValue component:');
    KeyValue(
      key: 'Name',
      value: 'artisanal',
      renderConfig: renderConfig,
    ).writelnTo(io);
    KeyValue(
      key: 'Version',
      value: '1.0.0',
      renderConfig: renderConfig,
    ).writelnTo(io);
    KeyValue(
      key: 'Author',
      value: 'You',
      renderConfig: renderConfig,
    ).writelnTo(io);
    io.newLine();

    // Box
    io.writeln('Box component:');
    Box(
      content: 'This is a boxed message.\nIt can have multiple lines.',
      title: 'Notice',
      borderStyle: BorderStyle.rounded,
      renderConfig: renderConfig,
    ).writelnTo(io);
    io.newLine();

    // Progress bar
    io.writeln('ProgressBar component:');
    ProgressBar(current: 7, total: 10).writelnTo(io);
    ProgressBar(
      current: 3,
      total: 10,
      fillChar: '▓',
      emptyChar: '░',
    ).writelnTo(io);
    io.newLine();

    // ─────────────────────────────────────────────────────────────────────────
    io.section('Composition');

    io.writeln('Components can be composed together:');
    io.newLine();

    ColumnComponent(
      children: [
        StyledText.heading('  My Application', renderConfig: renderConfig),
        Rule(char: '─', renderConfig: renderConfig),
        BulletList(
          items: ['Feature 1: Fast', 'Feature 2: Easy', 'Feature 3: Beautiful'],
          indent: 4,
          renderConfig: renderConfig,
        ),
      ],
    ).writelnTo(io);
    io.newLine();

    // Row composition
    io.writeln('Row composition:');
    RowComponent(
      children: [
        StyledText.success('✓ Pass', renderConfig: renderConfig),
        bubbles.Text(' | '),
        StyledText.error('✗ Fail', renderConfig: renderConfig),
        bubbles.Text(' | '),
        StyledText.warning('⚠ Warn', renderConfig: renderConfig),
      ],
    ).writelnTo(io);
    io.newLine();

    // ─────────────────────────────────────────────────────────────────────────
    io.section('Output Components');

    io.writeln('PanelComponent:');
    PanelComponent(
      content:
          'This is a panel using the component system.\nIt supports titles and alignment.',
      title: 'Panel Demo',
      renderConfig: renderConfig,
    ).writelnTo(io);
    io.newLine();

    io.writeln('TaskComponent:');
    TaskComponent(
      description: 'Compiling assets',
      status: TaskStatus.success,
      renderConfig: renderConfig,
    ).writelnTo(io);
    TaskComponent(
      description: 'Running tests',
      status: TaskStatus.failure,
      renderConfig: renderConfig,
    ).writelnTo(io);
    TaskComponent(
      description: 'Deploying',
      status: TaskStatus.skipped,
      renderConfig: renderConfig,
    ).writelnTo(io);
    io.newLine();

    io.writeln('AlertComponent:');
    AlertComponent(
      message: 'This is informational',
      type: AlertType.info,
      renderConfig: renderConfig,
    ).writelnTo(io);
    AlertComponent(
      message: 'Operation succeeded',
      type: AlertType.success,
      renderConfig: renderConfig,
    ).writelnTo(io);
    AlertComponent(
      message: 'Be careful!',
      type: AlertType.warning,
      renderConfig: renderConfig,
    ).writelnTo(io);
    AlertComponent(
      message: 'Something went wrong',
      type: AlertType.error,
      renderConfig: renderConfig,
    ).writelnTo(io);
    io.newLine();

    io.writeln('TwoColumnDetailComponent:');
    TwoColumnDetailComponent(
      left: 'Name',
      right: 'artisanal',
      renderConfig: renderConfig,
    ).writelnTo(io);
    TwoColumnDetailComponent(
      left: 'Version',
      right: '1.0.0',
      renderConfig: renderConfig,
    ).writelnTo(io);
    TwoColumnDetailComponent(
      left: 'Status',
      right: 'Active',
      renderConfig: renderConfig,
    ).writelnTo(io);
    io.newLine();

    io.writeln('TreeComponent:');
    TreeComponent(
      data: {
        'src': {
          'lib': ['main.dart', 'utils.dart'],
          'test': ['main_test.dart'],
        },
        'pubspec.yaml': null,
        'README.md': null,
      },
      renderConfig: renderConfig,
    ).writelnTo(io);
    io.newLine();

    io.writeln('ColumnsComponent:');
    ColumnsComponent(
      items: [
        'apple',
        'banana',
        'cherry',
        'date',
        'elderberry',
        'fig',
        'grape',
        'honeydew',
      ],
      columnCount: 4,
      renderConfig: renderConfig,
    ).writelnTo(io);
    io.newLine();

    // ─────────────────────────────────────────────────────────────────────────
    io.section('Interactive Components');

    io.text('Interactive components return values from user input.');
    io.newLine();

    io.writeln('Available interactive components:');
    io.components.bulletList([
      'TextInput - text input with validation',
      'Confirm - yes/no confirmation',
      'SecretInputComponent - password input',
      'Select<T> - single select with arrow keys',
      'MultiSelect<T> - multi select with arrow keys',
      'SpinnerComponent - async progress spinner',
    ]);
    io.newLine();

    // Demo interactive components
    io.writeln('Demo: Select prompt');
    final terminal = StdioTerminal(stdout: dartio.stdout, stdin: dartio.stdin);
    final color = await runSelectPrompt<String>(
      SelectModel<String>(
        items: ['Red', 'Green', 'Blue', 'Yellow'],
        title: 'Pick your favorite color',
      ),
      terminal,
    );
    if (color != null) io.success('You selected: $color');
    io.newLine();

    // ─────────────────────────────────────────────────────────────────────────
    io.section('Custom Components');

    io.text('Create custom components by extending DisplayComponent:');
    io.newLine();

    io.writeln('''
    class MyBanner extends DisplayComponent {
      final String title;
      MyBanner(this.title);

      @override
      String render() => Style().bold().foreground(Colors.yellow).render('★ \$title ★');
    }
    ''');

    // Demo custom component
    _CustomBanner('artisanal', renderConfig: renderConfig).writelnTo(io);
  }
}

/// Example custom component.
class _CustomBanner extends DisplayComponent {
  const _CustomBanner(this.title, {this.renderConfig = const RenderConfig()});

  final String title;
  final RenderConfig renderConfig;

  @override
  String render() {
    final stars = '★ ' * 3;
    final style = renderConfig.configureStyle(Style());
    return style.bold().foreground(Colors.yellow).render('$stars$title$stars');
  }
}
