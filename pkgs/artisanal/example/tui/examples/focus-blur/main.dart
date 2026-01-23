/// Focus/blur reporting example ported from Bubble Tea.
library;

import 'package:artisanal/tui.dart' as tui;

class FocusBlurModel implements tui.Model {
  FocusBlurModel({required this.focused, required this.reporting});

  factory FocusBlurModel.initial() =>
      FocusBlurModel(focused: true, reporting: true);

  final bool focused;
  final bool reporting;

  @override
  tui.Cmd? init() => reporting ? tui.Cmd.enableReportFocus() : null;

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    switch (msg) {
      case tui.FocusMsg(focused: final isFocused):
        return (copyWith(focused: isFocused), null);
      case tui.KeyMsg(key: final key):
        final rune = key.runes.isNotEmpty ? key.runes.first : -1;
        if ((key.ctrl && rune == 0x63) || (rune == 0x71)) {
          return (this, tui.Cmd.quit());
        }
        if (rune == 0x74) {
          final nextReporting = !reporting;
          final cmd = nextReporting
              ? tui.Cmd.enableReportFocus()
              : tui.Cmd.disableReportFocus();
          return (copyWith(reporting: nextReporting), cmd);
        }
    }

    return (this, null);
  }

  FocusBlurModel copyWith({bool? focused, bool? reporting}) {
    return FocusBlurModel(
      focused: focused ?? this.focused,
      reporting: reporting ?? this.reporting,
    );
  }

  @override
  String view() {
    final buffer = StringBuffer()
      ..write('Hi. Focus report is currently ')
      ..writeln(reporting ? 'enabled.' : 'disabled.')
      ..writeln();

    if (reporting) {
      buffer.writeln(
        focused
            ? 'This program is currently focused!'
            : 'This program is currently blurred!',
      );
    }

    buffer.writeln(
      '\nTo quit sooner press ctrl-c, or t to toggle focus reporting...\n',
    );

    return buffer.toString();
  }
}

Future<void> main() async {
  await tui.runProgram(
    FocusBlurModel.initial(),
    options: const tui.ProgramOptions(altScreen: false, hideCursor: false),
  );
}
