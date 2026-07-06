import 'package:artisanal/style.dart' as style;
import 'package:artisanal/artisanal.dart';
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:test/test.dart';

void main() {
  test('Frame renders left-only border with Style', () async {
    final tester = WidgetTester();
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(
      w.Frame(
        style: style.Style()
          ..border(
            style.Border.normal,
            top: false,
            right: false,
            bottom: false,
            left: true,
          )
          ..borderLeftForeground(const style.BasicColor('#8250df')),
        child: w.Container(
          color: const style.BasicColor('#f0f3f6'),
          padding: const w.EdgeInsets.only(left: 1, right: 1),
          child: w.Text('x'),
        ),
      ),
      width: 20,
      height: 5,
    );

    expect(tester.find.text('│'), isTrue, reason: tester.view);
  });
}
