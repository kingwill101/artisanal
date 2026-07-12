import 'dart:async';
import 'dart:convert' show base64, utf8;
import 'dart:io' as io;

import 'msg.dart';
import '../terminal/ansi.dart' as term_ansi;

DateTime _defaultNowProvider() => DateTime.now();

// ─────────────────────────────────────────────────────────────────────────────
// Internal messages for terminal control commands
// ─────────────────────────────────────────────────────────────────────────────

/// Internal message to set window title.
class SetWindowTitleMsg extends Msg {
  const SetWindowTitleMsg(this.title);
  final String title;
}

/// Internal message to clear the screen.
class ClearScreenMsg extends Msg {
  const ClearScreenMsg();
}

/// Internal message to enter alt screen.
class EnterAltScreenMsg extends Msg {
  const EnterAltScreenMsg();
}

/// Internal message to exit alt screen.
class ExitAltScreenMsg extends Msg {
  const ExitAltScreenMsg();
}

/// Internal message to show cursor.
class ShowCursorMsg extends Msg {
  const ShowCursorMsg();
}

/// Internal message to hide cursor.
class HideCursorMsg extends Msg {
  const HideCursorMsg();
}

/// Internal message to enable mouse cell motion tracking.
class EnableMouseCellMotionMsg extends Msg {
  const EnableMouseCellMotionMsg();
}

/// Internal message to enable mouse all motion tracking.
class EnableMouseAllMotionMsg extends Msg {
  const EnableMouseAllMotionMsg();
}

/// Internal message to disable mouse tracking.
class DisableMouseMsg extends Msg {
  const DisableMouseMsg();
}

/// Internal message to enable bracketed paste.
class EnableBracketedPasteMsg extends Msg {
  const EnableBracketedPasteMsg();
}

/// Internal message to disable bracketed paste.
class DisableBracketedPasteMsg extends Msg {
  const DisableBracketedPasteMsg();
}

/// Internal message to enable focus reporting.
class EnableReportFocusMsg extends Msg {
  const EnableReportFocusMsg();
}

/// Internal message to disable focus reporting.
class DisableReportFocusMsg extends Msg {
  const DisableReportFocusMsg();
}

/// Internal message to request window size.
class RequestWindowSizeMsg extends Msg {
  const RequestWindowSizeMsg();
}

/// Message signaling the program should suspend (like Ctrl+Z).
class SuspendMsg extends Msg {
  const SuspendMsg();
}

/// Message sent when the program resumes from suspension.
class ResumeMsg extends Msg {
  const ResumeMsg();
}

/// Message for printing a line above the program output.
class PrintLineMsg extends Msg {
  const PrintLineMsg(this.text);
  final String text;
}

/// Internal message to write raw bytes/escape sequences to the terminal.
///
/// This is primarily intended for requesting terminal reports (e.g. DA/OSC
/// queries) without performing direct `stdout.write` calls that can desync the
/// renderer.
class WriteRawMsg extends Msg {
  const WriteRawMsg(this.data);
  final String data;
}

/// Clipboard write transport used by [ClipboardSetMsg].
enum ClipboardSetMethod {
  /// Clipboard was written via an external helper process.
  external,

  /// Clipboard was written via OSC 52 terminal sequence.
  osc52,
}

/// Message emitted after a best-effort clipboard write is attempted.
class ClipboardSetMsg extends Msg {
  const ClipboardSetMsg({required this.method, required this.textLength});

  final ClipboardSetMethod method;
  final int textLength;
}

/// Internal message to request a repaint.
class RepaintRequestMsg extends Msg {
  const RepaintRequestMsg({this.force = false});
  final bool force;
}

/// Message signaling that an external process should be executed.
///
/// This is an internal message used by [Cmd.exec].
class ExecProcessMsg extends Msg {
  const ExecProcessMsg({
    required this.executable,
    required this.arguments,
    required this.onComplete,
    this.workingDirectory,
    this.environment,
  });

  /// The executable to run.
  final String executable;

  /// Arguments to pass to the executable.
  final List<String> arguments;

  /// Working directory for the process.
  final String? workingDirectory;

  /// Environment variables for the process.
  final Map<String, String>? environment;

  /// Callback to create a message from the process result.
  final Msg Function(ExecResult result) onComplete;
}

/// Result of executing an external process.
class ExecResult {
  const ExecResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  /// The exit code of the process.
  final int exitCode;

  /// Standard output from the process.
  final String stdout;

  /// Standard error from the process.
  final String stderr;

