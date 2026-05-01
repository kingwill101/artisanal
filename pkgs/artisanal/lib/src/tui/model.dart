import 'cmd.dart';
import 'msg.dart';

/// Abstract interface for TUI application models.
///
/// The [Model] represents the state of a TUI application and defines
/// the core functions of the Elm Architecture:
///
/// - [init] - Returns an optional command to run on startup
/// - [update] - Handles messages and returns new state + optional command
/// - [view] - Renders the current state as a string
///
/// {@category TUI}
///
/// {@macro artisanal_tui_tea_overview}
///
/// ## Example: Counter
///
/// ```dart
/// class CounterModel implements Model {
///   final int count;
///   CounterModel([this.count = 0]);
///
///   @override
///   Cmd? init() => null; // No initialization needed
///
///   @override
///   (Model, Cmd?) update(Msg msg) {
///     return switch (msg) {
///       KeyMsg(key: Key(type: KeyType.up)) =>
///         (CounterModel(count + 1), null),
///       KeyMsg(key: Key(type: KeyType.down)) =>
///         (CounterModel(count - 1), null),
///       KeyMsg(key: Key(type: KeyType.runes, runes: [0x71])) => // 'q'
///         (this, Cmd.quit()),
///       _ => (this, null),
///     };
///   }
///
///   @override
///   String view() => '''
/// Counter: $count
///
/// Press ↑/↓ to change, q to quit
/// ''';
/// }
/// ```
///
/// ## Example: Async Data Loading
///
/// ```dart
/// class DataModel implements Model {
///   final bool loading;
///   final List<String> items;
///   final String? error;
///
///   DataModel({this.loading = false, this.items = const [], this.error});
///
///   @override
///   Cmd? init() => Cmd.perform(
///     () => fetchItems(),
///     onSuccess: (items) => ItemsLoadedMsg(items),
///     onError: (e, _) => ErrorMsg(e.toString()),
///   );
///
///   @override
///   (Model, Cmd?) update(Msg msg) {
///     return switch (msg) {
///       ItemsLoadedMsg(:final items) =>
///         (DataModel(items: items), null),
///       ErrorMsg(:final message) =>
///         (DataModel(error: message), null),
///       KeyMsg(key: Key(type: KeyType.runes, runes: [0x72])) => // 'r' to refresh
///         (DataModel(loading: true), init()),
///       _ => (this, null),
///     };
///   }
///
///   @override
///   String view() {
///     if (loading) return 'Loading...';
///     if (error != null) return 'Error: $error\n\nPress r to retry';
///     return items.map((i) => '• $i').join('\n');
///   }
/// }
/// ```
abstract class Model {
  /// Creates a base model instance.
  const Model();

  /// Returns an optional command to execute on program startup.
  ///
  /// This is called once when the program starts, after the initial
  /// view has been rendered. Use it to:
  ///
  /// - Start timers for animations
  /// - Fetch initial data
  /// - Set up subscriptions
  ///
  /// Return `null` if no initialization is needed.
  Cmd? init() => null;

  /// Handles a message and returns the new model state and optional command.
  ///
  /// This is the heart of the Elm Architecture. When a message arrives
  /// (from user input, timers, async operations, etc.), this method:
  ///
  /// 1. Examines the message
  /// 2. Computes the new model state
  /// 3. Optionally returns a command to execute
  ///
  /// The returned tuple contains:
  /// - The new model (can be `this` if unchanged)
  /// - An optional command to execute (or `null`)
  ///
  /// ## Pattern Matching
  ///
  /// Dart's pattern matching makes update functions clean and readable:
  ///
  /// ```dart
  /// @override
  /// (Model, Cmd?) update(Msg msg) {
  ///   return switch (msg) {
  ///     // Match key type
  ///     KeyMsg(key: Key(type: KeyType.enter)) =>
  ///       (submitForm(), null),
  ///
  ///     // Match specific character
  ///     KeyMsg(key: Key(type: KeyType.runes, runes: [0x71])) =>
  ///       (this, Cmd.quit()),
  ///
  ///     // Match with modifier
  ///     KeyMsg(key: Key(ctrl: true, runes: [0x73])) => // Ctrl+S
  ///       (this, saveFile()),
  ///
  ///     // Match custom message with destructuring
  ///     DataLoadedMsg(:final items) =>
  ///       (copyWith(items: items, loading: false), null),
  ///
  ///     // Match window resize
  ///     WindowSizeMsg(:final width, :final height) =>
  ///       (copyWith(width: width, height: height), null),
  ///
  ///     // Default case - no change
  ///     _ => (this, null),
  ///   };
  /// }
  /// ```
  ///
  /// ## Immutability
  ///
  /// Models should be immutable. Create new instances rather than
  /// modifying existing ones:
  ///
  /// ```dart
  /// // ✓ Good - create new instance
  /// return (CounterModel(count + 1), null);
  ///
  /// // ✓ Good - use copyWith pattern
  /// return (copyWith(count: count + 1), null);
  ///
  /// // ✗ Bad - mutating state
  /// count++;
  /// return (this, null);
  /// ```
  (Model, Cmd?) update(Msg msg);

