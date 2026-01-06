import 'dart:io' as dartio;

import 'package:args/command_runner.dart' as args_pkg;
import 'package:args/command_runner.dart' show UsageException;
export 'package:args/args.dart' show ArgParser, ArgParserException, ArgResults;

import '../io/console.dart';
import '../renderer/renderer.dart';
import '../style/color.dart';
import '../style/style.dart';
import '../style/verbosity.dart';
import 'command_listing.dart';

/// Callback for writing a line to output.
typedef Write = void Function(String line);

/// Callback for writing raw text to output.
typedef WriteRaw = void Function(String text);

/// Callback for reading a line of input.
typedef ReadLine = String? Function();

/// Callback for setting the process exit code.
typedef ExitCodeSetter = void Function(int code);

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
/// final runner = CommandRunner('myapp', 'My application')
///   ..addCommand(ServeCommand())
///   ..addCommand(DbMigrateCommand());
///
/// await runner.run(args);
/// ```
class CommandRunner<T> extends args_pkg.CommandRunner<T> {
  /// Creates a new command runner.
  ///
  /// - [executableName]: The name of the executable (shown in usage).
  /// - [description]: A description of the application.
  /// - [namespaceSeparator]: Character used to group commands (default: `:`).
  /// - [usageExitCode]: Exit code for usage errors (default: 64).
  /// - [ansi]: Force ANSI output on/off (auto-detected by default).
  CommandRunner(
    super.executableName,
    super.description, {
    this.namespaceSeparator = ':',
    this.usageExitCode = 64,
    bool? ansi,
    Renderer? renderer,
    Write? out,
    Write? err,
    WriteRaw? outRaw,
    WriteRaw? errRaw,
    ReadLine? readLine,
    ExitCodeSetter? setExitCode,
    super.usageLineLength,
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
                 ? null
                 : (ansi == false ? ColorProfile.ascii : null),
             forceNoAnsi: ansi == false,
           ),
       _rendererInjected = renderer != null {
    _setupGlobalFlags();
  }

  /// Separator used to group commands into namespaces.
  final String namespaceSeparator;

  /// Exit code set when a [UsageException] occurs.
  final int usageExitCode;

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

  /// The renderer for output.
  Renderer get renderer => _renderer;

  /// The current verbosity level.
  Verbosity get verbosity => _verbosity;

  /// Whether interactive prompts are enabled.
  bool get interactive => _interactive;

  /// The I/O helper for console output.
  Console get io => _io ??= _buildIo();

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
    final ansi = _resolveAnsiForArgs(args);
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
        // If forced on, we use default detection but could optionally force ANSI support.
        // For now we leave it to auto-detect the best profile.
        _renderer = TerminalRenderer();
      } else {
        _renderer = TerminalRenderer();
      }
    }

    _verbosity = _resolveVerbosityForArgs(args);
    _interactive = _resolveInteractiveForArgs(args);
    _io = null;

    try {
      return await super.run(args);
    } on args_pkg.UsageException catch (e) {
      _printUsageError(e);
      _setExitCode(usageExitCode);
      return null;
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

    buffer.writeln(_heading('Available commands:'));
    buffer.writeln(
      formatCommandListing(
        _uniqueTopLevelEntries(),
        namespaceSeparator: namespaceSeparator,
        styleNamespace: _heading,
        styleCommand: _command,
      ),
    );
    buffer.writeln();
    buffer.writeln(
      'Run ${_emphasize('"$executableName <command> --help"')} for more information about a command.',
    );

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
  }

  Iterable<CommandListingEntry> _uniqueTopLevelEntries() {
    final seen = <args_pkg.Command<T>>{};
    final unique = <CommandListingEntry>[];
    for (final cmd in commands.values) {
      if (!seen.add(cmd)) continue;
      if (cmd.name == 'help') continue;
      unique.add(CommandListingEntry(name: cmd.name, description: cmd.summary));
    }
    unique.sort((a, b) => a.name.compareTo(b.name));
    return unique;
  }

  void _printUsageError(args_pkg.UsageException e) {
    final message = e.message.trim();
    if (message.isNotEmpty) {
      writeErr(_error('Error: $message'));
      writeErr('');
    }
    writeOut(e.usage.trimRight());
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
  String _heading(String text) =>
      (Style()
            ..colorProfile = _renderer.colorProfile
            ..hasDarkBackground = _renderer.hasDarkBackground)
          .bold()
          .foreground(Colors.yellow)
          .render(text);
  String _command(String text) =>
      (Style()
            ..colorProfile = _renderer.colorProfile
            ..hasDarkBackground = _renderer.hasDarkBackground)
          .foreground(Colors.green)
          .render(text);
  String _option(String text) =>
      (Style()
            ..colorProfile = _renderer.colorProfile
            ..hasDarkBackground = _renderer.hasDarkBackground)
          .foreground(Colors.green)
          .render(text);
  String _emphasize(String text) =>
      (Style()
            ..colorProfile = _renderer.colorProfile
            ..hasDarkBackground = _renderer.hasDarkBackground)
          .bold()
          .render(text);
  String _error(String text) =>
      (Style()
            ..colorProfile = _renderer.colorProfile
            ..hasDarkBackground = _renderer.hasDarkBackground)
          .foreground(Colors.red)
          .render(text);

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
