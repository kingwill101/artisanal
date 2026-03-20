import 'dart:async';
import 'dart:collection';
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
import 'trace.dart';
import 'view.dart';
import '../layout/layout.dart' show Layout;
import '../style/color.dart' show Color, ColorProfile;
import 'background_color_probe.dart';
import 'uv_capability_probe.dart';
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
///   if (msg is InterruptMsg && model is MyModel && model.hasUnsavedChanges) {
///     // Block Ctrl+C and show a warning instead.
///     return const ShowUnsavedWarningMsg();
///   }
///   return msg; // Allow message through.
/// }
/// ```
typedef MessageFilter = Msg? Function(Model model, Msg msg);

/// Intercepts program messages and lifecycle events.
///
/// Use this to observe/transform queued messages, inject automation events,
/// and collect timing metrics for test harnesses.
abstract class ProgramInterceptor {
  /// Called once after program initialization.
  ///
  /// Use [send] to inject messages (for example, replay scripts).
  void onStart(void Function(Msg msg) send) {}

  /// Called for each message before it is queued.
  ///
  /// Return the same message to keep it, a modified message to transform it,
  /// or `null` to drop it.
  Msg? onSend(Msg msg) => msg;

  /// Called after a message has been processed.
  void onProcessed(Msg msg, Duration elapsed) {}

  /// Called during program cleanup.
  void onStop() {}
}

/// One replay step for [ProgramReplay.script].
final class ProgramReplayStep {
  const ProgramReplayStep({required this.after, required this.msg});

  /// Delay before [msg] is emitted.
  final Duration after;

  /// Message emitted after [after].
  final Msg msg;
}

/// Message replay source for [ProgramOptions.replay].
///
/// Use [ProgramReplay.stream] to reuse an existing stream or
/// [ProgramReplay.script] to define timed steps.
final class ProgramReplay {
  ProgramReplay.stream(Stream<Msg> messages) : _messages = messages;

  ProgramReplay.script(List<ProgramReplayStep> steps, {bool loop = false})
    : _messages = _scriptStream(steps, loop: loop);

  final Stream<Msg> _messages;

  Stream<Msg> toStream() => _messages;

  static Stream<Msg> _scriptStream(
    List<ProgramReplayStep> steps, {
    required bool loop,
  }) async* {
    if (steps.isEmpty) return;
    do {
      for (final step in steps) {
        if (step.after > Duration.zero) {
          await Future<void>.delayed(step.after);
        }
        yield step.msg;
      }
    } while (loop);
  }
}

/// Options for configuring the TUI program.
class ProgramOptions {
  static const Object _retainValue = Object();

  /// Creates program configuration options.
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
    this.interceptor,
    this.replay,
    this.blockInputWhileReplay = false,
    this.signalHandlers = true,
    this.sendInterrupt = true,
    this.sendSuspendSignal = true,
    this.startupTitle,
    this.input,
    this.output,
    this.disableRenderer = false,
    this.ansiCompress = false,
    this.useUltravioletRenderer = true,
    this.useUltravioletInputDecoder = true,
    this.startupProbes,
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
  ///
  /// This enables [MouseMode.cellMotion] unless [mouseMode] is set explicitly.
  /// Use [MouseMode.allMotion] for passive hover behavior such as tooltips,
  /// hover styling, and `MouseRegion` enter/exit callbacks that should fire
  /// without a mouse button being held.
  final bool mouse;

  /// Mouse tracking mode (none, cell motion, all motion).
  ///
  /// Takes precedence over [mouse]. When not [MouseMode.none],
  /// mouse tracking is enabled according to the chosen mode.
  ///
  /// Use [MouseMode.cellMotion] for click/drag interactions where pointer
  /// motion only matters while a button is pressed. Use [MouseMode.allMotion]
  /// for passive hover interactions.
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

  /// Optional interceptor hook for message automation and observability.
  final ProgramInterceptor? interceptor;

  /// Optional replay source used to inject messages automatically.
  final ProgramReplay? replay;

  /// Whether terminal input should be ignored while replay is active.
  ///
  /// When true, stdin key/mouse/paste events are dropped while the replay
  /// stream is emitting messages. Useful for deterministic profiling.
  final bool blockInputWhileReplay;

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
  /// When true (default), pressing Ctrl+C is delivered as an [InterruptMsg].
  /// This lets the model or widget tree handle terminal interrupts separately
  /// from ordinary keyboard shortcuts.
  ///
  /// When false, SIGINT is converted to a Ctrl+C [KeyMsg] for backward
  /// compatibility. Call [withoutInterruptMsg] to opt into that behavior.
  final bool sendInterrupt;

  /// Whether [SuspendMsg] should send `SIGTSTP` to the current process.
  ///
  /// When true (default), suspend behaves like a normal terminal app on Unix:
  /// the runtime releases the terminal and then sends `SIGTSTP`.
  ///
  /// When false, the runtime still executes the full release/restore suspend
  /// lifecycle but skips the OS-level suspend signal. This is useful for
  /// embedded hosts, tests, and environments that do not want to suspend the
  /// parent process.
  final bool sendSuspendSignal;

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

  /// Whether to run UV startup probes before and after the first render.
  ///
  /// When `true`, probes always run when the active terminal supports them.
  /// When `false`, probes are skipped entirely.
  ///
  /// When `null` (default), the runtime only auto-runs startup probes for the
  /// built-in terminal implementations that it knows how to interrogate
  /// safely. Arbitrary injected terminals are skipped unless they opt in.
  final bool? startupProbes;

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

  /// The interval at which render metrics are reported to the model.
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
    ProgramInterceptor? interceptor,
    ProgramReplay? replay,
    bool? blockInputWhileReplay,
    bool? signalHandlers,
    bool? sendInterrupt,
    bool? sendSuspendSignal,
    String? startupTitle,
    Stream<List<int>>? input,
    void Function(String)? output,
    bool? disableRenderer,
    bool? ansiCompress,
    bool? useUltravioletRenderer,
    bool? useUltravioletInputDecoder,
    bool? startupProbes,
    Future<void>? cancelSignal,
    List<String>? environment,
    bool? inputTTY,
    ({bool useTabs, bool useBackspace})? movementCapsOverride,
    bool? shutdownSharedStdinOnExit,
    Duration? metricsInterval,
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
      interceptor: interceptor ?? this.interceptor,
      replay: replay ?? this.replay,
      blockInputWhileReplay:
          blockInputWhileReplay ?? this.blockInputWhileReplay,
      signalHandlers: signalHandlers ?? this.signalHandlers,
      sendInterrupt: sendInterrupt ?? this.sendInterrupt,
      sendSuspendSignal: sendSuspendSignal ?? this.sendSuspendSignal,
      startupTitle: startupTitle ?? this.startupTitle,
      input: input ?? this.input,
      output: output ?? this.output,
      disableRenderer: disableRenderer ?? this.disableRenderer,
      ansiCompress: ansiCompress ?? this.ansiCompress,
      useUltravioletRenderer:
          useUltravioletRenderer ?? this.useUltravioletRenderer,
      useUltravioletInputDecoder:
          useUltravioletInputDecoder ?? this.useUltravioletInputDecoder,
      startupProbes: startupProbes ?? this.startupProbes,
      cancelSignal: cancelSignal ?? this.cancelSignal,
      environment: environment ?? this.environment,
      inputTTY: inputTTY ?? this.inputTTY,
      movementCapsOverride: movementCapsOverride ?? this.movementCapsOverride,
      shutdownSharedStdinOnExit:
          shutdownSharedStdinOnExit ?? this.shutdownSharedStdinOnExit,
      metricsInterval: metricsInterval ?? this.metricsInterval,
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
  ProgramOptions withoutFilter() => _copyClearingNullable(filter: null);

  /// Creates options with signal handlers disabled.
  ///
  /// The program will not install SIGINT or SIGWINCH handlers.
  ProgramOptions withoutSignalHandlers() => copyWith(signalHandlers: false);

  /// Creates options that send a Ctrl+C [KeyMsg] instead of [InterruptMsg].
  ///
  /// Use this when a model expects legacy key-based Ctrl+C handling.
  ProgramOptions withoutInterruptMsg() => copyWith(sendInterrupt: false);

  /// Creates options that skip the OS-level suspend signal during [SuspendMsg].
  ProgramOptions withoutSuspendSignal() => copyWith(sendSuspendSignal: false);

  /// Creates options with the given startup title.
  ProgramOptions withStartupTitle(String title) =>
      copyWith(startupTitle: title);

  /// Creates options with no startup title override.
  ProgramOptions withoutStartupTitle() =>
      _copyClearingNullable(startupTitle: null);

  /// Creates options with startup probes forced on or off.
  ProgramOptions withStartupProbes(bool enabled) =>
      copyWith(startupProbes: enabled);

  /// Creates options that clear any explicit startup-probe override.
  ///
  /// After calling this helper, startup probing returns to the default
  /// terminal-driven auto behavior.
  ProgramOptions withoutStartupProbeOverride() =>
      _copyClearingNullable(startupProbes: null);

  /// Creates options with custom input stream.
  ProgramOptions withInput(Stream<List<int>> input) => copyWith(input: input);

  /// Creates options with custom input cleared.
  ProgramOptions withoutInput() => _copyClearingNullable(input: null);

  /// Creates options with custom output function.
  ProgramOptions withOutput(void Function(String) output) =>
      copyWith(output: output);

  /// Creates options with custom output cleared.
  ProgramOptions withoutOutput() => _copyClearingNullable(output: null);

  /// Creates options with the given interceptor.
  ProgramOptions withInterceptor(ProgramInterceptor interceptor) =>
      copyWith(interceptor: interceptor);

  /// Creates options with a replay source.
  ProgramOptions withReplay(ProgramReplay replay) => copyWith(replay: replay);

  /// Creates options with replay input blocking enabled/disabled.
  ProgramOptions withReplayInputBlocking(bool enabled) =>
      copyWith(blockInputWhileReplay: enabled);

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

  /// Creates options with replay disabled.
  ProgramOptions withoutReplay() => _copyClearingNullable(replay: null);

  /// Creates options with interceptor disabled.
  ProgramOptions withoutInterceptor() =>
      _copyClearingNullable(interceptor: null);

  /// Creates options with no external cancellation signal.
  ProgramOptions withoutCancelSignal() =>
      _copyClearingNullable(cancelSignal: null);

  /// Creates options with no movement capability override.
  ProgramOptions withoutMovementCapsOverride() =>
      _copyClearingNullable(movementCapsOverride: null);

  ProgramOptions _copyClearingNullable({
    Object? filter = _retainValue,
    Object? interceptor = _retainValue,
    Object? replay = _retainValue,
    Object? startupTitle = _retainValue,
    Object? input = _retainValue,
    Object? output = _retainValue,
    Object? startupProbes = _retainValue,
    Object? cancelSignal = _retainValue,
    Object? movementCapsOverride = _retainValue,
  }) {
    return ProgramOptions(
      altScreen: altScreen,
      mouse: mouse,
      mouseMode: mouseMode,
      fps: fps,
      frameTick: frameTick,
      hideCursor: hideCursor,
      bracketedPaste: bracketedPaste,
      inputTimeout: inputTimeout,
      catchPanics: catchPanics,
      maxStackFrames: maxStackFrames,
      filter:
          identical(filter, _retainValue)
              ? this.filter
              : filter as MessageFilter?,
      interceptor:
          identical(interceptor, _retainValue)
              ? this.interceptor
              : interceptor as ProgramInterceptor?,
      replay:
          identical(replay, _retainValue)
              ? this.replay
              : replay as ProgramReplay?,
      blockInputWhileReplay: blockInputWhileReplay,
      signalHandlers: signalHandlers,
      sendInterrupt: sendInterrupt,
      sendSuspendSignal: sendSuspendSignal,
      startupTitle:
          identical(startupTitle, _retainValue)
              ? this.startupTitle
              : startupTitle as String?,
      input:
          identical(input, _retainValue)
              ? this.input
              : input as Stream<List<int>>?,
      output:
          identical(output, _retainValue)
              ? this.output
              : output as void Function(String)?,
      disableRenderer: disableRenderer,
      ansiCompress: ansiCompress,
      useUltravioletRenderer: useUltravioletRenderer,
      useUltravioletInputDecoder: useUltravioletInputDecoder,
      startupProbes:
          identical(startupProbes, _retainValue)
              ? this.startupProbes
              : startupProbes as bool?,
      cancelSignal:
          identical(cancelSignal, _retainValue)
              ? this.cancelSignal
              : cancelSignal as Future<void>?,
      environment: environment,
      inputTTY: inputTTY,
      movementCapsOverride:
          identical(movementCapsOverride, _retainValue)
              ? this.movementCapsOverride
              : movementCapsOverride as ({bool useTabs, bool useBackspace})?,
      shutdownSharedStdinOnExit: shutdownSharedStdinOnExit,
      metricsInterval: metricsInterval,
    );
  }
}

