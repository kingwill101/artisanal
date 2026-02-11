/// Session list dialog — searchable list of sessions.
///
/// Matches the real OpenCode session list: Modal overlay with
/// search input, sessions grouped by date, spinner for busy sessions,
/// keyboard navigation (up/down, enter to select, esc to dismiss).
library;

import 'package:artisanal/style.dart' as style;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;

import '../models/chat_model.dart';
import '../theme.dart';

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
  SessionListDialog({
    required this.child,
    required this.sessions,
    this.open = false,
    this.onDismiss,
    this.onSelect,
    this.onDelete,
    super.key,
  });

  /// The background content.
  final w.Widget child;

  /// The list of sessions to display.
  final List<SessionSummary> sessions;

  /// Whether the dialog is open.
  final bool open;

  /// Called when the dialog is dismissed.
  final w.CmdCallback? onDismiss;

  /// Called when a session is selected.
  final void Function(SessionSummary session)? onSelect;

  /// Called when a session should be deleted.
  final void Function(SessionSummary session)? onDelete;

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
  tui.Cmd? didUpdateWidget(covariant SessionListDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset state when dialog opens.
    if (widget.open && !oldWidget.open) {
      _selectedIndex = 0;
      _searchQuery = '';
      _searchController.clear();
    }
    return null;
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
    if (!widget.open) return widget.child;

    final filtered = _filteredSessions;

    // Clamp selection
    if (_selectedIndex >= filtered.length) {
      _selectedIndex = filtered.isEmpty ? 0 : filtered.length - 1;
    }

    // Group sessions by date
    final groups = <String, List<int>>{};
    for (var i = 0; i < filtered.length; i++) {
      final group = filtered[i].dateGroup;
      groups.putIfAbsent(group, () => []).add(i);
    }

    // Build grouped list items
    final listItems = <w.Widget>[];
    for (final entry in groups.entries) {
      // Group header
      listItems.add(
        w.Padding(
          padding: const w.EdgeInsets.only(left: 2, top: 1, bottom: 0),
          child: w.Text(
            entry.key,
            style: style.Style()
              ..foreground(OC.textMuted)
              ..bold(),
          ),
        ),
      );

      // Session items
      for (final idx in entry.value) {
        final session = filtered[idx];
        final isSelected = idx == _selectedIndex;

        listItems.add(
          w.GestureDetector(
            onTap: () {
              widget.onSelect?.call(session);
              return null;
            },
            child: w.Container(
              color: isSelected ? OC.backgroundElement : null,
              padding: const w.EdgeInsets.only(left: 2, right: 2),
              child: w.Row(
                children: [
                  // Busy indicator or bullet
                  if (session.isBusy)
                    w.SpinnerIndicator(
                      frames: _brailleFrames,
                      interval: const Duration(milliseconds: 80),
                      color: OC.primary,
                    )
                  else if (session.isCurrent)
                    w.Text(
                      '\u25cf',
                      style: style.Style()..foreground(OC.primary),
                    )
                  else
                    w.Text(' ', style: style.Style()..foreground(OC.textMuted)),
                  w.SizedBox(width: 1),
                  // Title
                  w.Expanded(
                    child: w.Text(
                      session.title,
                      style: style.Style()
                        ..foreground(isSelected ? OC.text : OC.textMuted),
                      softWrap: false,
                    ),
                  ),
                  // Time ago
                  w.Text(
                    session.timeAgo,
                    style: style.Style()
                      ..foreground(OC.textMuted)
                      ..dim(),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    // Search input with icon
    final searchRow = w.Container(
      padding: const w.EdgeInsets.only(left: 2, right: 2),
      child: w.Row(
        children: [
          w.Text('\u{1F50D} ', style: style.Style()..foreground(OC.textMuted)),
          w.Expanded(
            child: w.TextField(
              controller: _searchController,
              focusId: 'session-list-search',
              prompt: ' ',
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
    );

    // The dialog content
    final dialog = w.SizedBox(
      width: 60,
      height: 20,
      child: w.Container(
        color: OC.backgroundPanel,
        child: w.Column(
          crossAxisAlignment: w.CrossAxisAlignment.stretch,
          children: [
            // Title bar
            w.Container(
              padding: const w.EdgeInsets.only(
                left: 2,
                right: 2,
                top: 1,
                bottom: 0,
              ),
              child: w.Row(
                children: [
                  w.Text(
                    'Sessions',
                    style: style.Style()
                      ..foreground(OC.text)
                      ..bold(),
                  ),
                  w.Spacer(),
                  w.Text(
                    'esc',
                    style: style.Style()
                      ..foreground(OC.textMuted)
                      ..dim(),
                  ),
                ],
              ),
            ),
            // Separator
            w.Container(
              padding: const w.EdgeInsets.only(left: 1, right: 1),
              child: w.Container(color: OC.borderSubtle, height: 1),
            ),
            // Search input
            searchRow,
            // Separator
            w.Container(
              padding: const w.EdgeInsets.only(left: 1, right: 1),
              child: w.Container(color: OC.borderSubtle, height: 1),
            ),
            // Session list
            w.Expanded(
              child: w.SingleChildScrollView(
                child: w.Column(
                  crossAxisAlignment: w.CrossAxisAlignment.stretch,
                  children: listItems.isEmpty
                      ? [
                          w.Padding(
                            padding: const w.EdgeInsets.all(2),
                            child: w.Center(
                              child: w.Text(
                                _searchQuery.isEmpty
                                    ? 'No sessions'
                                    : 'No sessions matching "$_searchQuery"',
                                style: style.Style()..foreground(OC.textMuted),
                              ),
                            ),
                          ),
                        ]
                      : listItems,
                ),
              ),
            ),
            // Footer hint
            w.Container(
              padding: const w.EdgeInsets.only(
                left: 2,
                right: 2,
                top: 0,
                bottom: 0,
              ),
              color: OC.backgroundPanel,
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
                      ..foreground(OC.textMuted)
                      ..dim(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return w.Modal(
      open: true,
      onDismiss: widget.onDismiss,
      child: widget.child,
      dialog: dialog,
    );
  }

  /// Small styled helper for footer hint keys.
  w.Widget _hintKey(String text) {
    return w.Text(
      text,
      style: style.Style()
        ..foreground(OC.textMuted)
        ..dim(),
    );
  }

  /// Small styled helper for footer hint labels.
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
    if (!widget.open) return null;

    if (msg is tui.KeyMsg) {
      final key = msg.key;
      final filtered = _filteredSessions;

      // Escape to dismiss
      if (key.type == tui.KeyType.escape) {
        widget.onDismiss?.call();
        return tui.Cmd.none();
      }

      // Enter to select
      if (key.type == tui.KeyType.enter && filtered.isNotEmpty) {
        widget.onSelect?.call(filtered[_selectedIndex]);
        return tui.Cmd.none();
      }

      // Up navigation
      if (key.type == tui.KeyType.up && filtered.isNotEmpty) {
        setState(() {
          _selectedIndex =
              (_selectedIndex - 1 + filtered.length) % filtered.length;
        });
        return tui.Cmd.none();
      }

      // Down navigation
      if (key.type == tui.KeyType.down && filtered.isNotEmpty) {
        setState(() {
          _selectedIndex = (_selectedIndex + 1) % filtered.length;
        });
        return tui.Cmd.none();
      }

      // Delete key to delete session
      if (key.type == tui.KeyType.delete && filtered.isNotEmpty) {
        widget.onDelete?.call(filtered[_selectedIndex]);
        return tui.Cmd.none();
      }

      // DO NOT consume all keys — let typing flow through to the TextField.
      // The TextField handles its own keyboard input via its handleUpdate.
    }
    return null;
  }
}
