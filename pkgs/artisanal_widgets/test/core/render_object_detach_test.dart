import 'package:artisanal_widgets/src/widgets/rendering/render_object.dart';
import 'package:test/test.dart';

void main() {
  test('detachAll removes many children without disturbing retained order', () {
    final parent = _TestRenderBox();
    final children = [
      _TestRenderBox(),
      _TestRenderBox(),
      _TestRenderBox(),
      _TestRenderBox(),
      _TestRenderBox(),
    ];

    for (final child in children) {
      parent.attach(child);
    }

    parent.detachAll([children[1], children[3]]);

    expect(parent.children, [children[0], children[2], children[4]]);
    expect(children[1].parent, isNull);
    expect(children[3].parent, isNull);
    expect(children[0].parent, same(parent));
    expect(children[2].parent, same(parent));
    expect(children[4].parent, same(parent));
  });

  test('detach skips children that are no longer attached to this parent', () {
    final parent = _TestRenderBox();
    final child = _TestRenderBox();

    parent.attach(child);
    parent.detachAll([child]);
    parent.detach(child);

    expect(parent.children, isEmpty);
    expect(child.parent, isNull);
  });
}

final class _TestRenderBox extends RenderBox {
  @override
  String paint() => '';
}
