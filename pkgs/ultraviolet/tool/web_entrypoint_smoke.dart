import 'package:ultraviolet/core.dart' as core;
import 'package:ultraviolet/input.dart' as input;
import 'package:ultraviolet/rendering.dart' as rendering;
import 'package:ultraviolet/terminal.dart' as terminal;
import 'package:ultraviolet/ultraviolet.dart' as ultraviolet;
import 'package:ultraviolet/unicode.dart' as unicode;

void main() {
  final entrypointSymbols = <Object?>[
    core.Buffer,
    input.EventDecoder,
    rendering.UvTerminalRenderer,
    terminal.Terminal,
    terminal.enableWindowsVtInput,
    ultraviolet.UvStyle,
    unicode.stringWidth,
  ];
  if (entrypointSymbols.isEmpty) {
    throw StateError('Ultraviolet entrypoints were not loaded.');
  }
}
