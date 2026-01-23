/// Spinner example ported from Bubble Tea.
///
/// Shows an animated spinner until the user quits.
library;

import 'package:artisanal/artisanal.dart';
import 'package:artisanal/tui.dart';

// #region spinner_usage
class SpinnerExampleModel implements Model {
  SpinnerExampleModel({SpinnerModel? spinner, this.quitting = false})
    : spinner = spinner ?? SpinnerModel(spinner: Spinners.dot);

  final SpinnerModel spinner;
  final bool quitting;

  SpinnerExampleModel copyWith({SpinnerModel? spinner, bool? quitting}) {
    return SpinnerExampleModel(
      spinner: spinner ?? this.spinner,
      quitting: quitting ?? this.quitting,
    );
  }

  @override
  Cmd? init() => spinner.tick();

  @override
  (Model, Cmd?) update(Msg msg) {
    switch (msg) {
      case KeyMsg(key: Key(type: KeyType.runes, runes: [0x71])) || // q
          KeyMsg(key: Key(ctrl: true, runes: [0x63])) || // Ctrl+C
          KeyMsg(key: Key(type: KeyType.escape)):
        return (copyWith(quitting: true), Cmd.quit());

      default:
        final (newSpinner, cmd) = spinner.update(msg);
        return (copyWith(spinner: newSpinner), cmd);
    }
  }

  @override
  String view() {
    final spinnerText = Style()
        .foreground(const AnsiColor(205))
        .render(spinner.view());
    final quittingSuffix = quitting ? '\n' : '';

    return '\n\n   $spinnerText Loading forever...press q to quit\n\n'
        '$quittingSuffix';
  }
}
// #endregion

Future<void> main() async {
  await runProgram(
    SpinnerExampleModel(),
    options: const ProgramOptions(altScreen: false, hideCursor: false),
  );
}
