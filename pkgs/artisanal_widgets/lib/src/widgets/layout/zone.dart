import '../core/widget.dart';
import '../rendering/render_object.dart';
import '_layout_utils.dart';

class Zone extends SingleChildRenderObjectWidget {
  Zone({required Widget super.child, this.zoneId, super.key});

  final String? zoneId;

  @override
  Object view() => renderWidget(child!);

  @override
  RenderObject createRenderObject() {
    return RenderDelegateBox(_render);
  }

  @override
  void updateRenderObject(RenderObject renderObject) {
    (renderObject as RenderDelegateBox).paintDelegate = _render;
  }

  Object _render() => view();
}
