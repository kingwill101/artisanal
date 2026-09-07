# Editing and commands

The editor core supports two complementary styles:

- pure functions that return a changed document and state; and
- `TextAreaModel`, which combines those rules with history, commands, paste
  scheduling, rendering state, and TEA messages.

## Pure editing functions

Pure editing functions accept a `TextDocument` plus an immutable state
snapshot and return a result:

```dart
final document = TextDocument(text: 'hello');
final state = TextOffsetStateSnapshot.collapsed(cursorOffset: 5);

final result = textInsertText(
  document: document,
  state: state,
  text: ' world',
);

if (result.changed) {
  final nextDocument = result.document!;
  final nextState = TextOffsetStateSnapshot.collapsed(
    cursorOffset: result.cursorOffset,
  );
  print(nextDocument.text);
}
```

`TextCommandResult` may carry a `document`, cursor/selection offsets, and a
`TextDocumentChange`. `TextCursorCommandResult` changes only cursor state.
`TextLineCommandResult` operates on line text and line/column state.

### Available operation families

- Insertion and deletion: selection replacement, previous/next grapheme,
  previous/next word, and deletion to line boundaries.
- Navigation: character, word, document boundary, visual line, and visual line
  boundary.
- Selection transforms: selection/line case conversion, wrapping, unwrapping,
  and adjacent-word transforms.
- Line operations: split, join, indent, outdent, move, duplicate, delete,
  whitespace cleanup, and sorting.
- Markdown-like operations: line prefixes, numbered lists, headings, and
  checklists.
- Code behavior: auto-pairs, pair backspace, closing-delimiter alignment,
  indented newline, and block comments.

Use the `text*Document` variant when one exists to preserve
`TextDocumentChange` and incremental storage behavior.

## Integrated editing with `TextAreaModel`

```dart
import 'package:artisanal/bubbles.dart';
import 'package:artisanal/editor_core.dart';

final editor = TextAreaModel(
  width: 100,
  height: 30,
  showLineNumbers: true,
  useVirtualCursor: true,
)
  ..setText('one\ntwo\nthree', recordHistory: false)
  ..focus();

editor.setSelections(
  TextSelectionSet([
    const TextSelectionRange(startOffset: 0, endOffset: 0),
    const TextSelectionRange(startOffset: 4, endOffset: 4),
  ]),
);
editor.insertString('> ');
```

Useful state:

- `value`, `document`, `lineCount`, and `length`
- `line`, `column`, `cursorOffset`, and `editorState`
- `selections`, `hasSelection`, and `hasMultipleSelections`
- `canUndo`, `canRedo`, and `isDirty`
- `consumeLastDocumentChange()` for incremental tooling

## Transactions and history

`TextAreaModel` records normal edits automatically:

```dart
editor.insertString('first');
editor.undo();
editor.redo();
```

Use `editTransaction` when several operations should be one undo step:

```dart
editor.editTransaction((model) {
  model.insertString('/* ');
  model.insertString(' */');
});
```

Use:

- `pushHistoryBoundary()` to stop adjacent edits from coalescing;
- `clearHistory()` after loading a document that should become the new
  baseline;
- `markSaved()` after a durable save.

Programmatic calls that conceptually belong to one user action should be
wrapped in one transaction rather than manually manipulating history.

## Multiple cursors

The integrated editor exposes commands for:

- adding a cursor above or below;
- adding the next occurrence of the current selection;
- moving all cursors horizontally, vertically, by word, or to line boundaries;
- extending all selections;
- inserting and deleting at all selections;
- indenting, outdenting, moving, duplicating, and deleting selected lines.

```dart
editor
  ..selectCurrentLine()
  ..addNextOccurrence();

editor.executeCommand(EditorCommandIds.cursorWordRight);
editor.executeCommand(EditorCommandIds.insertText, argument: 'value');
```

Multi-range edits are applied from highest offset to lowest. This avoids
invalidating ranges that have not yet been processed.

## Stable commands

`EditorCommand` separates intent from keyboard events:

