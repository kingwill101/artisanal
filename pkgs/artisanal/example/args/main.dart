// ignore_for_file: depend_on_referenced_packages
// #region imports
import 'dart:io' as dartio;

import 'package:artisanal/artisanal.dart';
import 'package:artisanal/args.dart';

// #endregion

// =============================================================================
// args Demo — all artisanal package:args improvements
// =============================================================================
//
// Run:  dart run example/args/main.dart --ansi <command>
//
// The --ansi flag forces styled output for documentation purposes.
//
// This example demonstrates every improvement artisanal adds on top of
// package:args.  Each section is clearly labelled so you can see the
// feature in action.
// =============================================================================

Future<void> main(List<String> args) async {
  // ── CommandRunner with namespaceSeparator (default `:`) ──────────────
  final runner = CommandRunner<void>(
    CommandRunner.detectExecutableName(),
    'Demonstrates all artisanal improvements to package:args.',
    namespaceSeparator: ':',
    usageExitCode: 64,

    // Customize help colors at construction time.
    helpColorScheme: HelpColorScheme.default_,

    // Enable shell completion automatically.
    enableShellCompletion: true,

    // Fallback for unknown top-level commands (shim-style).
    unknownCommandFallback: _shimFallback,
  );

  // ── Register commands ───────────────────────────────────────────────
  runner
    ..addCommand(HelloCommand())
    ..addCommand(HelpThemeCommand())
    ..addCommand(VerbosityDemoCommand())
    ..addCommand(NonInteractiveCommand())
    // Namespaced commands — grouped under `db` in help output.
    ..addCommand(DbListCommand())
    ..addCommand(DbSeedCommand())
    ..addCommand(DbMigrateCommand())
    ..addCommand(DbRollbackCommand())
    // Nested namespaces — grouped under `cache` and `cache:user`.
    ..addCommand(CacheClearCommand())
    ..addCommand(CacheWarmCommand())
    ..addCommand(CacheUserListCommand())
    ..addCommand(CacheUserEvictCommand())
    // Subcommand hierarchy — project:create, project:deploy, etc.
    ..addCommand(ProjectCreateCommand())
    ..addCommand(ProjectDeployCommand())
    ..addCommand(ProjectDestroyCommand())
    // Shell completion example.
    ..addCommand(CompletionDemoCommand());

  await runner.run(args);
}

// =============================================================================
// Feature 1 — Basic Command
// =============================================================================
//
// A classic "hello" command that shows argParser usage, Console integration
// (io.info, io.success, etc.), and verbosity-aware output.
//
//   dart run example/args/main.dart hello
//   dart run example/args/main.dart hello --name Alice --times 3 --formal
//
// #region hello_command
class HelloCommand extends Command<void> {
  HelloCommand() {
    // ── Flags ────────────────────────────────────────────────────────
    argParser.addFlag(
      'formal',
      negatable: false,
      help: 'Use a formal greeting.',
    );
    argParser.addFlag('shout', negatable: false, help: 'SHOUT the greeting.');

    // ── Options ──────────────────────────────────────────────────────
    argParser.addOption(
      'name',
      abbr: 'n',
      defaultsTo: 'World',
      help: 'Who to greet.',
    );
    argParser.addOption(
      'times',
      abbr: 't',
      defaultsTo: '1',
      help: 'Number of times to repeat.',
    );

    // Note: positional arguments are available via argResults!.rest.
    // See run() for usage.
  }

  @override
  String get name => 'hello';

  @override
  String get description =>
      'Say hello — demonstrates flags, options, and Console output.';

  @override
  String get summary => 'Greet someone with a configurable message.';

