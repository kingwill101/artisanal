// Form Inputs Showcase
//
// Demonstrates Checkbox, Radio, Switch, and Select widgets
// with interactive state management, plus a scrollable log
// using SingleChildScrollView + Scrollbar.
//
// Run with: dart run example/inputs/main.dart

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

void main() async {
  final app = tui.WidgetApp(InputShowcase());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouse: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class InputShowcase extends w.StatefulWidget {
  InputShowcase({super.key});

  @override
  w.State createState() => _InputShowcaseState();
}

class _InputShowcaseState extends w.State<InputShowcase> {
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();
  bool _check1 = true;
  bool _check2 = false;
  bool _switchVal = false;
  int _radioVal = 1;
  String _selectVal = 'Alpha';
  final _logController = w.WidgetScrollController();
  final List<String> _log = [];

  static const _selectOptions = [
    w.SelectOption(label: 'Alpha', value: 'Alpha'),
    w.SelectOption(label: 'Beta', value: 'Beta'),
    w.SelectOption(label: 'Gamma', value: 'Gamma'),
    w.SelectOption(label: 'Delta', value: 'Delta'),
  ];

  void _addLog(String entry) {
    _log.add('[${_log.length + 1}] $entry');
  }

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);

    return w.Container(
      padding: const w.EdgeInsets.all(1),
      color: theme.background,
      child: w.Scrollbar(
        controller: _scrollController,
        thickness: 1,
        gap: 1,
        enableHover: true,
        trackChar: ' ',
        thumbChar: ' ',
        trackUsesBackground: true,
        thumbUsesBackground: true,
        trackGradient: w.ScrollbarGradient.background(
          start: w.hasDarkBackground
              ? const BasicColor('#2f363d')
              : const BasicColor('#e3e7eb'),
          end: w.hasDarkBackground
              ? const BasicColor('#1f252a')
              : const BasicColor('#d3d9e0'),
        ),
        thumbGradient: w.ScrollbarGradient.background(
          start: w.hasDarkBackground
              ? const BasicColor('#3fb2ff')
              : const BasicColor('#2f7df6'),
          end: w.hasDarkBackground
              ? const BasicColor('#7c5cff')
              : const BasicColor('#6e55f5'),
        ),
        hoverThumbGradient: w.ScrollbarGradient.background(
          start: w.hasDarkBackground
              ? const BasicColor('#79ddff')
              : const BasicColor('#4f93ff'),
          end: w.hasDarkBackground
              ? const BasicColor('#b18bff')
              : const BasicColor('#836bff'),
        ),
        hoverThumbChar: ' ',
        child: w.ScrollView(
          controller: _scrollController,
          handleKeys: true,
          child: w.Column(
            gap: 1,
            children: [
              w.Text('Form Inputs Showcase', style: theme.titleLarge),
              w.Text('Click to toggle. q to quit.', style: label),
              w.Divider(width: 50),

              // -- Checkbox --
              w.Text('Checkbox', style: theme.titleMedium),
              w.Checkbox(
                value: _check1,
                label: w.Text('Email notifications'),
                onChanged: (val) {
                  setState(() {
                    _check1 = val;
                    _addLog('Email notifications: $val');
                  });
                  return null;
                },
              ),
              w.Checkbox(
                value: _check2,
                label: w.Text('Marketing updates'),
                onChanged: (val) {
                  setState(() {
                    _check2 = val;
                    _addLog('Marketing updates: $val');
                  });
                  return null;
                },
              ),
              w.Checkbox(
                value: true,
                label: w.Text('Disabled (checked)'),
                enabled: false,
              ),
              w.Divider(width: 50),

              // -- Switch --
              w.Text('Switch', style: theme.titleMedium),
              w.Switch(
                value: _switchVal,
                label: w.Text('Dark mode'),
                onChanged: (val) {
                  setState(() {
                    _switchVal = val;
                    _addLog('Dark mode: $val');
                  });
                  return null;
                },
              ),
              w.Switch(
                value: true,
                label: w.Text('Disabled switch'),
                enabled: false,
              ),
              w.Divider(width: 50),

              // -- Radio --
              w.Text('Radio', style: theme.titleMedium),
              w.Radio<int>(
                value: 1,
                groupValue: _radioVal,
                label: w.Text('Option A'),
                onChanged: (val) {
                  setState(() {
                    _radioVal = val;
                    _addLog('Radio: Option A');
                  });
                  return null;
                },
              ),
              w.Radio<int>(
                value: 2,
                groupValue: _radioVal,
                label: w.Text('Option B'),
                onChanged: (val) {
                  setState(() {
                    _radioVal = val;
                    _addLog('Radio: Option B');
                  });
                  return null;
                },
              ),
              w.Radio<int>(
                value: 3,
                groupValue: _radioVal,
                label: w.Text('Option C'),
                onChanged: (val) {
                  setState(() {
                    _radioVal = val;
                    _addLog('Radio: Option C');
                  });
                  return null;
                },
              ),
              w.Radio<int>(
                value: 4,
                groupValue: _radioVal,
                label: w.Text('Disabled'),
                enabled: false,
              ),
              w.Divider(width: 50),

              // -- Select --
              w.Text('Select', style: theme.titleMedium),
              w.Select<String>(
                options: _selectOptions,
                value: _selectVal,
                placeholder: 'Choose...',
                onChanged: (val) {
                  setState(() {
                    _selectVal = val;
                    _addLog('Select: $val');
                  });
                  return null;
                },
              ),
              w.Text('Selected: $_selectVal', style: label),
              w.Divider(width: 50),

              // -- Scrollable event log (SingleChildScrollView + Scrollbar) --
              w.Text('Event Log', style: theme.titleMedium),
              w.Text(
                'Interact with controls above. ↑/↓ to scroll log.',
                style: label,
              ),
              w.Container(
                width: 50,
                height: 8,
                color: theme.surface,
                child: w.Scrollbar(
                  controller: _logController,
                  enableHover: true,
                  thumbChar: '█',
                  trackChar: '│',
                  child: w.SingleChildScrollView(
                    controller: _logController,
                    handleKeys: true,
                    child: w.Column(
                      gap: 0,
                      children: _log.isEmpty
                          ? [w.Text('(no events yet)', style: label)]
                          : [
                              for (final entry in _log)
                                w.Text(entry, style: theme.bodySmall),
                            ],
                    ),
                  ),
                ),
              ),

              // -- Summary --
              w.Text(
                'State: check1=$_check1 check2=$_check2 '
                'switch=$_switchVal radio=$_radioVal select=$_selectVal',
                style: label,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg && msg.key.char == 'q') {
      return tui.Cmd.quit();
    }
    return null;
  }
}
