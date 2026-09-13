import 'package:artisanal_widgets/src/widgets/core/element.dart';
import 'package:artisanal_widgets/widgets.dart' as w;
import 'package:test/test.dart';

void main() {
  test('child states dispose before their resource-owning parent', () {
    final events = <String>[];
    final tree = ElementTree(
      _Tracked(
        label: 'parent',
        events: events,
        child: _Tracked(label: 'child', events: events),
      ),
    );
    tree.render();
    tree.unmount();

    expect(events, ['child', 'parent']);
  });
}

class _Tracked extends w.StatefulWidget {
  _Tracked({required this.label, required this.events, this.child});
  final String label;
  final List<String> events;
  final w.Widget? child;

  @override
  w.State createState() => _TrackedState();
}

class _TrackedState extends w.State<_Tracked> {
  @override
  w.Widget build(w.BuildContext context) => widget.child ?? w.Text('leaf');

  @override
  void dispose() {
    widget.events.add(widget.label);
    super.dispose();
  }
}