  @override
  Future<void> run() async {
    final name = option('name') as String? ?? 'World';
    final times = int.tryParse(option('times') as String? ?? '1') ?? 1;
    final formal = option('formal') as bool;
    final shout = option('shout') as bool;
    final message = argument(0);

    // ── Console integration: io helpers ──────────────────────────────
    io.title('Hello Command');

    if (times > 3) {
      io.warn('That is a lot of repetitions ($times)!');
    }

    for (var i = 0; i < times; i++) {
      String? greeting;
      if (message != null) {
        greeting = message;
      } else if (formal) {
        greeting = 'Greetings, $name.';
      } else {
        greeting = 'Hello, $name!';
      }
      if (shout) {
        greeting = greeting.toUpperCase();
      }
      io.line(greeting);
    }

    io.newLine();
    io.success('Done!');

    // Verbosity-aware output (try with --verbose / -v):
    io.verbose('Verbose: repeated $times time(s)');
    io.debug('Debug: args=${argResults!.arguments}');
  }
}
// #endregion

// =============================================================================
// Feature 2 — Subcommands (nested hierarchy)
// =============================================================================
//
// Demonstrates subcommand nesting using Command's addSubcommand.
//
//   dart run example/args/main.dart project:create MyApp
//   dart run example/args/main.dart project:deploy MyApp --env staging
//
// #region subcommands
class ProjectCreateCommand extends Command<void> {
  ProjectCreateCommand() {
    argParser.addOption(
      'template',
      abbr: 't',
      defaultsTo: 'default',
      help: 'Project template to use.',
    );
    // Project name is accessed from argResults!.rest (positional args).
  }

  @override
  String get name => 'project:create';

  @override
  String get description => 'Create a new project.';

  @override
  String get summary => 'Scaffold a new project from a template.';

  @override
  Future<void> run() async {
    final name = argument(0) ?? 'unnamed';
    final template = option('template') as String? ?? 'default';

    io.title('Project: Create');
    io.info('Creating project "$name" from template "$template"...');
    await Future.delayed(const Duration(milliseconds: 200));
    io.success('Project "$name" created.');
  }
}

class ProjectDeployCommand extends Command<void> {
  ProjectDeployCommand() {
    argParser.addOption(
      'env',
      abbr: 'e',
      defaultsTo: 'production',
      help: 'Deployment environment.',
      allowed: ['production', 'staging', 'development'],
      allowedHelp: {
        'production': 'Live environment',
        'staging': 'Pre-production',
        'development': 'Local dev',
      },
    );
    argParser.addFlag('force', help: 'Skip confirmation prompts.');
  }

  @override
  String get name => 'project:deploy';

  @override
  String get description => 'Deploy a project.';

  @override
  String get summary => 'Deploy an existing project to an environment.';

  @override
  Future<void> run() async {
    final env = option('env') as String? ?? 'production';
    final force = option('force') as bool;

    io.title('Project: Deploy');
    io.info('Deploying to "$env"...');
    if (!force) {
      io.warn('Use --force to skip confirmation.');
    }
    await Future.delayed(const Duration(milliseconds: 300));
    io.success('Deployed to $env.');
  }
}

class ProjectDestroyCommand extends Command<void> {
  ProjectDestroyCommand() {
    argParser.addFlag('force', abbr: 'f', help: 'Skip destruction warning.');
  }

  @override
  String get name => 'project:destroy';

  @override
  String get description => 'Destroy a project (destructive!).';

  @override
  String get summary => 'Permanently destroy a project.';

  @override
  Future<void> run() async {
    io.title('Project: Destroy');
    io.error('This will permanently destroy the project!');
    io.warn('Run with --force to proceed.');
  }
}
// #endregion

// =============================================================================
// Feature 3 — Namespace grouping & discovery
// =============================================================================
//
// Commands named `db:*` are automatically grouped under `db` in help output.
//
// Typing just `db` shows the available subcommands instead of an error
// (Symfony Console behavior):
//
//   dart run example/args/main.dart db
//
// Try it with nested namespaces too:
//
//   dart run example/args/main.dart cache:user
//
// #region namespaces
class DbListCommand extends Command<void> {
  @override
  String get name => 'db:list';

  @override
  String get description => 'List all database tables.';

  @override
  String get summary => 'Display all tables in the database.';

