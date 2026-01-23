/// Credit card form example ported from Bubble Tea.
library;

import 'package:artisanal/artisanal.dart' show BasicColor, Style;
import 'package:artisanal/tui.dart' as tui;

const _hotPink = BasicColor('#FF06B7');
const _darkGray = BasicColor('#767676');

final _inputStyle = Style().foreground(_hotPink);
final _continueStyle = Style().foreground(_darkGray);

enum _Field { ccn, exp, cvv }

class CreditCardModel implements tui.Model {
  CreditCardModel({
    required this.inputs,
    this.focused = 0,
    this.error,
    this.initialCmd,
  });

  factory CreditCardModel.initial() {
    final inputs = <tui.TextInputModel>[
      tui.TextInputModel(
        placeholder: '4505 **** **** 1234',
        charLimit: 20,
        width: 30,
        prompt: '',
        validate: _ccnValidator,
      ),
      tui.TextInputModel(
        placeholder: 'MM/YY',
        charLimit: 5,
        width: 5,
        prompt: '',
        validate: _expValidator,
      ),
      tui.TextInputModel(
        placeholder: 'XXX',
        charLimit: 3,
        width: 5,
        prompt: '',
        validate: _cvvValidator,
      ),
    ];
    final focusCmd = inputs[0].focus();
    return CreditCardModel(inputs: inputs, focused: 0, initialCmd: focusCmd);
  }

  final List<tui.TextInputModel> inputs;
  final int focused;
  final String? error;
  final tui.Cmd? initialCmd;

  @override
  tui.Cmd? init() => initialCmd;

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    final cmds = <tui.Cmd?>[];

    switch (msg) {
      case tui.KeyMsg(key: final key):
        final rune = key.runes.isNotEmpty ? key.runes.first : -1;
        switch (key.type) {
          case tui.KeyType.enter:
            if (focused == inputs.length - 1) {
              return (this, tui.Cmd.quit());
            }
            return _focusNext(cmds);
          case tui.KeyType.escape:
            return (this, tui.Cmd.quit());
          case tui.KeyType.tab:
            return _focusNext(cmds);
          case tui.KeyType.backspace:
          case tui.KeyType.delete:
          case tui.KeyType.runes:
          default:
            break;
        }
        if (key.ctrl && rune == 0x63) {
          return (this, tui.Cmd.quit());
        }
        // Ctrl+N
        if (key.ctrl && rune == 0x6e) {
          return _focusNext(cmds);
        }
        // Ctrl+P or shift+tab -> previous
        if ((key.ctrl && rune == 0x70) ||
            (key.type == tui.KeyType.tab && key.shift)) {
          return _focusPrev(cmds);
        }
      case _ErrMsg(:final message):
        return (copyWith(error: message), null);
    }

    // Update inputs
    var nextInputs = inputs;
    for (var i = 0; i < inputs.length; i++) {
      final (updated, cmd) = inputs[i].update(msg);
      nextInputs = [...nextInputs.take(i), updated, ...nextInputs.skip(i + 1)];
      cmds.add(cmd);
    }

    return (copyWith(inputs: nextInputs), _batch(cmds));
  }

  (CreditCardModel, tui.Cmd?) _focusNext(List<tui.Cmd?> cmds) {
    final next = (focused + 1) % inputs.length;
    return _setFocus(next, cmds);
  }

  (CreditCardModel, tui.Cmd?) _focusPrev(List<tui.Cmd?> cmds) {
    var next = focused - 1;
    if (next < 0) next = inputs.length - 1;
    return _setFocus(next, cmds);
  }

  (CreditCardModel, tui.Cmd?) _setFocus(int index, List<tui.Cmd?> cmds) {
    final updatedInputs = <tui.TextInputModel>[];
    for (var i = 0; i < inputs.length; i++) {
      if (i == index) {
        final cmd = inputs[i].focus();
        cmds.add(cmd);
        updatedInputs.add(inputs[i]);
      } else {
        inputs[i].blur();
        updatedInputs.add(inputs[i]);
      }
    }
    return (copyWith(inputs: updatedInputs, focused: index), _batch(cmds));
  }

  CreditCardModel copyWith({
    List<tui.TextInputModel>? inputs,
    int? focused,
    String? error,
    tui.Cmd? initialCmd,
  }) {
    return CreditCardModel(
      inputs: inputs ?? this.inputs,
      focused: focused ?? this.focused,
      error: error ?? this.error,
      initialCmd: initialCmd ?? this.initialCmd,
    );
  }

  @override
  String view() {
    final buffer = StringBuffer()
      ..writeln(' Total: \$21.50:\n')
      ..writeln(_inputStyle.width(30).render('Card Number'))
      ..writeln(inputs[_Field.ccn.index].view())
      ..writeln()
      ..write(_inputStyle.width(6).render('EXP'))
      ..write('  ')
      ..writeln(_inputStyle.width(6).render('CVV'))
      ..write(inputs[_Field.exp.index].view())
      ..write('  ')
      ..writeln(inputs[_Field.cvv.index].view())
      ..writeln()
      ..writeln(_continueStyle.render('Continue ->'))
      ..writeln();
    return buffer.toString();
  }
}

class _ErrMsg extends tui.Msg {
  const _ErrMsg(this.message);
  final String message;
}

String? _ccnValidator(String s) {
  if (s.length > 19) return 'CCN is too long';
  if (s.isEmpty) return 'CCN is invalid';
  // allow spaces every 4 digits
  for (var i = 0; i < s.length; i++) {
    final ch = s[i];
    if (i % 5 == 4) {
      if (ch != ' ') return 'CCN must separate groups with spaces';
    } else if (ch.codeUnitAt(0) < 0x30 || ch.codeUnitAt(0) > 0x39) {
      return 'CCN is invalid';
    }
  }
  return null;
}

String? _expValidator(String s) {
  final digits = s.replaceAll('/', '');
  if (int.tryParse(digits) == null) return 'EXP is invalid';
  if (s.length >= 3 && (s.indexOf('/') != 2 || s.lastIndexOf('/') != 2)) {
    return 'EXP is invalid';
  }
  if (s.length > 5) return 'EXP too long';
  return null;
}

String? _cvvValidator(String s) {
  if (s.length > 3) return 'CVV too long';
  if (s.length < 3) return null; // allow typing
  return int.tryParse(s) == null ? 'CVV invalid' : null;
}

tui.Cmd? _batch(List<tui.Cmd?> cmds) {
  final filtered = cmds.whereType<tui.Cmd>().toList();
  return filtered.isEmpty ? null : tui.Cmd.batch(filtered);
}

Future<void> main() async {
  await tui.runProgram(
    CreditCardModel.initial(),
    options: const tui.ProgramOptions(altScreen: false, hideCursor: false),
  );
}
