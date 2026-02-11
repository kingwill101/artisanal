import 'package:artisanal/style.dart' as style;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

void main() {
  test('row left stripe remains visible beside expanded pane', () async {
    final tester = WidgetTester();
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(
      w.Row(
        crossAxisAlignment: w.CrossAxisAlignment.stretch,
        children: [
          w.Container(
            color: const style.BasicColor('#f0f3f6'),
            width: 1,
            child: w.Text(
              '│\n│\n│\n│',
              style: style.Style()
                ..foreground(const style.BasicColor('#8250df')),
            ),
          ),
          w.Expanded(
            child: w.Container(
              color: const style.BasicColor('#f0f3f6'),
              child: w.Text('pane'),
            ),
          ),
        ],
      ),
      width: 40,
      height: 8,
    );

    expect(tester.find.text('│'), isTrue, reason: tester.view);
  });
}
