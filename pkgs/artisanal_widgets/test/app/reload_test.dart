import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:artisanal_widgets/artisanal_widgets.dart' show WidgetTester;
import 'package:test/test.dart';

void main() {
  test('WidgetApp reassemble invalidates view cache and rebuilds', () {
    var label = 'WidgetApp v1';
    final app = w.WidgetApp(_HotReloadProbeRoot(() => label));

    expect(app.view(), contains(label));

    label = 'WidgetApp v2';
    app.reassemble();

    expect(app.view(), contains(label));
  });

  group('ReloadHost', () {
    test('reload rebuilds while preserving compatible state', () async {
      _ReloadProbeState.mountCount = 0;
      final controller = w.ReloadController();
      final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
      addTearDown(() async {
        await controller.dispose();
        await tester.dispose();
      });

      await tester.pumpWidget(
        w.ReloadHost(
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
      final controller = w.ReloadController();
      final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
      addTearDown(() async {
        await controller.dispose();
        await tester.dispose();
      });

      await tester.pumpWidget(
        w.ReloadHost(
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
      final controller = w.ReloadController();
      final tester = WidgetTester(screenWidth: 80, screenHeight: 24);
      addTearDown(() async {
        await controller.dispose();
        await tester.dispose();
      });

      await tester.pumpWidget(
        w.ReloadHost(
          controller: controller,
          builder: (context, revision) => w.Text(
            identical(w.ReloadScope.of(context), controller)
                ? 'scope:ok'
                : 'scope:missing',
          ),
        ),
      );

      expect(tester.view, contains('scope:ok'));
    });
  });
}

final class _HotReloadProbeRoot extends w.StatelessWidget {
  _HotReloadProbeRoot(this.textProvider);

  final String Function() textProvider;

  @override
  w.Widget build(w.BuildContext context) => w.Text(textProvider());
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
