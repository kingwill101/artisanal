import 'package:artisanal_widgets/app.dart' as app;
import 'package:artisanal_widgets/charting.dart' as charts;
import 'package:artisanal_widgets/editors.dart' as editors;
import 'package:artisanal_widgets/selection.dart' as selection;
import 'package:artisanal_widgets/testing.dart' as testing;
import 'package:artisanal_widgets/widgets.dart' as widgets;
import 'package:test/test.dart';

class _DemoKeyMap implements widgets.KeyMap {
  final help = widgets.KeyBinding.withHelp(['?'], '?', 'help');
  final quit = widgets.KeyBinding.withHelp(['ctrl+c'], 'ctrl+c', 'quit');

  @override
  List<widgets.KeyBinding> shortHelp() => [help, quit];

  @override
  List<List<widgets.KeyBinding>> fullHelp() => [
    [help],
    [quit],
  ];
}

void main() {
  test('stable app entrypoint exposes app shells and runners', () {
    final shell = app.ArtisanalApp(title: 'Demo', home: widgets.Text('hello'));

    expect(shell, isA<app.ArtisanalApp>());
    expect(app.runArtisanalApp, isA<Function>());
    expect(app.runWidgetApp, isA<Function>());
    expect(app.runReloadableArtisanalApp, isA<Function>());
  });

  test(
    'stable widgets entrypoint exposes the high-level app and component surface',
    () {
      final widget = widgets.Text('hello');
      final app = widgets.ArtisanalApp(title: 'Demo', home: widget);
      final help = widgets.HelpView(keyMap: _DemoKeyMap());
      final picker = widgets.FilePicker(directory: '.');
      final editor = widgets.TextEditor(
        controller: widgets.TextAreaController(text: 'hello'),
      );
      final codeEditor = widgets.CodeEditor(
        controller: widgets.TextAreaController(text: 'void main() {}'),
      );

      expect(app, isA<widgets.ArtisanalApp>());
      expect(help, isA<widgets.HelpView>());
      expect(picker, isA<widgets.FilePicker>());
      expect(editor, isA<widgets.TextEditor>());
      expect(codeEditor, isA<widgets.CodeEditor>());
      expect(widget, isA<widgets.Widget>());
      expect(widgets.ZoneInBoundsMsg, isA<Type>());
      expect(widgets.runArtisanalApp, isA<Function>());
    },
  );

  test('stable editors entrypoint exposes text input and editor widgets', () {
    final textFieldKeyMap = editors.TextInputKeyMap();
    final textAreaKeyMap = editors.TextAreaKeyMap();
    final baseController = editors.TextAreaController(text: 'TODO');
    final diagnosticsBinding = editors.TextDiagnosticsBinding.patternRules(
      controller: baseController,
      rules: const [
        editors.TextPatternDiagnosticRule(
          pattern: 'TODO',
          severity: editors.TextDiagnosticSeverity.warning,
        ),
      ],
    );
    final diagnosticsSource =
        editors.TextPositionDiagnosticsSource.patternRules(
          text: baseController,
          rules: const [
            editors.TextPatternDiagnosticRule(
              pattern: 'TODO',
              severity: editors.TextDiagnosticSeverity.warning,
            ),
          ],
        );
    final rangeDiagnosticsSource =
        widgets.ValueNotifier<Iterable<editors.TextDiagnosticRange>>(const []);
    final positionDiagnosticsSource =
        widgets.ValueNotifier<Iterable<editors.TextPositionDiagnosticRange>>(
          const [],
        );
    final rangeDiagnosticsBinding =
        editors.TextDiagnosticsBinding.fromRangeListenable(
          controller: baseController,
          diagnostics: rangeDiagnosticsSource,
        );
    final positionDiagnosticsBinding =
        editors.TextDiagnosticsBinding.fromPositionListenable(
          controller: baseController,
          diagnostics: positionDiagnosticsSource,
        );
    final decorationBinding = editors.TextDecorationLayerBinding(
      controller: baseController,
      layerKey: 'search',
      buildDecorations: (String text) => text.isEmpty
          ? const []
          : const [
              editors.TextDecorationRange(
                startOffset: 0,
                endOffset: 1,
                styleKey: 'match',
              ),
            ],
    );
    final lineDecorationBinding = editors.TextLineDecorationLayerBinding(
      controller: baseController,
      layerKey: 'review',
      buildDecorations: (String text) => text.isEmpty
          ? const []
          : const [
              editors.TextLineDecoration(lineIndex: 0, styleKey: 'review.line'),
            ],
    );
    final textField = editors.TextField(
      controller: editors.TextEditingController(text: 'hello'),
      keyMap: textFieldKeyMap,
    );
    final textArea = editors.TextArea(
      controller: editors.TextAreaController(text: 'hello\nworld'),
      keyMap: textAreaKeyMap,
    );
    final selectableTextField = editors.SelectableTextFieldView(
      controller: editors.TextEditingController(text: 'hello'),
    );
    final selectableTextArea = editors.SelectableTextAreaView(
      controller: editors.TextAreaController(text: 'hello\nworld'),
    );
    final textEditor = editors.TextEditor(
      controller: editors.TextAreaController(text: 'hello'),
      keyMap: textAreaKeyMap,
    );
    final codeEditor = editors.CodeEditor(
      controller: editors.TextAreaController(text: 'void main() {}'),
      keyMap: textAreaKeyMap,
    );
    final markdownEditor = editors.MarkdownEditor(
      controller: editors.TextAreaController(text: '# Hello'),
      keyMap: textAreaKeyMap,
    );

    expect(textFieldKeyMap, isA<editors.TextInputKeyMap>());
    expect(textAreaKeyMap, isA<editors.TextAreaKeyMap>());
    expect(textField, isA<editors.TextField>());
    expect(textArea, isA<editors.TextArea>());
    expect(selectableTextField, isA<editors.SelectableTextFieldView>());
    expect(selectableTextArea, isA<editors.SelectableTextAreaView>());
    expect(textEditor, isA<editors.TextEditor>());
    expect(codeEditor, isA<editors.CodeEditor>());
    expect(markdownEditor, isA<editors.MarkdownEditor>());
    expect(diagnosticsBinding, isA<editors.TextDiagnosticsBinding>());
    expect(diagnosticsSource, isA<editors.TextPositionDiagnosticsSource>());
    expect(rangeDiagnosticsBinding, isA<editors.TextDiagnosticsBinding>());
    expect(positionDiagnosticsBinding, isA<editors.TextDiagnosticsBinding>());
    expect(decorationBinding, isA<editors.TextDecorationLayerBinding>());
    expect(
      lineDecorationBinding,
      isA<editors.TextLineDecorationLayerBinding>(),
    );

    diagnosticsBinding.dispose();
    diagnosticsSource.dispose();
    rangeDiagnosticsBinding.dispose();
    positionDiagnosticsBinding.dispose();
    decorationBinding.dispose();
    lineDecorationBinding.dispose();
  });

  test('stable charting entrypoint exposes chart widgets and models', () {
    final model = charts.ChartModel(
      type: charts.ChartType.line,
      values: const [1, 2, 3],
      showGrid: true,
    );
    final chart = charts.LineChart(
      values: const [1, 2, 3],
      width: 12,
      height: 4,
    );

    expect(model, isA<charts.ChartModel>());
    expect(chart, isA<charts.LineChart>());
  });

  test('stable selection entrypoint exposes shared selection widgets', () {
    final widget = selection.SelectionArea(
      child: selection.SelectableText('select me'),
    );
    final rich = selection.SelectableRichText(
      text: const widgets.TextSpan(text: 'rich'),
    );
    final view = selection.SelectableView('generic');

    expect(widget, isA<selection.SelectionArea>());
    expect(rich, isA<selection.SelectableRichText>());
    expect(view, isA<selection.SelectableView>());
  });

  test('stable testing entrypoint exposes WidgetTester', () {
    final tester = testing.WidgetTester();
    expect(tester, isA<testing.WidgetTester>());
  });
}
