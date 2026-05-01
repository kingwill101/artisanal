import 'package:artisanal/bubbles.dart';
import 'package:artisanal/src/style/style.dart';

void main() {
  // Simulate exactly what DataTableModel does for the demo columns
  final cols = [
    Column(title: 'PID', width: 6),
    Column(title: 'Name', width: 20),
    Column(title: 'CPU', width: 8),
    Column(title: 'Mem', width: 10),
  ];
  final totalWidth = cols.fold(0, (s, c) => s + c.width + 2);
  print('totalWidth: $totalWidth');

  // Test: what does _headersView produce?
  // Reproduce it manually
  final headerStyle = Style().bold().padding(0, 1);
  for (final col in cols) {
    final widthStyle = Style()
        .inline(true)
        .width(col.width)
        .maxWidth(col.width);
    final rendered = widthStyle.render(col.title);
    final cell = headerStyle.render(rendered);
    print(
      'col "${col.title}" width=${col.width} '
      'cellLen=${Style.visibleLength(cell)} cell="$cell"',
    );
  }
}
