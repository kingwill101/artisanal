import 'dart:async';
import 'dart:io' as io;

import 'package:artisanal/terminal.dart';

import '../unicode/width.dart' as uni_width;
import 'cmd.dart';
import 'emoji_width_probe.dart';
import 'key.dart' show Key, KeyParser, KeyResult, KeyType, MsgResult;
import 'model.dart';
import 'msg.dart';
import 'renderer.dart';
import 'startup_probe.dart';
import 'terminal.dart';
import 'view.dart';
import '../uv/cursor.dart';
import '../uv/tui_adapter.dart' show UvTuiInputParser;

/// The TUI program runtime.
///
/// [Program] manages the event loop, input decoding, state updates, and
/// rendering for an [artisanal.tui] application.
///
/// {@category TUI}
///
/// {@macro artisanal_tui_tea_overview}
/// {@macro artisanal_tui_program_lifecycle}
/// {@macro artisanal_tui_rendering_overview}
///
/// ## Usage
///
/// ```dart
/// final program = Program(MyModel());
/// await program.run();
/// ```
///
/// Or use the convenience helper:
///
/// ```dart
/// await runProgram(MyModel());
/// ```
// Re-export control messages for convenience
export 'cmd.dart'
    show
        SetWindowTitleMsg,
        ClearScreenMsg,
        EnterAltScreenMsg,
        ExitAltScreenMsg,
        ShowCursorMsg,
        HideCursorMsg,
        EnableMouseCellMotionMsg,
        EnableMouseAllMotionMsg,
        DisableMouseMsg,
        EnableBracketedPasteMsg,
        DisableBracketedPasteMsg,
        EnableReportFocusMsg,
        DisableReportFocusMsg,
        RequestWindowSizeMsg,
        SuspendMsg,
        ResumeMsg,
        PrintLineMsg,
        WriteRawMsg,
        ExecProcessMsg,
        ExecResult,
        RepaintRequestMsg;

// Re-export InterruptMsg and RepaintMsg from msg.dart
export 'msg.dart' show InterruptMsg, RepaintMsg;

/// A function that filters messages before they reach the model.
///
/// The filter receives the current model and the incoming message.
/// Return the message (possibly modified) to allow it through,
/// or return `null` to filter it out completely.
///
/// This is useful for:
/// - Preventing quit on unsaved changes
/// - Modifying messages before they reach the model
/// - Logging or debugging message flow
/// - Implementing global key bindings
///
/// Example:
/// ```dart
/// Msg? preventQuitFilter(Model model, Msg msg) {
///   if (msg is KeyMsg && msg.key.ctrl && msg.key.runes.firstOrNull == 0x63) {
///     // Ctrl+C pressed
///     if (model is MyModel && model.hasUnsavedChanges) {
///       // Block quit and show warning instead
///       return const ShowUnsavedWarningMsg();
///     }
///   }
///   return msg; // Allow message through
/// }
/// ```
typedef MessageFilter = Msg? Function(Model model, Msg msg);

/// Options for configuring the TUI program.
class ProgramOptions {
  const ProgramOptions({
    this.altScreen = true,
    this.mouse = false,
    this.mouseMode = MouseMode.none,
    this.fps = 60,
    this.frameTick = true,
    this.hideCursor = true,
    this.bracketedPaste = false,
    this.inputTimeout = const Duration(milliseconds: 50),
    this.catchPanics = true,
    this.maxStackFrames = 10,
    this.filter,
    this.signalHandlers = true,
    this.sendInterrupt = true,
    this.startupTitle,
    this.input,
    this.output,
    this.disableRenderer = false,
    this.ansiCompress = false,
    this.useUltravioletRenderer = true,
    this.useUltravioletInputDecoder = true,
    this.cancelSignal,
    this.environment,
    this.inputTTY = false,
    this.movementCapsOverride,
    this.shutdownSharedStdinOnExit = true,
    this.metricsInterval = const Duration(seconds: 1),
  }) : assert(fps >= 1 && fps <= 120, 'fps must be between 1 and 120');

  /// Whether to use the alternate screen buffer (fullscreen mode).
  ///
  /// When true, the application takes over the entire terminal and
  /// restores the original content on exit.
  final bool altScreen;

  /// Whether to enable mouse tracking.
  ///
  /// When true, mouse events (clicks, motion, wheel) are reported
  /// as [MouseMsg] messages.
  final bool mouse;

  /// Mouse tracking mode (none, cell motion, all motion).
  ///
  /// Takes precedence over [mouse]. When not [MouseMode.none],
  /// mouse tracking is enabled according to the chosen mode.
  final MouseMode mouseMode;

  /// Maximum frames per second for rendering.
  ///
  /// Limits how often the screen can be redrawn.
  /// Value is clamped to the range 1-120.
  final int fps;

  /// Whether to automatically send [FrameTickMsg] at the configured [fps].
  ///
  /// When true (default), the runtime sends [FrameTickMsg] messages at
  /// regular intervals based on the [fps] setting. This drives animations
  /// and continuous updates without requiring each application to set up
  /// its own tick loop.
  ///
  /// When false, no automatic ticks are sent. This is useful for static
  /// UIs that only update in response to user input, reducing CPU usage.
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Dynamic UI with animations (default)
  /// final program = Program(MyAnimatedModel());
  ///
  /// // Static UI that only updates on input
  /// final program = Program(
  ///   MyStaticModel(),
  ///   options: ProgramOptions(frameTick: false),
  /// );
  /// ```
  final bool frameTick;

  /// Whether to hide the cursor during program execution.
  final bool hideCursor;

  /// Whether to enable bracketed paste mode.
  ///
  /// When true, pasted content is wrapped in escape sequences
  /// and delivered as a single [PasteMsg].
  final bool bracketedPaste;

  /// Timeout for waiting on incomplete escape sequences.
  final Duration inputTimeout;

  /// Whether to catch panics (exceptions) and restore terminal state.
  ///
  /// When true (default), exceptions are caught, terminal state is restored,
  /// and a formatted error message with stack trace is printed.
  ///
  /// When false, exceptions propagate normally. This is useful for debugging
  /// with a debugger that needs to catch exceptions.
  final bool catchPanics;

  /// Maximum number of stack frames to display on panic.
  ///
  /// Only used when [catchPanics] is true.
  final int maxStackFrames;

  /// Optional message filter function.
  ///
  /// When provided, all messages pass through this filter before
  /// reaching the model's update method. The filter can:
  /// - Return the message unchanged to allow it through
  /// - Return a modified message
  /// - Return `null` to filter out the message completely
  ///
  /// Example:
  /// ```dart
  /// final options = ProgramOptions(
  ///   filter: (model, msg) {
  ///     // Log all messages
  ///     print('Message: $msg');
  ///     return msg;
  ///   },
  /// );
  /// ```
  final MessageFilter? filter;

