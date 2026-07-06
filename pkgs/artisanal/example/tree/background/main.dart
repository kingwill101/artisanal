/// Background tree example - ported from lipgloss/examples/tree/background
///
/// Demonstrates tree with background colors on items and enumerators.
library;
import 'package:artisanal/bubbles.dart' hide CodeBlockCommentDelimiters, CodeLanguageProfile, Column, CommonKeyBindings, EditBuffer, EditHistoryCoalescePredicate, EditHistoryController, EditHistoryMarkerBuilder, EditHistoryStateEquals, EditorCoreConfig, EditorState, GraphemePredicate, GraphemeReader, Help, KeyBinding, KeyMap, PasteMsg, Row, Spinner, SpinnerModel, SpinnerTickMsg, Spinners, Text, TextCommandResult, TextCursorCommandResult, TextDecorationLayerKey, TextDecorationRange, TextDiagnosticRange, TextDiagnosticSeverity, TextDocument, TextDocumentChange, TextDocumentEditResult, TextEditResult, TextExtmark, TextExtmarkOptions, TextExtmarkPositionRange, TextExtmarksController, TextHighlightRange, TextHitResult, TextLineCommandResult, TextLineDecoration, TextLineStateCommandExtensions, TextLineStateSnapshot, TextOffsetStateCommandExtensions, TextOffsetStateDocumentEditingExtensions, TextOffsetStateSnapshot, TextPasteChunk, TextPasteChunkStep, TextPasteController, TextPasteMode, TextPastePlan, TextPasteReference, TextPasteReferenceStore, TextPasteSession, TextPatternDiagnosticRule, TextPosition, TextPositionDiagnosticRange, TextSelection, TextSyntaxBuildResult, TextSyntaxChangeWindow, TextSyntaxDecorationPatch, TextSyntaxLineWindow, TextSyntaxProvider, TextSyntaxSession, TextSyntaxSnapshot, TextView, TextViewLine, TextViewport, TextVisualCursorPosition, UndoCommandDecoder, UndoCommandJournalEntry, UndoManager, UndoableCommand;

import 'package:artisanal/artisanal.dart';
import 'package:artisanal/style.dart';

void main() {
  final enumeratorStyle = Style().background(AnsiColor(0)).padding(0, 1);

  final headerItemStyle = Style()
      .background(BasicColor('#ee6ff8'))
      .foreground(BasicColor('#ecfe65'))
      .bold()
      .padding(0, 1);

  final itemStyle = headerItemStyle.copy().background(AnsiColor(0));

  final t = Tree()
      .root('# Table of Contents')
      .rootStyle(itemStyle)
      .itemStyle(itemStyle)
      .enumeratorStyle(enumeratorStyle)
      .indenterStyle(enumeratorStyle)
      .child(
        Tree().root('## Chapter 1').child('Chapter 1.1').child('Chapter 1.2'),
      )
      .child(
        Tree().root('## Chapter 2').child('Chapter 2.1').child('Chapter 2.2'),
      );

  print(t.render());
}
