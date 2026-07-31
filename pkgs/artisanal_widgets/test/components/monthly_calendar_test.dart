import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:artisanal/style.dart' show Style;
import 'package:test/test.dart';

void main() {
  test('renders a Monday-first month grid', () async {
    final tester = WidgetTester(screenWidth: 40, screenHeight: 12);
    addTearDown(tester.dispose);

    await tester.pumpWidget(
      MonthlyCalendar(month: DateTime(2026, 7), today: DateTime(2026, 7, 4)),
    );

    expect(tester.view, contains('July 2026'));
    expect(Style.stripAnsi(tester.view), contains('Mo Tu We Th Fr Sa Su'));
    expect(tester.find.text(' 1 '), isTrue);
    expect(tester.find.text('31 '), isTrue);
  });

  test('supports Sunday-first weeks and neighboring dates', () async {
    final tester = WidgetTester(screenWidth: 40, screenHeight: 12);
    addTearDown(tester.dispose);

    await tester.pumpWidget(
      MonthlyCalendar(
        month: DateTime(2026, 7),
        firstDayOfWeek: DateTime.sunday,
        showAdjacentMonths: true,
        today: DateTime(2000),
      ),
    );

    expect(Style.stripAnsi(tester.view), contains('Su Mo Tu We Th Fr Sa'));
    expect(tester.find.text('28 '), isTrue);
  });

  test('renders date markers and selected dates', () async {
    final tester = WidgetTester(screenWidth: 40, screenHeight: 12);
    addTearDown(tester.dispose);

    await tester.pumpWidget(
      MonthlyCalendar(
        month: DateTime(2026, 7),
        selectedDate: DateTime(2026, 7, 14),
        today: DateTime(2000),
        markers: {DateTime(2026, 7, 4): '*'},
      ),
    );

    expect(tester.find.text(' 4*'), isTrue);
    expect(tester.find.text('14 '), isTrue);
    expect(tester.view, contains('\x1b['));
  });
}
