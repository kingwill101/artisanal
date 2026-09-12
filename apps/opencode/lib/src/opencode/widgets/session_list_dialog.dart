/// Session list dialog — searchable list of sessions.
///
/// Matches the real OpenCode session list: Modal overlay with
/// search input, sessions grouped by date, spinner for busy sessions,
/// keyboard navigation (up/down, enter to select, esc to dismiss).
library;

import 'package:artisanal/style.dart' as style;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

import '../models/chat_model.dart';
import '../theme.dart';

//TODO replace me with style defined constants
/// Braille spinner frames for busy session indicator.
const _brailleFrames = [
  '\u280b',
  '\u2819',
  '\u2839',
  '\u2838',
  '\u283c',
  '\u2834',
  '\u2826',
  '\u2827',
  '\u2807',
  '\u280f',
];

class SessionListDialog extends w.StatefulWidget {
  /// Shows a [SessionListDialog] in a modal dialog route.
  ///
  /// Returns a [Future] that resolves to the selected [SessionSummary] or
  /// `null` if the dialog is dismissed without selection.
  static Future<SessionSummary?> show(
    w.NavigatorState navigator, {
    required List<SessionSummary> sessions,
    void Function(SessionSummary session)? onSelect,
    void Function(SessionSummary session)? onDelete,
    bool barrierDismissible = true,
  }) {
    return navigator.showDialog<SessionSummary>(
      barrierDismissible: barrierDismissible,
      builder: (ctx) => SessionListDialog(
        sessions: sessions,
        onSelect: (session) {
          w.Navigator.of(ctx).pop(session);
          onSelect?.call(session);
        },
        onDelete: onDelete,
      ),
    );
  }

  SessionListDialog({
    required this.sessions,
    this.onSelect,
    this.onDelete,
    this.onDismiss,
    super.key,
  });

  /// The list of sessions to display.
  final List<SessionSummary> sessions;

  /// Called when a session is selected.
  final void Function(SessionSummary session)? onSelect;

  /// Called when a session should be deleted.
  final void Function(SessionSummary session)? onDelete;

  /// Called when esc dismisses the picker (overlay host).
  final void Function()? onDismiss;

  @override
  w.State createState() => _SessionListDialogState();
}

class _SessionListDialogState extends w.State<SessionListDialog> {
  int _selectedIndex = 0;
  String _searchQuery = '';
  late w.TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = w.TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SessionSummary> get _filteredSessions {
    if (_searchQuery.isEmpty) return widget.sessions;
    final q = _searchQuery.toLowerCase();
    return widget.sessions
        .where((s) => s.title.toLowerCase().contains(q))
        .toList();
  }

