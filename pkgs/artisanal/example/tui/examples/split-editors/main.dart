/// Split editors example ported from Bubble Tea.
library;

import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart';
import 'package:artisanal/tui.dart' as tui;

const _initialInputs = 2;
const _maxInputs = 6;
const _minInputs = 1;
const _helpHeight = 5;

final _cursorLineStyle = Style()
    .background(const BasicColor('#39005a'))
    .foreground(const BasicColor('#e6e6e6'));
final _placeholderStyle = Style().foreground(const BasicColor('#6e6e6e'));
final _focusedPlaceholderStyle = Style().foreground(
  const BasicColor('#7f7ce1'),
);
final _endOfBufferStyle = Style().foreground(const BasicColor('#303030'));
final _focusedBorderStyle = Style()
    .border(Border.rounded)
    .borderForeground(const BasicColor('#6e6e6e'));
final _blurredBorderStyle = Style().border(Border.hidden);

class SplitKeys implements tui.KeyMap {
  SplitKeys()
    : next = tui.KeyBinding.withHelp(['tab'], 'tab', 'next'),
      prev = tui.KeyBinding.withHelp(['shift+tab'], 'shift+tab', 'prev'),
      add = tui.KeyBinding.withHelp(['ctrl+n'], 'ctrl+n', 'add editor'),
      remove = tui.KeyBinding.withHelp(['ctrl+w'], 'ctrl+w', 'remove editor'),
      quit = tui.KeyBinding.withHelp(['esc', 'ctrl+c'], 'esc', 'quit');

  final tui.KeyBinding next;
  final tui.KeyBinding prev;
  final tui.KeyBinding add;
  final tui.KeyBinding remove;
  final tui.KeyBinding quit;

  @override
  List<tui.KeyBinding> shortHelp() => [next, prev, add, remove, quit];

  @override
  List<List<tui.KeyBinding>> fullHelp() => [
    [next, prev, add, remove, quit],
  ];
}

class SplitEditorsModel implements tui.Model {
  SplitEditorsModel({
    required this.inputs,
    required this.keymap,
    required this.help,
    this.focus = 0,
    this.width = 80,
    this.height = 24,
  });

  factory SplitEditorsModel.initial() {
    final keymap = SplitKeys();
    final help = tui.HelpModel();
    final inputs = List<tui.TextAreaModel>.generate(
      _initialInputs,
      (_) => _newTextarea(),
    );
    inputs[0].focus();
    return SplitEditorsModel(inputs: inputs, keymap: keymap, help: help);
  }

  final List<tui.TextAreaModel> inputs;
  final SplitKeys keymap;
  final tui.HelpModel help;
  final int focus;
  final int width;
  final int height;

  @override
  tui.Cmd? init() => null;

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    final cmds = <tui.Cmd?>[];

    switch (msg) {
      case tui.KeyMsg(:final key):
        if (key.matches([keymap.quit])) {
          for (final ta in inputs) {
            ta.blur();
          }
          return (this, tui.Cmd.quit());
        }
        if (key.matches([keymap.next])) {
          return _focusNext(cmds);
        }
        if (key.matches([keymap.prev])) {
          return _focusPrev(cmds);
        }
        if (key.matches([keymap.add]) && inputs.length < _maxInputs) {
          final newInputs = [...inputs, _newTextarea()];
          return (
            copyWith(
              inputs: newInputs,
              focus: focus,
              width: width,
              height: height,
            ),
            null,
          );
        }
        if (key.matches([keymap.remove]) && inputs.length > _minInputs) {
          final newList = inputs.take(inputs.length - 1).toList();
          final newFocus = focus >= newList.length ? newList.length - 1 : focus;
          newList[newFocus].focus();
          return (copyWith(inputs: newList, focus: newFocus), null);
        }
      case tui.WindowSizeMsg(width: final w, height: final h):
        return (copyWith(width: w, height: h), null);
    }

    // Resize after potential size updates
    _sizeInputs();

    // Update all textareas
    var updatedInputs = inputs;
    for (var i = 0; i < inputs.length; i++) {
      final (newTa, cmd) = inputs[i].update(msg);
      updatedInputs = [
        ...updatedInputs.take(i),
        newTa,
        ...updatedInputs.skip(i + 1),
      ];
      cmds.add(cmd);
    }

    return (copyWith(inputs: updatedInputs), _batch(cmds));
  }

  (SplitEditorsModel, tui.Cmd?) _focusNext(List<tui.Cmd?> cmds) {
    inputs[focus].blur();
    final next = (focus + 1) % inputs.length;
    final cmd = inputs[next].focus();
    cmds.add(cmd);
    return (copyWith(focus: next), _batch(cmds));
  }

  (SplitEditorsModel, tui.Cmd?) _focusPrev(List<tui.Cmd?> cmds) {
    inputs[focus].blur();
    var next = focus - 1;
    if (next < 0) next = inputs.length - 1;
    final cmd = inputs[next].focus();
    cmds.add(cmd);
    return (copyWith(focus: next), _batch(cmds));
  }

  void _sizeInputs() {
    final usableHeight = (height - _helpHeight);
    for (final ta in inputs) {
      ta.setWidth(width ~/ inputs.length);
      ta.setHeight(usableHeight > 0 ? usableHeight : ta.height);
    }
  }

  SplitEditorsModel copyWith({
    List<tui.TextAreaModel>? inputs,
    SplitKeys? keymap,
    tui.HelpModel? help,
    int? focus,
    int? width,
    int? height,
  }) {
    return SplitEditorsModel(
      inputs: inputs ?? this.inputs,
      keymap: keymap ?? this.keymap,
      help: help ?? this.help,
      focus: focus ?? this.focus,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  @override
  String view() {
    _sizeInputs();

    final views = <String>[];
    for (var i = 0; i < inputs.length; i++) {
      final taView = inputs[i].view();
      final styled = (i == focus ? _focusedBorderStyle : _blurredBorderStyle)
          .render(taView);
      views.add(styled);
    }

    final row = Layout.joinHorizontal(VerticalAlign.top, views);
    final helpView = help.shortHelpView([
      keymap.next,
      keymap.prev,
      keymap.add,
      keymap.remove,
      keymap.quit,
    ]);

    return '$row\n\n$helpView';
  }
}

tui.TextAreaModel _newTextarea() {
  final ta = tui.TextAreaModel(
    prompt: '',
    placeholder: 'Type something',
    showLineNumbers: true,
  );
  ta.styles.focused = ta.styles.focused.copyWith(
    base: _focusedBorderStyle,
    cursorLine: _cursorLineStyle,
    placeholder: _focusedPlaceholderStyle,
    endOfBuffer: _endOfBufferStyle,
  );
  ta.styles.blurred = ta.styles.blurred.copyWith(
    base: _blurredBorderStyle,
    placeholder: _placeholderStyle,
    endOfBuffer: _endOfBufferStyle,
  );
  ta.blur();
  return ta;
}

tui.Cmd? _batch(List<tui.Cmd?> cmds) {
  final filtered = cmds.whereType<tui.Cmd>().toList();
  return filtered.isEmpty ? null : tui.Cmd.batch(filtered);
}

Future<void> main() async {
  await tui.runProgram(
    SplitEditorsModel.initial(),
    options: const tui.ProgramOptions(altScreen: true, hideCursor: true),
  );
}
