import 'package:artisanal/artisanal.dart' as plugins;

plugins.RemotePluginFrame boxedFrame({
  required String surfaceId,
  required int width,
  required int height,
  required String title,
  required List<String> bodyLines,
  String accent = '#7dd3fc',
  String border = '#94a3b8',
}) {
  final lines = _buildLines(
    width: width,
    height: height,
    title: title,
    bodyLines: bodyLines,
  );
  final cells = <plugins.RemotePluginFrameCell>[];

  for (var row = 0; row < lines.length; row++) {
    final line = lines[row];
    for (var column = 0; column < line.length; column++) {
      final symbol = line[column];
      final isBorder =
          row == 0 ||
          row == lines.length - 1 ||
          column == 0 ||
          column == line.length - 1 ||
          row == 2;
      cells.add(
        plugins.RemotePluginFrameCell(
          column: column,
          row: row,
          symbol: symbol,
          foreground: switch (row) {
            1 => accent,
            _ when isBorder => border,
            _ => null,
          },
          attributes: plugins.RemotePluginCellAttributes(
            bold: row == 1,
            dim: row > 2 && symbol == '·',
          ),
        ),
      );
    }
  }

  return plugins.RemotePluginFrame(
    surfaceId: surfaceId,
    width: width,
    height: height,
    cells: cells,
  );
}

List<String> _buildLines({
  required int width,
  required int height,
  required String title,
  required List<String> bodyLines,
}) {
  final innerWidth = width - 2;
  final usableBodyRows = height - 4;
  final lines = <String>[
    '┌${'─' * innerWidth}┐',
    '│${_fit(title, innerWidth)}│',
    '├${'─' * innerWidth}┤',
  ];

  for (var index = 0; index < usableBodyRows; index++) {
    final line = index < bodyLines.length ? bodyLines[index] : '';
    lines.add('│${_fit(line, innerWidth)}│');
  }

  lines.add('└${'─' * innerWidth}┘');
  return lines;
}

String _fit(String value, int width) {
  if (value.length >= width) {
    return value.substring(0, width);
  }
  return value.padRight(width);
}