```dart
final registry = EditorCommandRegistry<TextAreaModel>()
  ..register(
    EditorCommand(
      id: 'app.editor.format',
      label: 'Format Document',
      category: 'Source',
      isEnabled: (editor) => editor.length > 0,
      execute: (editor) => editor.cleanupWhitespace(),
    ),
  );

final result = registry.dispatch('app.editor.format', editor);
```

A command has:

- a stable `id`;
- user-facing `label`, `description`, and `category`;
- an optional `isEnabled` predicate;
- an `execute` handler;
- an optional `executeWith` handler for arguments such as inserted text or
  snippet source.

Duplicate IDs are rejected unless `replace: true` is explicit. This prevents a
plugin or mode from silently shadowing another command.

`TextAreaModel.commandRegistry` is pre-populated with shared
`EditorCommandIds`. Invoke it through `executeCommand`; add application
commands to the same registry so keyboard shortcuts and palettes share one
source of truth.

`TextAreaModel.update` uses this registry for ordinary editing too. Typed
characters dispatch `EditorCommandIds.insertText` with an argument; newline,
arrows, word/line/document motions, deletion, indentation, and folds dispatch
their corresponding IDs. There is no separate private behavior path for those
keys.
Transpose and word-case bindings likewise dispatch `transposeCharacters`,
`uppercaseWord`, `lowercaseWord`, and `capitalizeWord`, so palettes and modal
hosts can invoke the same undoable transforms.
The registry also exposes line joining/splitting, whitespace cleanup, sorting,
and selection-or-line case conversion. These operations are available to
command palettes without requiring a terminal key binding.
`wrapSelection` accepts either a string for symmetric delimiters or an
`EditorWrapSelectionArgument` for distinct opening and closing text;
`unwrapSelection` removes recognized surrounding pairs.
Markdown-oriented commands expose prefix toggling, numbered-list
toggle/renumber, heading toggle, and checklist state. Their optional arguments
use simple portable values: `String` for prefixes/markers and `int` for list
starts/heading levels.

This means a host may consume a key before `TextAreaModel.update` and dispatch
the same command itself:

```dart
editor.executeCommand(EditorCommandIds.cursorWordRight);
editor.executeCommand(EditorCommandIds.insertText, argument: 'value');
```

The host changes input policy, not editing semantics.

## Portable keymaps

The editor core does not parse terminal key events. Normalize host events into
chords, then resolve them with `EditorKeymap`:

```dart
final keymap = EditorKeymap()
  ..bind(
    const EditorKeyBinding(
      chord: 'ctrl+z',
      commandId: EditorCommandIds.undo,
    ),
  )
  ..bind(
    const EditorKeyBinding(
      chord: 'g g',
      commandId: EditorCommandIds.cursorDocumentStart,
      when: 'mode == normal',
    ),
  );

final commandId = keymap.resolve(
  'g g',
  evaluateWhen: (expression) => expression == 'mode == normal',
);
```

Later bindings have higher priority. `when` expressions are opaque strings;
the host supplies their evaluator.

## Command palettes

`EditorCommandPalette<T>` filters enabled commands, maintains selection, and
dispatches the selected command:

```dart
final palette = EditorCommandPalette(
  registry: editor.commandRegistry,
  target: editor,
)..open();

palette.updateQuery('undo');
palette.moveSelection(1);
final result = palette.executeSelected();
```

This is UI-independent state. TEA hosts can use
`CommandPaletteOverlay`/`CommandPaletteComponent` from `bubbles.dart`; widget
hosts use the themed widget component. Both delegate matching, selection, and
visible-window calculation to the same Artisanal command-palette controller.

Always render a bounded window instead of slicing the first N commands. Use
`visibleWindow(viewportSize:)` so moving the selection keeps it on screen.

## Modal editing

A modal editor should layer modes over commands rather than fork document
operations:

1. Normalize an event into a chord.
2. Resolve the chord in the active mode/context.
3. Dispatch a stable command or apply an `EditorRangeResolver`.
4. Render the mode separately in the status line.

Insert, normal, visual, and operator-pending modes can therefore share the
same document, undo, selection, folding, diagnostics, and tooling sessions.
