/// Testing utilities for TUI widgets.
///
/// Provides [WidgetTester] for mounting widgets, sending input events,
/// and asserting on rendered output — similar to Flutter's widget testing.
///
/// ```dart
/// import 'package:artisanal_widgets/artisanal_widgets.dart';
///
/// void main() {
///   testWidgets('counter increments on tap', (tester) {
///     tester.pumpWidget(MyCounterWidget());
///     expect(tester.find.text('count: 0'), isTrue);
///
///     tester.tap(tester.find.zone('my-button'));
///     tester.pump();
///     expect(tester.find.text('count: 1'), isTrue);
///   });
/// }
/// ```
library;

export 'widget_tester.dart';
