# Language tooling

Editor core defines backend-neutral contracts for language behavior and
tooling. It does not start an LSP server, load a Tree-sitter library, or perform
file I/O. Those adapters live in the application or a separate package.

## Language adapters

Implement `EditorLanguageAdapter` for comment syntax, pairs, and indentation:

```dart
final class MyLanguage extends EditorLanguageAdapter {
  const MyLanguage();

  @override
  String get languageId => 'my-language';

  @override
  List<String> get aliases => const ['mine'];

  @override
  EditorCommentConfig get comments => const EditorCommentConfig(
        linePrefix: '//',
        blockStart: '/*',
        blockEnd: '*/',
      );

  @override
  bool shouldIncreaseIndent(EditorIndentContext context) {
    return context.lineBeforeCursor.trimRight().endsWith(':');
  }
}

final languages = EditorLanguageRegistry()..register(const MyLanguage());
final adapter = languages.require('mine');
```

The core registry begins empty. `registerBuiltinEditorLanguages()` registers
the bundled profiles for hosts that want the opinionated defaults.

The public `package:artisanal/editor_core.dart` entrypoint currently re-exports
the builtin code extensions for compatibility. Custom language packages
should still program against `EditorLanguageAdapter` and avoid relying on
global registration.

## Syntax decorations

A synchronous provider returns either a full decoration list or an incremental
patch:

```dart
final class DemoSyntaxProvider extends TextSyntaxProvider<int> {
  @override
  TextSyntaxBuildResult<int> build(
    String text, {
    TextDocument? document,
    String? language,
    TextSyntaxSnapshot<int>? previous,
    TextDocumentChange? change,
  }) {
    final keywordEnd = text.startsWith('import') ? 6 : 0;
    return TextSyntaxBuildResult(
      decorations: [
        if (keywordEnd > 0)
          TextDecorationRange(
            startOffset: 0,
            endOffset: keywordEnd,
            styleKey: 'syntax.keyword',
          ),
      ],
      state: (previous?.state ?? 0) + 1,
    );
  }
}

final session = TextSyntaxSession<int>(
  provider: DemoSyntaxProvider(),
  language: 'dart',
);
final snapshot = session.syncDocument(document);
```

Pass the accepted snapshot to `TextAreaModel.setDecorationLayer`, or use
`TextAreaModel.syncSyntax` to coordinate the session and layer.

For incremental providers:

1. consume `TextDocumentChange`;
2. calculate a bounded line window with `textSyntaxChangeWindow`;
3. parse that window with enough look-behind/look-ahead;
4. return `TextSyntaxBuildResult.patch`;
5. let the session merge and shift unaffected ranges.

## Asynchronous syntax

Use `AsyncTextSyntaxProvider` and `AsyncTextSyntaxSession` when parsing should
not block the render isolate:

```dart
final snapshot = await asyncSession.request(
  document.copy(),
  change: lastChange,
);

if (snapshot != null) {
  editor.setDecorationLayer(
    textSyntaxDecorationLayerKey,
    snapshot.decorations,
    priority: textSyntaxDecorationLayerPriority,
  );
}
```

`null` means a newer request or cancellation superseded the result. Never
publish the provider's raw result without this generation check.

Consult `EditorWorkBudget` before synchronous whole-document parsing.

## Syntax trees

`EditorSyntaxNode`, `EditorSyntaxTree`, `EditorSyntaxCapture`, and
`SyntaxTreeEdit` are pure Dart DTOs for structural backends.
`SyntaxTreeProvider` is the integration boundary for a Tree-sitter-like parser.
For native workers, isolates, and other future-based parsers, implement
`AsyncSyntaxTreeProvider` and submit snapshots through
`AsyncSyntaxTreeSession`. The session retains the previous document/tree for
incremental parsing and rejects responses superseded by newer requests.

Use syntax trees for:

- node and ancestor queries;
- structural selections and text objects;
- syntax-aware folds;
- comment/string filtering for bracket matching;
- semantic decorations;
- code actions that need syntax context.

Native bindings belong in a dependent package. Editor core remains free of
`dart:ffi`.

The optional
[`tree_sitter_language_pack` adapter example](../../pkgs/artisanal/example/tree_sitter_language_pack/)
shows this boundary end to end. It owns native runtime initialization,
implements `AsyncSyntaxTreeProvider`, parses outside the render path, and maps
the package's UTF-8 byte spans into editor grapheme offsets. Its live editor
walks the complete native tree to decorate lexical syntax nodes. The high-level
language-pack API performs full parses; adapters that retain native trees should
additionally apply `SyntaxTreeEdit`s and opt into incremental parsing.

Tree-sitter-style parsers usually report UTF-8 byte coordinates, while editor
documents use grapheme coordinates. Create one `TextUtf8CoordinateIndex` for
each parser request and reuse it when mapping nodes and captures:

