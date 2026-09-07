import 'package:artisanal/bubbles.dart';
import 'package:test/test.dart';

void main() {
  test('shared foundation ranks labels, metadata, and typo matches', () {
    const items = [
      CommandPaletteItem(label: 'Open', group: 'File'),
      CommandPaletteItem(
        label: 'Save Document',
        description: 'Write changes',
        tags: ['persist'],
      ),
      CommandPaletteItem(label: 'Disabled', enabled: false),
    ];

    expect(matchCommandPaletteItems(items, 'open').first.item.label, 'Open');
    expect(
      matchCommandPaletteItems(items, 'write').first.item.label,
      'Save Document',
    );
    expect(
      matchCommandPaletteItems(items, 'persist').first.item.label,
      'Save Document',
    );
    expect(matchCommandPaletteItems(items, 'opne').first.item.label, 'Open');
    expect(
      matchCommandPaletteItems(items, '').map((match) => match.item.label),
      ['Open', 'Save Document'],
    );
  });

  test('shared controller filters items and wraps selection', () {
    final controller = CommandPaletteController(
      items: const [
        CommandPaletteItem(label: 'Open File', tags: ['load']),
        CommandPaletteItem(label: 'Save File', tags: ['persist']),
        CommandPaletteItem(label: 'Disabled', enabled: false),
      ],
    );

    controller.updateQuery('save');
    expect(controller.filteredItems.single.label, 'Save File');
    expect(controller.selectedItem?.label, 'Save File');
    controller.updateQuery('');
    expect(controller.moveSelection(-1), isTrue);
    expect(controller.selectedItem?.label, 'Save File');
    final window = controller.visibleWindow(viewportSize: 1);
    expect((window.start, window.end), (1, 2));
    expect(controller.visibleItems(viewportSize: 1).single.label, 'Save File');
  });

  test('controller filtered items match matchCommandPaletteItems order', () {
    const items = [
      CommandPaletteItem(id: 'folder', label: 'Open Folder'),
      CommandPaletteItem(id: 'open', label: 'Open'),
      CommandPaletteItem(id: 'close', label: 'Close'),
    ];
    final controller = CommandPaletteController(items: items)
      ..updateQuery('open');

    expect(
      controller.filteredItems.map((item) => item.id),
      matchCommandPaletteItems(items, 'open').map((match) => match.item.id),
    );
    expect(
      controller.matches.first.evidence,
      containsPair('label:exact', 10000),
    );
  });

  test('controller preserves stable selection when items are rebuilt', () {
    final controller = CommandPaletteController(
      items: const [
        CommandPaletteItem(id: 'open', label: 'Open'),
        CommandPaletteItem(id: 'save', label: 'Save'),
      ],
    )..selectIndex(1);

    controller.updateItems(const [
      CommandPaletteItem(id: 'open', label: 'Open file'),
      CommandPaletteItem(id: 'save', label: 'Save file'),
    ]);

    expect(controller.selectedItem?.id, 'save');
  });

  test('keeps the selected command inside its rendered window', () {
    final target = _Target();
    final registry = EditorCommandRegistry<_Target>()
      ..registerAll([
        for (var index = 0; index < 12; index++)
          EditorCommand(
            id: 'command.$index',
            label: 'Command $index',
            execute: (_) => true,
          ),
      ]);
    final palette = EditorCommandPalette(registry: registry, target: target)
      ..open();
    for (var index = 0; index < 9; index++) {
      palette.moveSelection(1);
    }
    final component = CommandPaletteComponent(
      palette: palette,
      viewportSize: 5,
    );

    expect(component.visibleWindow.map((command) => command.label), [
      'Command 7',
      'Command 8',
      'Command 9',
      'Command 10',
      'Command 11',
    ]);
    final rendered = component.render(
      List<String>.filled(24, '').join('\n'),
      screenWidth: 80,
      screenHeight: 24,
    );
    expect(rendered, contains('❯ Command 9'));
    expect(rendered, contains('10/12'));
    expect(rendered, isNot(contains('Command 0')));
  });

  test('returns the base view unchanged while closed', () {
    final target = _Target();
    final palette = EditorCommandPalette(
      registry: EditorCommandRegistry<_Target>(),
      target: target,
    );
    final component = CommandPaletteComponent(palette: palette);

    expect(component.render('base', screenWidth: 80, screenHeight: 24), 'base');
  });
}

final class _Target {}
