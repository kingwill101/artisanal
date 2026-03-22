/// Demonstrates terminal breakpoint detection and responsive branching behavior.
library;

import 'dart:math' as math;

import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart' as tui;

const _fallbackWidth = 64;

const _defaultBreakpoints = ResponsiveBreakpoints.defaults;

const _compactBreakpoints = ResponsiveBreakpoints(
  xs: 0,
  sm: 30,
  md: 54,
  lg: 78,
  xl: 108,
);

final _headerStyle = Style().bold().foreground(const BasicColor('#9BC8FF'));
final _bodyStyle = Style().foreground(const BasicColor('#B8C1CC'));
final _noteStyle = Style().foreground(const BasicColor('#8899AA')).italic();
final _cardStyle = Style()
    .padding(1, 1)
    .border(Border.rounded, top: true, bottom: true, left: true, right: true);

void main() async {
  await tui.runProgram(_BreakpointDemoModel(width: 0, height: 0));
}

final class _BreakpointDemoModel implements tui.Model {
  const _BreakpointDemoModel({
    required this.width,
    required this.height,
    this.compactProfile = false,
  });

  final int width;
  final int height;
  final bool compactProfile;

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

        if (rune == 0x70) {
          return (copyWith(compactProfile: !compactProfile), null);
        }

      case tui.WindowSizeMsg(width: final w, height: final h):
        return (copyWith(width: w, height: h), null);
    }

    return (this, null);
  }

  @override
  String view() {
    final viewportWidth = width <= 0 ? _fallbackWidth : width;
    final breakpoints = compactProfile
        ? _compactBreakpoints
        : _defaultBreakpoints;
    final columns = _columnsForViewport(viewportWidth, breakpoints);
    final panelWidth = _panelWidth(viewportWidth, columns);
    final active = breakpoints.resolve(viewportWidth);
    final canSplit = breakpoints.isAtLeast(viewportWidth, LayoutBreakpoint.md);
    final isBelowLg = breakpoints.isBelow(viewportWidth, LayoutBreakpoint.lg);

    final cards = <String>[
      _panel(
        title: 'Active Breakpoints',
        lines: [
          'Profile: ${compactProfile ? 'compact' : 'default'}',
          'Current bucket: $active',
          'md+ split: ${canSplit ? 'true' : 'false'}',
          'below lg: $isBelowLg',
        ],
        width: panelWidth,
      ),
      _panel(
        title: 'Thresholds',
        lines: [
          'xs: ${breakpoints.xs}',
          'sm: ${breakpoints.sm}',
          'md: ${breakpoints.md}',
          'lg: ${breakpoints.lg}',
          'xl: ${breakpoints.xl}',
        ],
        width: panelWidth,
      ),
      _panel(
        title: 'Layout Switch',
        lines: [
          'Window: ${width}x$height',
          'Columns now: $columns',
          'Strategy: ${_layoutMode(columns)}',
          'Resize terminal or press `p` to compare profiles.',
        ],
        width: panelWidth,
      ),
    ];

    final header = _panel(
      title: 'Responsive Breakpoints',
      lines: [
        'Resize terminal to trigger transitions.',
        'Press `p` to toggle default vs compact thresholds.',
        'Press q/esc/Ctrl+C to quit.',
      ],
      width: viewportWidth - 4,
    );

    return Layout.joinVertical(HorizontalAlign.left, [
      header,
      _renderCards(cards, columns: columns),
    ], gap: 1);
  }

  _BreakpointDemoModel copyWith({
    int? width,
    int? height,
    bool? compactProfile,
  }) {
    return _BreakpointDemoModel(
      width: width ?? this.width,
      height: height ?? this.height,
      compactProfile: compactProfile ?? this.compactProfile,
    );
  }
}

int _columnsForViewport(int width, ResponsiveBreakpoints breakpoints) {
  if (breakpoints.isAtLeast(width, LayoutBreakpoint.lg)) return 3;
  if (breakpoints.isAtLeast(width, LayoutBreakpoint.md)) return 2;
  return 1;
}

int _panelWidth(int width, int columns) {
  final available = math.max(24, width - 4);
  final gapWidth = math.max(0, columns - 1) * 2;
  return math.max(22, (available - gapWidth) ~/ columns);
}

String _layoutMode(int columns) {
  if (columns >= 3) return '3 columns';
  if (columns >= 2) return '2 columns';
  return '1 column';
}

String _renderCards(List<String> cards, {required int columns}) {
  if (columns <= 1) {
    return Layout.joinVertical(HorizontalAlign.left, cards, gap: 1);
  }

  final rows = <String>[];
  for (var i = 0; i < cards.length; i += columns) {
    final row = cards.sublist(i, math.min(i + columns, cards.length));
    rows.add(Layout.joinHorizontal(VerticalAlign.top, row, gap: 2));
  }

  return Layout.joinVertical(HorizontalAlign.left, rows, gap: 1);
}

String _panel({
  required String title,
  required List<String> lines,
  required int width,
}) {
  final content = Layout.joinVertical(HorizontalAlign.left, [
    _headerStyle.render(title),
    for (final line in lines) _bodyStyle.render(line),
    _noteStyle.render('Using isAtLeast / isBelow / resolve'),
  ], gap: 1);

  return _cardStyle.width(width).render(content);
}