```dart
final coordinates = TextUtf8CoordinateIndex(document);
final start = coordinates.offsetForPoint(
  TextUtf8Point(row: capture.startRow, byteColumn: capture.startByteColumn),
);
final end = coordinates.offsetForByteOffset(capture.endByteOffset);
```

Byte positions inside a multi-byte grapheme round down to its leading
boundary. The standalone conversion functions are convenient for one-off
lookups; the index avoids rescanning the document for every parser range.

## Search and replace

```dart
final result = findTextSearchMatches(
  document,
  const TextSearchQuery(
    pattern: r'final\s+(\w+)',
    isRegex: true,
    caseSensitive: true,
  ),
  maxResults: 1000,
);

if (result.error != null) {
  // Invalid regexes are normal while the user types.
}
```

Search offsets are converted back into document grapheme coordinates.
`TextSearchResult.truncated` reports when `maxResults` stopped materialization.

Replacement templates support:

- `$&` for the whole match;
- `$1` through `$99` for capture groups;
- `$$` for a literal dollar.

`TextSearchSession` supplies next/previous navigation. `TextAreaModel` adds
decoration layers plus `replaceActiveSearchMatch` and
`replaceAllSearchMatches`, grouping each operation into normal history.

## Completions

Implement `EditorCompletionProvider`:

```dart
final class DemoCompletions implements EditorCompletionProvider {
  @override
  Future<EditorCompletionResult> provide(
    EditorCompletionRequest request,
  ) async {
    return const EditorCompletionResult(
      items: [
        EditorCompletionItem(
          label: 'print',
          insertText: 'print',
          kind: EditorCompletionKind.function,
          detail: 'Print a value',
        ),
      ],
    );
  }
}
```

In a TEA host:

```dart
final cmd = editor.requestCompletions(DemoCompletions());
// Return cmd from Model.update. TextAreaCompletionMsg returns through TEA.
```

Render `completionItems`, `completionIndex`, and `activeCompletion` in a
popup. Forward navigation to `moveCompletionSelection`; call
`acceptCompletion` or `cancelCompletions`.

Acceptance applies the primary insertion as one undo transaction.
`consumeCompletionAdditionalEdits()` hands import or cross-file changes back
to the host exactly once.

## Code actions

An `EditorCodeActionProvider` receives current text, version, selection, and
intersecting diagnostics. It returns quick fixes or refactors:

```dart
final action = EditorCodeAction(
  title: 'Replace with const',
  kind: 'quickfix',
  preferred: true,
  edit: const WorkspaceEdit(
    files: {
      'lib/main.dart': [
        FileTextEdit(
          startOffset: 0,
          endOffset: 5,
          replacement: 'const',
        ),
      ],
    },
  ),
);
```

`TextAreaModel.requestCodeActions` returns a `Cmd`. Render `codeActions` and
`activeCodeAction`, then call `acceptCodeAction`. The host consumes the result
with `consumeAcceptedCodeAction()` and decides how to preview/apply edits or
dispatch `commandId`.

## Workspace edits

`WorkspaceEdit` is intentionally I/O-free:

```dart
final files = <String, String>{
  'lib/main.dart': 'final value = 1;\n',
};

final preview = previewWorkspaceEdit(files, action.edit);
final applied = applyWorkspaceEdit(files, action.edit);

if (applied.values.every((result) => result.applied)) {
  // The host may now persist result.newText for each file.
}
```

Edits are validated for overlap and applied from highest offset to lowest.
Conflicting edits reject the whole affected file. Always preview user-visible
refactors before writing, and keep reads/writes in the host.

`applyFileEdits` operates directly on Dart strings, so `FileTextEdit` offsets
passed to that helper are UTF-16 code-unit indexes. Convert document grapheme
offsets before using the string helper, or apply the replacement to a
`TextDocument` when you want editor-coordinate semantics.

## Snippets

```dart
final snippet = parseSnippet(
  'for (var \${1:i} = 0; \$1 < \${2:n}; \$1++) {\n  \$0\n}',
);
final session = SnippetSession(snippet);
final first = session.next();
```

Supported syntax includes `$1`, `${1}`, `${1:default}`, mirrors, and `$0` as
the final stop. `SnippetSession` visits the first occurrence of each stop in
numeric order, with `$0` last.

The host inserts `ParsedSnippet.text`, offsets each tabstop by the insertion
origin, and selects each returned range. Live mirror synchronization while the
user edits is a host responsibility.

## Bracket matching

```dart
final partner = findMatchingBracket(document, cursorOffset);
final pair = bracketPairRange(document, cursorOffset);
```

The built-in matcher understands `()`, `[]`, and `{}` and performs depth
counting. Quotes are excluded because they require token context. Filter
brackets through syntax information when comments or strings must be ignored.
