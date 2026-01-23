/// Interactive TUI framework (Bubble Tea for Dart).
///
/// This library provides a framework for building interactive terminal
/// applications using the Elm Architecture (Model-Update-View).
///
/// {@category TUI}
///
/// ## Core Components
///
/// - **[Model]**: Represents the state of your application.
/// - **[Update]**: A function that handles messages and returns a new model and commands.
/// - **[View]**: A function that renders the current model into a string.
/// - **[Program]**: The runtime that manages the event loop and rendering.
/// - **[Bubbles]**: Reusable interactive widgets like text inputs, spinners, and lists.
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
///   String view() => 'Count: \$count\n\nUse ↑/↓ to change, q to quit';
/// }
///
/// void main() async {
///   await runProgram(CounterModel());
/// }
/// ```
///
/// ## The Elm Architecture
///
/// {@macro artisanal_tui_tea_overview}
///
/// ## Commands and Messages
///
/// {@macro artisanal_tui_commands_and_messages}
///
/// ## Program Lifecycle
///
/// {@macro artisanal_tui_program_lifecycle}
///
/// ## Rendering and Performance
///
/// {@macro artisanal_tui_rendering_overview}
///
/// {@template artisanal_tui_tea_overview}
/// The TUI runtime follows The Elm Architecture (TEA) pattern, which separates
/// state, logic, and presentation:
///
/// - **Model**: The state of your application. It should be immutable.
/// - **Update**: A pure function that takes a [Msg] and the current [Model],
///   and returns a new [Model] and an optional [Cmd].
/// - **View**: A pure function that takes the [Model] and returns a [String]
///   (or a [View] object for advanced metadata) representing the UI.
///
/// ```
/// ┌─────────────────────────────────────────────────────┐
/// │                     Program                          │
/// │                                                      │
/// │    ┌───────┐     ┌────────┐     ┌──────┐            │
/// │    │ Model │────▶│ update │────▶│ view │            │
/// │    └───────┘     └────────┘     └──────┘            │
/// │        ▲              │              │               │
/// │        │              │              ▼               │
/// │        │         ┌────────┐     ┌────────┐          │
/// │        └─────────│  Cmd   │     │ Screen │          │
/// │                  └────────┘     └────────┘          │
/// │                       │                              │
/// │                       ▼                              │
/// │                  ┌────────┐                          │
/// │                  │  Msg   │◀──── User Input          │
/// │                  └────────┘                          │
/// └─────────────────────────────────────────────────────┘
/// ```
/// {@endtemplate}
///
/// {@template artisanal_tui_commands_and_messages}
/// - **[Msg]**: Represents an event (key press, timer tick, network response).
/// - **[Cmd]**: Represents an effect to be performed by the runtime (quitting,
///   sending a message, running an external process).
///
/// Use [BatchMsg] to group multiple messages, and [BatchCmd] to group multiple
/// commands.
/// {@endtemplate}
///
/// {@template artisanal_tui_program_lifecycle}
/// 1. **Initialization**: The [Program] starts, calls `Model.init()`, and
///    executes the returned [Cmd].
/// 2. **Event Loop**: The program waits for input (stdin, signals, or commands).
/// 3. **Update**: When a [Msg] arrives, `Model.update(msg)` is called.
/// 4. **Render**: If the model changed, `Model.view()` is called and the
///    result is rendered to the terminal.
/// 5. **Termination**: The program exits when a [QuitMsg] is received or
///    `Cmd.quit()` is executed.
/// {@endtemplate}
///
/// {@template artisanal_tui_rendering_overview}
/// Artisanal supports multiple rendering strategies:
/// - **Standard**: Simple ANSI output for basic terminals.
/// - **Ultraviolet**: High-performance diff-based rendering with cell buffers.
/// - **ANSI Compression**: Minimizes output by removing redundant SGR sequences.
///
/// Configure these via [ProgramOptions].
/// {@endtemplate}
library;

export 'src/tui/tui.dart';
export 'src/tui/bubbles/bubbles.dart' hide ValidateFunc, PasteMsg;