  /// Whether the process exited successfully (exit code 0).
  bool get success => exitCode == 0;

  @override
  String toString() =>
      'ExecResult(exitCode: $exitCode, stdout: ${stdout.length} chars, stderr: ${stderr.length} chars)';
}

/// A command that produces a message asynchronously.
///
/// Commands represent side effects in the TUI architecture. They are
/// async operations that, when complete, may produce a message to be
/// sent back to the [Model.update] function.
///
/// {@category TUI}
///
/// {@macro artisanal_tui_commands_and_messages}
///
/// ## Built-in Commands
///
/// - [Cmd.none] - No-op command
/// - [Cmd.quit] - Exit the program
/// - [Cmd.tick] - Single timer
/// - `Cmd.every` - Repeating timer (not yet implemented)
/// - [Cmd.batch] - Run multiple commands concurrently
/// - [Cmd.sequence] - Run commands in order
/// - [Cmd.message] - Immediately send a message
///
/// ## Custom Commands
///
/// Create custom commands by providing an async function:
///
/// ```dart
/// Cmd fetchData() {
///   return Cmd(() async {
///     final response = await http.get(Uri.parse('https://api.example.com/data'));
///     return DataLoadedMsg(response.body);
///   });
/// }
/// ```
class Cmd {
  /// Creates a command from an async function.
  const Cmd(this._execute);

  final Future<Msg?> Function() _execute;

  /// Executes the command and returns the resulting message (if any).
  Future<Msg?> execute() => _execute();

  // ─────────────────────────────────────────────────────────────────────────────
  // Built-in Commands
  // ─────────────────────────────────────────────────────────────────────────────

  /// A command that does nothing.
  ///
  /// Use this when update needs to return a command but has nothing to do.
  ///
  /// ```dart
  /// return (newModel, Cmd.none());
  /// ```
  static Cmd none() => const Cmd(_noop);

  static Future<Msg?> _noop() async => null;

  /// A command that signals the program to quit.
  ///
  /// This triggers a graceful shutdown sequence:
  /// 1. Terminal state is restored
  /// 2. Alt screen is exited (if used)
  /// 3. Cursor is shown
  /// 4. Program exits
  ///
  /// ```dart
  /// KeyMsg(key: Key(type: KeyType.runes, runes: [0x71])) => // 'q'
  ///   (this, Cmd.quit()),
  /// ```
  static Cmd quit() => const Cmd(_quit);

  static Future<Msg?> _quit() async => const QuitMsg();

  /// Sends a message after a delay.
  static Cmd delayed(Duration duration, Msg? Function() callback) {
    return Cmd(() async {
      await Future<void>.delayed(duration);
      return callback();
    });
  }

  /// A command that forces a repaint of the view.
  ///
  /// This bypasses the skip-if-unchanged optimization and forces
  /// a full re-render of the current view.
  ///
  /// Useful when:
  /// - External factors have changed the terminal state
  /// - The view needs to be refreshed
  /// - Recovering from display corruption
  ///
  /// ```dart
  /// return (model, Cmd.repaint());
  /// ```
  static Cmd repaint({bool force = true}) {
    return Cmd(() async => RepaintRequestMsg(force: force));
  }

  /// A command that sets the terminal window title.
  ///
  /// ```dart
  /// return (model, Cmd.setWindowTitle('My App - Page 1'));
  /// ```
  static Cmd setWindowTitle(String title) {
    return Cmd(() async => SetWindowTitleMsg(title));
  }

  /// A command that writes raw bytes/escape sequences directly to the terminal.
  static Cmd writeRaw(String data) {
    return Cmd(() async => WriteRawMsg(data));
  }

  /// Set the terminal clipboard via OSC 52.
  ///
  /// Most terminals expect base64-encoded UTF-8.
  ///
  /// This requires ANSI escape support and may be blocked by terminal security
  /// settings. It is safe to call even if unsupported.
  static Cmd setClipboard(String text, {String selection = 'c'}) {
    final sel = selection.isEmpty ? 'c' : selection[0];
    final payload = base64.encode(utf8.encode(text));
    return writeRaw('\x1b]52;$sel;$payload\x07');
  }

