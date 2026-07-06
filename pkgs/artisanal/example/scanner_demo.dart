#!/usr/bin/env dart
import 'package:artisanal/bubbles.dart' hide CodeBlockCommentDelimiters, CodeLanguageProfile, Column, CommonKeyBindings, EditBuffer, EditHistoryCoalescePredicate, EditHistoryController, EditHistoryMarkerBuilder, EditHistoryStateEquals, EditorCoreConfig, EditorState, GraphemePredicate, GraphemeReader, Help, KeyBinding, KeyMap, PasteMsg, Row, Spinner, SpinnerModel, SpinnerTickMsg, Spinners, Text, TextCommandResult, TextCursorCommandResult, TextDecorationLayerKey, TextDecorationRange, TextDiagnosticRange, TextDiagnosticSeverity, TextDocument, TextDocumentChange, TextDocumentEditResult, TextEditResult, TextExtmark, TextExtmarkOptions, TextExtmarkPositionRange, TextExtmarksController, TextHighlightRange, TextHitResult, TextLineCommandResult, TextLineDecoration, TextLineStateCommandExtensions, TextLineStateSnapshot, TextOffsetStateCommandExtensions, TextOffsetStateDocumentEditingExtensions, TextOffsetStateSnapshot, TextPasteChunk, TextPasteChunkStep, TextPasteController, TextPasteMode, TextPastePlan, TextPasteReference, TextPasteReferenceStore, TextPasteSession, TextPatternDiagnosticRule, TextPosition, TextPositionDiagnosticRange, TextSelection, TextSyntaxBuildResult, TextSyntaxChangeWindow, TextSyntaxDecorationPatch, TextSyntaxLineWindow, TextSyntaxProvider, TextSyntaxSession, TextSyntaxSnapshot, TextView, TextViewLine, TextViewport, TextVisualCursorPosition, UndoCommandDecoder, UndoCommandJournalEntry, UndoManager, UndoableCommand;

import 'dart:io';
import 'dart:math';
import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart';

/// Run this directly: dart run example/scanner_demo.dart
void main() async {
  final terminal = StdioTerminal(stdout: stdout, stdin: stdin);

  print('Testing scanner animation (Knight Rider style)...\n');

  // Test 1: Default scanner with runSpinnerTask
  print('1. Default scanner (purple, blocks, 8 wide):');
  await _task(
    'Scanning...',
    Spinners.scanner(),
    terminal,
    const Duration(seconds: 4),
  );

  print('\n2. Scanner with success result:');
  final result = await _task(
    'Processing...',
    Spinners.scanner(),
    terminal,
    const Duration(seconds: 3),
    returns: 'Complete!',
  );
  print('   Result: $result');

  print('\n3. Scanner + esc label (interrupt indicator, 5s auto-quit):');
  final escLabel = Style().dim().foreground(Colors.muted).render('esc');
  final quitMsg = Style()
      .dim()
      .foreground(Colors.muted)
      .render('(auto-quit in 5s)');
  await _task(
    'Scanning... $escLabel $quitMsg',
    Spinners.scanner(),
    terminal,
    const Duration(seconds: 5),
  );

  print('\n4. Scanner with diamonds style:');
  await _task(
    'Scanning diamonds...',
    Spinners.scanner(chars: ScannerChars.diamonds),
    terminal,
    const Duration(seconds: 3),
  );

  print('\n5. Scanner with custom colors:');
  await _task(
    'Green scanner...',
    Spinners.scanner(color: Colors.green),
    terminal,
    const Duration(seconds: 3),
  );

  print('\n6. Scanner with wide bar (12 chars):');
  await _task(
    'Wide scanning...',
    Spinners.scanner(width: 12),
    terminal,
    const Duration(seconds: 4),
  );

  print('\n7. Scanner all colors gallery:');
  final colors = [
    Colors.purple,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.red,
    Colors.cyan,
    Colors.magenta,
  ];
  for (final color in colors) {
    await _task(
      '  Scanner',
      Spinners.scanner(color: color, holdEnd: 3, holdStart: 8),
      terminal,
      const Duration(milliseconds: 1200),
    );
  }

  print('\n8. Sequential messages with scanner:');
  final messages = [
    'Analyzing code...',
    'Checking dependencies...',
    'Running tests...',
    'Building assets...',
    'Linting files...',
  ];
  for (final msg in messages) {
    final delay = Random().nextInt(2000) + 1000;
    await _task(
      msg,
      Spinners.scanner(),
      terminal,
      Duration(milliseconds: delay),
    );
  }

  print('\nAll scanner demos completed!');
  await shutdownSharedStdinStream();
}

Future<String> _task(
  String message,
  Spinner spinner,
  StdioTerminal terminal,
  Duration delay, {
  String? returns,
}) {
  return runSpinnerTask<String>(
    message: message,
    spinner: spinner,
    terminal: terminal,
    task: () async {
      await Future<void>.delayed(delay);
      return returns ?? 'done';
    },
  );
}
