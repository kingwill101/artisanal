/// Pipe example ported from Bubble Tea.
library;

import 'dart:convert';
import 'dart:io' as io;

import 'package:artisanal/artisanal.dart' show Style, AnsiColor;
import 'package:artisanal/tui.dart' as tui;

class PipeModel implements tui.Model {
  PipeModel({required this.initial, tui.TextInputModel? input})
    : input =
          input ??
          (tui.TextInputModel(
            prompt: '',
            cursor: tui.CursorModel(
              // Match lipgloss color 63
              char: ' ',
              blinkSpeed: const Duration(milliseconds: 530),
            ),
            width: 48,
          )..value = initial);

  final String initial;
  final tui.TextInputModel input;

  @override
  tui.Cmd? init() {
    return input.focus();
  }

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    if (msg is tui.InterruptMsg) {
      return (this, tui.Cmd.quit());
    }

    if (msg is tui.KeyMsg) {
      switch (msg.key.type) {
        case tui.KeyType.enter:
        case tui.KeyType.escape:
          return (this, tui.Cmd.quit());
        default:
          if (msg.key.isCtrlC) {
            return (this, tui.Cmd.quit());
          }
      }
    }

    final (newInput, cmd) = input.update(msg);
    return (PipeModel(initial: initial, input: newInput), cmd);
  }

  @override
  String view() {
    final info = Style()
        .foreground(const AnsiColor(63))
        .render('Press Ctrl+C or Enter to exit');
    return '\nYou piped in: ${input.view()}\n\n$info';
  }
}

Future<void> main() async {
  final isPiped = !io.stdin.hasTerminal;
  final data = isPiped
      ? await utf8.decoder.bind(tui.sharedStdinStream).join()
      : '';

  if (!isPiped || data.isEmpty) {
    io.stderr.writeln('Try piping in some text.'); // tui:allow-stdout
    io.exit(1);
  }

  await tui.runProgram(
    PipeModel(initial: data.trim()),
    options: const tui.ProgramOptions(altScreen: false, hideCursor: false),
  );
}
