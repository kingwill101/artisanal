//
// Run with: dart run example/text-field/main.dart

import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

void main() async {
  final app = tui.WidgetApp(TextFieldDemo());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouseMode: tui.MouseMode.allMotion,
      useUltravioletRenderer: true,
    ),
  );
}

class TextFieldDemo extends w.StatefulWidget {
  TextFieldDemo({super.key});

  @override
  w.State createState() => _TextFieldDemoState();
}

class _TextFieldDemoState extends w.State<TextFieldDemo> {
  final w.FocusController _focus = w.FocusController();
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();
  final w.TextFieldController _nameController = w.TextFieldController();
  final w.TextFieldController _roleController = w.TextFieldController();
  String _name = '';
  String _role = '';

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    return w.FocusScope(
      key: const w.Key('text-field-demo-scope'),
      controller: _focus,
      child: w.Container(
        padding: const w.EdgeInsets.all(1),
        color: theme.background,
        child: w.Container(
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
                  w.Text('TextField Demo', style: theme.titleLarge),
                  w.Text(
                    'Click a field and type. Press q to quit.',
                    style: theme.labelSmall,
                  ),
                  w.Container(
                    padding: const w.EdgeInsets.all(1),
                    color: theme.surface,
                    child: w.Column(
                      gap: 1,
                      children: [
                        w.TextField(
                          key: const w.Key('name-field'),
                          focusController: _focus,
                          focusId: 'name',
                          controller: _nameController,
                          prompt: 'Name: ',
                          placeholder: 'Ada Lovelace',
                          width: 24,
                          autofocus: true,
                          onChanged: (value) => setState(() {
                            _name = value;
                          }),
                        ),
                        w.TextField(
                          key: const w.Key('role-field'),
                          focusController: _focus,
                          focusId: 'role',
                          controller: _roleController,
                          prompt: 'Role: ',
                          placeholder: 'Compiler pioneer',
                          width: 24,
                          onChanged: (value) => setState(() {
                            _role = value;
                          }),
                        ),
                      ],
                    ),
                  ),
                  w.Text('Preview:', style: theme.labelMedium),
                  w.Text('$_name — $_role', style: theme.bodyMedium),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg case tui.KeyMsg(:final key)) {
      if (key.char == 'q') return tui.Cmd.quit();
    }
    return null;
  }
}
