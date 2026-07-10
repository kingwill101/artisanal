import 'dart:async';
import 'dart:io' as dartio;

import 'package:args/command_runner.dart' as args_pkg;
export 'package:args/command_runner.dart' show UsageException;
export 'package:args/args.dart' show ArgParser, ArgParserException, ArgResults;
export 'shell_completion.dart' show ShellCompleter;

import 'package:completion/completion.dart' as completion;

import '../io/console.dart';
import '../renderer/renderer.dart';
import '../style/color.dart';
import '../style/style.dart';
import '../style/verbosity.dart';
import '../terminal/stdin_stream.dart';
import 'command_listing.dart';
import 'help_color_scheme.dart';
import 'shell_completion.dart';

/// Callback for writing a line to output.
typedef Write = void Function(String line);

/// Callback for writing raw text to output.
typedef WriteRaw = void Function(String text);

/// Callback for reading a line of input.
typedef ReadLine = String? Function();

/// Callback for setting the process exit code.
typedef ExitCodeSetter = void Function(int code);

/// Callback for handling arguments that do not match any top-level command.
typedef UnknownCommandFallback<T> = FutureOr<T> Function(List<String> args);

/// An Artisanal-inspired wrapper around `package:args` [CommandRunner].
///
/// Provides a polished CLI experience with:
/// - Grouped namespaced commands (e.g., `ui:*`, `db:*`) in help output
/// - Sectioned command help (`Description`, `Usage`, `Options`)
/// - Friendly error handling without stack traces
/// - Global flags for verbosity, ANSI, and interactivity
///
/// {@category Core}
///
/// {@macro artisanal_args_overview}
///
/// ```dart
/// final runner = CommandRunner(
///   CommandRunner.detectExecutableName(),
///   'My application',
/// )
///   ..addCommand(ServeCommand())
///   ..addCommand(DbMigrateCommand());
///
/// await runner.run(args);
/// ```
class CommandRunner<T> extends args_pkg.CommandRunner<T> {
  /// Auto-detects the executable name from [Platform.script].
  ///
  /// For a compiled binary, returns the binary's file name (e.g. `artisan`).
  /// For a script run via `dart run` or `dart file.dart`, returns a string
  /// like `dart run path/to/script.dart` so the usage help shows the correct
  /// invocation.
  ///
  /// ```dart
  /// final runner = CommandRunner(
  ///   CommandRunner.detectExecutableName(),
  ///   'My application',
  /// );
  /// ```
  static String detectExecutableName() {
    final script = dartio.Platform.script;
    final scriptPath = script.toFilePath();
    final basename = script.pathSegments.last;

    try {
      final cwd = dartio.Directory.current.path;
      if (scriptPath.startsWith(cwd)) {
        var relative = scriptPath.substring(cwd.length);
        final sep = dartio.Platform.pathSeparator;
        if (relative.startsWith(sep) || relative.startsWith('/') ||
            relative.startsWith('\\')) {
          relative = relative.substring(1);
        }
        if (relative.endsWith('.dart')) {
          final execName = _executableName();
          return '$execName run $relative';
        }
        return relative.split(sep).last;
      }
    } catch (_) {}
    // Fallback: just use basename
    if (basename.endsWith('.dart')) {
      final execName = _executableName();
      return '$execName run $basename';
    }
    return basename;
  }

  /// Returns the platform's Dart/Flutter executable name (e.g. `dart`).
  static String _executableName() {
    final path = dartio.Platform.executable;
    final name = path.split(dartio.Platform.pathSeparator).last;
    // Strip .exe on Windows for cleaner output.
    return name.endsWith('.exe') ? name.substring(0, name.length - 4) : name;
  }

