part of 'layout_widgets.dart';

class Zone extends SingleChildRenderObjectWidget {
  Zone({required Widget super.child, this.zoneId, super.key});

  final String? zoneId;

  @override
  Object view() {
    final content = _renderWidget(child!);
    final manager = globalZone;
    if (manager == null) return content;
    final resolvedId =
        zoneId ?? _keyToZoneId(key) ?? _keyToZoneId(child!.key) ?? child!.id;
    return manager.mark(resolvedId, content);
  }

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