  /// Set clipboard using external helpers when possible, with OSC 52 fallback.
  ///
  /// Preferred external tools by platform:
  /// - Linux: `wl-copy`, then `xclip`, then `xsel`
  /// - macOS: `pbcopy`
  /// - Windows: `clip`
  ///
  /// If an external helper is unavailable or fails, falls back to [setClipboard]
  /// (OSC 52) to preserve compatibility with terminals that support it.
  static Cmd setClipboardBestEffort(String text, {String selection = 'c'}) {
    return Cmd(() async {
      final copied = await _trySetClipboardExternal(text);
      if (copied) {
        return ClipboardSetMsg(
          method: ClipboardSetMethod.external,
          textLength: text.length,
        );
      }
      return await Cmd.sequence([
        setClipboard(text, selection: selection),
        Cmd.message(
          ClipboardSetMsg(
            method: ClipboardSetMethod.osc52,
            textLength: text.length,
          ),
        ),
      ]).execute();
    });
  }

  static Future<bool> _trySetClipboardExternal(String text) async {
    final commands = _clipboardWriteCommands();
    for (final cmd in commands) {
      try {
        final process = await io.Process.start(
          cmd.$1,
          cmd.$2,
          runInShell: false,
        );
        process.stdin.write(text);
        await process.stdin.close();
        final exitCode = await process.exitCode;
        if (exitCode == 0) return true;
      } on Object {
        continue;
      }
    }
    return false;
  }

  static List<(String, List<String>)> _clipboardWriteCommands() {
    if (io.Platform.isLinux) {
      return const <(String, List<String>)>[
        ('wl-copy', <String>[]),
        ('xclip', <String>['-selection', 'clipboard']),
        ('xsel', <String>['--clipboard', '--input']),
      ];
    }
    if (io.Platform.isMacOS) {
      return const <(String, List<String>)>[('pbcopy', <String>[])];
    }
    if (io.Platform.isWindows) {
      return const <(String, List<String>)>[('clip', <String>[])];
    }
    return const <(String, List<String>)>[];
  }

  /// Request clipboard content via OSC 52.
  ///
  /// Many terminals do not support clipboard reads and may ignore this request.
  /// When supported, UV input decoding will emit a [ClipboardMsg].
  static Cmd requestClipboard({String selection = 'c'}) {
    final sel = selection.isEmpty ? 'c' : selection[0];
    return writeRaw('\x1b]52;$sel;?\x07');
  }

  /// Request the terminal to report primary device attributes (DA1).
  ///
  /// Terminals respond with `CSI ? <attrs> c`, which UV decoding maps to
  /// [PrimaryDeviceAttributesMsg].
  static Cmd requestPrimaryDeviceAttributesReport() =>
      writeRaw(term_ansi.Ansi.requestPrimaryDeviceAttributes);

  /// Request the terminal to report secondary device attributes (DA2).
  ///
  /// Terminals respond with `CSI > <attrs> c`, which UV decoding maps to
  /// [SecondaryDeviceAttributesMsg].
  static Cmd requestSecondaryDeviceAttributesReport() =>
      writeRaw(term_ansi.Ansi.requestSecondaryDeviceAttributes);

  /// Request the terminal to report tertiary device attributes (DA3).
  ///
  /// Terminals respond with `DCS ! | <text> ST`, which UV decoding maps to
  /// [TertiaryDeviceAttributesMsg].
  static Cmd requestTertiaryDeviceAttributesReport() =>
      writeRaw(term_ansi.Ansi.requestTertiaryDeviceAttributes);

  /// Request the terminal to report its name and version (XTVERSION).
  ///
  /// Terminals respond with `DCS > | <text> ST`, which UV decoding maps to
  /// [TerminalVersionMsg].
  static Cmd requestTerminalVersionReport() =>
      writeRaw(term_ansi.Ansi.requestTerminalVersion);

  /// Request termcap/terminfo capability strings (XTGETTCAP).
  ///
  /// Terminals respond with `DCS 1 + r ... ST`, which UV decoding maps to
  /// [CapabilityMsg]. Capability names are encoded as hexadecimal bytes per
  /// xterm's XTGETTCAP protocol.
  static Cmd requestTermcapStrings(Iterable<String> names) =>
      writeRaw(term_ansi.Ansi.requestTermcapStrings(names));

  /// Request kitty keyboard enhancement support details.
  ///
  /// Terminals respond with `CSI ? ... u`, which UV decoding maps to
  /// [KeyboardEnhancementsMsg].
  static Cmd requestKeyboardEnhancementsReport() =>
      writeRaw(term_ansi.Ansi.requestKittyKeyboard);

