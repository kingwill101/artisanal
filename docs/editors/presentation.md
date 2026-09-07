# Editor presentation

Presentation is split into geometry and semantics:

- `TextView` computes visual rows, wrapping, scrolling, cursor positions, and
  hit tests.
- Decorations and diagnostics describe what should look different.
- A TEA or widget host maps those descriptions to concrete styles and cells.

## `TextView`

```dart
final document = TextDocument(text: 'first line\nsecond line');
final state = EditorState(line: 1, column: 3);
final view = TextView(
  width: 80,
  height: 20,
  leadingColumns: 5,
  softWrap: true,
  scrollMargin: 0.15,
);

view.ensureCursorVisible(document, state);
final viewport = view.resolveViewport(document, state);
final lines = view.buildLinesForCurrentViewport(document, state);
```

`leadingColumns` reserves columns for prompts, line numbers, fold markers, or
other gutter content. Keeping that width stable prevents the source text from
moving when line numbers gain another digit.

Important methods:

- `buildLines` creates every visual line.
- `buildViewportLines` and `buildLinesForCurrentViewport` return a window.
- `resolveViewport` reports vertical and horizontal bounds.
- `ensureCursorVisible` adjusts both viewport axes.
- `pageUp`, `pageDown`, `scrollByRows`, and `scrollByColumns` update scroll
  state.
- `resolveCursorVisualPosition` maps a logical cursor into screen geometry.
- `hitTestContent` maps a screen row/column back to document line/column.
- `cursorOffsetForVisualLineMove` preserves visual columns during vertical
  motion.

With `softWrap: false`, `viewportStartColumn` enables horizontal scrolling.
With wrapping enabled, visual rows may share one logical line.

## Rendering with `TextAreaModel`

`TextAreaModel` owns a `TextView` internally and handles prompt/gutter width,
line-number digits, selections, cursor visibility, and terminal cursor output.

For a full-screen editor:

```dart
void resize(TextAreaModel editor, int width, int height) {
  const headerRows = 1;
  const footerRows = 1;
  editor
    ..setWidth(width)
    ..setHeight((height - headerRows - footerRows).clamp(1, height));
}
```

Set `showLineNumbers: true` for an editor gutter and
`useVirtualCursor: true` when the cursor should be painted as part of the view.
If the terminal should own the cursor, expose `terminalCursor` through the
normal TUI rendering path.

## Decoration ranges

Decorations use grapheme offsets and semantic style keys:

```dart
editor.setDecorationLayer(
  textSyntaxDecorationLayerKey,
  const [
    TextDecorationRange(
      startOffset: 0,
      endOffset: 6,
      styleKey: 'syntax.keyword',
    ),
  ],
  priority: textSyntaxDecorationLayerPriority,
);
```

Configure the corresponding style key in the focused and blurred
`TextAreaStyleState.decorationStyles` maps. Keeping semantic keys in the core
lets a host apply a different theme without rebuilding syntax data.

Built-in layer ordering is:

1. default (`0`);
2. syntax (`50`);
3. diagnostics (`75`);
4. search (`100`).

Higher-priority layers win where ranges overlap. Prefer separate layers over
concatenating all decoration sources yourself:

- syntax can refresh without deleting search matches;
- diagnostics can refresh without reparsing syntax;
- closing search removes only its layer.

Use `clearDecorationLayer` or `clearSyntax` for targeted cleanup.

## Line decorations and gutters

`TextLineDecoration` styles a logical line and can add a gutter marker:

```dart
editor.setLineDecorationLayer(
  'folds',
  const [
    TextLineDecoration(
      lineIndex: 3,
      styleKey: 'line.fold.header',
      lineNumberMarker: '▸',
      lineNumberStyleKey: 'line.fold.marker',
    ),
  ],
  priority: 60,
);
```

Line styles, line-number styles, and markers are independent. This supports
active-line highlighting, diagnostics in the gutter, breakpoints, diff
markers, and fold state without rebuilding source text.

## Diagnostics

Diagnostics are data rather than rendered strings:

```dart
editor.setDiagnostics([
  const TextDiagnosticRange(
    startOffset: 10,
    endOffset: 14,
    severity: TextDiagnosticSeverity.warning,
    code: 'unused_local',
    message: 'The local variable is unused.',
    source: 'analyzer',
  ),
]);

editor.selectNextDiagnostic();
final active = editor.activeDiagnostic;
```

For line/column diagnostics, call `setDiagnosticsFromPositions` with
`TextPositionDiagnosticRange`. The editor converts positions, builds
diagnostic decoration layers, and supports next/previous navigation.

`textPatternDiagnostics` is useful for lightweight rules such as TODOs,
trailing whitespace, or forbidden tokens. A real analyzer or LSP adapter
should emit the same `TextDiagnosticRange` values.

## Search presentation

`TextAreaModel.startSearch` creates match and active-match decoration ranges:

```dart
final result = editor.startSearch(
  const TextSearchQuery(
    pattern: r'\bTODO\b',
    isRegex: true,
  ),
);

if (result.error == null) {
  editor.selectSearchMatch(forward: true);
}
```

Use `searchMatches`, `activeSearchMatch`, `searchMatchIndex`,
`searchTruncated`, and `searchError` to render a find overlay or status line.
Call `closeSearch()` when the overlay closes.

## Folding

`FoldRange` includes its header and body; only the body becomes hidden.
`TextView.folds` skips hidden logical lines while retaining original line
numbers:

```dart
final folds = FoldState(
  ranges: computeIndentFolds(document.lineTexts),
)..toggle(0);

view.folds = folds;
final visible = view.buildLines(document, state);
```

`TextAreaModel` integrates fold projection and fold-aware vertical motion:

```dart
editor.refreshIndentFolds();
editor.toggleFoldAtCursor();
editor.collapseAllFolds();
editor.expandAllFolds();
```

After edits, recompute ranges and retain collapse state. Custom syntax
providers can produce `FoldRange(kind: FoldKind.syntax)` instead of using
indentation.

Folding is a view projection rather than a document mutation. Hidden lines
remain in `TextDocument`; `TextView` omits them from visual output while
preserving logical line indexes on visible rows. Cursor and selection movement
uses the same fold-aware range path, so vertical motion skips a collapsed body
for both one cursor and multiple cursors.

## Pointer input

Pointer-aware hosts should:

1. subtract frame, border, header, and gutter offsets;
2. call `hitTestContent` with coordinates relative to the text content;
3. convert the hit to `TextPosition` or a document offset;
4. update selection state;
5. call `ensureCursorVisible` after drag/autoscroll changes.

Do not derive document columns from raw string length. Tabs, wide glyphs,
combining sequences, wrapping, and horizontal scroll all affect display
geometry.

## Overlay ownership

Completion lists, command palettes, code-action menus, paste previews, and
hover cards are host overlays. Keep them outside the document text unless they
are intentionally represented by an `InlineElement`.

For overlays:

- maintain selection/window state in a controller;
- render over the base editor after the editor view is built;
- reserve screen bounds rather than document bounds;
- return focus and invalidate stale requests when dismissed.
