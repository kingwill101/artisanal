import 'package:artisanal/bubbles.dart' hide CodeBlockCommentDelimiters, CodeLanguageProfile, Column, CommonKeyBindings, EditBuffer, EditHistoryCoalescePredicate, EditHistoryController, EditHistoryMarkerBuilder, EditHistoryStateEquals, EditorCoreConfig, EditorState, GraphemePredicate, GraphemeReader, Help, KeyBinding, KeyMap, PasteMsg, Row, Spinner, SpinnerModel, SpinnerTickMsg, Spinners, Text, TextCommandResult, TextCursorCommandResult, TextDecorationLayerKey, TextDecorationRange, TextDiagnosticRange, TextDiagnosticSeverity, TextDocument, TextDocumentChange, TextDocumentEditResult, TextEditResult, TextExtmark, TextExtmarkOptions, TextExtmarkPositionRange, TextExtmarksController, TextHighlightRange, TextHitResult, TextLineCommandResult, TextLineDecoration, TextLineStateCommandExtensions, TextLineStateSnapshot, TextOffsetStateCommandExtensions, TextOffsetStateDocumentEditingExtensions, TextOffsetStateSnapshot, TextPasteChunk, TextPasteChunkStep, TextPasteController, TextPasteMode, TextPastePlan, TextPasteReference, TextPasteReferenceStore, TextPasteSession, TextPatternDiagnosticRule, TextPosition, TextPositionDiagnosticRange, TextSelection, TextSyntaxBuildResult, TextSyntaxChangeWindow, TextSyntaxDecorationPatch, TextSyntaxLineWindow, TextSyntaxProvider, TextSyntaxSession, TextSyntaxSnapshot, TextView, TextViewLine, TextViewport, TextVisualCursorPosition, UndoCommandDecoder, UndoCommandJournalEntry, UndoManager, UndoableCommand;
import 'package:artisanal/style.dart';

void main() {
  final labelStyle = Style().width(3).align(HorizontalAlign.right);
  final swatchStyle = Style().width(6);

  final data = <List<String>>[];

  // First 8 colors (0-5, 8-13)
  for (var i = 0; i < 13; i += 8) {
    data.add(makeRow(i, i + 5));
  }
  data.add(makeEmptyRow());

  // Colors 6-7, 14-15
  for (var i = 6; i < 15; i += 8) {
    data.add(makeRow(i, i + 1));
  }
  data.add(makeEmptyRow());

  // Colors 16-231 (6x6x6 color cube)
  for (var i = 16; i < 231; i += 6) {
    data.add(makeRow(i, i + 5));
  }
  data.add(makeEmptyRow());

  // Grayscale 232-255
  for (var i = 232; i < 256; i += 6) {
    data.add(makeRow(i, i + 5));
  }

  final t = Table().border(Border.hidden).rows(data).styleFunc((row, col, _) {
    if (row < 0 || row >= data.length) return null;
    final colorIndex = col - col % 2;
    if (colorIndex >= data[row].length) return null;
    final colorStr = data[row][colorIndex];
    if (colorStr.isEmpty) return null;
    final colorNum = int.tryParse(colorStr);
    if (colorNum == null) return null;
    final color = AnsiColor(colorNum);

    if (col % 2 == 0) {
      return labelStyle.foreground(color);
    } else {
      return swatchStyle.background(color);
    }
  });

  print(t);
}

const rowLength = 12;

List<String> makeRow(int start, int end) {
  final row = <String>[];
  for (var i = start; i <= end; i++) {
    row.add('$i');
    row.add('');
  }
  while (row.length < rowLength) {
    row.add('');
  }
  return row;
}

List<String> makeEmptyRow() {
  return makeRow(0, -1);
}