  /// Whether to install signal handlers (SIGINT, SIGWINCH).
  ///
  /// When true (default), signal handlers are installed for graceful
  /// shutdown and window resize detection.
  ///
  /// When false, no signal handlers are installed. This is useful when:
  /// - Running in an environment that doesn't support signals
  /// - The parent application handles signals itself
  /// - You want complete control over signal handling
  final bool signalHandlers;

  /// Whether to send [InterruptMsg] on SIGINT instead of a Ctrl+C [KeyMsg].
  ///
  /// When true (default), SIGINT generates an [InterruptMsg] that can be
  /// handled differently from regular Ctrl+C key presses.
  ///
  /// When false, SIGINT is converted to a Ctrl+C [KeyMsg] for backward
  /// compatibility.
  final bool sendInterrupt;

  /// Optional title to set on program startup.
  ///
  /// When provided, sets the terminal window title when the program starts.
  final String? startupTitle;

  /// Optional custom input stream.
  ///
  /// When provided, input is read from this stream instead of stdin.
  /// This is useful for testing or when running in special environments.
  final Stream<List<int>>? input;

  /// Optional custom output function.
  ///
  /// When provided, output is written using this function instead of stdout.
  /// This is useful for testing or capturing output.
  final void Function(String)? output;

  /// Disable all rendering (nil renderer). Output is written once without diffing.
  final bool disableRenderer;

  /// Enable simple ANSI compression to remove redundant sequences.
  final bool ansiCompress;

  /// Use the Ultraviolet-inspired buffer + diff renderer.
  ///
  /// This keeps `Model.view(): String` but renders via a cell buffer to reduce
  /// flicker and minimize output.
  final bool useUltravioletRenderer;

  /// Use the Ultraviolet-style event decoder for terminal input.
  ///
  /// This is opt-in. The default input parser remains [KeyParser].
  final bool useUltravioletInputDecoder;

  /// Optional cancellation signal. When this completes, the program exits with cancellation.
  final Future<void>? cancelSignal;

  /// Optional environment variables to use for terminal setup.
  final List<String>? environment;

  /// Whether to prefer the controlling TTY (`/dev/tty`) for interactive input.
  ///
  /// This is useful when stdin is redirected (e.g. piping a file into the
  /// process) but you still want the TUI to read keystrokes from the terminal.
  ///
  /// On Unix platforms, the runtime attempts to open `/dev/tty` and will use
  /// `stty` to toggle raw mode for that device.
  final bool inputTTY;

  /// Optional override for terminal movement optimization capabilities.
  ///
  /// This provides a compatibility hook for environments where probing the
  /// terminal (e.g. via `stty`) is undesirable or unreliable.
  ///
  /// When set, the UV renderer uses these values instead of calling
  /// `terminal.optimizeMovements()`.
  final ({bool useTabs, bool useBackspace})? movementCapsOverride;

  /// Whether to shut down the shared stdin broadcast stream on exit.
  ///
  /// The TUI uses a shared broadcast wrapper around `stdin` so it can pause and
  /// resume input listening during a single run (e.g. suspend/exec) without
  /// hitting Dart's single-subscription stdin limitation.
  ///
  /// When enabled, program shutdown cancels the underlying stdin subscription
  /// so the process can exit cleanly on real TTYs.
  final bool shutdownSharedStdinOnExit;

  final Duration metricsInterval;

  /// Creates a copy with the given fields replaced.
  ProgramOptions copyWith({
    bool? altScreen,
    bool? mouse,
    MouseMode? mouseMode,
    int? fps,
    bool? frameTick,
    bool? hideCursor,
    bool? bracketedPaste,
    Duration? inputTimeout,
    bool? catchPanics,
    int? maxStackFrames,
    MessageFilter? filter,
    bool? signalHandlers,
    bool? sendInterrupt,
    String? startupTitle,
    Stream<List<int>>? input,
    void Function(String)? output,
    bool? disableRenderer,
    bool? ansiCompress,
    bool? useUltravioletRenderer,
    bool? useUltravioletInputDecoder,
    Future<void>? cancelSignal,
    List<String>? environment,
    bool? inputTTY,
    ({bool useTabs, bool useBackspace})? movementCapsOverride,
    bool? shutdownSharedStdinOnExit,
  }) {
    return ProgramOptions(
      altScreen: altScreen ?? this.altScreen,
      mouse: mouse ?? this.mouse,
      mouseMode: mouseMode ?? this.mouseMode,
      fps: fps ?? this.fps,
      frameTick: frameTick ?? this.frameTick,
      hideCursor: hideCursor ?? this.hideCursor,
      bracketedPaste: bracketedPaste ?? this.bracketedPaste,
      inputTimeout: inputTimeout ?? this.inputTimeout,
      catchPanics: catchPanics ?? this.catchPanics,
      maxStackFrames: maxStackFrames ?? this.maxStackFrames,
      filter: filter ?? this.filter,
      signalHandlers: signalHandlers ?? this.signalHandlers,
      sendInterrupt: sendInterrupt ?? this.sendInterrupt,
      startupTitle: startupTitle ?? this.startupTitle,
      input: input ?? this.input,
      output: output ?? this.output,
      disableRenderer: disableRenderer ?? this.disableRenderer,
      ansiCompress: ansiCompress ?? this.ansiCompress,
      useUltravioletRenderer:
          useUltravioletRenderer ?? this.useUltravioletRenderer,
      useUltravioletInputDecoder:
          useUltravioletInputDecoder ?? this.useUltravioletInputDecoder,
      cancelSignal: cancelSignal ?? this.cancelSignal,
      environment: environment ?? this.environment,
      inputTTY: inputTTY ?? this.inputTTY,
      movementCapsOverride: movementCapsOverride ?? this.movementCapsOverride,
      shutdownSharedStdinOnExit:
          shutdownSharedStdinOnExit ?? this.shutdownSharedStdinOnExit,
    );
  }

  /// Creates options with panic catching disabled.
  ///
  /// Useful for debugging with a debugger.
  ProgramOptions withoutCatchPanics() => copyWith(catchPanics: false);

  /// Creates options with the given message filter.
  ///
  /// Example:
  /// ```dart
  /// final options = ProgramOptions().withFilter((model, msg) {
  ///   if (msg is KeyMsg && msg.key.type == KeyType.ctrlC) {
  ///     if (model is MyModel && model.hasUnsavedChanges) {
  ///       return const ConfirmQuitMsg();
  ///     }
  ///   }
  ///   return msg;
  /// });
  /// ```
  ProgramOptions withFilter(MessageFilter filter) => copyWith(filter: filter);

