//
import 'package:artisanal/widgets.dart' as w;
import 'package:artisanal/widgets.dart' as tui hide Key, TextSelection;
// Run with: dart run example/tui/examples/widgets/text-field/main.dart

import 'package:artisanal/tui.dart' as tui;

void main() async {
  final app = tui.WidgetApp(TextFieldDemo());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouseMode: tui.MouseMode.cellMotion,
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
