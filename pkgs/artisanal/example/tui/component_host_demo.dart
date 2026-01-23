import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal/bubbles.dart' as bubbles;

// #region component_host
class MyModel with tui.ComponentHost implements tui.Model {
  final bubbles.TextInputModel searchInput;
  final bubbles.SpinnerModel spinner;

  MyModel({required this.searchInput, required this.spinner});

  @override
  tui.Cmd? init() => spinner.init();

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    // Delegate to child components using ComponentHost helpers
    final (newInput, inputCmd) = searchInput.update(msg);
    final (newSpinner, spinnerCmd) = spinner.update(msg);

    return (
      MyModel(searchInput: newInput, spinner: newSpinner),
      tui.Cmd.batch([
        if (inputCmd != null) inputCmd,
        if (spinnerCmd != null) spinnerCmd,
      ]),
    );
  }

  @override
  String view() {
    return '${spinner.view()} ${searchInput.view()}';
  }
}
// #endregion

void main() async {
  final model = MyModel(
    searchInput: bubbles.TextInputModel(placeholder: 'Search...'),
    spinner: bubbles.SpinnerModel(spinner: bubbles.Spinners.dot),
  );
  await tui.runProgram(model);
}
