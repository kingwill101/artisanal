/// Dart port of the lipgloss layout example.
///
/// This demonstrates various artisanal style and layout features,
/// mirroring the Go lipgloss example.
///
/// Run with: dart run example/lipgloss_layout.dart
library;

import 'dart:io';
import 'dart:math' as math;

import 'package:artisanal/style.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

const width = 96;
const columnWidth = 30;

// ─────────────────────────────────────────────────────────────────────────────
// Color Definitions
// ─────────────────────────────────────────────────────────────────────────────

const normal = BasicColor('#EEEEEE');
final subtle = AdaptiveColor(
  light: BasicColor('#D9DCCF'),
  dark: BasicColor('#383838'),
);
final highlight = AdaptiveColor(
  light: BasicColor('#874BFD'),
  dark: BasicColor('#7D56F4'),
);
final special = AdaptiveColor(
  light: BasicColor('#43BF6D'),
  dark: BasicColor('#73F59F'),
);

// ─────────────────────────────────────────────────────────────────────────────
// Style Definitions
// ─────────────────────────────────────────────────────────────────────────────

Style baseStyle() => Style().foreground(normal);

// Divider using setString like lipgloss
final divider = Style()
    .setString('•')
    .padding(0, 1)
    .foreground(subtle)
    .toString();

String urlStyle(String text) => Style().foreground(special).render(text);

// Tab styles
final activeTabBorder = Border(
  top: '─',
  bottom: ' ',
  left: '│',
  right: '│',
  topLeft: '╭',
  topRight: '╮',
  bottomLeft: '┘',
  bottomRight: '└',
);

final tabBorder = Border(
  top: '─',
  bottom: '─',
  left: '│',
  right: '│',
  topLeft: '╭',
  topRight: '╮',
  bottomLeft: '┴',
  bottomRight: '┴',
);

Style tabStyle() =>
    Style().border(tabBorder).borderForeground(highlight).padding(0, 1);

Style activeTabStyle() => tabStyle().border(activeTabBorder);

// Tab gap - uses borderTop(false) etc. like lipgloss
Style tabGapStyle() =>
    tabStyle().borderTop(false).borderLeft(false).borderRight(false);

// Title style - using individual margin setters like lipgloss
Style titleStyle() => Style()
    .marginLeft(1)
    .marginRight(5)
    .padding(0, 1)
    .italic()
    .foreground(BasicColor('#FFF7DB'))
    .setString('Lip Gloss');

Style descStyle() => baseStyle().marginTop(1);

Style infoStyle() => baseStyle()
    .borderStyle(Border.normal)
    .borderTop(true)
    .borderBottom(false)
    .borderLeft(false)
    .borderRight(false)
    .borderForeground(subtle);

// Dialog styles
Style dialogBoxStyle() => Style()
    .border(Border.rounded)
    .borderForeground(BasicColor('#874BFD'))
    .padding(1, 0)
    .borderTop(true)
    .borderLeft(true)
    .borderRight(true)
    .borderBottom(true);

Style buttonStyle() => Style()
    .foreground(BasicColor('#FFF7DB'))
    .background(BasicColor('#888B7E'))
    .paddingLeft(3)
    .paddingRight(3)
    .marginTop(1);

Style activeButtonStyle() => Style()
    .foreground(BasicColor('#FFF7DB'))
    .background(BasicColor('#F25D94'))
    .paddingLeft(3)
    .paddingRight(3)
    .marginTop(1)
    .marginRight(2)
    .underline();

// List styles - using borderTop/Left/Right/Bottom(false) like lipgloss
Style listStyle() => Style()
    .borderStyle(Border.normal)
    .borderTop(false)
    .borderBottom(false)
    .borderLeft(false)
    .borderForeground(subtle)
    .marginRight(2)
    .height(8)
    .width(columnWidth + 1);

