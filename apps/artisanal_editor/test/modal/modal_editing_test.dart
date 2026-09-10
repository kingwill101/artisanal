import 'package:artisanal/editor_core.dart' show EditorCommandIds;
import 'package:artisanal_editor/src/modal/modal_editing.dart';
import 'package:test/test.dart';

void main() {
  group('ModalEditingController', () {
    test('passes insert-mode text through and escapes to normal mode', () {
      final modal = ModalEditingController();

      expect(modal.handle('i').mode, ModalEditingMode.insert);
      expect(modal.handle('hello').handled, isFalse);
      expect(modal.handle('escape').mode, ModalEditingMode.normal);
    });

    test('resolves counted motions through Artisanal command IDs', () {
      final modal = ModalEditingController();

      modal.handle('3');
      final result = modal.handle('j');

      expect(result.commands, [
        for (var index = 0; index < 3; index++)
          const ModalCommandInvocation(EditorCommandIds.cursorDown),
      ]);
    });

    test('composes operator and motion counts', () {
      final modal = ModalEditingController();

      modal.handle('2');
      modal.handle('d');
      expect(modal.mode, ModalEditingMode.operatorPending);
      expect(modal.pendingKeys, '2d');

      modal.handle('3');
      final result = modal.handle('w');
      expect(result.commands, [
        for (var index = 0; index < 6; index++)
          const ModalCommandInvocation(EditorCommandIds.deleteWordRight),
      ]);
      expect(modal.mode, ModalEditingMode.normal);
    });

    test('supports visual deletion and change-to-insert', () {
      final modal = ModalEditingController();

      modal.handle('v');
      expect(
        modal.handle('l').commands.single.commandId,
        EditorCommandIds.selectRight,
      );
      expect(
        modal.handle('d').commands.single.commandId,
        EditorCommandIds.deleteRight,
      );
      expect(modal.mode, ModalEditingMode.normal);

      modal.handle('c');
      final change = modal.handle(r'$');
      expect(
        change.commands.single.commandId,
        EditorCommandIds.deleteLineRight,
      );
      expect(modal.mode, ModalEditingMode.insert);
    });

    test('leaves global shortcuts to the workbench', () {
      final modal = ModalEditingController();

      expect(modal.handle('ctrl+s').handled, isFalse);
      expect(
        modal.handle('ctrl+z').commands.single.commandId,
        EditorCommandIds.undo,
      );
      expect(
        modal.handle('ctrl+r').commands.single.commandId,
        EditorCommandIds.redo,
      );
    });

    test('owns undo in insert mode instead of leaking it to job control', () {
      final modal = ModalEditingController()..handle('i');

      final undo = modal.handle('ctrl+z');

      expect(undo.handled, isTrue);
      expect(undo.commands.single.commandId, EditorCommandIds.undo);
      expect(modal.mode, ModalEditingMode.insert);
    });
  });
}
