/// Textarea example ported from Bubble Tea.
library;

import 'package:artisanal/artisanal.dart' show Style, AnsiColor;
import 'package:artisanal/tui.dart' as tui;

class TextareaModel implements tui.Model {
  TextareaModel({required this.textarea, this.error, this.initCmd});

  factory TextareaModel.initial() {
    // #region textarea_usage
    final ta = tui.TextAreaModel(placeholder: 'Once upon a time...');
    final focusCmd = ta.focus();
    // #endregion
    return TextareaModel(textarea: ta, initCmd: focusCmd);
  }

  final tui.TextAreaModel textarea;
  final Object? error;
  final tui.Cmd? initCmd;

  @override
  tui.Cmd? init() => initCmd;

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    final cmds = <tui.Cmd>[];

    if (msg is tui.KeyMsg) {
      final key = msg.key;
      if (key.type == tui.KeyType.escape) {
        textarea.blur();
        return (copyWith(textarea: textarea), null);
      }
      if (key.ctrl && key.runes.isNotEmpty && key.runes.first == 0x63) {
        return (this, tui.Cmd.quit());
      }
      if (!textarea.focused) {
        final focusCmd = textarea.focus();
        if (focusCmd != null) cmds.add(focusCmd);
      }
    }

    final (newTa, cmd) = textarea.update(msg);
    if (cmd != null) cmds.add(cmd);

    return (copyWith(textarea: newTa), _batch(cmds));
  }

  tui.Cmd? _batch(List<tui.Cmd> cmds) =>
      cmds.isEmpty ? null : tui.Cmd.batch(cmds);

  TextareaModel copyWith({
    tui.TextAreaModel? textarea,
    Object? error,
    tui.Cmd? initCmd,
  }) {
    return TextareaModel(
      textarea: textarea ?? this.textarea,
      error: error ?? this.error,
      initCmd: initCmd ?? this.initCmd,
    );
  }

  @override
  String view() {
    final errLine = error == null
        ? ''
        : '${Style().foreground(const AnsiColor(196)).render('$error')}\n\n';
    return 'Tell me a story.\n\n${textarea.view()}\n\n$errLine(ctrl+c to quit)\n\n';
  }
}

Future<void> main() async {
  await tui.runProgram(
    TextareaModel.initial(),
    options: const tui.ProgramOptions(altScreen: false, hideCursor: false),
  );
}
