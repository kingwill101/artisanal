/// UV input decoder demo.
///
/// Run:
///   dart run packages/artisanal/example/tui/examples/uv-input/main.dart
///
/// Options:
///   --legacy-input     Use the legacy KeyParser (default is UV decoder)
///   --uv-renderer      Use the UV renderer (cell-buffer diff)
library;

import 'package:artisanal/artisanal.dart' show Style;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal/src/terminal/ansi.dart' as term_ansi;
import 'package:artisanal/src/unicode/grapheme.dart' as uni;

class _LogModel implements tui.Model {
  _LogModel({required this.useUvInput, required this.useUvRenderer});

  final bool useUvInput;
  final bool useUvRenderer;

  final List<String> _lines = <String>[];
  int _width = 80;
  int _height = 24;

  void _log(String line) {
    _lines.add(line);
    if (_lines.length > 200) _lines.removeAt(0);
  }

  @override
  tui.Cmd? init() {
    return tui.Cmd.batch([
      tui.Cmd.enableReportFocus(),
      tui.Cmd.enableBracketedPaste(),
      tui.Cmd.enableMouseCellMotion(),
      // Request a few common terminal reports. Not all terminals respond.
      tui.Cmd.requestTerminalColors(),
    ]);
  }

  // #region input_decoding_usage
  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    switch (msg) {
      case tui.WindowSizeMsg(:final width, :final height):
        _width = width;
        _height = height;
        _log('WindowSizeMsg(width: $width, height: $height)');
        return (this, null);

      case tui.FocusMsg(:final focused):
        _log('FocusMsg(focused: $focused)');
        return (this, null);

      case tui.PasteMsg(:final content):
        _log(
          'PasteMsg(${content.length} bytes): ${content.replaceAll('\n', r'\n')}',
        );
        return (this, null);

      case tui.MouseMsg(
        :final action,
        :final button,
        :final x,
        :final y,
        :final ctrl,
        :final alt,
        :final shift,
      ):
        _log(
          'MouseMsg(action: $action, button: $button, x: $x, y: $y, ctrl: $ctrl, alt: $alt, shift: $shift)',
        );
        return (this, null);

      case tui.KeyMsg(key: final key):
        if (key.matchesSingle(tui.CommonKeyBindings.quit)) {
          return (this, tui.Cmd.quit());
        }
        // #endregion
        // Convenience: press `d/b/f/c` to re-request reports.
        // Clipboard: `y` copy demo text, `p` request clipboard read (if supported).
        // Size: `s` request window-size report (CSI 18 t).
        if (key.type == tui.KeyType.runes && key.runes.isNotEmpty) {
          switch (key.runes.first) {
            case 0x64: // d
              return (
                this,
                tui.Cmd.writeRaw(term_ansi.Ansi.requestPrimaryDeviceAttributes),
              );
            case 0x62: // b
              return (this, tui.Cmd.requestBackgroundColorReport());
            case 0x66: // f
              return (this, tui.Cmd.requestTerminalColors());
            case 0x63: // c
              return (this, tui.Cmd.requestTerminalColors());
            case 0x79: // y
              return (this, tui.Cmd.setClipboard('uv-input demo: hello'));
            case 0x70: // p
              return (this, tui.Cmd.requestClipboard());
            case 0x73: // s
              return (this, tui.Cmd.requestWindowSizeReport());
          }
        }
        _log('KeyMsg($key)');
        return (this, null);

      case tui.ClipboardMsg(:final selection, :final content):
        _log(
          'ClipboardMsg(selection: $selection, ${content.length} bytes): ${content.replaceAll('\n', r'\n')}',
        );
        return (this, null);

      case tui.BackgroundColorMsg(:final hex):
        _log('BackgroundColorMsg(hex: $hex)');
        return (this, null);

      case tui.ForegroundColorMsg(:final hex):
        _log('ForegroundColorMsg(hex: $hex)');
        return (this, null);

      case tui.CursorColorMsg(:final hex):
        _log('CursorColorMsg(hex: $hex)');
        return (this, null);

      case tui.UvEventMsg(:final event):
        _log('UvEventMsg(${event.runtimeType}): $event');
        return (this, null);
    }

    return (this, null);
  }

  @override
  String view() {
    final title = Style().bold().render('UV Input Decoder Demo');
    final mode =
        'input=${useUvInput ? 'uv' : 'legacy'}  renderer=${useUvRenderer ? 'uv' : 'default'}';
    final help =
        'Press `q` to quit. Try keys/mouse/paste/focus/resize. Press `d/b/f/c` reports, `y/p` clipboard, `s` size.';

    final header = '$title\n$mode\n$help\n';

    final maxBody = (_height - 5).clamp(0, 10_000);
    final bodyLines = _lines.length <= maxBody
        ? _lines
        : _lines.sublist(_lines.length - maxBody);

    // Simple clipping to avoid huge lines.
    final clipped = bodyLines.map((l) => _clipToWidth(l, _width)).join('\n');

    return '$header\n$clipped';
  }
}

String _clipToWidth(String s, int maxWidth) {
  if (maxWidth <= 0) return '';
  if (Style.visibleLength(s) <= maxWidth) return s;

  var w = 0;
  final out = StringBuffer();
  for (final g in uni.graphemes(s)) {
    final gw = Style.visibleLength(g);
    if (w + gw > maxWidth) break;
    out.write(g);
    w += gw;
  }
  return out.toString();
}

void main(List<String> args) async {
  if (args.contains('-h') || args.contains('--help')) {
    tui.Cmd.println(''' // tui:allow-stdout
UV input decoder demo

Usage:
  dart run packages/artisanal/example/tui/examples/uv-input/main.dart [options]

Options:
  --legacy-input     Use legacy KeyParser input
  --uv-renderer      Use UV renderer (cell-buffer diff)
''');
    return;
  }

  final legacy = args.contains('--legacy-input');
  final uvRenderer = args.contains('--uv-renderer');

  await tui.runProgram(
    _LogModel(useUvInput: !legacy, useUvRenderer: uvRenderer),
    options: tui.ProgramOptions(
      altScreen: true,
      mouse: true,
      bracketedPaste: true,
      useUltravioletInputDecoder: !legacy,
      useUltravioletRenderer: uvRenderer,
    ),
  );
}
