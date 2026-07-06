/// Fullscreen border showcase for artisanal.
library;
import 'package:artisanal/bubbles.dart' as tui hide CodeBlockCommentDelimiters, CodeLanguageProfile, Column, CommonKeyBindings, EditBuffer, EditHistoryCoalescePredicate, EditHistoryController, EditHistoryMarkerBuilder, EditHistoryStateEquals, EditorCoreConfig, EditorState, GraphemePredicate, GraphemeReader, Help, KeyBinding, KeyMap, PasteMsg, Row, Spinner, SpinnerModel, SpinnerTickMsg, Spinners, Text, TextCommandResult, TextCursorCommandResult, TextDecorationLayerKey, TextDecorationRange, TextDiagnosticRange, TextDiagnosticSeverity, TextDocument, TextDocumentChange, TextDocumentEditResult, TextEditResult, TextExtmark, TextExtmarkOptions, TextExtmarkPositionRange, TextExtmarksController, TextHighlightRange, TextHitResult, TextLineCommandResult, TextLineDecoration, TextLineStateCommandExtensions, TextLineStateSnapshot, TextOffsetStateCommandExtensions, TextOffsetStateDocumentEditingExtensions, TextOffsetStateSnapshot, TextPasteChunk, TextPasteChunkStep, TextPasteController, TextPasteMode, TextPastePlan, TextPasteReference, TextPasteReferenceStore, TextPasteSession, TextPatternDiagnosticRule, TextPosition, TextPositionDiagnosticRange, TextSelection, TextSyntaxBuildResult, TextSyntaxChangeWindow, TextSyntaxDecorationPatch, TextSyntaxLineWindow, TextSyntaxProvider, TextSyntaxSession, TextSyntaxSnapshot, TextView, TextViewLine, TextViewport, TextVisualCursorPosition, UndoCommandDecoder, UndoCommandJournalEntry, UndoManager, UndoableCommand;

import 'dart:math' as math;

import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart' as tui;

const _fallbackWidth = 96;
const _fallbackHeight = 30;

final _heroStyle = Style()
    .foreground(Colors.white)
    .border(Border.rounded)
    .borderForeground(const BasicColor('#38bdf8'))
    .padding(1, 2);

final _cardBaseStyle = Style().foreground(Colors.gray).padding(1, 2);

Future<void> main() async {
  await tui.runProgram(
    const BorderShowcaseModel(width: 0, height: 0),
    options: const tui.ProgramOptions(altScreen: true, hideCursor: true),
  );
}

final class BorderShowcaseModel implements tui.Model {
  const BorderShowcaseModel({required this.width, required this.height});

  final int width;
  final int height;

  @override
  tui.Cmd? init() => tui.Cmd.windowSize();

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    switch (msg) {
      case tui.KeyMsg(key: final key):
        final rune = key.runes.isNotEmpty ? key.runes.first : -1;
        if (key.type == tui.KeyType.escape ||
            rune == 0x71 ||
            (key.ctrl && rune == 0x63)) {
          return (this, tui.Cmd.quit());
        }

      case tui.WindowSizeMsg(width: final w, height: final h):
        return (copyWith(width: w, height: h), null);
    }

    return (this, null);
  }

  @override
  String view() {
    final viewportWidth = width > 0 ? width : _fallbackWidth;
    final viewportHeight = height > 0 ? height : _fallbackHeight;
    final columns = viewportWidth >= 130
        ? 3
        : viewportWidth >= 85
        ? 2
        : 1;
    final cardWidth = columns == 1
        ? viewportWidth
        : math.max(24, (viewportWidth - (columns - 1) * 2) ~/ columns);
    final splitWidth = columns == 2
        ? math.max(30, viewportWidth ~/ 3)
        : cardWidth;
    final borderWidth = columns == 2
        ? math.max(24, viewportWidth - splitWidth - 2)
        : cardWidth;

    final hero = _heroCard(viewportWidth);
    final borderCard = _borderCard(borderWidth);
    final splitCard = _splitCard(splitWidth);
    final colorCard = columns == 2
        ? _colorCard(viewportWidth)
        : _colorCard(cardWidth);

    final grid = switch (columns) {
      1 => Layout.joinVertical(HorizontalAlign.left, [
        borderCard,
        splitCard,
        colorCard,
      ], gap: 1),
      2 => Layout.joinVertical(HorizontalAlign.left, [
        Layout.joinHorizontal(VerticalAlign.top, [
          borderCard,
          splitCard,
        ], gap: 2),
        colorCard,
      ], gap: 1),
      _ => Layout.joinVertical(HorizontalAlign.left, [
        Layout.joinHorizontal(VerticalAlign.top, [
          borderCard,
          splitCard,
          colorCard,
        ], gap: 2),
      ], gap: 1),
    };

    final footer = _footerCard();

    final content = Layout.joinVertical(HorizontalAlign.left, [
      hero,
      grid,
      footer,
    ], gap: 1);

    final viewport = tui.ViewportModel(
      width: viewportWidth,
      height: viewportHeight,
      fillHeight: true,
      style: Style().background(const BasicColor('#020617')),
    ).setContent(content);

    return viewport.view();
  }

  BorderShowcaseModel copyWith({int? width, int? height}) {
    return BorderShowcaseModel(
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }
}

