library;

import 'package:artisanal/style.dart' as style;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;

import '../theme.dart';

class ThemeListDialog extends w.StatefulWidget {
  ThemeListDialog({
    required this.child,
    required this.themes,
    required this.currentTheme,
    this.open = false,
    this.onDismiss,
    this.onSelect,
    super.key,
  });

  final w.Widget child;
  final List<String> themes;
  final String currentTheme;
  final bool open;
  final w.CmdCallback? onDismiss;
  final void Function(String themeName)? onSelect;

  @override
  w.State createState() => _ThemeListDialogState();
}

class _ThemeListDialogState extends w.State<ThemeListDialog> {
  int _selectedIndex = 0;
  String _searchQuery = '';
  late w.TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = w.TextEditingController();
  }

  @override
  tui.Cmd? didUpdateWidget(covariant ThemeListDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.open && !oldWidget.open) {
      _searchQuery = '';
      _searchController.clear();
      _selectedIndex = _indexOfTheme(widget.currentTheme);
    }
    return null;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _indexOfTheme(String themeName) {
    final index = _filteredThemes.indexOf(themeName);
    return index < 0 ? 0 : index;
  }

  List<String> get _filteredThemes {
    if (_searchQuery.isEmpty) return widget.themes;
    final q = _searchQuery.toLowerCase();
    return widget.themes
        .where(
          (name) =>
              _labelForTheme(name).toLowerCase().contains(q) ||
              name.contains(q),
        )
        .toList();
  }

  String _labelForTheme(String themeName) {
    if (themeName == openCodeDefaultThemeName) return 'Default (built-in)';
    final words = themeName.split(RegExp('[-_]'));
    return words
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  @override
  w.Widget build(w.BuildContext context) {
    if (!widget.open) return widget.child;

    final filtered = _filteredThemes;
    if (_selectedIndex >= filtered.length) {
      _selectedIndex = filtered.isEmpty ? 0 : filtered.length - 1;
    }

    final rows = <w.Widget>[];
    for (var i = 0; i < filtered.length; i++) {
      final themeName = filtered[i];
      final selected = i == _selectedIndex;
      final active = themeName == widget.currentTheme;

      rows.add(
        w.GestureDetector(
          onTap: () {
            widget.onSelect?.call(themeName);
            return null;
          },
          child: w.Container(
            color: selected ? OC.backgroundElement : null,
            padding: const w.EdgeInsets.only(left: 2, right: 2),
            child: w.Row(
              children: [
                w.Text(
                  active ? '*' : ' ',
                  style: style.Style()
                    ..foreground(active ? OC.primary : OC.textMuted),
                ),
                w.SizedBox(width: 1),
                w.Expanded(
                  child: w.Text(
                    _labelForTheme(themeName),
                    style: style.Style()
                      ..foreground(selected ? OC.text : OC.textMuted),
                    softWrap: false,
                  ),
                ),
                if (themeName != openCodeDefaultThemeName)
                  w.Text(
                    themeName,
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

    final dialog = w.SizedBox(
      width: 64,
      height: 20,
      child: w.Container(
        color: OC.backgroundPanel,
        child: w.Column(
          crossAxisAlignment: w.CrossAxisAlignment.stretch,
          children: [
            w.Container(
              padding: const w.EdgeInsets.only(left: 2, right: 2, top: 1),
              child: w.Row(
                children: [
                  w.Text(
                    'Themes',
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
            w.Container(
              padding: const w.EdgeInsets.only(left: 1, right: 1),
              child: w.Container(color: OC.borderSubtle, height: 1),
            ),
            w.Container(
              padding: const w.EdgeInsets.only(left: 2, right: 2),
              child: w.Row(
                children: [
                  w.Text('/ ', style: style.Style()..foreground(OC.textMuted)),
                  w.Expanded(
                    child: w.TextField(
                      controller: _searchController,
                      focusId: 'theme-list-search',
                      prompt: ' ',
                      placeholder: 'Search themes...',
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
            w.Container(
              padding: const w.EdgeInsets.only(left: 1, right: 1),
              child: w.Container(color: OC.borderSubtle, height: 1),
            ),
            w.Expanded(
              child: w.SingleChildScrollView(
                child: w.Column(
                  crossAxisAlignment: w.CrossAxisAlignment.stretch,
                  children: rows.isEmpty
                      ? [
                          w.Padding(
                            padding: const w.EdgeInsets.all(2),
                            child: w.Center(
                              child: w.Text(
                                'No themes matching "$_searchQuery"',
                                style: style.Style()..foreground(OC.textMuted),
                              ),
                            ),
                          ),
                        ]
                      : rows,
                ),
              ),
            ),
            w.Container(
              padding: const w.EdgeInsets.only(left: 2, right: 2),
              child: w.Row(
                children: [
                  _hintKey('up/down'),
                  w.SizedBox(width: 1),
                  _hintLabel('navigate'),
                  w.SizedBox(width: 2),
                  _hintKey('enter'),
                  w.SizedBox(width: 1),
                  _hintLabel('apply'),
                  w.Spacer(),
                  w.Text(
                    '${filtered.length} theme${filtered.length == 1 ? '' : 's'}',
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
    if (!widget.open) return null;
    if (msg is! tui.KeyMsg) return null;

    final key = msg.key;
    final filtered = _filteredThemes;

    if (key.type == tui.KeyType.escape) {
      widget.onDismiss?.call();
      return tui.Cmd.none();
    }

    if (key.type == tui.KeyType.enter && filtered.isNotEmpty) {
      widget.onSelect?.call(filtered[_selectedIndex]);
      return tui.Cmd.none();
    }
    if (key.type == tui.KeyType.enter) {
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

    if (key.ctrl || key.alt || key.type == tui.KeyType.tab) {
      return tui.Cmd.none();
    }

    return null;
  }
}
