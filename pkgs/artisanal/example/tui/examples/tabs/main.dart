/// Tabs example ported from Bubble Tea (lipgloss styling).
library;

import 'dart:math' as math;

import 'package:artisanal/style.dart';
import 'package:artisanal/src/tui/bubbles/runeutil.dart' show stringWidth;
import 'package:artisanal/tui.dart' as tui;

class TabsModel implements tui.Model {
  TabsModel({required this.tabs, required this.contents, this.active = 0});

  final List<String> tabs;
  final List<String> contents;
  final int active;

  TabsModel copyWith({int? active}) =>
      TabsModel(tabs: tabs, contents: contents, active: active ?? this.active);

  @override
  tui.Cmd? init() => null;

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    if (msg is tui.KeyMsg) {
      switch (msg.key.toString()) {
        case 'ctrl+c':
        case 'q':
          return (this, tui.Cmd.quit());
        case 'right':
        case 'l':
        case 'n':
        case 'tab':
          return (
            copyWith(active: math.min(active + 1, tabs.length - 1)),
            null,
          );
        case 'left':
        case 'h':
        case 'p':
        case 'shift+tab':
          return (copyWith(active: math.max(active - 1, 0)), null);
      }
    }
    return (this, null);
  }

  @override
  String view() {
    final doc = StringBuffer();
    final renderedTabs = <String>[];

    for (var i = 0; i < tabs.length; i++) {
      final isActive = i == active;
      final isFirst = i == 0;
      final isLast = i == tabs.length - 1;

      final border = _tabBorder(
        isActive: isActive,
        isFirst: isFirst,
        isLast: isLast,
      );

      final style = (isActive ? _activeTabStyle : _inactiveTabStyle).border(
        border,
        top: true,
        right: true,
        left: true,
      );

      renderedTabs.add(style.render(tabs[i]));
    }

    final row = _joinHorizontalTop(renderedTabs);
    doc.writeln(row);

    final rowWidth = _maxLineWidth(row);
    final contentWidth = _contentWidth(rowWidth);
    final window = _windowStyle.width(contentWidth).render(contents[active]);
    doc.writeln(window);

    return _docStyle.render(doc.toString());
  }
}

Border _tabBorder({
  required bool isActive,
  required bool isFirst,
  required bool isLast,
}) {
  final rounded = Border.rounded;
  final base = isActive ? _activeTabBorder : _inactiveTabBorder;
  var b = Border(
    topLeft: rounded.topLeft,
    top: rounded.top,
    topRight: rounded.topRight,
    right: rounded.right,
    left: rounded.left,
    bottomLeft: base.bottomLeft,
    bottom: base.bottom,
    bottomRight: base.bottomRight,
  );
  if (isFirst && isActive) b = b.copyWith(bottomLeft: '│');
  if (isFirst && !isActive) b = b.copyWith(bottomLeft: '├');
  if (isLast && isActive) b = b.copyWith(bottomRight: '│');
  if (isLast && !isActive) b = b.copyWith(bottomRight: '┤');
  return b;
}

Border _tabBorderWithBottom(String left, String mid, String right) {
  final rounded = Border.rounded;
  return Border(
    topLeft: rounded.topLeft,
    top: rounded.top,
    topRight: rounded.topRight,
    right: rounded.right,
    left: rounded.left,
    bottomLeft: left,
    bottom: mid,
    bottomRight: right,
  );
}

final _highlight = AnsiColor(93); // adaptive purple-ish
final _inactiveTabBorder = _tabBorderWithBottom('┴', '─', '┴');
final _activeTabBorder = _tabBorderWithBottom('┘', ' ', '└');

final _inactiveTabStyle = Style()
    .border(
      _inactiveTabBorder,
      top: true,
      right: true,
      left: true,
      bottom: true,
    )
    .borderForeground(_highlight)
    .padding(0, 1);
final _activeTabStyle = _inactiveTabStyle.border(
  _activeTabBorder,
  top: true,
  right: true,
  left: true,
  bottom: true,
);
final _windowStyle = Style()
    .border(Border.normal, top: false, right: true, bottom: true, left: true)
    .borderForeground(_highlight)
    .padding(2, 0)
    .align(HorizontalAlign.center);
final _docStyle = Style().padding(1, 2, 1, 2);

int _contentWidth(int rowWidth) {
  final frame = _windowStyle.getHorizontalFrameSize;
  return math.max(1, rowWidth - frame);
}

int _maxLineWidth(String s) {
  final lines = s.split('\n');
  var w = 0;
  for (final l in lines) {
    w = math.max(w, stringWidth(l));
  }
  return w;
}

/// Joins blocks horizontally, aligning to the top (similar to lipgloss.JoinHorizontal).
String _joinHorizontalTop(List<String> parts) {
  if (parts.isEmpty) return '';
  final split = parts.map((p) => p.split('\n')).toList();
  final heights = split.map((l) => l.length).toList();
  final widths = split
      .map((l) => l.map(stringWidth).fold<int>(0, math.max))
      .toList();
  final maxH = heights.fold<int>(0, math.max);

  final buffer = StringBuffer();
  for (var row = 0; row < maxH; row++) {
    for (var i = 0; i < split.length; i++) {
      final lines = split[i];
      final line = row < lines.length ? lines[row] : '';
      final pad = widths[i] - stringWidth(line);
      buffer.write(line);
      if (pad > 0) buffer.write(' ' * pad);
    }
    if (row < maxH - 1) buffer.writeln();
  }
  return buffer.toString();
}

Future<void> main() async {
  final tabs = ['Lip Gloss', 'Blush', 'Eye Shadow', 'Mascara', 'Foundation'];
  final contents = [
    'Lip Gloss Tab',
    'Blush Tab',
    'Eye Shadow Tab',
    'Mascara Tab',
    'Foundation Tab',
  ];
  await tui.runProgram(
    TabsModel(tabs: tabs, contents: contents),
    options: const tui.ProgramOptions(altScreen: false, hideCursor: false),
  );
}
