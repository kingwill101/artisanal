/// Command-line argument parsing and command runners for Artisanal.
///
/// This library provides [CommandRunner] and [Command] which extend
/// `package:args` to provide a polished CLI experience with:
/// - Automatic help generation with Lip Gloss styling.
/// - Support for subcommands and nested command structures.
/// - Integration with [Console] for verbosity-aware output.
/// - Custom usage formatting and command listing.
/// - Automatic shell tab-completion with `--completion-script` flag (enabled by default, opt-out available).
///
/// {@category Core}
///
/// ## Command Runner
///
/// {@macro artisanal_args_overview}
///
/// ## Defining Commands
///
/// {@macro artisanal_args_commands}
///
/// ## Usage
///
/// ```dart
/// import 'package:artisanal/args.dart';
///
/// class MyCommand extends Command {
///   @override
///   String get name => 'hello';
///   @override
///   String get description => 'Say hello';
///
///   @override
///   void run() {
///     print('Hello, world!');
///   }
/// }
///
/// void main(List<String> args) {
///   final runner = CommandRunner('my-cli', 'A great CLI');
///   runner.addCommand(MyCommand());
///   runner.run(args);
/// }
/// ```
///
/// {@template artisanal_args_overview}
/// The [CommandRunner] orchestrates the execution of commands and subcommands.
/// It handles argument parsing, help generation, and error reporting.
///
/// Artisanal's runner is fully integrated with the [Style] system, providing
/// beautiful, readable help output by default.
/// {@endtemplate}
///
/// {@template artisanal_args_commands}
/// [Command]s are the building blocks of your CLI. Each command has a name,
/// description, and an optional set of arguments and subcommands.
///
/// Override the `run()` method to implement the command's logic. You can
/// access the [Console] via the `io` property for styled output.
///
/// Access parsed arguments with Laravel-style helpers:
///
/// ```dart
/// class GreetCommand extends Command<void> {
///   @override
///   String get name => 'greet';
///
///   @override
///   String get description => 'Greet someone.';
///
///   GreetCommand() {
///     argParser.addOption('name', abbr: 'n', help: 'Who to greet.');
///     argParser.addFlag('shout', help: 'SHOUT the greeting.');
///   }
///
///   @override
///   void run() {
///     final name = option('name') as String? ?? 'World';
///     final shout = option('shout') as bool;
///     final message = argument(0); // first positional arg
///     io.success('Hello, $name!');
///   }
/// }
/// ```
///
/// See [Command.option], [Command.argument], [Command.hasOption],
/// [Command.arguments], and [Command.argumentCount].
/// {@endtemplate}
library;

export 'src/runner/runner.dart'
    show
        Command,
        CommandListingEntry,
        formatCommandListing,
        indentBlock,
        CommandRunner,
        ShellCompleter,
        UnknownCommandFallback,
        ArgParser,
        ArgParserException,
        ArgResults,
        UsageException;
export 'src/runner/help_color_scheme.dart' show HelpColorScheme;