  /// Creates a new command runner.
  ///
  /// - [executableName]: The name of the executable (shown in usage).
  /// - [description]: A description of the application.
  /// - [namespaceSeparator]: Character used to group commands (default: `:`).
  /// - [usageExitCode]: Exit code for usage errors (default: 64).
  /// - [ansi]: Force ANSI output on/off (auto-detected by default).
  /// - [helpColorScheme]: Color scheme for help output (default: [HelpColorScheme.default_]).
  /// - [enableShellCompletion]: Enable automatic shell tab-completion (default: true).
  /// - [unknownCommandFallback]: Optional fallback for shim-style CLIs that
  ///   delegate unknown commands to another executable.
  CommandRunner(
    super.executableName,
    super.description, {
    this.namespaceSeparator = ':',
    this.usageExitCode = 64,
    this.enableShellCompletion = true,
    bool? ansi,
    Renderer? renderer,
    Write? out,
    Write? err,
    WriteRaw? outRaw,
    WriteRaw? errRaw,
    ReadLine? readLine,
    ExitCodeSetter? setExitCode,
    super.usageLineLength,
    HelpColorScheme? helpColorScheme,
    this.unknownCommandFallback,
  }) : _out = out ?? ((line) => dartio.stdout.writeln(line)),
       _err = err ?? ((line) => dartio.stderr.writeln(line)),
       _outRaw = outRaw ?? ((text) => dartio.stdout.write(text)),
       _errRaw = errRaw ?? ((text) => dartio.stderr.write(text)),
       _readLine = readLine,
       _setExitCode = setExitCode ?? ((code) => dartio.exitCode = code),
       _ansiOverride = ansi,
       _renderer =
           renderer ??
           TerminalRenderer(
             forceProfile: ansi == true
                 ? ColorProfile.trueColor
                 : (ansi == false ? ColorProfile.ascii : null),
             forceNoAnsi: ansi == false,
           ),
       _rendererInjected = renderer != null,
       helpColorScheme = helpColorScheme ?? HelpColorScheme.default_ {
    _setupGlobalFlags();
  }

  /// Separator used to group commands into namespaces.
  final String namespaceSeparator;

  /// Exit code set when a [UsageException] occurs.
  final int usageExitCode;

  /// Whether automatic shell tab-completion is enabled.
  ///
  /// Defaults to `true`. Set to `false` to disable the built-in completion
  /// handler that responds to `completion --` invocations from the shell.
  final bool enableShellCompletion;

  /// Optional handler for unknown top-level commands.
  ///
  /// This is useful for shim-style CLIs that wrap another executable. The
  /// fallback runs only after built-in completion handling has had a chance to
  /// respond, so completion remains automatic for the Artisanal command tree.
  final UnknownCommandFallback<T>? unknownCommandFallback;

  final Write _out;
  final Write _err;
  final WriteRaw _outRaw;
  final WriteRaw _errRaw;
  final ReadLine? _readLine;
  final ExitCodeSetter _setExitCode;
  final bool? _ansiOverride;
  Renderer _renderer;
  final bool _rendererInjected;
  Verbosity _verbosity = Verbosity.normal;
  bool _interactive = true;
  Console? _io;

  /// The color scheme used for help output.
  ///
  /// Defaults to [HelpColorScheme.default_].
  ///
  /// Example:
  /// ```dart
  /// runner.helpColorScheme = HelpColorScheme.dark();
  /// ```
  final HelpColorScheme helpColorScheme;

  /// The renderer for output.
  Renderer get renderer => _renderer;

  /// The current verbosity level.
  Verbosity get verbosity => _verbosity;

  /// Whether interactive prompts are enabled.
  bool get interactive => _interactive;

  /// The I/O helper for console output.
  Console get io => _io ??= _buildIo();

  ShellCompleter? _shellCompleter;

  /// The shell completion helper for this runner.
  ShellCompleter get shellCompleter =>
      _shellCompleter ??= ShellCompleter(argParser);

  /// A generated shell completion script for this executable.
  String get shellCompletionScript => ShellCompleter.generate(executableName);

  @override
  String get usage => formatGlobalUsage();

  @override
  Never usageException(String message) => throw args_pkg.UsageException(
    message,
    formatGlobalUsage(includeDescription: false),
  );

  /// Writes a line to stdout.
  void writeOut(String line) => _out(line);

  /// Writes a line to stderr.
  void writeErr(String line) => _err(line);

  @override
  void printUsage() => writeOut(formatGlobalUsage());

