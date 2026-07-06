import 'package:artisanal/bubbles.dart' hide CodeBlockCommentDelimiters, CodeLanguageProfile, CommonKeyBindings, EditBuffer, EditHistoryCoalescePredicate, EditHistoryController, EditHistoryMarkerBuilder, EditHistoryStateEquals, EditorCoreConfig, EditorState, GraphemePredicate, GraphemeReader, Help, KeyBinding, KeyMap, PasteMsg, Row, Spinner, SpinnerModel, SpinnerTickMsg, Spinners, Text, TextCommandResult, TextCursorCommandResult, TextDecorationLayerKey, TextDecorationRange, TextDiagnosticRange, TextDiagnosticSeverity, TextDocument, TextDocumentChange, TextDocumentEditResult, TextEditResult, TextExtmark, TextExtmarkOptions, TextExtmarkPositionRange, TextExtmarksController, TextHighlightRange, TextHitResult, TextLineCommandResult, TextLineDecoration, TextLineStateCommandExtensions, TextLineStateSnapshot, TextOffsetStateCommandExtensions, TextOffsetStateDocumentEditingExtensions, TextOffsetStateSnapshot, TextPasteChunk, TextPasteChunkStep, TextPasteController, TextPasteMode, TextPastePlan, TextPasteReference, TextPasteReferenceStore, TextPasteSession, TextPatternDiagnosticRule, TextPosition, TextPositionDiagnosticRange, TextSelection, TextSyntaxBuildResult, TextSyntaxChangeWindow, TextSyntaxDecorationPatch, TextSyntaxLineWindow, TextSyntaxProvider, TextSyntaxSession, TextSyntaxSnapshot, TextView, TextViewLine, TextViewport, TextVisualCursorPosition, UndoCommandDecoder, UndoCommandJournalEntry, UndoManager, UndoableCommand;
import 'package:artisanal/src/style/style.dart';

void main() {
  final cols = [
    Column(title: 'PID', width: 6),
    Column(title: 'Name', width: 20),
    Column(title: 'CPU', width: 8),
    Column(title: 'Mem', width: 10),
  ];

  final headerStyle = Style().bold().padding(0, 1);
  final cellStyle = Style().padding(0, 1);

  // Step 1: widthStyle.render output
  for (final col in cols) {
    final widthStyle = Style()
        .inline(true)
        .width(col.width)
        .maxWidth(col.width);
    final rendered = widthStyle.render(col.title);
    print(
      'widthStyle("${col.title}") visible=${Style.visibleLength(rendered)}',
    );
  }
  print('');

  // Step 2: header cell visible widths
  for (final col in cols) {
    final widthStyle = Style()
        .inline(true)
        .width(col.width)
        .maxWidth(col.width);
    final rendered = widthStyle.render(col.title);
    final cell = headerStyle.render(rendered);
    print(
      'header "${col.title}" col.width=${col.width} '
      'visible=${Style.visibleLength(cell)}  expected=${col.width + 2}',
    );
  }
  print('');

  // Step 3: cell visible widths
  final row = ['1024', 'node server.js', '12.5%', '156MB'];
  for (var i = 0; i < cols.length; i++) {
    final col = cols[i];
    final widthStyle = Style()
        .inline(true)
        .width(col.width)
        .maxWidth(col.width);
    final rendered = widthStyle.render(row[i]);
    final cell = cellStyle.render(rendered);
    print(
      'cell "${row[i]}" col.width=${col.width} '
      'visible=${Style.visibleLength(cell)}  expected=${col.width + 2}',
    );
  }
}
