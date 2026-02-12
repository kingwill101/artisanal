import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

void main() {
  group('render-object flattening guard', () {
    test('asserts when a plain Widget visual wrapper is used under Row', () {
      expect(
        () => ElementTree(
          Row(children: [_LegacyVisualWrapper(child: Text('wrapped'))]),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('allows intentional pass-through wrappers under render layouts', () {
      final tree = ElementTree(
        Row(children: [Flexible(child: Text('flex child'))]),
      );
      addTearDown(tree.unmount);

      expect(tree.render(), contains('flex child'));
    });
  });
}

class _LegacyVisualWrapper extends Widget {
  _LegacyVisualWrapper({required this.child});

  final Widget child;

  @override
  List<Widget> get children => [child];

  @override
  Object view() {
    return Frame(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: child,
    ).view();
  }
}
