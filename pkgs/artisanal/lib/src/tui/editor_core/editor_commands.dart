library;

import '../command_palette.dart';

/// Executes an editor command against [target].
typedef EditorCommandHandler<T> = bool Function(T target);

/// Executes an editor command with a host-supplied argument such as insert text.
typedef EditorCommandArgumentHandler<T> =
    bool Function(T target, Object? argument);

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
  static const insertText = 'editor.action.insertText';
  static const cursorDocumentStart = 'editor.action.cursorDocumentStart';
  static const cursorDocumentEnd = 'editor.action.cursorDocumentEnd';
  static const selectDocumentStart = 'editor.action.selectDocumentStart';
  static const selectDocumentEnd = 'editor.action.selectDocumentEnd';
  static const addCursorAbove = 'editor.action.addCursorAbove';
  static const addCursorBelow = 'editor.action.addCursorBelow';
  static const addNextOccurrence = 'editor.action.addNextOccurrence';
  static const cursorLeft = 'editor.action.cursorLeft';
  static const cursorRight = 'editor.action.cursorRight';
  static const cursorWordLeft = 'editor.action.cursorWordLeft';
  static const cursorWordRight = 'editor.action.cursorWordRight';
  static const cursorLineStart = 'editor.action.cursorLineStart';
  static const cursorLineEnd = 'editor.action.cursorLineEnd';
  static const cursorVisualLineStart = 'editor.action.cursorVisualLineStart';
  static const cursorVisualLineEnd = 'editor.action.cursorVisualLineEnd';
  static const cursorPageUp = 'editor.action.cursorPageUp';
  static const cursorPageDown = 'editor.action.cursorPageDown';
  static const deleteLeft = 'editor.action.deleteLeft';
  static const deleteRight = 'editor.action.deleteRight';
  static const deleteWordLeft = 'editor.action.deleteWordLeft';
  static const deleteWordRight = 'editor.action.deleteWordRight';
  static const deleteLineLeft = 'editor.action.deleteLineLeft';
  static const deleteLineRight = 'editor.action.deleteLineRight';
  static const transposeCharacters = 'editor.action.transposeCharacters';
  static const uppercaseWord = 'editor.action.uppercaseWord';
  static const lowercaseWord = 'editor.action.lowercaseWord';
  static const capitalizeWord = 'editor.action.capitalizeWord';
  static const uppercaseSelectionOrLine =
      'editor.action.uppercaseSelectionOrLine';
  static const lowercaseSelectionOrLine =
      'editor.action.lowercaseSelectionOrLine';
  static const capitalizeSelectionOrLine =
      'editor.action.capitalizeSelectionOrLine';
  static const cleanupWhitespace = 'editor.action.cleanupWhitespace';
  static const joinLines = 'editor.action.joinLines';
  static const splitLine = 'editor.action.splitLine';
  static const sortSelectedLines = 'editor.action.sortSelectedLines';
  static const wrapSelection = 'editor.action.wrapSelection';
  static const unwrapSelection = 'editor.action.unwrapSelection';
  static const toggleLinePrefix = 'editor.action.toggleLinePrefix';
  static const toggleNumberedList = 'editor.action.toggleNumberedList';
  static const renumberNumberedList = 'editor.action.renumberNumberedList';
  static const toggleHeading = 'editor.action.toggleHeading';
  static const toggleChecklist = 'editor.action.toggleChecklist';
  static const nextSearchMatch = 'editor.action.nextSearchMatch';
  static const previousSearchMatch = 'editor.action.previousSearchMatch';
  static const nextDiagnostic = 'editor.action.nextDiagnostic';
  static const previousDiagnostic = 'editor.action.previousDiagnostic';
  static const cursorUp = 'editor.action.cursorUp';
  static const cursorDown = 'editor.action.cursorDown';
  static const selectLeft = 'editor.action.selectLeft';
  static const selectRight = 'editor.action.selectRight';
  static const selectUp = 'editor.action.selectUp';
  static const selectDown = 'editor.action.selectDown';
  static const selectWordLeft = 'editor.action.selectWordLeft';
  static const selectWordRight = 'editor.action.selectWordRight';
  static const selectLineStart = 'editor.action.selectLineStart';
  static const selectLineEnd = 'editor.action.selectLineEnd';
  static const selectVisualLineStart = 'editor.action.selectVisualLineStart';
  static const selectVisualLineEnd = 'editor.action.selectVisualLineEnd';
  static const selectPageUp = 'editor.action.selectPageUp';
  static const selectPageDown = 'editor.action.selectPageDown';
  static const indentLines = 'editor.action.indentLines';
  static const outdentLines = 'editor.action.outdentLines';
  static const deleteLine = 'editor.action.deleteLine';
  static const duplicateLine = 'editor.action.duplicateLine';
  static const moveLineUp = 'editor.action.moveLineUp';
  static const moveLineDown = 'editor.action.moveLineDown';
  static const toggleFold = 'editor.action.toggleFold';
  static const foldAll = 'editor.action.foldAll';
  static const unfoldAll = 'editor.action.unfoldAll';
  static const goToMatchingBracket = 'editor.action.jumpToBracket';
  static const insertSnippet = 'editor.action.insertSnippet';
  static const nextSnippetPlaceholder = 'editor.action.nextSnippetPlaceholder';
  static const previousSnippetPlaceholder =
      'editor.action.previousSnippetPlaceholder';
}