  @override
  Future<void> run() async {
    io.title('Database Tables');
    io.table(
      headers: ['Table', 'Rows', 'Engine'],
      rows: [
        ['users', '42', 'InnoDB'],
        ['posts', '128', 'InnoDB'],
        ['comments', '512', 'InnoDB'],
      ],
    );
  }
}

class DbSeedCommand extends Command<void> {
  DbSeedCommand() {
    argParser.addOption(
      'count',
      abbr: 'c',
      defaultsTo: '100',
      help: 'Number of records to seed.',
    );
  }

  @override
  String get name => 'db:seed';

  @override
  String get description => 'Seed the database with sample data.';

  @override
  String get summary => 'Insert sample records into the database.';

  @override
  Future<void> run() async {
    final count = option('count') as String? ?? '100';
    io.title('Database: Seed');
    io.info('Seeding $count records...');
    await Future.delayed(const Duration(milliseconds: 150));
    io.success('Seeded $count records.');
  }
}

class DbMigrateCommand extends Command<void> {
  DbMigrateCommand() {
    argParser.addFlag('fresh', help: 'Drop all tables before migrating.');
  }

  @override
  String get name => 'db:migrate';

  @override
  String get description => 'Run database migrations.';

  @override
  String get summary => 'Apply pending database migrations.';

  @override
  Future<void> run() async {
    final fresh = option('fresh') as bool;
    io.title('Database: Migrate');
    if (fresh) {
      io.warn('Fresh migration — dropping all tables first...');
    }
    io.info('Running migrations...');
    await Future.delayed(const Duration(milliseconds: 200));
    io.success('Migrations complete.');
  }
}

class DbRollbackCommand extends Command<void> {
  DbRollbackCommand() {
    argParser.addOption(
      'steps',
      abbr: 's',
      defaultsTo: '1',
      help: 'Number of steps to roll back.',
    );
  }

  @override
  String get name => 'db:rollback';

  @override
  String get description => 'Roll back database migrations.';

  @override
  String get summary => 'Revert the last batch of migrations.';

  @override
  Future<void> run() async {
    final steps = option('steps') as String? ?? '1';
    io.title('Database: Rollback');
    io.info('Rolling back $steps step(s)...');
    await Future.delayed(const Duration(milliseconds: 150));
    io.success('Rolled back $steps migration(s).');
  }
}

// Nested namespace: cache:user:*
class CacheUserListCommand extends Command<void> {
  @override
  String get name => 'cache:user:list';

  @override
  String get description => 'List cached users.';

  @override
  String get summary => 'Show all user keys in the cache.';

  @override
  Future<void> run() async {
    io.title('Cached Users');
    io.table(
      headers: ['Key', 'TTL'],
      rows: [
        ['user:1', '3600s'],
        ['user:42', '1800s'],
      ],
    );
  }
}

class CacheUserEvictCommand extends Command<void> {
  CacheUserEvictCommand() {
    argParser.addOption('id', help: 'User ID to evict.');
  }

  @override
  String get name => 'cache:user:evict';

  @override
  String get description => 'Evict a user from cache.';

  @override
  String get summary => 'Remove a specific user from the cache.';

  @override
  Future<void> run() async {
    final id = option('id') as String?;
    io.title('Cache: Evict User');
    if (id != null) {
      io.info('Evicting user:$id...');
    } else {
      io.info('Evicting all cached users...');
    }
    await Future.delayed(const Duration(milliseconds: 100));
    io.success('Evicted.');
  }
}

class CacheClearCommand extends Command<void> {
  @override
  String get name => 'cache:clear';

  @override
  String get description => 'Clear the entire cache.';

  @override
  String get summary => 'Flush all cached data.';

  @override
  Future<void> run() async {
    io.title('Cache: Clear');
    io.warn('Clearing entire cache...');
    await Future.delayed(const Duration(milliseconds: 200));
    io.success('Cache cleared.');
  }
}

