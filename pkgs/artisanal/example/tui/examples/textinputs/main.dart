/// Multiple text inputs example ported from Bubble Tea.
library;

import 'package:artisanal/artisanal.dart' show Style, AnsiColor;
import 'package:artisanal/tui.dart' as tui;

class TextInputsModel implements tui.Model {
  TextInputsModel({
    required this.focusIndex,
    required this.inputs,
    this.cursorMode = tui.CursorMode.blink,
  });

  factory TextInputsModel.initial() {
    final inputs = <tui.TextInputModel>[
      tui.TextInputModel(placeholder: 'Nickname', charLimit: 32),
      tui.TextInputModel(placeholder: 'Email', charLimit: 64),
      tui.TextInputModel(
        placeholder: 'Password',
        echoMode: tui.EchoMode.password,
        echoCharacter: '•',
        charLimit: 32,
      ),
    ];

    // Focus first input
    final focusCmd = inputs[0].focus();
    final model = TextInputsModel(focusIndex: 0, inputs: inputs);
    if (focusCmd != null) {
      return model._withCmd(focusCmd);
    }
    return model;
  }

  final int focusIndex; // 0..inputs.length, where last index is submit button
  final List<tui.TextInputModel> inputs;
  final tui.CursorMode cursorMode;

  tui.Cmd? _pendingCmd;

  TextInputsModel _withCmd(tui.Cmd cmd) {
    final clone = TextInputsModel(
      focusIndex: focusIndex,
      inputs: inputs,
      cursorMode: cursorMode,
    );
    clone._pendingCmd = cmd;
    return clone;
  }

  @override
  tui.Cmd? init() => _pendingCmd;

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    if (msg is tui.KeyMsg) {
      final key = msg.key;

      if (key.matchesSingle(tui.CommonKeyBindings.quit)) {
        return (this, tui.Cmd.quit());
      }

      // ctrl+r cycle cursor mode
      if (key.ctrl && key.runes.isNotEmpty && key.runes.first == 0x72) {
        final modes = tui.CursorMode.values;
        final nextIdx = (modes.indexOf(cursorMode) + 1) % modes.length;
        final nextMode = modes[nextIdx];
        final cmds = <tui.Cmd>[];
        for (var i = 0; i < inputs.length; i++) {
          final input = inputs[i];
          final (newCursor, cmd) = input.cursor.setMode(nextMode);
          input.cursor = newCursor;
          if (cmd != null) cmds.add(cmd);
        }
        return (
          copyWith(cursorMode: nextMode),
          cmds.isNotEmpty ? tui.Cmd.batch(cmds) : null,
        );
      }

      final isNav =
          key.type == tui.KeyType.tab ||
          key.type == tui.KeyType.enter ||
          key.type == tui.KeyType.up ||
          key.type == tui.KeyType.down;
      if (isNav) {
        if (key.type == tui.KeyType.enter && focusIndex == inputs.length) {
          return (this, tui.Cmd.quit());
        }

        var idx = focusIndex;
        final shift = key.shift;
        if (key.type == tui.KeyType.up ||
            (key.type == tui.KeyType.tab && shift)) {
          idx--;
        } else {
          idx++;
        }
        if (idx > inputs.length) idx = 0;
        if (idx < 0) idx = inputs.length;

        return _refocus(idx);
      }
    }

    // Propagate to inputs
    final cmds = <tui.Cmd>[];
    for (var i = 0; i < inputs.length; i++) {
      final (newInput, cmd) = inputs[i].update(msg);
      inputs[i] = newInput;
      if (cmd != null) cmds.add(cmd);
    }

    return (this, cmds.isNotEmpty ? tui.Cmd.batch(cmds) : null);
  }

  (tui.Model, tui.Cmd?) _refocus(int newIndex) {
    final cmds = <tui.Cmd>[];
    for (var i = 0; i < inputs.length; i++) {
      final input = inputs[i];
      if (i == newIndex) {
        final cmd = input.focus();
        if (cmd != null) cmds.add(cmd);
      } else {
        input.blur();
      }
    }
    return (
      copyWith(focusIndex: newIndex),
      cmds.isNotEmpty ? tui.Cmd.batch(cmds) : null,
    );
  }

  TextInputsModel copyWith({
    int? focusIndex,
    List<tui.TextInputModel>? inputs,
    tui.CursorMode? cursorMode,
  }) {
    return TextInputsModel(
      focusIndex: focusIndex ?? this.focusIndex,
      inputs: inputs ?? this.inputs,
      cursorMode: cursorMode ?? this.cursorMode,
    );
  }

  @override
  String view() {
    final focusedStyle = Style().foreground(const AnsiColor(205));
    final blurredStyle = Style().foreground(const AnsiColor(240));
    final buffer = StringBuffer();
    for (var i = 0; i < inputs.length; i++) {
      final input = inputs[i];
      final isFocused = i == focusIndex;
      final rendered = (isFocused ? focusedStyle : blurredStyle).render(
        input.view(),
      );
      buffer.writeln(rendered);
    }

    final buttonFocused = focusIndex == inputs.length;
    final button = buttonFocused
        ? focusedStyle.render('[ Submit ]')
        : '[ ${blurredStyle.render('Submit')} ]';

    final help =
        blurredStyle.render('cursor mode is ') +
        Style().foreground(const AnsiColor(244)).render(cursorMode.name) +
        blurredStyle.render(' (ctrl+r to change style)');

    buffer.writeln('\n$button\n');
    buffer.write(help);
    return buffer.toString();
  }
}

Future<void> main() async {
  await tui.runProgram(
    TextInputsModel.initial(),
    options: const tui.ProgramOptions(altScreen: false, hideCursor: false),
  );
}