String listHeader(String text) => baseStyle()
    .borderStyle(Border.normal)
    .borderTop(false)
    .borderLeft(false)
    .borderRight(false)
    .borderBottom(true)
    .borderForeground(subtle)
    .marginRight(2)
    .render(text);

String listItem(String text) => baseStyle().paddingLeft(2).render(text);

// checkMark using setString and toString() like lipgloss
final checkMark = Style().foreground(special).paddingRight(1).setString('✓');

// listDone now uses checkMark with setString
String listDone(String s) =>
    '$checkMark${Style().strikethrough().foreground(AdaptiveColor(light: BasicColor('#969B86'), dark: BasicColor('#696969'))).render(s)}';

// History/paragraph style - using individual setters
Style historyStyle() => Style()
    .align(HorizontalAlign.left)
    .foreground(BasicColor('#FAFAFA'))
    .background(highlight)
    .margin(1, 3, 0, 0)
    .paddingTop(1)
    .paddingBottom(1)
    .paddingLeft(2)
    .paddingRight(2)
    .height(19)
    .width(columnWidth);

// Status bar styles
Style statusNuggetStyle() =>
    Style().foreground(BasicColor('#FFFDF5')).paddingLeft(1).paddingRight(1);

Style statusBarStyle() => Style()
    .foreground(
      AdaptiveColor(light: BasicColor('#343433'), dark: BasicColor('#C1C6B2')),
    )
    .background(
      AdaptiveColor(light: BasicColor('#D9DCCF'), dark: BasicColor('#353533')),
    );

Style statusStyle() => statusBarStyle()
    .foreground(BasicColor('#FFFDF5'))
    .background(BasicColor('#FF5F87'))
    .padding(0, 1)
    .marginRight(1);

Style encodingStyle() => statusNuggetStyle()
    .background(BasicColor('#A550DF'))
    .align(HorizontalAlign.right);

Style statusTextStyle() => statusBarStyle();

Style fishCakeStyle() => statusNuggetStyle().background(BasicColor('#6124DF'));

// Page style
Style docStyle() =>
    Style().paddingTop(1).paddingBottom(1).paddingLeft(2).paddingRight(2);

// ─────────────────────────────────────────────────────────────────────────────
// Main
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  final doc = StringBuffer();

  // Tabs
  _buildTabs(doc);

  // Title
  _buildTitle(doc);

  // Dialog
  _buildDialog(doc);

  // Lists and Color Grid
  _buildListsAndColors(doc);

  // History
  _buildHistory(doc);

  // Status Bar
  _buildStatusBar(doc);

  // Print with doc style
  final physicalWidth = stdout.hasTerminal ? stdout.terminalColumns : width;
  final finalDoc = docStyle().maxWidth(physicalWidth).render(doc.toString());
  print(finalDoc);
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Builders
// ─────────────────────────────────────────────────────────────────────────────

void _buildTabs(StringBuffer doc) {
  final tabs = [
    activeTabStyle().render('Lip Gloss'),
    tabStyle().render('Blush'),
    tabStyle().render('Eye Shadow'),
    tabStyle().render('Mascara'),
    tabStyle().render('Foundation'),
  ];

  final row = Layout.joinHorizontal(VerticalAlign.top, tabs);
  final rowWidth = Layout.getWidth(row);
  final gapWidth = math.max(0, width - rowWidth - 2);
  final gap = tabGapStyle().render(' ' * gapWidth);

  final fullRow = Layout.joinHorizontal(VerticalAlign.bottom, [row, gap]);
  doc.writeln(fullRow);
  doc.writeln();
}

