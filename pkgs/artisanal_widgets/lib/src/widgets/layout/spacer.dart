import '../rendering/render_object.dart';
import '../rendering/render_layout.dart';


class Spacer extends LeafRenderObjectWidget {
  Spacer({this.size = 1, this.fill = ' ', this.flex, super.key});

  final int size;
  final String fill;
  final int? flex;

  @override
  RenderObject createRenderObject() {
    return RenderText(text: _render());
  }

  @override
  void updateRenderObject(RenderObject renderObject) {
    (renderObject as RenderText).text = _render();
  }

  @override
  Object view() => _render();

  String _render() => fill * size;
}
