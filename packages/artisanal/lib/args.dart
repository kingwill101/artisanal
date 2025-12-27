/// Command-line argument parsing and command runners for Artisanal.
///
/// This library provides [CommandRunner] and [Command] which extend
/// `package:args` to provide a polished CLI experience with:
/// - Automatic help generation with Lip Gloss styling.
/// - Support for subcommands and nested command structures.
/// - Integration with [Console] for verbosity-aware output.
/// - Custom usage formatting and command listing.
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
/// access the [Console] via the `console` property if the command is run
/// through an Artisanal runner.
/// {@endtemplate}
library artisanal.args;

export 'src/runner/command.dart' show Command;
export 'src/runner/command_listing.dart'
    show CommandListingEntry, formatCommandListing, indentBlock;
export 'src/runner/command_runner.dart'
    show CommandRunner, ArgParser, ArgParserException, ArgResults;
