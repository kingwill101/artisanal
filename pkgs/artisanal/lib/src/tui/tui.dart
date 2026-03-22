/// Interactive TUI runtime using the Elm Architecture pattern.
///
/// This module provides a Bubble Tea-style framework for building
/// interactive terminal applications in Dart.
///
/// ## Core Concepts
///
/// - [Model] - Defines application state and the init/update/view contract
/// - [Msg] - Messages that trigger state updates
/// - [Cmd] - Async commands that produce messages
/// - [Program] - Event loop that manages the application lifecycle
///
/// ## Quick Start
///
/// ```dart
/// import 'package:artisanal/tui.dart';
///
/// class CounterModel implements Model {
///   final int count;
///   CounterModel([this.count = 0]);
///
///   @override
///   Cmd? init() => null;
///
///   @override
///   (Model, Cmd?) update(Msg msg) {
///     return switch (msg) {
///       KeyMsg(key: Key(type: KeyType.up)) =>
///         (CounterModel(count + 1), null),
///       KeyMsg(key: Key(type: KeyType.down)) =>
///         (CounterModel(count - 1), null),
///       KeyMsg(key: Key(type: KeyType.runes, runes: [0x71])) =>
///         (this, Cmd.quit()),
///       _ => (this, null),
///     };
///   }
///
///   @override
///   String view() => 'Count: $count\n\nUse ↑/↓ to change, q to quit';
/// }
///
/// void main() async {
///   await runProgram(CounterModel());
/// }
/// ```
///
/// ## The Elm Architecture
///
/// This module implements The Elm Architecture (TEA), a pattern for
/// building interactive applications:
///
/// 1. **Model** - The application state
/// 2. **Update** - How the state changes in response to messages
/// 3. **View** - How to render the state as output
///
/// Messages flow through the system:
/// - User input generates messages (KeyMsg, MouseMsg, etc.)
/// - Messages are sent to `update()` which produces new state
/// - The new state is rendered via `view()`
/// - Commands from `update()` may produce more messages
///
/// ## Message Types
///
/// Built-in message types:
/// - [KeyMsg] - Keyboard input
/// - [MouseMsg] - Mouse events (when enabled)
/// - [WindowSizeMsg] - Terminal resize events
/// - [TickMsg] - Timer events
///
/// Custom messages can extend [Msg]:
/// ```dart
/// class DataLoadedMsg extends Msg {
///   final List<Item> items;
///   DataLoadedMsg(this.items);
/// }
/// ```
///
/// ## Commands
///
/// Commands represent side effects:
/// - [Cmd.quit] - Exit the program
/// - [Cmd.tick] - Timer that fires once
/// - [Cmd.batch] - Run commands concurrently
/// - [Cmd.sequence] - Run commands in order
/// - [Cmd.perform] - Wrap async operations
library;

// Terminal abstraction
export 'terminal.dart'
    show
        TerminalBackend,
        TerminalDimensions,
        BackendTerminal,
        StdioTerminalBackend,
        EmbeddedTerminalBackend,
        TerminalBridge,
        SocketTerminalBackend,
        TerminalBridgeMessageType,
        TerminalBridgeMessage,
        TerminalBridgeJsonChannel,
        JsonTerminalBackend,
        WebSocketTerminalBackend,
        BrowserTerminalSessionHandler,
        BrowserTerminalHostServer,
        SocketTerminalSessionHandler,
        SocketTerminalHostServer,
        TuiTerminal,
        SplitTerminal,
        StdioTerminal,
        TtyTerminal,
        StringTerminal,
        RawModeGuard,
        TerminalState,
        sharedStdinStream,
        isSharedStdinStreamStarted,
        shutdownSharedStdinStream;

// Components
export 'component.dart' show ViewComponent, StaticComponent, ComponentHost;

// Key input
export 'key.dart' show Key, KeyType, KeyParser, Keys;

// Message types
export 'msg.dart'
    show
        Msg,
        KeyMsg,
        ClipboardMsg,
        ClipboardSelection,
        BackgroundColorMsg,
        ForegroundColorMsg,
        CursorColorMsg,
        ColorPaletteMsg,
        MouseMsg,
        MouseButton,
        MouseAction,
        MouseMode,
        HitTestMouseMsg,
        WindowSizeMsg,
        CursorPositionMsg,
        WindowPixelSizeMsg,
        CellSizeMsg,
        TickMsg,
        FrameTickMsg,
        QuitMsg,
        BatchMsg,
        FocusMsg,
        PasteMsg,
        CustomMsg,
        CapabilityMsg,
        TerminalVersionMsg,
        ModifyOtherKeysMsg,
        PrimaryDeviceAttributesMsg,
        SecondaryDeviceAttributesMsg,
        TertiaryDeviceAttributesMsg,
        KeyboardEnhancementsMsg,
        ModeReportValue,
        ModeReportMsg,
        ColorProfileMsg,
        ColorSchemeMsg,
        InterruptMsg,
        RepaintMsg,
        RenderMetricsMsg,
        RenderBudgetMsg,
        UvEventMsg;

