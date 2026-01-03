/// This example demonstrates various Lip Gloss style and layout features.
///
/// Port of the Go lipgloss layout example:
/// https://github.com/charmbracelet/lipgloss/blob/master/examples/layout/main.go
library;

import 'dart:io';
import 'dart:math' as math;

import 'package:artisanal/style.dart';

const width = 96;
const columnWidth = 30;

// Style definitions

// General colors
final normal = BasicColor('#EEEEEE');
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

// Base style
final base = Style().foreground(normal);

// Divider
final divider = Style().padding(0, 1).foreground(subtle).render('•');

// URL styling
String url(String s) => Style().foreground(special).render(s);

// Tab borders
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

// Tab styles
final tab = Style()
    .border(tabBorder, top: true, bottom: true, left: true, right: true)
    .borderForeground(highlight)
    .padding(0, 1);

final activeTab = Style()
    .border(activeTabBorder, top: true, bottom: true, left: true, right: true)
    .borderForeground(highlight)
    .padding(0, 1);

Style get tabGap =>
    Style().border(tabBorder, bottom: true).borderForeground(highlight);

// Title styles
final titleStyle = Style()
    .marginLeft(1)
    .marginRight(5)
    .padding(0, 1)
    .italic()
    .foreground(BasicColor('#FFF7DB'));

Style get descStyle {
  final s = base.copy();
  s.marginTop(1);
  return s;
}

Style get infoStyle {
  final s = base.copy();
  s.borderStyle(Border.normal);
  s.borderTop(true);
  s.borderForeground(subtle);
  return s;
}

// Dialog styles
final dialogBoxStyle = Style()
    .border(Border.rounded, top: true, bottom: true, left: true, right: true)
    .borderForeground(BasicColor('#874BFD'))
    .padding(1, 0);

final buttonStyle = Style()
    .foreground(BasicColor('#FFF7DB'))
    .background(BasicColor('#888B7E'))
    .padding(0, 3)
    .marginTop(1);

final activeButtonStyle = Style()
    .foreground(BasicColor('#FFF7DB'))
    .background(BasicColor('#F25D94'))
    .padding(0, 3)
    .marginTop(1)
    .marginRight(2)
    .underline();

// List styles
final list = Style()
    .border(Border.normal, right: true)
    .borderForeground(subtle)
    .marginRight(2)
    .height(8)
    .width(columnWidth + 1);

String listHeader(String s) {
  final style = base.copy();
  style.borderStyle(Border.normal);
  style.borderBottom(true);
  style.borderForeground(subtle);
  style.marginRight(2);
  return style.render(s);
}

String listItem(String s) {
  final style = base.copy();
  style.paddingLeft(2);
  return style.render(s);
}

final checkMark = Style().foreground(special).paddingRight(1).render('✓');

String listDone(String s) =>
    checkMark +
    Style()
        .strikethrough()
        .foreground(
          AdaptiveColor(
            light: BasicColor('#969B86'),
            dark: BasicColor('#696969'),
          ),
        )
        .render(s);

// History style
final historyStyle = Style()
    .align(HorizontalAlign.left)
    .foreground(BasicColor('#FAFAFA'))
    .background(highlight)
    .margin(1, 3, 0, 0)
    .padding(1, 2)
    .height(19)
    .width(columnWidth);

// Status bar styles
final statusNugget = Style().foreground(BasicColor('#FFFDF5')).padding(0, 1);

final statusBarStyle = Style()
    .foreground(
      AdaptiveColor(light: BasicColor('#343433'), dark: BasicColor('#C1C6B2')),
    )
    .background(
      AdaptiveColor(light: BasicColor('#D9DCCF'), dark: BasicColor('#353533')),
    );

final statusStyle = Style()
    .inherit(statusBarStyle)
    .foreground(BasicColor('#FFFDF5'))
    .background(BasicColor('#FF5F87'))
    .padding(0, 1)
    .marginRight(1);

