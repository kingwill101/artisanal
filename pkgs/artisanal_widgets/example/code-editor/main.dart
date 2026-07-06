import 'package:artisanal_widgets/app.dart' as app;
import 'package:artisanal/bubbles.dart' as b;
import 'package:artisanal_widgets/editors.dart' as editors;
import 'package:artisanal/tui.dart' as runtime;
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
        pattern: 'hint',
        severity: b.TextDiagnosticSeverity.hint,
        code: 'HINT001',
        message: 'Hints mark optional polish work in the sample text.',
        source: 'demo',
        wholeWord: true,
      ),
    ];

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
  // TODO: replace the demo print with real bootstrap work
  final widgets = <String>['TextEditor', 'CodeEditor'];
  for (final widget in widgets) {
    print('Ship \$widget'); // hint: keep diagnostics visible in the demo
  }
}
''',
  );
  late final editors.TextPositionDiagnosticsSource _diagnosticsSource;
  late final editors.TextDiagnosticsBinding _diagnosticsBinding;
  String _themePresetName = 'adaptive';
  String _status = 'Press Ctrl+S to save';

  @override
  void initState() {
    super.initState();
    _diagnosticsSource = editors.TextPositionDiagnosticsSource.patternRules(
      text: _controller,
      rules: _demoDiagnosticRules,
    );
    _diagnosticsBinding = editors.TextDiagnosticsBinding.fromPositionListenable(
      controller: _controller,
      diagnostics: _diagnosticsSource,
    );
  }

  @override
  void dispose() {
    _diagnosticsBinding.dispose();
    _diagnosticsSource.dispose();
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
              w.Text('CodeEditor Demo', style: theme.titleLarge),
              w.Text(
                'Editable source with a live syntax-highlighted preview. '
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