class CacheWarmCommand extends Command<void> {
  CacheWarmCommand() {
    argParser.addMultiOption(
      'keys',
      abbr: 'k',
      help: 'Keys to warm (repeatable).',
    );
  }

  @override
  String get name => 'cache:warm';

  @override
  String get description => 'Warm the cache with specific keys.';

  @override
  String get summary => 'Pre-populate cache entries.';

  @override
  Future<void> run() async {
    final keys = option('keys') as List<String>? ?? [];
    io.title('Cache: Warm');
    if (keys.isEmpty) {
      io.info('Warming common keys...');
    } else {
      io.info('Warming keys: ${keys.join(', ')}');
    }
    await Future.delayed(const Duration(milliseconds: 200));
    io.success('Cache warmed.');
  }
}
// #endregion

// =============================================================================
// Feature 4 — Custom HelpColorScheme
// =============================================================================
//
// Demonstrates applying different HelpColorScheme presets at runtime.
//
//   dart run example/args/main.dart --ansi --help-color dark
//   dart run example/args/main.dart --ansi --help-color light
//   dart run example/args/main.dart --ansi --help-color cyberpunk
//
// #region help_theme_command
class HelpThemeCommand extends Command<void> {
  HelpThemeCommand() {
    argParser.addOption(
      'help-color',
      help: 'Color scheme: default, dark, light, minimal, cyberpunk.',
      defaultsTo: 'default',
    );
  }

  @override
  String get name => 'help:theme';

  @override
  String get description => 'Change help color scheme and show usage.';

  @override
  String get summary => 'Demonstrate HelpColorScheme presets.';

  @override
  Future<void> run() async {
    final theme = option('help-color') as String? ?? 'default';

    // Apply the chosen scheme to the runner.
    // ignore: avoid_dynamic_calls
    final r = runner as dynamic;
    r.helpColorScheme = _resolveScheme(theme);

    io.title('Help Theme: $theme');
    io.info('The help output now uses the "$theme" color scheme.');
    io.newLine();
    io.line('Run with --ansi to see colors:');
    io.line(
      '  dart run example/args/main.dart --ansi help:theme --help-color dark',
    );
    io.newLine();

    // Print usage with the new scheme.
    r.printUsage();
  }

  static HelpColorScheme _resolveScheme(String name) {
    return switch (name) {
      'dark' => HelpColorScheme.dark(),
      'light' => HelpColorScheme.light(),
      'minimal' => HelpColorScheme.minimal(BasicColor('#00ff00')),
      'cyberpunk' => const HelpColorScheme(
        heading: AdaptiveColor(
          light: BasicColor('#ff00ff'),
          dark: BasicColor('#ff00ff'),
        ),
        command: AdaptiveColor(
          light: BasicColor('#00ffff'),
          dark: BasicColor('#00ffff'),
        ),
        option: AdaptiveColor(
          light: BasicColor('#ffff00'),
          dark: BasicColor('#ffff00'),
        ),
        namespace: AdaptiveColor(
          light: BasicColor('#ff00ff'),
          dark: BasicColor('#ff00ff'),
        ),
        error: AdaptiveColor(
          light: BasicColor('#ff0000'),
          dark: BasicColor('#ff4444'),
        ),
      ),
      _ => HelpColorScheme.default_,
    };
  }
}
// #endregion

// =============================================================================
// Feature 5 — Verbosity (global --quiet, --verbose / -v, -vv, -vvv)
// =============================================================================
//
//   dart run example/args/main.dart verbosity
//   dart run example/args/main.dart verbosity -q
//   dart run example/args/main.dart verbosity -v
//   dart run example/args/main.dart verbosity -vv
//   dart run example/args/main.dart verbosity -vvv
//
// #region verbosity_demo
class VerbosityDemoCommand extends Command<void> {
  @override
  String get name => 'verbosity';

  @override
  String get description => 'Demonstrate global verbosity levels.';

  @override
  String get summary =>
      'Show how --quiet, --verbose / -v, -vv, -vvv affect output.';

