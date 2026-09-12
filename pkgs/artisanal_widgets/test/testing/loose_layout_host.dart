import 'package:artisanal_widgets/widgets.dart';

/// Hosts an isolated component with bounded, loose viewport constraints.
///
/// Unlike Align, this test-only host does not pad the child's paint to the
/// viewport. Assertions can inspect the component's own output while the host
/// still obeys the application's tight root bounds. Tests of root expansion
/// must mount their widgets directly instead.
class LooseLayoutHost extends SingleChildRenderObjectWidget {
  LooseLayoutHost({required super.child});

  @override
  RenderObject createRenderObject() => _RenderLooseLayoutHost();

  @override
  Object view() => child?.view() ?? '';
}

class _RenderLooseLayoutHost extends RenderBox {
  RenderObject? get _child => children.isEmpty ? null : children.first;

  @override
  void layout(BoxConstraints constraints) {
    super.layout(constraints);
    _child?.layout(constraints.loosen());
    _child?.offset = Offset.zero;
    size = constraints.constrain(_child?.size ?? Size.zero);
  }

  @override
  String paint() => _child?.paint() ?? '';
}