/// Resolves a reusable launch target for a [Program].
///
/// Hosts package the terminal/backend choice separately from the model and
/// other runtime options so callers can reuse the same launch surface across
/// local stdio, split-TTY, embedded, or future remote backends.
typedef ProgramHostResolver =
    ProgramHostBinding Function(ProgramOptions options);

/// Resolved runtime configuration produced by a [ProgramHost].
///
/// The [options] value should be treated as the final runtime options after
/// any host-specific adjustments. When [terminal] is omitted, [Program] falls
/// back to its built-in stdio terminal selection.
final class ProgramHostBinding {
  /// Creates a resolved host binding.
  const ProgramHostBinding({required this.options, this.terminal});

  /// Final runtime options after host adjustments.
  final ProgramOptions options;

  /// Optional terminal implementation to use for the run.
  final TuiTerminal? terminal;
}

/// Reusable launch target for a [Program].
///
/// Use [ProgramHost] to package backend selection separately from model logic.
/// The current runtime supports:
///
/// - [ProgramHost.stdio] for the built-in stdio host
/// - [ProgramHost.backend] for backend-driven embedded/native hosts
/// - [ProgramHost.bridge] for ergonomic embedded/web bridge hosts
/// - [ProgramHost.jsonChannel] for message-oriented JSON transports
/// - [ProgramHost.webSocket] for websocket JSON bridge hosts
/// - [ProgramHost.terminal] for an already-created terminal
/// - [ProgramHost.split] for separate control/output terminals
/// - [ProgramHost.custom] for embedding adapters and future backends
abstract interface class ProgramHost {
  /// Creates a stdio-backed host.
  ///
  /// Set [inputTTY] when the app should read input from `/dev/tty` even if
  /// stdin is redirected.
  factory ProgramHost.stdio({bool inputTTY = false}) =>
      _StdioProgramHost(inputTTY: inputTTY);

  /// Creates a host backed by [backend].
  factory ProgramHost.backend(TerminalBackend backend) =>
      _BackendProgramHost(backend);

  /// Creates a host backed by [bridge].
  factory ProgramHost.bridge(TerminalBridge bridge) =>
      _BackendProgramHost(bridge.backend);

  /// Creates a host backed by a JSON message channel.
  factory ProgramHost.jsonChannel({
    required void Function(String message) sendMessage,
    required Stream<Object?> inboundMessages,
    Future<void> Function()? flushMessages,
    Future<void> Function()? closeTransport,
    TerminalDimensions initialSize = const (width: 80, height: 24),
    bool supportsAnsi = true,
    bool isTerminal = true,
    ColorProfile colorProfile = ColorProfile.trueColor,
    ({bool useTabs, bool useBackspace}) movementCaps = const (
      useTabs: false,
      useBackspace: true,
    ),
  }) => _BackendProgramHost(
    JsonTerminalBackend(
      sendMessage: sendMessage,
      inboundMessages: inboundMessages,
      flushMessages: flushMessages,
      closeTransport: closeTransport,
      initialSize: initialSize,
      supportsAnsi: supportsAnsi,
      isTerminal: isTerminal,
      colorProfile: colorProfile,
      movementCaps: movementCaps,
    ),
  );

  /// Creates a websocket-backed host using the JSON bridge protocol.
  factory ProgramHost.webSocket(
    io.WebSocket socket, {
    TerminalDimensions initialSize = const (width: 80, height: 24),
    bool supportsAnsi = true,
    bool isTerminal = true,
    ColorProfile colorProfile = ColorProfile.trueColor,
    ({bool useTabs, bool useBackspace}) movementCaps = const (
      useTabs: false,
      useBackspace: true,
    ),
    bool closeSocketOnDispose = true,
  }) => _BackendProgramHost(
    WebSocketTerminalBackend(
      socket,
      initialSize: initialSize,
      supportsAnsi: supportsAnsi,
      isTerminal: isTerminal,
      colorProfile: colorProfile,
      movementCaps: movementCaps,
      closeSocketOnDispose: closeSocketOnDispose,
    ),
  );

  /// Creates a socket-backed host for remote or shell-mode terminals.
  factory ProgramHost.socket(
    io.Socket socket, {
    TerminalDimensions initialSize = const (width: 80, height: 24),
    bool supportsAnsi = true,
    ColorProfile colorProfile = ColorProfile.trueColor,
    bool closeSocketOnDispose = true,
  }) => _BackendProgramHost(
    SocketTerminalBackend(
      socket,
      initialSize: initialSize,
      supportsAnsi: supportsAnsi,
      colorProfile: colorProfile,
      closeSocketOnDispose: closeSocketOnDispose,
    ),
  );

  /// Creates a host that always uses [terminal].
  factory ProgramHost.terminal(TuiTerminal terminal) =>
      _TerminalProgramHost(terminal);

  /// Creates a split host with separate [control] and [output] terminals.
  factory ProgramHost.split({
    required TuiTerminal control,
    required TuiTerminal output,
  }) => _SplitProgramHost(control: control, output: output);

  /// Creates a custom host using [resolver].
  factory ProgramHost.custom(ProgramHostResolver resolver) =>
      _CustomProgramHost(resolver);

  /// Resolves the host against [options].
  ProgramHostBinding resolve(ProgramOptions options);
}

final class _StdioProgramHost implements ProgramHost {
  const _StdioProgramHost({this.inputTTY = false});

  final bool inputTTY;

  @override
  ProgramHostBinding resolve(ProgramOptions options) {
    return ProgramHostBinding(
      options: options.copyWith(inputTTY: inputTTY || options.inputTTY),
    );
  }
}

final class _TerminalProgramHost implements ProgramHost {
  const _TerminalProgramHost(this.terminal);

  final TuiTerminal terminal;

  @override
  ProgramHostBinding resolve(ProgramOptions options) {
    return ProgramHostBinding(
      // A supplied terminal should own its own input source.
      options: options.copyWith(inputTTY: false),
      terminal: terminal,
    );
  }
}

final class _BackendProgramHost implements ProgramHost {
  const _BackendProgramHost(this.backend);

  final TerminalBackend backend;

  @override
  ProgramHostBinding resolve(ProgramOptions options) {
    return ProgramHostBinding(
      options: options.copyWith(inputTTY: false),
      terminal: BackendTerminal(backend),
    );
  }
}

final class _SplitProgramHost implements ProgramHost {
  const _SplitProgramHost({required this.control, required this.output});

  final TuiTerminal control;
  final TuiTerminal output;

  @override
  ProgramHostBinding resolve(ProgramOptions options) {
    return ProgramHostBinding(
      // Split terminals already provide the control/input path.
      options: options.copyWith(inputTTY: false),
      terminal: SplitTerminal(control: control, output: output),
    );
  }
}

final class _CustomProgramHost implements ProgramHost {
  const _CustomProgramHost(this.resolver);

  final ProgramHostResolver resolver;

  @override
  ProgramHostBinding resolve(ProgramOptions options) => resolver(options);
}

