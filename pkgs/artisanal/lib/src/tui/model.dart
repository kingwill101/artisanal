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