Style get encodingStyle =>
    (statusNugget.copy()..background(BasicColor('#A550DF'))).align(
      HorizontalAlign.right,
    );

final statusText = Style().inherit(statusBarStyle);

Style get fishCakeStyle =>
    statusNugget.copy()..background(BasicColor('#6124DF'));

// Page style
Style get docStyle => Style().padding(1, 2, 1, 2);

void main() {
  final doc = StringBuffer();

  // Tabs
  {
    var row = Layout.joinHorizontal(VerticalAlign.top, [
      activeTab.render('Lip Gloss'),
      tab.render('Blush'),
      tab.render('Eye Shadow'),
      tab.render('Mascara'),
      tab.render('Foundation'),
    ]);
    final gapWidth = math.max(0, width - Layout.getWidth(row) - 2);
    final gap = tabGap.render(' ' * gapWidth);
    row = Layout.joinHorizontal(VerticalAlign.bottom, [row, gap]);
    doc.writeln(row);
    doc.writeln();
  }

  // Title
  {
    final colors = colorGrid(1, 5);
    final title = StringBuffer();

    for (var i = 0; i < colors.length; i++) {
      const offset = 2;
      final c = BasicColor(colors[i][0]);
      final style = titleStyle.copy()
        ..marginLeft(i * offset)
        ..background(c);
      title.write(style.render('Lip Gloss'));
      if (i < colors.length - 1) {
        title.write('\n');
      }
    }

    final desc = Layout.joinVertical(HorizontalAlign.left, [
      descStyle.render('Style Definitions for Nice Terminal Layouts'),
      infoStyle.render(
        'From Charm$divider${url("https://github.com/charmbracelet/lipgloss")}',
      ),
    ]);

    final row = Layout.joinHorizontal(VerticalAlign.top, [
      title.toString(),
      desc,
    ]);
    doc.writeln(row);
    doc.writeln();
  }

  // Dialog
  {
    final okButton = activeButtonStyle.render('Yes');
    final cancelButton = buttonStyle.render('Maybe');

    final question = Style()
        .width(50)
        .align(HorizontalAlign.center)
        .render(rainbow('Are you sure you want to eat marmalade?'));
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
      content: dialogBoxStyle.render(ui),
      whitespace: WhitespaceOptions(
        chars: '猫咪',
        foreground: subtle.dark, // Use dark variant
      ),
    );

    doc.writeln(dialog);
    doc.writeln();
  }

  // Color grid
  final colors = () {
    final grid = colorGrid(14, 8);
    final b = StringBuffer();
    for (final row in grid) {
      for (final color in row) {
        final s = Style().background(BasicColor(color));
        b.write(s.render('  '));
      }
      b.write('\n');
    }
    return b.toString();
  }();

  // Lists
  final lists = Layout.joinHorizontal(VerticalAlign.top, [
    list.render(
      Layout.joinVertical(HorizontalAlign.left, [
        listHeader('Citrus Fruits to Try'),
        listDone('Grapefruit'),
        listDone('Yuzu'),
        listItem('Citron'),
        listItem('Kumquat'),
        listItem('Pomelo'),
      ]),
    ),
    (list.copy()..width(columnWidth)).render(
      Layout.joinVertical(HorizontalAlign.left, [
        listHeader('Actual Lip Gloss Vendors'),
        listItem('Glossier'),
        listItem("Claire's Boutique"),
        listDone('Nyx'),
        listItem('Mac'),
        listDone('Milk'),
      ]),
    ),
  ]);

  doc.writeln(Layout.joinHorizontal(VerticalAlign.top, [lists, colors]));

  // Marmalade history
  {
    const historyA =
        'The Romans learned from the Greeks that quinces slowly cooked with honey would "set" when cool. The Apicius gives a recipe for preserving whole quinces, stems and leaves attached, in a bath of honey diluted with defrutum: Roman marmalade. Preserves of quince and lemon appear (along with rose, apple, plum and pear) in the Book of ceremonies of the Byzantine Emperor Constantine VII Porphyrogennetos.';
    const historyB =
        'Medieval quince preserves, which went by the French name cotignac, produced in a clear version and a fruit pulp version, began to lose their medieval seasoning of spices in the 16th century. In the 17th century, La Varenne provided recipes for both thick and clear cotignac.';
    const historyC =
        'In 1524, Henry VIII, King of England, received a "box of marmalade" from Mr. Hull of Exeter. This was probably marmelada, a solid quince paste from Portugal, still made and sold in southern Europe today. It became a favourite treat of Anne Boleyn and her ladies in waiting.';

    doc.writeln(
      Layout.joinHorizontal(VerticalAlign.top, [
        (historyStyle.copy()..align(HorizontalAlign.right)).render(historyA),
        (historyStyle.copy()..align(HorizontalAlign.center)).render(historyB),
        (historyStyle.copy()..marginRight(0)).render(historyC),
      ]),
    );
    doc.writeln();
  }

  // Status bar
  {
    final statusKey = statusStyle.render('STATUS');
    final encoding = encodingStyle.render('UTF-8');
    final fishCake = fishCakeStyle.render('🍥 Fish Cake');
    final availableWidth =
        width -
        Layout.getWidth(statusKey) -
        Layout.getWidth(encoding) -
        Layout.getWidth(fishCake);
    final statusVal = (statusText.copy()..width(availableWidth)).render(
      'Ravishing',
    );

    final bar = Layout.joinHorizontal(VerticalAlign.top, [
      statusKey,
      statusVal,
      encoding,
      fishCake,
    ]);

    doc.writeln((statusBarStyle.copy()..width(width)).render(bar));
  }

  // Print final document
  stdout.write(docStyle.render(doc.toString()));
}

