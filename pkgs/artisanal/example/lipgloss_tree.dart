/// Dart port of lipgloss tree examples.
///
/// Demonstrates the Tree component with various styles.
///
/// Run with: dart run example/lipgloss_tree.dart
library;
import 'package:artisanal/bubbles.dart' hide CodeBlockCommentDelimiters, CodeLanguageProfile, Column, CommonKeyBindings, EditBuffer, EditHistoryCoalescePredicate, EditHistoryController, EditHistoryMarkerBuilder, EditHistoryStateEquals, EditorCoreConfig, EditorState, GraphemePredicate, GraphemeReader, Help, KeyBinding, KeyMap, PasteMsg, Row, Spinner, SpinnerModel, SpinnerTickMsg, Spinners, Text, TextCommandResult, TextCursorCommandResult, TextDecorationLayerKey, TextDecorationRange, TextDiagnosticRange, TextDiagnosticSeverity, TextDocument, TextDocumentChange, TextDocumentEditResult, TextEditResult, TextExtmark, TextExtmarkOptions, TextExtmarkPositionRange, TextExtmarksController, TextHighlightRange, TextHitResult, TextLineCommandResult, TextLineDecoration, TextLineStateCommandExtensions, TextLineStateSnapshot, TextOffsetStateCommandExtensions, TextOffsetStateDocumentEditingExtensions, TextOffsetStateSnapshot, TextPasteChunk, TextPasteChunkStep, TextPasteController, TextPasteMode, TextPastePlan, TextPasteReference, TextPasteReferenceStore, TextPasteSession, TextPatternDiagnosticRule, TextPosition, TextPositionDiagnosticRange, TextSelection, TextSyntaxBuildResult, TextSyntaxChangeWindow, TextSyntaxDecorationPatch, TextSyntaxLineWindow, TextSyntaxProvider, TextSyntaxSession, TextSyntaxSnapshot, TextView, TextViewLine, TextViewport, TextVisualCursorPosition, UndoCommandDecoder, UndoCommandJournalEntry, UndoManager, UndoableCommand;

import 'package:artisanal/artisanal.dart';
import 'package:artisanal/style.dart';

void main() {
  print('=== Simple Tree ===\n');
  _simpleTree();

  print('\n=== Styled Tree ===\n');
  _styledTree();

  print('\n=== File System Tree ===\n');
  _fileSystemTree();
}

/// Simple tree example from lipgloss.
void _simpleTree() {
  final tree = Tree()
      .root('.')
      .child('macOS')
      .child(
        Tree()
            .root('Linux')
            .child('NixOS')
            .child('Arch Linux (btw)')
            .child('Void Linux'),
      )
      .child(Tree().root('BSD').child('FreeBSD').child('OpenBSD'));

  print(tree.render());
}

/// Tree with custom styling.
void _styledTree() {
  final rootStyle = Style().bold().foreground(BasicColor('#FF6B6B'));

  final dirStyle = Style().foreground(BasicColor('#7D56F4')).bold();

  final fileStyle = Style().foreground(BasicColor('#FAFAFA'));

  final branchStyle = Style().foreground(BasicColor('#7D56F4'));

  final tree = Tree()
      .root('🌳 Projects')
      .enumerator(TreeEnumerator.rounded)
      .rootStyle(rootStyle)
      .itemStyleFunc((children, index) {
        final node = children[index];
        return node.childrenNodes.isNotEmpty ? dirStyle : fileStyle;
      })
      .enumeratorStyle(branchStyle)
      .indenterStyle(branchStyle)
      .child(
        Tree()
            .root('📁 dart_packages')
            .child('📦 artisanal')
            .child('📦 ormed')
            .child('📦 ormed_cli'),
      )
      .child(Tree().root('📁 web_apps').child('🌐 portfolio').child('🌐 blog'))
      .child(
        Tree()
            .root('📁 experiments')
            .child('🧪 ml_playground')
            .child('🧪 rust_learning'),
      );

  print(tree.render());
}

/// File system tree with icons.
void _fileSystemTree() {
  final tree = Tree()
      .root('lib/')
      .enumerator(TreeEnumerator.normal)
      .itemStyleFunc((children, index) {
        final node = children[index];
        final item = node.value;
        // Color files differently than directories
        final isFile = item.endsWith('.dart');
        if (isFile) {
          return Style().foreground(BasicColor('#73F59F'));
        }
        return Style().foreground(BasicColor('#7D56F4')).bold();
      })
      .child(
        Tree()
            .root('src/')
            .child(
              Tree()
                  .root('components/')
                  .child('alert.dart')
                  .child('box.dart')
                  .child('spinner.dart')
                  .child('table.dart')
                  .child('tree.dart'),
            )
            .child(
              Tree()
                  .root('style/')
                  .child('border.dart')
                  .child('color.dart')
                  .child('style.dart'),
            )
            .child('layout.dart'),
      )
      .child('artisanal.dart');

  print(tree.render());
}
