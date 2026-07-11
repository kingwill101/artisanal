/// Testing utilities for TUI widgets.
///
/// Provides [WidgetTester] for mounting widgets, sending input events,
/// and asserting on rendered output — similar to Flutter's widget testing.
///
/// ```dart
/// import 'package:artisanal_widgets/testing.dart';
///
/// void main() {
///   testWidgets('counter increments on tap', (tester) async {
///     await tester.pumpWidget(MyCounterWidget());
///     expect(tester.find.text('count: 0'), isTrue);
///
///     tester.tap(tester.find.textLocation('count: 0'));
///     expect(tester.find.text('count: 1'), isTrue);
///   });
/// }
/// ```
///
/// {@category Testing}
library;

export 'src/widgets/testing/widget_testing.dart';
