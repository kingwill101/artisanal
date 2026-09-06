# Editor fundamentals

This guide covers the data model shared by every editor host. Import it with:

```dart
import 'package:artisanal/editor_core.dart';
```

## Documents

`TextDocument` stores text as lines and graphemes while exposing both offset
and line/column access:

```dart
final document = TextDocument(text: 'A👩‍💻\nsecond');

print(document.lineCount); // 2
print(document.length); // graphemes, including the newline
print(document.lineAt(0)); // A👩‍💻

final offset = document.offsetForPosition(
  const TextPosition(line: 1, column: 2),
);
final position = document.positionForOffset(offset);
```

Use these APIs rather than Dart `String` indexing when editor coordinates are
involved:

- `graphemeAt(offset)`
- `lineAt(line)` and `lineGraphemesAt(line)`
- `lineLength(line)`
- `lineStartOffset(line)` and `lineEndOffset(line)`
- `textInRange(startOffset:, endOffset:)`
- `graphemesInRange(startOffset:, endOffset:)`
- `offsetForPosition(position)` and `positionForOffset(offset)`

`TextDocument` always has at least one logical line. Its `revision` increases
when content changes.

## Copy and mutate

`copy()` creates an independent document that initially shares immutable
storage:

```dart
final before = TextDocument(text: 'hello');
final after = before.copy();

final change = after.replaceTextRange(
  startOffset: 5,
  endOffset: 5,
  replacement: ' world',
);

assert(before.text == 'hello');
assert(after.text == 'hello world');
assert(change.insertedLength == 6);
```

Prefer targeted mutations when you know the changed range:

- `replaceTextRange` accepts a `String`.
- `replaceOffsetRange` accepts already-split graphemes.
- `replaceLineTextRange` replaces a logical line window.
- `replaceText`, `replaceLines`, and `replaceLineTexts` replace all content.

Targeted methods return `TextDocumentChange`, which language services and
anchored data can use for incremental updates.

## Changes

`TextDocumentChange` describes one replacement in both coordinate systems:

```dart
final change = document.replaceTextRange(
  startOffset: 0,
  endOffset: 1,
  replacement: 'Header',
);

print(change.startOffset);
print(change.oldEndOffset);
print(change.newEndOffset);
print(change.startPosition.line);
print(change.newEndPosition.column);
```

When a host receives complete before/after text rather than a known edit, use
`computeTextDocumentChange` or `computeTextDocumentChangeForDocuments`.

## Cursor and single selection state

`EditorState` stores a line/column cursor and one directional selection:

```dart
final state = EditorState(line: 0, column: 0);

state.moveCursorTo(const TextPosition(line: 1, column: 2));
state.beginSelection();
state.extendSelectionTo(const TextPosition(line: 1, column: 5));

print(state.selection?.start.column); // normalized start
print(state.selection?.end.column); // normalized end
print(state.selection?.base.column); // original anchor
print(state.selection?.extent.column); // moving edge
```

The direction matters for keyboard selection. `start` and `end` normalize the
range, while `base` and `extent` preserve its direction.

## Offset and line snapshots

Pure editing functions use immutable snapshots:

- `TextOffsetStateSnapshot` uses document offsets.
- `TextLineStateSnapshot` uses `TextPosition`s.

```dart
final collapsed = TextOffsetStateSnapshot.collapsed(cursorOffset: 4);
final selected = TextOffsetStateSnapshot.selection(
  baseOffset: 2,
  extentOffset: 8,
);
```

These values make it practical to run editing rules in tests, servers, or
custom hosts without constructing `TextAreaModel`.

## Multiple selections

`TextSelectionSet` holds sorted, non-overlapping offset ranges. Collapsed
ranges are cursors:

```dart
var selections = TextSelectionSet([
  const TextSelectionRange(startOffset: 1, endOffset: 1),
  TextSelectionRange.directional(anchorOffset: 12, activeOffset: 8),
], primaryOffset: 8);

selections = selections.add(
  const TextSelectionRange(startOffset: 20, endOffset: 20),
);
```

