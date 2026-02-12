import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:artisanal_widgets/testing.dart';
import 'package:test/test.dart';

class _StatefulBuilder extends w.StatefulWidget {
  _StatefulBuilder({required this.builder});
  final w.Widget Function(
    w.BuildContext context,
    void Function(void Function()) setState,
  )
  builder;
  @override
  w.State createState() => _StatefulBuilderState();
}

class _StatefulBuilderState extends w.State<_StatefulBuilder> {
  @override
  w.Widget build(w.BuildContext context) => widget.builder(context, setState);
}

void main() {
  group('Focus Trapping', () {
    test('cannot request focus outside trapped scope', () async {
      final tester = WidgetTester();
      try {
        final controller = w.FocusController();

        await tester.pumpWidget(
          w.FocusScope(
            controller: controller,
            child: w.Column(
              children: [
                w.Focusable(focusId: 'outside', child: w.Text('outside')),
                w.FocusScope(
                  isTrapped: true,
                  child: w.Focusable(
                    focusId: 'inside',
                    child: w.Text('inside'),
                  ),
                ),
              ],
            ),
          ),
        );

        // Initially focus inside
        controller.requestFocus('inside');
        expect(controller.focusedId, equals('inside'));

        // Try to focus outside - should fail
        final changed = controller.requestFocus('outside');
        expect(changed, isFalse);
        expect(controller.focusedId, equals('inside'));
      } finally {
        await tester.dispose();
      }
    });

    test('can request focus inside trapped scope', () async {
      final tester = WidgetTester();
      try {
        final controller = w.FocusController();

        await tester.pumpWidget(
          w.FocusScope(
            controller: controller,
            child: w.FocusScope(
              isTrapped: true,
              child: w.Column(
                children: [
                  w.Focusable(focusId: 'id1', child: w.Text('id1')),
                  w.Focusable(focusId: 'id2', child: w.Text('id2')),
                ],
              ),
            ),
          ),
        );

        controller.requestFocus('id1');
        expect(controller.focusedId, equals('id1'));

        final changed = controller.requestFocus('id2');
        expect(changed, isTrue);
        expect(controller.focusedId, equals('id2'));
      } finally {
        await tester.dispose();
      }
    });

    test('releasing trap allows focusing outside', () async {
      final tester = WidgetTester();
      try {
        final controller = w.FocusController();

        bool trapped = true;

        await tester.pumpWidget(
          _StatefulBuilder(
            builder: (context, setState) {
              return w.FocusScope(
                controller: controller,
                child: w.Column(
                  children: [
                    w.Focusable(focusId: 'outside', child: w.Text('outside')),
                    if (trapped)
                      w.FocusScope(
                        key: w.Key('trap'),
                        isTrapped: true,
                        child: w.Focusable(
                          focusId: 'inside',
                          child: w.Text('inside'),
                        ),
                      ),
                    w.GestureDetector(
                      onTap: () {
                        setState(() => trapped = false);
                        return null;
                      },
                      child: w.Text('release'),
                    ),
                  ],
                ),
              );
            },
          ),
        );

        controller.requestFocus('inside');
        expect(controller.focusedId, equals('inside'));

        // Try to focus outside - should fail
        controller.requestFocus('outside');
        expect(controller.focusedId, equals('inside'));

        // Release trap
        tester.tap(tester.find.textLocation('release'));
        tester.pump();

        // Now focus outside should work
        final changed = controller.requestFocus('outside');
        expect(changed, isTrue);
        expect(controller.focusedId, equals('outside'));
      } finally {
        await tester.dispose();
      }
    });
  });
}
