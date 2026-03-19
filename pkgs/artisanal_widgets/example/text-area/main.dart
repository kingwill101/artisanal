import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

Future<void> main() async {
  await w.runArtisanalApp(
    w.ArtisanalApp(title: 'TextArea Demo', home: TextAreaDemoScreen()),
  );
}

class TextAreaDemoScreen extends w.StatefulWidget {
  TextAreaDemoScreen({super.key});

  @override
  w.State createState() => _TextAreaDemoScreenState();
}

class _TextAreaDemoScreenState extends w.State<TextAreaDemoScreen> {
  final w.FocusController _focus = w.FocusController();
  final w.TextAreaController _controller = w.TextAreaController(
    text: 'Line one\nLine two',
  );

  @override
  tui.Cmd? handleIntercept(tui.Msg msg) {
    if (msg is tui.InterruptMsg) {
      return tui.Cmd.quit();
    }
    if (msg is tui.KeyMsg &&
        msg.key.type == tui.KeyType.escape &&
        _focus.hasFocus) {
      _clearFocus();
      return tui.Cmd.none();
    }
    if (msg is tui.KeyMsg && !_focus.hasFocus && _isQuitShortcut(msg.key)) {
      return tui.Cmd.quit();
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
          crossAxisAlignment: w.CrossAxisAlignment.start,
          gap: 1,
          children: [
            w.Text('TextArea Demo', style: theme.titleLarge),
            w.Text(
              'Multi-line editing with line numbers. Click outside to blur. '
              'Press Esc to blur. Press Ctrl+C to quit.',
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
            w.Container(
              height: 10,
              color: theme.surface,
              padding: const w.EdgeInsets.all(1),
              child: w.TextArea(
                controller: _controller,
                focusController: _focus,
                focusId: 'editor',
                autofocus: true,
                height: 8,
                placeholder: 'Write notes here...',
                onChanged: (_) => setState(() {}),
              ),
            ),
            w.Text('Preview', style: theme.labelMedium),
            w.Container(
              color: theme.resolvedSurfaceVariant,
              padding: const w.EdgeInsets.all(1),
              child: w.Text(_controller.text, softWrap: true),
            ),
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

bool _isQuitShortcut(tui.Key key) {
  if (!key.ctrl || key.alt || key.meta) return false;
  if (key.type != tui.KeyType.runes || key.runes.isEmpty) return false;
  final rune = key.runes.first;
  return rune == 0x03 || String.fromCharCode(rune).toLowerCase() == 'c';
}