  /// Creates options with no message filter.
  ProgramOptions withoutFilter() => ProgramOptions(
    altScreen: altScreen,
    mouse: mouse,
    fps: fps,
    frameTick: frameTick,
    hideCursor: hideCursor,
    bracketedPaste: bracketedPaste,
    inputTimeout: inputTimeout,
    catchPanics: catchPanics,
    maxStackFrames: maxStackFrames,
    filter: null,
    signalHandlers: signalHandlers,
    sendInterrupt: sendInterrupt,
    startupTitle: startupTitle,
    input: input,
    output: output,
    shutdownSharedStdinOnExit: shutdownSharedStdinOnExit,
  );

  /// Creates options with signal handlers disabled.
  ///
  /// The program will not install SIGINT or SIGWINCH handlers.
  ProgramOptions withoutSignalHandlers() => copyWith(signalHandlers: false);

  /// Creates options that send Ctrl+C KeyMsg instead of InterruptMsg on SIGINT.
  ProgramOptions withoutInterruptMsg() => copyWith(sendInterrupt: false);

  /// Creates options with the given startup title.
  ProgramOptions withStartupTitle(String title) =>
      copyWith(startupTitle: title);

  /// Creates options with custom input stream.
  ProgramOptions withInput(Stream<List<int>> input) => copyWith(input: input);

  /// Creates options with custom output function.
  ProgramOptions withOutput(void Function(String) output) =>
      copyWith(output: output);

  /// Creates options that disable rendering (nil renderer).
  ProgramOptions withoutRenderer() => copyWith(disableRenderer: true);

  /// Creates options that enable mouse cell motion tracking.
  ProgramOptions withMouseCellMotion() =>
      copyWith(mouseMode: MouseMode.cellMotion);

  /// Creates options that enable mouse all motion tracking.
  ProgramOptions withMouseAllMotion() =>
      copyWith(mouseMode: MouseMode.allMotion);

  /// Creates options that disable automatic frame ticks.
  ///
  /// Use this for static UIs that only update in response to user input,
  /// which reduces CPU usage since no periodic timer is running.
  ///
  /// ```dart
  /// final program = Program(
  ///   MyStaticModel(),
  ///   options: ProgramOptions().withoutFrameTick(),
  /// );
  /// ```
  ProgramOptions withoutFrameTick() => copyWith(frameTick: false);
}

/// Error thrown when a program is cancelled via an external signal.
class ProgramCancelledError implements Exception {
  @override
  String toString() => 'ProgramCancelledError';
}

/// The TUI program runtime.
///
/// [Program] manages the complete lifecycle of a TUI application:
///
/// 1. Initializes the terminal (raw mode, alt screen, etc.)
/// 2. Calls [Model.init] and executes any returned command
/// 3. Renders the initial view
/// 4. Listens for input and dispatches messages to [Model.update]
/// 5. Re-renders after each update
/// 6. Executes commands returned from updates
/// 7. Cleans up on exit (restores terminal state)
///
/// ## Example
///
/// ```dart
/// void main() async {
///   final program = Program(MyModel());
///   await program.run();
/// }
/// ```
///
/// ## With Options
///
/// ```dart
/// void main() async {
///   final program = Program(
///     MyModel(),
///     options: ProgramOptions(
///       altScreen: true,
///       mouse: true,
///       fps: 30,
///     ),
///   );
///   await program.run();
/// }
/// ```
///
/// ## Panic Recovery
///
/// By default, the program catches all exceptions, restores the terminal
/// state, and prints a formatted error message. This ensures the terminal
/// is never left in a broken state.
///
/// ```dart
/// // Disable panic catching for debugging
/// final program = Program(
///   MyModel(),
///   options: ProgramOptions().withoutCatchPanics(),
/// );
/// ```
///
/// ## Message Filtering
///
/// You can filter messages before they reach the model using a filter function:
///
/// ```dart
/// final program = Program(
///   MyModel(),
///   options: ProgramOptions().withFilter((model, msg) {
///     // Prevent quit if there are unsaved changes
///     if (msg is QuitMsg && model is MyModel && model.hasUnsavedChanges) {
///       return const ShowSavePromptMsg();
///     }
///     return msg; // Allow message through
///   }),
/// );
/// ```
/// The runtime that manages the TUI event loop and rendering.
/// The TUI program runtime.
///
/// {@macro artisanal_tui_tea_overview}
///
/// {@macro artisanal_tui_program_lifecycle}
///
/// {@macro artisanal_tui_rendering_overview}
///
/// {@category TUI}
class Program<M extends Model> {
  /// Creates a new TUI program with the given initial model.
  Program(
    this._initialModel, {
    ProgramOptions options = const ProgramOptions(),
    TuiTerminal? terminal,
  }) : _options = options,
       _terminal = terminal;

  final M _initialModel;
  final ProgramOptions _options;
  TuiTerminal? _terminal;

  /// The current model state.
  M? _model;

  /// The last view object returned by the model.
  View? _lastView;

  /// The renderer for output.
  TuiRenderer? _renderer;

  /// The key parser for input.
  final KeyParser _keyParser = KeyParser();
  final UvTuiInputParser _uvInputParser = UvTuiInputParser();
  Timer? _uvInputTimeoutTimer;
  Timer? _metricsTimer;
  Timer? _frameTickTimer;

  /// Frame tick state for FrameTickMsg.
  int _frameNumber = 0;
  DateTime? _lastFrameTime;

  StartupProbeRunner? _startupProbes;
  StartupProbeContext? _startupProbeContext;

  /// Stream subscription for input.
  StreamSubscription<List<int>>? _inputSubscription;
  StreamSubscription<void>? _cancelSubscription;

  /// Active stream commands.
  final List<StreamCmd> _streamCommands = [];

  /// Active repeating commands.
  final List<EveryCmd> _everyCommands = [];

  /// Whether the program is running.
  bool _running = false;
  bool _cancelled = false;

  /// Completer for the run() method.
  Completer<void>? _runCompleter;

  /// Final model snapshot captured during cleanup.
  M? _finalModel;

  /// Signal subscriptions.
  StreamSubscription<io.ProcessSignal>? _sigintSubscription;
  StreamSubscription<io.ProcessSignal>? _sigwinchSubscription;

  /// Stored panic for re-throwing after cleanup.
  Object? _panic;
  StackTrace? _panicStackTrace;

  /// Returns the current model (for testing).
  M? get currentModel => _model;

  /// Whether the program is currently running.
  bool get isRunning => _running;

  /// Final model after the program exits (captured before cleanup).
  M? get finalModel => _finalModel;

  /// Runs the TUI program.
  ///
  /// This method:
  /// 1. Sets up the terminal
  /// 2. Initializes the model
  /// 3. Starts the event loop
  /// 4. Waits for quit signal
  /// 5. Cleans up and exits
  ///
  /// Returns when the program exits (via [Cmd.quit] or interrupt).
  ///
  /// If [ProgramOptions.catchPanics] is true (default), exceptions are caught,
  /// the terminal is restored, and a formatted error is printed.
  Future<void> run() async {
    if (_running) {
      throw StateError('Program is already running');
    }

    _running = true;
    _cancelled = false;
    _runCompleter = Completer<void>();
    _panic = null;
    _panicStackTrace = null;

    if (_options.catchPanics) {
      await _runWithPanicRecovery();
    } else {
      await _runWithoutPanicRecovery();
    }
  }

