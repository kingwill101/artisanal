library;

import 'dart:async' show FutureOr;

import 'package:args/args.dart' show ArgParser;
import 'package:args/command_runner.dart'
    as args
    show Command, CommandRunner, UsageException;

export 'command_listing.dart'
    show CommandListingEntry, formatCommandListing, indentBlock;

export 'help_color_scheme.dart' show HelpColorScheme;

export 'package:args/args.dart' show ArgParser, ArgParserException, ArgResults;
export 'package:args/command_runner.dart' show UsageException;

typedef UnknownCommandFallback<T> = FutureOr<T> Function(List<String> args);

abstract class Command<T> extends args.Command<T> {
  @override
  String get name;

  @override
  String get description;

  String formatUsage({bool includeDescription = true}) => '';

  @override
  Never usageException(String message) =>
      throw args.UsageException(message, formatUsage(includeDescription: true));
}

class CommandRunner<T> extends args.CommandRunner<T> {
  CommandRunner(super.executableName, super.description);
}

class ShellCompleter {
  ShellCompleter(ArgParser parser) : _parser = parser;
  final ArgParser _parser;

  List<String> complete(List<String> args, String compLine, int compPoint) {
    throw UnsupportedError('ShellCompleter is not available on this platform.');
  }

  static String generate(String executableName) => throw UnsupportedError(
    'ShellCompleter is not available on this platform.',
  );

  static String generateAll(List<String> executableNames) =>
      throw UnsupportedError(
        'ShellCompleter is not available on this platform.',
      );
}
