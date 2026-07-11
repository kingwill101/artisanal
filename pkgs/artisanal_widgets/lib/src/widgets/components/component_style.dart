import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart' show Cmd;

import '../theme/theme.dart' show hasDarkBackground;

/// Callback that may return a command.
typedef CmdCallback = Cmd? Function();

/// Callback that receives a value and may return a command.
typedef ValueCmdCallback<T> = Cmd? Function(T value);

/// Copies [base] (or a fresh [Style]) and sets [Style.hasDarkBackground]
/// to the current terminal background state.
Style copyStyle(Style? base) {
  final style = (base ?? Style()).copy();
  style.hasDarkBackground = hasDarkBackground;
  return style;
}
