import 'package:artisanal/style.dart' as style;
import 'package:artisanal/testing.dart';
import 'package:artisanal/widgets.dart' as w;
import 'package:test/test.dart';

void main() {
  test('Frame left border remains visible with TextField child', () async {
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
          padding: const w.EdgeInsets.only(
            left: 2,
            right: 2,
            top: 1,
            bottom: 1,
          ),
          child: w.TextField(
            focusId: 'prompt',
            prompt: ' ',
            placeholder: 'Ask anything...',
            multiline: true,
            autofocus: true,
          ),
        ),
      ),
      width: 80,
      height: 12,
    );

    expect(tester.find.text('│'), isTrue, reason: tester.view);
  });
}