void _buildTitle(StringBuffer doc) {
  // Create gradient title effect - using setString like lipgloss
  final colors = _colorGrid(1, 5);
  final titleParts = <String>[];

  for (var i = 0; i < colors.length; i++) {
    final c = BasicColor(colors[i][0]);
    // titleStyle already has setString('Lip Gloss'), just modify marginLeft and background
    final style = Style()
        .marginLeft(i * 2)
        .marginRight(5)
        .paddingLeft(1)
        .paddingRight(1)
        .italic()
        .foreground(BasicColor('#FFF7DB'))
        .background(c)
        .setString('Lip Gloss');
    titleParts.add(style.toString());
  }

  final title = titleParts.join('\n');

  final desc = Layout.joinVertical(HorizontalAlign.left, [
    descStyle().render('Style Definitions for Nice Terminal Layouts'),
    infoStyle().render(
      'From Charm$divider${urlStyle("https://github.com/charmbracelet/lipgloss")}',
    ),
  ]);

  final row = Layout.joinHorizontal(VerticalAlign.top, [title, desc]);
  doc.writeln(row);
  doc.writeln();
}

void _buildDialog(StringBuffer doc) {
  final okButton = activeButtonStyle().render('Yes');
  final cancelButton = buttonStyle().render('Maybe');

  final question = Style()
      .width(50)
      .align(HorizontalAlign.center)
      .render(_rainbow('Are you sure you want to eat marmalade?'));

  final buttons = Layout.joinHorizontal(VerticalAlign.top, [
    okButton,
    cancelButton,
  ]);
  final ui = Layout.joinVertical(HorizontalAlign.center, [question, buttons]);

  final dialog = Layout.place(
    width: width,
    height: 9,
    horizontal: HorizontalAlign.center,
    vertical: VerticalAlign.center,
    content: dialogBoxStyle().render(ui),
    whitespace: WhitespaceOptions(chars: '猫咪', foreground: subtle),
  );

  doc.writeln(dialog);
  doc.writeln();
}

void _buildListsAndColors(StringBuffer doc) {
  // Color grid
  final colorGrid = _buildColorGrid();

  // Lists
  final list1 = listStyle().render(
    Layout.joinVertical(HorizontalAlign.left, [
      listHeader('Citrus Fruits to Try'),
      listDone('Grapefruit'),
      listDone('Yuzu'),
      listItem('Citron'),
      listItem('Kumquat'),
      listItem('Pomelo'),
    ]),
  );

  final list2 = listStyle()
      .width(columnWidth)
      .render(
        Layout.joinVertical(HorizontalAlign.left, [
          listHeader('Actual Lip Gloss Vendors'),
          listItem('Glossier'),
          listItem("Claire's Boutique"),
          listDone('Nyx'),
          listItem('Mac'),
          listDone('Milk'),
        ]),
      );

  final lists = Layout.joinHorizontal(VerticalAlign.top, [list1, list2]);
  final combined = Layout.joinHorizontal(VerticalAlign.top, [lists, colorGrid]);

  doc.writeln(combined);
}

String _buildColorGrid() {
  final colors = _colorGrid(14, 8);
  final buffer = StringBuffer();

  for (final row in colors) {
    for (final color in row) {
      final style = Style().background(BasicColor(color));
      buffer.write(style.render('  '));
    }
    buffer.writeln();
  }

  // Pad the grid to align with list column widths
  return Style().width(columnWidth + 1).render(buffer.toString().trimRight());
}

void _buildHistory(StringBuffer doc) {
  const historyA =
      'The Romans learned from the Greeks that quinces slowly cooked with honey would "set" when cool. The Apicius gives a recipe for preserving whole quinces, stems and leaves attached, in a bath of honey diluted with defrutum: Roman marmalade. Preserves of quince and lemon appear (along with rose, apple, plum and pear) in the Book of ceremonies of the Byzantine Emperor Constantine VII Porphyrogennetos.';
  const historyB =
      'Medieval quince preserves, which went by the French name cotignac, produced in a clear version and a fruit pulp version, began to lose their medieval seasoning of spices in the 16th century. In the 17th century, La Varenne provided recipes for both thick and clear cotignac.';
  const historyC =
      'In 1524, Henry VIII, King of England, received a "box of marmalade" from Mr. Hull of Exeter. This was probably marmelada, a solid quince paste from Portugal, still made and sold in southern Europe today. It became a favourite treat of Anne Boleyn and her ladies in waiting.';

  final col1 = historyStyle().align(HorizontalAlign.right).render(historyA);
  final col2 = historyStyle().align(HorizontalAlign.center).render(historyB);
  final col3 = historyStyle().marginRight(0).render(historyC);

  final history = Layout.joinHorizontal(VerticalAlign.top, [col1, col2, col3]);
  doc.writeln(history);
  doc.writeln();
}

