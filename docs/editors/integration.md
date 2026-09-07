# Editor host integration

Editor core supplies reusable state and rules. A complete host still owns
events, effects, files, overlays, process lifecycle, and styling.

## Responsibility split

| Editor core or `TextAreaModel` | Host |
|---|---|
| Document and grapheme coordinates | Open/read/write files |
| Cursor and selection transforms | Normalize terminal/widget input |
| Undo/redo and edit transactions | Choose shortcuts and modal contexts |
| Search, diagnostics, syntax sessions | Render search/tooling overlays |
| Completion/code-action request sessions | Connect LSP or other providers |
| Fold projection and view geometry | Draw borders, headers, and status bars |
| Persistence contract and snapshots | Implement database/file/browser store |
| Inline element range tracking | Own attachment/paste sidecars and cleanup |

## TEA integration

Forward unhandled messages to the editor and return its command:

```dart
@override
(Model, Cmd?) update(Msg msg) {
  switch (msg) {
    case WindowSizeMsg(width: final width, height: final height):
      editor
        ..setWidth(width)
        ..setHeight((height - 2).clamp(1, height));
    case KeyMsg(:final key) when palette.isOpen:
      // Give the focused overlay first chance to consume the key.
      return handlePaletteKey(key);
  }

  final (next, cmd) = editor.update(msg);
  editor = next;
  return (this, cmd);
}
```

Rules for a predictable host:

1. Focused overlays receive input before the editor.
2. Global quit/save shortcuts run before ordinary text insertion.
3. Unhandled input reaches `TextAreaModel.update`.
4. Commands returned by completion, code-action, syntax, or persistence
   requests are returned to the TEA runtime.
5. Window size updates the editor's **content** size, not the whole screen.

Use `ProgramOptions(altScreen: true, bracketedPaste: true)` for a conventional
full-screen editor.

## Widget integration

For widget applications:

```dart
import 'package:artisanal_widgets/editors.dart';
```

The stable widget entrypoint exposes:

- `TextField` and `TextArea` with their controllers;
- `TextEditor`, `CodeEditor`, and `MarkdownEditor`;
- diagnostics and decoration bindings;
- `TextInputKeyMap` and `TextAreaKeyMap`.

Widget components consume Artisanal's editor primitives but retain
widget-specific focus, pointer targeting, layout, and themed rendering.
Do not move widget lifecycle concepts into editor core.

## Persistence and recovery

Implement `EditorDocumentStore` for your storage backend:

```dart
final session = EditorPersistenceSession(
  documentId: 'lib/main.dart',
  store: myStore,
);

final loaded = await session.load();
if (loaded != null) {
  editor
    ..setText(loaded.document.text, recordHistory: false)
    ..clearHistory()
    ..markSaved();
}
```

Saving:

```dart
final saved = await session.save(
  editor.document,
  revision: editor.document.revision,
  metadata: {'language': 'dart'},
);
```

Recovery checkpoints are separate from durable saves:

```dart
await session.checkpoint(
  editor.document,
  revision: editor.document.revision,
);

final recovery = await session.loadRecovery();
```

`EditorPersistenceSession` rejects stale operation completions. A successful
save clears recovery and updates `savedRevision`; a checkpoint does neither.
Use `MemoryEditorDocumentStore` in tests and examples.

Production stores should:

- write atomically where the platform permits;
- preserve encoding and line endings when required;
- report failures without marking the editor clean;
- checkpoint on a timer or idle boundary, not every keystroke;
- delete recovery only after a durable save or explicit dismissal.

## Large-document budgets

```dart
editor.workBudget = const EditorWorkBudget(
  maxSearchResults: 5000,
  maxDecorations: 10000,
  maxCompletionItems: 100,
  maxSynchronousSyntaxLength: 75000,
);

final assessment = editor.workAssessment;
```

`EditorWorkAssessment` classifies documents as `normal`, `large`, or
`oversized`, recommends visible-range work, and says whether synchronous syntax
is appropriate.

`TextAreaModel` enforces its budget for:

- maximum materialized search results;
- maximum decorations per layer;
- completion candidate count;
- synchronous syntax scheduling.

For large files:

- use `TextDocument.copy()` and incremental changes;
- parse asynchronously;
- return syntax patches or visible-range decorations;
- cap result lists;
- avoid reading `document.text` on every frame;
- render only the viewport.

## Paste handling

`planTextPaste` classifies content as inline, chunked, or collapsed:

```dart
final plan = planTextPaste(
  content,
  collapseLargePaste: true,
  collapsedPasteMinChars: 1200,
  collapsedPasteMinLines: 20,
  chunkThresholdRunes: 4000,
);
```

`TextPasteController` schedules large inline pastes in chunks so one message
does not monopolize the event loop. A collapsed paste requires a host-owned
sidecar:

1. store the full content with `storeCollapsed` or another store;
2. insert a short display token;
3. anchor an `InlineElement(kind: inlineElementPaste)` to the token;
4. prevent cursor movement into the element if it should be atomic;
5. show a preview when the cursor touches either edge;
6. expand the sidecar content on submit or external editing;
7. reconcile deleted elements before sending.

