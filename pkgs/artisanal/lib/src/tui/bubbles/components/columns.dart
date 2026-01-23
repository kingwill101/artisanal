import '../../../style/style.dart';
import 'base.dart';

/// A multi-column layout component.
///
/// ```dart
/// ColumnsComponent(
///   items: ['Item 1', 'Item 2', 'Item 3', 'Item 4'],
///   columnCount: 2,
/// ).render();
/// ```
class ColumnsComponent extends DisplayComponent {
  const ColumnsComponent({
    required this.items,
    this.columnCount,
    this.gutter = 2,
    this.indent = 2,
    this.renderConfig = const RenderConfig(),
  });

  final List<String> items;
  final int? columnCount;
  final int gutter;
  final int indent;
  final RenderConfig renderConfig;

  @override
  String render() {
    if (items.isEmpty) return '';

    // Auto-calculate columns if not specified
    final maxItemWidth = items
        .map((i) => Style.visibleLength(i))
        .fold<int>(0, (m, v) => v > m ? v : m);
    final cols =
        columnCount ??
        ((renderConfig.terminalWidth - indent) ~/ (maxItemWidth + gutter))
            .clamp(1, items.length);

    final colWidth =
        (renderConfig.terminalWidth - indent - (cols - 1) * gutter) ~/ cols;

    final buffer = StringBuffer();

    for (var i = 0; i < items.length; i += cols) {
      final row = <String>[];
      for (var j = 0; j < cols && i + j < items.length; j++) {
        final item = items[i + j];
        final visible = Style.visibleLength(item);
        final fill = colWidth - visible;
        row.add('$item${' ' * (fill > 0 ? fill : 0)}');
      }
      if (buffer.isNotEmpty) buffer.writeln();
      buffer.write('${' ' * indent}${row.join(' ' * gutter)}');
    }

    return buffer.toString();
  }
}
