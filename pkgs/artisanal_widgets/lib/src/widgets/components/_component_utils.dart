part of 'components_widgets.dart';

typedef CmdCallback = Cmd? Function();
typedef ValueCmdCallback<T> = Cmd? Function(T value);

String _viewToString(Object value) {
  if (value is String) return value;
  if (value is View) return value.content;
  return value.toString();
}

String _renderWidget(Widget widget) {
  final element = elementOf(widget);
  if (element != null) return element.render();
  return _viewToString(widget.view());
}

int _edgeToInt(num? value) {
  if (value == null) return 0;
  if (value is double && value.isNaN) return 0;
  if (value is double && value.isInfinite) return 0;
  return math.max(0, value.round());
}

void _applyPadding(Style style, EdgeInsets? padding) {
  if (padding == null) return;
  style.padding(
    _edgeToInt(padding.top),
    _edgeToInt(padding.right),
    _edgeToInt(padding.bottom),
    _edgeToInt(padding.left),
  );
}

void _applyMargin(Style style, EdgeInsets? margin) {
  if (margin == null) return;
  style.margin(
    _edgeToInt(margin.top),
    _edgeToInt(margin.right),
    _edgeToInt(margin.bottom),
    _edgeToInt(margin.left),
  );
}

Style _copyStyle(Style? base) {
  final style = (base ?? Style()).copy();
  style.hasDarkBackground = hasDarkBackground;
  return style;
}