/// Delimiters supplied to the argument-taking `wrapSelection` command.
final class EditorWrapSelectionArgument {
  const EditorWrapSelectionArgument(this.before, {this.after});

  /// Text inserted before the selection.
  final String before;

  /// Text inserted after the selection, or [before] when omitted.
  final String? after;
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
    this.executeWith,
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

  /// Optional argument-taking implementation (insert text, snippet source).
  final EditorCommandArgumentHandler<T>? executeWith;

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
  ///
  /// When [argument] is supplied and the command defines [EditorCommand.executeWith],
  /// that handler runs. Otherwise [EditorCommand.execute] runs.
  EditorCommandDispatchResult dispatch(
    String id,
    T target, {
    Object? argument,
  }) {
    final command = _commands[id];
    if (command == null) return EditorCommandDispatchResult.notFound;
    if (!command.enabledFor(target)) {
      return EditorCommandDispatchResult.disabled;
    }
    final handled = command.executeWith != null && argument != null
        ? command.executeWith!(target, argument)
        : command.execute(target);
    return handled
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

  final CommandPaletteController controller = CommandPaletteController();

  /// Current filter text.
  String get query => controller.query;
  set query(String value) => controller.updateQuery(value);

  /// Whether the palette is accepting interaction.
  bool isOpen = false;

  /// Selected index within [visibleCommands].
  int get selectedIndex => controller.selectedIndex;
  set selectedIndex(int value) => controller.selectedIndex = value;

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
    controller.updateItems([
      for (final command in enabled)
        CommandPaletteItem(
          id: command.id,
          payload: command,
          label: command.label,
          description: command.description,
          group: command.category,
          tags: [command.id, if (command.category.isNotEmpty) command.category],
        ),
    ]);
    return List<EditorCommand<T>>.unmodifiable([
      for (final item in controller.filteredItems) _commandFor(item),
    ]);
  }

  /// Visible slice of [visibleCommands] that keeps the selection on screen.
  CommandPaletteWindow visibleWindow({int viewportSize = 7}) {
    visibleCommands;
    return controller.visibleWindow(viewportSize: viewportSize);
  }

  EditorCommand<T> _commandFor(CommandPaletteItem item) {
    final payload = item.payload;
    if (payload is EditorCommand<T>) return payload;
    final id = item.id;
    if (id != null) {
      final command = registry[id];
      if (command != null) return command;
    }
    throw StateError('Palette item missing command identity: ${item.label}');
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
    return isOpen && delta != 0 && controller.moveSelection(delta);
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
