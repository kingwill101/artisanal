library;

import '../command_palette.dart';

/// Executes an editor command against [target].
typedef EditorCommandHandler<T> = bool Function(T target);

/// Decides whether an editor command is currently available.
typedef EditorCommandPredicate<T> = bool Function(T target);

/// Stable IDs for commands shared by editor hosts.
abstract final class EditorCommandIds {
  static const undo = 'editor.action.undo';
  static const redo = 'editor.action.redo';
  static const selectAll = 'editor.action.selectAll';
  static const selectLine = 'editor.action.selectLine';
  static const clearSelection = 'editor.action.clearSelection';
  static const insertLineBreak = 'editor.action.insertLineBreak';
  static const addCursorAbove = 'editor.action.addCursorAbove';
  static const addCursorBelow = 'editor.action.addCursorBelow';
  static const addNextOccurrence = 'editor.action.addNextOccurrence';
  static const cursorLeft = 'editor.action.cursorLeft';
  static const cursorRight = 'editor.action.cursorRight';
  static const cursorWordLeft = 'editor.action.cursorWordLeft';
  static const cursorWordRight = 'editor.action.cursorWordRight';
  static const cursorLineStart = 'editor.action.cursorLineStart';
  static const cursorLineEnd = 'editor.action.cursorLineEnd';
  static const deleteLeft = 'editor.action.deleteLeft';
  static const deleteRight = 'editor.action.deleteRight';
  static const deleteWordLeft = 'editor.action.deleteWordLeft';
  static const deleteWordRight = 'editor.action.deleteWordRight';
  static const deleteLineLeft = 'editor.action.deleteLineLeft';
  static const deleteLineRight = 'editor.action.deleteLineRight';
  static const nextSearchMatch = 'editor.action.nextSearchMatch';
  static const previousSearchMatch = 'editor.action.previousSearchMatch';
  static const nextDiagnostic = 'editor.action.nextDiagnostic';
  static const previousDiagnostic = 'editor.action.previousDiagnostic';
}

/// A stable, discoverable editor operation.
///
/// Commands separate user intent from key events. A TUI, widget host, command
/// palette, or modal keymap can invoke the same operation by [id].
final class EditorCommand<T> {
  const EditorCommand({
    required this.id,
    required this.label,
    required this.execute,
    this.description = '',
    this.category = 'Editor',
    this.isEnabled,
  }) : assert(id != ''),
       assert(label != '');

  /// Stable identifier such as `editor.action.undo`.
  final String id;

  /// Short, user-facing command name.
  final String label;

  /// Longer explanation for command palettes and help surfaces.
  final String description;

  /// Palette grouping label.
  final String category;

  /// Optional contextual availability predicate.
  final EditorCommandPredicate<T>? isEnabled;

  /// Command implementation. Returns whether it changed or handled [target].
  final EditorCommandHandler<T> execute;

  /// Whether this command can execute against [target].
  bool enabledFor(T target) => isEnabled?.call(target) ?? true;
}

/// Result of dispatching a command through [EditorCommandRegistry].
enum EditorCommandDispatchResult {
  /// No command has the requested ID.
  notFound,

  /// The command exists but its context predicate rejected the target.
  disabled,

  /// The command ran and reported that it handled the request.
  handled,

  /// The command ran but reported no change.
  noChange,
}

/// Ordered registry of stable editor commands.
///
/// Registration rejects duplicate IDs by default so application and modal
/// layers cannot silently shadow each other. Explicit replacement is useful
/// for host-level customization.
final class EditorCommandRegistry<T> {
  final Map<String, EditorCommand<T>> _commands = <String, EditorCommand<T>>{};

  /// Commands in registration order.
  Iterable<EditorCommand<T>> get commands => _commands.values;

  /// Returns the command registered as [id], if any.
  EditorCommand<T>? operator [](String id) => _commands[id];

  /// Registers [command].
  ///
  /// Throws [StateError] for a duplicate ID unless [replace] is true.
  void register(EditorCommand<T> command, {bool replace = false}) {
    if (!replace && _commands.containsKey(command.id)) {
      throw StateError('Editor command already registered: ${command.id}');
    }
    _commands[command.id] = command;
  }

  /// Registers every command, applying the same duplicate policy.
  void registerAll(
    Iterable<EditorCommand<T>> commands, {
    bool replace = false,
  }) {
    for (final command in commands) {
      register(command, replace: replace);
    }
  }

  /// Removes [id], returning whether it existed.
  bool unregister(String id) => _commands.remove(id) != null;

  /// Commands currently enabled for [target], preserving registration order.
  Iterable<EditorCommand<T>> enabledCommands(T target) =>
      _commands.values.where((command) => command.enabledFor(target));

  /// Dispatches [id] against [target].
  EditorCommandDispatchResult dispatch(String id, T target) {
    final command = _commands[id];
    if (command == null) return EditorCommandDispatchResult.notFound;
    if (!command.enabledFor(target)) {
      return EditorCommandDispatchResult.disabled;
    }
    return command.execute(target)
        ? EditorCommandDispatchResult.handled
        : EditorCommandDispatchResult.noChange;
  }
}

