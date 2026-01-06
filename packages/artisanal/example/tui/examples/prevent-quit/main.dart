/// Prevent-quit example using ProgramOptions.filter.
library;

import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart';
import 'package:artisanal/tui.dart' as tui;

class PreventQuitKeys {
  PreventQuitKeys()
    : save = tui.KeyBinding.withHelp(['ctrl+s'], 'ctrl+s', 'save'),
      quit = tui.KeyBinding.withHelp(['esc', 'ctrl+c'], 'esc', 'quit');

  final tui.KeyBinding save;
  final tui.KeyBinding quit;
}

class PreventQuitModel implements tui.Model {
  PreventQuitModel({
    tui.TextAreaModel? textarea,
    PreventQuitKeys? keys,
    this.saveText = '',
    this.hasChanges = false,
    this.quitting = false,
  })
    : textarea =
          textarea ?? tui.TextAreaModel(placeholder: 'Only the best words')
            ..focus(),
      keys = keys ?? PreventQuitKeys();

  final tui.TextAreaModel textarea;
  final PreventQuitKeys keys;
  final String saveText;
  final bool hasChanges;
  final bool quitting;

  PreventQuitModel copyWith({
    tui.TextAreaModel? textarea,
    PreventQuitKeys? keys,
    String? saveText,
    bool? hasChanges,
    bool? quitting,
  }) {
    return PreventQuitModel(
      textarea: textarea ?? this.textarea,
      keys: keys ?? this.keys,
      saveText: saveText ?? this.saveText,
      hasChanges: hasChanges ?? this.hasChanges,
      quitting: quitting ?? this.quitting,
    );
  }

  @override
  tui.Cmd? init() => textarea.focus();

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    if (quitting) return _updatePromptView(msg);
    return _updateTextView(msg);
  }

  (tui.Model, tui.Cmd?) _updateTextView(tui.Msg msg) {
    var saveText = this.saveText;
    var hasChanges = this.hasChanges;
    var quitting = this.quitting;
    final cmds = <tui.Cmd>[];

    switch (msg) {
      case tui.KeyMsg(key: final key):
        saveText = '';
        if (key.matchesSingle(keys.save)) {
          saveText = 'Changes saved!';
          hasChanges = false;
        } else if (key.matchesSingle(keys.quit)) {
          quitting = true;
          return (
            copyWith(
              saveText: saveText,
              hasChanges: hasChanges,
              quitting: quitting,
            ),
            tui.Cmd.quit(),
          );
        } else if (key.type == tui.KeyType.runes) {
          saveText = '';
          hasChanges = true;
        }

        // Ensure textarea is focused after any keypress.
        if (!textarea.focused) {
          final focusCmd = textarea.focus();
          if (focusCmd != null) cmds.add(focusCmd);
        }
    }

    final (newTextarea, cmd) = textarea.update(msg);
    if (cmd != null) cmds.add(cmd);

    return (
      copyWith(
        saveText: saveText,
        hasChanges: hasChanges,
        quitting: quitting,
        textarea: newTextarea,
      ),
      cmds.isNotEmpty ? tui.Cmd.batch(cmds) : null,
    );
  }

  (tui.Model, tui.Cmd?) _updatePromptView(tui.Msg msg) {
    if (msg is tui.KeyMsg) {
      // Treat any key besides 'y' or quit binding as "no"
      final isYes =
          msg.key.type == tui.KeyType.runes &&
          msg.key.runes.isNotEmpty &&
          msg.key.runes.first == 0x79; // y
      if (msg.key.matchesSingle(keys.quit) || isYes) {
        return (
          copyWith(saveText: saveText, hasChanges: false, quitting: true),
          tui.Cmd.quit(),
        );
      }
      // Cancel quit
      return (
        copyWith(saveText: saveText, hasChanges: hasChanges, quitting: false),
        null,
      );
    }
    return (this, null);
  }

  @override
  String view() {
    if (quitting) {
      if (hasChanges) {
        final text = 'You have unsaved changes. Quit without saving? ';
        final choice = Style()
            .paddingLeft(1)
            .foreground(const AnsiColor(241))
            .render('[yn]');
        final box = Style()
            .padding(1)
            .border(Border.rounded)
            .borderForeground(const AnsiColor(170))
            .render('$text$choice');
        return box;
      }
      return 'Very important, thank you\n';
    }

    final help = tui.HelpModel().shortHelpView([keys.save, keys.quit]);
    final saveTextStyled = Style()
        .foreground(const AnsiColor(170))
        .render(saveText);

    return '\nType some important things.\n\n'
        '${textarea.view()}\n\n '
        '$saveTextStyled\n $help\n\n';
  }
}

tui.Msg? preventQuitFilter(tui.Model model, tui.Msg msg) {
  if (msg is! tui.QuitMsg) return msg;
  if (model is! PreventQuitModel) return msg;
  if (model.hasChanges) return null; // Block quit when unsaved changes
  return msg;
}

Future<void> main() async {
  await tui.runProgram(
    PreventQuitModel(),
    options: const tui.ProgramOptions(
      altScreen: false,
      hideCursor: false,
      filter: preventQuitFilter,
    ),
  );
}