  /// Renders the current model state for display.
  ///
  /// This method is called after every update to refresh the screen.
  /// It should return either a [String] or a [View] object.
  ///
  /// ## Guidelines
  ///
  /// - Keep view functions pure - no side effects
  /// - View should only depend on model state
  /// - Use string interpolation or StringBuffer for complex views
  /// - Consider terminal width/height for responsive layouts
  ///
  /// ## Example
  ///
  /// ```dart
  /// @override
  /// String view() {
  ///   final buffer = StringBuffer();
  ///
  ///   // Header
  ///   buffer.writeln('╔════════════════════════════╗');
  ///   buffer.writeln('║      My Application        ║');
  ///   buffer.writeln('╚════════════════════════════╝');
  ///   buffer.writeln();
  ///
  ///   // Content
  ///   if (loading) {
  ///     buffer.writeln('Loading...');
  ///   } else {
  ///     for (final item in items) {
  ///       final prefix = item == selectedItem ? '▸ ' : '  ';
  ///       buffer.writeln('$prefix$item');
  ///     }
  ///   }
  ///
  ///   buffer.writeln();
  ///
  ///   // Footer
  ///   buffer.writeln('↑/↓: Navigate  Enter: Select  q: Quit');
  ///
  ///   return buffer.toString();
  /// }
  /// ```
  Object view();
}

/// Optional interface for models that want to control frame ticks.
///
/// When implemented, the runtime will only start the frame tick timer if
/// [wantsFrameTicks] is true.
abstract class FrameTickModel {
  /// Whether the model wants to receive frame tick messages.
  bool get wantsFrameTicks;
}

/// Optional interface for models that want render metrics updates.
///
/// When implemented, the runtime only starts the metrics timer if
/// [wantsRenderMetrics] is true.
abstract class RenderMetricsModel {
  /// Whether the model wants to receive render metrics updates.
  bool get wantsRenderMetrics;
}

/// Optional interface for models that support hot-reload reassembly.
///
/// When a model implements [ReassemblableModel], [Program.performReassemble]
/// calls [reassemble] before re-rendering. This gives the model a chance to
/// invalidate internal caches, mark element trees dirty, or perform any other
/// bookkeeping needed so that the next [Model.view] call produces fresh output
/// that reflects the reloaded code.
///
/// This follows the same opt-in pattern as [FrameTickModel] and
/// [RenderMetricsModel].
///
/// [WidgetApp] implements this interface to mark its entire element tree dirty
/// and clear its cached view, ensuring that widget `build()` methods are
/// re-executed after a hot reload.
abstract class ReassemblableModel {
  /// Called by the runtime immediately before re-rendering after a hot reload.
  ///
  /// Implementations should invalidate any cached state so that the next
  /// [Model.view] call rebuilds from scratch.
  void reassemble();
}

/// Mixin that documents the copyWith pattern for models.
///
/// Models can use this mixin to indicate they follow the copyWith pattern
/// for creating modified copies of themselves.
///
/// ```dart
/// class MyModel with CopyWithModel implements Model {
///   final int count;
///   final String name;
///
///   MyModel({this.count = 0, this.name = ''});
///
///   MyModel copyWith({int? count, String? name}) {
///     return MyModel(
///       count: count ?? this.count,
///       name: name ?? this.name,
///     );
///   }
///
///   // ... implement init, update, view
/// }
/// ```
mixin CopyWithModel {
  // This mixin serves as documentation for the copyWith pattern.
  // Actual implementation must be provided by the concrete class.
}

/// A model that wraps another model, useful for composition.
///
/// ```dart
/// class AppModel implements Model {
///   final HeaderModel header;
///   final ContentModel content;
///   final FooterModel footer;
///
///   // Delegate to child models and compose views
/// }
/// ```
abstract class CompositeModel implements Model {
  /// The child models that make up this composite.
  List<Model> get children;
}

/// Type alias for the update function return type.
///
/// Makes type signatures more readable:
///
/// ```dart
/// UpdateResult handleKeyPress(KeyMsg msg) {
///   // ...
///   return (newModel, cmd);
/// }
/// ```
typedef UpdateResult = (Model, Cmd?);

/// Helper function to create an update result with no command.
///
/// ```dart
/// return noCmd(newModel);
/// // equivalent to: return (newModel, null);
/// ```
UpdateResult noCmd(Model model) => (model, null);

/// Helper function to create an update result that quits.
///
/// ```dart
/// return quit(model);
/// // equivalent to: return (model, Cmd.quit());
/// ```
UpdateResult quit(Model model) => (model, Cmd.quit());

// ---------------------------------------------------------------------------
// Captured output support
// ---------------------------------------------------------------------------

