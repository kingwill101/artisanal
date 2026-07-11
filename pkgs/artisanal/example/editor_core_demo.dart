import 'package:artisanal/artisanal.dart';

void main() {
  final buffer = EditBuffer(
    text: 'alpha\nbeta\ngamma',
    width: 8,
    height: 4,
    softWrap: true,
  );

  _printState('initial', buffer);

  buffer.setCursor(1, 4);
  buffer.insertText('!');
  _printState('insert ! at beta', buffer);

  buffer.beginTransaction();
  buffer.gotoLine(0);
  buffer.insertText('> ');
  buffer.gotoLine(2);
  buffer.insertText('# ');
  _printState('transaction edits', buffer);

  buffer.rollbackTransaction();
  _printState('after rollback', buffer);

  buffer.beginTransaction();
  buffer.setCursorByOffset(buffer.length);
  buffer.newLine();
  buffer.insertText('delta');
  buffer.commitTransaction();
  _printState('after committed append', buffer);

  buffer.setCursor(0, 6);
  buffer.moveCursorDown();
  _printState('after vertical move', buffer);

  final journal = buffer.toJournal();
  final restored = EditBuffer.fromJournal(journal);
  _printState('restored from journal', restored);

  restored.undo();
  _printState('restored after undo', restored);

  restored.redo();
  _printState('restored after redo', restored);
}

void _printState(String label, EditBuffer buffer) {
  final selection = buffer.selection;
  final selectionText = selection == null
      ? 'none'
      : '${selection.start.line}:${selection.start.column}'
            ' -> ${selection.end.line}:${selection.end.column}';
  print('== $label ==');
  print('cursor: ${buffer.cursor.line}:${buffer.cursor.column}');
  print('selection: $selectionText');
  print('canUndo=${buffer.canUndo} canRedo=${buffer.canRedo}');
  print('--- text ---');
  print(buffer.text);
  print('------------');
}
