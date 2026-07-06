
import 'package:artisanal/bubbles.dart' hide CodeBlockCommentDelimiters, CodeLanguageProfile, CommonKeyBindings, EditBuffer, EditHistoryCoalescePredicate, EditHistoryController, EditHistoryMarkerBuilder, EditHistoryStateEquals, EditorCoreConfig, EditorState, GraphemePredicate, GraphemeReader, Help, KeyBinding, KeyMap, PasteMsg, Row, Spinner, SpinnerModel, SpinnerTickMsg, Spinners, Text, TextCommandResult, TextCursorCommandResult, TextDecorationLayerKey, TextDecorationRange, TextDiagnosticRange, TextDiagnosticSeverity, TextDocument, TextDocumentChange, TextDocumentEditResult, TextEditResult, TextExtmark, TextExtmarkOptions, TextExtmarkPositionRange, TextExtmarksController, TextHighlightRange, TextHitResult, TextLineCommandResult, TextLineDecoration, TextLineStateCommandExtensions, TextLineStateSnapshot, TextOffsetStateCommandExtensions, TextOffsetStateDocumentEditingExtensions, TextOffsetStateSnapshot, TextPasteChunk, TextPasteChunkStep, TextPasteController, TextPasteMode, TextPastePlan, TextPasteReference, TextPasteReferenceStore, TextPasteSession, TextPatternDiagnosticRule, TextPosition, TextPositionDiagnosticRange, TextSelection, TextSyntaxBuildResult, TextSyntaxChangeWindow, TextSyntaxDecorationPatch, TextSyntaxLineWindow, TextSyntaxProvider, TextSyntaxSession, TextSyntaxSnapshot, TextView, TextViewLine, TextViewport, TextVisualCursorPosition, UndoCommandDecoder, UndoCommandJournalEntry, UndoManager, UndoableCommand;
void main() {
  // Test 1: bare TableModel with explicit width
  final cols = [
    Column(title: 'PID', width: 6),
    Column(title: 'Name', width: 20),
    Column(title: 'CPU', width: 8),
  ];
  final totalWidth = cols.fold(0, (s, c) => s + c.width + 2);

  final table = TableModel(
    columns: cols,
    rows: [
      ['1024', 'node server.js', '12.5%'],
      ['2048', 'dart run', '5.2%'],
      ['3072', 'postgres', '1.1%'],
    ],
    height: 5,
  )..focus();
  table.setWidth(totalWidth);

  print('--- TableModel.view() ---');
  print(table.view());

  // Test 2: DataTableModel (the composite component)
  final items = ['node server.js', 'dart run', 'postgres', 'redis', 'nginx'];
  final model = DataTableModel<String>(
    items: items,
    columns: [
      Column(title: '#', width: 3),
      Column(title: 'Process', width: 20),
    ],
    rowBuilder: (s) => [(items.indexOf(s) + 1).toString(), s],
    title: 'Pick a process',
    pageSize: 3,
  );
  print('\n--- DataTableModel.view() ---');
  print(model.view());
}
