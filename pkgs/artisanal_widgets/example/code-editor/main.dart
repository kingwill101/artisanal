import 'package:artisanal/app.dart' as app;
import 'package:artisanal/editors.dart' as editors;
import 'package:artisanal/runtime.dart' as runtime;
import 'package:artisanal/widgets.dart' as w;

Future<void> main() async {
  await app.runArtisanalApp(
    app.ArtisanalApp(title: 'CodeEditor Demo', home: CodeEditorDemoScreen()),
  );
}

class CodeEditorDemoScreen extends w.StatefulWidget {
  CodeEditorDemoScreen({super.key});

  @override
  w.State createState() => _CodeEditorDemoScreenState();
}

class _CodeEditorDemoScreenState extends w.State<CodeEditorDemoScreen> {
  final w.FocusController _focus = w.FocusController();
  final editors.TextAreaController _controller = editors.TextAreaController(
    text: '''
void main() {
  final widgets = <String>['TextEditor', 'CodeEditor'];
  for (final widget in widgets) {
    print('Ship \$widget');
  }
}
''',
  );
  String _status = 'Press Ctrl+S to save';

  @override
  runtime.Cmd? handleIntercept(runtime.Msg msg) {
    if (msg is runtime.InterruptMsg) {
      return runtime.Cmd.quit();
    }
    if (msg is runtime.KeyMsg &&
        msg.key.type == runtime.KeyType.escape &&
        _focus.hasFocus) {
      _clearFocus();
      return runtime.Cmd.none();
    }
    if (msg is runtime.KeyMsg &&
        !_focus.hasFocus &&
        _isQuitShortcut(msg.key)) {
      return runtime.Cmd.quit();
    }
    return null;
  }

  void _clearFocus() {
    if (_focus.clearFocus()) {
      setState(() {});
    }
  }

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    return w.FocusScope(
      controller: _focus,
      child: w.Container(
        padding: const w.EdgeInsets.all(1),
        color: theme.background,
        child: w.Column(
          gap: 1,
          crossAxisAlignment: w.CrossAxisAlignment.start,
          children: [
            w.Text('CodeEditor Demo', style: theme.titleLarge),
            w.Text(
              'Editable source with a live syntax-highlighted preview. '
              'Click outside or press Esc to blur, then Ctrl+C quits.',
              style: theme.labelSmall,
            ),
            w.Row(
              gap: 1,
              children: [
                w.TextButton(
                  child: w.Text('Blur editor'),
                  onPressed: () {
                    _clearFocus();
                    return null;
                  },
                ),
              ],
            ),
            editors.CodeEditor(
              title: 'main.dart',
              language: 'dart',
              controller: _controller,
              focusController: _focus,
              focusId: 'code-editor',
              autofocus: true,
              height: 8,
              previewHeight: 8,
              onSave: (value) {
                setState(() {
                  _status = 'Saved ${value.runes.length} characters';
                });
                return null;
              },
            ),
            w.Text(_status, style: theme.labelSmall),
            w.Expanded(
              child: w.GestureDetector(
                behavior: w.HitTestBehavior.opaque,
                onTap: () {
                  _clearFocus();
                  return null;
                },
                child: w.Container(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

bool _isQuitShortcut(runtime.Key key) {
  if (!key.ctrl || key.alt || key.meta) return false;
  if (key.type != runtime.KeyType.runes || key.runes.isEmpty) return false;
  final rune = key.runes.first;
  return rune == 0x03 || String.fromCharCode(rune).toLowerCase() == 'c';
}