Construction normalizes bounds and merges overlapping or touching ranges.
`TextSelectionRange` retains direction separately: `anchorOffset` is fixed,
`activeOffset` moves, and `isReversed` reports whether the active edge is the
lower bound. Use `TextSelectionRange.directional` when constructing from
anchor/active offsets. Use `primary` for status displays and provider requests.
Use `applyInsertion`/`applyDeletion` when maintaining selection state outside
an integrated editor.

For direct list-based transformations,
`insertTextAtEachSelection` and the other multi-range helpers apply edits in
descending offset order so earlier offsets remain stable.

## Range transforms

`EditorRangeResolver` is the host-independent motion contract:

```dart
typedef EditorRangeResolver = TextSelectionSet Function(
  TextDocument document,
  TextSelectionSet current,
);
```

The range helpers are:

- `mapSelectionRanges`, which transforms every complete range and preserves
  the primary selection;
- `mapSelectionEnds`, which moves or extends every range's active edge while
  preserving its anchor;
- `textOffsetOnAdjacentVisibleLine`, which resolves fold-aware vertical
  movement and accepts a preferred column retained by the host.

When `mapSelectionEnds` moves instead of extending, a directional motion first
collapses an existing selection toward that direction. This is the usual arrow
key behavior and applies identically to a single selection and a selection set.
Repeated backward extension remains backward, and crossing the anchor changes
direction without changing the anchor.

For vertical movement, capture the cursor column at the start of a movement
sequence and pass it back as `preferredColumn`. Short lines clamp the resulting
offset without replacing that preference, so a later long line restores the
intended column. Reset the preference after horizontal movement or editing.

A host can package a structural motion as an `EditorRangeResolver` and apply it
to every selection rather than duplicating single- and multi-cursor paths.

Use one resolver for:

- moving every cursor;
- extending every selection;
- character, word, line, or syntax-node motions;
- fold-aware vertical navigation.

This is especially useful for Vim-like or structural editing layers: the mode
decides which resolver to invoke, while document and selection rules remain in
the shared core.

## Extmarks

`TextExtmarksController` tracks arbitrary anchored ranges as edits occur.
Extmarks are appropriate for bookmarks, breakpoints, semantic anchors, or
virtual annotations:

```dart
final marks = TextExtmarksController();
final id = marks.create(
  const TextExtmarkOptions(
    startOffset: 3,
    endOffset: 8,
    type: 'bookmark',
    styleKey: 'bookmark.active',
    data: {'name': 'entry'},
  ),
);

marks.applyInsertion(offset: 0, text: '// ');
final moved = marks.get(id);
```

Call `applyInsertion`, `applyDeletion`, or `applyReplacement` for every
document edit. Query marks with `getAtOffset`, `getAllForType`, and
`getVirtual`.

## Extmarks, decorations, placeholders, and inline elements

These types solve different problems:

| Type | Purpose |
|---|---|
| `TextExtmark` | Long-lived anchored metadata that tracks edits |
| `TextDecorationRange` | A semantic style span for the current render state |
| `TrackedPlaceholderRange` | Display text that expands to hidden full text |
| `InlineElement` | A typed document span associated with host-owned sidecar data |
| `TextDiagnosticRange` | A problem span with severity and message |

Do not use marker text alone as identity. Keep a stable extmark or inline
element ID and associate external records with that ID.

## Coordinate checklist

When integrating another protocol:

1. Determine whether its offsets are UTF-8 bytes, UTF-16 code units, Unicode
   scalars, graphemes, or line/column positions.
2. Convert into `TextDocument` grapheme coordinates at the boundary.
3. Keep all editor operations in grapheme coordinates.
4. Convert back only when calling the external protocol.

The pure `applyFileEdits`/`applyWorkspaceEdit` helpers operate on Dart
`String.substring` indexes and therefore use UTF-16 code units. Treat them as
an external string boundary rather than mixing their offsets into
`TextDocument` operations.

`TextPositionDiagnosticRange.toOffsetRange(document)` performs the
line/column-to-offset conversion for diagnostics already expressed in editor
line and column coordinates.