/// UI-agnostic state for an editor command palette.
///
/// Hosts render [visibleCommands] however they prefer and forward text,
/// navigation, acceptance, and dismissal through this model.
final class EditorCommandPalette<T> {
  EditorCommandPalette({required this.registry, required this.target});

  /// Commands available to the palette.
  final EditorCommandRegistry<T> registry;

  /// Dispatch target used for availability checks and execution.
  final T target;

  final CommandPaletteController _controller = CommandPaletteController();

  /// Current filter text.
  String get query => _controller.query;
  set query(String value) => _controller.updateQuery(value);

  /// Whether the palette is accepting interaction.
  bool isOpen = false;

  /// Selected index within [visibleCommands].
  int get selectedIndex => _controller.selectedIndex;
  set selectedIndex(int value) => _controller.selectedIndex = value;

  /// Opens the palette and optionally supplies an initial [query].
  void open({String query = ''}) {
    isOpen = true;
    this.query = query;
    selectedIndex = 0;
  }

  /// Dismisses the palette and clears its transient state.
  void close() {
    isOpen = false;
    query = '';
    selectedIndex = 0;
  }

  /// Changes the filter and resets selection to its best match.
  void updateQuery(String value) {
    query = value;
    selectedIndex = 0;
  }

  /// Enabled commands matching [query], ordered by match quality.
  List<EditorCommand<T>> get visibleCommands {
    final enabled = registry.enabledCommands(target).toList(growable: false);
    final commandByItem = <CommandPaletteItem, EditorCommand<T>>{};
    final items = <CommandPaletteItem>[];
    for (final command in enabled) {
      final item = CommandPaletteItem(
        label: command.label,
        description: command.description,
        group: command.category,
        tags: [command.id],
      );
      items.add(item);
      commandByItem[item] = command;
    }
    _controller.updateItems(items);
    return List<EditorCommand<T>>.unmodifiable([
      for (final item in _controller.filteredItems) commandByItem[item]!,
    ]);
  }

  /// Currently selected command, if the filtered list is non-empty.
  EditorCommand<T>? get selectedCommand {
    final commands = visibleCommands;
    if (commands.isEmpty) return null;
    return commands[selectedIndex.clamp(0, commands.length - 1)];
  }

  /// Moves selection by [delta], wrapping at either end.
  bool moveSelection(int delta) {
    visibleCommands;
    return isOpen && delta != 0 && _controller.moveSelection(delta);
  }

  /// Executes the selected command and closes after a handled dispatch.
  EditorCommandDispatchResult executeSelected() {
    if (!isOpen) return EditorCommandDispatchResult.noChange;
    final command = selectedCommand;
    if (command == null) return EditorCommandDispatchResult.noChange;
    final result = registry.dispatch(command.id, target);
    if (result == EditorCommandDispatchResult.handled) close();
    return result;
  }
}

/// Associates a host-normalized key chord with a command.
///
/// Parsing terminal keys remains a host responsibility because TEA and widget
/// hosts use different event types. This value object provides one portable
/// binding representation after normalization.
final class EditorKeyBinding {
  const EditorKeyBinding({
    required this.chord,
    required this.commandId,
    this.when,
  }) : assert(chord != ''),
       assert(commandId != '');

  /// Normalized chord such as `ctrl+z` or `g g`.
  final String chord;

  /// Stable command ID to dispatch.
  final String commandId;

  /// Optional host-defined context expression.
  final String? when;
}

/// Ordered keymap with conflict detection.
final class EditorKeymap {
  final List<EditorKeyBinding> _bindings = <EditorKeyBinding>[];

  /// Bindings in priority order; later entries have higher priority.
  List<EditorKeyBinding> get bindings =>
      List<EditorKeyBinding>.unmodifiable(_bindings);

  /// Adds [binding], rejecting an identical chord/context unless [replace].
  void bind(EditorKeyBinding binding, {bool replace = false}) {
    final index = _bindings.indexWhere(
      (candidate) =>
          candidate.chord == binding.chord && candidate.when == binding.when,
    );
    if (index >= 0) {
      if (!replace) {
        throw StateError(
          'Editor key binding already registered: ${binding.chord}'
          '${binding.when == null ? '' : ' when ${binding.when}'}',
        );
      }
      _bindings.removeAt(index);
    }
    _bindings.add(binding);
  }

  /// Resolves [chord] using a host-provided context-expression evaluator.
  String? resolve(
    String chord, {
    bool Function(String expression)? evaluateWhen,
  }) {
    for (final binding in _bindings.reversed) {
      if (binding.chord != chord) continue;
      final when = binding.when;
      if (when == null || (evaluateWhen?.call(when) ?? false)) {
        return binding.commandId;
      }
    }
    return null;
  }
}