The
[`prompt-composer`](../../pkgs/artisanal/example/tui/examples/prompt-composer/main.dart)
demonstrates this complete workflow. The core tracks ranges; atomic navigation
and preview policy remain host choices.

## Tracked placeholders

`PlaceholderTracker` is useful when compact display text should expand to
hidden content:

```dart
final tracker = PlaceholderTracker()
  ..track(
    const TrackedPlaceholderRange(
      startOffset: 0,
      endOffset: 18,
      displayText: '[Pasted: 24 lines]',
      fullText: 'the complete pasted content',
    ),
  );

final submitted = expandPlaceholderRanges(editor.value, tracker.ranges);
```

Forward insertions, deletions, and replacements to the tracker, or rebuild it
from stable inline-element IDs. Do not submit display tokens as user content.

## Inline elements and sidecars

`InlineElementStore` associates a typed range with a stable ID:

```dart
final elements = InlineElementStore();
final id = elements.create(
  kind: inlineElementImage,
  startOffset: 4,
  endOffset: 14,
);

final attachment = MediaAttachment(
  elementId: id,
  displayNumber: 1,
  mimeType: 'image/png',
);
final attachments = <int, MediaAttachment>{id: attachment};
final underCursor = elements.elementAt(editor.cursorOffset);
```

Update the store for every insertion, deletion, or replacement. Keep large or
platform-specific data in a sidecar keyed by element ID, not in the text
document. At submit/cleanup boundaries:

```dart
final removed = reconcileExternalRecords(
  attachments,
  elements.liveIds,
);
```

Clean up temp files associated with `removed`.

Known kinds are `inlineElementImage`, `inlineElementPaste`, and
`inlineElementFileRef`; applications may define additional strings.

## Media attachments

The media layer includes:

- `MediaAttachment` for host-owned attachment metadata;
- `AttachmentPreview` and `AttachmentPreviewStatus`;
- `MediaViewerState`;
- `DisplayNumberAssigner`;
- `MediaAffordance` capability choices;
- pasted/dropped path extraction helpers.

Protocol detection and actual image drawing remain renderer concerns. The
[`media-composer`](../../pkgs/artisanal/example/tui/examples/media-composer/main.dart)
shows the chip → cursor preview → modal viewer workflow.

## External editor round trips

For a TEA application, use `Cmd.openEditor`:

1. expand placeholders into the full draft;
2. write a temporary file in the host;
3. return `Cmd.openEditor(path, onComplete:)`;
4. read and normalize the result in the completion message;
5. replace editor text without recording load history;
6. remove the temporary directory in `finally`.

`normalizePromptContent`, `resolveExternalEditorCommand`, and the editor
selection helpers support prompt-composer workflows. File and process access
stays outside editor core.

## IDE selection context

`EditorSelection`, `EditorSelectionRange`, and `EditorSelectionPosition`
represent context delivered by an IDE bridge. Use:

- `resolveEditorSelectionRange` to map into a `TextDocument`;
- `editorSelectionKey` for stable dismissal/deduplication;
- `editorSelectionRangeLabel` for UI;
- `formatEditorSelectionContext` when attaching context to a prompt.

Treat incoming positions as a protocol boundary. Confirm whether the source is
zero- or one-based and which character encoding it uses before constructing
editor values.

## Testing

Test core logic without a terminal:

```dart
test('inserts through the command registry', () {
  final editor = TextAreaModel()
    ..setText('ab', recordHistory: false)
    ..setSelections(TextSelectionSet.collapsed(1));

  expect(
    editor.executeCommand(
      EditorCommandIds.insertText,
      argument: 'X',
    ),
    EditorCommandDispatchResult.handled,
  );
  expect(editor.value, 'aXb');
});
```

Recommended layers:

1. Pure unit tests for document/edit functions.
2. Component tests that call `TextAreaModel.update`.
3. Provider tests for stale response rejection and incremental changes.
4. Render tests with ANSI stripped or stable cell-buffer assertions.
5. A small number of real TTY/manual checks for cursor shape, mouse input, and
   terminal-specific graphics.

Use injected clocks and `MemoryEditorDocumentStore` for deterministic history
and persistence tests. Avoid tests that depend on a user's `$EDITOR`, terminal
size, or live stdin.

## Production checklist

- [ ] Convert external coordinates at the boundary.
- [ ] Reserve stable gutter width.
- [ ] Keep the cursor visible after every motion and resize.
- [ ] Route intent through stable commands.
- [ ] Group compound edits into transactions.
- [ ] Reject stale async tooling results.
- [ ] Separate semantic decorations into layers.
- [ ] Cap work with `EditorWorkBudget`.
- [ ] Preview and validate workspace edits before writes.
- [ ] Mark clean only after a durable save.
- [ ] Reconcile and clean sidecar records.
- [ ] Test Unicode graphemes, Windows behavior, resize, and undo/redo.
