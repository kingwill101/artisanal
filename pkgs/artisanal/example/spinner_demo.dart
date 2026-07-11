#!/usr/bin/env dart

import 'package:artisanal/bubbles.dart'
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

import 'dart:io';
import 'package:artisanal/tui.dart';

/// Run this directly: dart run example/spinner_demo.dart
void main() async {
  final terminal = StdioTerminal(stdout: stdout, stdin: stdin);

  print('Testing animated spinner...\n');

  // Test 1: Basic spinner with dots
  print('1. Dots spinner (default):');
  await runSpinnerTask<void>(
    message: 'Loading data...',
    terminal: terminal,
    task: () async {
      await Future<void>.delayed(const Duration(seconds: 5));
    },
  );

  print('\n2. Line spinner:');
  await runSpinnerTask<void>(
    message: 'Processing...',
    spinner: Spinners.line,
    terminal: terminal,
    task: () async {
      await Future<void>.delayed(const Duration(seconds: 2));
    },
  );

  print('\n3. Circle spinner:');
  await runSpinnerTask<void>(
    message: 'Compiling...',
    spinner: Spinners.circle,
    terminal: terminal,
    task: () async {
      await Future<void>.delayed(const Duration(seconds: 2));
    },
  );

  print('\n4. Arc spinner:');
  await runSpinnerTask<void>(
    message: 'Uploading...',
    spinner: Spinners.arc,
    terminal: terminal,
    task: () async {
      await Future<void>.delayed(const Duration(seconds: 2));
    },
  );

  print('\n5. Arrows spinner:');
  await runSpinnerTask<void>(
    message: 'Syncing...',
    spinner: Spinners.arrows,
    terminal: terminal,
    task: () async {
      await Future<void>.delayed(const Duration(seconds: 2));
    },
  );

  print('\n6. Error spinner:');
  try {
    await runSpinnerTask<void>(
      message: 'This will fail...',
      terminal: terminal,
      task: () async {
        await Future<void>.delayed(const Duration(seconds: 2));
        throw Exception('Simulated error');
      },
    );
  } catch (_) {
    // Ignore.
  }

  print('\nAll spinners tested!');
  await shutdownSharedStdinStream();
}
