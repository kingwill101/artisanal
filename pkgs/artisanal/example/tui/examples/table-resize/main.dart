/// Table resize example ported from Bubble Tea using the table component.
library;

import 'package:artisanal/artisanal.dart' show BasicColor, Style;
import 'package:artisanal/tui.dart' as tui;

class TableResizeModel implements tui.Model {
  TableResizeModel({
    required this.table,
    required this.width,
    required this.height,
  });

  final tui.TableComponent table;
  final int width;
  final int height;

  @override
  tui.Cmd? init() => null;

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    switch (msg) {
      case tui.KeyMsg(key: final key):
        final rune = key.runes.isNotEmpty ? key.runes.first : -1;
        if (rune == 0x71 || (key.ctrl && rune == 0x63)) {
          return (this, tui.Cmd.quit());
        }
      case tui.WindowSizeMsg(width: final w, height: final h):
        return (copyWith(width: w, height: h), null);
    }
    return (this, null);
  }

  TableResizeModel copyWith({
    tui.TableComponent? table,
    int? width,
    int? height,
  }) {
    return TableResizeModel(
      table: table ?? this.table,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  @override
  String view() => '\n${table.render()}\n';
}

final _baseStyle = Style().padding(0, 1);
final _headerStyle = _baseStyle.foreground(const BasicColor('252')).bold(true);
final _selectedStyle = _baseStyle
    .foreground(const BasicColor('#01BE85'))
    .background(const BasicColor('#00432F'));

final _typeColors = <String, BasicColor>{
  'Bug': const BasicColor('#D7FF87'),
  'Electric': const BasicColor('#FDFF90'),
  'Fire': const BasicColor('#FF7698'),
  'Flying': const BasicColor('#FF87D7'),
  'Grass': const BasicColor('#75FBAB'),
  'Ground': const BasicColor('#FF875F'),
  'Normal': const BasicColor('#929292'),
  'Poison': const BasicColor('#7D5AFC'),
  'Water': const BasicColor('#00E2C7'),
};

final _dimTypeColors = <String, BasicColor>{
  'Bug': const BasicColor('#97AD64'),
  'Electric': const BasicColor('#FCFF5F'),
  'Fire': const BasicColor('#BA5F75'),
  'Flying': const BasicColor('#C97AB2'),
  'Grass': const BasicColor('#59B980'),
  'Ground': const BasicColor('#C77252'),
  'Normal': const BasicColor('#727272'),
  'Poison': const BasicColor('#634BD0'),
  'Water': const BasicColor('#439F8E'),
};

Style? _styleFunc(int row, int col, String data, List<List<String>> rows) {
  if (row == -1) return _headerStyle;

  final rowIndex = row;
  if (rowIndex < 0 || rowIndex >= rows.length) return _baseStyle;

  // Highlight Pikachu
  if (rows[rowIndex][1] == 'Pikachu') {
    return _selectedStyle;
  }

  final even = row.isEven;

  if (col == 2 || col == 3) {
    final colors = even ? _dimTypeColors : _typeColors;
    final color = colors[rows[rowIndex][col]];
    if (color != null) {
      return _baseStyle.foreground(color);
    }
  }

  return even
      ? _baseStyle.foreground(const BasicColor('245'))
      : _baseStyle.foreground(const BasicColor('252'));
}

TableResizeModel _buildModel() {
  const headers = [
    '#',
    'NAME',
    'TYPE 1',
    'TYPE 2',
    'JAPANESE',
    'OFFICIAL ROM.',
  ];
  const rows = [
    ['1', 'Bulbasaur', 'Grass', 'Poison', 'フシギダネ', 'Bulbasaur'],
    ['2', 'Ivysaur', 'Grass', 'Poison', 'フシギソウ', 'Ivysaur'],
    ['3', 'Venusaur', 'Grass', 'Poison', 'フシギバナ', 'Venusaur'],
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

  final table = tui.TableComponent(
    headers: headers,
    rows: rows,
    styleFunc: (r, c, data) => _styleFunc(r, c, data, rows),
  );

  return TableResizeModel(table: table, width: 0, height: 0);
}

Future<void> main() async {
  await tui.runProgram(
    _buildModel(),
    options: const tui.ProgramOptions(altScreen: true, hideCursor: true),
  );
}