  /// Request the xterm ModifyOtherKeys mode.
  ///
  /// Terminals respond with `CSI > 4 ; <mode> m`, which UV decoding maps to
  /// [ModifyOtherKeysMsg].
  static Cmd requestModifyOtherKeysReport() =>
      writeRaw(term_ansi.Ansi.requestModifyOtherKeys);

  /// Request the terminal to report its character cell size (rows/cols).
  ///
  /// Terminals that support xterm window ops respond to `CSI 18 t` with
  /// `CSI 8 ; <rows> ; <cols> t`, which UV decoding maps to [WindowSizeMsg].
  static Cmd requestWindowSizeReport() => writeRaw('\x1b[18t');

  /// Request the terminal to report the current cursor position.
  ///
  /// Terminals respond to `CSI 6 n` with `CSI <row> ; <col> R`, which UV
  /// decoding maps to [CursorPositionMsg].
  static Cmd requestCursorPositionReport() =>
      writeRaw(term_ansi.Ansi.requestCursorPosition);

  /// Request the terminal to report its window size in pixels.
  ///
  /// Terminals that support xterm window ops respond to `CSI 14 t` with
  /// `CSI 4 ; <height> ; <width> t`, which UV decoding maps to
  /// [WindowPixelSizeMsg].
  static Cmd requestWindowPixelSizeReport() => writeRaw('\x1b[14t');

  /// Request the terminal to report its cell size in pixels.
  ///
  /// Terminals that support xterm window ops respond to `CSI 16 t` with
  /// `CSI 6 ; <height> ; <width> t`, which UV decoding maps to [CellSizeMsg].
  static Cmd requestCellSizeReport() => writeRaw('\x1b[16t');

  /// Request the terminal to report the current state of a terminal mode.
  ///
  /// When UV input decoding is enabled, xterm-style mode replies such as
  /// `CSI ? 2004 ; 1 $ y` are translated to [ModeReportMsg].
  static Cmd requestModeReport(int mode, {bool private = true}) =>
      writeRaw('\x1b[${private ? '?' : ''}$mode\$p');

  /// Request the terminal to report its light/dark color-scheme preference.
  ///
  /// When UV input decoding is enabled, replies such as `CSI ? 997 ; 1 n` and
  /// `CSI ? 997 ; 2 n` are translated to [ColorSchemeMsg].
  static Cmd requestColorSchemeReport() =>
      writeRaw(term_ansi.Ansi.requestColorScheme);

  /// Requests terminal foreground/background/cursor color reports (OSC 10/11/12),
  /// plus DA1 as a follow-up.
  ///
  /// When UV input decoding is enabled, these are translated to
  /// [BackgroundColorMsg], [ForegroundColorMsg], or [CursorColorMsg]
  /// instances by the UV adapter.
  static Cmd requestTerminalColors() => writeRaw(
    term_ansi.Ansi.requestForegroundColor +
        term_ansi.Ansi.requestBackgroundColor +
        term_ansi.Ansi.requestCursorColor +
        term_ansi.Ansi.requestPrimaryDeviceAttributes,
  );

  /// Requests the terminal background color (OSC 11), plus DA1 as a follow-up.
  static Cmd requestBackgroundColorReport() => writeRaw(
    term_ansi.Ansi.requestBackgroundColor +
        term_ansi.Ansi.requestPrimaryDeviceAttributes,
  );

  /// A command that clears the terminal screen.
  ///
  /// ```dart
  /// return (model, Cmd.clearScreen());
  /// ```
  static Cmd clearScreen() {
    return const Cmd(_clearScreen);
  }

  static Future<Msg?> _clearScreen() async => const ClearScreenMsg();

  /// A command that enters the alternate screen buffer.
  ///
  /// Use this to switch to fullscreen mode dynamically.
  static Cmd enterAltScreen() {
    return const Cmd(_enterAltScreen);
  }

  static Future<Msg?> _enterAltScreen() async => const EnterAltScreenMsg();

  /// A command that exits the alternate screen buffer.
  ///
  /// Use this to return to normal terminal mode.
  static Cmd exitAltScreen() {
    return const Cmd(_exitAltScreen);
  }

  static Future<Msg?> _exitAltScreen() async => const ExitAltScreenMsg();

  /// A command that shows the terminal cursor.
  static Cmd showCursor() {
    return const Cmd(_showCursor);
  }

  static Future<Msg?> _showCursor() async => const ShowCursorMsg();

  /// A command that hides the terminal cursor.
  static Cmd hideCursor() {
    return const Cmd(_hideCursor);
  }

  static Future<Msg?> _hideCursor() async => const HideCursorMsg();

