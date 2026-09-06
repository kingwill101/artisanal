import 'package:artisanal/tui.dart' as tui;
import 'package:test/test.dart';

import '../../../example/tui/examples/prompt-composer/main.dart'
    as composer;

tui.KeyMsg _ctrl(int rune) => tui.KeyMsg(
  tui.Key(tui.KeyType.runes, runes: [rune], ctrl: true),
);

/// Raw control code form, as real terminals deliver Ctrl+letter
/// (e.g. 0x03 for Ctrl+C) without the `ctrl` flag set.
tui.KeyMsg _ctrlCode(int code) =>
    tui.KeyMsg(tui.Key(tui.KeyType.runes, runes: [code]));

void main() {
  test('prompt composer tracks placeholders and expands on submit', () {
    var model = composer.PromptComposerModel.initial();

    var (next, _) = model.update(_ctrl(0x76)); // ctrl+v: big paste
    model = next as composer.PromptComposerModel;
    expect(model.placeholders.isEmpty, isFalse);
    expect(model.composer.value, contains('[Pasted ~8 lines #1]'));

    (next, _) = model.update(_ctrl(0x73)); // ctrl+s: submit
    model = next as composer.PromptComposerModel;
    expect(model.submitted, hasLength(1));
    expect(model.submitted.single, contains('pasted line 1'));
    expect(model.submitted.single, contains('pasted line 8'));
    expect(model.placeholders.isEmpty, isTrue);
    expect(model.composer.value, isEmpty);
  });

  test('prompt composer attaches IDE selection context on submit', () {
    var model = composer.PromptComposerModel.initial();

    var (next, _) = model.update(_ctrl(0x67)); // ctrl+g: IDE selection
    model = next as composer.PromptComposerModel;
    expect(model.activeIdeSelection, isNotNull);
    expect(model.view(), contains('IDE:'));

    model.composer.insertString('explain this');
    (next, _) = model.update(_ctrl(0x73)); // ctrl+s: submit
    model = next as composer.PromptComposerModel;
    expect(model.submitted.single, contains('explain this'));
    expect(model.submitted.single, contains('system-reminder'));
    expect(model.submitted.single, contains('lib/main.dart'));
  });

  test('prompt composer dismisses IDE selection', () {
    var model = composer.PromptComposerModel.initial();

    var (next, _) = model.update(_ctrl(0x67));
    model = next as composer.PromptComposerModel;
    (next, _) = model.update(_ctrl(0x64)); // ctrl+d: dismiss
    model = next as composer.PromptComposerModel;
    expect(model.activeIdeSelection, isNull);
  });

  test('prompt composer bindings fire on raw terminal control codes', () async {
    var model = composer.PromptComposerModel.initial();

    var (next, cmd) = model.update(_ctrlCode(0x16)); // ctrl+v as 0x16
    model = next as composer.PromptComposerModel;
    expect(cmd, isNull);
    expect(model.placeholders.isEmpty, isFalse);

    (next, cmd) = model.update(_ctrlCode(0x03)); // ctrl+c as 0x03
    expect(await cmd?.execute(), isA<tui.QuitMsg>());
  });

  test('prompt composer submits on ctrl+t (flow-control-safe)', () {
    var model = composer.PromptComposerModel.initial();
    model.composer.insertString('hello');
    final (next, _) = model.update(_ctrl(0x74)); // ctrl+t: submit
    model = next as composer.PromptComposerModel;
    expect(model.submitted.single, 'hello');
    expect(model.composer.value, isEmpty);
  });

  test('prompt composer records the last key for debugging', () {
    var model = composer.PromptComposerModel.initial();
    final (next, _) = model.update(_ctrl(0x74));
    model = next as composer.PromptComposerModel;
    expect(model.lastKey, contains('0x74'));
    expect(model.view(), contains('Last key:'));
  });

  test('prompt composer quits on interrupt', () async {
    final model = composer.PromptComposerModel.initial();
    final (_, cmd) = model.update(const tui.InterruptMsg());
    expect(await cmd?.execute(), isA<tui.QuitMsg>());
  });
}
