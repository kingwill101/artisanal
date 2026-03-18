import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

import '../../example/wizard/main.dart' as example;

void main() {
  test('wizard showcase renders the initial project flow', () async {
    final tester = WidgetTester(screenWidth: 100, screenHeight: 28);
    addTearDown(() => tester.dispose());

    await tester.pumpWidget(example.WizardShowcaseScreen());

    expect(tester.find.text('Create New Project'), isTrue);
    expect(tester.find.text('Project name'), isTrue);
    expect(tester.find.text('Step 1 of 6'), isTrue);
  });
}
