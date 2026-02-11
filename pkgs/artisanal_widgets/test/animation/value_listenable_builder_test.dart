import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

void main() {
  testWidgets('ValueListenableBuilder rebuilds when value changes', (
    tester,
  ) async {
    final notifier = ValueNotifier<int>(0);
    int buildCount = 0;

    await tester.pumpWidget(
      ValueListenableBuilder<int>(
        valueListenable: notifier,
        builder: (context, value, child) {
          buildCount++;
          return Text('Value: $value');
        },
      ),
    );

    expect(tester.find.text('Value: 0'), isTrue);
    expect(buildCount, 1);

    notifier.value = 1;
    tester.pump();

    expect(tester.find.text('Value: 1'), isTrue);
    expect(buildCount, 2);
  });

  testWidgets('ValueListenableBuilder uses child parameter', (tester) async {
    final notifier = ValueNotifier<int>(0);
    int buildCount = 0;

    await tester.pumpWidget(
      ValueListenableBuilder<int>(
        valueListenable: notifier,
        child: Text('Static'),
        builder: (context, value, child) {
          buildCount++;
          return Column(children: [Text('Value: $value'), child!]);
        },
      ),
    );

    expect(tester.find.text('Value: 0'), isTrue);
    expect(tester.find.text('Static'), isTrue);
    expect(buildCount, 1);

    notifier.value = 1;
    tester.pump();

    expect(tester.find.text('Value: 1'), isTrue);
    expect(tester.find.text('Static'), isTrue);
    expect(buildCount, 2);
  });
}
