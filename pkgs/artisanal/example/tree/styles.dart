/// Styled tree example - demonstrates per-subtree styling.
///
/// This is a port of the Go lipgloss example: examples/tree/styles/main.go
library;
import 'package:artisanal/bubbles.dart' hide CodeBlockCommentDelimiters, CodeLanguageProfile, Column, CommonKeyBindings, EditBuffer, EditHistoryCoalescePredicate, EditHistoryController, EditHistoryMarkerBuilder, EditHistoryStateEquals, EditorCoreConfig, EditorState, GraphemePredicate, GraphemeReader, Help, KeyBinding, KeyMap, PasteMsg, Row, Spinner, SpinnerModel, SpinnerTickMsg, Spinners, Text, TextCommandResult, TextCursorCommandResult, TextDecorationLayerKey, TextDecorationRange, TextDiagnosticRange, TextDiagnosticSeverity, TextDocument, TextDocumentChange, TextDocumentEditResult, TextEditResult, TextExtmark, TextExtmarkOptions, TextExtmarkPositionRange, TextExtmarksController, TextHighlightRange, TextHitResult, TextLineCommandResult, TextLineDecoration, TextLineStateCommandExtensions, TextLineStateSnapshot, TextOffsetStateCommandExtensions, TextOffsetStateDocumentEditingExtensions, TextOffsetStateSnapshot, TextPasteChunk, TextPasteChunkStep, TextPasteController, TextPasteMode, TextPastePlan, TextPasteReference, TextPasteReferenceStore, TextPasteSession, TextPatternDiagnosticRule, TextPosition, TextPositionDiagnosticRange, TextSelection, TextSyntaxBuildResult, TextSyntaxChangeWindow, TextSyntaxDecorationPatch, TextSyntaxLineWindow, TextSyntaxProvider, TextSyntaxSession, TextSyntaxSnapshot, TextView, TextViewLine, TextViewport, TextVisualCursorPosition, UndoCommandDecoder, UndoCommandJournalEntry, UndoManager, UndoableCommand;

import 'package:artisanal/artisanal.dart';
import 'package:artisanal/style.dart';

void main() {
  final purple = Style().foreground(AnsiColor(99)).marginRight(1);
  final pink = Style().foreground(AnsiColor(212)).marginRight(1);

  final t = Tree()
      .child('Glossier')
      .child("Claire's Boutique")
      .child(
        Tree()
            .root('Nyx')
            .child('Lip Gloss')
            .child('Foundation')
            .enumeratorStyle(pink)
            .indenterStyle(pink),
      )
      .child('Mac')
      .child('Milk')
      .enumeratorStyle(purple)
      .indenterStyle(purple);

  print(t.render());
}
