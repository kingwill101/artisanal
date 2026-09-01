import 'package:artisanal/style.dart' show Color, Style;
import '_component_foundation.dart';

/// A compact month calendar with independently styled dates and markers.
class MonthlyCalendar extends StatelessWidget {
  /// Creates a month calendar containing [month].
  MonthlyCalendar({
    required this.month,
    this.selectedDate,
    this.today,
    this.firstDayOfWeek = DateTime.monday,
    this.showAdjacentMonths = false,
    this.markers = const {},
    this.headerStyle,
    this.weekdayStyle,
    this.dayStyle,
    this.outsideStyle,
    this.todayStyle,
    this.selectedStyle,
    this.markerColor,
    super.key,
  }) : assert(firstDayOfWeek >= DateTime.monday),
       assert(firstDayOfWeek <= DateTime.sunday);

  /// Any date in the month to display.
  final DateTime month;

  /// Date rendered with [selectedStyle].
  final DateTime? selectedDate;

  /// Date rendered with [todayStyle]. Defaults to the current local date.
  final DateTime? today;

  /// First weekday column, using the [DateTime] weekday constants.
  final int firstDayOfWeek;

  /// Whether dates from neighboring months are visible.
  final bool showAdjacentMonths;

  /// Optional single-cell markers keyed by date.
  final Map<DateTime, String> markers;

  final Style? headerStyle;
  final Style? weekdayStyle;
  final Style? dayStyle;
  final Style? outsideStyle;
  final Style? todayStyle;
  final Style? selectedStyle;
  final Color? markerColor;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final visibleMonth = DateTime(month.year, month.month);
    final currentDay = _dateOnly(today ?? DateTime.now());
    final selected = selectedDate == null ? null : _dateOnly(selectedDate!);
    final normalizedMarkers = <DateTime, String>{
      for (final entry in markers.entries)
        _dateOnly(entry.key): entry.value.isEmpty ? '•' : entry.value[0],
    };

    final normal = dayStyle ?? theme.bodyMedium;
    final outside =
        outsideStyle ?? (copyStyle(normal)..foreground(theme.muted));
    final todayCell =
        todayStyle ??
        (copyStyle(normal)
          ..foreground(theme.primary)
          ..bold());
    final selectedCell =
        selectedStyle ??
        (copyStyle(normal)
          ..foreground(theme.onPrimary)
          ..background(theme.primary)
          ..bold());
    final weekdays = _orderedWeekdays(firstDayOfWeek);
    final cells = _monthCells(visibleMonth, firstDayOfWeek);

    final rows = <Widget>[
      Text(
        '${_monthNames[visibleMonth.month - 1]} ${visibleMonth.year}',
        style: headerStyle ?? theme.titleSmall,
      ),
      Row(
        gap: 0,
        children: [
          for (final weekday in weekdays)
            Text(weekday.padRight(3), style: weekdayStyle ?? theme.labelSmall),
        ],
      ),
    ];

    for (var week = 0; week < cells.length; week += 7) {
      rows.add(
        Row(
          gap: 0,
          children: [
            for (final date in cells.skip(week).take(7))
              _buildDay(
                date,
                visibleMonth,
                currentDay,
                selected,
                normalizedMarkers,
                normal,
                outside,
                todayCell,
                selectedCell,
              ),
          ],
        ),
      );
    }

    return Column(gap: 0, children: rows);
  }

  Widget _buildDay(
    DateTime date,
    DateTime visibleMonth,
    DateTime currentDay,
    DateTime? selected,
    Map<DateTime, String> normalizedMarkers,
    Style normal,
    Style outside,
    Style todayCell,
    Style selectedCell,
  ) {
    final inMonth = date.month == visibleMonth.month;
    final isSelected = selected != null && date == selected;
    final isToday = date == currentDay;
    final marker = normalizedMarkers[date];
    final value = !inMonth && !showAdjacentMonths
        ? '   '
        : marker == null
        ? date.day.toString().padLeft(2).padRight(3)
        : '${date.day.toString().padLeft(2)}$marker';
    var style = inMonth ? normal : outside;
    if (isToday) style = todayCell;
    if (isSelected) style = selectedCell;
    if (marker != null && markerColor != null && !isSelected) {
      style = copyStyle(style)..foreground(markerColor!);
    }
    return Text(value, style: style);
  }
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

List<DateTime> _monthCells(DateTime month, int firstDayOfWeek) {
  final leading = (month.weekday - firstDayOfWeek + 7) % 7;
  final first = month.subtract(Duration(days: leading));
  final lastOfMonth = DateTime(month.year, month.month + 1, 0);
  final occupied = leading + lastOfMonth.day;
  final cellCount = occupied <= 35 ? 35 : 42;
  return List<DateTime>.generate(
    cellCount,
    (index) => first.add(Duration(days: index)),
    growable: false,
  );
}

List<String> _orderedWeekdays(int firstDayOfWeek) => List<String>.generate(
  7,
  (index) => _weekdayNames[(firstDayOfWeek - 1 + index) % 7],
  growable: false,
);

const _weekdayNames = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
