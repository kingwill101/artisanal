/// Demonstrates responsive layout composition with `Layout.joinHorizontal` and
/// `Layout.joinVertical`.
library;

import 'dart:math' as math;

import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart' as tui;

const _fallbackWidth = 60;

final _cardBorder = Style()
    .padding(1, 1)
    .border(Border.rounded, top: true, bottom: true, left: true, right: true)
    .foreground(const BasicColor('#B9D2FF'));

final _titleStyle = Style().bold();
final _metaStyle = Style().foreground(const BasicColor('#9AA9BB'));

void main() async {
  await tui.runProgram(const _LayoutDemoModel(width: 0, height: 0));
}

final class _LayoutDemoModel implements tui.Model {
  const _LayoutDemoModel({required this.width, required this.height});

  final int width;
  final int height;

  @override
  tui.Cmd? init() {
    return tui.Cmd.windowSize();
  }

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
    final viewportWidth = width <= 0 ? _fallbackWidth : width;
    final columns = _layoutColumns(viewportWidth);
    final panelWidth = _panelWidth(viewportWidth, columns);

    final cards = <String>[
      _panel(
        title: 'Window State',
        details: [
          'Size: ${width}x$height',
          'Columns: $columns',
          'Panel width: $panelWidth',
        ],
        width: panelWidth,
      ),
      _panel(
        title: 'Card Layout',
        details: [
          'Uses joinVertical for stacked mode.',
          'Uses joinHorizontal for side-by-side mode.',
          'Width changes trigger reflow instantly.',
        ],
        width: panelWidth,
      ),
      _panel(
        title: 'Layout Notes',
        details: [
          'All cards are plain text blocks',
          'with explicit alignment via Layout helpers.',
          'No external state except viewport size.',
        ],
        width: panelWidth,
      ),
    ];

    return Layout.joinVertical(HorizontalAlign.left, [
      _panel(
        title: 'Layout primitives',
        details: [
          'Resize terminal to see card layout switch modes.',
          'Press q/esc/Ctrl+C to quit.',
          'Mode: ${_layoutMode(viewportWidth)}',
        ],
        width: viewportWidth,
      ),
      _renderCardGrid(cards, columns: columns),
    ], gap: 1);
  }

  _LayoutDemoModel copyWith({int? width, int? height}) {
    return _LayoutDemoModel(
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }
}

int _panelWidth(int terminalWidth, int columns) {
  final available = math.max(20, terminalWidth - 4);
  final gapWidth = math.max(0, columns - 1) * 2;
  return math.max(20, (available - gapWidth) ~/ columns);
}

int _layoutColumns(int width) {
  if (width >= 120) return 3;
  if (width >= 70) return 2;
  return 1;
}

String _layoutMode(int width) {
  if (width >= 120) return '3-up';
  if (width >= 70) return '2-up';
  return 'stacked';
}

String _renderCardGrid(List<String> cards, {required int columns}) {
  if (columns <= 1) {
    return Layout.joinVertical(HorizontalAlign.left, cards, gap: 1);
  }

  final rows = <String>[];
  for (var i = 0; i < cards.length; i += columns) {
    final rowCards = cards.sublist(i, math.min(i + columns, cards.length));
    rows.add(Layout.joinHorizontal(VerticalAlign.top, rowCards, gap: 2));
  }

  return Layout.joinVertical(HorizontalAlign.left, rows, gap: 1);
}

String _panel({
  required String title,
  required List<String> details,
  required int width,
}) {
  final body = Layout.joinVertical(HorizontalAlign.left, [
    _titleStyle.render(title),
    for (final line in details) _metaStyle.render('- $line'),
  ], gap: 1);

  return _cardBorder.width(width).render(body);
}
