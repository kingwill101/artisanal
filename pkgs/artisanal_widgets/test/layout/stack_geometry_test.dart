import 'package:artisanal/style.dart' show Layout;
import 'package:artisanal_widgets/testing.dart';
import 'package:artisanal_widgets/widgets.dart';
import 'package:test/test.dart';

import '../testing/loose_layout_host.dart';

void main() {
  test('expanded children use the constrained explicit stack size', () {
    final child = RenderText(text: 'x');
    final stack = RenderStack(width: 40, height: 10, fit: StackFit.expand)
      ..attach(child);
    stack.layout(BoxConstraints(maxWidth: 80, maxHeight: 30));
    expect(stack.size, const Size(40, 10));
    expect(child.constraints, BoxConstraints.tight(const Size(40, 10)));
    stack.layout(BoxConstraints(maxWidth: 28, maxHeight: 6));
    expect(stack.size, const Size(28, 6));
    expect(child.constraints, BoxConstraints.tight(const Size(28, 6)));
    expect(Layout.getWidth(stack.paint()), 28);
    expect(Layout.getHeight(stack.paint()), 6);
  });

  test('opposite insets stretch against the final allocated size', () {
    final child = RenderText(
      text: 'x',
    )..parentData = const StackParentData(left: 2, right: 3, top: 1, bottom: 2);
    final stack = RenderStack(width: 40, height: 10)..attach(child);
    stack.layout(BoxConstraints(maxWidth: 28, maxHeight: 6));
    expect(child.size, const Size(23, 3));
    expect(child.offset, const Offset(2, 1));
    stack.layout(BoxConstraints(maxWidth: 12, maxHeight: 4));
    expect(child.size, const Size(7, 1));
    expect(child.offset, const Offset(2, 1));
  });

  test('negative left is preserved and paint agrees with clipped hits', () {
    final child = RenderText(text: 'ABCDE', softWrap: false)
      ..parentData = const StackParentData(
        left: -2,
        top: 0,
        width: 5,
        height: 1,
      );
    final stack = RenderStack(width: 3, height: 1)..attach(child);
    stack.layout(BoxConstraints(maxWidth: 10, maxHeight: 5));
    expect(child.offset, const Offset(-2, 0));
    expect(Layout.stripAnsi(stack.paint()), 'CDE');

    final inside = HitTestResult();
    expect(stack.hitTest(inside, localX: 0, localY: 0), isTrue);
    expect(inside.path.first.renderObject, same(child));
    expect(inside.path.first.localX, 2);
    final outside = HitTestResult();
    expect(stack.hitTest(outside, localX: 3, localY: 0), isFalse);
    expect(outside.path, isEmpty);
  });

  test('negative right and top insets clip without relocating the child', () {
    final right = RenderText(text: 'XY', softWrap: false)
      ..parentData = const StackParentData(
        right: -1,
        top: 0,
        width: 2,
        height: 1,
      );
    final horizontal = RenderStack(width: 3, height: 1)..attach(right);
    horizontal.layout(BoxConstraints(maxWidth: 10, maxHeight: 5));
    expect(right.offset, const Offset(2, 0));
    expect(Layout.stripAnsi(horizontal.paint()), '  X');

    final top = RenderText(text: 'A\nB\nC')
      ..parentData = const StackParentData(
        left: 0,
        top: -1,
        width: 1,
        height: 3,
      );
    final vertical = RenderStack(width: 1, height: 2)..attach(top);
    vertical.layout(BoxConstraints(maxWidth: 10, maxHeight: 5));
    expect(top.offset, const Offset(0, -1));
    expect(Layout.stripAnsi(vertical.paint()), 'B\nC');
  });

  test('passthrough retains parent minimum constraints', () {
    final child = RenderText(text: 'x');
    final stack = RenderStack(fit: StackFit.passthrough)..attach(child);
    final constraints = BoxConstraints(
      minWidth: 2,
      maxWidth: 8,
      minHeight: 2,
      maxHeight: 4,
    );
    stack.layout(constraints);
    expect(child.constraints, constraints);
  });

  test(
    'negative opposite insets enlarge the child but not the clip region',
    () {
      final child = RenderText(text: 'ABCDEF\nGHIJKL\nMNOPQR\nSTUVWX')
        ..parentData = const StackParentData(
          left: -1,
          right: -1,
          top: -1,
          bottom: -1,
        );
      final stack = RenderStack(width: 4, height: 2)..attach(child);
      stack.layout(BoxConstraints(maxWidth: 10, maxHeight: 5));
      expect(child.size, const Size(6, 4));
      expect(child.offset, const Offset(-1, -1));
      expect(Layout.stripAnsi(stack.paint()), 'HIJK\nNOPQ');
      final hit = HitTestResult();
      expect(stack.hitTest(hit, localX: 0, localY: 0), isTrue);
      expect(hit.path.first.localX, 1);
      expect(hit.path.first.localY, 1);
    },
  );

  test('unsupported visible overflow fails explicitly', () {
    expect(
      () => Stack(clipBehavior: Overflow.visible, children: []),
      throwsUnsupportedError,
    );
    expect(
      () => RenderStack(clipBehavior: Overflow.visible),
      throwsUnsupportedError,
    );
    final stack = RenderStack();
    expect(() => stack.clipBehavior = Overflow.visible, throwsUnsupportedError);
    expect(stack.clipBehavior, Overflow.clip);
  });

  test('only visible clipped cells can receive widget taps', () async {
    final tester = WidgetTester();
    addTearDown(tester.dispose);
    var taps = 0;
    await tester.pumpWidget(
      LooseLayoutHost(
        child: Stack(
          width: 4,
          height: 1,
          children: [
            Positioned(
              left: -2,
              top: 0,
              width: 6,
              height: 1,
              child: GestureDetector(
                onTap: () {
                  taps++;
                  return null;
                },
                child: Text('ABCDEF', softWrap: false),
              ),
            ),
          ],
        ),
      ),
    );
    expect(Layout.stripAnsi(tester.view), 'CDEF');
    tester.tapAt(0, 0);
    expect(taps, 1);
    tester.tapAt(4, 0);
    expect(taps, 1);
  });
}
