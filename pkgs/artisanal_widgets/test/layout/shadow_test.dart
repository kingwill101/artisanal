import 'package:artisanal/uv.dart';
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

final class _ReplaceFilter extends BufferFilter {
  @override
  void apply(Buffer source, Buffer target, double dt) {
    for (var y = 0; y < source.height(); y++) {
      for (var x = 0; x < source.width(); x++) {
        final cell = source.cellAt(x, y);
        target.setCell(
          x,
          y,
          cell == null || cell.isEmpty
              ? cell
              : Cell(content: 'Z', style: cell.style),
        );
      }
    }
  }
}

void main() {
  test('Shadow expands the child and paints the selected shade', () async {
    final tester = WidgetTester(screenWidth: 20, screenHeight: 10);
    addTearDown(tester.dispose);

    await tester.pumpWidget(
      Shadow(
        offsetX: 2,
        offsetY: 1,
        shadowStyle: TerminalShadowStyle.light,
        child: Text('AB'),
      ),
    );

    final lines = tester.view.split('\n');
    expect(lines.first, contains('AB'));
    expect(tester.view, contains('░'));
  });

  test('Shadow supports negative offsets', () async {
    final tester = WidgetTester(screenWidth: 20, screenHeight: 10);
    addTearDown(tester.dispose);

    await tester.pumpWidget(
      Shadow(
        offsetX: -1,
        offsetY: -1,
        shadowStyle: TerminalShadowStyle.dark,
        child: Text('X'),
      ),
    );

    expect(tester.view, contains('▓'));
    expect(tester.view, contains('X'));
  });

  test('CellFilter applies UV buffer filters to a widget subtree', () async {
    final tester = WidgetTester(screenWidth: 20, screenHeight: 10);
    addTearDown(tester.dispose);

    await tester.pumpWidget(
      CellFilter(filters: [_ReplaceFilter()], child: Text('ABC')),
    );

    expect(tester.view, contains('ZZZ'));
    expect(tester.view, isNot(contains('ABC')));
  });
}
