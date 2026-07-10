import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:artisanal_widgets/editors.dart'
    show TextInputKeyMap, TextAreaKeyMap;
import 'package:test/test.dart';
import 'package:artisanal/tui.dart';

class _DemoKeyMap extends KeyMap {
  _DemoKeyMap() {
    final help = KeyBinding.withHelp(['?'], '?', 'help');
    final quit = KeyBinding.withHelp(['ctrl+c'], 'ctrl+c', 'quit');
    shortHelp = [help, quit];
    fullHelp = [
      [help],
      [quit],
    ];
  }
}

void main() {
  test('stable app entrypoint exposes app shells', () {
    final shell = ArtisanalApp(title: 'Demo', home: Text('hello'));

    expect(shell, isA<ArtisanalApp>());
    expect(ReloadController, isA<Type>());
    expect(ReloadHost, isA<Type>());
    expect(ReloadFileWatcher, isA<Type>());
    expect(ReloadMode, isA<Type>());
    expect(WidgetApp, isA<Type>());
  });

  test(
    'stable widgets entrypoint exposes the high-level app and component surface',
    () {
      final widget = Text('hello');
      final app = ArtisanalApp(title: 'Demo', home: widget);
      final help = HelpView(keyMap: _DemoKeyMap());
      final picker = FilePicker(directory: '.');
      final editor = TextEditor(controller: TextAreaController(text: 'hello'));
      final codeEditor = CodeEditor(
        controller: TextAreaController(text: 'void main() {}'),
      );

      expect(app, isA<ArtisanalApp>());
      expect(help, isA<HelpView>());
      expect(picker, isA<FilePicker>());
      expect(editor, isA<TextEditor>());
      expect(codeEditor, isA<CodeEditor>());
      expect(widget, isA<Widget>());
      expect(ZoneInBoundsMsg, isA<Type>());
    },
  );

  test('stable editors entrypoint exposes text input and editor widgets', () {
    final textFieldKeyMap = TextInputKeyMap();
    final textAreaKeyMap = TextAreaKeyMap();
    final baseController = TextAreaController(text: 'TODO');
    final diagnosticsBinding = TextDiagnosticsBinding.patternRules(
      controller: baseController,
      rules: const [
        TextPatternDiagnosticRule(
          pattern: 'TODO',
          severity: TextDiagnosticSeverity.warning,
        ),
      ],
    );
    final diagnosticsSource = TextPositionDiagnosticsSource.patternRules(
      text: baseController,
      rules: const [
        TextPatternDiagnosticRule(
          pattern: 'TODO',
          severity: TextDiagnosticSeverity.warning,
        ),
      ],
    );
    final rangeDiagnosticsSource = ValueNotifier<Iterable<TextDiagnosticRange>>(
      const [],
    );
    final positionDiagnosticsSource =
        ValueNotifier<Iterable<TextPositionDiagnosticRange>>(const []);
    final rangeDiagnosticsBinding = TextDiagnosticsBinding.fromRangeListenable(
      controller: baseController,
      diagnostics: rangeDiagnosticsSource,
    );
    final positionDiagnosticsBinding =
        TextDiagnosticsBinding.fromPositionListenable(
          controller: baseController,
          diagnostics: positionDiagnosticsSource,
        );
    final decorationBinding = TextDecorationLayerBinding(
      controller: baseController,
      layerKey: 'search',
      buildDecorations: (String text) => text.isEmpty
          ? const []
          : const [
              TextDecorationRange(
                startOffset: 0,
                endOffset: 1,
                styleKey: 'match',
              ),
            ],
    );
    final lineDecorationBinding = TextLineDecorationLayerBinding(
      controller: baseController,
      layerKey: 'review',
      buildDecorations: (String text) => text.isEmpty
          ? const []
          : const [TextLineDecoration(lineIndex: 0, styleKey: 'review.line')],
    );
    final textField = TextField(
      controller: TextEditingController(text: 'hello'),
      keyMap: textFieldKeyMap,
    );
    final textArea = TextArea(
      controller: TextAreaController(text: 'hello\nworld'),
      keyMap: textAreaKeyMap,
    );
    final selectableTextField = SelectableTextFieldView(
      controller: TextEditingController(text: 'hello'),
    );
    final selectableTextArea = SelectableTextAreaView(
      controller: TextAreaController(text: 'hello\nworld'),
    );
    final textEditor = TextEditor(
      controller: TextAreaController(text: 'hello'),
      keyMap: textAreaKeyMap,
    );
    final codeEditor = CodeEditor(
      controller: TextAreaController(text: 'void main() {}'),
      keyMap: textAreaKeyMap,
    );
    final markdownEditor = MarkdownEditor(
      controller: TextAreaController(text: '# Hello'),
      keyMap: textAreaKeyMap,
    );

    expect(textFieldKeyMap, isA<TextInputKeyMap>());
    expect(textAreaKeyMap, isA<TextAreaKeyMap>());
    expect(textField, isA<TextField>());
    expect(textArea, isA<TextArea>());
    expect(selectableTextField, isA<SelectableTextFieldView>());
    expect(selectableTextArea, isA<SelectableTextAreaView>());
    expect(textEditor, isA<TextEditor>());
    expect(codeEditor, isA<CodeEditor>());
    expect(markdownEditor, isA<MarkdownEditor>());
    expect(diagnosticsBinding, isA<TextDiagnosticsBinding>());
    expect(diagnosticsSource, isA<TextPositionDiagnosticsSource>());
    expect(rangeDiagnosticsBinding, isA<TextDiagnosticsBinding>());
    expect(positionDiagnosticsBinding, isA<TextDiagnosticsBinding>());
    expect(decorationBinding, isA<TextDecorationLayerBinding>());
    expect(lineDecorationBinding, isA<TextLineDecorationLayerBinding>());

    diagnosticsBinding.dispose();
    diagnosticsSource.dispose();
    rangeDiagnosticsBinding.dispose();
    positionDiagnosticsBinding.dispose();
    decorationBinding.dispose();
    lineDecorationBinding.dispose();
  });

  test('stable charting entrypoint exposes chart widgets and models', () {
    final model = ChartModel(
      type: ChartType.line,
      values: const [1, 2, 3],
      showGrid: true,
    );
    final chart = LineChart(values: const [1, 2, 3], width: 12, height: 4);

    expect(model, isA<ChartModel>());
    expect(chart, isA<LineChart>());
  });

  test('stable selection entrypoint exposes shared selection widgets', () {
    final widget = SelectionArea(child: SelectableText('select me'));
    final rich = SelectableRichText(text: const TextSpan(text: 'rich'));
    final view = SelectableView('generic');

    expect(widget, isA<SelectionArea>());
    expect(rich, isA<SelectableRichText>());
    expect(view, isA<SelectableView>());
  });

  test('stable testing entrypoint exposes WidgetTester', () {
    final tester = WidgetTester();
    expect(tester, isA<WidgetTester>());
  });
}
