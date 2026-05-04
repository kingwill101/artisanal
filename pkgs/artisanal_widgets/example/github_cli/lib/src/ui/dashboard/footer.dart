import 'package:artisanal/style.dart' show Colors;
import 'package:artisanal_widgets/widgets.dart' as w;

import '../../app/layout_mode.dart';

w.Widget githubDashboardFooter(
  w.Theme theme, {
  required GithubDashboardLayoutMode layoutMode,
  required String themeName,
  String? notice,
}) {
  final keyStyle = theme.bodyMedium.copy()..foreground(Colors.warning);
  final hintStyle = theme.bodyMedium.copy()..foreground(theme.muted);
  final noticeStyle = theme.bodySmall.copy()..foreground(Colors.green);

  w.Widget key(String value) => w.Text(value, style: keyStyle);
  w.Widget label(String value) => w.Text(value, style: hintStyle);
  final focused = layoutMode.isFocused;

  return w.Row(
    gap: 1,
    children: [
      key('↑↓/j/k'),
      label(focused ? 'scroll' : 'move'),
      key('pg/ctrl+d/u'),
      label('page'),
      if (!focused) ...[
        key('n'),
        label('more'),
        key('enter'),
        label('focus/run'),
      ],
      key(focused ? 'f/esc' : 'f'),
      label(focused ? 'split' : 'focus'),
      if (focused) ...[key('tab/←→'), label('detail tabs')],
      key('t'),
      label(themeName),
      key('d'),
      label('diff'),
      key('c/v'),
      label('comments/review'),
      key('a/l/x'),
      label('mutate'),
      key('o'),
      label('open'),
      key('ctrl+o'),
      label('repo'),
      key('p'),
      label('palette'),
      key('r'),
      label('refresh'),
      key('q'),
      label('quit'),
      if (notice != null) w.Spacer(),
      if (notice != null)
        w.Text(notice, style: noticeStyle, overflow: w.TextOverflow.ellipsis),
    ],
  );
}
