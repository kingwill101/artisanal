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

export 'runtime.dart';
export 'rendering.dart';
export 'automation.dart';

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
export 'zone/zone_info.dart';
export 'zone/zone_manager.dart';
export 'zone/zone_scanner.dart';

// Low-level text editing primitives
export 'editor_core/editor_core.dart' hide TextSelection;

// Markdown to ANSI rendering
export 'markdown/markdown.dart';

// Capability / startup probes
export 'background_color_probe.dart';
export 'emoji_width_probe.dart';
export 'startup_probe.dart';
export 'uv_capability_probe.dart';

// Hot reload (conditional per-platform stub on web)
export 'hot_reload_mixin.dart';

// Misc runtime helpers
export 'replay_harness_mixin.dart';
export 'resize_coalescer.dart';
export 'program_host_io.dart';
