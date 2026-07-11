import 'package:artisanal/bubbles.dart' show EchoMode, TextInputModel;
import 'package:artisanal/artisanal.dart';
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/artisanal_widgets.dart';
import 'package:test/test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Construction & properties
  // ---------------------------------------------------------------------------
  group('TextField construction', () {
    test('creates with default properties', () {
      final tf = TextField();
      expect(tf.autofocus, isFalse);
      expect(tf.enabled, isTrue);
      expect(tf.model, isNull);
      expect(tf.controller, isNull);
      expect(tf.prompt, isNull);
      expect(tf.placeholder, isNull);
      expect(tf.width, isNull);
      expect(tf.echoMode, isNull);
      expect(tf.charLimit, isNull);
      expect(tf.onChanged, isNull);
      expect(tf.focusController, isNull);
      expect(tf.focusId, isNull);
    });

    test('creates with custom properties', () {
      final fc = FocusController();
      final tf = TextField(
        prompt: '>> ',
        placeholder: 'type here',
        width: 30,
        echoMode: EchoMode.password,
        echoCharacter: '#',
        charLimit: 10,
        autofocus: true,
        enabled: false,
        focusController: fc,
        focusId: 'my-field',
      );
      expect(tf.prompt, equals('>> '));
      expect(tf.placeholder, equals('type here'));
      expect(tf.width, equals(30));
      expect(tf.echoMode, equals(EchoMode.password));
      expect(tf.echoCharacter, equals('#'));
      expect(tf.charLimit, equals(10));
      expect(tf.autofocus, isTrue);
      expect(tf.enabled, isFalse);
      expect(tf.focusController, same(fc));
      expect(tf.focusId, equals('my-field'));
    });

    test('is not focusable at widget level', () {
      final tf = TextField();
      expect(tf.focusable, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // TextFieldController
  // ---------------------------------------------------------------------------
  group('TextFieldController', () {
    test('creates with default model', () {
      final ctrl = TextFieldController();
      expect(ctrl.model, isA<TextInputModel>());
      expect(ctrl.model.value, isEmpty);
    });

    test('creates with provided model', () {
      final model = TextInputModel(prompt: 'Q: ');
      final ctrl = TextFieldController(model: model);
      expect(ctrl.model, same(model));
      expect(ctrl.model.prompt, equals('Q: '));
    });

    test('model value can be read and written', () {
      final ctrl = TextFieldController();
      expect(ctrl.model.value, isEmpty);
      ctrl.model.value = 'hello';
      expect(ctrl.model.value, equals('hello'));
    });
  });

  // ---------------------------------------------------------------------------
  // Rendering basics
  // ---------------------------------------------------------------------------
  group('TextField rendering', () {
    test('renders with default prompt', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(TextField(autofocus: true));
      // The default prompt is '> ' when no external model is provided
      // and prompt is null — the internal model defaults to '> '.
      final view = tester.view;
      expect(view.isNotEmpty, isTrue);
    });

    test('renders custom prompt', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(TextField(prompt: 'Name: ', autofocus: true));
      expect(tester.locateText('Name:'), isNotNull);
    });

    test('renders placeholder when empty', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        TextField(placeholder: 'Enter text...', autofocus: true),
      );
      // Placeholder is shown when the field is empty
      expect(tester.locateText('Enter text...'), isNotNull);
    });

    test('renders with controller initial value', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final ctrl = TextFieldController();
      ctrl.model.value = 'preset';

      await tester.pumpWidget(TextField(controller: ctrl, autofocus: true));
      expect(tester.locateText('preset'), isNotNull);
    });

    test('renders with external model', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final model = TextInputModel(prompt: r'$ ');
      model.value = 'cmd';

      await tester.pumpWidget(TextField(model: model, autofocus: true));
      expect(tester.locateText('cmd'), isNotNull);
    });

    test('uses a readable foreground in light theme', () async {
      final tester = WidgetTester(screenWidth: 40, screenHeight: 5);
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        ThemeScope(
          theme: Theme.light(),
          child: FocusScope(
            child: TextField(
              controller: (TextFieldController()..model.value = 'hello'),
              prompt: '> ',
              autofocus: true,
            ),
          ),
        ),
      );

      expect(tester.view, contains('\x1b[38;5;232m'));
    });
  });

  // ---------------------------------------------------------------------------
  // Text input
  // ---------------------------------------------------------------------------
  group('TextField input', () {
    test('typing characters updates the displayed text', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(TextField(prompt: '> ', autofocus: true));

      tester.sendKey('h');
      tester.sendKey('i');
      expect(tester.locateText('hi'), isNotNull);
    });

    test('onChanged fires when text changes', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final values = <String>[];
      await tester.pumpWidget(
        TextField(
          prompt: '> ',
          autofocus: true,
          onChanged: (v) => values.add(v),
        ),
      );

      tester.sendKey('a');
      tester.sendKey('b');
      tester.sendKey('c');
      expect(values, equals(['a', 'ab', 'abc']));
    });

    test('backspace removes characters', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final values = <String>[];
      await tester.pumpWidget(
        TextField(
          prompt: '> ',
          autofocus: true,
          onChanged: (v) => values.add(v),
        ),
      );

      tester.sendKey('a');
      tester.sendKey('b');
      tester.sendSpecialKey(KeyType.backspace);
      // After backspace, value should be 'a'
      expect(values.last, equals('a'));
    });

    test('typing multiple characters builds up text', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final ctrl = TextFieldController();
      await tester.pumpWidget(TextField(controller: ctrl, autofocus: true));

      tester.sendKey('h');
      tester.sendKey('e');
      tester.sendKey('l');
      tester.sendKey('l');
      tester.sendKey('o');
      expect(ctrl.model.value, equals('hello'));
    });

    test('ctrl+z and ctrl+y undo and redo coalesced edits', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final ctrl = TextFieldController();
      await tester.pumpWidget(TextField(controller: ctrl, autofocus: true));

      tester.sendKey('h');
      tester.sendKey('i');
      expect(ctrl.text, 'hi');

      tester.sendMsg(tui.KeyMsg(tui.Key.char('z', ctrl: true)));
      expect(ctrl.text, '');

      tester.sendMsg(tui.KeyMsg(tui.Key.char('y', ctrl: true)));
      expect(ctrl.text, 'hi');
    });

    test(
      'focused field consumes editing keys before sibling traversal',
      () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        await tester.pumpWidget(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _KeyProbe(),
              TextField(prompt: '> ', autofocus: true),
            ],
          ),
        );

        tester.sendKey('a');

        expect(tester.locateText('a'), isNotNull);
        expect(tester.locateText('PROBE:none'), isNotNull);
      },
    );

    test('unhandled shortcuts still bubble past focused field', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _KeyProbe(),
            TextField(prompt: '> ', autofocus: true),
          ],
        ),
      );

      tester.sendMsg(
        const tui.KeyMsg(tui.Key(tui.KeyType.runes, ctrl: true, runes: [0x70])),
      );

      expect(tester.locateText('PROBE:ctrl+p'), isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Focus behavior
  // ---------------------------------------------------------------------------
  group('TextField focus', () {
    test('autofocus requests focus on first build', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final fc = FocusController();
      final tf = TextField(
        autofocus: true,
        focusController: fc,
        focusId: 'field1',
      );

      await tester.pumpWidget(tf);
      expect(fc.isFocused('field1'), isTrue);
    });

    test('does not process input when not focused', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final values = <String>[];
      final fc = FocusController();
      await tester.pumpWidget(
        TextField(
          prompt: '> ',
          focusController: fc,
          focusId: 'field1',
          onChanged: (v) => values.add(v),
          // no autofocus — field is NOT focused
        ),
      );

      tester.sendKey('a');
      tester.sendKey('b');
      // No onChanged should have fired since the field is unfocused
      expect(values, isEmpty);
    });

    test('does not process input when disabled', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final values = <String>[];
      await tester.pumpWidget(
        TextField(
          prompt: '> ',
          autofocus: true,
          enabled: false,
          onChanged: (v) => values.add(v),
        ),
      );

      tester.sendKey('a');
      expect(values, isEmpty);
    });

    test('focus controller switches focus between fields', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final fc = FocusController();
      final values1 = <String>[];
      final values2 = <String>[];

      await tester.pumpWidget(
        FocusScope(
          controller: fc,
          child: Column(
            children: [
              TextField(
                prompt: '1> ',
                focusId: 'f1',
                autofocus: true,
                onChanged: (v) => values1.add(v),
              ),
              TextField(
                prompt: '2> ',
                focusId: 'f2',
                onChanged: (v) => values2.add(v),
              ),
            ],
          ),
        ),
      );

      // Field 1 has autofocus
      tester.sendKey('x');
      expect(values1, equals(['x']));
      expect(values2, isEmpty);

      // Switch focus to field 2
      fc.requestFocus('f2');
      tester.pump();

      tester.sendKey('y');
      // values1 should not grow (field 1 lost focus)
      expect(values1, hasLength(1));
      expect(values2, equals(['y']));
    });
  });

  // ---------------------------------------------------------------------------
  // EchoMode
  // ---------------------------------------------------------------------------
  group('TextField echoMode', () {
    test('password mode shows echo character instead of text', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        TextField(
          prompt: '> ',
          echoMode: EchoMode.password,
          echoCharacter: '*',
          autofocus: true,
        ),
      );

      tester.sendKey('s');
      tester.sendKey('e');
      tester.sendKey('c');
      // Should show *** not sec
      expect(tester.locateText('***'), isNotNull);
      // Should NOT show the plaintext
      expect(tester.locateText('sec'), isNull);
    });

    test('custom echo character works', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        TextField(
          prompt: '> ',
          echoMode: EchoMode.password,
          echoCharacter: '#',
          autofocus: true,
        ),
      );

      tester.sendKey('a');
      tester.sendKey('b');
      expect(tester.locateText('##'), isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Character limit
  // ---------------------------------------------------------------------------
  group('TextField charLimit', () {
    test('respects character limit', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final values = <String>[];
      await tester.pumpWidget(
        TextField(
          charLimit: 3,
          autofocus: true,
          onChanged: (v) => values.add(v),
        ),
      );

      tester.sendKey('a');
      tester.sendKey('b');
      tester.sendKey('c');
      tester.sendKey('d');
      tester.sendKey('e');
      // Should only have 3 characters
      expect(values.last, equals('abc'));
    });
  });

  // ---------------------------------------------------------------------------
  // Width
  // ---------------------------------------------------------------------------
  group('TextField width', () {
    test('renders within specified width', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        TextField(prompt: '', width: 10, autofocus: true),
      );
      // Field renders — basic sanity check
      final view = tester.view;
      expect(view.isNotEmpty, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // Key
  // ---------------------------------------------------------------------------
  group('TextField key', () {
    test('respects ValueKey', () {
      final tf = TextField(key: ValueKey('my-input'));
      expect(tf.id, equals('my-input'));
    });

    test('has unique id without key', () {
      final tf1 = TextField();
      final tf2 = TextField();
      expect(tf1.id, isNot(equals(tf2.id)));
    });
  });

  // ---------------------------------------------------------------------------
  // Integration
  // ---------------------------------------------------------------------------
  group('TextField integration', () {
    test('works inside a Container', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Container(width: 40, child: TextField(prompt: 'Q: ', autofocus: true)),
      );
      expect(tester.locateText('Q:'), isNotNull);
    });

    test('works inside a Column with other widgets', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        Column(
          children: [
            Text('Enter your name:'),
            TextField(prompt: '> ', autofocus: true),
          ],
        ),
      );
      expect(tester.locateText('Enter your name:'), isNotNull);
      // TextField should be on the next row
      final labelPos = tester.locateText('Enter your name:');
      expect(labelPos, isNotNull);
      expect(labelPos!.y, equals(0));
    });

    test('controller value persists across pumps', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final ctrl = TextFieldController();
      await tester.pumpWidget(TextField(controller: ctrl, autofocus: true));

      tester.sendKey('a');
      tester.sendKey('b');
      expect(ctrl.model.value, equals('ab'));

      // Pump again — value should persist
      tester.pump();
      expect(ctrl.model.value, equals('ab'));
      expect(tester.locateText('ab'), isNotNull);
    });

    test('FocusScope provides focus to TextField', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final fc = FocusController();
      final ctrl = TextFieldController();
      await tester.pumpWidget(
        FocusScope(
          controller: fc,
          child: TextField(controller: ctrl, focusId: 'input', autofocus: true),
        ),
      );

      expect(fc.isFocused('input'), isTrue);
      tester.sendKey('z');
      expect(ctrl.model.value, equals('z'));
    });
  });
}

class _KeyProbe extends StatefulWidget {
  _KeyProbe();

  @override
  State<_KeyProbe> createState() => _KeyProbeState();
}

class _KeyProbeState extends State<_KeyProbe> {
  String _status = 'none';

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is! tui.KeyMsg) return null;

    var label = msg.key.char ?? '';
    if (msg.key.ctrl && msg.key.runes.isNotEmpty) {
      label = 'ctrl+${String.fromCharCode(msg.key.runes.first)}';
    }
    if (label.isEmpty) {
      label = msg.key.type.name;
    }

    setState(() => _status = label);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Text('PROBE:$_status');
  }
}