  /// A command that enables mouse cell motion tracking.
  ///
  /// Reports mouse clicks and motion when a button is held.
  static Cmd enableMouseCellMotion() {
    return const Cmd(_enableMouseCellMotion);
  }

  static Future<Msg?> _enableMouseCellMotion() async =>
      const EnableMouseCellMotionMsg();

  /// A command that enables mouse all motion tracking.
  ///
  /// Reports all mouse motion, even without a button held.
  static Cmd enableMouseAllMotion() {
    return const Cmd(_enableMouseAllMotion);
  }

  static Future<Msg?> _enableMouseAllMotion() async =>
      const EnableMouseAllMotionMsg();

  /// A command that disables mouse tracking.
  static Cmd disableMouse() {
    return const Cmd(_disableMouse);
  }

  static Future<Msg?> _disableMouse() async => const DisableMouseMsg();

  /// A command that enables bracketed paste mode.
  ///
  /// When enabled, pasted text is wrapped in escape sequences
  /// and delivered as a single [PasteMsg].
  static Cmd enableBracketedPaste() {
    return const Cmd(_enableBracketedPaste);
  }

  static Future<Msg?> _enableBracketedPaste() async =>
      const EnableBracketedPasteMsg();

  /// A command that disables bracketed paste mode.
  static Cmd disableBracketedPaste() {
    return const Cmd(_disableBracketedPaste);
  }

  static Future<Msg?> _disableBracketedPaste() async =>
      const DisableBracketedPasteMsg();

  /// A command that enables focus reporting.
  ///
  /// When enabled, [FocusMsg] is sent when the terminal gains or loses focus.
  static Cmd enableReportFocus() {
    return const Cmd(_enableReportFocus);
  }

  static Future<Msg?> _enableReportFocus() async =>
      const EnableReportFocusMsg();

  /// A command that disables focus reporting.
  static Cmd disableReportFocus() {
    return const Cmd(_disableReportFocus);
  }

  static Future<Msg?> _disableReportFocus() async =>
      const DisableReportFocusMsg();

  /// A command that requests the current window size.
  ///
  /// Results in a [WindowSizeMsg] being sent.
  static Cmd windowSize() {
    return const Cmd(_windowSize);
  }

  static Future<Msg?> _windowSize() async => const RequestWindowSizeMsg();

  /// A command that suspends the program.
  ///
  /// Similar to pressing Ctrl+Z in a normal terminal program.
  /// The program can be resumed later.
  static Cmd suspend() {
    return const Cmd(_suspend);
  }

  static Future<Msg?> _suspend() async => const SuspendMsg();

  /// A command that prints a line above the program output.
  ///
  /// This output persists across renders and is useful for logging.
  /// Only works when not in alt screen mode.
  static Cmd println(String text) {
    return Cmd(() async => PrintLineMsg(text));
  }

  /// A command that prints formatted text above the program output.
  ///
  /// Similar to [println] but accepts format arguments.
  static Cmd printf(String format, List<Object> args) {
    // Simple string formatting
    var result = format;
    for (final arg in args) {
      result = result.replaceFirst(RegExp(r'%[sdifv]'), arg.toString());
    }
    return Cmd(() async => PrintLineMsg(result));
  }

  /// A command that executes an external process.
  ///
  /// The TUI program will:
  /// 1. Restore the terminal to normal mode
  /// 2. Run the external process
  /// 3. Re-enter TUI mode
  /// 4. Send [onComplete] message with the result
  ///
  /// This is useful for opening editors, running shell commands,
  /// or any external program that needs terminal access.
  ///
  /// ```dart
  /// // Open a file in the user's editor
  /// Cmd.exec(
  ///   'vim',
  ///   ['/path/to/file.txt'],
  ///   onComplete: (result) => FileEditedMsg(result.exitCode),
  /// )
  ///
  /// // Run a shell command
  /// Cmd.exec(
  ///   'git',
  ///   ['status', '--short'],
  ///   onComplete: (result) => GitStatusMsg(result.stdout),
  /// )
  /// ```
  static Cmd exec(
    String executable,
    List<String> arguments, {
    required Msg Function(ExecResult result) onComplete,
    String? workingDirectory,
    Map<String, String>? environment,
  }) {
    return Cmd(
      () async => ExecProcessMsg(
        executable: executable,
        arguments: arguments,
        onComplete: onComplete,
        workingDirectory: workingDirectory,
        environment: environment,
      ),
    );
  }

