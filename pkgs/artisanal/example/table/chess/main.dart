import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart';

void main() {
  final labelStyle = Style().foreground(AnsiColor(241));

  final board = [
    ['♜', '♞', '♝', '♛', '♚', '♝', '♞', '♜'],
    ['♟', '♟', '♟', '♟', '♟', '♟', '♟', '♟'],
    [' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '],
    [' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '],
    [' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '],
    [' ', ' ', ' ', ' ', ' ', ' ', ' ', ' '],
    ['♙', '♙', '♙', '♙', '♙', '♙', '♙', '♙'],
    ['♖', '♘', '♗', '♕', '♔', '♗', '♘', '♖'],
  ];

  final t = Table()
      .border(Border.normal)
      .borderRow(true)
      .borderColumn(true)
      .rows(board)
      .styleFunc((row, col, data) {
        return Style().padding(0, 1);
      });

  final ranks = labelStyle.render(
    [' A', 'B', 'C', 'D', 'E', 'F', 'G', 'H  '].join('   '),
  );
  final files = labelStyle.render(
    [' 1', '2', '3', '4', '5', '6', '7', '8 '].join('\n\n '),
  );

  final boardStr = Layout.joinVertical(HorizontalAlign.right, [
    Layout.joinHorizontal(VerticalAlign.center, [files, t.render()]),
    ranks,
  ]);

  print('$boardStr\n');
}
