import 'package:artisanal_widgets/testing.dart';
import 'package:flutter_cli_port/flutter_cli_port.dart';
import 'package:test/test.dart';

void main() {
  test('renders dashboard header panels and ready footer', () async {
    await testWidgets('dashboard', (tester) async {
      await tester.pumpWidget(FlutterCliDashboard(), width: 120, height: 24);

      expect(tester.find.text('flutter-cli'), isTrue);
      expect(tester.find.text('Performance'), isTrue);
      expect(tester.find.text('Devices'), isTrue);
      expect(tester.find.text('[r] reload'), isTrue);
      expect(tester.find.text('FPS'), isTrue);
      expect(tester.find.text('Memory'), isTrue);
    });
  });

  test('network key swaps the left panel with the n binding', () async {
    await testWidgets('dashboard', (tester) async {
      await tester.pumpWidget(FlutterCliDashboard(), width: 120, height: 24);

      expect(tester.find.text('Performance'), isTrue);
      tester.sendKey('n');

      expect(tester.find.text('Network'), isTrue);
      expect(tester.find.text('method'), isTrue);
    });
  });

  test('pre-ready footer shows weighted progress bar', () async {
    await testWidgets('dashboard', (tester) async {
      await tester.pumpWidget(
        FlutterCliDashboard(initialState: FlutterCliState.demo(ready: false)),
        width: 100,
        height: 20,
      );

      expect(tester.find.text('%'), isTrue);
      expect(tester.find.text('█'), isTrue);
      expect(tester.find.text('[e] error'), isTrue);
      expect(tester.find.text('[r] reload'), isFalse);
    });
  });

  test('small terminal renders same too-small fallback', () async {
    await testWidgets('dashboard', (tester) async {
      await tester.pumpWidget(FlutterCliDashboard(), width: 30, height: 8);

      expect(tester.find.text('Terminal too small'), isTrue);
      expect(tester.find.text('50x8'), isTrue);
    });
  });
}
