import 'dart:io' as dartio;

import 'package:args/command_runner.dart' as args;

import '../io/console.dart';
import '../renderer/renderer.dart';
import '../style/verbosity.dart';
import 'command_listing.dart';
import 'command_runner.dart';
import 'help_color_scheme.dart';

/// Base command class for Artisanal-style CLI commands.
///
/// Provides access to the [io] helper for console output and
/// renders help with proper section formatting.
///
/// {@category Core}
///
/// {@macro artisanal_args_commands}
///
/// ```dart
/// class ServeCommand extends Command<void> {
///   @override
///   String get name => 'serve';
///
///   @override
///   String get description => 'Start the development server.';
///
///   @override
///   Future<void> run() async {
///     io.title('Starting server...');
///     // ...
///   }
/// }
/// ```
abstract class Command<T> extends args.Command<T> {
  /// Creates a new command with optional aliases.
  Command({List<String> aliases = const []}) : _aliases = aliases;

  final List<String> _aliases;

  /// Alternative names for this command.
  @override
  List<String> get aliases => _aliases;

  /// Access to the I/O helper for console output.
  ///
  /// Use this to output formatted messages, tables, progress bars, etc.
  Console get io {
    final r = runner;
    if (r is CommandRunner<T>) {
      return r.io;
    }
    return Console(
      renderer: StringRenderer(colorProfile: ColorProfile.ascii),
      out: dartio.stdout.writeln,
      err: dartio.stderr.writeln,
    );
  }

  /// Writes a plain line to output (Laravel-style).
  void line(Object message, {String? style, Verbosity? verbosity}) =>
      io.line(message, style: style, verbosity: verbosity);

  /// Writes an info message (Laravel-style).
  void info(Object message, {Verbosity? verbosity}) =>
      io.info(message, verbosity: verbosity);

  /// Writes a comment message (Laravel-style).
  void comment(Object message, {Verbosity? verbosity}) =>
      io.comment(message, verbosity: verbosity);

  /// Writes a question message (Laravel-style).
  void question(Object message, {Verbosity? verbosity}) =>
      io.question(message, verbosity: verbosity);

  /// Writes a warning message (Laravel-style).
  void warn(Object message, {Verbosity? verbosity}) =>
      io.warn(message, verbosity: verbosity);

  /// Writes an error message (Laravel-style).
  void error(Object message, {Verbosity? verbosity}) =>
      io.error(message, verbosity: verbosity);

  /// Writes an alert box (Laravel-style).
  void alert(Object message, {Verbosity? verbosity}) =>
      io.alert(message, verbosity: verbosity);

  // ── Argument / Option accessors (Laravel-style) ──────────────────────

  /// Returns the value of a named option (e.g., `--name`, `--force`).
  ///
  /// Sugar over `argResults![name]`.  Use the `as` cast or `??` default to
  /// get a typed value:
  ///
  /// ```dart
  /// final name = option('name') as String? ?? 'World';
  /// final force = option('force') as bool;
  /// ```
  Object? option(String name) => argResults![name];

  /// Returns `true` if [name] was explicitly provided on the command line.
  bool hasOption(String name) => argResults!.wasParsed(name);

  /// Returns the positional argument at [index] (0-based), or `null` if
  /// fewer positional arguments were provided.
  ///
  /// ```dart
  /// final name = argument(0) ?? 'default';
  /// ```
  String? argument(int index) {
    final args = argResults!.rest;
    return index < args.length ? args[index] : null;
  }

  /// All positional arguments passed to this command.
  List<String> get arguments => argResults!.rest;

  /// Number of positional arguments.
  int get argumentCount => arguments.length;

  /// Separator used to group subcommands for display.
  ///
  /// Defaults to `:` (matching Artisanal-style namespaces).
  String get namespaceSeparator {
    final r = runner;
    if (r is CommandRunner<T>) {
      return r.namespaceSeparator;
    }
    return ':';
  }

  /// Prints the command usage information.
  @override
  void printUsage() {
    final r = runner;
    if (r is CommandRunner<T>) {
      r.writeOut(formatUsage());
      return;
    }
    dartio.stdout.writeln(formatUsage());
  }

  /// Throws a usage error with the given message.
  @override
  Never usageException(String message) =>
      throw args.UsageException(message, formatUsage(includeDescription: true));

  /// Formats help output for this command.
  String formatUsage({bool includeDescription = true}) {
    final buffer = StringBuffer();
    final Renderer renderer = runner is CommandRunner<T>
        ? (runner as CommandRunner<T>).renderer
        : StringRenderer(colorProfile: ColorProfile.ascii);
    final HelpColorScheme scheme = runner is CommandRunner<T>
        ? (runner as CommandRunner<T>).helpColorScheme
        : HelpColorScheme.default_;

    String heading(String text) => scheme.headingStyle(renderer)(text);
    String command(String text) => scheme.commandStyle(renderer)(text);
    String option(String text) => scheme.optionStyle(renderer)(text);

    String formatOptionsUsage(String usage) {
      if (renderer.colorProfile == ColorProfile.ascii) return usage;
      final lines = usage.split('\n');
      final styled = <String>[];
      for (final line in lines) {
        if (line.trim().isEmpty) {
          styled.add(line);
          continue;
        }
        final match = RegExp(r'^(\s*)(.*)$').firstMatch(line);
        if (match == null) {
          styled.add(line);
          continue;
        }
        final indent = match.group(1) ?? '';
        final rest = match.group(2) ?? '';
        final split = RegExp(r'\s{2,}').firstMatch(rest);
        if (split == null) {
          styled.add(line);
          continue;
        }
        final opt = rest.substring(0, split.start);
        final desc = rest.substring(split.end);
        final styledOption = option(opt);
        styled.add(
          '$indent$styledOption${' ' * (split.end - split.start)}$desc',
        );
      }
      return styled.join('\n');
    }

    final desc = description.trim();
    if (includeDescription && desc.isNotEmpty) {
      buffer.writeln(heading('Description:'));
      buffer.writeln('  $desc');
      buffer.writeln();
    }

    buffer.writeln(heading('Usage:'));
    buffer.writeln('  ${invocation.trim()}');
    buffer.writeln();

    buffer.writeln(heading('Options:'));
    final options = argParser.usage.trimRight();
    if (options.isEmpty) {
      buffer.writeln('  (none)');
    } else {
      buffer.writeln(indentBlock(formatOptionsUsage(options), 2));
    }

    final uniqueSubs = <args.Command<T>>{};
    final entries = <CommandListingEntry>[];
    for (final sub in subcommands.values) {
      if (!uniqueSubs.add(sub)) continue;
      if (sub.hidden) continue;
      entries.add(
        CommandListingEntry(name: sub.name, description: sub.summary),
      );
    }
    if (entries.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(heading('Available commands:'));
      buffer.writeln(
        formatCommandListing(
          entries,
          namespaceSeparator: namespaceSeparator,
          styleNamespace: heading,
          styleCommand: command,
        ),
      );
    }

    return buffer.toString().trimRight();
  }
}
