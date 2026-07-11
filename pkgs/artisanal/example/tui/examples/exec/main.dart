/// Exec process example ported from Bubble Tea.
library;

import 'dart:io' as io;

import 'package:artisanal/tui.dart' as tui;

class EditorFinishedMsg extends tui.Msg {
  const EditorFinishedMsg(this.result);
  final tui.ExecResult result;
}

class ExecModel implements tui.Model {
  const ExecModel({this.altScreenActive = false, this.error});

  final bool altScreenActive;
  final String? error;

  @override
  tui.Cmd? init() => null;

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    switch (msg) {
      case tui.KeyMsg(key: final key):
        final rune = key.runes.isNotEmpty ? key.runes.first : -1;
        // toggle alt screen
        if (rune == 0x61 && key.type == tui.KeyType.runes) {
          final nextAlt = !altScreenActive;
          return (
            copyWith(altScreenActive: nextAlt),
            nextAlt ? tui.Cmd.enterAltScreen() : tui.Cmd.exitAltScreen(),
          );
        }
        // open editor
        if (rune == 0x65 && key.type == tui.KeyType.runes) {
          return (this, _openEditor());
        }
        // quit
        if ((key.ctrl && rune == 0x63) || rune == 0x71) {
          return (this, tui.Cmd.quit());
        }
      case EditorFinishedMsg(:final result):
        if (!result.success) {
          return (
            copyWith(
              error: result.stderr.isNotEmpty
                  ? result.stderr
                  : 'exit code ${result.exitCode}',
            ),
            tui.Cmd.quit(),
          );
        }
    }
    return (this, null);
  }

  tui.Cmd _openEditor() {
    final editor =
        io.Platform.environment['EDITOR'] ??
        io.Platform.environment['VISUAL'] ??
        (io.Platform.isWindows ? 'notepad' : 'vim');
    return tui.Cmd.exec(editor, const [], onComplete: EditorFinishedMsg.new);
  }

  ExecModel copyWith({bool? altScreenActive, String? error}) {
    return ExecModel(
      altScreenActive: altScreenActive ?? this.altScreenActive,
      error: error ?? this.error,
    );
  }

  @override
  String view() {
    if (error != null) {
      return 'Error: $error\n';
    }
    return "Press 'e' to open your EDITOR.\n"
        "Press 'a' to toggle the altscreen\n"
        "Press 'q' to quit.\n";
  }
}

Future<void> main() async {
  await tui.runProgram(
    const ExecModel(),
    options: const tui.ProgramOptions(altScreen: false, hideCursor: false),
  );
}
