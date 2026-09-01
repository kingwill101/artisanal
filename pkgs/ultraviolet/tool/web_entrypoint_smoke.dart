import 'package:ultraviolet/core.dart' as core;
import 'package:ultraviolet/input.dart' as input;
import 'package:ultraviolet/rendering.dart' as rendering;
import 'package:ultraviolet/terminal.dart' as terminal;
import 'package:ultraviolet/ultraviolet.dart' as ultraviolet;
import 'package:ultraviolet/unicode.dart' as unicode;
import 'package:ultraviolet/uv.dart' as uv;

void main() {
  final entrypointSymbols = <Object?>[
    core.Buffer,
    input.EventDecoder,
    rendering.UvTerminalRenderer,
    terminal.Terminal,
    terminal.enableWindowsVtInput,
    ultraviolet.UvStyle,
    unicode.stringWidth,
    uv.parsePrimaryDevAttrs,
    uv.Win32ControlKeyState,
  ];
  if (entrypointSymbols.isEmpty) {
    throw StateError('Ultraviolet entrypoints were not loaded.');
  }
}
