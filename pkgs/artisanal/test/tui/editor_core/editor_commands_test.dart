import 'package:artisanal/editor_core.dart';
import 'package:test/test.dart';

final class _Target {
  var value = 0;
  var editable = true;
}

void main() {
  group('EditorCommandRegistry', () {
    test('dispatches enabled commands and reports every outcome', () {
      final target = _Target();
      final registry = EditorCommandRegistry<_Target>()
        ..register(
          EditorCommand(
            id: 'editor.increment',
            label: 'Increment',
            isEnabled: (target) => target.editable,
            execute: (target) {
              target.value++;
              return true;
            },
          ),
        );

      expect(
        registry.dispatch('missing', target),
        EditorCommandDispatchResult.notFound,
      );
      expect(
        registry.dispatch('editor.increment', target),
        EditorCommandDispatchResult.handled,
      );
      expect(target.value, 1);

      target.editable = false;
      expect(
        registry.dispatch('editor.increment', target),
        EditorCommandDispatchResult.disabled,
      );
      expect(target.value, 1);
    });

    test('dispatches an optional argument to executeWith', () {
      final target = _Target();
      final registry = EditorCommandRegistry<_Target>()
        ..register(
          EditorCommand(
            id: 'editor.insert',
            label: 'Insert',
            execute: (_) => false,
            executeWith: (target, argument) {
              if (argument is! int) return false;
              target.value = argument;
              return true;
            },
          ),
        );

      expect(
        registry.dispatch('editor.insert', target),
        EditorCommandDispatchResult.noChange,
      );
      expect(
        registry.dispatch('editor.insert', target, argument: 9),
        EditorCommandDispatchResult.handled,
      );
      expect(target.value, 9);
    });

    test(
      'rejects accidental duplicate IDs and permits explicit replacement',
      () {
        final registry = EditorCommandRegistry<_Target>();
        final first = EditorCommand<_Target>(
          id: 'editor.test',
          label: 'First',
          execute: (_) => false,
        );
        final second = EditorCommand<_Target>(
          id: 'editor.test',
          label: 'Second',
          execute: (_) => true,
        );

        registry.register(first);
        expect(() => registry.register(second), throwsStateError);
        registry.register(second, replace: true);

        expect(registry['editor.test']?.label, 'Second');
      },
    );
  });

  group('EditorKeymap', () {
    test('resolves the highest-priority matching contextual binding', () {
      final keymap = EditorKeymap()
        ..bind(
          const EditorKeyBinding(
            chord: 'ctrl+k',
            commandId: 'editor.deleteLine',
          ),
        )
        ..bind(
          const EditorKeyBinding(
            chord: 'ctrl+k',
            commandId: 'editor.showReferences',
            when: 'editorHasSelection',
          ),
        );

      expect(
        keymap.resolve('ctrl+k', evaluateWhen: (value) => value == 'no'),
        'editor.deleteLine',
      );
      expect(
        keymap.resolve(
          'ctrl+k',
          evaluateWhen: (value) => value == 'editorHasSelection',
        ),
        'editor.showReferences',
      );
    });

    test('detects binding conflicts in the same context', () {
      final keymap = EditorKeymap()
        ..bind(
          const EditorKeyBinding(chord: 'ctrl+z', commandId: 'editor.undo'),
        );

      expect(
        () => keymap.bind(
          const EditorKeyBinding(chord: 'ctrl+z', commandId: 'editor.other'),
        ),
        throwsStateError,
      );
    });
  });

  group('EditorCommandPalette', () {
    test('filters enabled commands and executes the selected match', () {
      final target = _Target();
      final registry = EditorCommandRegistry<_Target>()
        ..registerAll([
          EditorCommand(
            id: 'editor.increment',
            label: 'Increment Value',
            category: 'Edit',
            execute: (target) {
              target.value++;
              return true;
            },
          ),
          EditorCommand(
            id: 'editor.disabled',
            label: 'Increment Disabled',
            isEnabled: (_) => false,
            execute: (_) => true,
          ),
          EditorCommand(
            id: 'editor.reset',
            label: 'Reset Value',
            execute: (target) {
              target.value = 0;
              return true;
            },
          ),
        ]);
      final palette = EditorCommandPalette(registry: registry, target: target)
        ..open(query: 'inc');

      expect(palette.visibleCommands.map((command) => command.id), [
        'editor.increment',
      ]);
      expect(palette.executeSelected(), EditorCommandDispatchResult.handled);
      expect(target.value, 1);
      expect(palette.isOpen, isFalse);
    });

    test(
      'wraps selection and preserves registration order for equal matches',
      () {
        final target = _Target();
        final registry = EditorCommandRegistry<_Target>()
          ..registerAll([
            EditorCommand(
              id: 'editor.alpha',
              label: 'Alpha',
              execute: (_) => false,
            ),
            EditorCommand(
              id: 'editor.beta',
              label: 'Beta',
              execute: (_) => false,
            ),
          ]);
        final palette = EditorCommandPalette(registry: registry, target: target)
          ..open();

        expect(palette.selectedCommand?.id, 'editor.alpha');
        expect(palette.moveSelection(-1), isTrue);
        expect(palette.selectedCommand?.id, 'editor.beta');
        palette.updateQuery('zzz');
        expect(palette.selectedCommand, isNull);
        expect(palette.executeSelected(), EditorCommandDispatchResult.noChange);
      },
    );

    test(
      'maps filtered items by stable command id rather than object identity',
      () {
        final target = _Target();
        final registry = EditorCommandRegistry<_Target>()
          ..registerAll([
            EditorCommand(
              id: 'editor.alpha',
              label: 'Alpha',
              execute: (_) => false,
            ),
            EditorCommand(
              id: 'editor.beta',
              label: 'Beta',
              execute: (_) => true,
            ),
          ]);
        final palette = EditorCommandPalette(registry: registry, target: target)
          ..open(query: 'bet');

        expect(palette.visibleCommands.single.id, 'editor.beta');
        expect(palette.visibleCommands.single.id, 'editor.beta');
        expect(palette.controller.filteredItems.single.id, 'editor.beta');
      },
    );
  });
}
