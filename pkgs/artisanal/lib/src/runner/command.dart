import 'dart:io' as dartio;

import 'package:args/command_runner.dart' as args;

import '../io/console.dart';
import '../renderer/renderer.dart';
import '../style/color.dart';
import '../style/style.dart';
import 'command_listing.dart';
import 'command_runner.dart';

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

  @override
  void printUsage() {
    final r = runner;
    if (r is CommandRunner<T>) {
      r.writeOut(formatUsage());
      return;
    }
    dartio.stdout.writeln(formatUsage());
  }

  @override
  Never usageException(String message) =>
      throw args.UsageException(message, formatUsage(includeDescription: true));

  /// Formats help output for this command.
  String formatUsage({bool includeDescription = true}) {
    final buffer = StringBuffer();
    final Renderer renderer = runner is CommandRunner<T>
        ? (runner as CommandRunner<T>).renderer
        : StringRenderer(colorProfile: ColorProfile.ascii);

    String heading(String text) =>
        (Style()
              ..colorProfile = renderer.colorProfile
              ..hasDarkBackground = renderer.hasDarkBackground)
            .bold()
            .foreground(Colors.yellow)
            .render(text);
    String command(String text) =>
        (Style()
              ..colorProfile = renderer.colorProfile
              ..hasDarkBackground = renderer.hasDarkBackground)
            .foreground(Colors.green)
            .render(text);
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
        final option = rest.substring(0, split.start);
        final desc = rest.substring(split.end);
        final styledOption =
            (Style()
                  ..colorProfile = renderer.colorProfile
                  ..hasDarkBackground = renderer.hasDarkBackground)
                .foreground(Colors.green)
                .render(option);
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