  @override
  Future<T?> run(Iterable<String> args) async {
    final argsList = args.toList();

    if (argsList.contains('--completion-script')) {
      writeOut(shellCompletionScript);
      _setExitCode(0);
      return null;
    }

    if (enableShellCompletion) {
      completion.tryCompletion(
        argsList,
        (compArgs, compLine, compPoint) =>
            shellCompleter.complete(compArgs, compLine, compPoint),
      );
    }

    if (_shouldRunUnknownCommandFallback(argsList)) {
      return await unknownCommandFallback!(List.unmodifiable(argsList));
    }

    final ansi = _resolveAnsiForArgs(argsList);
    if (_rendererInjected) {
      // Deterministic behavior for tests: respect explicit --ansi/--no-ansi but
      // do not auto-detect terminal capabilities.
      if (ansi == false) {
        _renderer.colorProfile = ColorProfile.ascii;
      } else if (ansi == true) {
        // Use a safe default for "ANSI enabled" output.
        _renderer.colorProfile = ColorProfile.trueColor;
      }
    } else {
      if (ansi == false) {
        _renderer = TerminalRenderer(forceProfile: ColorProfile.ascii);
      } else if (ansi == true) {
        _renderer = TerminalRenderer(forceProfile: ColorProfile.trueColor);
      } else {
        _renderer = TerminalRenderer();
      }
    }

    _verbosity = _resolveVerbosityForArgs(argsList);
    _interactive = _resolveInteractiveForArgs(argsList);
    _io = null;

    try {
      return await super.run(argsList);
    } on args_pkg.UsageException catch (e) {
      if (!_handleMissingCommandAsNamespace(e)) {
        _printUsageError(e);
        _setExitCode(usageExitCode);
      }
      return null;
    } finally {
      _io?.dispose();
      if (isSharedStdinStreamStarted) {
        await shutdownSharedStdinStream();
      }
    }
  }

  /// Formats global usage, grouping commands by namespace.
  String formatGlobalUsage({bool includeDescription = true}) {
    final buffer = StringBuffer();

    if (includeDescription && description.trim().isNotEmpty) {
      buffer.writeln(description.trim());
      buffer.writeln();
    }

    buffer.writeln(_heading('Usage:'));
    buffer.writeln('  ${invocation.trim()}');
    buffer.writeln();

    buffer.writeln(_heading('Options:'));
    final globalOptions = argParser.usage.trimRight();
    if (globalOptions.isNotEmpty) {
      buffer.writeln(indentBlock(_formatOptionsUsage(globalOptions), 2));
    }
    buffer.writeln();

    final commandEntries = _uniqueTopLevelEntries();
    if (commandEntries.isNotEmpty) {
      final listing = formatCommandListing(
        commandEntries,
        namespaceSeparator: namespaceSeparator,
        styleNamespace: _heading,
        styleCommand: _command,
      );
      if (listing.isNotEmpty) {
        buffer.writeln(_heading('Available commands:'));
        buffer.writeln(listing);
        buffer.writeln();
        buffer.writeln(
          'Run ${_emphasize('"$executableName <command> --help"')} for more information about a command.',
        );
      }
    }

    return buffer.toString().trimRight();
  }

