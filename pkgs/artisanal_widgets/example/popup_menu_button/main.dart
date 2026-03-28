// PopupMenuButton Showcase
//
// Demonstrates PopupMenuButton, PopupMenuItem, CheckedPopupMenuItem,
// and PopupMenuDivider.
//
// Run with: dart run example/popup_menu_button/main.dart
//
// Record a trace:
// ARTISANAL_TUI_TRACE=1 dart run pkgs/artisanal_widgets/example/popup_menu_button/main.dart

import 'dart:io';

import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    return;
  }

  if (tui.TuiTrace.enabled) {
    stdout.writeln(
      'TUI trace enabled. '
      'Logs will be written to ${_traceOutputHint()}.',
    );
    _traceEvent(
      'demo.start',
      fields: <String, Object?>{
        'trace_output': _traceOutputHint(),
      },
    );
  }

  final app = tui.WidgetApp(
    PopupMenuButtonShowcase(),
    enableRenderMetrics: false,
    enableRenderMetricsInjection: false,
  );
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouse: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

void _traceEvent(
  String type, {
  tui.TraceTag tag = tui.TraceTag.general,
  Map<String, Object?> fields = const <String, Object?>{},
}) {
  if (!tui.TuiTrace.enabled) return;
  tui.TuiTrace.log(
    'POPUP_MENU_DEMO $type ${fields.isEmpty ? '' : fields}',
    tag: tag,
  );
  tui.TuiTrace.event(
    'popup_menu_demo.$type',
    tag: tag,
    fields: fields,
  );
}

String _traceOutputHint() {
  final env = Platform.environment;
  final explicit = env['ARTISANAL_TUI_TRACE_PATH'];
  if (explicit != null && explicit.isNotEmpty) return explicit;
  return './traces/artisanal-<timestamp>.log';
}

const String _usage = '''
PopupMenuButton showcase

Run:
  dart run pkgs/artisanal_widgets/example/popup_menu_button/main.dart

Trace:
  ARTISANAL_TUI_TRACE=1 dart run pkgs/artisanal_widgets/example/popup_menu_button/main.dart
  ARTISANAL_TUI_TRACE=1 ARTISANAL_TUI_TRACE_TAGS=input,dispatch,render,general dart run pkgs/artisanal_widgets/example/popup_menu_button/main.dart
  ARTISANAL_TUI_TRACE_PATH=/tmp/popup-menu.log ARTISANAL_TUI_TRACE=1 dart run pkgs/artisanal_widgets/example/popup_menu_button/main.dart
''';

class PopupMenuButtonShowcase extends w.StatelessWidget {
  PopupMenuButtonShowcase({super.key});

  @override
  w.Widget build(w.BuildContext context) {
    return w.Overlay(
      initialEntries: [w.OverlayEntry(builder: (_) => _PopupMenuButtonHost())],
    );
  }
}

class _PopupMenuButtonHost extends w.StatefulWidget {
  _PopupMenuButtonHost();

  @override
  w.State createState() => _PopupMenuButtonHostState();
}

class _PopupMenuButtonHostState extends w.State<_PopupMenuButtonHost> {
  String _selectedAction = 'none';
  String _status = 'menu closed';
  bool _showHidden = false;

  @override
  w.Widget build(w.BuildContext context) {
    return _buildContent();
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
            'Open menu with click/enter. Hover highlights items. Use up/down + enter. q to quit.',
            style: labelStyle,
          ),
          w.Text(
            tui.TuiTrace.enabled
                ? 'Trace: enabled -> ${_traceOutputHint()}'
                : 'Trace: disabled',
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
              final nextShowHidden = value == 'toggle_hidden'
                  ? !_showHidden
                  : _showHidden;
              setState(() {
                _selectedAction = value;
                if (value == 'toggle_hidden') {
                  _showHidden = nextShowHidden;
                  _status = 'show hidden: $_showHidden';
                } else {
                  _status = 'selected: $value';
                }
              });
              _traceEvent(
                'menu.selected',
                fields: <String, Object?>{
                  'value': value,
                  'show_hidden': nextShowHidden,
                  'status': _status,
                },
              );
              return null;
            },
            onCanceled: () {
              setState(() => _status = 'menu canceled');
              _traceEvent(
                'menu.canceled',
                fields: <String, Object?>{
                  'selected_action': _selectedAction,
                  'show_hidden': _showHidden,
                },
              );
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
    if (msg is tui.KeyMsg && msg.key.char == 'q') {
      _traceEvent(
        'quit.requested',
        tag: tui.TraceTag.input,
        fields: <String, Object?>{
          'selected_action': _selectedAction,
          'show_hidden': _showHidden,
        },
      );
      return tui.Cmd.quit();
    }
    return null;
  }
}
