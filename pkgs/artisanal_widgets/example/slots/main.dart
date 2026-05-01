// Slot Registry Showcase
//
// Demonstrates in-process slot composition with SlotScope, SlotPluginMount,
// deterministic ordering, and live mount/unmount toggles.
//
// Run with: dart run example/slots/main.dart

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

void main() async {
  final app = tui.WidgetApp(SlotRegistryShowcase());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouse: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

enum _DemoSlot { header, sidebar, inspector, footer }

final class _SlotData {
  const _SlotData({
    required this.cycle,
    required this.showAlerts,
    required this.showActivity,
    required this.showTools,
  });

  final int cycle;
  final bool showAlerts;
  final bool showActivity;
  final bool showTools;
}

class SlotRegistryShowcase extends w.StatefulWidget {
  SlotRegistryShowcase({super.key});

  @override
  w.State createState() => _SlotRegistryShowcaseState();
}

class _SlotRegistryShowcaseState extends w.State<SlotRegistryShowcase> {
  final w.SlotRegistry<_DemoSlot, _SlotData> _registry =
      w.SlotRegistry<_DemoSlot, _SlotData>();

  bool _showAlerts = true;
  bool _showActivity = true;
  bool _showTools = false;
  int _cycle = 0;

  late final w.SlotPlugin<_DemoSlot, _SlotData> _basePlugin;
  late final w.SlotPlugin<_DemoSlot, _SlotData> _alertsPlugin;
  late final w.SlotPlugin<_DemoSlot, _SlotData> _activityPlugin;
  late final w.SlotPlugin<_DemoSlot, _SlotData> _toolsPlugin;

  @override
  void initState() {
    super.initState();
    _basePlugin = w.SlotPlugin<_DemoSlot, _SlotData>(
      pluginId: 'host.chrome',
      slots: <_DemoSlot, w.SlotPluginContribution<_SlotData>>{
        _DemoSlot.header: w.SlotPluginContribution<_SlotData>(
          order: 10,
          builder: (context, data) => _slotTile(
            context,
            title: 'Host chrome',
            accent: Colors.blue,
            body:
                'Base shell contribution. Cycle ${data.cycle} keeps slot data visible inside plugin renderers.',
          ),
        ),
        _DemoSlot.footer: w.SlotPluginContribution<_SlotData>(
          order: 30,
          builder: (context, data) => _slotTile(
            context,
            title: 'Footer summary',
            accent: Colors.gray,
            body:
                'alerts=${data.showAlerts} activity=${data.showActivity} tools=${data.showTools}',
          ),
        ),
      },
    );
    _alertsPlugin = w.SlotPlugin<_DemoSlot, _SlotData>(
      pluginId: 'ops.alerts',
      slots: <_DemoSlot, w.SlotPluginContribution<_SlotData>>{
        _DemoSlot.header: w.SlotPluginContribution<_SlotData>(
          order: 0,
          builder: (context, data) => _slotTile(
            context,
            title: 'Alert banner',
            accent: Colors.red,
            body: data.showAlerts
                ? '3 incidents need review before the next deploy window.'
                : 'Alerts muted.',
          ),
        ),
        _DemoSlot.sidebar: w.SlotPluginContribution<_SlotData>(
          order: 5,
          builder: (context, data) => _slotTile(
            context,
            title: 'Alert queue',
            accent: Colors.red,
            body: 'P1 checkout | P2 indexing | P3 docs sync',
          ),
        ),
      },
    );
    _activityPlugin = w.SlotPlugin<_DemoSlot, _SlotData>(
      pluginId: 'activity.stream',
      slots: <_DemoSlot, w.SlotPluginContribution<_SlotData>>{
        _DemoSlot.sidebar: w.SlotPluginContribution<_SlotData>(
          order: 20,
          builder: (context, data) => _slotTile(
            context,
            title: 'Activity stream',
            accent: Colors.green,
            body:
                'Cycle ${data.cycle}: deploy queued, docs rebuilt, palette probe completed.',
          ),
        ),
        _DemoSlot.footer: w.SlotPluginContribution<_SlotData>(
          order: 10,
          builder: (context, data) => _slotTile(
            context,
            title: 'Recent event',
            accent: Colors.green,
            body: 'Merged render-monitor metrics into debug overlay.',
          ),
        ),
      },
    );
    _toolsPlugin = w.SlotPlugin<_DemoSlot, _SlotData>(
      pluginId: 'dev.tools',
      slots: <_DemoSlot, w.SlotPluginContribution<_SlotData>>{
        _DemoSlot.inspector: w.SlotPluginContribution<_SlotData>(
          order: 5,
          builder: (context, data) => _slotTile(
            context,
            title: 'Inspector tools',
            accent: Colors.yellow,
            body: 'Render feed | palette cache | slot order trace',
          ),
        ),
        _DemoSlot.footer: w.SlotPluginContribution<_SlotData>(
          order: 20,
          builder: (context, data) => _slotTile(
            context,
            title: 'Tooling',
            accent: Colors.yellow,
            body: 'Press c to bump data cycle and refresh every mounted slot.',
          ),
        ),
      },
    );
  }

  _SlotData get _slotData => _SlotData(
    cycle: _cycle,
    showAlerts: _showAlerts,
    showActivity: _showActivity,
    showTools: _showTools,
  );

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is! tui.KeyMsg) return null;

    final char = msg.key.char;
    switch (char) {
      case 'q':
        return tui.Cmd.quit();
      case '1':
        setState(() => _showAlerts = !_showAlerts);
      case '2':
        setState(() => _showActivity = !_showActivity);
      case '3':
        setState(() => _showTools = !_showTools);
      case 'c':
        setState(() => _cycle++);
    }
    return null;
  }

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    final subtle = theme.bodySmall.copy()..foreground(theme.muted);

    return w.SlotScope<_DemoSlot, _SlotData>(
      registry: _registry,
      child: _mountPlugins(
        w.Container(
          color: theme.background,
          padding: const w.EdgeInsets.all(1),
          child: w.Column(
            gap: 1,
            crossAxisAlignment: w.CrossAxisAlignment.stretch,
            children: [
              w.Text('Slot Registry Showcase', style: theme.titleLarge),
              w.Text(
                '1 alerts | 2 activity | 3 tools | c cycle data | q quit',
                style: subtle,
              ),
              w.Row(
                gap: 1,
                children: [
                  _stateBadge(
                    'alerts',
                    _showAlerts,
                    activeColor: Colors.red,
                    disabled: Colors.gray,
                  ),
                  _stateBadge(
                    'activity',
                    _showActivity,
                    activeColor: Colors.green,
                    disabled: Colors.gray,
                  ),
                  _stateBadge(
                    'tools',
                    _showTools,
                    activeColor: Colors.yellow,
                    disabled: Colors.gray,
                  ),
                  w.Badge('cycle $_cycle', background: Colors.blue),
                ],
              ),
              w.Divider(),
              _slotHost(
                title: 'Header Slot',
                slot: _DemoSlot.header,
                data: _slotData,
                description:
                    'Two plugins target this slot. Ordering should stay deterministic when alerts are toggled.',
              ),
              w.Row(
                gap: 1,
                crossAxisAlignment: w.CrossAxisAlignment.start,
                children: [
                  w.Expanded(
                    child: _slotHost(
                      title: 'Sidebar Slot',
                      slot: _DemoSlot.sidebar,
                      data: _slotData,
                      description:
                          'Multiple contributions stack in ascending order.',
                    ),
                  ),
                  w.Expanded(
                    child: _slotHost(
                      title: 'Inspector Slot',
                      slot: _DemoSlot.inspector,
                      data: _slotData,
                      description:
                          'Starts empty, then fills when the tools plugin mounts.',
                    ),
                  ),
                ],
              ),
              _slotHost(
                title: 'Footer Slot',
                slot: _DemoSlot.footer,
                data: _slotData,
                description:
                    'Shows one slot receiving contributions from three different plugins.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  w.Widget _mountPlugins(w.Widget child) {
    var current = w.SlotPluginMount<_DemoSlot, _SlotData>(
      plugin: _basePlugin,
      child: child,
    );
    if (_showAlerts) {
      current = w.SlotPluginMount<_DemoSlot, _SlotData>(
        plugin: _alertsPlugin,
        child: current,
      );
    }
    if (_showActivity) {
      current = w.SlotPluginMount<_DemoSlot, _SlotData>(
        plugin: _activityPlugin,
        child: current,
      );
    }
    if (_showTools) {
      current = w.SlotPluginMount<_DemoSlot, _SlotData>(
        plugin: _toolsPlugin,
        child: current,
      );
    }
    return current;
  }

  w.Widget _slotHost({
    required String title,
    required _DemoSlot slot,
    required _SlotData data,
    required String description,
  }) {
    final theme = widget.theme;
    final subtle = theme.bodySmall.copy()..foreground(theme.muted);

    return w.Card(
      child: w.Column(
        gap: 1,
        crossAxisAlignment: w.CrossAxisAlignment.stretch,
        children: [
          w.Text(title, style: theme.titleMedium),
          w.Text(description, style: subtle),
          w.SlotBuilder<_DemoSlot, _SlotData>(
            slot: slot,
            data: data,
            layoutBuilder: (context, contributions, slotData) {
              if (contributions.isEmpty) {
                return w.Text(
                  'No mounted contributions for $slot.',
                  style: subtle,
                );
              }

              return w.Column(
                gap: 1,
                crossAxisAlignment: w.CrossAxisAlignment.stretch,
                children: [
                  w.Row(
                    gap: 1,
                    children: [
                      for (final contribution in contributions)
                        w.Badge(
                          '${contribution.pluginId}@${contribution.order}',
                          background: Colors.gray,
                        ),
                    ],
                  ),
                  for (final contribution in contributions)
                    contribution.build(context, slotData),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  w.Widget _stateBadge(
    String label,
    bool isEnabled, {
    required Color activeColor,
    required Color disabled,
  }) {
    return w.Badge(
      '$label ${isEnabled ? "on" : "off"}',
      background: isEnabled ? activeColor : disabled,
      foreground: Colors.black,
    );
  }
}

w.Widget _slotTile(
  w.BuildContext context, {
  required String title,
  required Color accent,
  required String body,
}) {
  final theme = context.theme;
  final subtle = theme.bodySmall.copy()..foreground(theme.muted);
  return w.Card(
    borderColor: accent,
    child: w.Column(
      gap: 1,
      crossAxisAlignment: w.CrossAxisAlignment.stretch,
      children: [
        w.Text(title, style: theme.labelLarge),
        w.Text(body, style: subtle),
      ],
    ),
  );
}