void _buildStatusBar(StringBuffer doc) {
  final statusKey = statusStyle().render('STATUS');
  final encoding = encodingStyle().render('UTF-8');
  final fishCake = fishCakeStyle().render('🍥 Fish Cake');

  final statusKeyWidth = Layout.getWidth(statusKey);
  final encodingWidth = Layout.getWidth(encoding);
  final fishCakeWidth = Layout.getWidth(fishCake);

  final statusVal = statusTextStyle()
      .width(width - statusKeyWidth - encodingWidth - fishCakeWidth)
      .render('Ravishing');

  final bar = Layout.joinHorizontal(VerticalAlign.top, [
    statusKey,
    statusVal,
    encoding,
    fishCake,
  ]);

  doc.write(statusBarStyle().width(width).render(bar));
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Generates a color grid for the visual display.
List<List<String>> _colorGrid(int xSteps, int ySteps) {
  // Corner colors (hex)
  final x0y0 = _parseHex('#F25D94');
  final x1y0 = _parseHex('#EDFF82');
  final x0y1 = _parseHex('#643AFF');
  final x1y1 = _parseHex('#14F9D5');

  // Create left edge colors
  final x0 = <List<int>>[];
  for (var i = 0; i < ySteps; i++) {
    x0.add(_blendColor(x0y0, x0y1, i / ySteps));
  }

  // Create right edge colors
  final x1 = <List<int>>[];
  for (var i = 0; i < ySteps; i++) {
    x1.add(_blendColor(x1y0, x1y1, i / ySteps));
  }

  // Create grid
  final grid = <List<String>>[];
  for (var y = 0; y < ySteps; y++) {
    final row = <String>[];
    for (var x = 0; x < xSteps; x++) {
      final color = _blendColor(x0[y], x1[y], x / xSteps);
      row.add(_toHex(color));
    }
    grid.add(row);
  }

  return grid;
}

List<int> _parseHex(String hex) {
  hex = hex.replaceFirst('#', '');
  return [
    int.parse(hex.substring(0, 2), radix: 16),
    int.parse(hex.substring(2, 4), radix: 16),
    int.parse(hex.substring(4, 6), radix: 16),
  ];
}

List<int> _blendColor(List<int> c1, List<int> c2, double t) {
  return [
    (c1[0] + (c2[0] - c1[0]) * t).round(),
    (c1[1] + (c2[1] - c1[1]) * t).round(),
    (c1[2] + (c2[2] - c1[2]) * t).round(),
  ];
}

String _toHex(List<int> color) {
  return '#${color[0].toRadixString(16).padLeft(2, '0')}'
      '${color[1].toRadixString(16).padLeft(2, '0')}'
      '${color[2].toRadixString(16).padLeft(2, '0')}';
}

/// Creates a rainbow-colored string.
String _rainbow(String text) {
  final colors = [
    '#F25D94',
    '#FF6B6B',
    '#FFA07A',
    '#FFD700',
    '#ADFF2F',
    '#00FA9A',
    '#00CED1',
    '#1E90FF',
    '#9370DB',
    '#FF69B4',
  ];

  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final color = colors[i % colors.length];
    buffer.write(Style().foreground(BasicColor(color)).render(text[i]));
  }
  return buffer.toString();
}