  @override
  w.Widget build(w.BuildContext context) {
    final theme = w.ThemeScope.of(context);
    final cpTheme = theme.commandPaletteTheme;
    final dialogBg = cpTheme?.background ?? OC.backgroundPanel;
    final dialogFg = cpTheme?.foreground ?? OC.text;
    final selectedBg = cpTheme?.selectedBackground ?? OC.backgroundElement;
    final selectedFg = cpTheme?.selectedForeground ?? OC.text;
    final headerFg = cpTheme?.headerForeground ?? OC.secondary;
    final shortcutFg = cpTheme?.shortcutForeground ?? OC.textMuted;
    final searchBg = cpTheme?.searchBackground ?? OC.backgroundElement;

    final filtered = _filteredSessions;

    if (_selectedIndex >= filtered.length) {
      _selectedIndex = filtered.isEmpty ? 0 : filtered.length - 1;
    }

    // Group sessions by date
    final groups = <String, List<int>>{};
    for (var i = 0; i < filtered.length; i++) {
      final group = filtered[i].dateGroup;
      groups.putIfAbsent(group, () => []).add(i);
    }

    final listItems = <w.Widget>[];
    for (final entry in groups.entries) {
      listItems.add(
        w.Padding(
          padding: const w.EdgeInsets.only(left: 3, right: 3, top: 1),
          child: w.Text(
            entry.key,
            style: style.Style()
              ..foreground(headerFg)
              ..bold(),
          ),
        ),
      );
      for (final idx in entry.value) {
        final session = filtered[idx];
        final isSelected = idx == _selectedIndex;
        final rowFg = isSelected ? selectedFg : dialogFg;
        final rowHintFg = isSelected ? selectedFg : shortcutFg;
        final markerColor = isSelected ? selectedFg : OC.primary;

        listItems.add(
          w.GestureDetector(
            onTap: () {
              widget.onSelect?.call(session);
              return null;
            },
            child: w.Container(
              color: isSelected ? selectedBg : null,
              padding: const w.EdgeInsets.only(left: 3, right: 3),
              child: w.Row(
                children: [
                  if (session.isBusy)
                    w.SpinnerIndicator(
                      frames: _brailleFrames,
                      interval: const Duration(milliseconds: 80),
                      color: markerColor,
                    )
                  else if (session.isCurrent)
                    w.Text(
                      '\u00b7',
                      style: style.Style()..foreground(markerColor),
                    )
                  else
                    w.Text(' ', style: style.Style()..foreground(rowHintFg)),
                  w.SizedBox(width: 1),
                  w.Expanded(
                    child: w.Text(
                      session.title,
                      style: style.Style()..foreground(rowFg),
                      softWrap: false,
                    ),
                  ),
                  w.Text(
                    session.timeAgo,
                    style: style.Style()
                      ..foreground(rowHintFg)
                      ..dim(),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    final searchRow = w.Container(
      padding: const w.EdgeInsets.only(left: 4, right: 4),
      child: w.Container(
        color: searchBg,
        padding: const w.EdgeInsets.only(left: 1, right: 1),
        child: w.Row(
          children: [
            w.Text('\u{1F50D}', style: style.Style()..foreground(shortcutFg)),
            w.SizedBox(width: 1),
            w.Expanded(
              child: w.TextField(
                controller: _searchController,
                focusId: 'session-list-search',
                prompt: '',
                placeholder: 'Search sessions...',
                autofocus: true,
                onChanged: (text) {
                  setState(() {
                    _searchQuery = text;
                    _selectedIndex = 0;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );

    return w.SizedBox(
      width: 64,
      height: 22,
      child: w.Container(
        color: dialogBg,
        child: w.Column(
          crossAxisAlignment: w.CrossAxisAlignment.stretch,
          children: [
            w.Container(
              padding: const w.EdgeInsets.only(left: 4, right: 4, top: 1),
              child: w.Row(
                children: [
                  w.Text(
                    'Sessions',
                    style: style.Style()
                      ..foreground(dialogFg)
                      ..bold(),
                  ),
                  w.Spacer(),
                  w.Text(
                    'esc',
                    style: style.Style()
                      ..foreground(shortcutFg)
                      ..dim(),
                  ),
                ],
              ),
            ),
            w.SizedBox(height: 1),
            searchRow,
            w.SizedBox(height: 1),
            w.Expanded(
              child: w.Container(
                color: dialogBg,
                padding: const w.EdgeInsets.only(left: 1, right: 1),
                child: w.SingleChildScrollView(
                  child: w.Column(
                    crossAxisAlignment: w.CrossAxisAlignment.stretch,
                    children: listItems.isEmpty
                        ? [
                            w.Padding(
                              padding: const w.EdgeInsets.only(
                                left: 3,
                                right: 3,
                              ),
                              child: w.Text(
                                _searchQuery.isEmpty
                                    ? 'No sessions'
                                    : 'No sessions matching "$_searchQuery"',
                                style: style.Style()..foreground(shortcutFg),
                              ),
                            ),
                          ]
                        : listItems,
                  ),
                ),
              ),
            ),
            w.Container(
              padding: const w.EdgeInsets.only(left: 4, right: 4, bottom: 1),
              color: dialogBg,
              child: w.Row(
                children: [
                  _hintKey('\u2191\u2193'),
                  w.SizedBox(width: 1),
                  _hintLabel('navigate'),
                  w.SizedBox(width: 2),
                  _hintKey('\u23ce'),
                  w.SizedBox(width: 1),
                  _hintLabel('select'),
                  w.SizedBox(width: 2),
                  _hintKey('del'),
                  w.SizedBox(width: 1),
                  _hintLabel('delete'),
                  w.Spacer(),
                  w.Text(
                    '${filtered.length} session${filtered.length == 1 ? '' : 's'}',
                    style: style.Style()
                      ..foreground(shortcutFg)
                      ..dim(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  w.Widget _hintKey(String text) {
    return w.Text(
      text,
      style: style.Style()
        ..foreground(OC.textMuted)
        ..dim(),
    );
  }

  w.Widget _hintLabel(String text) {
    return w.Text(
      text,
      style: style.Style()
        ..foreground(OC.textMuted)
        ..dim(),
    );
  }

  @override
  tui.Cmd? handleIntercept(tui.Msg msg) {
    if (msg is! tui.KeyMsg) return null;
    final key = msg.key;
    final filtered = _filteredSessions;

    if (key.isEscape) {
      widget.onDismiss?.call();
      return tui.Cmd.none();
    }

    if (key.type == tui.KeyType.enter && filtered.isNotEmpty) {
      widget.onSelect?.call(filtered[_selectedIndex]);
      return tui.Cmd.none();
    }

    if (key.type == tui.KeyType.up && filtered.isNotEmpty) {
      setState(() {
        _selectedIndex =
            (_selectedIndex - 1 + filtered.length) % filtered.length;
      });
      return tui.Cmd.none();
    }

    if (key.type == tui.KeyType.down && filtered.isNotEmpty) {
      setState(() {
        _selectedIndex = (_selectedIndex + 1) % filtered.length;
      });
      return tui.Cmd.none();
    }

    if (key.type == tui.KeyType.delete && filtered.isNotEmpty) {
      widget.onDelete?.call(filtered[_selectedIndex]);
      return tui.Cmd.none();
    }

    return null;
  }
}
