library;

import 'package:artisanal_widgets/testing.dart';
import 'package:artisanal_widgets/widgets.dart' as w;
import 'package:test/test.dart';

void main() {
  group('SlotRegistry', () {
    test('resolves contributions in deterministic order', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final registry = w.SlotRegistry<String, String>();
      registry.register(
        pluginId: 'beta',
        slot: 'main',
        order: 20,
        builder: (_, data) => w.Text('second:$data'),
      );
      registry.register(
        pluginId: 'alpha',
        slot: 'main',
        order: 10,
        builder: (_, data) => w.Text('first:$data'),
      );

      await tester.pumpWidget(
        w.SlotScope<String, String>(
          registry: registry,
          child: w.SlotBuilder<String, String>(slot: 'main', data: 'payload'),
        ),
      );

      final firstIndex = tester.view.indexOf('first:payload');
      final secondIndex = tester.view.indexOf('second:payload');

      expect(firstIndex, greaterThanOrEqualTo(0));
      expect(secondIndex, greaterThan(firstIndex));
    });

    test('first mode renders only the highest-priority contribution', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final registry = w.SlotRegistry<String, int>();
      registry.register(
        pluginId: 'first',
        slot: 'status',
        order: 0,
        builder: (_, data) => w.Text('top:$data'),
      );
      registry.register(
        pluginId: 'second',
        slot: 'status',
        order: 1,
        builder: (_, data) => w.Text('lower:$data'),
      );

      await tester.pumpWidget(
        w.SlotScope<String, int>(
          registry: registry,
          child: w.SlotBuilder<String, int>(
            slot: 'status',
            data: 42,
            mode: w.SlotBuildMode.first,
          ),
        ),
      );

      expect(tester.find.text('top:42'), isTrue);
      expect(tester.find.text('lower:42'), isFalse);
    });

    test('renders fallback when a slot has no contributions', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      await tester.pumpWidget(
        w.SlotScope<String, String>(
          registry: w.SlotRegistry<String, String>(),
          child: w.SlotBuilder<String, String>(
            slot: 'empty',
            data: 'ignored',
            fallback: w.Text('fallback'),
          ),
        ),
      );

      expect(tester.find.text('fallback'), isTrue);
    });

    test('scope rebuilds dependents after register and unregister', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final registry = w.SlotRegistry<String, String>();
      await tester.pumpWidget(
        w.SlotScope<String, String>(
          registry: registry,
          child: w.SlotBuilder<String, String>(
            slot: 'sidebar',
            data: 'live',
            fallback: w.Text('empty'),
          ),
        ),
      );

      expect(tester.find.text('empty'), isTrue);

      final dispose = registry.register(
        pluginId: 'inspector',
        slot: 'sidebar',
        builder: (_, data) => w.Text('panel:$data'),
      );
      tester.pump();

      expect(tester.find.text('panel:live'), isTrue);
      expect(tester.find.text('empty'), isFalse);

      dispose();
      tester.pump();

      expect(tester.find.text('empty'), isTrue);
      expect(tester.find.text('panel:live'), isFalse);
    });

    test('rejects duplicate plugin registrations for the same slot', () {
      final registry = w.SlotRegistry<String, String>();
      registry.register(
        pluginId: 'plugin',
        slot: 'main',
        builder: (_, data) => w.Text(data),
      );

      expect(
        () => registry.register(
          pluginId: 'plugin',
          slot: 'main',
          builder: (_, data) => w.Text('again:$data'),
        ),
        throwsStateError,
      );
    });

    test(
      'registerPlugin registers multiple slots and unregisters atomically',
      () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        final registry = w.SlotRegistry<String, String>();
        final dispose = registry.registerPlugin(
          w.SlotPlugin<String, String>(
            pluginId: 'workspace',
            slots: {
              'header': w.SlotPluginContribution<String>(
                builder: (_, data) => w.Text('header:$data'),
              ),
              'footer': w.SlotPluginContribution<String>(
                builder: (_, data) => w.Text('footer:$data'),
                order: 5,
              ),
            },
          ),
        );

        await tester.pumpWidget(
          w.SlotScope<String, String>(
            registry: registry,
            child: w.Column(
              children: [
                w.SlotBuilder<String, String>(slot: 'header', data: 'demo'),
                w.SlotBuilder<String, String>(slot: 'footer', data: 'demo'),
              ],
            ),
          ),
        );

        expect(tester.find.text('header:demo'), isTrue);
        expect(tester.find.text('footer:demo'), isTrue);

        dispose();
        tester.pump();

        expect(tester.find.text('header:demo'), isFalse);
        expect(tester.find.text('footer:demo'), isFalse);
      },
    );

    test('registerPlugin rejects duplicate plugin-slot pairs up front', () {
      final registry = w.SlotRegistry<String, String>();
      registry.register(
        pluginId: 'workspace',
        slot: 'header',
        builder: (_, data) => w.Text(data),
      );

      expect(
        () => registry.registerPlugin(
          w.SlotPlugin<String, String>(
            pluginId: 'workspace',
            slots: {
              'header': w.SlotPluginContribution<String>(
                builder: (_, data) => w.Text('dupe:$data'),
              ),
              'footer': w.SlotPluginContribution<String>(
                builder: (_, data) => w.Text('footer:$data'),
              ),
            },
          ),
        ),
        throwsStateError,
      );

      expect(registry.hasSlot('footer'), isFalse);
    });

    test(
      'SlotPluginMount registers declaratively into the nearest scope',
      () async {
        final tester = WidgetTester();
        addTearDown(() => tester.dispose());

        final registry = w.SlotRegistry<String, String>();
        await tester.pumpWidget(
          w.SlotScope<String, String>(
            registry: registry,
            child: w.Column(
              children: [
                w.SlotPluginMount<String, String>(
                  plugin: w.SlotPlugin<String, String>(
                    pluginId: 'inspector',
                    slots: {
                      'sidebar': w.SlotPluginContribution<String>(
                        builder: (_, data) => w.Text('mounted:$data'),
                      ),
                    },
                  ),
                ),
                w.SlotBuilder<String, String>(slot: 'sidebar', data: 'ok'),
              ],
            ),
          ),
        );

        expect(tester.find.text('mounted:ok'), isTrue);
      },
    );

    test('SlotPluginMount updates registrations when plugin changes', () async {
      final tester = WidgetTester();
      addTearDown(() => tester.dispose());

      final registry = w.SlotRegistry<String, String>();
      final controller = _PluginController(
        w.SlotPlugin<String, String>(
          pluginId: 'workspace',
          slots: {
            'sidebar': w.SlotPluginContribution<String>(
              builder: (_, data) => w.Text('first:$data'),
            ),
          },
        ),
      );
      await tester.pumpWidget(
        w.SlotScope<String, String>(
          registry: registry,
          child: _ControlledPluginMount(controller: controller),
        ),
      );

      expect(tester.find.text('first:live'), isTrue);

      controller.swap(
        w.SlotPlugin<String, String>(
          pluginId: 'workspace',
          slots: {
            'sidebar': w.SlotPluginContribution<String>(
              builder: (_, data) => w.Text('second:$data'),
            ),
          },
        ),
      );
      tester.pump();

      expect(tester.find.text('second:live'), isTrue);
      expect(tester.find.text('first:live'), isFalse);
    });
  });
}

class _PluginController {
  _PluginController(this.plugin);

  final Set<void Function()> _listeners = <void Function()>{};
  w.SlotPlugin<String, String> plugin;

  void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  void swap(w.SlotPlugin<String, String> next) {
    plugin = next;
    for (final listener in List<void Function()>.from(_listeners)) {
      listener();
    }
  }
}

class _ControlledPluginMount extends w.StatefulWidget {
  _ControlledPluginMount({required this.controller});

  final _PluginController controller;

  @override
  w.State createState() => _ControlledPluginMountState();
}

class _ControlledPluginMountState extends w.State<_ControlledPluginMount> {
  late w.SlotPlugin<String, String> _plugin;

  @override
  void initState() {
    super.initState();
    _plugin = widget.controller.plugin;
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  void _handleControllerChanged() {
    setState(() {
      _plugin = widget.controller.plugin;
    });
  }

  @override
  w.Widget build(w.BuildContext context) {
    return w.Column(
      children: [
        w.SlotPluginMount<String, String>(plugin: _plugin),
        w.SlotBuilder<String, String>(slot: 'sidebar', data: 'live'),
      ],
    );
  }
}
