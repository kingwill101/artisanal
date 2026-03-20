import 'package:artisanal/app.dart' as app;
import 'package:artisanal/bubbles.dart' as b;
import 'package:artisanal/editors.dart' as editors;
import 'package:artisanal/runtime.dart' as runtime;
import 'package:artisanal/widgets.dart' as w;

import '../_editor_demo_theme.dart' as demo_theme;

const List<b.TextPatternDiagnosticRule> _demoDiagnosticRules =
    <b.TextPatternDiagnosticRule>[
      b.TextPatternDiagnosticRule(
        pattern: 'FIXME',
        severity: b.TextDiagnosticSeverity.error,
        code: 'FIX001',
        message: 'Resolve FIXME markers before treating this draft as ready.',
        source: 'demo',
        wholeWord: true,
      ),
      b.TextPatternDiagnosticRule(
        pattern: 'TODO',
        severity: b.TextDiagnosticSeverity.warning,
        code: 'TODO001',
        message: 'Address TODO markers before shipping this sample.',
        source: 'demo',
        wholeWord: true,
      ),
      b.TextPatternDiagnosticRule(
        pattern: 'NOTE',
        severity: b.TextDiagnosticSeverity.info,
        code: 'NOTE001',
        message: 'Review NOTE blocks for follow-up context.',
        source: 'demo',
        wholeWord: true,
      ),
    ];

Future<void> main() async {
  await app.runArtisanalApp(
    app.ArtisanalApp(title: 'MarkdownEditor Demo', home: MarkdownEditorDemo()),
  );
}

class MarkdownEditorDemo extends w.StatefulWidget {
  MarkdownEditorDemo({super.key});

  @override
  w.State createState() => _MarkdownEditorDemoState();
}

class _MarkdownEditorDemoState extends w.State<MarkdownEditorDemo> {
  final w.FocusController _focus = w.FocusController();
  final editors.TextAreaController _controller = editors.TextAreaController(
    text: '''
# Shipping Notes

- [x] Added `TextEditor`
- [x] Added `CodeEditor`
- [ ] TODO: Add `MarkdownEditor`

> NOTE: Shared transforms now live in the base editor.

```dart
void main() {
  // FIXME: replace the demo preview with richer release notes
  print('preview markdown');
}
```
''',
  );
  late final editors.TextDiagnosticsBinding _diagnosticsBinding;
  String _themePresetName = 'adaptive';
  String _status = 'Press Ctrl+S to save';

  @override
  void initState() {
    super.initState();
    _diagnosticsBinding = editors.TextDiagnosticsBinding.patternRules(
      controller: _controller,
      rules: _demoDiagnosticRules,
    );
  }

  @override
  void dispose() {
    _diagnosticsBinding.dispose();
    super.dispose();
  }

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
    if (msg is runtime.KeyMsg && !_focus.hasFocus && _isQuitShortcut(msg.key)) {
      return runtime.Cmd.quit();
    }
    return null;
  }

  void _clearFocus() {
    if (_focus.clearFocus()) {
      setState(() {});
    }
  }

  void _cycleThemePreset({required bool forward}) {
    setState(() {
      _themePresetName = demo_theme.nextEditorDemoThemePreset(
        _themePresetName,
        forward: forward,
      );
    });
  }

  @override
  w.Widget build(w.BuildContext context) {
    final theme = demo_theme.resolveEditorDemoTheme(_themePresetName);
    return w.ThemeScope(
      theme: theme,
      child: w.FocusScope(
        controller: _focus,
        child: w.Container(
          padding: const w.EdgeInsets.all(1),
          color: theme.background,
          child: w.Column(
            gap: 1,
            crossAxisAlignment: w.CrossAxisAlignment.start,
            children: [
              w.Text('MarkdownEditor Demo', style: theme.titleLarge),
              w.Text(
                'Markdown-focused editing with a live rendered preview. '
                'Diagnostics stay live as you edit; use F8 or click gutter '
                'markers to jump. Click outside or press Esc to blur, then '
                'Ctrl+C quits.',
                style: theme.labelSmall,
              ),
              w.Text(
                'Theme preset: ${demo_theme.editorDemoThemeLabel(_themePresetName)}',
                style: theme.labelSmall,
              ),
              w.Row(
                gap: 1,
                children: [
                  w.TextButton(
                    child: w.Text('Theme prev'),
                    onPressed: () {
                      _cycleThemePreset(forward: false);
                      return null;
                    },
                  ),
                  w.TextButton(
                    child: w.Text('Theme next'),
                    onPressed: () {
                      _cycleThemePreset(forward: true);
                      return null;
                    },
                  ),
                  w.TextButton(
                    child: w.Text('Blur editor'),
                    onPressed: () {
                      _clearFocus();
                      return null;
                    },
                  ),
                ],
              ),
              editors.MarkdownEditor(
                title: 'CHANGELOG.md',
                controller: _controller,
                focusController: _focus,
                focusId: 'markdown-editor',
                autofocus: true,
                height: 10,
                previewHeight: 10,
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
