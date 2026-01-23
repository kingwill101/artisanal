/// Dart port of lipgloss table examples.
///
/// Demonstrates the Table component with various styles.
///
/// Run with: dart run example/lipgloss_table.dart
library;

import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart';

void main() {
  print('=== Simple Table ===\n');
  _simpleTable();

  print('\n=== Languages Table ===\n');
  _languagesTable();

  print('\n=== Pokemon Table ===\n');
  _pokemonTable();
}

/// Simple table example.
void _simpleTable() {
  final table = Table()
      .headers(['Name', 'Age', 'City'])
      .row(['Alice', '30', 'New York'])
      .row(['Bob', '25', 'Los Angeles'])
      .row(['Charlie', '35', 'Chicago'])
      .border(Border.rounded);

  print(table.render());
}

/// Languages table example from lipgloss.
void _languagesTable() {
  const purple = AnsiColor(99);
  const gray = AnsiColor(245);
  const lightGray = AnsiColor(241);

  final headerStyle = Style()
      .foreground(purple)
      .bold()
      .align(HorizontalAlign.center);

  final cellStyle = Style().padding(0, 1).width(14);

  final oddRowStyle = cellStyle.copy().foreground(gray);
  final evenRowStyle = cellStyle.copy().foreground(lightGray);

  final borderStyle = Style().foreground(purple);

  final rows = [
    ['Chinese', '您好', '你好'],
    ['Japanese', 'こんにちは', 'やあ'],
    ['Arabic', 'أهلين', 'أهلا'],
    ['Russian', 'Здравствуйте', 'Привет'],
    ['Spanish', 'Hola', '¿Qué tal?'],
    ['English', 'You look absolutely fabulous.', "How's it going?"],
  ];

  final table = Table()
      .border(Border.thick)
      .borderStyle(borderStyle)
      .headers(['LANGUAGE', 'FORMAL', 'INFORMAL'])
      .styleFunc((row, col, data) {
        if (row == -1) {
          // Header row
          return headerStyle;
        }

        var style = row % 2 == 0 ? evenRowStyle : oddRowStyle;

        // Make the second column a little wider
        if (col == 1) {
          style = style.copy().width(22);
        }

        // Arabic is right-to-left, so right align the text
        if (row < rows.length && rows[row][0] == 'Arabic' && col != 0) {
          style = style.copy().align(HorizontalAlign.right);
        }

        return style;
      });

  for (final row in rows) {
    table.row(row);
  }

  print(table.render());
}

/// Pokemon table example from lipgloss.
void _pokemonTable() {
  final typeColors = {
    'Bug': BasicColor('#D7FF87'),
    'Electric': BasicColor('#FDFF90'),
    'Fire': BasicColor('#FF7698'),
    'Flying': BasicColor('#FF87D7'),
    'Grass': BasicColor('#75FBAB'),
    'Ground': BasicColor('#FF875F'),
    'Normal': BasicColor('#929292'),
    'Poison': BasicColor('#7D5AFC'),
    'Water': BasicColor('#00E2C7'),
  };

  final baseStyle = Style().padding(0, 1);
  final headerStyle = baseStyle.copy().foreground(AnsiColor(252)).bold();
  final selectedStyle = baseStyle
      .copy()
      .foreground(BasicColor('#01BE85'))
      .background(BasicColor('#00432F'));

  final rows = [
    ['1', 'Bulbasaur', 'Grass', 'Poison', 'フシギダネ', 'Fushigidane'],
    ['2', 'Ivysaur', 'Grass', 'Poison', 'フシギソウ', 'Fushigisou'],
    ['3', 'Venusaur', 'Grass', 'Poison', 'フシギバナ', 'Fushigibana'],
    ['4', 'Charmander', 'Fire', '', 'ヒトカゲ', 'Hitokage'],
    ['5', 'Charmeleon', 'Fire', '', 'リザード', 'Lizardo'],
    ['6', 'Charizard', 'Fire', 'Flying', 'リザードン', 'Lizardon'],
    ['7', 'Squirtle', 'Water', '', 'ゼニガメ', 'Zenigame'],
    ['8', 'Wartortle', 'Water', '', 'カメール', 'Kameil'],
    ['9', 'Blastoise', 'Water', '', 'カメックス', 'Kamex'],
    ['25', 'Pikachu', 'Electric', '', 'ピカチュウ', 'Pikachu'],
  ];

  final table = Table()
      .border(Border.normal)
      .borderStyle(Style().foreground(AnsiColor(238)))
      .headers(['#', 'NAME', 'TYPE 1', 'TYPE 2', 'JAPANESE', 'OFFICIAL ROM.'])
      .width(80)
      .styleFunc((row, col, data) {
        if (row == -1) {
          return headerStyle;
        }

        final rowData = (row >= 0 && row < rows.length) ? rows[row] : null;
        final isPikachuRow =
            rowData != null && rowData.length > 1 && rowData[1] == 'Pikachu';

        // Highlight Pikachu row
        if (isPikachuRow) {
          return selectedStyle;
        }

        final even = row % 2 == 0;

        // Type columns - use the cell value to pick a color
        if (col == 2 || col == 3) {
          final color = typeColors[data];
          if (color != null) {
            return baseStyle.copy().foreground(color);
          }
        }

        if (even) {
          return baseStyle.copy().foreground(AnsiColor(245));
        }
        return baseStyle.copy().foreground(AnsiColor(252));
      });

  for (final row in rows) {
    table.row(row);
  }

  print(table.render());
}
