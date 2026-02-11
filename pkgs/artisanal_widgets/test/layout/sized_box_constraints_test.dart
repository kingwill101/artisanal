import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

void main() {
  test('SizedBox width constrains Row with Expanded child', () async {
    final tester = WidgetTester();
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(
      w.SizedBox(
        width: 32,
        child: w.Row(
          children: [
            w.Expanded(child: w.Text('left', softWrap: false)),
            w.Text('right', softWrap: false),
          ],
        ),
      ),
      width: 120,
      height: 20,
    );

    expect(tester.find.text('left'), isTrue);
    expect(tester.find.text('right'), isTrue);
  });
}
