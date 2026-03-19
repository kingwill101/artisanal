import 'package:artisanal/app.dart' as app;
import 'package:artisanal/testing.dart';
import 'package:artisanal/widgets.dart' as w;
import 'package:test/test.dart';

void main() {
  group('ReloadHost', () {
    test('reload rebuilds while preserving compatible state', () async {
      _ReloadProbeState.mountCount = 0;
      final controller = app.ReloadController();
      final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
      addTearDown(() async {
        await controller.dispose();
        await tester.dispose();
      });

      await tester.pumpWidget(
        app.ReloadHost(
          controller: controller,
          builder: (context, revision) => _ReloadProbe(revision: revision),
        ),
      );

      expect(tester.view, contains('revision:0'));
      expect(tester.view, contains('instance:1'));

      controller.reload();
      tester.pump();

      expect(tester.view, contains('revision:1'));
      expect(tester.view, contains('instance:1'));
    });

    test('restart remounts the subtree', () async {
      _ReloadProbeState.mountCount = 0;
      final controller = app.ReloadController();
      final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
      addTearDown(() async {
        await controller.dispose();
        await tester.dispose();
      });

      await tester.pumpWidget(
        app.ReloadHost(
          controller: controller,
          builder: (context, revision) => _ReloadProbe(revision: revision),
        ),
      );

      controller.restart();
      tester.pump();

      expect(tester.view, contains('revision:1'));
      expect(tester.view, contains('instance:2'));
    });

    test('ReloadScope exposes the controller to descendants', () async {
      final controller = app.ReloadController();
      final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
      addTearDown(() async {
        await controller.dispose();
        await tester.dispose();
      });

      await tester.pumpWidget(
        app.ReloadHost(
          controller: controller,
          builder: (context, revision) => w.Text(
            identical(app.ReloadScope.of(context), controller)
                ? 'scope:ok'
                : 'scope:missing',
          ),
        ),
      );

      expect(tester.view, contains('scope:ok'));
    });
  });
}

final class _ReloadProbe extends w.StatefulWidget {
  _ReloadProbe({required this.revision});

  final int revision;

  @override
  w.State<_ReloadProbe> createState() => _ReloadProbeState();
}

final class _ReloadProbeState extends w.State<_ReloadProbe> {
  static int mountCount = 0;
  late final int instanceId;

  @override
  void initState() {
    super.initState();
    mountCount++;
    instanceId = mountCount;
  }

  @override
  w.Widget build(w.BuildContext context) {
    return w.Text('revision:${widget.revision} instance:$instanceId');
  }
}
