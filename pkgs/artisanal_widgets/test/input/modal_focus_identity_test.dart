// The GitHub example still uses Modal; cover its trapped scope as well as
// ordinary inherited focus without an app-specific focus controller workaround.
// ignore_for_file: deprecated_member_use

import 'package:artisanal_widgets/widgets.dart' as w;
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

class _Host extends w.StatefulWidget {
  _Host({required this.field, required this.focus, required this.ready});
  final w.Widget Function() field;
  final w.FocusController focus;
  final void Function(void Function(bool)) ready;

  @override
  w.State<_Host> createState() => _HostState();
}

class _HostState extends w.State<_Host> {
  bool open = false;

  @override
  void initState() {
    super.initState();
    widget.ready((value) => setState(() => open = value));
  }

  @override
  w.Widget build(w.BuildContext context) => w.FocusScope(
    controller: widget.focus,
    child: w.Modal(
      open: open,
      dialog: w.SizedBox(width: 40, height: 5, child: widget.field()),
      child: w.Text('Background'),
    ),
  );
}

void main() {
  for (final area in [false, true]) {
    test(
      '${area ? 'TextArea' : 'TextField'} retains autofocus across modal rebuilds and reopen',
      () async {
        final tester = WidgetTester();
        addTearDown(tester.dispose);
        final focus = w.FocusController();
        final field = w.TextEditingController();
        final multiline = w.TextAreaController();
        addTearDown(field.dispose);
        addTearDown(multiline.dispose);
        late void Function(bool) setOpen;
        await tester.pumpWidget(
          _Host(
            focus: focus,
            ready: (callback) => setOpen = callback,
            field: () => area
                ? w.TextArea(controller: multiline, autofocus: true)
                : w.TextField(controller: field, autofocus: true),
          ),
        );
        String text() => area ? multiline.text : field.text;
        for (var cycle = 0; cycle < 2; cycle++) {
          setOpen(true);
          tester.pump();
          final id = focus.focusedId;
          expect(id, isNotNull);
          tester.typeText('a');
          setOpen(true); // New widget configuration, same mounted editor state.
          tester.pump();
          expect(focus.focusedId, id);
          tester.typeText('b');
          expect(text(), 'ab' * (cycle + 1));
          setOpen(false);
          tester.pump();
          expect(focus.focusedId, isNull);
        }
      },
    );
  }
}