ProgramHostBinding _resolveProgramHost({
  required ProgramOptions options,
  ProgramHost? host,
  TuiTerminal? terminal,
}) {
  assert(
    host == null || terminal == null,
    'Provide either a ProgramHost or a terminal, not both.',
  );
  if (host == null) {
    return ProgramHostBinding(options: options, terminal: terminal);
  }
  final binding = host.resolve(options);
  return ProgramHostBinding(options: binding.options, terminal: binding.terminal);
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
    M initialModel, {
    ProgramOptions options = const ProgramOptions(),
    ProgramHost? host,
    TuiTerminal? terminal,
  }) : this._resolved(
         initialModel,
         _resolveProgramHost(options: options, host: host, terminal: terminal),
       );

  Program._resolved(this._initialModel, ProgramHostBinding binding)
    : _options = binding.options,
      _terminal = binding.terminal;

  final M _initialModel;
  final ProgramOptions _options;
  TuiTerminal? _terminal;

  /// The current model state.
  M? _model;

  /// The last view object returned by the model.
  View? _lastView;

  /// The last view object returned by model.view(), used for identity-based
  /// skip in _render() to avoid the full ANSI-parse/draw/diff pipeline
  /// when the model returned the exact same cached object.
  Object? _lastRenderedView;

  /// Terminal size at the last successful render.
  ///
  /// Even when the model returns the same view object, a window resize must
  /// still trigger rendering so the renderer can resize/reflow buffers.
  int? _lastRenderWidth;
  int? _lastRenderHeight;

  /// Last window size dispatched to the model from passive resize sources.
  int? _lastWindowSizeWidth;
  int? _lastWindowSizeHeight;

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
  StreamSubscription<Msg>? _replaySubscription;
  bool _replayActive = false;
  StreamSubscription<void>? _cancelSubscription;

  /// Active stream commands.
  final List<StreamCmd> _streamCommands = [];

  /// Active repeating commands.
  final List<EveryCmd> _everyCommands = [];

  /// Whether the program is running.
  bool _running = false;
  bool _cancelled = false;

  /// Message queue for sequential processing.
  final Queue<Msg> _messageQueue = Queue<Msg>();

  /// Whether we're currently processing a message (prevents reentrant calls).
  bool _processingMessage = false;

  int _traceMsgId = 0;
  DateTime? _lastQueuedKeyAt;
  DateTime? _lastProcessedKeyAt;
  int _traceRenderId = 0;
  int _renderGeneration = 0;

  /// Whether we're in the initialization phase (suppresses renders until init completes).
  bool _initializing = false;

  /// Whether init-command completions are being drained before the first frame.
  bool _drainingInitMessages = false;

  /// Whether a graceful quit should happen immediately after the first render.
  bool _quitAfterInitialRender = false;

  /// Messages deferred until after the first frame is painted.
  ///
  /// This is mainly for async init-time exec completions: the process may
  /// finish before the first render, but the initialized view should still
  /// paint once before completion logic runs.
  final List<Msg> _deferredUntilAfterInitialRender = <Msg>[];

  /// Whether cleanup has already been performed (prevents double cleanup).
  bool _cleanedUp = false;

  /// Whether the terminal background color was overridden via OSC 11.
  bool _bgColorOverridden = false;

  /// Whether the terminal foreground color was overridden via OSC 10.
  bool _fgColorOverridden = false;

  /// Whether the terminal cursor color was overridden via OSC 12.
  bool _cursorColorOverridden = false;

  /// Whether the terminal cursor style was overridden from the default block blink.
  bool _cursorStyleOverridden = false;

  /// Whether the terminal progress bar was overridden via OSC 9;4.
  bool _progressBarOverridden = false;

  /// Whether the terminal is temporarily released for exec/suspend.
  bool _terminalReleased = false;

  /// Sticky cursor visibility override requested by control messages.
  bool? _desiredCursorVisibilityOverride;
  bool? _appliedCursorVisibilityOverride;

  /// Monotonic token for released-terminal exec lifecycles.
  int _terminalReleaseGeneration = 0;

  /// The last window title this program believes it applied.
  String? _appliedWindowTitle;

  /// A window title requested while the terminal was temporarily released.
  String? _releasedWindowTitle;

  /// Desired mouse tracking mode for the current runtime/view state.
  MouseMode _desiredMouseMode = MouseMode.none;

  /// Mouse tracking mode currently applied to the terminal.
  MouseMode _appliedMouseMode = MouseMode.none;

  /// Whether bracketed paste should be enabled for the current runtime/view state.
  bool _desiredBracketedPaste = false;

  /// Whether bracketed paste is currently enabled on the terminal.
  bool _appliedBracketedPaste = false;

  /// Whether focus reporting should be enabled for the current runtime/view state.
  bool _desiredFocusReporting = false;

  /// Whether focus reporting is currently enabled on the terminal.
  bool _appliedFocusReporting = false;

  /// Desired kitty keyboard enhancement flags for the current runtime/view state.
  int _desiredKeyboardEnhancementFlags = 0;

  /// Kitty keyboard enhancement flags currently applied to the terminal.
  int _appliedKeyboardEnhancementFlags = 0;

  /// Persistent alt-screen state requested by control messages in inline mode.
  bool _commandAltScreenEnabled = false;

  /// Per-view alt-screen override for inline-mode programs.
  bool? _viewAltScreenOverride;

  /// Whether inline-mode dynamic alt-screen is currently active.
  bool _appliedDynamicAltScreen = false;

  /// Completer for the run() method.
  Completer<void>? _runCompleter;

  /// Final model snapshot captured during cleanup.
  M? _finalModel;

  /// Signal subscriptions.
  StreamSubscription<io.ProcessSignal>? _sigintSubscription;
  StreamSubscription<io.ProcessSignal>? _sigwinchSubscription;
  StreamSubscription<TerminalDimensions>? _backendResizeSubscription;
  StreamSubscription<void>? _backendShutdownSubscription;
  bool _backendShutdownRequested = false;

  /// Stored panic for re-throwing after cleanup.
  Object? _panic;
  StackTrace? _panicStackTrace;

  /// Errors that occurred during cleanup (for debugging).
  final List<Object> _cleanupErrors = [];

  /// Returns any errors that occurred during cleanup.
  ///
  /// This is useful for debugging cleanup issues. Cleanup errors are
  /// normally swallowed to ensure terminal restoration always completes,
  /// but they are collected here for inspection.
  List<Object> get cleanupErrors => List.unmodifiable(_cleanupErrors);

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
    _cleanedUp = false;
    _cleanupErrors.clear();
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
    if (TuiTrace.enabled) {
      _trace(
        'setup terminal=${_terminal.runtimeType} raw=${_terminal?.isRawMode}',
      );
      _trace(
        'setup options altScreen=${_options.altScreen} '
        'mouse=${_effectiveMouseMode()} '
        'fps=${_options.fps} '
        'uvRenderer=${_options.useUltravioletRenderer} '
        'uvInput=${_options.useUltravioletInputDecoder} '
        'disableRenderer=${_options.disableRenderer} '
        'replay=${_options.replay != null} '
        'blockInputWhileReplay=${_options.blockInputWhileReplay}',
      );
    }

    // Set startup title if provided
    if (_options.startupTitle != null) {
      _terminal!.write('\x1b]0;${_options.startupTitle}\x07');
      _appliedWindowTitle = _options.startupTitle;
    }

    // Set up renderer based on options
    final rendererOptions = TuiRendererOptions(
      fps: _options.fps,
      altScreen: _options.altScreen && !_options.disableRenderer,
      hideCursor: _options.hideCursor && !_options.disableRenderer,
      ansiCompress: _options.ansiCompress,
    );

    _createRenderer(rendererOptions);

    // Enable mouse tracking if requested
    _applyMouseMode();
    if (TuiTrace.enabled) {
      _trace('setup mouse mode=${_effectiveMouseMode()}');
    }

    // Enable bracketed paste if requested
    if (_options.bracketedPaste) {
      _setDesiredBracketedPaste(true);
    }

    _setupBackendLifecycleListeners();

    // Set up signal handlers (if enabled and not provided by the backend).
    if (_options.signalHandlers) {
      _setupSignalHandlers(
        handleInterrupt: _backendShutdownSubscription == null,
        handleResize: _backendResizeSubscription == null,
      );
    }

    // Start listening for input
    _startInputListener();
  }

  void _createRenderer(TuiRendererOptions options) {
    if (_options.disableRenderer) {
      _renderer = SimpleTuiRenderer(
        terminal: _terminal!,
        options: options,
      );
    } else if (_options.useUltravioletRenderer) {
      _renderer = UltravioletTuiRenderer(
        terminal: _terminal!,
        options: options,
      );
    } else if (_options.altScreen) {
      _renderer = FullScreenTuiRenderer(
        terminal: _terminal!,
        options: options,
      );
    } else {
      _renderer = InlineTuiRenderer(
        terminal: _terminal!,
        options: options,
      );
    }
    _renderer!.initialize();
  }

  /// Initializes the model and renders initial view.
  Future<void> _initialize() async {
    _replayActive = false;
    _model = _initialModel;

    // Suppress renders during initialization to avoid visual flash of pre-init state
    _initializing = true;

    // Send initial window size (model receives this before init runs)
    final size = _terminal!.size;
    _lastWindowSizeWidth = size.width;
    _lastWindowSizeHeight = size.height;
    _processMessage(WindowSizeMsg(size.width, size.height));

    // Send initial color profile (model receives this before init runs)
    _processMessage(ColorProfileMsg(_terminal!.colorProfile));

    // Kick off the init command before first render, but do not block the
    // first paint on long-running or delayed side effects such as timers,
    // process launches, or network work. This keeps startup responsive while
    // still allowing immediately-resolved init messages to land in the same
    // initialization turn.
    final initCmd = _model!.init();
    if (initCmd != null) {
      _drainingInitMessages = true;
      try {
        unawaited(_executeCommand(initCmd));
        await Future<void>.microtask(() {});
        _drainMessageQueue();
      } finally {
        _drainingInitMessages = false;
      }
    }

    if (_quitAfterInitialRender) {
      _startupProbes = null;
      _startupProbeContext = null;
      _initializing = false;
      _render();
      _quitAfterInitialRender = false;
      _quit();
      return;
    }

    await _runPreRenderStartupProbesIfNeeded();
    _drainMessageQueue();
    if (!_running || _backendShutdownRequested) {
      _startupProbes = null;
      _startupProbeContext = null;
      return;
    }
    _startupProbes?.drain(_processMessage);
    _drainMessageQueue();
    if (!_running || _backendShutdownRequested) {
      _startupProbes = null;
      _startupProbeContext = null;
      return;
    }
    final skipPostRenderStartupProbes = _startupProbes?.wasAborted ?? false;
    _startupProbes = null;
    _startupProbeContext = null;

    // Initialization complete - render the initialized state immediately so the
    // user sees content without waiting for startup probes.
    _initializing = false;
    _render();
    _drainDeferredUntilAfterInitialRender();
    if (!_running || _backendShutdownRequested) {
      _startupProbes = null;
      _startupProbeContext = null;
      return;
    }

    if (skipPostRenderStartupProbes) {
      _syncModelOptionalTimers();
      _options.interceptor?.onStart(send);
      _startReplay();
      return;
    }

    // Run startup probes (e.g. emoji width detection) AFTER the first frame is
    // painted.  The probe uses cursor save/restore on the already-active alt
    // screen so the user never sees a blank flash.
    //
    // Always force a full re-render after probes complete: the emoji width
    // probe clears the last terminal line (where status bars, etc. live) to
    // avoid visual artifacts during probing.  Even if the emoji presentation
    // width didn't change, the terminal display was disturbed and must be
    // repainted.
    await _runPostRenderStartupProbesIfNeeded();
    _drainMessageQueue();
    if (!_running || _backendShutdownRequested) {
      _startupProbes = null;
      _startupProbeContext = null;
      return;
    }
    _startupProbes?.drain(_processMessage);
    _drainMessageQueue();
    if (!_running || _backendShutdownRequested) {
      _startupProbes = null;
      _startupProbeContext = null;
      return;
    }
    if (_startupProbes case final probes? when !probes.wasAborted) {
      _forceRender();
    }
    _startupProbes = null;
    _startupProbeContext = null;

    // Start optional runtime timers (metrics + frame ticks) based on current
    // model capabilities/flags.
    _syncModelOptionalTimers();

    // Start automation hooks after the first stable frame is rendered.
    _options.interceptor?.onStart(send);
    _startReplay();
  }

  void _startReplay() {
    final replay = _options.replay;
    if (replay == null || _replaySubscription != null) return;

    _replayActive = true;
    if (TuiTrace.enabled) {
      _trace(
        'replay stream start blockInputWhileReplay=${_options.blockInputWhileReplay}',
        tag: TraceTag.input,
      );
    }
    _replaySubscription = replay.toStream().listen(
      (msg) {
        if (!_running) return;
        _traceInputBatch(
          parser: 'replay',
          flush: false,
          messages: <Msg>[msg],
          dropped: 0,
        );
        send(msg);
      },
      onError: (error, stackTrace) {
        _replayActive = false;
        if (TuiTrace.enabled) {
          _trace('replay stream error: $error', tag: TraceTag.input);
        }
      },
      onDone: () {
        _replayActive = false;
        if (TuiTrace.enabled) {
          _trace('replay stream done', tag: TraceTag.input);
        }
      },
    );
  }

  /// Starts a periodic timer to send render metrics to the model.
  void _startMetricsTimer() {
    if (_metricsTimer != null) return;
    if (_options.metricsInterval <= Duration.zero) return;
    if (_model case RenderMetricsModel(
      :final wantsRenderMetrics,
    ) when !wantsRenderMetrics) {
      return;
    }

    _metricsTimer = Timer.periodic(_options.metricsInterval, (_) {
      if (_terminalReleased) return;
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
    if (_frameTickTimer != null) return;
    if (!_options.frameTick) return;
    if (_model case FrameTickModel(
      :final wantsFrameTicks,
    ) when !wantsFrameTicks) {
      return;
    }

    // Calculate interval from fps
    final intervalMs = (1000 / _options.fps).round();
    final interval = Duration(milliseconds: intervalMs);

    // Initialize frame tick state
    _frameNumber = 0;
    _lastFrameTime = DateTime.now();

    _frameTickTimer = Timer.periodic(interval, (_) {
      if (!_running || _terminalReleased) return;

      final now = DateTime.now();
      final delta = _lastFrameTime != null
          ? now.difference(_lastFrameTime!)
          : interval;

      _frameNumber++;
      _lastFrameTime = now;

      send(FrameTickMsg(time: now, frameNumber: _frameNumber, delta: delta));
    });
  }

  void _stopMetricsTimer() {
    try {
      _metricsTimer?.cancel();
    } catch (_) {}
    _metricsTimer = null;
  }

  void _stopFrameTickTimer() {
    try {
      _frameTickTimer?.cancel();
    } catch (_) {}
    _frameTickTimer = null;
  }

  void _syncModelOptionalTimers() {
    // Render metrics timer.
    if (_options.metricsInterval <= Duration.zero) {
      _stopMetricsTimer();
    } else {
      final wantsMetrics = switch (_model) {
        RenderMetricsModel(:final wantsRenderMetrics) => wantsRenderMetrics,
        _ => true,
      };
      if (wantsMetrics) {
        _startMetricsTimer();
      } else {
        _stopMetricsTimer();
      }
    }

    // Frame tick timer.
    if (!_options.frameTick) {
      _stopFrameTickTimer();
    } else {
      final wantsTicks = switch (_model) {
        FrameTickModel(:final wantsFrameTicks) => wantsFrameTicks,
        _ => true,
      };
      if (wantsTicks) {
        _startFrameTickTimer();
      } else {
        _stopFrameTickTimer();
      }
    }
  }

  void _setupBackendLifecycleListeners() {
    final terminal = _terminal;
    if (terminal is! BackendTerminal) return;

    final resizeStream = terminal.resizeStream;
    if (resizeStream != null) {
      _backendResizeSubscription = resizeStream.listen((size) {
        _sendWindowSizeIfChanged(size.width, size.height);
      });
    }

    final shutdownStream = terminal.shutdownStream;
    if (shutdownStream != null) {
      _backendShutdownSubscription = shutdownStream.listen((_) {
        _handleBackendShutdown();
      });
    }
  }

  void _handleBackendShutdown() {
    if (_backendShutdownRequested || !_running) return;
    _backendShutdownRequested = true;

    if (_options.sendInterrupt) {
      send(const InterruptMsg());
    } else {
      send(const KeyMsg(Key(KeyType.runes, runes: [0x63], ctrl: true)));
    }

    scheduleMicrotask(() {
      if (_running) {
        quit();
      }
    });
  }

  /// Sets up signal handlers for graceful shutdown and resize.
  void _setupSignalHandlers({
    required bool handleInterrupt,
    required bool handleResize,
  }) {
    if (handleInterrupt) {
      try {
        _sigintSubscription = io.ProcessSignal.sigint.watch().listen((_) {
          if (_options.sendInterrupt) {
            send(const InterruptMsg());
          } else {
            send(const KeyMsg(Key(KeyType.runes, runes: [0x63], ctrl: true)));
          }
        });
      } catch (_) {
        // Signal handling not supported on this platform
      }
    }

    if (handleResize) {
      try {
        _sigwinchSubscription = io.ProcessSignal.sigwinch.watch().listen((_) {
          final size = _terminal!.size;
          _sendWindowSizeIfChanged(size.width, size.height);
        });
      } catch (_) {
        // SIGWINCH not available on this platform
      }
    }
  }

  void _sendWindowSizeIfChanged(int width, int height) {
    if (_lastWindowSizeWidth == width && _lastWindowSizeHeight == height) {
      return;
    }
    _lastWindowSizeWidth = width;
    _lastWindowSizeHeight = height;
    send(WindowSizeMsg(width, height));
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
      onDone: () {
        if (TuiTrace.enabled) {
          _trace('input stream closed');
        }
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

  void _trace(String message, {TraceTag tag = TraceTag.general}) {
    if (!TuiTrace.enabled) return;
    TuiTrace.log(message, tag: tag);
  }

  String _traceMsgSummary(Msg msg) {
    return switch (msg) {
      KeyMsg(:final key) => 'KeyMsg(${key.toString()})',
      MouseMsg(:final action, :final button, :final x, :final y) =>
        'MouseMsg($action $button @ $x,$y)',
      WindowSizeMsg(:final width, :final height) =>
        'WindowSizeMsg($width,$height)',
      UvEventMsg(:final event) => 'UvEventMsg(${event.runtimeType})',
      _ => msg.runtimeType.toString(),
    };
  }

  Map<String, Object?> _traceMsgPayload(Msg msg) {
    return switch (msg) {
      KeyMsg(:final key) => <String, Object?>{
        'kind': 'key',
        'keyType': key.type.name,
        if (key.runes.isNotEmpty) 'runes': key.runes,
        if (key.ctrl) 'ctrl': true,
        if (key.alt) 'alt': true,
        if (key.shift) 'shift': true,
        if (key.meta) 'meta': true,
        if (key.hyper) 'hyper': true,
        if (key.superKey) 'superKey': true,
        if (key.isRelease) 'isRelease': true,
        if (key.isRepeat) 'isRepeat': true,
      },
      MouseMsg(:final action, :final button, :final x, :final y) =>
        <String, Object?>{
          'kind': 'mouse',
          'action': action.name,
          'button': button.name,
          'x': x,
          'y': y,
          if (msg.ctrl) 'ctrl': true,
          if (msg.alt) 'alt': true,
          if (msg.shift) 'shift': true,
        },
      WindowSizeMsg(:final width, :final height) => <String, Object?>{
        'kind': 'window_size',
        'width': width,
        'height': height,
      },
      PasteTextMsg(:final content) => <String, Object?>{
        'kind': 'paste_text',
        'length': content.length,
      },
      PasteMsg(:final content) => <String, Object?>{
        'kind': 'paste',
        'length': content.length,
      },
      _ => <String, Object?>{
        'kind': 'other',
        'runtimeType': msg.runtimeType.toString(),
      },
    };
  }

  void _traceInputBatch({
    required String parser,
    required bool flush,
    required List<Msg> messages,
    required int dropped,
  }) {
    if (!TuiTrace.enabled) return;
    TuiTrace.event(
      TraceEventType.inputBatch,
      tag: TraceTag.input,
      fields: <String, Object?>{
        'parser': parser,
        'flush': flush,
        if (dropped > 0) 'dropped': dropped,
        'messages': messages
            .map<Map<String, Object?>>(_traceMsgPayload)
            .toList(growable: false),
      },
    );
  }

  String _traceBytes(List<int> bytes, {int limit = 32}) {
    final take = bytes.length > limit ? limit : bytes.length;
    final parts = <String>[];
    for (var i = 0; i < take; i++) {
      final b = bytes[i];
      parts.add(b.toRadixString(16).padLeft(2, '0'));
    }
    final suffix = bytes.length > limit ? '…' : '';
    return '${parts.join(' ')}$suffix';
  }

  /// Handles raw input bytes from the terminal.
  void _handleInput(List<int> bytes) {
    if (TuiTrace.enabled) {
      _trace(
        'input bytes=${bytes.length} pending=${_uvInputParser.hasPending} '
        'hex=${_traceBytes(bytes)} raw=${_terminal?.isRawMode ?? false}',
        tag: TraceTag.input,
      );
    }

    if (_options.blockInputWhileReplay && _replayActive) {
      if (TuiTrace.enabled) {
        _trace(
          'input dropped while replay active bytes=${bytes.length}',
          tag: TraceTag.input,
        );
      }
      return;
    }

    if (_options.useUltravioletInputDecoder) {
      _uvInputTimeoutTimer?.cancel();

      final msgs = _collapseLikelyRunePaste(
        _uvInputParser.parseAll(bytes, expired: false),
      );
      final coalesced = _coalesceInputMsgs(msgs);
      final dropped = msgs.length - coalesced.length;
      _traceInputBatch(
        parser: 'uv',
        flush: false,
        messages: coalesced,
        dropped: dropped,
      );
      if (TuiTrace.enabled) {
        final summary = coalesced.isEmpty
            ? '(none)'
            : coalesced.map(_traceMsgSummary).join(', ');
        _trace(
          'parsed uv: $summary${dropped > 0 ? ' (dropped $dropped)' : ''}',
          tag: TraceTag.input,
        );
      }
      for (final msg in coalesced) {
        _dispatchParsedInputMsg(msg);
      }

      if (_uvInputParser.hasPending) {
        _uvInputTimeoutTimer = Timer(_options.inputTimeout, () {
          if (!_running) return;
          final flushed = _collapseLikelyRunePaste(
            _uvInputParser.parseAll(const [], expired: true),
          );
          final coalesced = _coalesceInputMsgs(flushed);
          final dropped = flushed.length - coalesced.length;
          _traceInputBatch(
            parser: 'uv',
            flush: true,
            messages: coalesced,
            dropped: dropped,
          );
          if (TuiTrace.enabled) {
            final summary = coalesced.isEmpty
                ? '(none)'
                : coalesced.map(_traceMsgSummary).join(', ');
            _trace(
              'parsed uv flush: $summary'
              '${dropped > 0 ? ' (dropped $dropped)' : ''}',
              tag: TraceTag.input,
            );
          }
          for (final msg in coalesced) {
            _dispatchParsedInputMsg(msg);
          }
        });
      }
      return;
    }

    // Parse bytes into keys and other messages (mouse, focus, paste)
    final results = _keyParser.parseAll(bytes);
    final collapsedPaste = _collapseLikelyRunePasteFromResults(results);
    if (collapsedPaste != null) {
      _traceInputBatch(
        parser: 'key',
        flush: false,
        messages: <Msg>[collapsedPaste],
        dropped: results.length - 1,
      );
      if (TuiTrace.enabled) {
        _trace(
          'collapsed key parse into ${_traceMsgSummary(collapsedPaste)}',
          tag: TraceTag.input,
        );
      }
      send(collapsedPaste);
      return;
    }
    if (TuiTrace.enabled && results.isNotEmpty) {
      final summaries = <String>[];
      for (final result in results) {
        if (result is KeyResult) {
          summaries.add('KeyMsg(${result.key})');
        } else if (result is MsgResult) {
          summaries.add(_traceMsgSummary(result.msg));
        }
      }
      if (summaries.isNotEmpty) {
        _trace('parsed key: ${summaries.join(', ')}', tag: TraceTag.input);
      }
    }

    final parsedMessages = <Msg>[];
    for (final result in results) {
      switch (result) {
        case KeyResult(:final key):
          parsedMessages.add(KeyMsg(key));
        case MsgResult(:final msg):
          parsedMessages.add(msg);
      }
    }
    _traceInputBatch(
      parser: 'key',
      flush: false,
      messages: parsedMessages,
      dropped: 0,
    );

    // Send each result as a message
    for (final msg in parsedMessages) {
      _dispatchParsedInputMsg(msg);
    }
  }

  void _dispatchParsedInputMsg(Msg msg) {
    if (msg case WindowSizeMsg(:final width, :final height)) {
      _sendWindowSizeIfChanged(width, height);
      return;
    }
    send(msg);
  }

  List<Msg> _coalesceInputMsgs(List<Msg> msgs) {
    if (msgs.isEmpty) return msgs;
    final hasKey = msgs.any((m) => m is KeyMsg);
    if (hasKey) {
      return msgs.where((m) => m is! MouseMsg).toList(growable: false);
    }

    final lastByAction = <MouseAction, (int index, MouseMsg msg)>{};
    for (var i = 0; i < msgs.length; i++) {
      final msg = msgs[i];
      if (msg is! MouseMsg) continue;
      lastByAction[msg.action] = (i, msg);
    }

    if (lastByAction.isEmpty) return msgs;

    final keep = <int>{};
    for (final entry in lastByAction.values) {
      keep.add(entry.$1);
    }

    final result = <Msg>[];
    for (var i = 0; i < msgs.length; i++) {
      final msg = msgs[i];
      if (msg is MouseMsg) {
        if (keep.contains(i)) result.add(msg);
      } else {
        result.add(msg);
      }
    }

    return result;
  }

  static const int _pasteCollapseMinMsgs = 64;
  static const int _pasteCollapseMinRunes = 96;

  List<int>? _pasteTextRunesFromKey(Key key) {
    if (key.hasModifier || key.isRelease) return null;
    if (key.type == KeyType.runes) return key.runes;
    if (key.isEnterLike) return const <int>[0x0A];
    if (key.isTab) return const <int>[0x09];
    if (key.isSpaceLike) return const <int>[0x20];
    return null;
  }

  List<Msg> _collapseLikelyRunePaste(List<Msg> msgs) {
    if (msgs.length < _pasteCollapseMinMsgs) return msgs;

    final runes = <int>[];
    for (final msg in msgs) {
      if (msg case KeyMsg(:final key)) {
        final textRunes = _pasteTextRunesFromKey(key);
        if (textRunes == null) {
          if (TuiTrace.enabled) {
            _trace(
              'paste-collapse skipped(uv) non-text-key/modifier '
              'msgs=${msgs.length}',
            );
          }
          return msgs;
        }
        runes.addAll(textRunes);
      } else {
        if (TuiTrace.enabled) {
          _trace('paste-collapse skipped(uv) non-key msgs=${msgs.length}');
        }
        return msgs;
      }
    }

    if (runes.length < _pasteCollapseMinRunes) {
      if (TuiTrace.enabled) {
        _trace(
          'paste-collapse skipped(uv) runes=${runes.length} '
          'threshold=$_pasteCollapseMinRunes msgs=${msgs.length}',
        );
      }
      return msgs;
    }
    final collapsed = PasteTextMsg(String.fromCharCodes(runes));
    if (TuiTrace.enabled) {
      _trace(
        'collapsed ${msgs.length} key msgs into ${collapsed.content.length} chars',
      );
    }
    return <Msg>[collapsed];
  }

  PasteTextMsg? _collapseLikelyRunePasteFromResults(List<Object> results) {
    if (results.length < _pasteCollapseMinMsgs) return null;

    final runes = <int>[];
    for (final result in results) {
      if (result case KeyResult(:final key)) {
        final textRunes = _pasteTextRunesFromKey(key);
        if (textRunes == null) {
          if (TuiTrace.enabled) {
            _trace(
              'paste-collapse skipped(key) non-text-key/modifier '
              'results=${results.length}',
            );
          }
          return null;
        }
        runes.addAll(textRunes);
      } else {
        if (TuiTrace.enabled) {
          _trace(
            'paste-collapse skipped(key) non-key results=${results.length}',
          );
        }
        return null;
      }
    }

    if (runes.length < _pasteCollapseMinRunes) {
      if (TuiTrace.enabled) {
        _trace(
          'paste-collapse skipped(key) runes=${runes.length} '
          'threshold=$_pasteCollapseMinRunes results=${results.length}',
        );
      }
      return null;
    }
    if (TuiTrace.enabled) {
      _trace(
        'collapsed key results=${results.length} into chars=${runes.length}',
      );
    }
    return PasteTextMsg(String.fromCharCodes(runes));
  }

  Future<void> _runPreRenderStartupProbesIfNeeded() async {
    if (_options.disableRenderer) return;
    if (!_options.useUltravioletRenderer) return;
    if (!_options.useUltravioletInputDecoder) return;
    final term = _terminal;
    if (term == null) return;
    if (!_shouldRunStartupProbes(term)) return;

    final ctx = StartupProbeContext(terminal: term);
    _startupProbeContext = ctx;

    final runner = StartupProbeRunner([BackgroundColorProbe()]);
    _startupProbes = runner;
    await runner.runAll(ctx);
  }

  Future<void> _runPostRenderStartupProbesIfNeeded() async {
    if (_options.disableRenderer) return;
    if (!_options.useUltravioletRenderer) return;
    if (!_options.useUltravioletInputDecoder) return;
    final term = _terminal;
    if (term == null) return;
    if (!_shouldRunStartupProbes(term)) return;

    final probes = <StartupProbe>[UvCapabilityProbe()];

    // Avoid messing with normal terminal output in inline mode. Users can
    // always override via UV_EMOJI_WIDTH/EMOJI_WIDTH if needed.
    if (_options.altScreen) {
      final override =
          io.Platform.environment['UV_EMOJI_WIDTH'] ??
          io.Platform.environment['EMOJI_WIDTH'];
      if (override != null) {
        final v = int.tryParse(override.trim());
        if (v != null) uni_width.setEmojiPresentationWidth(v);
      } else {
        probes.add(EmojiWidthProbe());
      }
    }

    if (probes.isEmpty) return;

    final ctx = StartupProbeContext(terminal: term);
    _startupProbeContext = ctx;

    // Run non-visual capability probing after the first frame so it cannot
    // delay paint. Emoji-width probing remains opt-in to fullscreen mode.
    final runner = StartupProbeRunner(probes);
    _startupProbes = runner;
    await runner.runAll(ctx);
  }

  bool _shouldRunStartupProbes(TuiTerminal term) {
    if (!term.supportsAnsi || !term.isTerminal) return false;
    final explicit = _options.startupProbes;
    if (explicit != null) return explicit;
    return term is StdioTerminal ||
        term is SplitTerminal ||
        term is TtyTerminal ||
        term is BackendTerminal;
  }

  /// Sends a message to the program.
  ///
  /// The message will be processed through [Model.update] and
  /// the view will be re-rendered.
  ///
  /// This can be called from outside the program to inject messages.
  /// Messages are queued and processed sequentially to prevent race
  /// conditions and ensure consistent state updates.
  void send(Msg msg) {
    if (!_running) return;

    if ((_startupProbes?.hasActiveProbe ?? false) &&
        isCriticalStartupProbeMsg(msg)) {
      _startupProbes?.abort();
    }

    final interceptor = _options.interceptor;
    if (interceptor != null) {
      final intercepted = interceptor.onSend(msg);
      if (intercepted == null) {
        if (TuiTrace.enabled) {
          _trace(
            'interceptor dropped ${msg.runtimeType}',
            tag: TraceTag.dispatch,
          );
        }
        return;
      }
      msg = intercepted;
    }

    // Coalesce: when a key arrives, drop all pending mouse messages.
    // Also drop pending frame ticks so input is not blocked by stale animation
    // updates. When a motion/wheel arrives, drop prior events of the same
    // action. Keep only the newest frame tick in the queue.
    // Use _coalesceQueue to avoid O(n) removeWhere on each send.
    if (msg is KeyMsg) {
      final dropped = _coalesceQueue(
        (m) => m is! MouseMsg && m is! FrameTickMsg,
      );
      if (TuiTrace.enabled && dropped > 0) {
        _trace('queue coalesce key dropped=$dropped', tag: TraceTag.queue);
      }
    } else if (msg is FrameTickMsg) {
      final dropped = _coalesceQueue((m) => m is! FrameTickMsg);
      if (TuiTrace.enabled && dropped > 0) {
        _trace(
          'queue coalesce frameTick dropped=$dropped',
          tag: TraceTag.queue,
        );
      }
    } else if (msg is MouseMsg &&
        msg.action == MouseAction.motion &&
        msg.button == MouseButton.none) {
      final dropped = _coalesceQueue(
        (m) => m is! MouseMsg || m.action != MouseAction.motion,
      );
      if (TuiTrace.enabled && dropped > 0) {
        _trace(
          'queue coalesce mouse-motion dropped=$dropped',
          tag: TraceTag.queue,
        );
      }
    } else if (msg is MouseMsg && msg.action == MouseAction.wheel) {
      final dropped = _coalesceQueue(
        (m) => m is! MouseMsg || m.action != MouseAction.wheel,
      );
      if (TuiTrace.enabled && dropped > 0) {
        _trace(
          'queue coalesce mouse-wheel dropped=$dropped',
          tag: TraceTag.queue,
        );
      }
    }
    if (TuiTrace.enabled && msg is KeyMsg) {
      final now = DateTime.now();
      final dtMs = _lastQueuedKeyAt == null
          ? -1
          : now.difference(_lastQueuedKeyAt!).inMicroseconds / 1000.0;
      _lastQueuedKeyAt = now;
      TuiTrace.log(
        'queue before key len=${_messageQueue.length} '
        'msg=${_traceMsgSummary(msg)} '
        'input_dt_ms=${dtMs < 0 ? 'n/a' : dtMs.toStringAsFixed(2)}',
        tag: TraceTag.queue,
      );
    }
    _messageQueue.add(msg);
    if (TuiTrace.enabled && msg is KeyMsg) {
      TuiTrace.log(
        'queue after key len=${_messageQueue.length}',
        tag: TraceTag.queue,
      );
    }
    _drainMessageQueue();
  }

  /// Removes messages from the queue that don't pass [keep].
  ///
  /// Rebuilds the queue in-place, retaining only matching messages.
  /// O(n) but only called when coalescing is needed.
  int _coalesceQueue(bool Function(Msg) keep) {
    if (_messageQueue.isEmpty) return 0;
    var dropped = 0;
    final len = _messageQueue.length;
    for (var i = 0; i < len; i++) {
      final m = _messageQueue.removeFirst();
      if (keep(m)) {
        _messageQueue.add(m);
      } else {
        dropped++;
      }
    }
    return dropped;
  }

  /// Drains the message queue, processing messages sequentially.
  ///
  /// This prevents reentrant message processing - if a message handler
  /// calls [send], the new message is queued and processed after the
  /// current message completes.
  void _drainMessageQueue() {
    if (_processingMessage) return;
    _processingMessage = true;
    try {
      while (_messageQueue.isNotEmpty && _running) {
        final msg = _messageQueue.removeFirst();
        final deferRender =
            msg is KeyMsg &&
            _messageQueue.isNotEmpty &&
            _messageQueue.first is KeyMsg;
        _processMessage(msg, deferRender: deferRender);
      }
    } finally {
      _processingMessage = false;
    }
  }

  /// Processes a message through the model.
  void _processMessage(Msg msg, {bool deferRender = false}) {
    if (_model == null) return;

    final interceptor = _options.interceptor;
    final processSw = interceptor == null ? null : (Stopwatch()..start());

    if (TuiTrace.enabled && msg is KeyMsg) {
      final now = DateTime.now();
      final dtMs = _lastProcessedKeyAt == null
          ? -1
          : now.difference(_lastProcessedKeyAt!).inMicroseconds / 1000.0;
      _lastProcessedKeyAt = now;
      TuiTrace.log(
        'key process_start queue_len=${_messageQueue.length} '
        'process_dt_ms=${dtMs < 0 ? 'n/a' : dtMs.toStringAsFixed(2)}',
        tag: TraceTag.queue,
      );
    }

    final span = TuiTrace.begin(
      'msg#${++_traceMsgId}',
      tag: TraceTag.dispatch,
      extra: msg.runtimeType.toString(),
    );

    try {
      if (msg case WindowSizeMsg(:final width, :final height)) {
        TuiTrace.event(
          TraceEventType.windowSize,
          tag: TraceTag.input,
          fields: <String, Object?>{'width': width, 'height': height},
        );
      }

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
        if (_drainingInitMessages) {
          _quitAfterInitialRender = true;
          return;
        }
        _quit();
        return;
      }

      // Handle repaint message
      if (msg is RepaintMsg) {
        _forceRender();
        return;
      }

      // Handle batch message - flatten nested batches to avoid stack overflow
      if (msg is BatchMsg) {
        // Use a queue to process messages iteratively instead of recursively
        final queue = <Msg>[...msg.messages];
        while (queue.isNotEmpty) {
          final m = queue.removeAt(0);
          if (m is BatchMsg) {
            // Flatten nested batch by adding its messages to the front of the queue
            queue.insertAll(0, m.messages);
          } else {
            _processMessage(m);
          }
        }
        return;
      }

      // Handle internal control messages
      if (_handleControlMessage(msg)) {
        return;
      }

      // Update model
      final (newModel, cmd) = _model!.update(msg);
      if (newModel is! M) {
        throw StateError(
          'Model.update() returned ${newModel.runtimeType}, expected $M. '
          'Ensure your update() method returns the same model type.',
        );
      }
      _model = newModel;

      // The model may have toggled optional runtime feeds (frame ticks /
      // render metrics). Keep timers in sync with current model flags.
      _syncModelOptionalTimers();

      // Re-render
      // Mark metrics-only frames so the renderer doesn't count them toward
      // FPS.  The metrics timer fires every ~1s which would otherwise produce
      // a steady 1.0 FPS when idle.
      if (msg is RenderMetricsMsg) {
        _renderer?.metrics?.metricsOnlyFrame = true;
      }
      final startupProbeActive = _startupProbes?.hasActiveProbe ?? false;
      if (deferRender || startupProbeActive) {
        if (TuiTrace.enabled && msg is KeyMsg) {
          TuiTrace.log(
            startupProbeActive
                ? 'render deferred while startup probe active; '
                      'queue_len=${_messageQueue.length}'
                : 'render deferred for queued key; '
                      'queue_len=${_messageQueue.length}',
            tag: TraceTag.render,
          );
        }
      } else {
        _render();
      }

      // Execute command
      if (cmd != null) {
        final cmdSpan = TuiTrace.begin(
          'cmd',
          tag: TraceTag.cmd,
          extra: cmd.runtimeType.toString(),
        );
        _executeCommand(cmd);
        cmdSpan.end();
      }
    } finally {
      span.end();
      if (processSw != null) {
        processSw.stop();
        interceptor!.onProcessed(msg, processSw.elapsed);
      }
    }
  }

  /// Handles internal control messages.
  /// Returns true if the message was handled internally.
  bool _handleControlMessage(Msg msg) {
    switch (msg) {
      case SetWindowTitleMsg(:final title):
        _applyWindowTitle(title);
        return true;

      case ClearScreenMsg():
        if (_terminalReleased) return true;
        _terminal?.clearScreen();
        _render();
        return true;

      case EnterAltScreenMsg():
        if (_options.altScreen) {
          _terminal?.enterAltScreen();
        } else {
          _commandAltScreenEnabled = true;
          _applyDynamicAltScreen();
        }
        return true;

      case ExitAltScreenMsg():
        if (_options.altScreen) {
          _terminal?.exitAltScreen();
        } else {
          _commandAltScreenEnabled = false;
          _applyDynamicAltScreen();
        }
        return true;

      case ShowCursorMsg():
        if (_terminalReleased) return true;
        _setDesiredCursorVisibilityOverride(true);
        return true;

      case HideCursorMsg():
        if (_terminalReleased) return true;
        _setDesiredCursorVisibilityOverride(false);
        return true;

      case EnableMouseCellMotionMsg():
        _setDesiredMouseMode(MouseMode.cellMotion);
        return true;

      case EnableMouseAllMotionMsg():
        _setDesiredMouseMode(MouseMode.allMotion);
        return true;

      case DisableMouseMsg():
        _setDesiredMouseMode(MouseMode.none);
        return true;

      case EnableBracketedPasteMsg():
        _setDesiredBracketedPaste(true);
        return true;

      case DisableBracketedPasteMsg():
        _setDesiredBracketedPaste(false);
        return true;

      case EnableReportFocusMsg():
        _setDesiredFocusReporting(true);
        return true;

      case DisableReportFocusMsg():
        _setDesiredFocusReporting(false);
        return true;

      case RequestWindowSizeMsg():
        final size = _terminal?.size ?? (width: 80, height: 24);
        _lastWindowSizeWidth = size.width;
        _lastWindowSizeHeight = size.height;
        TuiTrace.event(
          TraceEventType.windowSize,
          tag: TraceTag.input,
          fields: <String, Object?>{'width': size.width, 'height': size.height},
        );
        _processMessage(WindowSizeMsg(size.width, size.height));
        return true;

      case PrintLineMsg(:final text):
        if (_terminalReleased) return true;
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
        if (_terminalReleased) return true;
        final terminal = _terminal;
        if (terminal == null) return true;
        if ((!terminal.isTerminal || !terminal.supportsAnsi) &&
            _isTerminalReportRequest(data)) {
          return true;
        }
        terminal.write(data);
        unawaited(terminal.flush());
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
        if (_terminalReleased) return true;
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
    final releaseGeneration = ++_terminalReleaseGeneration;

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

      if (!_canRestoreReleasedTerminal(releaseGeneration)) return;

      // Restore terminal
      _restoreTerminal();
      final restoreSizeChanged = _dispatchRestoreSizeIfChanged();

      // Send result message
      final result = ExecResult(
        exitCode: process.exitCode,
        stdout: process.stdout.toString(),
        stderr: process.stderr.toString(),
      );

      final deferCompletionUntilAfterInitialRender = _initializing;
      if (!restoreSizeChanged && !deferCompletionUntilAfterInitialRender) {
        _renderAfterTerminalRestore(skipSizeDispatch: true);
      }

      final completionMsg = onComplete(result);
      if (deferCompletionUntilAfterInitialRender) {
        _deferredUntilAfterInitialRender.add(completionMsg);
      } else {
        // Route completion through the normal send/queue path so interceptors,
        // coalescing, and ordering semantics are consistent with all other
        // runtime messages.
        send(completionMsg);
      }
    } catch (e) {
      // Restore terminal even on error
      if (!_canRestoreReleasedTerminal(releaseGeneration)) return;
      _restoreTerminal();
      final restoreSizeChanged = _dispatchRestoreSizeIfChanged();

      // Send error result
      final result = ExecResult(exitCode: -1, stdout: '', stderr: e.toString());

      final deferCompletionUntilAfterInitialRender = _initializing;
      if (!restoreSizeChanged && !deferCompletionUntilAfterInitialRender) {
        _renderAfterTerminalRestore(skipSizeDispatch: true);
      }

      final completionMsg = onComplete(result);
      if (deferCompletionUntilAfterInitialRender) {
        _deferredUntilAfterInitialRender.add(completionMsg);
      } else {
        // Route completion through the normal send/queue path so interceptors,
        // coalescing, and ordering semantics are consistent with all other
        // runtime messages.
        send(completionMsg);
      }
    }
  }

  bool _canRestoreReleasedTerminal(int releaseGeneration) =>
      _running && _terminalReleaseGeneration == releaseGeneration;

  /// Releases the terminal for external process execution.
  Future<void> _releaseTerminal() async {
    _terminalReleased = true;
    _releasedWindowTitle = null;
    final rendererHandledCursor = _rendererHandlesCursorLifecycle();

    // Stop input listening temporarily.
    _uvInputTimeoutTimer?.cancel();
    _uvInputTimeoutTimer = null;
    _stopMetricsTimer();
    _stopFrameTickTimer();
    _uvInputParser.clear();

    try {
      await _inputSubscription?.cancel();
    } catch (_) {
      // Input subscription may already be closed during shutdown.
    }
    _inputSubscription = null;

    // Dispose renderer (restores cursor, exits alt screen if needed)
    _renderer?.dispose();

    _resetProgressBarIfOverridden();
    _resetTerminalColorOverrides();
    _resetCursorStyleOverride();
    _appliedWindowTitle = null;

    _disableAppliedTerminalModes();
    _appliedCursorVisibilityOverride = null;

    // Restore terminal to normal mode
    _terminal?.disableRawMode();
    if (!rendererHandledCursor) {
      _terminal?.showCursor();
    }
  }

  /// Restores the terminal after external process execution.
  void _restoreTerminal() {
    _terminalReleased = false;

    // Re-enable raw mode
    _terminal?.enableRawMode();

    final rendererOptions = TuiRendererOptions(
      fps: _options.fps,
      altScreen: _options.altScreen && !_options.disableRenderer,
      hideCursor: _options.hideCursor && !_options.disableRenderer,
      ansiCompress: _options.ansiCompress,
    );
    _createRenderer(rendererOptions);
    _appliedCursorVisibilityOverride = null;
    _applyWindowTitle(_restoreWindowTitle());
    _releasedWindowTitle = null;

    _restoreDesiredTerminalModes();
    _applyDesiredCursorVisibilityOverride();
    _applyDynamicAltScreen();

    // Restart input listening.
    if (_inputSubscription == null) {
      _startInputListener();
    }

    _syncModelOptionalTimers();
  }

  void _schedulePostRestoreRender({bool skipSizeDispatch = false}) {
    unawaited(
      Future<void>.delayed(Duration.zero, () {
        if (!_running) return;
        if (_processingMessage) {
          _schedulePostRestoreRender(skipSizeDispatch: skipSizeDispatch);
          return;
        }
        final renderGenerationBeforeDrain = _renderGeneration;
        _drainMessageQueue();
        if (_backendShutdownRequested) return;
        if (_renderGeneration != renderGenerationBeforeDrain) return;
        _renderAfterTerminalRestore(skipSizeDispatch: skipSizeDispatch);
      }),
    );
  }

  void _drainDeferredUntilAfterInitialRender() {
    if (_deferredUntilAfterInitialRender.isEmpty) return;
    final pending = List<Msg>.from(_deferredUntilAfterInitialRender);
    _deferredUntilAfterInitialRender.clear();
    for (final msg in pending) {
      send(msg);
    }
    _drainMessageQueue();
  }

  bool _dispatchRestoreSizeIfChanged() {
    if (!_running || _backendShutdownRequested) return false;

    final size = _terminal?.size;
    if (size != null &&
        (_lastWindowSizeWidth != size.width ||
            _lastWindowSizeHeight != size.height)) {
      _sendWindowSizeIfChanged(size.width, size.height);
      return true;
    }

    return false;
  }

  void _renderAfterTerminalRestore({bool skipSizeDispatch = false}) {
    if (!_running || _backendShutdownRequested) return;

    // Force metadata reapplication even when the model returns the same cached
    // view object after restoring the terminal.
    _lastRenderedView = null;

    if (!skipSizeDispatch && _dispatchRestoreSizeIfChanged()) {
      return;
    }

    _render();
  }

  MouseMode _effectiveMouseMode() {
    if (_options.mouseMode != MouseMode.none) return _options.mouseMode;
    return _options.mouse ? MouseMode.cellMotion : MouseMode.none;
  }

  void _applyMouseMode() {
    _setDesiredMouseMode(_effectiveMouseMode());
  }

  void _setDesiredMouseMode(MouseMode mode) {
    _desiredMouseMode = mode;
    _applyDesiredMouseMode();
  }

  void _applyDesiredMouseMode() {
    final terminal = _terminal;
    if (terminal == null) return;
    if (_terminalReleased) return;
    if (_appliedMouseMode == _desiredMouseMode) return;
    if (_appliedMouseMode != MouseMode.none) {
      terminal.disableMouse();
      _appliedMouseMode = MouseMode.none;
    }
    switch (_desiredMouseMode) {
      case MouseMode.none:
        return;
      case MouseMode.cellMotion:
        terminal.enableMouseCellMotion();
        break;
      case MouseMode.allMotion:
        terminal.enableMouseAllMotion();
        break;
    }
    _appliedMouseMode = _desiredMouseMode;
  }

  void _setDesiredBracketedPaste(bool enabled) {
    _desiredBracketedPaste = enabled;
    _applyDesiredBracketedPaste();
  }

  void _applyDesiredBracketedPaste() {
    final terminal = _terminal;
    if (terminal == null) return;
    if (_terminalReleased) return;
    if (_appliedBracketedPaste == _desiredBracketedPaste) return;
    if (_desiredBracketedPaste) {
      terminal.enableBracketedPaste();
    } else {
      terminal.disableBracketedPaste();
    }
    _appliedBracketedPaste = _desiredBracketedPaste;
  }

  void _setDesiredFocusReporting(bool enabled) {
    _desiredFocusReporting = enabled;
    _applyDesiredFocusReporting();
  }

  void _applyDesiredFocusReporting() {
    final terminal = _terminal;
    if (terminal == null) return;
    if (_terminalReleased) return;
    if (_appliedFocusReporting == _desiredFocusReporting) return;
    if (_desiredFocusReporting) {
      terminal.enableFocusReporting();
    } else {
      terminal.disableFocusReporting();
    }
    _appliedFocusReporting = _desiredFocusReporting;
  }

  void _setDesiredKeyboardEnhancementFlags(int flags) {
    _desiredKeyboardEnhancementFlags = flags;
    _applyDesiredKeyboardEnhancements();
  }

  void _applyDesiredKeyboardEnhancements() {
    final terminal = _terminal;
    if (terminal == null) return;
    if (_terminalReleased) return;
    if (_appliedKeyboardEnhancementFlags == _desiredKeyboardEnhancementFlags) {
      return;
    }
    if (_appliedKeyboardEnhancementFlags != 0) {
      terminal.write(Ansi.resetKittyKeyboard);
      _appliedKeyboardEnhancementFlags = 0;
    }
    if (_desiredKeyboardEnhancementFlags != 0) {
      terminal.write(Ansi.kittyKeyboard(_desiredKeyboardEnhancementFlags, mode: 1));
      terminal.write(Ansi.requestKittyKeyboard);
      _appliedKeyboardEnhancementFlags = _desiredKeyboardEnhancementFlags;
    }
  }

  void _restoreDesiredTerminalModes() {
    _applyDesiredFocusReporting();
    _applyDesiredBracketedPaste();
    _applyDesiredMouseMode();
    _applyDesiredKeyboardEnhancements();
  }

  String? _restoreWindowTitle() =>
      _releasedWindowTitle ?? _lastView?.windowTitle ?? _options.startupTitle;

  void _applyWindowTitle(String? title) {
    if (title == null) return;
    if (_terminalReleased) {
      _releasedWindowTitle = title;
      return;
    }
    if (_appliedWindowTitle == title) return;
    _terminal?.setTitle(title);
    _appliedWindowTitle = title;
  }

  void _resetProgressBarIfOverridden() {
    if (_progressBarOverridden) {
      _terminal?.setProgressBar(TerminalProgressBarState.none.index, 0);
      _progressBarOverridden = false;
    }
  }

  void _resetTerminalColorOverrides() {
    if (_bgColorOverridden) {
      _terminal?.write('\x1b]111\x07');
      _bgColorOverridden = false;
    }
    if (_fgColorOverridden) {
      _terminal?.write('\x1b]110\x07');
      _fgColorOverridden = false;
    }
    _resetCursorColorOverride();
  }

  void _resetCursorColorOverride() {
    if (_cursorColorOverridden) {
      _terminal?.write('\x1b]112\x07');
      _cursorColorOverridden = false;
    }
  }

  void _resetCursorStyleOverride() {
    if (_cursorStyleOverridden) {
      _terminal?.write('\x1b[1 q');
      _cursorStyleOverridden = false;
    }
  }

  bool _rendererHandlesCursorLifecycle() {
    if (_options.disableRenderer || !_options.hideCursor) return false;
    final renderer = _renderer;
    return renderer is FullScreenTuiRenderer ||
        renderer is UltravioletTuiRenderer;
  }

  void _setDesiredCursorVisibilityOverride(bool? visible) {
    _desiredCursorVisibilityOverride = visible;
    _applyDesiredCursorVisibilityOverride();
  }

  void _applyDesiredCursorVisibilityOverride() {
    final terminal = _terminal;
    if (terminal == null) return;
    if (_terminalReleased) return;
    final target = _desiredCursorVisibilityOverride;
    if (target == null) {
      _appliedCursorVisibilityOverride = null;
      return;
    }
    if (_appliedCursorVisibilityOverride == target) return;
    if (target) {
      terminal.showCursor();
    } else {
      terminal.hideCursor();
    }
    _appliedCursorVisibilityOverride = target;
  }

  void _applyDynamicAltScreen() {
    if (_options.altScreen) return;
    if (_terminalReleased) return;
    final target = _viewAltScreenOverride ?? _commandAltScreenEnabled;
    if (_appliedDynamicAltScreen == target) return;
    if (target) {
      _terminal?.enterAltScreen();
    } else {
      _terminal?.exitAltScreen();
    }
    _appliedDynamicAltScreen = target;
  }

  void _resetViewScopedTerminalMetadata() {
    _applyWindowTitle(_options.startupTitle);
    _viewAltScreenOverride = null;
    _applyDynamicAltScreen();
    _setDesiredFocusReporting(false);
    _setDesiredBracketedPaste(_options.bracketedPaste);
    _applyMouseMode();
    _setDesiredKeyboardEnhancementFlags(0);
    _resetProgressBarIfOverridden();
    _resetTerminalColorOverrides();
    _resetCursorStyleOverride();
  }

  void _disableAppliedTerminalModes() {
    final terminal = _terminal;
    if (terminal == null) return;
    if (_appliedDynamicAltScreen) {
      terminal.exitAltScreen();
      _appliedDynamicAltScreen = false;
    }
    if (_appliedFocusReporting) {
      terminal.disableFocusReporting();
      _appliedFocusReporting = false;
    }
    if (_appliedBracketedPaste) {
      terminal.disableBracketedPaste();
      _appliedBracketedPaste = false;
    }
    if (_appliedMouseMode != MouseMode.none) {
      terminal.disableMouse();
      _appliedMouseMode = MouseMode.none;
    }
    if (_appliedKeyboardEnhancementFlags != 0) {
      terminal.write(Ansi.resetKittyKeyboard);
      _appliedKeyboardEnhancementFlags = 0;
    }
  }

  /// Suspends the program temporarily.
  void _suspend() {
    final restoringDuringInitialization = _initializing;
    final restoreDynamicAltScreen = _appliedDynamicAltScreen;
    _terminalReleased = true;
    _releasedWindowTitle = null;
    final rendererHandledCursor = _rendererHandlesCursorLifecycle();

    // Save terminal state
    _renderer?.dispose();

    // Stop input listening and timers temporarily.
    _uvInputTimeoutTimer?.cancel();
    _uvInputTimeoutTimer = null;
    _stopMetricsTimer();
    _stopFrameTickTimer();
    _uvInputParser.clear();
    unawaited(_inputSubscription?.cancel());
    _inputSubscription = null;

    // Restore terminal
    _disableAppliedTerminalModes();
    _terminal?.disableRawMode();
    _appliedCursorVisibilityOverride = null;
    if (!rendererHandledCursor) {
      _terminal?.showCursor();
    }

    _resetProgressBarIfOverridden();
    _resetTerminalColorOverrides();
    _resetCursorStyleOverride();
    _appliedWindowTitle = null;

    // Send SIGTSTP to suspend (Unix only) unless the caller explicitly wants
    // the release/restore lifecycle without suspending the parent process.
    if (_options.sendSuspendSignal) {
      try {
        io.Process.killPid(io.pid, io.ProcessSignal.sigtstp);
      } catch (_) {
        // Suspend not supported on this platform
      }
    }

    // When resumed, restore terminal state
    _terminalReleased = false;
    _terminal?.enableRawMode();
    if (!_options.altScreen && restoreDynamicAltScreen) {
      _terminal?.enterAltScreen();
      _appliedDynamicAltScreen = true;
    }

    final rendererOptions = TuiRendererOptions(
      fps: _options.fps,
      altScreen: _options.altScreen && !_options.disableRenderer,
      hideCursor: _options.hideCursor && !_options.disableRenderer,
      ansiCompress: _options.ansiCompress,
    );
    _createRenderer(rendererOptions);
    _appliedCursorVisibilityOverride = null;
    _applyWindowTitle(_restoreWindowTitle());
    _releasedWindowTitle = null;

    _restoreDesiredTerminalModes();
    _applyDesiredCursorVisibilityOverride();
    _applyDynamicAltScreen();

    // Restart input.
    _startInputListener();

    // Restart optional runtime timers.
    _syncModelOptionalTimers();

    // Force resume to repaint even when the model returns the same cached view.
    _lastRenderedView = null;

    // Send resume message
    _processMessage(const ResumeMsg(), deferRender: true);
    if (!restoringDuringInitialization) {
      _schedulePostRestoreRender();
    }
  }

  /// Renders the current view.
  void _render() {
    if (_model == null || _renderer == null) return;
    if (_terminalReleased) return;
    // Skip rendering during initialization phase to avoid visual flash
    if (_initializing) return;

    final termSize = _terminal?.size;
    final sizeChangedSinceLastRender =
        termSize != null &&
        (termSize.width != _lastRenderWidth ||
            termSize.height != _lastRenderHeight);

    final renderId = TuiTrace.enabled ? ++_traceRenderId : null;
    final Stopwatch? viewSw = renderId == null ? null : Stopwatch();
    viewSw?.start();
    final view = _model!.view();
    viewSw?.stop();
    if (renderId != null && viewSw != null) {
      _trace(
        'render#$renderId view ${view.runtimeType} ${viewSw.elapsedMicroseconds}us',
      );
    }

    // Identity-based skip: if the model returned the exact same object
    // (e.g. WidgetApp returning its _cachedView when !_dirty), skip the
    // entire renderer pipeline.  This avoids ANSI parsing, buffer drawing,
    // and diffing for no-op frames (e.g. RenderMetricsMsg with overlay off).
    if (!sizeChangedSinceLastRender && identical(view, _lastRenderedView)) {
      if (renderId != null) {
        _trace('render#$renderId skip (identical view)', tag: TraceTag.render);
      }
      return;
    }
    _lastRenderedView = view;
    if (termSize != null) {
      _lastRenderWidth = termSize.width;
      _lastRenderHeight = termSize.height;
    }

    if (view is View) {
      _lastView = view;
      _applyViewMetadata(view);
    } else {
      _resetViewScopedTerminalMetadata();
      _lastView = null;
    }

    final Stopwatch? renderSw = renderId == null ? null : Stopwatch();
    renderSw?.start();
    _renderer!.render(view);
    _renderGeneration += 1;
    renderSw?.stop();
    if (renderId != null && renderSw != null) {
      _trace('render#$renderId paint ${renderSw.elapsedMicroseconds}us');
    }
    // Emit per-frame Layout operation counters before flushing.
    Layout.emitFrameCounters();
    // Ensure the underlying sink paints promptly. Some terminals (and Dart IO
    // implementations) may buffer output until an explicit flush, and the UV
    // renderer in particular emits bytes through an intermediate writer.
    unawaited(_renderer!.flush());
  }

  /// Applies metadata from a [View] object to the terminal state.
  void _applyViewMetadata(View view) {
    if (view.windowTitle != null) {
      _applyWindowTitle(view.windowTitle!);
    } else {
      _applyWindowTitle(_options.startupTitle);
    }

    if (view.backgroundColor != null) {
      // OSC 11
      _terminal?.write('\x1b]11;${view.backgroundColor!.toHex()}\x07');
      _bgColorOverridden = true;
    } else if (_bgColorOverridden) {
      _terminal?.write('\x1b]111\x07');
      _bgColorOverridden = false;
    }

    if (view.foregroundColor != null) {
      // OSC 10
      _terminal?.write('\x1b]10;${view.foregroundColor!.toHex()}\x07');
      _fgColorOverridden = true;
    } else if (_fgColorOverridden) {
      _terminal?.write('\x1b]110\x07');
      _fgColorOverridden = false;
    }

    if (view.progressBar != null) {
      _terminal?.setProgressBar(
        view.progressBar!.state.index,
        view.progressBar!.value,
      );
      _progressBarOverridden =
          view.progressBar!.state != TerminalProgressBarState.none;
    } else {
      _resetProgressBarIfOverridden();
    }

    _viewAltScreenOverride = view.altScreen;
    _applyDynamicAltScreen();

    _setDesiredFocusReporting(view.reportFocus ?? false);

    _setDesiredBracketedPaste(view.bracketedPaste ?? _options.bracketedPaste);

    if (view.mouseMode != null) {
      if (TuiTrace.enabled) {
        _trace('view mouseMode=${view.mouseMode}');
      }
      _setDesiredMouseMode(view.mouseMode!);
    } else {
      _applyMouseMode();
    }

    var keyboardEnhancementFlags = 0;
    if (view.keyboardEnhancements != null) {
      keyboardEnhancementFlags = Ansi.kittyDisambiguateEscapeCodes;
      if (view.keyboardEnhancements!.reportEventTypes) {
        keyboardEnhancementFlags |= Ansi.kittyReportEventTypes;
      }
    }
    _setDesiredKeyboardEnhancementFlags(keyboardEnhancementFlags);

    if (view.cursor != null) {
      // Move cursor to position
      _terminal?.moveCursor(
        view.cursor!.position.y + 1,
        view.cursor!.position.x + 1,
      );
      // Set shape and blink
      final code = view.cursor!.shape.encode(blink: view.cursor!.blink);
      _terminal?.write('\x1b[$code q');
      _cursorStyleOverridden = code != CursorShape.block.encode(blink: true);
      // Set color if provided
      if (view.cursor!.color != null) {
        _terminal?.write(
          '\x1b]12;${(view.cursor!.color! as Color).toHex()}\x07',
        );
        _cursorColorOverridden = true;
      } else {
        _resetCursorColorOverride();
      }
    } else {
      _resetCursorColorOverride();
      _resetCursorStyleOverride();
    }
  }

  /// Forces a re-render, bypassing the skip-if-unchanged optimization.
  void _forceRender() {
    if (_model == null || _renderer == null) return;
    if (_terminalReleased) return;

    // Clear the renderer's cached view to force a full redraw
    _renderer!.clear();
    final view = _model!.view();

    if (view is View) {
      _lastView = view;
      _applyViewMetadata(view);
    } else {
      _resetViewScopedTerminalMetadata();
      _lastView = null;
    }

    _renderer!.render(view);
    _renderGeneration += 1;
    _lastRenderedView = view;
    final termSize = _terminal?.size;
    if (termSize != null) {
      _lastRenderWidth = termSize.width;
      _lastRenderHeight = termSize.height;
    }
    unawaited(_renderer!.flush());
  }

  /// Executes a command.
  Future<void> _executeCommand(Cmd cmd) async {
    // Handle parallel command - execute each command through proper dispatch
    if (cmd is ParallelCmd) {
      for (final c in cmd.commands) {
        unawaited(_executeCommand(c));
      }
      return;
    }

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
      if (msg != null) {
        // Command completion should flow through send() so the queue/ordering
        // invariants hold and interceptor hooks observe all messages.
        send(msg);
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
    _running = false; // Stop accepting new messages immediately
    _startupProbes?.abort();
    _deferredUntilAfterInitialRender.clear();
    _messageQueue.clear(); // Clear any pending messages
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
    _running = false; // Stop accepting new messages immediately
    _startupProbes?.abort();
    _messageQueue.clear(); // Clear any pending messages
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
    if (!_running || _options.altScreen || _appliedDynamicAltScreen) return;
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
    if (!_running || _options.altScreen || _appliedDynamicAltScreen) return;

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
  /// even if some cleanup operations fail. It is idempotent - calling it
  /// multiple times is safe and has no additional effect.
  ///
  /// Any errors that occur during cleanup are collected in [cleanupErrors]
  /// for debugging purposes, but do not prevent other cleanup operations
  /// from running.
  Future<void> _cleanup() async {
    // Guard against double cleanup
    if (_cleanedUp) return;
    _cleanedUp = true;

    // Helper to run cleanup operations and collect errors
    void trySync(void Function() operation) {
      try {
        operation();
      } catch (e) {
        _cleanupErrors.add(e);
      }
    }

    Future<void> tryAsync(Future<void> Function() operation) async {
      try {
        await operation();
      } catch (e) {
        _cleanupErrors.add(e);
      }
    }

    // Snapshot final model before clearing references
    _finalModel = _model;

    trySync(() => _uvInputTimeoutTimer?.cancel());
    _uvInputTimeoutTimer = null;
    trySync(() => _metricsTimer?.cancel());
    _metricsTimer = null;
    trySync(() => _frameTickTimer?.cancel());
    _frameTickTimer = null;
    _frameNumber = 0;
    _lastFrameTime = null;

    // Cancel input subscription
    await tryAsync(() async => _inputSubscription?.cancel());
    _inputSubscription = null;
    await tryAsync(() async => _replaySubscription?.cancel());
    _replaySubscription = null;
    _replayActive = false;
    await tryAsync(() async => _cancelSubscription?.cancel());
    _cancelSubscription = null;

    // Cancel signal subscriptions
    await tryAsync(() async => _sigintSubscription?.cancel());
    _sigintSubscription = null;

    await tryAsync(() async => _sigwinchSubscription?.cancel());
    _sigwinchSubscription = null;

    await tryAsync(() async => _backendResizeSubscription?.cancel());
    _backendResizeSubscription = null;

    await tryAsync(() async => _backendShutdownSubscription?.cancel());
    _backendShutdownSubscription = null;

    // Stop stream commands
    for (final cmd in _streamCommands) {
      await tryAsync(() async => cmd.cancel());
    }
    _streamCommands.clear();

    // Stop repeating commands
    for (final cmd in _everyCommands) {
      trySync(() => cmd.stop());
    }
    _everyCommands.clear();

    // Clear key parser buffer
    trySync(() => _keyParser.clear());
    trySync(() => _uvInputParser.clear());
    _startupProbes = null;
    _startupProbeContext = null;

    // Dispose renderer (this should restore cursor/alt screen)
    trySync(() => _renderer?.dispose());
    _renderer = null;

    trySync(() {
      _resetProgressBarIfOverridden();
      _resetTerminalColorOverrides();
    });

    // Restore terminal state (belt and suspenders approach)
    // Even if renderer.dispose() failed, try to restore these
    trySync(() {
      _disableAppliedTerminalModes();
    });

    // Flush all buffered escape sequences (alt-screen exit, cursor restore,
    // mouse disable) to stdout before disposing the terminal. Without this,
    // the sequences remain in the terminal's write buffer and are lost when
    // the process exits, leaving the terminal in a broken state (e.g. mouse
    // tracking still enabled, still in alt screen).
    await tryAsync(() async => _terminal?.flush());

    trySync(() => TuiTrace.close());
    trySync(() => _options.interceptor?.onStop());

    // Final terminal cleanup
    trySync(() => _terminal?.dispose());
    _terminal = null;
    _model = null;

    if (_options.shutdownSharedStdinOnExit && isSharedStdinStreamStarted) {
      await tryAsync(() async => shutdownSharedStdinStream());
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
  ProgramHost? host,
  TuiTerminal? terminal,
}) async {
  final program = Program<M>(
    model,
    options: options,
    host: host,
    terminal: terminal,
  );
  await program.run();
}

/// Runs a TUI program and returns the final model after exit.
Future<M> runProgramWithResult<M extends Model>(
  M model, {
  ProgramOptions options = const ProgramOptions(),
  ProgramHost? host,
  TuiTerminal? terminal,
}) async {
  final program = Program<M>(
    model,
    options: options,
    host: host,
    terminal: terminal,
  );
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
  ProgramHost? host,
  TuiTerminal? terminal,
}) async {
  final resolved = _resolveProgramHost(
    options: options ?? const ProgramOptions(),
    host: host,
    terminal: terminal,
  );
  final program = Program<M>._resolved(
    model,
    ProgramHostBinding(
      options: resolved.options.withoutCatchPanics(),
      terminal: resolved.terminal,
    ),
  );
  await program.run();
}

bool _isTerminalReportRequest(String data) {
  if (data.isEmpty) return false;

  final modeReportMatch = RegExp(r'^\x1b\[\??\d+(?:;\d+)*\$p');
  var remaining = data;
  var matchedAny = false;
  while (remaining.isNotEmpty) {
    if (remaining.startsWith(Ansi.requestForegroundColor)) {
      remaining = remaining.substring(Ansi.requestForegroundColor.length);
      matchedAny = true;
      continue;
    }
    if (remaining.startsWith(Ansi.requestBackgroundColor)) {
      remaining = remaining.substring(Ansi.requestBackgroundColor.length);
      matchedAny = true;
      continue;
    }
    if (remaining.startsWith(Ansi.requestCursorColor)) {
      remaining = remaining.substring(Ansi.requestCursorColor.length);
      matchedAny = true;
      continue;
    }
    if (remaining.startsWith(Ansi.requestColorScheme)) {
      remaining = remaining.substring(Ansi.requestColorScheme.length);
      matchedAny = true;
      continue;
    }
    if (remaining.startsWith(Ansi.requestModifyOtherKeys)) {
      remaining = remaining.substring(Ansi.requestModifyOtherKeys.length);
      matchedAny = true;
      continue;
    }
    if (remaining.startsWith('\x1b]4;')) {
      final belLen = _consumePaletteColorRequest(remaining, terminator: '\x07');
      final stLen = _consumePaletteColorRequest(remaining, terminator: '\x1b\\');
      final consumed = belLen > 0 ? belLen : stLen;
      if (consumed > 0) {
        remaining = remaining.substring(consumed);
        matchedAny = true;
        continue;
      }
    }
    if (remaining.startsWith(Ansi.requestPrimaryDeviceAttributes)) {
      remaining = remaining.substring(Ansi.requestPrimaryDeviceAttributes.length);
      matchedAny = true;
      continue;
    }
    if (remaining.startsWith(Ansi.requestSecondaryDeviceAttributes)) {
      remaining = remaining.substring(
        Ansi.requestSecondaryDeviceAttributes.length,
      );
      matchedAny = true;
      continue;
    }
    if (remaining.startsWith(Ansi.requestTertiaryDeviceAttributes)) {
      remaining = remaining.substring(
        Ansi.requestTertiaryDeviceAttributes.length,
      );
      matchedAny = true;
      continue;
    }
    if (remaining.startsWith(Ansi.requestTerminalVersion)) {
      remaining = remaining.substring(Ansi.requestTerminalVersion.length);
      matchedAny = true;
      continue;
    }
    if (remaining.startsWith('\x1bP+q')) {
      final consumed = _consumeXtGetTcapRequest(remaining);
      if (consumed > 0) {
        remaining = remaining.substring(consumed);
        matchedAny = true;
        continue;
      }
    }
    if (remaining.startsWith(Ansi.requestCursorPosition)) {
      remaining = remaining.substring(Ansi.requestCursorPosition.length);
      matchedAny = true;
      continue;
    }
    if (remaining.startsWith(Ansi.requestKittyKeyboard)) {
      remaining = remaining.substring(Ansi.requestKittyKeyboard.length);
      matchedAny = true;
      continue;
    }
    if (remaining.startsWith('\x1b[18t')) {
      remaining = remaining.substring('\x1b[18t'.length);
      matchedAny = true;
      continue;
    }
    if (remaining.startsWith('\x1b[14t')) {
      remaining = remaining.substring('\x1b[14t'.length);
      matchedAny = true;
      continue;
    }
    if (remaining.startsWith('\x1b[16t')) {
      remaining = remaining.substring('\x1b[16t'.length);
      matchedAny = true;
      continue;
    }
    final modeReport = modeReportMatch.matchAsPrefix(remaining);
    if (modeReport != null) {
      remaining = remaining.substring(modeReport.group(0)!.length);
      matchedAny = true;
      continue;
    }
    if (remaining.startsWith('\x1b]52;')) {
      final belLen = _consumeClipboardReadRequest(
        remaining,
        terminator: '\x07',
      );
      final stLen = _consumeClipboardReadRequest(
        remaining,
        terminator: '\x1b\\',
      );
      final consumed = belLen > 0 ? belLen : stLen;
      if (consumed > 0) {
        remaining = remaining.substring(consumed);
        matchedAny = true;
        continue;
      }
    }
    return false;
  }

  return matchedAny;
}

int _consumePaletteColorRequest(String text, {required String terminator}) {
  final end = text.indexOf(terminator);
  if (end <= 0) return 0;
  final payload = text.substring(0, end);
  final parts = payload.split(';');
  if (parts.length != 3 || parts[0] != '\x1b]4' || parts[2] != '?') {
    return 0;
  }
  if (int.tryParse(parts[1]) == null) return 0;
  return end + terminator.length;
}

int _consumeXtGetTcapRequest(String text) {
  const prefix = '\x1bP+q';
  if (!text.startsWith(prefix)) return 0;
  final end = text.indexOf('\x1b\\', prefix.length);
  if (end < 0) return 0;
  final payload = text.substring(prefix.length, end);
  if (payload.isEmpty) return 0;
  final parts = payload.split(';');
  final hexPart = RegExp(r'^[0-9a-fA-F]+$');
  if (parts.any((part) => part.isEmpty || part.length.isOdd || !hexPart.hasMatch(part))) {
    return 0;
  }
  return end + '\x1b\\'.length;
}

int _consumeClipboardReadRequest(String text, {required String terminator}) {
  if (!text.startsWith('\x1b]52;')) return 0;
  final end = text.indexOf(terminator);
  if (end <= 0) return 0;
  final payload = text.substring(0, end);
  final parts = payload.split(';');
  if (parts.length != 3 || parts[0] != '\x1b]52' || parts[2] != '?') {
    return 0;
  }
  if (parts[1].isEmpty) return 0;
  return end + terminator.length;
}