  /// A command that opens an editor for the given file.
  ///
  /// Uses the `EDITOR` environment variable, falling back to
  /// `vi` on Unix or `notepad` on Windows.
  ///
  /// ```dart
  /// Cmd.openEditor(
  ///   '/path/to/file.txt',
  ///   onComplete: (result) => EditorClosedMsg(result.success),
  /// )
  /// ```
  static Cmd openEditor(
    String filePath, {
    required Msg Function(ExecResult result) onComplete,
  }) {
    final editor =
        io.Platform.environment['EDITOR'] ??
        io.Platform.environment['VISUAL'] ??
        (io.Platform.isWindows ? 'notepad' : 'vi');

    return exec(editor, [filePath], onComplete: onComplete);
  }

  /// A command that opens a URL in the default browser.
  ///
  /// Uses the platform-appropriate command:
  /// - macOS: `open <url>`
  /// - Linux: `xdg-open <url>`
  /// - Windows: `cmd /c start "" <url>`
  ///
  /// ```dart
  /// Cmd.openUrl(
  ///   'https://example.com',
  ///   onComplete: (result) => BrowserOpenedMsg(),
  /// )
  /// ```
  static Cmd openUrl(
    String url, {
    required Msg Function(ExecResult result) onComplete,
  }) {
    final executable = io.Platform.isMacOS
        ? 'open'
        : io.Platform.isWindows
        ? 'cmd'
        : 'xdg-open';
    final arguments = io.Platform.isWindows ? ['/c', 'start', '', url] : [url];
    return exec(executable, arguments, onComplete: onComplete);
  }

  /// A command that sends a message after a delay.
  ///
  /// The [callback] receives the current time and should return the message
  /// to send. Returns null to send no message.
  ///
  /// ```dart
  /// // Send a TickMsg after 1 second
  /// Cmd.tick(Duration(seconds: 1), (time) => TickMsg(time));
  ///
  /// // Chain ticks for repeated behavior
  /// @override
  /// (Model, Cmd?) update(Msg msg) {
  ///   return switch (msg) {
  ///     TickMsg() => (
  ///       decrementCounter(),
  ///       Cmd.tick(Duration(seconds: 1), (t) => TickMsg(t)),
  ///     ),
  ///     _ => (this, null),
  ///   };
  /// }
  /// ```
  static Cmd tick(
    Duration duration,
    Msg? Function(DateTime time) callback, {
    DateTime Function()? nowProvider,
  }) {
    final resolveNow = nowProvider ?? _defaultNowProvider;
    return Cmd(() async {
      await Future<void>.delayed(duration);
      return callback(resolveNow());
    });
  }

  /// Requests the terminal's foreground color.
  ///
  /// This sends OSC 10 ? to the terminal. The terminal will respond with an
  /// OSC 10 sequence which is decoded into a [ForegroundColorMsg].
  static Cmd requestForegroundColor() =>
      Cmd(() async => WriteRawMsg(term_ansi.Ansi.requestForegroundColor));

  /// Requests the terminal's background color.
  ///
  /// This sends OSC 11 ? to the terminal. The terminal will respond with an
  /// OSC 11 sequence which is decoded into a [BackgroundColorMsg].
  static Cmd requestBackgroundColor() =>
      Cmd(() async => WriteRawMsg(term_ansi.Ansi.requestBackgroundColor));

  /// Requests the terminal's cursor color.
  ///
  /// This sends OSC 12 ? to the terminal. The terminal will respond with an
  /// OSC 12 sequence which is decoded into a [CursorColorMsg].
  static Cmd requestCursorColor() =>
      Cmd(() async => WriteRawMsg(term_ansi.Ansi.requestCursorColor));

  /// Requests a color from the terminal palette.
  ///
  /// This sends OSC 4 ; [index] ; ? to the terminal. The terminal will respond
  /// with an OSC 4 sequence which is decoded into a [ColorPaletteMsg].
  static Cmd requestColorPalette(int index) =>
      Cmd(() async => WriteRawMsg('\x1b]4;$index;?\x07'));

  /// A command that sends a message immediately.
  ///
  /// Useful for triggering an immediate update without async work.
  ///
  /// ```dart
  /// return (newModel, Cmd.message(SomeMsg()));
  /// ```
  static Cmd message(Msg msg) {
    return Cmd(() async => msg);
  }

