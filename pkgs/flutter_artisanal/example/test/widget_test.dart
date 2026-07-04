import 'package:flutter_test/flutter_test.dart';

import 'package:example/main.dart';
import 'package:flutter_artisanal/flutter_artisanal.dart' as uv;

void main() {
  late uv.TuiController<CounterModel> controller;

  setUp(() {
    controller = uv.TuiController<CounterModel>(
      model: const CounterModel(),
      options: const uv.ProgramOptions(altScreen: true, hotReload: false),
    );
  });

  testWidgets('TUI counter example builds', (WidgetTester tester) async {
    await controller.start();
    final widget = TuiExample(controller: controller);
    await tester.pumpWidget(widget);

    expect(find.byType(TuiExample), findsOneWidget);

    await controller.dispose();
    if (controller.done != null) {
      await controller.done;
    }
    await tester.pumpAndSettle();
  });
}