  @override
  Future<void> run() async {
    io.title('Verbosity Demo');

    io.line('This always shows (normal verbosity).');
    io.info('This shows in normal/verbose/debug.');
    io.verbose('This shows only in VERBOSE or DEBUG.');
    io.debug('This shows only in DEBUG (-vvv).');

    io.newLine();
    io.success(
      'Verbosity level: ${runner is CommandRunner<void> ? (runner as CommandRunner<void>).verbosity : "unknown"}',
    );
  }
}
// #endregion

// =============================================================================
// Feature 6 — Non-interactive mode (--no-interaction / -n)
// =============================================================================
//
//   dart run example/args/main.dart non-interactive
//   dart run example/args/main.dart non-interactive -n
//
// #region non_interactive
class NonInteractiveCommand extends Command<void> {
  NonInteractiveCommand() {
    argParser.addFlag('confirm', help: 'Skip the prompt (simulates -n).');
  }

  @override
  String get name => 'non-interactive';

  @override
  String get description => 'Demonstrate --no-interaction.';

  @override
  String get summary => 'Show how --no-interaction / -n skips prompts.';

  @override
  Future<void> run() async {
    io.title('Non-Interactive Demo');

    final interactive =
        hasOption('confirm') ||
        (runner is CommandRunner<void>
            ? (runner as CommandRunner<void>).interactive
            : true);

    io.info('Interactive mode: $interactive');

    if (interactive) {
      final name = io.ask('What is your name?', defaultValue: 'Guest');
      io.success('Hello, $name!');
    } else {
      io.warn('Skipping interactive prompt (--no-interaction).');
      io.info('Use --no-interaction (or -n) to skip prompts.');
    }
  }
}
// #endregion

// =============================================================================
// Feature 7 — Shell completion (--completion-script)
// =============================================================================
//
//   dart run example/args/main.dart --completion-script
//
// #region shell_completion
class CompletionDemoCommand extends Command<void> {
  @override
  String get name => 'completion:demo';

  @override
  String get description => 'Demonstrate shell completion feature.';

  @override
  String get summary => 'Print info about shell tab-completion.';

  @override
  Future<void> run() async {
    io.title('Shell Completion');
    io.info('Built-in shell completion is enabled by default.');
    io.newLine();
    io.line('Generate a completion script:');
    io.line('  dart run example/args/main.dart --completion-script');
    io.newLine();
    io.line('Or pipe it directly into your shell config:');
    io.line(
      '  dart run example/args/main.dart --completion-script >> ~/.bashrc',
    );
    io.newLine();
    io.info('This is powered by the completion package via ShellCompleter.');
  }
}
// #endregion

// =============================================================================
// Feature 8 — UnknownCommandFallback (shim-style delegation)
// =============================================================================
//
// When no top-level command matches, the fallback runs.
// This is useful for wrappers that delegate to another binary.
//
// Registered at the top of main(): unknownCommandFallback: _shimFallback
//
// #region shim_fallback
Future<void> _shimFallback(List<String> args) async {
  final first = args.first;
  // Outside a Command context, so write directly to stdout.
  dartio.stdout.writeln('=== Shim Fallback ===');
  dartio.stdout.writeln('! No command named "$first" found.');
  dartio.stdout.writeln('');
  dartio.stdout.writeln(
    'This UnknownCommandFallback could delegate to another executable:',
  );
  dartio.stdout.writeln('  Process.run("$first", ${args.skip(1).toList()})');
  dartio.stdout.writeln('');
  dartio.stdout.writeln('Registered commands are:');
  dartio.stdout.writeln(
    '  hello, project:create, project:deploy, project:destroy,',
  );
  dartio.stdout.writeln('  db:list, db:seed, db:migrate, db:rollback,');
  dartio.stdout.writeln(
    '  cache:clear, cache:warm, cache:user:list, cache:user:evict,',
  );
  dartio.stdout.writeln(
    '  help:theme, verbosity, non-interactive, completion:demo',
  );
}

// #endregion
