import 'package:artisanal/bubbles.dart' hide CodeBlockCommentDelimiters, CodeLanguageProfile, Column, CommonKeyBindings, EditBuffer, EditHistoryCoalescePredicate, EditHistoryController, EditHistoryMarkerBuilder, EditHistoryStateEquals, EditorCoreConfig, EditorState, GraphemePredicate, GraphemeReader, Help, KeyBinding, KeyMap, PasteMsg, Row, Spinner, SpinnerModel, SpinnerTickMsg, Spinners, Text, TextCommandResult, TextCursorCommandResult, TextDecorationLayerKey, TextDecorationRange, TextDiagnosticRange, TextDiagnosticSeverity, TextDocument, TextDocumentChange, TextDocumentEditResult, TextEditResult, TextExtmark, TextExtmarkOptions, TextExtmarkPositionRange, TextExtmarksController, TextHighlightRange, TextHitResult, TextLineCommandResult, TextLineDecoration, TextLineStateCommandExtensions, TextLineStateSnapshot, TextOffsetStateCommandExtensions, TextOffsetStateDocumentEditingExtensions, TextOffsetStateSnapshot, TextPasteChunk, TextPasteChunkStep, TextPasteController, TextPasteMode, TextPastePlan, TextPasteReference, TextPasteReferenceStore, TextPasteSession, TextPatternDiagnosticRule, TextPosition, TextPositionDiagnosticRange, TextSelection, TextSyntaxBuildResult, TextSyntaxChangeWindow, TextSyntaxDecorationPatch, TextSyntaxLineWindow, TextSyntaxProvider, TextSyntaxSession, TextSyntaxSnapshot, TextView, TextViewLine, TextViewport, TextVisualCursorPosition, UndoCommandDecoder, UndoCommandJournalEntry, UndoManager, UndoableCommand;
import 'package:artisanal/style.dart';

const purple = AnsiColor(99);
const gray = AnsiColor(245);
const lightGray = AnsiColor(241);

void main() {
  // Style definitions
  final headerStyle = Style()
      .foreground(purple)
      .bold()
      .align(HorizontalAlign.center);
  final cellStyle = Style().padding(0, 1).width(14);
  final oddRowStyle = cellStyle.copy().foreground(gray);
  final evenRowStyle = cellStyle.copy().foreground(lightGray);
  final borderStyle = Style().foreground(purple);

  final rows = [
    ['Chinese', '您好', '你好'],
    ['Japanese', 'こんにちは', 'やあ'],
    ['Arabic', 'أهلين', 'أهلا'],
    ['Russian', 'Здравствуйте', 'Привет'],
    ['Spanish', 'Hola', '¿Qué tal?'],
  ];

  final t = Table()
      .border(Border.thick)
      .borderStyle(borderStyle)
      .styleFunc((row, col, data) {
        Style style;

        if (row == -1) {
          // Header row
          return headerStyle;
        } else if (row % 2 == 0) {
          style = evenRowStyle;
        } else {
          style = oddRowStyle;
        }

        // Make the second column a little wider
        if (col == 1) {
          style = style.width(22);
        }

        // Arabic is right-to-left, so right align the text
        if (row < rows.length && rows[row][0] == 'Arabic' && col != 0) {
          style = style.align(HorizontalAlign.right);
        }

        return style;
      })
      .headers(['LANGUAGE', 'FORMAL', 'INFORMAL'])
      .rows(rows)
      .row(['English', 'You look absolutely fabulous.', "How's it going?"]);

  print(t);
}