/// A single entry in an [OutputLog].
///
/// Captures a line of output along with its [source] and [timestamp].
class OutputLogEntry {
  /// Creates an output log entry.
  const OutputLogEntry({
    required this.line,
    required this.source,
    required this.timestamp,
  });

  /// The captured output line.
  final String line;

  /// Where the output originated from.
  final OutputSource source;

  /// When the output was captured.
  final DateTime timestamp;

  @override
  String toString() => '[$source] $line';
}

/// An immutable, bounded log of captured output entries.
///
/// [OutputLog] is designed for use inside immutable [Model] classes.
/// Because models must be immutable, mutating methods like [add] and
/// [clear] return new [OutputLog] instances instead of modifying this
/// one in place.
///
/// Entries beyond [maxEntries] are dropped from the front (oldest
/// first), making this behave like a ring buffer.
///
/// ## Example
///
/// ```dart
/// class MyModel extends Model implements CapturedOutputModel {
///   final OutputLog outputLog;
///
///   MyModel({this.outputLog = const OutputLog()});
///
///   @override
///   MyModel withOutputLog(OutputLog log) =>
///       MyModel(outputLog: log);
///
///   // ...
/// }
/// ```
class OutputLog {
  /// Creates an empty output log.
  ///
  /// [maxEntries] controls how many entries are retained. Defaults
  /// to 500.
  const OutputLog({
    this.maxEntries = 500,
    List<OutputLogEntry> entries = const [],
  }) : _entries = entries;

  /// The maximum number of entries retained in this log.
  final int maxEntries;

  final List<OutputLogEntry> _entries;

  /// The log entries, oldest first.
  List<OutputLogEntry> get entries =>
      List<OutputLogEntry>.unmodifiable(_entries);

  /// The number of entries currently in the log.
  int get length => _entries.length;

  /// Whether the log contains no entries.
  bool get isEmpty => _entries.isEmpty;

  /// Whether the log contains at least one entry.
  bool get isNotEmpty => _entries.isNotEmpty;

  /// Returns a new [OutputLog] with [entry] appended.
  ///
  /// If the resulting log would exceed [maxEntries], the oldest
  /// entries are dropped.
  OutputLog add(OutputLogEntry entry) {
    final newEntries = [..._entries, entry];
    if (newEntries.length > maxEntries) {
      return OutputLog(
        maxEntries: maxEntries,
        entries: newEntries.sublist(newEntries.length - maxEntries),
      );
    }
    return OutputLog(maxEntries: maxEntries, entries: newEntries);
  }

  /// Returns a new [OutputLog] with a [CapturedOutputMsg] appended.
  ///
  /// Convenience method that creates an [OutputLogEntry] from a
  /// [CapturedOutputMsg] and appends it.
  OutputLog addMessage(CapturedOutputMsg msg) {
    return add(
      OutputLogEntry(
        line: msg.line,
        source: msg.source,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Returns a new empty [OutputLog] with the same [maxEntries].
  OutputLog clear() => OutputLog(maxEntries: maxEntries);

  @override
  String toString() => 'OutputLog(${_entries.length}/$maxEntries entries)';
}

/// Optional interface for models that receive captured output
/// automatically.
///
/// When a model implements [CapturedOutputModel] and
/// [ProgramOptions.captureOutput] is enabled, the runtime
/// automatically appends intercepted `print()` output to the
/// model's [outputLog] by calling [withOutputLog]. The model's
/// [update] method is **not** called for [CapturedOutputMsg] —
/// the runtime handles it entirely.
///
/// This follows the same opt-in pattern as [FrameTickModel] and
/// [RenderMetricsModel].
///
/// ## Example
///
/// ```dart
/// class DebugModel extends Model implements CapturedOutputModel {
///   final int count;
///   final OutputLog outputLog;
///
///   DebugModel({this.count = 0, this.outputLog = const OutputLog()});
///
///   @override
///   DebugModel withOutputLog(OutputLog log) =>
///       DebugModel(count: count, outputLog: log);
///
///   @override
///   (Model, Cmd?) update(Msg msg) {
///     // No need to handle CapturedOutputMsg here —
///     // the runtime does it automatically.
///     return switch (msg) {
///       KeyMsg(key: Key(type: KeyType.runes, runes: [0x71])) =>
///         (this, Cmd.quit()),
///       _ => (this, null),
///     };
///   }
///
///   @override
///   String view() {
///     final buf = StringBuffer('Count: $count\n\n');
///     buf.writeln('--- Output Log ---');
///     for (final entry in outputLog.entries) {
///       buf.writeln(entry);
///     }
///     return buf.toString();
///   }
/// }
/// ```
abstract class CapturedOutputModel {
  /// The current captured output log.
  OutputLog get outputLog;

  /// Returns a new model with the given [log] replacing [outputLog].
  ///
  /// This is called by the runtime when a [CapturedOutputMsg] is
  /// received. Implementations should return a copy of `this` with
  /// only the [outputLog] field replaced.
  Model withOutputLog(OutputLog log);
}
