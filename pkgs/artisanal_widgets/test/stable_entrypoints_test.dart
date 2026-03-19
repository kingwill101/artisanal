import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/charting.dart' as charts;
import 'package:artisanal_widgets/selection.dart' as selection;
import 'package:artisanal_widgets/testing.dart' as testing;
import 'package:artisanal_widgets/widgets.dart' as widgets;
import 'package:test/test.dart';

class _DemoKeyMap implements tui.KeyMap {
  final help = tui.KeyBinding.withHelp(['?'], '?', 'help');
  final quit = tui.KeyBinding.withHelp(['ctrl+c'], 'ctrl+c', 'quit');

  @override
  List<tui.KeyBinding> shortHelp() => [help, quit];

  @override
  List<List<tui.KeyBinding>> fullHelp() => [
    [help],
    [quit],
  ];
}

void main() {
  test('stable widgets entrypoint exposes the high-level app and component surface', () {
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
    expect(widgets.runArtisanalApp, isA<Function>());
  });

  test('stable charting entrypoint exposes chart widgets and models', () {
    final model = charts.ChartModel(
      type: charts.ChartType.line,
      values: const [1, 2, 3],
      showGrid: true,
    );
    final chart = charts.LineChart(values: const [1, 2, 3], width: 12, height: 4);

    expect(model, isA<charts.ChartModel>());
    expect(chart, isA<charts.LineChart>());
  });

  test('stable selection entrypoint exposes shared selection widgets', () {
    final widget = selection.SelectionArea(
      child: selection.SelectableText('select me'),
    );

    expect(widget, isA<selection.SelectionArea>());
  });

  test('stable testing entrypoint exposes WidgetTester', () {
    final tester = testing.WidgetTester();
    expect(tester, isA<testing.WidgetTester>());
  });
}