  void _setupGlobalFlags() {
    argParser.addFlag(
      'ansi',
      help: 'Force (or disable with --no-ansi) ANSI output.',
    );
    argParser.addFlag(
      'quiet',
      abbr: 'q',
      negatable: false,
      help: 'Do not output any message.',
    );
    argParser.addFlag('silent', negatable: false, help: 'Alias for --quiet.');
    argParser.addFlag(
      'no-interaction',
      abbr: 'n',
      negatable: false,
      help: 'Do not ask any interactive question.',
    );
    argParser.addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help:
          'Increase verbosity of messages: 1 for normal output, 2 for more verbose output and 3 for debug.',
    );
    argParser.addFlag(
      'completion-script',
      negatable: false,
      help: 'Print a shell completion script to stdout.',
    );
  }

  List<CommandListingEntry> _uniqueTopLevelEntries() {
    final seen = <args_pkg.Command<T>>{};
    final unique = <CommandListingEntry>[];
    for (final cmd in commands.values) {
      if (!seen.add(cmd)) continue;
      if (cmd.name == 'help' || cmd.hidden) continue;
      unique.add(CommandListingEntry(name: cmd.name, description: cmd.summary));
    }
    unique.sort((a, b) => a.name.compareTo(b.name));
    return unique;
  }

  bool _shouldRunUnknownCommandFallback(List<String> args) {
    if (unknownCommandFallback == null || args.isEmpty) return false;

    final first = args.first;
    if (first.startsWith('-')) return false;
    if (commands.containsKey(first)) return false;

    // Don't delegate namespace commands (e.g. "flutter" when commands like
    // "flutter:debug-dump" exist) to the fallback.
    if (_hasNamespaceCommands(first)) return false;

    return true;
  }

  /// Returns `true` if there are commands in the given namespace.
  bool _hasNamespaceCommands(String prefix) {
    return allCommandsInNamespace(prefix).isNotEmpty;
  }

  /// Returns all unique namespace prefixes from registered commands.
  ///
  /// For a command named `cache:clear`, this produces `['cache']`.
  /// For nested namespaces like `cache:foo:bar`, this produces
  /// `['cache', 'cache:foo']`.
  ///
  /// This is equivalent to Symfony Console's `Application::getNamespaces()`.
  List<String> getNamespaces() {
    final namespaces = <String>{};
    for (final command in commands.values) {
      if (command.hidden) continue;
      for (final ns in _extractAllNamespaces(command.name)) {
        namespaces.add(ns);
      }
    }
    final sorted = namespaces.toList()..sort();
    return sorted;
  }

  /// Returns all commands whose full name starts with [namespace] followed by
  /// [namespaceSeparator].
  ///
  /// For example, `allCommandsInNamespace('cache')` returns `cache:clear`,
  /// `cache:forget`, etc.
  ///
  /// This is equivalent to Symfony Console's `Application::all($namespace)`.
  Map<String, args_pkg.Command<T>> allCommandsInNamespace(String namespace) {
    final prefix = '$namespace$namespaceSeparator';
    return {
      for (final entry in commands.entries)
        if (entry.key.startsWith(prefix)) entry.key: entry.value,
    };
  }

  /// Attempts to handle a "command not found" error as a namespace reference.
  ///
  /// When a user types a grouped command namespace (e.g. `flutter` where
  /// commands like `flutter:debug-dump`, `flutter:frame-profile` exist),
  /// this displays the subcommands in that namespace instead of showing
  /// an error, matching Symfony Console's behavior when an unknown command
  /// matches a namespace.
  ///
  /// Returns `true` if the error was handled as a namespace, `false` otherwise.
  bool _handleMissingCommandAsNamespace(args_pkg.UsageException e) {
    final message = e.message.trim();
    // Match "Could not find a command named "X"."
    final match = RegExp(
      r'^Could not find a command named "(.+)"',
    ).firstMatch(message);
    if (match == null) return false;

    final name = match.group(1)!;

    // Check if this is a namespace with subcommands.
    final namespaceCommands = allCommandsInNamespace(name);
    if (namespaceCommands.isEmpty) return false;

    // Display a Symfony-style header.
    writeOut(_heading('Available commands for the "$name" namespace:'));

    // Build command listing entries.
    final entries = namespaceCommands.entries.map(
      (e) => CommandListingEntry(name: e.key, description: e.value.summary),
    );
    final listing = formatCommandListing(
      entries,
      namespaceSeparator: namespaceSeparator,
      styleNamespace: _heading,
      styleCommand: _command,
    );
    writeOut(listing);
    writeOut('');
    writeOut(
      'Run ${_emphasize('"$executableName $name:<subcommand> --help"')} '
      'for more information about a command.',
    );

    // Exit code 1 because no command was actually executed (matches Symfony).
    _setExitCode(1);
    return true;
  }

  /// Extracts all parent namespace parts from a command name.
  ///
  /// For `cache:clear` returns `['cache']`.
  /// For `cache:foo:bar` returns `['cache', 'cache:foo']`.
  /// For a command with no separator like `serve`, returns `[]`.
  ///
  /// This is equivalent to Symfony Console's `extractAllNamespaces()`.
  List<String> _extractAllNamespaces(String commandName) {
    final parts = commandName.split(namespaceSeparator);
    if (parts.length <= 1) return [];

    final namespaces = <String>[];
    for (var i = 0; i < parts.length - 1; i++) {
      if (i == 0) {
        namespaces.add(parts[0]);
      } else {
        namespaces.add('${namespaces.last}$namespaceSeparator${parts[i]}');
      }
    }
    return namespaces;
  }

  /// Formats and prints a Symfony-style error block to stderr.
  ///
  /// Output matches Laravel Artisan's `formatBlock($message, 'error', large: true)`:
  /// a blank line, the styled message with padding, then a trailing blank line.
  void _printUsageError(args_pkg.UsageException e) {
    final message = e.message.trim();
    if (message.isEmpty) return;

    writeErr('');
    writeErr(_styleErrorBlock(message));
    writeErr('');
  }

  /// Applies Symfony-style `<error>` block styling.
  ///
  /// In ANSI mode, the text is rendered with white foreground on red background.
  /// In ASCII mode, the text is returned with extra leading spaces (matching the
  /// visual effect of Symfony's non-decorated error output).
  String _styleErrorBlock(String message) {
    // Symfony's formatBlock with large=true adds 2 spaces padding on each side.
    final padded = '  $message  ';
    if (_renderer.colorProfile == ColorProfile.ascii) {
      return padded;
    }
    return (Style()
          ..colorProfile = _renderer.colorProfile
          ..hasDarkBackground = _renderer.hasDarkBackground
          ..foreground(Colors.white)
          ..background(Colors.red))
        .render(padded);
  }

  bool _resolveAnsiForArgs(Iterable<String> args) {
    bool? last;
    for (final arg in args) {
      if (arg == '--ansi') last = true;
      if (arg == '--no-ansi') last = false;
    }
    if (last != null) return last;
    if (_ansiOverride != null) return _ansiOverride;
    return dartio.stdout.supportsAnsiEscapes;
  }

  Console _buildIo() {
    final width = dartio.stdout.hasTerminal
        ? dartio.stdout.terminalColumns
        : null;
    return Console(
      renderer: _renderer,
      out: writeOut,
      err: writeErr,
      outRaw: _outRaw,
      errRaw: _errRaw,
      readLine: _readLine ?? (() => dartio.stdin.readLineSync()),
      interactive: interactive,
      verbosity: verbosity,
      terminalWidth: width,
    );
  }

  bool _resolveInteractiveForArgs(Iterable<String> args) {
    for (final arg in args) {
      if (arg == '--no-interaction' || arg == '-n') return false;
    }
    return true;
  }

  Verbosity _resolveVerbosityForArgs(Iterable<String> args) {
    var quiet = false;
    var vCount = 0;

    for (final arg in args) {
      if (arg == '--quiet' || arg == '-q' || arg == '--silent') {
        quiet = true;
        continue;
      }
      if (arg == '--verbose' || arg == '-v') {
        vCount++;
        continue;
      }
      final match = RegExp(r'^-v+$').firstMatch(arg);
      if (match != null) {
        vCount += arg.length - 1;
      }
    }

    if (quiet) return Verbosity.quiet;
    if (vCount <= 0) return Verbosity.normal;
    if (vCount == 1) return Verbosity.verbose;
    if (vCount == 2) return Verbosity.veryVerbose;
    return Verbosity.debug;
  }

  // Helpers for styling
  String _heading(String text) => helpColorScheme.headingStyle(_renderer)(text);
  String _command(String text) => helpColorScheme.commandStyle(_renderer)(text);
  String _option(String text) => helpColorScheme.optionStyle(_renderer)(text);
  String _emphasize(String text) =>
      helpColorScheme.emphasisStyle(_renderer)(text);
  String _formatOptionsUsage(String usage) {
    if (_renderer.colorProfile == ColorProfile.ascii) return usage;

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

      final left = rest.substring(0, split.start).trimRight();
      final spacing = rest.substring(split.start, split.end);
      final right = rest.substring(split.end);
      styled.add('$indent${_option(left)}$spacing$right');
    }

    return styled.join('\n');
  }
}
