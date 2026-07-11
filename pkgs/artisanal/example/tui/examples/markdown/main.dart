/// Minimal Markdown rendering example using `renderMarkdown`.
///
/// This example parses Markdown with `package:markdown`, converts it to
/// ANSI-styled text via `renderMarkdown`, and displays it inside a viewport.
library;

import 'package:artisanal/bubbles.dart'
    as tui
    hide
        CodeBlockCommentDelimiters,
        CodeLanguageProfile,
        Column,
        CommonKeyBindings,
        EditBuffer,
        EditHistoryCoalescePredicate,
        EditHistoryController,
        EditHistoryMarkerBuilder,
        EditHistoryStateEquals,
        EditorCoreConfig,
        EditorState,
        GraphemePredicate,
        GraphemeReader,
        Help,
        KeyBinding,
        KeyMap,
        PasteMsg,
        Row,
        Spinner,
        SpinnerModel,
        SpinnerTickMsg,
        Spinners,
        Text,
        TextCommandResult,
        TextCursorCommandResult,
        TextDecorationLayerKey,
        TextDecorationRange,
        TextDiagnosticRange,
        TextDiagnosticSeverity,
        TextDocument,
        TextDocumentChange,
        TextDocumentEditResult,
        TextEditResult,
        TextExtmark,
        TextExtmarkOptions,
        TextExtmarkPositionRange,
        TextExtmarksController,
        TextHighlightRange,
        TextHitResult,
        TextLineCommandResult,
        TextLineDecoration,
        TextLineStateCommandExtensions,
        TextLineStateSnapshot,
        TextOffsetStateCommandExtensions,
        TextOffsetStateDocumentEditingExtensions,
        TextOffsetStateSnapshot,
        TextPasteChunk,
        TextPasteChunkStep,
        TextPasteController,
        TextPasteMode,
        TextPastePlan,
        TextPasteReference,
        TextPasteReferenceStore,
        TextPasteSession,
        TextPatternDiagnosticRule,
        TextPosition,
        TextPositionDiagnosticRange,
        TextSelection,
        TextSyntaxBuildResult,
        TextSyntaxChangeWindow,
        TextSyntaxDecorationPatch,
        TextSyntaxLineWindow,
        TextSyntaxProvider,
        TextSyntaxSession,
        TextSyntaxSnapshot,
        TextView,
        TextViewLine,
        TextViewport,
        TextVisualCursorPosition,
        UndoCommandDecoder,
        UndoCommandJournalEntry,
        UndoManager,
        UndoableCommand;

import 'package:artisanal/tui.dart' as markdown;
import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart' as tui;

const _md = r'''
# Markdown Demo

This example shows **renderMarkdown** output inside a viewport. Resize the
terminal and the content will re-wrap automatically.

## Lists

- Apples
- Bananas
- Cherries

1. First
2. Second
3. Third

## Code

```
dart run packages/artisanal/example/tui/examples/markdown/main.dart
```

> Blockquotes are supported too.

| Column | Value |
| --- | --- |
| A | 1 |
| B | 2 |
| C | 3 |
''';

final _border = Style()
    .border(Border.rounded)
    .borderForeground(const AnsiColor(62))
    .padding(0, 1);

final _help = Style()
    .foreground(const AnsiColor(241))
    .render('↑/↓ scroll • q/esc/ctrl+c quit');

class MarkdownExample implements tui.Model {
  MarkdownExample({
    required this.viewport,
    required this.width,
    required this.height,
  });

  factory MarkdownExample.initial() {
    const width = 78;
    final content = markdown.markdownToAnsi(_md);
    final vp = tui.ViewportModel(width: width, height: 22)..setContent(content);
    return MarkdownExample(viewport: vp, width: width, height: 22);
  }

  final tui.ViewportModel viewport;
  final int width;
  final int height;

  @override
  tui.Cmd? init() => null;

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    switch (msg) {
      case tui.KeyMsg(key: final key):
        final rune = key.runes.isNotEmpty ? key.runes.first : -1;
        if (key.type == tui.KeyType.escape ||
            (key.ctrl && rune == 0x63) || // Ctrl+C
            rune == 0x71) {
          return (this, tui.Cmd.quit());
        }
      case tui.WindowSizeMsg(width: final w, height: final h):
        final content = markdown.markdownToAnsi(_md);
        final vp = viewport.copyWith(width: w, height: h - 2)
          ..setContent(content);
        return (copyWith(viewport: vp, width: w, height: h), null);
    }

    final (newVp, cmd) = viewport.update(msg);
    return (copyWith(viewport: newVp), cmd);
  }

  MarkdownExample copyWith({
    tui.ViewportModel? viewport,
    int? width,
    int? height,
  }) {
    return MarkdownExample(
      viewport: viewport ?? this.viewport,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  @override
  String view() => '${_border.render(viewport.view())}\n$_help\n';
}

Future<void> main() async {
  await tui.runProgram(
    MarkdownExample.initial(),
    options: const tui.ProgramOptions(altScreen: false, hideCursor: false),
  );
}
