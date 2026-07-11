import 'package:artisanal/uv.dart' as uv;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:artisanal_widgets/testing.dart';

Future<void> main() async {
  final tester = WidgetTester(screenWidth: 80, screenHeight: 8);
  try {
    final theme = w.Theme.dark();

    final selectedTitleStyle = theme.bodyMedium.copy()
      ..foreground(theme.listRowSelectedForeground)
      ..bold();
    final selectedMetaStyle = theme.bodySmall.copy()
      ..foreground(theme.listRowSelectedMutedForeground);
    final selectedAuthorStyle = theme.bodySmall.copy()
      ..foreground(theme.listRowSelectedAccentForeground)
      ..bold();
    final selectedSeparatorStyle = theme.bodySmall.copy()
      ..foreground(theme.listRowSelectedSeparatorForeground);
    final accentStyle = theme.bodyMedium.copy()
      ..foreground(theme.listRowSelectedAccentForeground);

    await tester.pumpWidget(
      w.ThemeScope(
        theme: theme,
        child: w.Container(
          color: theme.background,
          child: w.Container(
            color: theme.listRowSelectedBackground,
            padding: const w.EdgeInsets.symmetric(horizontal: 1),
            child: w.Text.rich(
              w.TextSpan(
                children: [
                  w.TextSpan(text: '┃', style: accentStyle),
                  const w.TextSpan(text: ' '),
                  w.TextSpan(
                    text: '#63358 [vm/io] Range check SynchronousSocket_Wr...',
                    style: selectedTitleStyle,
                  ),
                  const w.TextSpan(text: '\n'),
                  w.TextSpan(text: '@LemonTeatw1', style: selectedAuthorStyle),
                  w.TextSpan(text: '  ·  ', style: selectedSeparatorStyle),
                  w.TextSpan(text: 'updated 3m ago', style: selectedMetaStyle),
                  w.TextSpan(text: '  ·  ', style: selectedSeparatorStyle),
                  w.TextSpan(text: '41c', style: selectedMetaStyle),
                  w.TextSpan(text: '  ·  ', style: selectedSeparatorStyle),
                  w.TextSpan(text: 'pending', style: selectedMetaStyle),
                ],
              ),
              softWrap: false,
            ),
          ),
        ),
      ),
    );

    final view = tester.view;
    print('VIEW');
    print(view);

    final screen = uv.ScreenBuffer(80, 8);
    final styled = uv.StyledString(view)..wrap = true;
    styled.draw(screen, screen.bounds());

    for (var y = 0; y < 2; y++) {
      final line = StringBuffer();
      for (var x = 0; x < 80; x++) {
        final cell = screen.cellAt(x, y);
        line.write(cell == null || cell.isZero ? ' ' : cell.content);
      }
      print('LINE $y: ${line.toString()}');
    }

    for (final x in [0, 1, 2, 3, 10, 20, 30, 40, 50, 60]) {
      final cell = screen.cellAt(x, 0);
      print(
        'row0 x=$x content=${cell?.content} style=${cell?.style} bg=${cell?.style.bg} fg=${cell?.style.fg} attrs=${cell?.style.attrs}',
      );
    }

    for (var x = 0; x < 70; x++) {
      final cell = screen.cellAt(x, 1);
      if (cell == null || cell.isZero) continue;
      if (cell.content == ' ') {
        print(
          'row1 space x=$x bg=${cell.style.bg} fg=${cell.style.fg} attrs=${cell.style.attrs}',
        );
      }
    }
  } finally {
    await tester.dispose();
  }
}
