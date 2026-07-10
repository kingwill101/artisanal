/// Glamour + viewport example ported from Bubble Tea.
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

import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart' as tui;

const _content = r'''
# Today’s Menu

## Appetizers

| Name        | Price | Notes                           |
| ---         | ---   | ---                             |
| Tsukemono   | $2    | Just an appetizer               |
| Tomato Soup | $4    | Made with San Marzano tomatoes  |
| Okonomiyaki | $4    | Takes a few minutes to make     |
| Curry       | $3    | We can add squash if you’d like |

## Seasonal Dishes

| Name                 | Price | Notes              |
| ---                  | ---   | ---                |
| Steamed bitter melon | $2    | Not so bitter      |
| Takoyaki             | $3    | Fun to eat         |
| Winter squash        | $3    | Today it's pumpkin |

## Desserts

| Name         | Price | Notes                 |
| ---          | ---   | ---                   |
| Dorayaki     | $4    | Looks good on rabbits |
| Banana Split | $5    | A classic             |
| Cream Puff   | $3    | Pretty creamy!        |

All our dishes are made in-house by Karen, our chef. Most of our ingredients
are from our garden or the fish market down the street.

Some famous people that have eaten here lately:

* [x] René Redzepi
* [x] David Chang
* [ ] Jiro Ono (maybe some day)

Bon appétit!
''';

final _helpStyle = Style().foreground(const AnsiColor(241)).render;
final _borderStyle = Style()
    .border(Border.rounded)
    .borderForeground(const AnsiColor(62))
    .padding(0, 2);

class GlamourExample implements tui.Model {
  GlamourExample({
    required this.viewport,
    required this.width,
    required this.height,
  });

  factory GlamourExample.initial() {
    const width = 78;
    final rendered = tui.markdownToAnsi(_content);
    final vp = tui.ViewportModel(width: width, height: 20)
      ..setContent(rendered);
    return GlamourExample(viewport: vp, width: width, height: 20);
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
        if (rune == 0x71 ||
            key.type == tui.KeyType.escape ||
            (key.ctrl && rune == 0x63)) {
          return (this, tui.Cmd.quit());
        }
      case tui.WindowSizeMsg(width: final w, height: final h):
        final rendered = tui.markdownToAnsi(_content);
        final vp = viewport.copyWith(width: w, height: h - 2)
          ..setContent(rendered);
        return (copyWith(viewport: vp, width: w, height: h), null);
    }

    final (newVp, cmd) = viewport.update(msg);
    return (copyWith(viewport: newVp), cmd);
  }

  GlamourExample copyWith({
    tui.ViewportModel? viewport,
    int? width,
    int? height,
  }) {
    return GlamourExample(
      viewport: viewport ?? this.viewport,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  @override
  String view() =>
      '${_borderStyle.render(viewport.view())}\n${_helpStyle('  ↑/↓: Navigate • q: Quit')}\n';
}

Future<void> main() async {
  await tui.runProgram(
    GlamourExample.initial(),
    options: const tui.ProgramOptions(altScreen: false, hideCursor: false),
  );
}
