/// Box drawing characters for panels and borders.
class PanelBoxChars {
  PanelBoxChars._();

  static const single = PanelBoxCharSet(
    topLeft: '┌',
    topRight: '┐',
    bottomLeft: '└',
    bottomRight: '┘',
    horizontal: '─',
    vertical: '│',
    leftT: '├',
    rightT: '┤',
    topT: '┬',
    bottomT: '┴',
    cross: '┼',
  );

  static const double = PanelBoxCharSet(
    topLeft: '╔',
    topRight: '╗',
    bottomLeft: '╚',
    bottomRight: '╝',
    horizontal: '═',
    vertical: '║',
    leftT: '╠',
    rightT: '╣',
    topT: '╦',
    bottomT: '╩',
    cross: '╬',
  );

  static const rounded = PanelBoxCharSet(
    topLeft: '╭',
    topRight: '╮',
    bottomLeft: '╰',
    bottomRight: '╯',
    horizontal: '─',
    vertical: '│',
    leftT: '├',
    rightT: '┤',
    topT: '┬',
    bottomT: '┴',
    cross: '┼',
  );

  static const heavy = PanelBoxCharSet(
    topLeft: '┏',
    topRight: '┓',
    bottomLeft: '┗',
    bottomRight: '┛',
    horizontal: '━',
    vertical: '┃',
    leftT: '┣',
    rightT: '┫',
    topT: '┳',
    bottomT: '┻',
    cross: '╋',
  );

  static const ascii = PanelBoxCharSet(
    topLeft: '+',
    topRight: '+',
    bottomLeft: '+',
    bottomRight: '+',
    horizontal: '-',
    vertical: '|',
    leftT: '+',
    rightT: '+',
    topT: '+',
    bottomT: '+',
    cross: '+',
  );
}

/// A set of box drawing characters.
class PanelBoxCharSet {
  const PanelBoxCharSet({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
    required this.horizontal,
    required this.vertical,
    required this.leftT,
    required this.rightT,
    required this.topT,
    required this.bottomT,
    required this.cross,
  });

  final String topLeft;
  final String topRight;
  final String bottomLeft;
  final String bottomRight;
  final String horizontal;
  final String vertical;
  final String leftT;
  final String rightT;
  final String topT;
  final String bottomT;
  final String cross;
}
