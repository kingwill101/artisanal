import 'package:artisanal/style.dart' show Border, Layout;
import 'package:artisanal_widgets/src/widgets/layout/container.dart';
import 'package:artisanal_widgets/src/widgets/layout/geometry.dart';
import 'package:artisanal_widgets/src/widgets/layout/spacing.dart';
import 'package:artisanal_widgets/src/widgets/rendering/render_object.dart';
import 'package:test/test.dart';

void main() {
  test(
    'fractional parent bounds do not produce an inverted child interval',
    () {
      final child = _ProbeBox();
      final container = RenderContainer()..attach(child);
      container.layout(BoxConstraints.tight(const Size(0.6, 1)));
      expect(child.constraints.minWidth, 0.6);
      expect(child.constraints.maxWidth, 0.6);
    },
  );

  test('margins larger than the allocation cannot enlarge painted bounds', () {
    final child = _ProbeBox();
    final container = RenderContainer(margin: const EdgeInsets.all(3))
      ..attach(child);
    container.layout(BoxConstraints(maxWidth: 2, maxHeight: 2));
    expect(container.size, const Size(2, 2));
    expect(child.size, Size.zero);
    expect(Layout.getWidth(container.paint()), lessThanOrEqualTo(2));
    expect(Layout.getHeight(container.paint()), lessThanOrEqualTo(2));
  });

  test('clips explicit outer width before deriving child constraints', () {
    final child = _ProbeBox();
    final container = RenderContainer(
      width: 40,
      padding: const EdgeInsets.all(1),
      decoration: const BoxDecoration(border: Border.normal),
    )..attach(child);

    container.layout(BoxConstraints(maxWidth: 28, maxHeight: 10));

    expect(container.size.width, 28);
    expect(child.constraints.maxWidth, 24);
    expect(child.constraints.minWidth, 24);
  });

  test('margins are outside the inner child width', () {
    final child = _ProbeBox();
    final container = RenderContainer(
      width: 40,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 1),
    )..attach(child);

    container.layout(BoxConstraints(maxWidth: 28, maxHeight: 10));

    expect(container.size.width, 28);
    expect(child.constraints.maxWidth, 22);
    expect(child.constraints.minWidth, 22);
    expect(
      container.paint().split('\n').every((line) => line.length <= 28),
      isTrue,
    );
  });

  test('auto width uses the visible parent width for child constraints', () {
    final child = _ProbeBox();
    final container = RenderContainer(
      padding: const EdgeInsets.symmetric(horizontal: 2),
    )..attach(child);

    container.layout(BoxConstraints(maxWidth: 28, maxHeight: 10));

    expect(child.constraints.maxWidth, 24);
    expect(container.size.width, 28);
  });
}

final class _ProbeBox extends RenderBox {
  @override
  void layout(BoxConstraints constraints) {
    super.layout(constraints);
    size = constraints.constrain(const Size(100, 1));
  }

  @override
  String paint() => 'x' * size.width.toInt();
}
