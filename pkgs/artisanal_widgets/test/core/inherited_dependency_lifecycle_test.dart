import 'package:artisanal_widgets/src/widgets/core/element.dart';
import 'package:artisanal_widgets/src/widgets/core/framework.dart'
    show BuildContext, InheritedWidget, StatelessWidget;
import 'package:artisanal_widgets/src/widgets/core/widget.dart';
import 'package:artisanal_widgets/src/widgets/layout/_layout_core.dart';
import 'package:test/test.dart';

class _ValueScope extends InheritedWidget {
  _ValueScope({required this.value, required super.child});

  final int value;

  @override
  bool updateShouldNotify(covariant _ValueScope oldWidget) {
    return value != oldWidget.value;
  }
}

class _Dependent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Register this element with the inherited provider, as FocusScope and
    // ThemeScope do for real input widgets.
    context.dependOnInheritedWidgetOfExactType<_ValueScope>();
    return Text('dependent');
  }
}

void main() {
  test('unmounted inherited dependents are not retained or redirtied', () {
    final owner = BuildOwner();
    final tree = ElementTree(
      _ValueScope(value: 0, child: _Dependent()),
      owner: owner,
    );
    tree.render();

    for (var cycle = 1; cycle <= 25; cycle++) {
      tree.update(_ValueScope(value: cycle - 1, child: _Dependent()));
      tree.render();
      // Remove the dependent in a separate update so the provider does not
      // notify it before its unmount has removed the reverse edge.
      tree.update(_ValueScope(value: cycle - 1, child: Text('closed')));
      tree.render();
      expect(owner.hasDirty, isFalse);

      // A later provider change must not reach the old element. Before the
      // lifecycle fix this left the detached element in BuildOwner._dirty.
      tree.update(_ValueScope(value: cycle, child: Text('closed')));
      tree.render();
      expect(owner.hasDirty, isFalse);
    }

    tree.unmount();
  });
}
