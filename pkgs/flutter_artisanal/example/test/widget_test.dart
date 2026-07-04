import 'package:flutter_test/flutter_test.dart';

import 'package:example/tui_example.dart';
import 'package:flutter_artisanal/flutter_artisanal.dart' as uv;

void main() {
  testWidgets('TUI counter example builds', (WidgetTester tester) async {
    final controller = uv.TuiController<CounterModel>(
      model: const CounterModel(),
      options: const uv.ProgramOptions(altScreen: true, hotReload: false),
    );

    await tester.pumpWidget(TuiExample(controller: controller));

    expect(find.byType(TuiExample), findsOneWidget);

    await controller.dispose();
  });
}
