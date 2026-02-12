part of 'components_widgets.dart';

typedef CmdCallback = Cmd? Function();
typedef ValueCmdCallback<T> = Cmd? Function(T value);

Style _copyStyle(Style? base) {
  final style = (base ?? Style()).copy();
  style.hasDarkBackground = hasDarkBackground;
  return style;
}
