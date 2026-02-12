// ListTile, Accordion, ExpansionTile & Tooltip Showcase
//
// Demonstrates ListTile variants, Accordion (controlled expand/collapse),
// ExpansionTile with CheckboxListTile/SwitchListTile/RadioListTile, and
// Tooltip (hover to preview).
//
// Run with: dart run example/list_accordion/main.dart

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;

void main() async {
  final app = tui.WidgetApp(ListAccordionShowcase());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class ListAccordionShowcase extends w.StatefulWidget {
  ListAccordionShowcase({super.key});

  @override
  w.State createState() => _ListAccordionShowcaseState();
}

class _ListAccordionShowcaseState extends w.State<ListAccordionShowcase> {
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();
  bool _acc1 = true;
  bool _acc2 = false;
  bool _expSettingsOpen = true;
  bool _expIntegrationsOpen = false;
  bool _emailAlerts = true;
  bool _autoDeploy = false;
  String _buildChannel = 'stable';

  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);

    return w.Container(
      padding: const w.EdgeInsets.all(1),
      color: theme.background,
      child: w.Scrollbar(
        controller: _scrollController,
        thickness: 1,
        gap: 1,
        enableHover: true,
        trackChar: ' ',
        thumbChar: ' ',
        trackUsesBackground: true,
        thumbUsesBackground: true,
        trackGradient: w.ScrollbarGradient.background(
          start: w.hasDarkBackground
              ? const BasicColor('#2f363d')
              : const BasicColor('#e3e7eb'),
          end: w.hasDarkBackground
              ? const BasicColor('#1f252a')
              : const BasicColor('#d3d9e0'),
        ),
        thumbGradient: w.ScrollbarGradient.background(
          start: w.hasDarkBackground
              ? const BasicColor('#3fb2ff')
              : const BasicColor('#2f7df6'),
          end: w.hasDarkBackground
              ? const BasicColor('#7c5cff')
              : const BasicColor('#6e55f5'),
        ),
        hoverThumbGradient: w.ScrollbarGradient.background(
          start: w.hasDarkBackground
              ? const BasicColor('#79ddff')
              : const BasicColor('#4f93ff'),
          end: w.hasDarkBackground
              ? const BasicColor('#b18bff')
              : const BasicColor('#836bff'),
        ),
        hoverThumbChar: ' ',
        child: w.ScrollView(
          controller: _scrollController,
          handleKeys: true,
          child: w.Column(
            gap: 1,
            children: [
              w.Text(
                'ListTile, Accordion, ExpansionTile & Tooltip',
                style: theme.titleLarge,
              ),
              w.Text(
                'Try accordions, expansion tiles, and tooltips. q to quit.',
                style: label,
              ),
              w.Divider(width: 55),

              // -- ListTile --
              w.Text('ListTile', style: theme.titleMedium),
              w.ListTile(
                title: 'Release Notes',
                subtitle: 'Today, 9:41 AM',
                leading: w.Icon(w.Icons.star, color: theme.warning),
                trailing: w.Badge('New'),
                selected: true,
              ),
              w.ListTile(
                title: 'System Status',
                subtitle: 'All services healthy',
                leading: w.Icon(w.Icons.check, color: theme.success),
              ),
              w.ListTile(
                title: 'Error Report',
                subtitle: '3 unresolved issues',
                leading: w.Icon(w.Icons.close, color: theme.error),
                trailing: w.Badge(
                  '3',
                  background: theme.error,
                  foreground: theme.onPrimary,
                ),
              ),
              w.ListTile(
                title: 'Dense Item',
                subtitle: 'Compact layout',
                dense: true,
              ),
              w.Divider(width: 55),

              // -- Accordion --
              w.Text('Accordion', style: theme.titleMedium),
              w.Accordion(
                title: 'Getting Started',
                expanded: _acc1,
                onChanged: (val) {
                  setState(() => _acc1 = val);
                  return null;
                },
                child: w.Column(
                  gap: 0,
                  children: [
                    w.Text(
                      '1. Install the artisanal package',
                      style: theme.bodySmall,
                    ),
                    w.Text('2. Create a WidgetApp', style: theme.bodySmall),
                    w.Text('3. Run with dart run', style: theme.bodySmall),
                  ],
                ),
              ),
              w.Accordion(
                title: 'Advanced Topics',
                expanded: _acc2,
                onChanged: (val) {
                  setState(() => _acc2 = val);
                  return null;
                },
                child: w.Text(
                  'Custom themes, scroll controllers, focus management.',
                  style: theme.bodySmall,
                ),
              ),
              w.Accordion(
                title: 'Disabled Section',
                expanded: false,
                enabled: false,
                child: w.Text('Hidden', style: theme.bodySmall),
              ),
              w.Divider(width: 55),

              // -- ExpansionTile + control list tiles --
              w.Text(
                'ExpansionTile + Control ListTiles',
                style: theme.titleMedium,
              ),
              w.ExpansionTile(
                initiallyExpanded: true,
                title: 'Workspace Preferences',
                subtitle: _expSettingsOpen ? 'Open' : 'Closed',
                onExpansionChanged: (value) {
                  setState(() => _expSettingsOpen = value);
                  return null;
                },
                children: [
                  w.CheckboxListTile(
                    value: _emailAlerts,
                    title: 'Email alerts',
                    subtitle: 'Notify me when builds fail',
                    onChanged: (value) {
                      setState(() => _emailAlerts = value);
                      return null;
                    },
                  ),
                  w.SwitchListTile(
                    value: _autoDeploy,
                    title: 'Auto deploy',
                    subtitle: 'Deploy automatically after green CI',
                    onChanged: (value) {
                      setState(() => _autoDeploy = value);
                      return null;
                    },
                  ),
                  w.RadioListTile<String>(
                    value: 'stable',
                    groupValue: _buildChannel,
                    title: 'Stable channel',
                    onChanged: (value) {
                      setState(() => _buildChannel = value);
                      return null;
                    },
                  ),
                  w.RadioListTile<String>(
                    value: 'beta',
                    groupValue: _buildChannel,
                    title: 'Beta channel',
                    onChanged: (value) {
                      setState(() => _buildChannel = value);
                      return null;
                    },
                  ),
                ],
              ),
              w.ExpansionTile(
                title: 'Integrations',
                subtitle: _expIntegrationsOpen
                    ? '2 connected services'
                    : 'Click to expand',
                trailing: w.Badge(_expIntegrationsOpen ? 'Open' : 'Closed'),
                onExpansionChanged: (value) {
                  setState(() => _expIntegrationsOpen = value);
                  return null;
                },
                children: [
                  w.ListTile(
                    title: 'GitHub',
                    subtitle: 'Connected',
                    leading: w.Icon(w.Icons.check, color: theme.success),
                    dense: true,
                  ),
                  w.ListTile(
                    title: 'Slack',
                    subtitle: 'Connected',
                    leading: w.Icon(w.Icons.check, color: theme.success),
                    dense: true,
                  ),
                ],
              ),
              w.Divider(width: 55),

              // -- Tooltip --
              w.Text('Tooltip (hover over buttons)', style: theme.titleMedium),
              w.Row(
                gap: 2,
                children: [
                  w.Tooltip(
                    message: 'Save your work',
                    position: w.TooltipPosition.above,
                    child: w.Button(
                      label: 'Save',
                      size: w.ButtonSize.small,
                      onPressed: () => null,
                    ),
                  ),
                  w.Tooltip(
                    message: 'Delete permanently',
                    position: w.TooltipPosition.below,
                    child: w.Button(
                      label: 'Delete',
                      variant: w.ButtonVariant.danger,
                      size: w.ButtonSize.small,
                      onPressed: () => null,
                    ),
                  ),
                  w.Tooltip(
                    message: 'Custom styled tooltip',
                    background: theme.primary,
                    foreground: theme.onPrimary,
                    child: w.Text('Hover me', style: label),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg && msg.key.char == 'q') {
      return tui.Cmd.quit();
    }
    return null;
  }
}