  /// Runs the program with panic recovery enabled.
  Future<void> _runWithPanicRecovery() async {
    try {
      await _setup();
      _setupCancelListener();
      await _initialize();
      await _runCompleter!.future;
    } catch (e, st) {
      _panic = e;
      _panicStackTrace = st;
    } finally {
      await _cleanup();
      _running = false;
    }

    // Print panic information after terminal is restored
    if (_panic != null) {
      _printPanic(_panic!, _panicStackTrace);
      return;
    }

    if (_cancelled) {
      throw ProgramCancelledError();
    }
  }

  /// Runs the program without panic recovery (for debugging).
  Future<void> _runWithoutPanicRecovery() async {
    try {
      await _setup();
      _setupCancelListener();
      await _initialize();
      await _runCompleter!.future;
    } finally {
      await _cleanup();
      _running = false;
      if (_cancelled) {
        throw ProgramCancelledError();
      }
    }
  }

  void _setupCancelListener() {
    _cancelSubscription?.cancel();
    final cancelFuture = _options.cancelSignal;
    if (cancelFuture == null) return;
    _cancelSubscription = cancelFuture.asStream().listen((_) {
      _cancelled = true;
      _quit();
    });
  }

  /// Prints a formatted panic message to stderr.
  void _printPanic(Object error, StackTrace? stackTrace) {
    final stderr = io.stderr;

    // ANSI color codes
    const reset = '\x1b[0m';
    const red = '\x1b[31m';
    const yellow = '\x1b[33m';
    const cyan = '\x1b[36m';
    const dim = '\x1b[2m';
    const bold = '\x1b[1m';

    // Check if stderr supports ANSI
    final useColor = _supportsAnsiColors();

    String colored(String text, String color) {
      return useColor ? '$color$text$reset' : text;
    }

    stderr.writeln();
    stderr.writeln(colored('  PANIC  ', '$bold$red'));
    stderr.writeln();

    // Exception type and message
    final errorType = error.runtimeType.toString();
    final errorMessage = error.toString();

    stderr.writeln(colored('  $errorType', '$bold$yellow'));
    stderr.writeln();

    // Exception message lines
    final messageLines = errorMessage.split('\n');
    for (final line in messageLines) {
      stderr.writeln('  ${colored(line, yellow)}');
    }

    // Stack trace
    if (stackTrace != null) {
      stderr.writeln();
      stderr.writeln(colored('  Stack trace:', dim));
      stderr.writeln();

      final lines = stackTrace.toString().split('\n');
      var frameCount = 0;

      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        if (frameCount >= _options.maxStackFrames) {
          stderr.writeln(colored('  ... and more frames', dim));
          break;
        }

        // Parse and format stack frame
        // Format: #0      functionName (package:path/file.dart:line:col)
        final match = RegExp(r'#(\d+)\s+(\S+)\s+\((.+)\)').firstMatch(line);
        if (match != null) {
          final number = match.group(1)!.padLeft(2);
          final member = match.group(2)!;
          final location = match.group(3)!;

          stderr.writeln('  ${colored(number, dim)}  ${colored(member, cyan)}');
          stderr.writeln('      ${colored(location, dim)}');
          frameCount++;
        } else {
          // Fallback for non-standard format
          stderr.writeln('  ${colored(line.trim(), dim)}');
          frameCount++;
        }
      }
    }

