import 'package:test/test.dart';

import 'package:artisanal/src/tui/key.dart';
import 'package:artisanal/src/tui/msg.dart';
import 'package:artisanal/src/tui/view.dart';

import '../../example/tui/examples/trello.dart' show TrelloModel;

void main() {
  test('trello modal content overlays base (compositor z-order)', () {
    // Use the same dimensions as the trello golden so we get stable layout.
    final (m0, _) = TrelloModel.initial().update(const WindowSizeMsg(110, 28));

    final openKey = Key(KeyType.runes, runes: ['n'.codeUnitAt(0)]);
    final (m1, _) = (m0 as TrelloModel).update(KeyMsg(openKey));

    final v = (m1 as TrelloModel).view();
    final content = switch (v) {
      View(:final content) => content,
      final String s => s,
      _ => v.toString(),
    };

    final lines = content.split('\n');
    final modalTitleLine = lines.firstWhere(
      (l) => l.contains('New card'),
      orElse: () => '',
    );

    expect(modalTitleLine, isNotEmpty);

    // The Done column contains a card called "Kitchen sink split files". When
    // z-ordering is wrong, part of it can show through the modal border/title.
    expect(modalTitleLine.contains('Kitchen sink'), isFalse);
  });
}