// Terminal theme helper (background/dark-mode)
export 'theme.dart' show TerminalThemeState, TerminalThemeHost;

// Command system
export 'cmd.dart'
    show
        Cmd,
        StreamCmd,
        EveryCmd,
        ParallelCmd,
        CmdExtension,
        every,
        CmdFunc,
        CmdFunc1,
        // Control messages
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
        RepaintRequestMsg,
        ClipboardSetMethod,
        ClipboardSetMsg,
        ExecProcessMsg,
        ExecResult;

// Model interface
export 'model.dart'
    show
        Model,
        CopyWithModel,
        CompositeModel,
        UpdateResult,
        FrameTickModel,
        RenderMetricsModel,
        noCmd,
        quit;
export 'degradation.dart'
    show
        DegradationLevel,
        RenderBudgetOptions,
        RenderBudgetController,
        RenderBudgetState,
        ViewDegradation;
export 'pane_manager.dart'
    show
        PaneSplitDirection,
        PaneNavigationDirection,
        PaneSnapAlignment,
        PaneSnapTarget,
        PaneRect,
        SplitHandle,
        PaneLayout,
        PaneTreeNode,
        PaneLeaf,
        PaneSplit,
        TilingPaneManager;
export 'view.dart'
    show
        View,
        TerminalProgressBar,
        TerminalProgressBarState,
        KeyboardEnhancements;
export 'component.dart' show ViewComponent, ComponentHost;

// TuiRenderer
export 'renderer.dart'
    show
        TuiRenderer,
        TuiRendererOptions,
        FullScreenTuiRenderer,
        InlineTuiRenderer,
        UltravioletTuiRenderer,
        SimpleTuiRenderer,
        BufferedTuiRenderer,
        NullTuiRenderer,
        StringSinkTuiRenderer,
        TuiTerminalRendererExtension,
        RenderMetrics,
        compressAnsi;

// Program runtime
export 'program.dart'
    show
        ScreenMode,
        UiAnchor,
        ProgramHostResolver,
        ProgramHostBinding,
        ProgramHost,
        ProgramInterceptor,
        ProgramMacro,
        ProgramReplay,
        ProgramReplayStep,
        Program,
        ProgramOptions,
        MessageFilter,
        ProgramCancelledError,
        runProgram,
        runProgramWithResult,
        runProgramDebug;

// Replay scenario protocol + trace conversion.
export 'replay_protocol.dart'
    show
        ReplayScreen,
        ReplayCustomEvent,
        ReplayEventControl,
        ReplayEventDirective,
        ReplayEventHook,
        ReplayAction,
        ReplayScenario,
        ReplayMouseMsg,
        ReplayEventMsg,
        ReplayCoordinateInterceptor,
        ReplayTraceConversionOptions,
        ReplayTraceConversionResult,
        ReplayTraceConverter,
        replayScenarioStream;

// Harmonica helpers (spring, projectile) used by progress and demos
export 'harmonica.dart'
    show
        Spring,
        Projectile,
        Point,
        Vector,
        gravity,
        terminalGravity,
        fpsDelta,
        newSpringFromFps;

// Zone-based mouse click tracking (BubbleZone port)
export 'zone/zone.dart'
    show
        ZoneManager,
        ZoneInfo,
        ZoneInBoundsMsg,
        zone,
        globalZone,
        hasGlobalZone,
        initGlobalZone,
        closeGlobalZone;

// Trace / debug logging
export 'trace.dart'
    show TuiTrace, TraceTag, TraceSpan, TraceEventType, TraceEventRecord;

// Structured runtime evidence logging
export 'evidence.dart' show TuiEvidence, TuiEvidenceRecord;

// Stable high-level widget system for composable components.
//
// This keeps `package:artisanal/tui.dart` backward-compatible while routing
// consumers through the package-level stabilized widget entrypoint.
export '../../widgets.dart' hide Key, LocalKey, UniqueKey, ValueKey;
