import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart';

void main() {
  final baseStyle = Style().padding(0, 1);
  final headerStyle = baseStyle.copy().foreground(AnsiColor(252)).bold();
  final selectedStyle = baseStyle
      .copy()
      .foreground(BasicColor('#01BE85'))
      .background(BasicColor('#00432F'));

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

  final dimTypeColors = {
    'Bug': BasicColor('#97AD64'),
    'Electric': BasicColor('#FCFF5F'),
    'Fire': BasicColor('#BA5F75'),
    'Flying': BasicColor('#C97AB2'),
    'Grass': BasicColor('#59B980'),
    'Ground': BasicColor('#C77252'),
    'Normal': BasicColor('#727272'),
    'Poison': BasicColor('#634BD0'),
    'Water': BasicColor('#439F8E'),
  };

  final headers = [
    '#',
    'Name',
    'Type 1',
    'Type 2',
    'Japanese',
    'Official Rom.',
  ];
  final data = [
    ['1', 'Bulbasaur', 'Grass', 'Poison', 'フシギダネ', 'Fushigidane'],
    ['2', 'Ivysaur', 'Grass', 'Poison', 'フシギソウ', 'Fushigisou'],
    ['3', 'Venusaur', 'Grass', 'Poison', 'フシギバナ', 'Fushigibana'],
    ['4', 'Charmander', 'Fire', '', 'ヒトカゲ', 'Hitokage'],
    ['5', 'Charmeleon', 'Fire', '', 'リザード', 'Lizardo'],
    ['6', 'Charizard', 'Fire', 'Flying', 'リザードン', 'Lizardon'],
    ['7', 'Squirtle', 'Water', '', 'ゼニガメ', 'Zenigame'],
    ['8', 'Wartortle', 'Water', '', 'カメール', 'Kameil'],
    ['9', 'Blastoise', 'Water', '', 'カメックス', 'Kamex'],
    ['10', 'Caterpie', 'Bug', '', 'キャタピー', 'Caterpie'],
    ['11', 'Metapod', 'Bug', '', 'トランセル', 'Trancell'],
    ['12', 'Butterfree', 'Bug', 'Flying', 'バタフリー', 'Butterfree'],
    ['13', 'Weedle', 'Bug', 'Poison', 'ビードル', 'Beedle'],
    ['14', 'Kakuna', 'Bug', 'Poison', 'コクーン', 'Cocoon'],
    ['15', 'Beedrill', 'Bug', 'Poison', 'スピアー', 'Spear'],
    ['16', 'Pidgey', 'Normal', 'Flying', 'ポッポ', 'Poppo'],
    ['17', 'Pidgeotto', 'Normal', 'Flying', 'ピジョン', 'Pigeon'],
    ['18', 'Pidgeot', 'Normal', 'Flying', 'ピジョット', 'Pigeot'],
    ['19', 'Rattata', 'Normal', '', 'コラッタ', 'Koratta'],
    ['20', 'Raticate', 'Normal', '', 'ラッタ', 'Ratta'],
    ['21', 'Spearow', 'Normal', 'Flying', 'オニスズメ', 'Onisuzume'],
    ['22', 'Fearow', 'Normal', 'Flying', 'オニドリル', 'Onidrill'],
    ['23', 'Ekans', 'Poison', '', 'アーボ', 'Arbo'],
    ['24', 'Arbok', 'Poison', '', 'アーボック', 'Arbok'],
    ['25', 'Pikachu', 'Electric', '', 'ピカチュウ', 'Pikachu'],
    ['26', 'Raichu', 'Electric', '', 'ライチュウ', 'Raichu'],
    ['27', 'Sandshrew', 'Ground', '', 'サンド', 'Sand'],
    ['28', 'Sandslash', 'Ground', '', 'サンドパン', 'Sandpan'],
  ];

  final t = Table()
      .border(Border.normal)
      .borderStyle(Style().foreground(AnsiColor(238)))
      .headers(headers.map((h) => h.toUpperCase()).toList())
      .width(80)
      .rows(data)
      .styleFunc((row, col, _) {
        if (row == -1) {
          return headerStyle;
        }

        if (data[row][1] == 'Pikachu') {
          return selectedStyle;
        }

        final even = row % 2 == 0;

        // Type columns
        if (col == 2 || col == 3) {
          final colors = even ? dimTypeColors : typeColors;
          final typeName = data[row][col];
          if (typeName.isNotEmpty && colors.containsKey(typeName)) {
            return baseStyle.copy().foreground(colors[typeName]!);
          }
        }

        if (even) {
          return baseStyle.copy().foreground(AnsiColor(245));
        }

        return baseStyle;
      });

  print(t);
}