  /// A command that runs multiple commands concurrently.
  ///
  /// All commands start executing immediately. Each command's message is
  /// delivered as it completes, without waiting for the others.
  ///
  /// ```dart
  /// return (newModel, Cmd.batch([
  ///   fetchUsers(),
  ///   fetchPosts(),
  ///   Cmd.tick(Duration(seconds: 5), (t) => TimeoutMsg()),
  /// ]));
  /// ```
  static Cmd batch(List<Cmd> commands) {
    if (commands.isEmpty) return none();
    if (commands.length == 1) return commands.first;

    // ParallelCmd is handled by the runtime: each sub-command is dispatched
    // through _executeCommand and its message forwarded via send() as soon
    // as that command finishes.  This matches the documented semantics of
    // "sent as they complete" — unlike the old Future.wait approach which
    // blocked until every command resolved.
    return ParallelCmd(commands);
  }

  /// A command that runs commands in sequence.
  ///
  /// Each command completes before the next starts. Messages are collected
  /// and returned together after all commands complete.
  ///
  /// ```dart
  /// return (newModel, Cmd.sequence([
  ///   initializeDatabase(),
  ///   loadConfiguration(),
  ///   startServer(),
  /// ]));
  /// ```
  static Cmd sequence(List<Cmd> commands) {
    if (commands.isEmpty) return none();
    if (commands.length == 1) return commands.first;

    return Cmd(() async {
      final messages = <Msg>[];
      for (final cmd in commands) {
        final msg = await cmd.execute();
        if (msg != null) messages.add(msg);
      }

      if (messages.isEmpty) return null;
      if (messages.length == 1) return messages.first;
      return BatchMsg(messages);
    });
  }

  /// A command that runs an async function and maps the result to a message.
  ///
  /// This is a convenience for wrapping arbitrary async work.
  ///
  /// ```dart
  /// Cmd.perform(
  ///   () => httpClient.get(url),
  ///   onSuccess: (response) => DataMsg(response.body),
  ///   onError: (error) => ErrorMsg(error.toString()),
  /// );
  /// ```
  static Cmd perform<T>(
    Future<T> Function() task, {
    required Msg Function(T result) onSuccess,
    Msg Function(Object error, StackTrace stack)? onError,
  }) {
    return Cmd(() async {
      try {
        final result = await task();
        return onSuccess(result);
      } catch (e, stack) {
        if (onError != null) {
          return onError(e, stack);
        }
        rethrow;
      }
    });
  }

  /// A command that listens to a stream and sends messages for each event.
  ///
  /// Returns a [StreamCmd] that can be cancelled.
  ///
  /// ```dart
  /// final cmd = Cmd.listen(
  ///   websocket.stream,
  ///   onData: (data) => WebSocketDataMsg(data),
  ///   onError: (e, s) => WebSocketErrorMsg(e.toString()),
  ///   onDone: () => WebSocketClosedMsg(),
  /// );
  /// ```
  static StreamCmd<T> listen<T>(
    Stream<T> stream, {
    required Msg? Function(T data) onData,
    Msg? Function(Object error, StackTrace stack)? onError,
    Msg? Function()? onDone,
  }) {
    return StreamCmd<T>(
      stream: stream,
      onData: onData,
      onError: onError,
      onDone: onDone,
    );
  }
}

/// A command that manages a stream subscription.
///
/// Unlike regular [Cmd], a [StreamCmd] continues producing messages
/// until cancelled or the stream completes.
class StreamCmd<T> extends Cmd {
  StreamCmd({
    required this.stream,
    required this.onData,
    this.onError,
    this.onDone,
  }) : super(_placeholder);

  static Future<Msg?> _placeholder() async => null;

  /// The stream to listen to.
  final Stream<T> stream;

  /// Callback for stream data events.
  final Msg? Function(T data) onData;

  /// Callback for stream errors.
  final Msg? Function(Object error, StackTrace stack)? onError;

  /// Callback for stream completion.
  final Msg? Function()? onDone;

  StreamSubscription<T>? _subscription;

  /// Starts listening to the stream.
  ///
  /// Messages are sent through the provided [sendMessage] callback.
  void start(void Function(Msg) sendMessage) {
    _subscription = stream.listen(
      (data) {
        final msg = onData(data);
        if (msg != null) sendMessage(msg);
      },
      onError: (Object error, StackTrace stack) {
        if (onError != null) {
          final msg = onError!(error, stack);
          if (msg != null) sendMessage(msg);
        }
      },
      onDone: () {
        if (onDone != null) {
          final msg = onDone!();
          if (msg != null) sendMessage(msg);
        }
      },
    );
  }

