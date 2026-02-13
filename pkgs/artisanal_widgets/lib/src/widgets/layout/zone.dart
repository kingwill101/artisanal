part of 'layout_widgets.dart';

class Zone extends SingleChildRenderObjectWidget {
  Zone({required Widget super.child, this.zoneId, super.key});

  final String? zoneId;

  @override
  Object view() => _renderWidget(child!);

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