    stderr.writeln();
  }

  /// Checks if the terminal supports ANSI color codes.
  bool _supportsAnsiColors() {
    try {
      // Check NO_COLOR environment variable (https://no-color.org/)
      if (io.Platform.environment.containsKey('NO_COLOR')) {
        return false;
      }

      // Check stderr for ANSI support
      return io.stderr.supportsAnsiEscapes;
    } catch (_) {
      return false;
    }
  }

  /// Sets up the terminal and renderer.
  Future<void> _setup() async {
    // Create terminal if not provided.
    //
    // If inputTTY is requested, we try to split control/input from output:
    // - control: `/dev/tty` (raw mode, size probing, input reporting toggles)
    // - output: stdout (may be redirected)
    if (_terminal == null && _options.inputTTY) {
      final control = TtyTerminal.tryOpen();
      if (control != null) {
        _terminal = SplitTerminal(control: control, output: StdioTerminal());
      } else {
        _terminal = StdioTerminal();
      }
    } else {
      _terminal ??= StdioTerminal();
    }

    // Enable raw mode for character-by-character input
    _terminal!.enableRawMode();

    // Set startup title if provided
    if (_options.startupTitle != null) {
      _terminal!.write('\x1b]0;${_options.startupTitle}\x07');
    }

    // Set up renderer based on options
    final rendererOptions = TuiRendererOptions(
      fps: _options.fps,
      altScreen: _options.altScreen && !_options.disableRenderer,
      hideCursor: _options.hideCursor && !_options.disableRenderer,
      ansiCompress: _options.ansiCompress,
    );

    if (_options.disableRenderer) {
      _renderer = SimpleTuiRenderer(
        terminal: _terminal!,
        options: rendererOptions,
      );
    } else if (_options.useUltravioletRenderer) {
      _renderer = UltravioletTuiRenderer(
        terminal: _terminal!,
        options: rendererOptions,
      );
    } else if (_options.altScreen) {
      _renderer = FullScreenTuiRenderer(
        terminal: _terminal!,
        options: rendererOptions,
      );
    } else {
      _renderer = InlineTuiRenderer(
        terminal: _terminal!,
        options: rendererOptions,
      );
    }

    // Enable mouse tracking if requested
    _applyMouseMode();

    // Enable bracketed paste if requested
    if (_options.bracketedPaste) {
      _terminal!.enableBracketedPaste();
    }

    // Set up signal handlers (if enabled)
    if (_options.signalHandlers) {
      _setupSignalHandlers();
    }

    // Start listening for input
    _startInputListener();
  }

  /// Initializes the model and renders initial view.
  Future<void> _initialize() async {
    _model = _initialModel;

    // If we're using UV input decoding, probe terminal emoji width before we
    // render anything. The UV renderer relies on correct cell widths to avoid
    // overwriting graphemes during incremental updates.
    await _runStartupProbesIfNeeded();

    // Send initial window size
    final size = _terminal!.size;
    _processMessage(WindowSizeMsg(size.width, size.height));

    // Send initial color profile
    _processMessage(ColorProfileMsg(_terminal!.colorProfile));

    // Render initial view
    _render();

    _startupProbes?.drain(_processMessage);

    // Start metrics timer
    _startMetricsTimer();

    // Start frame tick timer for automatic animation updates
    _startFrameTickTimer();

    // Execute init command
    final initCmd = _model!.init();
    if (initCmd != null) {
      await _executeCommand(initCmd);
    }
  }

  /// Starts a periodic timer to send render metrics to the model.
  void _startMetricsTimer() {
    if (_options.metricsInterval <= Duration.zero) return;

    _metricsTimer = Timer.periodic(_options.metricsInterval, (_) {
      final metrics = _renderer?.metrics;
      if (metrics != null) {
        send(RenderMetricsMsg(metrics));
      }
    });
  }

  /// Starts the automatic frame tick timer.
  ///
  /// When [ProgramOptions.frameTick] is enabled, this sends [FrameTickMsg]
  /// at regular intervals based on the configured [ProgramOptions.fps].
  void _startFrameTickTimer() {
    if (!_options.frameTick) return;

    // Calculate interval from fps
    final intervalMs = (1000 / _options.fps).round();
    final interval = Duration(milliseconds: intervalMs);

    // Initialize frame tick state
    _frameNumber = 0;
    _lastFrameTime = DateTime.now();

    _frameTickTimer = Timer.periodic(interval, (_) {
      if (!_running) return;

      final now = DateTime.now();
      final delta = _lastFrameTime != null
          ? now.difference(_lastFrameTime!)
          : interval;

      _frameNumber++;
      _lastFrameTime = now;

      send(FrameTickMsg(time: now, frameNumber: _frameNumber, delta: delta));
    });
  }

  /// Sets up signal handlers for graceful shutdown and resize.
  void _setupSignalHandlers() {
    // Handle Ctrl+C (SIGINT)
    try {
      _sigintSubscription = io.ProcessSignal.sigint.watch().listen((_) {
        if (_options.sendInterrupt) {
          // Send InterruptMsg for explicit interrupt handling
          send(const InterruptMsg());
        } else {
          // Send Ctrl+C as a key message for backward compatibility
          send(const KeyMsg(Key(KeyType.runes, runes: [0x63], ctrl: true)));
        }
      });
    } catch (_) {
      // Signal handling not supported on this platform
    }

    // Handle window resize (SIGWINCH) - Unix only
    try {
      _sigwinchSubscription = io.ProcessSignal.sigwinch.watch().listen((_) {
        final size = _terminal!.size;
        send(WindowSizeMsg(size.width, size.height));
      });
    } catch (_) {
      // SIGWINCH not available on this platform
    }
  }

  /// Starts listening for terminal input.
  void _startInputListener() {
    // Use custom input stream if provided, otherwise use terminal input
    final inputStream =
        _options.input ??
        ((_options.inputTTY &&
                _terminal is! TtyTerminal &&
                _terminal is! SplitTerminal)
            ? _openTtyInput()
            : null) ??
        _terminal!.input;
    _inputSubscription = inputStream.listen(
      _handleInput,
      onError: (error) {
        // Avoid direct stdout writes while a TUI is running (UV renderer will
        // desync). Best-effort: surface the issue via the program pipeline.
        scheduleMicrotask(() {
          if (!_running) return;
          send(PrintLineMsg('Input error: $error'));
        });
      },
    );
  }

  Stream<List<int>>? _openTtyInput() {
    try {
      if (io.Platform.isWindows) return null;
      final tty = io.File('/dev/tty');
      if (tty.existsSync()) {
        return tty.openRead();
      }
    } catch (_) {
      // ignore failures, will fall back to default input
    }
    return null;
  }

  /// Handles raw input bytes from the terminal.
  void _handleInput(List<int> bytes) {
    if (_options.useUltravioletInputDecoder) {
      _uvInputTimeoutTimer?.cancel();

      final msgs = _uvInputParser.parseAll(bytes, expired: false);
      for (final msg in msgs) {
        send(msg);
      }

      if (_uvInputParser.hasPending) {
        _uvInputTimeoutTimer = Timer(_options.inputTimeout, () {
          if (!_running) return;
          final flushed = _uvInputParser.parseAll(const [], expired: true);
          for (final msg in flushed) {
            send(msg);
          }
        });
      }
      return;
    }

    // Parse bytes into keys and other messages (mouse, focus, paste)
    final results = _keyParser.parseAll(bytes);

    // Send each result as a message
    for (final result in results) {
      switch (result) {
        case KeyResult(:final key):
          send(KeyMsg(key));
        case MsgResult(:final msg):
          send(msg);
      }
    }
  }

  Future<void> _runStartupProbesIfNeeded() async {
    if (_options.disableRenderer) return;
    if (!_options.useUltravioletRenderer) return;
    if (!_options.useUltravioletInputDecoder) return;
    // Avoid messing with normal terminal output in inline mode. Users can
    // always override via UV_EMOJI_WIDTH/EMOJI_WIDTH if needed.
    if (!_options.altScreen) return;
    final term = _terminal;
    if (term == null) return;
    if (!term.supportsAnsi || !term.isTerminal) return;

    // Allow explicit override via environment (skip probing).
    final override =
        io.Platform.environment['UV_EMOJI_WIDTH'] ??
        io.Platform.environment['EMOJI_WIDTH'];
    if (override != null) {
      final v = int.tryParse(override.trim());
      if (v != null) uni_width.setEmojiPresentationWidth(v);
      return;
    }

    final ctx = StartupProbeContext(terminal: term);
    _startupProbeContext = ctx;

    // For now, only emoji-width probing is wired, but this runner makes it easy
    // to add other one-shot terminal capability probes later.
    final runner = StartupProbeRunner([EmojiWidthProbe()]);
    _startupProbes = runner;
    await runner.runAll(ctx);
  }

  /// Sends a message to the program.
  ///
  /// The message will be processed through [Model.update] and
  /// the view will be re-rendered.
  ///
  /// This can be called from outside the program to inject messages.
  void send(Msg msg) {
    if (!_running) return;
    _processMessage(msg);
  }

  /// Processes a message through the model.
  void _processMessage(Msg msg) {
    if (_model == null) return;

    final probes = _startupProbes;
    final probeCtx = _startupProbeContext;
    if (probes != null && probeCtx != null) {
      if (probes.intercept(msg, probeCtx)) return;
    }

    // Handle View-specific mouse interception
    if (msg is MouseMsg && _lastView?.onMouse != null) {
      final cmd = _lastView!.onMouse!(msg);
      if (cmd != null) {
        _executeCommand(cmd);
      }
    }

    // Apply message filter if configured
    if (_options.filter != null) {
      final filteredMsg = _options.filter!(_model!, msg);
      if (filteredMsg == null) {
        // Message was filtered out
        return;
      }
      msg = filteredMsg;
    }

    // Handle quit message
    if (msg is QuitMsg) {
      _quit();
      return;
    }

    // Handle repaint message
    if (msg is RepaintMsg) {
      _forceRender();
      return;
    }

    // Handle batch message
    if (msg is BatchMsg) {
      for (final m in msg.messages) {
        _processMessage(m);
      }
      return;
    }

    // Handle internal control messages
    if (_handleControlMessage(msg)) {
      return;
    }

    // Update model
    final (newModel, cmd) = _model!.update(msg);
    _model = newModel as M;

    // Re-render
    _render();

    // Execute command
    if (cmd != null) {
      _executeCommand(cmd);
    }
  }

  /// Handles internal control messages.
  /// Returns true if the message was handled internally.
  bool _handleControlMessage(Msg msg) {
    switch (msg) {
      case SetWindowTitleMsg(:final title):
        _terminal?.write('\x1b]0;$title\x07');
        return true;

      case ClearScreenMsg():
        _terminal?.clearScreen();
        _render();
        return true;

      case EnterAltScreenMsg():
        _terminal?.enterAltScreen();
        return true;

      case ExitAltScreenMsg():
        _terminal?.exitAltScreen();
        return true;

      case ShowCursorMsg():
        _terminal?.showCursor();
        return true;

      case HideCursorMsg():
        _terminal?.hideCursor();
        return true;

      case EnableMouseCellMotionMsg():
        _terminal?.enableMouse();
        return true;

      case EnableMouseAllMotionMsg():
        // Enable all motion tracking (1003 mode)
        if (_terminal?.supportsAnsi ?? false) {
          _terminal?.write('\x1b[?1003h');
          _terminal?.write('\x1b[?1006h'); // SGR mode
        }
        return true;

      case DisableMouseMsg():
        _terminal?.disableMouse();
        return true;

      case EnableBracketedPasteMsg():
        _terminal?.enableBracketedPaste();
        return true;

      case DisableBracketedPasteMsg():
        _terminal?.disableBracketedPaste();
        return true;

      case EnableReportFocusMsg():
        if (_terminal?.supportsAnsi ?? false) {
          _terminal?.write('\x1b[?1004h');
        }
        return true;

      case DisableReportFocusMsg():
        if (_terminal?.supportsAnsi ?? false) {
          _terminal?.write('\x1b[?1004l');
        }
        return true;

      case RequestWindowSizeMsg():
        final size = _terminal?.size ?? (width: 80, height: 24);
        // Send the window size message to the model
        final (newModel, cmd) = _model!.update(
          WindowSizeMsg(size.width, size.height),
        );
        _model = newModel as M;
        _render();
        if (cmd != null) {
          _executeCommand(cmd);
        }
        return true;

      case PrintLineMsg(:final text):
        // Print above the program.
        //
        // With the UV renderer this is implemented as a renderer-owned "print
        // line buffer" and is safe in both inline and fullscreen modes.
        //
        // For non-UV renderers we only support inline mode: fullscreen mode
        // has no stable "scrollback" concept to print into without changing
        // the view contract.
        final r = _renderer;
        if (r is UltravioletTuiRenderer) {
          r.printLine(text);
          final view = _model?.view() ?? '';
          final content = view is View ? view.content : view.toString();
          r.renderImmediate(content);
        } else if (!_options.altScreen) {
          _renderer?.clear();
          _terminal?.writeln(text);
          _render();
        }
        return true;

      case WriteRawMsg(:final data):
        _terminal?.write(data);
        unawaited(_terminal?.flush());
        return true;

      case SuspendMsg():
        _suspend();
        return true;

      case ExecProcessMsg(
        :final executable,
        :final arguments,
        :final onComplete,
        :final workingDirectory,
        :final environment,
      ):
        _executeExternalProcess(
          executable,
          arguments,
          onComplete,
          workingDirectory,
          environment,
        );
        return true;

      case RepaintRequestMsg(:final force):
        if (force) {
          _forceRender();
        } else {
          _render();
        }
        return true;

      default:
        return false;
    }
  }

  /// Executes an external process, releasing the terminal during execution.
  Future<void> _executeExternalProcess(
    String executable,
    List<String> arguments,
    Msg Function(ExecResult result) onComplete,
    String? workingDirectory,
    Map<String, String>? environment,
  ) async {
    // Release terminal for external process
    await _releaseTerminal();

    try {
      // Run the external process
      final process = await io.Process.run(
        executable,
        arguments,
        workingDirectory: workingDirectory,
        environment: environment,
        runInShell: io.Platform.isWindows,
      );

      // Restore terminal
      _restoreTerminal();

      // Send result message
      final result = ExecResult(
        exitCode: process.exitCode,
        stdout: process.stdout.toString(),
        stderr: process.stderr.toString(),
      );

      _processMessage(onComplete(result));
    } catch (e) {
      // Restore terminal even on error
      _restoreTerminal();

      // Send error result
      final result = ExecResult(exitCode: -1, stdout: '', stderr: e.toString());

      _processMessage(onComplete(result));
    }
  }

  /// Releases the terminal for external process execution.
  Future<void> _releaseTerminal() async {
    // Stop input listening temporarily.
    _uvInputTimeoutTimer?.cancel();
    _uvInputTimeoutTimer = null;
    _metricsTimer?.cancel();
    _metricsTimer = null;
    _uvInputParser.clear();

    try {
      await _inputSubscription?.cancel();
    } catch (_) {}
    _inputSubscription = null;

    // Dispose renderer (restores cursor, exits alt screen if needed)
    _renderer?.dispose();

    // Restore terminal to normal mode
    _terminal?.disableRawMode();
    _terminal?.showCursor();

    final mouseMode = _effectiveMouseMode();
    if (mouseMode != MouseMode.none) {
      _terminal?.disableMouse();
    }
    if (_options.bracketedPaste) {
      _terminal?.disableBracketedPaste();
    }
  }

  /// Restores the terminal after external process execution.
  void _restoreTerminal() {
    // Re-enable raw mode
    _terminal?.enableRawMode();

    // Restore options
    _applyMouseMode();
    if (_options.bracketedPaste) {
      _terminal?.enableBracketedPaste();
    }

    // Re-initialize renderer
    final rendererOptions = TuiRendererOptions(
      fps: _options.fps,
      altScreen: _options.altScreen && !_options.disableRenderer,
      hideCursor: _options.hideCursor && !_options.disableRenderer,
      ansiCompress: _options.ansiCompress,
    );

    if (_options.disableRenderer) {
      _renderer = SimpleTuiRenderer(
        terminal: _terminal!,
        options: rendererOptions,
      );
    } else if (_options.useUltravioletRenderer) {
      _renderer = UltravioletTuiRenderer(
        terminal: _terminal!,
        options: rendererOptions,
      );
    } else if (_options.altScreen) {
      _renderer = FullScreenTuiRenderer(
        terminal: _terminal!,
        options: rendererOptions,
      );
    } else {
      _renderer = InlineTuiRenderer(
        terminal: _terminal!,
        options: rendererOptions,
      );
    }

    // Restart input listening.
    if (_inputSubscription == null) {
      _startInputListener();
    }

    // Re-render
    _render();
  }

  MouseMode _effectiveMouseMode() {
    if (_options.mouseMode != MouseMode.none) return _options.mouseMode;
    return _options.mouse ? MouseMode.cellMotion : MouseMode.none;
  }

  void _applyMouseMode() {
    final mode = _effectiveMouseMode();
    switch (mode) {
      case MouseMode.none:
        break;
      case MouseMode.cellMotion:
        _terminal?.enableMouseCellMotion();
        break;
      case MouseMode.allMotion:
        _terminal?.enableMouseAllMotion();
        break;
    }
  }

  /// Suspends the program temporarily.
  void _suspend() {
    // Save terminal state
    _renderer?.dispose();

    // Stop input listening and timers temporarily.
    _uvInputTimeoutTimer?.cancel();
    _uvInputTimeoutTimer = null;
    _metricsTimer?.cancel();
    _metricsTimer = null;
    _uvInputParser.clear();
    unawaited(_inputSubscription?.cancel());
    _inputSubscription = null;

    // Restore terminal
    _terminal?.disableRawMode();
    _terminal?.showCursor();
    if (_options.altScreen) {
      _terminal?.exitAltScreen();
    }

    // Send SIGTSTP to suspend (Unix only)
    try {
      io.Process.killPid(io.pid, io.ProcessSignal.sigtstp);
    } catch (_) {
      // Suspend not supported on this platform
    }

    // When resumed, restore terminal state
    _terminal?.enableRawMode();
    if (_options.altScreen) {
      _terminal?.enterAltScreen();
    }
    if (_options.hideCursor) {
      _terminal?.hideCursor();
    }

    // Re-initialize renderer
    final rendererOptions = TuiRendererOptions(
      fps: _options.fps,
      altScreen: _options.altScreen && !_options.disableRenderer,
      hideCursor: _options.hideCursor && !_options.disableRenderer,
      ansiCompress: _options.ansiCompress,
    );
    if (_options.disableRenderer) {
      _renderer = SimpleTuiRenderer(
        terminal: _terminal!,
        options: rendererOptions,
      );
    } else if (_options.useUltravioletRenderer) {
      _renderer = UltravioletTuiRenderer(
        terminal: _terminal!,
        options: rendererOptions,
      );
    } else if (_options.altScreen) {
      _renderer = FullScreenTuiRenderer(
        terminal: _terminal!,
        options: rendererOptions,
      );
    } else {
      _renderer = InlineTuiRenderer(
        terminal: _terminal!,
        options: rendererOptions,
      );
    }

    // Restart input.
    _startInputListener();

    // Restart metrics timer.
    _startMetricsTimer();

    // Send resume message
    _processMessage(const ResumeMsg());
  }

  /// Renders the current view.
  void _render() {
    if (_model == null || _renderer == null) return;

    final view = _model!.view();

    if (view is View) {
      _lastView = view;
      _applyViewMetadata(view);
    } else {
      _lastView = null;
    }

    _renderer!.render(view);
    // Ensure the underlying sink paints promptly. Some terminals (and Dart IO
    // implementations) may buffer output until an explicit flush, and the UV
    // renderer in particular emits bytes through an intermediate writer.
    unawaited(_renderer!.flush());
  }

  /// Applies metadata from a [View] object to the terminal state.
  void _applyViewMetadata(View view) {
    if (view.windowTitle != null) {
      _terminal?.setTitle(view.windowTitle!);
    }

    if (view.backgroundColor != null) {
      // OSC 11
      _terminal?.write('\x1b]11;${view.backgroundColor!.toHex()}\x07');
    }

    if (view.foregroundColor != null) {
      // OSC 10
      _terminal?.write('\x1b]10;${view.foregroundColor!.toHex()}\x07');
    }

    if (view.progressBar != null) {
      _terminal?.setProgressBar(
        view.progressBar!.state.index,
        view.progressBar!.value,
      );
    }

    if (view.altScreen != null) {
      if (view.altScreen!) {
        _terminal?.enterAltScreen();
      } else {
        _terminal?.exitAltScreen();
      }
    }

    if (view.reportFocus != null) {
      if (view.reportFocus!) {
        _terminal?.enableFocusReporting();
      } else {
        _terminal?.disableFocusReporting();
      }
    }

    if (view.bracketedPaste != null) {
      if (view.bracketedPaste!) {
        _terminal?.enableBracketedPaste();
      } else {
        _terminal?.disableBracketedPaste();
      }
    }

    if (view.mouseMode != null) {
      switch (view.mouseMode!) {
        case MouseMode.none:
          _terminal?.disableMouse();
        case MouseMode.cellMotion:
          _terminal?.enableMouseCellMotion();
        case MouseMode.allMotion:
          _terminal?.enableMouseAllMotion();
      }
    }

    if (view.keyboardEnhancements != null) {
      var flags = Ansi.kittyDisambiguateEscapeCodes;
      if (view.keyboardEnhancements!.reportEventTypes) {
        flags |= Ansi.kittyReportEventTypes;
      }
      _terminal?.write(Ansi.kittyKeyboard(flags, mode: 1));
      _terminal?.write(Ansi.requestKittyKeyboard);
    }

    if (view.cursor != null) {
      // Move cursor to position
      _terminal?.moveCursor(
        view.cursor!.position.y + 1,
        view.cursor!.position.x + 1,
      );
      // Set shape and blink
      final code = view.cursor!.shape.encode(blink: view.cursor!.blink);
      _terminal?.write('\x1b[$code q');
      // Set color if provided
      if (view.cursor!.color != null) {
        _terminal?.write('\x1b]12;${view.cursor!.color!.toHex()}\x07');
      }
    }
  }

  /// Forces a re-render, bypassing the skip-if-unchanged optimization.
  void _forceRender() {
    if (_model == null || _renderer == null) return;

    // Clear the renderer's cached view to force a full redraw
    _renderer!.clear();
    final view = _model!.view();

    if (view is View) {
      _lastView = view;
      _applyViewMetadata(view);
    } else {
      _lastView = null;
    }

    _renderer!.render(view);
    unawaited(_renderer!.flush());
  }

  /// Executes a command.
  Future<void> _executeCommand(Cmd cmd) async {
    // Handle special command types
    if (cmd is StreamCmd) {
      _streamCommands.add(cmd);
      cmd.start(send);
      return;
    }

    if (cmd is EveryCmd) {
      _everyCommands.add(cmd);
      cmd.start(send);
      return;
    }

    // Execute regular command
    try {
      final msg = await cmd.execute();
      if (msg != null && _running) {
        _processMessage(msg);
      }
    } catch (e, st) {
      // If panic catching is enabled, store and quit
      // Otherwise, rethrow
      if (_options.catchPanics) {
        _panic = e;
        _panicStackTrace = st;
        _quit();
      } else {
        rethrow;
      }
    }
  }

  /// Triggers program quit.
  void _quit() {
    if (!_running) return;
    final completer = _runCompleter;
    if (completer == null || completer.isCompleted) return;
    completer.complete();
  }

  /// Requests the program to quit.
  ///
  /// This is equivalent to the model returning [Cmd.quit()].
  void quit() {
    send(const QuitMsg());
  }

  /// Whether the program was killed (vs graceful quit).
  bool _killed = false;

  /// Returns true if the program was terminated via [kill] rather than [quit].
  ///
  /// This can be used to differentiate between graceful shutdown and
  /// immediate termination after the program exits.
  bool get wasKilled => _killed;

  /// Immediately terminates the program without a final render.
  ///
  /// Unlike [quit], which sends a [QuitMsg] through the normal message
  /// processing pipeline, [kill] immediately stops the program and
  /// skips the final render.
  ///
  /// Use this when you need to terminate immediately, such as:
  /// - Handling a fatal error
  /// - Responding to an external shutdown signal
  /// - Timeout scenarios
  void kill() {
    if (!_running) return;
    _killed = true;
    final completer = _runCompleter;
    if (completer == null || completer.isCompleted) return;
    completer.complete();
  }

  /// Returns a [Future] that completes when the program exits.
  ///
  /// This is useful when you need to wait for the program to finish
  /// from outside code, such as in tests or when embedding the TUI
  /// in a larger application.
  ///
  /// ```dart
  /// final program = Program(MyModel());
  ///
  /// // Start the program
  /// final runFuture = program.run();
  ///
  /// // Later, wait for it to complete
  /// await program.wait();
  /// ```
  Future<void> wait() async {
    if (!_running) return;
    await _runCompleter?.future;
  }

  /// Prints a line of text above the TUI output.
  ///
  /// This only works in inline mode (non-alt-screen). In fullscreen
  /// mode, this method does nothing.
  ///
  /// The text is printed immediately and persists across re-renders.
  ///
  /// ```dart
  /// program.println('Loading complete!');
  /// ```
  void println(String text) {
    if (!_running || _options.altScreen) return;
    send(PrintLineMsg(text));
  }

  /// Prints formatted text above the TUI output.
  ///
  /// This only works in inline mode (non-alt-screen). In fullscreen
  /// mode, this method does nothing.
  ///
  /// ```dart
  /// program.printf('Loaded %d items', [items.length]);
  /// ```
  void printf(String format, List<Object?> args) {
    if (!_running || _options.altScreen) return;

    // Simple printf-style formatting
    var result = format;
    for (final arg in args) {
      result = result.replaceFirst(
        RegExp(r'%[sdifxXobeEgGaAcsp%]'),
        arg.toString(),
      );
    }
    println(result);
  }

  /// Forces a repaint of the current view.
  ///
  /// This bypasses the skip-if-unchanged optimization and forces
  /// a full re-render of the current view.
  ///
  /// Useful when:
  /// - External factors have changed the terminal state
  /// - The view needs to be refreshed due to resize
  /// - Recovering from display corruption
  void forceRepaint() {
    if (!_running) return;
    _forceRender();
  }

  /// Cleans up resources and restores terminal state.
  ///
  /// This method is designed to be robust and always restore the terminal,
  /// even if some cleanup operations fail.
  Future<void> _cleanup() async {
    // Snapshot final model before clearing references
    _finalModel = _model;

    _uvInputTimeoutTimer?.cancel();
    _uvInputTimeoutTimer = null;
    _metricsTimer?.cancel();
    _metricsTimer = null;
    _frameTickTimer?.cancel();
    _frameTickTimer = null;
    _frameNumber = 0;
    _lastFrameTime = null;

    // Cancel input subscription
    try {
      await _inputSubscription?.cancel();
    } catch (_) {}
    _inputSubscription = null;
    try {
      await _cancelSubscription?.cancel();
    } catch (_) {}
    _cancelSubscription = null;

    // Cancel signal subscriptions
    try {
      await _sigintSubscription?.cancel();
    } catch (_) {}
    _sigintSubscription = null;

    try {
      await _sigwinchSubscription?.cancel();
    } catch (_) {}
    _sigwinchSubscription = null;

    // Stop stream commands
    for (final cmd in _streamCommands) {
      try {
        await cmd.cancel();
      } catch (_) {}
    }
    _streamCommands.clear();

    // Stop repeating commands
    for (final cmd in _everyCommands) {
      try {
        cmd.stop();
      } catch (_) {}
    }
    _everyCommands.clear();

    // Clear key parser buffer
    try {
      _keyParser.clear();
    } catch (_) {}
    try {
      _uvInputParser.clear();
    } catch (_) {}
    _startupProbes = null;
    _startupProbeContext = null;

    // Dispose renderer (this should restore cursor/alt screen)
    try {
      _renderer?.dispose();
    } catch (_) {}
    _renderer = null;

    // Restore terminal state (belt and suspenders approach)
    // Even if renderer.dispose() failed, try to restore these
    try {
      if (_options.bracketedPaste) {
        _terminal?.disableBracketedPaste();
      }
    } catch (_) {}

    try {
      if (_options.mouse) {
        _terminal?.disableMouse();
      }
    } catch (_) {}

    // Final terminal cleanup
    try {
      _terminal?.dispose();
    } catch (_) {}
    _terminal = null;
    _model = null;

    if (_options.shutdownSharedStdinOnExit && isSharedStdinStreamStarted) {
      try {
        await shutdownSharedStdinStream();
      } catch (_) {}
    }
  }
}

/// Runs a TUI program with the given model.
///
/// Convenience function for simple programs:
///
/// ```dart
/// void main() async {
///   await runProgram(MyModel());
/// }
/// ```
Future<void> runProgram<M extends Model>(
  M model, {
  ProgramOptions options = const ProgramOptions(),
}) async {
  final program = Program<M>(model, options: options);
  await program.run();
}

/// Runs a TUI program and returns the final model after exit.
Future<M> runProgramWithResult<M extends Model>(
  M model, {
  ProgramOptions options = const ProgramOptions(),
}) async {
  final program = Program<M>(model, options: options);
  await program.run();
  return program.finalModel ?? model;
}

/// Runs a TUI program without panic catching (for debugging).
///
/// This is useful when you want exceptions to propagate normally
/// so a debugger can catch them.
///
/// ```dart
/// void main() async {
///   await runProgramDebug(MyModel());
/// }
/// ```
Future<void> runProgramDebug<M extends Model>(
  M model, {
  ProgramOptions? options,
}) async {
  final opts = (options ?? const ProgramOptions()).withoutCatchPanics();
  final program = Program<M>(model, options: opts);
  await program.run();
}
