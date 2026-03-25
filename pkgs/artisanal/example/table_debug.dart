import 'package:artisanal/bubbles.dart';

void main() {
  // Test 1: bare TableModel with explicit width
  final cols = [
    Column(title: 'PID', width: 6),
    Column(title: 'Name', width: 20),
    Column(title: 'CPU', width: 8),
  ];
  final totalWidth = cols.fold(0, (s, c) => s + c.width + 2);

  final table = TableModel(
    columns: cols,
    rows: [
      ['1024', 'node server.js', '12.5%'],
      ['2048', 'dart run', '5.2%'],
      ['3072', 'postgres', '1.1%'],
    ],
    height: 5,
  )..focus();
  table.setWidth(totalWidth);

  print('--- TableModel.view() ---');
  print(table.view());

  // Test 2: DataTableModel (the composite component)
  final items = ['node server.js', 'dart run', 'postgres', 'redis', 'nginx'];
  final model = DataTableModel<String>(
    items: items,
    columns: [
      Column(title: '#', width: 3),
      Column(title: 'Process', width: 20),
    ],
    rowBuilder: (s) => [(items.indexOf(s) + 1).toString(), s],
    title: 'Pick a process',
    pageSize: 3,
  );
  print('\n--- DataTableModel.view() ---');
  print(model.view());
}
