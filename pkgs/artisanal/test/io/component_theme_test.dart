import 'package:artisanal/artisanal.dart';
import 'package:test/test.dart';

void main() {
  group('ComponentTheme', () {
    test('exposes the built-in palette presets', () {
      const presets = [
        ComponentTheme.dark,
        ComponentTheme.light,
        ComponentTheme.hacker,
        ComponentTheme.ocean,
        ComponentTheme.monokai,
        ComponentTheme.dracula,
        ComponentTheme.nord,
        ComponentTheme.solarizedDark,
        ComponentTheme.solarizedLight,
      ];

      expect(presets, hasLength(9));
      expect(presets.map((theme) => theme.palette), everyElement(isNotNull));
    });

    test('builds complete select and search style bundles', () {
      const theme = ComponentTheme.ocean;

      final select = theme.selectStyles();
      expect(select.title.getForeground, same(theme.palette.accentBold));
      expect(select.title.isBold, isTrue);
      expect(select.item.getForeground, same(theme.palette.text));
      expect(select.selectedItem.getForeground, same(theme.palette.accent));
      expect(select.cursorPrefix, '❯ ');

      final search = theme.searchStyles();
      expect(search.prompt.getForeground, same(theme.palette.info));
      expect(
        search.matchHighlight.getForeground,
        same(theme.palette.highlight),
      );
      expect(search.noResults.isItalic, isTrue);
    });

    test('keeps structural styling while applying semantic colors', () {
      const theme = ComponentTheme.dracula;

      final table = theme.dataTableStyles();
      expect(table.tableHeader.getForeground, same(theme.palette.accentBold));
      expect(table.tableHeader.isBold, isTrue);
      expect(table.tableHeader.getHorizontalPadding, 2);
      expect(table.tableCell.getHorizontalPadding, 2);

      final input = theme.textInputStyles();
      expect(
        input.focused.prompt.getForeground,
        same(theme.palette.accentBold),
      );
      expect(input.focused.selection.getBackground, same(theme.palette.accent));
      expect(input.cursor.color, same(theme.palette.accentBold));
    });

    test('covers password, number, suggest, and file picker styles', () {
      const theme = ComponentTheme.hacker;

      expect(
        theme.passwordStyles().error.getForeground,
        same(theme.palette.error),
      );
      expect(theme.numberInputStyles().error.isBold, isTrue);
      expect(
        theme.suggestStyles().highlighted.getForeground,
        same(theme.palette.accent),
      );
      expect(
        theme.filePickerStyles().directory.getForeground,
        same(theme.palette.accent),
      );
    });
  });

  test('Console accepts and exposes a component theme', () {
    final console = Console(
      componentTheme: ComponentTheme.nord,
      renderer: StringRenderer(colorProfile: ColorProfile.ascii),
      interactive: false,
      out: (_) {},
      err: (_) {},
    );

    expect(console.componentTheme, same(ComponentTheme.nord));

    console.componentTheme = ComponentTheme.light;
    expect(console.componentTheme, same(ComponentTheme.light));
  });
}