String _heroCard(int width) {
  return _heroStyle
      .copy()
      .width(width)
      .render(
        Layout.joinVertical(HorizontalAlign.left, const [
          'Border showcase',
          'Border presets, border colors, foreground text, and background fills in one fullscreen TUI.',
          'Press q, esc, or Ctrl+C to quit.',
        ], gap: 1),
      );
}

String _borderCard(int width) {
  return _cardBaseStyle
      .copy()
      .width(width)
      .foreground(Colors.white)
      .border(Border.double)
      .borderForeground(const BasicColor('#f59e0b'))
      .render(
        Layout.joinVertical(HorizontalAlign.left, [
          'Border presets',
          'Rounded, double, thick, and ASCII presets.',
          _chipRow([
            _chip('rounded', Colors.white, const BasicColor('#1f2937')),
            _chip('double', Colors.white, const BasicColor('#1d4ed8')),
            _chip('thick', Colors.white, const BasicColor('#7c2d12')),
            _chip('ascii', Colors.white, const BasicColor('#374151')),
          ]),
        ], gap: 1),
      );
}

String _splitCard(int width) {
  final body = Style()
      .width(width)
      .foreground(Colors.gray)
      .render(
        Layout.joinVertical(HorizontalAlign.left, [
          'Split rail',
          'One visible rail, no top or bottom edge.',
          _chipRow([
            _chip('left rail', Colors.white, const BasicColor('#6b21a8')),
            _chip('muted body', Colors.white, const BasicColor('#1f2937')),
          ]),
        ], gap: 1),
      );

  final railHeight = Layout.height(body);
  final rail = Style()
      .border(Border.split, top: false, right: false, bottom: false, left: true)
      .borderForeground(const BasicColor('#a855f7'))
      .render(List.filled(railHeight, ' ').join('\n'));

  return Layout.joinHorizontal(VerticalAlign.top, [rail, body], gap: 1);
}

String _colorCard(int width) {
  return Style()
      .width(width)
      .foreground(Colors.white)
      .border(Border.rounded)
      .borderForeground(const BasicColor('#22c55e'))
      .padding(1, 2)
      .render(
        Layout.joinVertical(HorizontalAlign.left, [
          'Foreground and background',
          'Explicit foreground and background pairs.',
          _chipRow([
            _chip('cyan/navy', Colors.cyan, const BasicColor('#0f172a')),
            _chip('green/slate', Colors.green, const BasicColor('#1e293b')),
            _chip('yellow/ink', Colors.yellow, const BasicColor('#111827')),
          ]),
        ], gap: 1),
      );
}

String _footerCard() {
  final rail = Style()
      .border(Border.split, top: false, right: false, bottom: false, left: true)
      .borderForeground(const BasicColor('#64748b'))
      .padding(0, 0)
      .render(' ');

  final text = Style()
      .foreground(Colors.gray)
      .render(
        'Footer rail demo  •  q / esc / Ctrl+C quit  •  resize the terminal to reflow cards',
      );

  return Layout.joinHorizontal(VerticalAlign.top, [rail, text], gap: 1);
}

String _chip(String label, Color fg, Color bg) {
  return Style().foreground(fg).background(bg).padding(0, 1).render(label);
}

String _chipRow(List<String> chips) =>
    Layout.joinHorizontal(VerticalAlign.top, chips, gap: 1);
