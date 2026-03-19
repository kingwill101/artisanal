// PopupMenuButton Showcase
//
// Demonstrates PopupMenuButton, PopupMenuItem, CheckedPopupMenuItem,
// and PopupMenuDivider.
//
// Run with: dart run example/popup_menu_button/main.dart

import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

void main() async {
  final app = tui.WidgetApp(PopupMenuButtonShowcase());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouse: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class PopupMenuButtonShowcase extends w.StatefulWidget {
  PopupMenuButtonShowcase({super.key});

  @override
  w.State createState() => _PopupMenuButtonShowcaseState();
}

class _PopupMenuButtonShowcaseState extends w.State<PopupMenuButtonShowcase> {
  String _selectedAction = 'none';
  String _status = 'menu closed';
  bool _showHidden = false;

  @override
  w.Widget build(w.BuildContext context) {
    return w.Overlay(
      initialEntries: [w.OverlayEntry(builder: (_) => _buildContent())],
    );
  }

  w.Widget _buildContent() {
    final theme = widget.theme;
    final labelStyle = theme.labelSmall.copy()..foreground(theme.onBackground);

    return w.Container(
      padding: w.EdgeInsets.all(1),
      color: theme.background,
      child: w.Column(
        crossAxisAlignment: w.CrossAxisAlignment.start,
        gap: 1,
        children: [
          w.Text('PopupMenuButton', style: theme.titleLarge),
          w.Text(
            'Open menu with click/enter. Use up/down + enter. q to quit.',
            style: labelStyle,
          ),
          w.Divider(width: 68),
          w.PopupMenuButton<String>(
            initialValue: _selectedAction == 'none' ? null : _selectedAction,
            child: w.Text('Action: ${_selectedLabel()}'),
            items: [
              w.PopupMenuItem(value: 'open', child: w.Text('Open')),
              w.PopupMenuItem(value: 'save', child: w.Text('Save')),
              w.PopupMenuDivider(),
              w.CheckedPopupMenuItem(
                value: 'toggle_hidden',
                checked: _showHidden,
                child: w.Text('Show Hidden Files'),
              ),
              w.PopupMenuItem(
                value: 'delete',
                enabled: false,
                child: w.Text('Delete (disabled)'),
              ),
            ],
            onSelected: (value) {
              setState(() {
                _selectedAction = value;
                if (value == 'toggle_hidden') {
                  _showHidden = !_showHidden;
                  _status = 'show hidden: $_showHidden';
                } else {
                  _status = 'selected: $value';
                }
              });
              return null;
            },
            onCanceled: () {
              setState(() => _status = 'menu canceled');
              return null;
            },
          ),
          w.Text('Last action: $_selectedAction', style: labelStyle),
          w.Text('Status: $_status', style: labelStyle),
        ],
      ),
    );
  }

  String _selectedLabel() {
    if (_selectedAction == 'none') return 'none';
    if (_selectedAction == 'toggle_hidden') {
      return _showHidden ? 'hidden:on' : 'hidden:off';
    }
    return _selectedAction;
  }

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg && msg.key.char == 'q') return tui.Cmd.quit();
    return null;
  }
}
