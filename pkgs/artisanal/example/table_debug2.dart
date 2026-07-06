import 'package:artisanal/bubbles.dart' hide CodeBlockCommentDelimiters, CodeLanguageProfile, CommonKeyBindings, EditBuffer, EditHistoryCoalescePredicate, EditHistoryController, EditHistoryMarkerBuilder, EditHistoryStateEquals, EditorCoreConfig, EditorState, GraphemePredicate, GraphemeReader, Help, KeyBinding, KeyMap, PasteMsg, Row, Spinner, SpinnerModel, SpinnerTickMsg, Spinners, Text, TextCommandResult, TextCursorCommandResult, TextDecorationLayerKey, TextDecorationRange, TextDiagnosticRange, TextDiagnosticSeverity, TextDocument, TextDocumentChange, TextDocumentEditResult, TextEditResult, TextExtmark, TextExtmarkOptions, TextExtmarkPositionRange, TextExtmarksController, TextHighlightRange, TextHitResult, TextLineCommandResult, TextLineDecoration, TextLineStateCommandExtensions, TextLineStateSnapshot, TextOffsetStateCommandExtensions, TextOffsetStateDocumentEditingExtensions, TextOffsetStateSnapshot, TextPasteChunk, TextPasteChunkStep, TextPasteController, TextPasteMode, TextPastePlan, TextPasteReference, TextPasteReferenceStore, TextPasteSession, TextPatternDiagnosticRule, TextPosition, TextPositionDiagnosticRange, TextSelection, TextSyntaxBuildResult, TextSyntaxChangeWindow, TextSyntaxDecorationPatch, TextSyntaxLineWindow, TextSyntaxProvider, TextSyntaxSession, TextSyntaxSnapshot, TextView, TextViewLine, TextViewport, TextVisualCursorPosition, UndoCommandDecoder, UndoCommandJournalEntry, UndoManager, UndoableCommand;
import 'package:artisanal/src/style/style.dart';

void main() {
  // Simulate exactly what DataTableModel does for the demo columns
  final cols = [
    Column(title: 'PID', width: 6),
    Column(title: 'Name', width: 20),
    Column(title: 'CPU', width: 8),
    Column(title: 'Mem', width: 10),
  ];
  final totalWidth = cols.fold(0, (s, c) => s + c.width + 2);
  print('totalWidth: $totalWidth');

  // Test: what does _headersView produce?
  // Reproduce it manually
  final headerStyle = Style().bold().padding(0, 1);
  for (final col in cols) {
    final widthStyle = Style()
        .inline(true)
        .width(col.width)
        .maxWidth(col.width);
    final rendered = widthStyle.render(col.title);
    final cell = headerStyle.render(rendered);
    print(
      'col "${col.title}" width=${col.width} '
      'cellLen=${Style.visibleLength(cell)} cell="$cell"',
    );
  }
}