/// Generates a grid of color hex codes.
List<List<String>> colorGrid(int xSteps, int ySteps) {
  // Starting colors for corners
  final x0y0 = hexToRgb('#F25D94');
  final x1y0 = hexToRgb('#EDFF82');
  final x0y1 = hexToRgb('#643AFF');
  final x1y1 = hexToRgb('#14F9D5');

  // Generate left edge colors (x0)
  final x0 = List<List<int>>.generate(ySteps, (i) {
    return blendColor(x0y0, x0y1, i / ySteps);
  });

  // Generate right edge colors (x1)
  final x1 = List<List<int>>.generate(ySteps, (i) {
    return blendColor(x1y0, x1y1, i / ySteps);
  });

  // Generate full grid
  final grid = List<List<String>>.generate(ySteps, (y) {
    return List<String>.generate(xSteps, (x) {
      return rgbToHex(blendColor(x0[y], x1[y], x / xSteps));
    });
  });

  return grid;
}

List<int> hexToRgb(String hex) {
  hex = hex.replaceFirst('#', '');
  return [
    int.parse(hex.substring(0, 2), radix: 16),
    int.parse(hex.substring(2, 4), radix: 16),
    int.parse(hex.substring(4, 6), radix: 16),
  ];
}

String rgbToHex(List<int> rgb) {
  return '#${rgb[0].toRadixString(16).padLeft(2, '0')}'
      '${rgb[1].toRadixString(16).padLeft(2, '0')}'
      '${rgb[2].toRadixString(16).padLeft(2, '0')}';
}

List<int> blendColor(List<int> c1, List<int> c2, double t) {
  return [
    (c1[0] + (c2[0] - c1[0]) * t).round(),
    (c1[1] + (c2[1] - c1[1]) * t).round(),
    (c1[2] + (c2[2] - c1[2]) * t).round(),
  ];
}

/// Applies rainbow coloring to each character.
String rainbow(String s) {
  final colors = colorGrid(s.length, 1)[0];
  final buffer = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    buffer.write(Style().foreground(BasicColor(colors[i])).render(s[i]));
  }
  return buffer.toString();
}
