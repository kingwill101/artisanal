# Artisanal Tree-sitter language-pack adapter

This optional workspace package demonstrates how an application can connect
[`tree_sitter_language_pack`](https://pub.dev/packages/tree_sitter_language_pack)
to Artisanal without adding a native parser dependency to the `artisanal`
package itself.

The adapter:

- owns `RustLib.init()` / `dispose()` outside editor core;
- implements `AsyncSyntaxTreeProvider`;
- parses through the package's isolate-safe `process` API;
- converts UTF-8 byte spans to Artisanal grapheme offsets with one
  `TextUtf8CoordinateIndex` per result;
- walks the complete native syntax tree and converts keywords, identifiers,
  strings, numbers, constants, comments, and operators into editor decoration
  ranges;
- drives a live `TextAreaModel` editor and rejects stale parse responses.

Run from the repository root:

```sh
TMP=.tmp dart run \
  pkgs/artisanal/example/tree_sitter_language_pack/bin/main.dart
```

The first run may download the Python Tree-sitter grammar into the language
pack's cache.

Edit the sample Python directly in the terminal. The status line reports parse
progress, highlighted ranges, and structure-node count. Press `ctrl+c` to quit.

## Dependency boundary

```text
artisanal
    pure Dart editor contracts

artisanal_tree_sitter_language_pack_example
    depends on artisanal
    depends on tree_sitter_language_pack
    owns native runtime initialization
    maps external DTOs into editor-core DTOs
```

Only this example package imports the external dependency. Its generated
`RustLib` implementation is not publicly exported by the dependency, so the
implementation-detail import is isolated in `language_pack_runtime.dart`.

The high-level `process` API does not accept a previous native tree. This
example consequently performs full asynchronous parses. A production adapter
built on the package's lower-level `Parser` API can retain native trees and set
`supportsIncremental` to `true`.
