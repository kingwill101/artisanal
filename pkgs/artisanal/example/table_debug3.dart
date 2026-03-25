import 'package:artisanal/bubbles.dart';
import 'package:artisanal/src/style/style.dart';

void main() {
  final cols = [
    Column(title: 'PID', width: 6),
    Column(title: 'Name', width: 20),
    Column(title: 'CPU', width: 8),
    Column(title: 'Mem', width: 10),
  ];

  final headerStyle = Style().bold().padding(0, 1);
  final cellStyle = Style().padding(0, 1);

  // Step 1: widthStyle.render output
  for (final col in cols) {
    final widthStyle = Style()
        .inline(true)
        .width(col.width)
        .maxWidth(col.width);
    final rendered = widthStyle.render(col.title);
    print(
      'widthStyle("${col.title}") visible=${Style.visibleLength(rendered)}',
    );
  }
  print('');

  // Step 2: header cell visible widths
  for (final col in cols) {
    final widthStyle = Style()
        .inline(true)
        .width(col.width)
        .maxWidth(col.width);
    final rendered = widthStyle.render(col.title);
    final cell = headerStyle.render(rendered);
    print(
      'header "${col.title}" col.width=${col.width} '
      'visible=${Style.visibleLength(cell)}  expected=${col.width + 2}',
    );
  }
  print('');

  // Step 3: cell visible widths
  final row = ['1024', 'node server.js', '12.5%', '156MB'];
  for (var i = 0; i < cols.length; i++) {
    final col = cols[i];
    final widthStyle = Style()
        .inline(true)
        .width(col.width)
        .maxWidth(col.width);
    final rendered = widthStyle.render(row[i]);
    final cell = cellStyle.render(rendered);
    print(
      'cell "${row[i]}" col.width=${col.width} '
      'visible=${Style.visibleLength(cell)}  expected=${col.width + 2}',
    );
  }
}
