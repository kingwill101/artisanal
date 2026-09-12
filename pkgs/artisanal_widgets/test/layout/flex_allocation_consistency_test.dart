import 'package:artisanal/style.dart' show Layout;
import 'package:artisanal_widgets/widgets.dart';
import 'package:test/test.dart';

void main() {
  test('mixed tight and loose row reserves the loose share', () {
    final tight = RenderText(text: 'ABCDE')
      ..parentData = FlexParentData(flex: 1, fit: RenderFlexFit.tight);
    final loose = RenderText(text: 'x')
      ..parentData = FlexParentData(flex: 1, fit: RenderFlexFit.loose);
    final row = RenderRow()
      ..attach(tight)
      ..attach(loose);
    row.layout(BoxConstraints(maxWidth: 10, maxHeight: 1));

    expect(tight.size.width, 5);
    expect(loose.constraints.maxWidth, 5);
    expect(loose.size.width, 1);
    expect(row.size.width, 6);
    expect(loose.offset.dx, 5);
    expect(Layout.getWidth(row.paint()), 6);
    expect(Layout.stripAnsi(row.paint()), 'ABCDEx');
  });

  test(
    'mixed tight and loose column uses measured sizes for offsets and paint',
    () {
      final tight = RenderText(text: 'A\nB\nC\nD\nE\nF')
        ..parentData = FlexParentData(flex: 1, fit: RenderFlexFit.tight);
      final loose = RenderText(text: 'x')
        ..parentData = FlexParentData(flex: 1, fit: RenderFlexFit.loose);
      final column = RenderColumn()
        ..attach(tight)
        ..attach(loose);
      column.layout(BoxConstraints(maxWidth: 1, maxHeight: 10));

      expect(tight.size.height, 5);
      expect(loose.constraints.maxHeight, 5);
      expect(loose.size.height, 1);
      expect(column.size.height, 6);
      expect(loose.offset.dy, 5);
      expect(Layout.getHeight(column.paint()), 6);
      expect(Layout.stripAnsi(column.paint()), 'A\nB\nC\nD\nE\nx');
    },
  );

  test('explicit row extent is applied before flex allocation', () {
    final left = RenderText(text: 'A')
      ..parentData = FlexParentData(flex: 1, fit: RenderFlexFit.tight);
    final right = RenderText(text: 'B')
      ..parentData = FlexParentData(flex: 2, fit: RenderFlexFit.tight);
    final row =
        RenderRow(mainAxisExtent: 20, mainAxisSize: RenderMainAxisSize.max)
          ..attach(left)
          ..attach(right);
    row.layout(BoxConstraints(maxWidth: 80, maxHeight: 24));

    expect(row.size.width, 20);
    expect(left.size.width, 7);
    expect(right.size.width, 13);
    expect(right.offset.dx, 7);
    expect(Layout.getWidth(row.paint()), 20);
  });

  test('explicit column extent is applied before flex allocation', () {
    final top = RenderText(text: 'A')
      ..parentData = FlexParentData(flex: 1, fit: RenderFlexFit.tight);
    final bottom = RenderText(text: 'B')
      ..parentData = FlexParentData(flex: 1, fit: RenderFlexFit.tight);
    final column =
        RenderColumn(mainAxisExtent: 10, mainAxisSize: RenderMainAxisSize.max)
          ..attach(top)
          ..attach(bottom);
    column.layout(BoxConstraints(maxWidth: 80, maxHeight: 24));

    expect(column.size.height, 10);
    expect(top.size.height, 5);
    expect(bottom.size.height, 5);
    expect(bottom.offset.dy, 5);
    expect(Layout.getHeight(column.paint()), 10);
  });
}
