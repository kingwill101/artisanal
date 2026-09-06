import 'package:artisanal/editor_core.dart';
import 'package:artisanal/tui.dart' as tui;
import 'package:test/test.dart';

import '../../../example/tui/examples/advanced-editor/main.dart' as demo;

tui.KeyMsg _ctrl(int rune) =>
    tui.KeyMsg(tui.Key(tui.KeyType.runes, runes: [rune], ctrl: true));

tui.KeyMsg _key(
  tui.KeyType type, {
  bool shift = false,
  List<int> runes = const [],
}) => tui.KeyMsg(tui.Key(type, shift: shift, runes: runes));

void main() {
  demo.AdvancedEditorModel model() => demo.AdvancedEditorModel.initial(
    store: MemoryEditorDocumentStore(),
    documentId: 'demo.dart',
  );

  test('find overlay searches, counts, and replaces matches', () {
    var editor = model();
    var (next, _) = editor.update(_ctrl(0x66));
    editor = next as demo.AdvancedEditorModel;
    expect(editor.view(), contains('Find and Replace'));

    (next, _) = editor.update(_key(tui.KeyType.runes, runes: [0x54])); // T
    editor = next as demo.AdvancedEditorModel;
    (next, _) = editor.update(_key(tui.KeyType.runes, runes: [0x4f])); // O
    editor = next as demo.AdvancedEditorModel;
    (next, _) = editor.update(_key(tui.KeyType.runes, runes: [0x44])); // D
    editor = next as demo.AdvancedEditorModel;
    (next, _) = editor.update(_key(tui.KeyType.runes, runes: [0x4f])); // O
    editor = next as demo.AdvancedEditorModel;
    expect(editor.editor.searchMatches, isNotEmpty);

    (next, _) = editor.update(_key(tui.KeyType.enter));
    editor = next as demo.AdvancedEditorModel;
    expect(editor.editor.activeSearchMatch, isNotNull);

    (next, _) = editor.update(_key(tui.KeyType.tab));
    editor = next as demo.AdvancedEditorModel;
    (next, _) = editor.update(_key(tui.KeyType.runes, runes: [0x58])); // X
    editor = next as demo.AdvancedEditorModel;
    (next, _) = editor.update(
      tui.KeyMsg(const tui.Key(tui.KeyType.enter, alt: true)),
    );
    editor = next as demo.AdvancedEditorModel;
    expect(editor.editor.value, isNot(contains('TODO')));
    expect(editor.editor.value, contains('X'));
  });

  test('command palette executes registered editor commands', () {
    var editor = model();
    var (next, _) = editor.update(_ctrl(0x70));
    editor = next as demo.AdvancedEditorModel;
    expect(editor.view(), contains('Command Palette'));

    for (final unit in 'fold all'.codeUnits) {
      (next, _) = editor.update(_key(tui.KeyType.runes, runes: [unit]));
      editor = next as demo.AdvancedEditorModel;
    }
    (next, _) = editor.update(_key(tui.KeyType.enter));
    editor = next as demo.AdvancedEditorModel;
    expect(editor.status, 'COMMAND  •  Fold All');
  });

  test(
    'save records a durable revision through the persistence session',
    () async {
      final store = MemoryEditorDocumentStore();
      var editor = demo.AdvancedEditorModel.initial(
        store: store,
        documentId: 'demo.dart',
      );
      editor.editor.insertString('// edited\n');
      editor.revision++;

      final (next, cmd) = editor.update(_ctrl(0x73));
      editor = next as demo.AdvancedEditorModel;
      final msg = await cmd?.execute();
      expect(msg, isNotNull);
      final (saved, _) = editor.update(msg!);
      editor = saved as demo.AdvancedEditorModel;

      expect(editor.isDirty, isFalse);
      expect(store.durableFor('demo.dart')?.document.text, editor.editor.value);
    },
  );

  test('recovery overlay restores a checkpointed document', () async {
    final store = MemoryEditorDocumentStore();
    final session = EditorPersistenceSession(
      documentId: 'demo.dart',
      store: store,
    );
    await session.checkpoint(
      TextDocument(text: 'recovered buffer'),
      revision: 4,
    );

    var editor = demo.AdvancedEditorModel.initial(
      store: store,
      documentId: 'demo.dart',
    );
    final snapshot = await store.readRecovery('demo.dart');
    var (next, _) = editor.update(demo.AdvancedEditorRecoveryMsg(snapshot));
    editor = next as demo.AdvancedEditorModel;
    expect(editor.view(), contains('Recover unsaved work'));

    (next, _) = editor.update(_key(tui.KeyType.runes, runes: [0x79]));
    editor = next as demo.AdvancedEditorModel;
    expect(editor.editor.value, 'recovered buffer');
    expect(editor.revision, 4);
  });
}
