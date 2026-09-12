import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

class _SparseBox extends RenderBox {
  _SparseBox(this.intrinsic);

  final Size intrinsic;
  BoxConstraints? received;

  @override
  void layout(BoxConstraints constraints) {
    received = constraints;
    super.layout(constraints);
    size = constraints.constrain(intrinsic);
  }

  @override
  String paint() => 'x';
}

void main() {
  test('sparse child is padded before centering and hit testing', () {
    final child = _SparseBox(const Size(4, 2));
    final align = RenderAlign(alignment: Alignment.center, width: 8, height: 6)
      ..attach(child);

    align.layout(BoxConstraints());

    final lines = align.paint().split('\n');
    expect(lines[2][2], equals('x'));
    expect(child.offset, equals(const Offset(2, 2)));
    final hit = HitTestResult();
    expect(align.hitTest(hit, localX: 2, localY: 2), isTrue);
    expect(hit.path.first.renderObject, same(child));
  });

  test('empty child keeps the reserved Align size', () {
    final align = RenderAlign(width: 8, height: 6);
    align.layout(BoxConstraints());
    expect(align.size, equals(const Size(8, 6)));
    expect(align.paint().split('\n'), hasLength(6));
  });

  test('explicit dimensions are clamped to both parent bounds', () {
    final align = RenderAlign(width: 20, height: 20);
    align.layout(
      BoxConstraints(minWidth: 3, maxWidth: 10, minHeight: 2, maxHeight: 10),
    );
    expect(align.size, equals(const Size(10, 10)));

    final tight = RenderAlign(width: 2, height: 2);
    tight.layout(BoxConstraints.tight(const Size(10, 10)));
    expect(tight.size, equals(const Size(10, 10)));
  });

  test('explicit width constrains the child before it measures', () {
    final child = _SparseBox(const Size(20, 1));
    final align = RenderAlign(width: 10)..attach(child);
    align.layout(BoxConstraints(maxWidth: 80, maxHeight: 5));
    expect(child.received?.maxWidth, equals(10));
    expect(child.size.width, equals(10));
  });

  test('odd cell centering uses the same floor as paint placement', () {
    final child = _SparseBox(const Size(1, 1));
    final align = RenderAlign(alignment: Alignment.center, width: 4, height: 3)
      ..attach(child);
    align.layout(BoxConstraints());
    expect(child.offset, equals(const Offset(1, 1)));
    expect(align.paint().split('\n')[1][1], equals('x'));
  });

  test('standalone view centers a six by three allocation', () {
    final value = Align(
      width: 6,
      height: 3,
      alignment: Alignment.center,
      child: Text('x'),
    ).view();
    final content = value is String ? value : value.toString();
    final lines = content.split('\n');
    expect(lines[1][2], equals('x'));
  });

  test('mounted Align.view uses the laid out render path', () async {
    final tester = WidgetTester();
    addTearDown(tester.dispose);
    final widget = Align(
      width: 8,
      height: 4,
      alignment: Alignment.center,
      child: Text('x'),
    );
    await tester.pumpWidget(widget);
    final element = elementOf(widget);
    final render = element?.renderObject;
    expect(render, isA<RenderAlign>());
    expect(widget.view().toString(), equals(render!.paint()));
  });

  test('standalone view lays out wrapping content at the explicit width', () {
    final widget = Align(width: 10, child: Text('abcdefghijABCDEFGHIJ'));
    final standalone = widget.view().toString();
    final tree = ElementTree(widget);
    addTearDown(tree.unmount);
    expect(standalone, tree.render());
    expect(standalone.split('\n'), hasLength(2));
  });

  test('standalone view retains a sparse render child allocation', () {
    final output = Align(
      width: 8,
      height: 6,
      alignment: Alignment.center,
      child: _SparseWidget(),
    ).view().toString();
    expect(output.split('\n')[2][2], 'x');
  });

  test('mounted alignment and size updates move paint and hits together', () {
    final child = _SparseWidget();
    final tree = ElementTree(
      Align(key: const ValueKey('align'), width: 8, height: 6, child: child),
    );
    addTearDown(tree.unmount);
    tree.setRootConstraints(BoxConstraints(maxWidth: 10, maxHeight: 8));
    tree.render();
    final render = tree.root.renderObject!;
    final renderChild = render.children.single;
    expect(renderChild.offset, Offset.zero);

    tree.update(
      Align(
        key: const ValueKey('align'),
        width: 10,
        height: 8,
        alignment: Alignment.center,
        child: child,
      ),
    );
    final output = tree.render();
    expect(tree.root.renderObject, same(render));
    expect(render.children.single, same(renderChild));
    expect(render.size, const Size(10, 8));
    expect(renderChild.offset, const Offset(3, 3));
    expect(output.split('\n')[3][3], 'x');
    final hit = HitTestResult();
    expect(render.hitTest(hit, localX: 6, localY: 4), isTrue);
    expect(hit.path.first.renderObject, same(renderChild));
    expect(hit.path.first.localX, 3);
    expect(hit.path.first.localY, 1);
  });
}

class _SparseWidget extends LeafRenderObjectWidget {
  @override
  RenderObject createRenderObject() => _SparseBox(const Size(4, 2));
  @override
  Object view() => 'x';
}