  /// Cancels the stream subscription.
  Future<void> cancel() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  /// Whether the subscription is active.
  bool get isActive => _subscription != null;
}

/// A repeating command that fires at regular intervals.
///
/// The interval is synchronized to wall-clock time (e.g., if interval
/// is 1 second, it fires at :00, :01, :02, etc.).
class EveryCmd extends Cmd {
  EveryCmd({
    required this.interval,
    required this.callback,
    this.id,
    DateTime Function()? nowProvider,
  }) : _nowProvider = nowProvider ?? _defaultNowProvider,
       super(_placeholder);

  static Future<Msg?> _placeholder() async => null;

  /// The interval between ticks.
  final Duration interval;

  /// The callback to create messages on each tick.
  final Msg? Function(DateTime time) callback;

  /// Optional identifier for this timer.
  final Object? id;

  final DateTime Function() _nowProvider;

  Timer? _starter;
  Timer? _timer;

  /// Starts the repeating timer.
  ///
  /// Messages are sent through the provided [sendMessage] callback.
  void start(void Function(Msg) sendMessage) {
    // Calculate time until next interval boundary
    final now = _nowProvider();
    final intervalMs = interval.inMilliseconds;
    final msIntoInterval = now.millisecondsSinceEpoch % intervalMs;
    final msUntilNext = intervalMs - msIntoInterval;

    // First tick at next boundary
    _starter?.cancel();
    _timer?.cancel();
    _starter = Timer(Duration(milliseconds: msUntilNext), () {
      // If stop() was called before the first tick, do nothing.
      if (_starter == null) return;
      _tick(sendMessage);
      // Then repeat at interval
      _timer = Timer.periodic(interval, (_) => _tick(sendMessage));
    });
  }

  void _tick(void Function(Msg) sendMessage) {
    final msg = callback(_nowProvider());
    if (msg != null) sendMessage(msg);
  }

  /// Stops the repeating timer.
  void stop() {
    _starter?.cancel();
    _starter = null;
    _timer?.cancel();
    _timer = null;
  }

  /// Whether the timer is active.
  ///
  /// Returns `true` if either the initial delay timer or the repeating
  /// timer is active. This correctly reports activity during the initial
  /// delay period before the first tick.
  bool get isActive =>
      (_starter?.isActive ?? false) || (_timer?.isActive ?? false);
}

/// A command that executes multiple commands in parallel through the Program's
/// command execution system.
///
/// Unlike [Cmd.batch], which executes commands directly and waits for all to
/// complete before returning messages, [ParallelCmd] delegates each command
/// to [Program._executeCommand], allowing special commands like [EveryCmd]
/// and [StreamCmd] to be properly started.
///
/// Use this when you need to start both regular commands and special commands
/// (like timers or streams) in parallel:
///
/// ```dart
/// @override
/// Cmd? init() {
///   return ParallelCmd([
///     // This EveryCmd will be properly started by Program
///     EveryCmd(interval: fps, callback: (t) => TickMsg(t)),
///     // This regular command runs alongside
///     Cmd.perform(fetchData, onSuccess: DataMsg.new, onError: ErrorMsg.new),
///   ]);
/// }
/// ```
class ParallelCmd extends Cmd {
  ParallelCmd(this.commands) : super(_placeholder);

  static Future<Msg?> _placeholder() async => null;

  /// The commands to execute in parallel.
  final List<Cmd> commands;
}

// ─────────────────────────────────────────────────────────────────────────────
// Extensions
// ─────────────────────────────────────────────────────────────────────────────

/// Extension methods for nullable Cmd.
extension CmdExtension on Cmd? {
  /// Returns the command or [Cmd.none()] if null.
  Cmd orNone() => this ?? Cmd.none();

  /// Returns true if this command is non-null and not a no-op.
  bool get isActive => this != null;
}

/// Helper to create a repeating timer command.
///
/// ```dart
/// @override
/// Cmd? init() => every(Duration(seconds: 1), (t) => TickMsg(t));
/// ```
Cmd every(
  Duration interval,
  Msg? Function(DateTime time) callback, {
  Object? id,
  DateTime Function()? nowProvider,
}) {
  return EveryCmd(
    interval: interval,
    callback: callback,
    id: id,
    nowProvider: nowProvider,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Convenience type aliases
// ─────────────────────────────────────────────────────────────────────────────

/// Type alias for a function that creates commands.
typedef CmdFunc = Cmd Function();

/// Type alias for a function that creates commands from a value.
typedef CmdFunc1<T> = Cmd Function(T value);
