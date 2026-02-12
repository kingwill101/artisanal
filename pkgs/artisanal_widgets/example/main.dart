//
// Demonstrates widgets, layout, theming, and hit-test-driven mouse events.
//
// Run with: dart run example/main.dart

import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;
import 'package:artisanal/tui.dart' show TuiTrace;

void _trace(String msg) {
  TuiTrace.log('EXAMPLE $msg');
}

void main() async {
  final app = tui.WidgetApp(AppWidget());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(altScreen: true, mouse: true),
  );
}

class AppWidget extends tui.StatefulWidget {
  AppWidget({super.key});

  @override
  tui.State createState() => _AppWidgetState();
}

class _AppWidgetState extends tui.State<AppWidget> {
  int _counter = 0;
  int _selectedTab = 0;
  int? _hoveredTab;

  final ClickCounter _clickCounter = ClickCounter(
    key: w.ValueKey<String>('click-counter'),
  );

  bool _checkboxValue = true;
  bool _switchValue = false;
  int _radioValue = 1;
  String _selectValue = 'Alpha';
  int _componentSection = 0;
  int _page = 1;
  bool _accordionExpanded = true;
  bool _modalOpen = false;
  bool _drawerOpen = false;
  double _progressValue = 0.35;
  String _lastAction = 'None';

  final List<tui.TabItem> _componentTabs = const [
    tui.TabItem('Core'),
    tui.TabItem('Forms'),
    tui.TabItem('Layout'),
    tui.TabItem('Overlays'),
  ];

  final List<tui.SelectOption<String>> _selectOptions = const [
    tui.SelectOption(label: 'Alpha', value: 'Alpha'),
    tui.SelectOption(label: 'Beta', value: 'Beta'),
    tui.SelectOption(label: 'Gamma', value: 'Gamma'),
  ];

  tui.Theme get theme => widget.theme;

  @override
  tui.Widget build(tui.BuildContext context) {
    _trace(
      'build _counter=$_counter _selectedTab=$_selectedTab _componentSection=$_componentSection',
    );
    final media = tui.MediaQuery.of(context);
    final width = media.size.width.round();
    media.size.height.round();

    return tui.Column(
      gap: 1,
      children: [
        _buildHeader(width),
        _buildTabs(),
        _buildBody(width),
        tui.Divider(width: width > 0 ? width : 72),
        _buildFooter(),
      ],
    );
  }

  tui.Widget _buildHeader(int width) {
    return tui.SizedBox(
      width: width > 0 ? width : null,
      child: tui.Frame(
        padding: const tui.EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        background: theme.surface,
        child: tui.Row(
          mainAxisSize: tui.MainAxisSize.max,
          mainAxisAlignment: tui.MainAxisAlignment.spaceBetween,
          children: [
            tui.Row(
              gap: 1,
              children: [
                tui.Icon(tui.Icons.star, color: theme.warning),
                tui.Text('Widget + Zone Demo', style: theme.titleLarge),
              ],
            ),
            tui.Text('Counter: $_counter', style: theme.bodyMedium),
          ],
        ),
      ),
    );
  }

  tui.Widget _buildTabs() {
    return tui.Row(
      gap: 2,
      children: [
        _tab(0, 'Layout'),
        _tab(1, 'Theme'),
        _tab(2, 'Stack'),
        _tab(3, 'Components'),
      ],
    );
  }

  tui.Widget _tab(int index, String label) {
    final isSelected = _selectedTab == index;
    final isHovered = _hoveredTab == index;
    // Trace which tab is selected during build
    if (isSelected) {
      _trace('_tab($index, $label) isSelected=true');
    }

    final bg = isSelected
        ? theme.primary
        : isHovered
        ? theme.surface
        : theme.background;
    final fg = isSelected ? theme.onPrimary : theme.onSurface;
    final style = (isSelected ? theme.labelLarge : theme.bodyMedium)
        .copy()
        .foreground(fg);

    return tui.GestureDetector(
      key: w.ValueKey<int>(index),
      onTap: () {
        _trace('tab.onTap index=$index _selectedTab(before)=$_selectedTab');
        setState(() => _selectedTab = index);
        _trace('tab.onTap _selectedTab(after)=$_selectedTab');
        return null;
      },
      onEnter: (_) {
        setState(() => _hoveredTab = index);
        return null;
      },
      onExit: (_) {
        if (_hoveredTab == index) {
          setState(() => _hoveredTab = null);
        }
        return null;
      },
      child: tui.Container(
        padding: const tui.EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
        color: bg,
        child: tui.Text(label, style: style),
      ),
    );
  }

  tui.Widget _buildBody(int width) {
    final isWide = width >= 96;
    final contentPanel = tui.Frame(
      padding: const tui.EdgeInsets.all(1),
      background: theme.surface,
      child: _contentForTab(width),
    );
    final sidePanel = tui.Column(
      gap: 1,
      children: [_clickCounter, _buildTips()],
    );
    final bodyLayout = isWide
        ? tui.Row(
            gap: 2,
            children: [
              tui.Expanded(child: contentPanel),
              tui.SizedBox(width: 24, child: sidePanel),
            ],
          )
        : contentPanel;

    return tui.SizedBox(
      width: width > 0 ? width : null,
      child: tui.Frame(
        padding: const tui.EdgeInsets.symmetric(horizontal: 1),
        child: bodyLayout,
      ),
    );
  }

  tui.Widget _contentForTab(int width) {
    switch (_selectedTab) {
      case 0:
        return _layoutDemo();
      case 1:
        return _themeDemo();
      case 2:
        return _stackDemo();
      case 3:
        return _componentsDemo(width);
      default:
        return tui.Text('Unknown tab');
    }
  }

  tui.Widget _layoutDemo() {
    return tui.Column(
      gap: 1,
      children: [
        tui.Text('Row + Column', style: theme.titleMedium),
        tui.Divider(width: 30),
        tui.Row(
          gap: 2,
          children: [
            tui.Container(
              width: 8,
              height: 3,
              color: theme.primary,
              alignment: tui.Alignment.center,
              child: tui.Text('A', style: theme.labelLarge),
            ),
            tui.Container(
              width: 20,
              height: 3,
              color: theme.surface,
              alignment: tui.Alignment.center,
              child: tui.Text('Fixed', style: theme.bodyMedium),
            ),
            tui.Container(
              width: 8,
              height: 3,
              color: theme.secondary,
              alignment: tui.Alignment.center,
              child: tui.Text('C', style: theme.labelLarge),
            ),
          ],
        ),
        tui.Text('Align + Padding + SizedBox', style: theme.labelSmall),
        tui.Row(
          gap: 2,
          children: [
            tui.Padding(
              padding: const tui.EdgeInsets.all(1),
              child: tui.Container(
                color: theme.warning,
                child: tui.Text('Pad', style: theme.labelSmall),
              ),
            ),
            tui.Container(
              width: 14,
              height: 5,
              color: theme.surface,
              child: tui.Align(
                alignment: tui.Alignment.bottomRight,
                child: tui.Text('BR', style: theme.labelSmall),
              ),
            ),
            tui.SizedBox(
              width: 10,
              height: 3,
              child: tui.Container(
                color: theme.primary,
                alignment: tui.Alignment.center,
                child: tui.Text('Box', style: theme.labelSmall),
              ),
            ),
          ],
        ),
        tui.Text('Wrap', style: theme.labelSmall),
        tui.Wrap(
          spacing: 1,
          runSpacing: 1,
          children: [
            _chip('Wrap'),
            _chip('fits'),
            _chip('to'),
            _chip('width'),
            _chip('nicely'),
          ],
        ),
        tui.Text('Spacing uses gap + padding', style: theme.labelSmall),
      ],
    );
  }

  tui.Widget _chip(String label) {
    return tui.Container(
      padding: const tui.EdgeInsets.symmetric(horizontal: 1),
      color: theme.background,
      child: tui.Text(label, style: theme.labelSmall),
    );
  }

  tui.Widget _themeDemo() {
    return tui.Column(
      gap: 1,
      children: [
        tui.Text('Theme Colors', style: theme.titleMedium),
        tui.Divider(width: 30),
        tui.Row(
          gap: 2,
          children: [
            tui.Text('Primary', style: Style().foreground(theme.primary)),
            tui.Text('Secondary', style: Style().foreground(theme.secondary)),
          ],
        ),
        tui.Row(
          gap: 2,
          children: [
            tui.Text('Success', style: Style().foreground(theme.success)),
            tui.Text('Error', style: Style().foreground(theme.error)),
            tui.Text('Warning', style: Style().foreground(theme.warning)),
          ],
        ),
        tui.Row(
          gap: 2,
          children: [
            tui.Text('Muted', style: Style().foreground(theme.muted)),
            tui.Text('Border', style: Style().foreground(theme.border)),
          ],
        ),
      ],
    );
  }

  tui.Widget _stackDemo() {
    return tui.Column(
      gap: 1,
      children: [
        tui.Text('Stack + Positioned', style: theme.titleMedium),
        tui.Divider(width: 30),
        tui.Stack(
          width: 32,
          height: 6,
          alignment: tui.Alignment.center,
          children: [
            tui.Container(
              width: 32,
              height: 6,
              color: theme.surface,
              alignment: tui.Alignment.center,
              child: tui.Text('Base Panel', style: theme.bodyMedium),
            ),
            tui.Positioned(
              right: 1,
              top: 0,
              child: tui.Text('Badge', style: theme.labelSmall),
            ),
            tui.Positioned(
              left: 1,
              bottom: 0,
              child: tui.Text('Bottom Left', style: theme.labelSmall),
            ),
          ],
        ),
      ],
    );
  }

  tui.Widget _componentsDemo(int width) {
    final isWide = width >= 110;
    final sections = switch (_componentSection) {
      0 => [_panelButtons(), _panelIndicators()],
      1 => [_panelInputs(), _panelSelect()],
      2 => [_panelNavigation(), _panelData(), _panelLayout()],
      _ => [_panelOverlays()],
    };

    final header = tui.Tabs(
      tabs: _componentTabs,
      index: _componentSection,
      onChanged: (index) {
        setState(() => _componentSection = index);
        return null;
      },
    );

    final body = isWide && sections.length > 1
        ? _splitColumns(sections)
        : tui.Column(gap: 1, children: sections);

    return tui.Column(gap: 1, children: [header, body]);
  }

  tui.Widget _splitColumns(List<tui.Widget> sections) {
    final split = (sections.length / 2).ceil();
    final left = sections.sublist(0, split);
    final right = sections.sublist(split);
    return tui.Row(
      gap: 2,
      children: [
        tui.Expanded(child: tui.Column(gap: 1, children: left)),
        tui.Expanded(child: tui.Column(gap: 1, children: right)),
      ],
    );
  }

  tui.Widget _panelButtons() {
    return tui.PanelBox(
      title: 'Buttons + Badges',
      child: tui.Column(
        gap: 1,
        children: [
          tui.Row(
            gap: 1,
            children: [
              tui.Button(
                label: 'Primary',
                onPressed: () {
                  setState(() => _lastAction = 'Primary');
                  return null;
                },
              ),
              tui.Button(
                label: 'Secondary',
                variant: tui.ButtonVariant.secondary,
                onPressed: () {
                  setState(() => _lastAction = 'Secondary');
                  return null;
                },
              ),
              tui.Button(
                label: 'Outline',
                variant: tui.ButtonVariant.outline,
                onPressed: () {
                  setState(() => _lastAction = 'Outline');
                  return null;
                },
              ),
            ],
          ),
          tui.Row(
            gap: 1,
            children: [
              tui.Button(
                label: 'Ghost',
                variant: tui.ButtonVariant.ghost,
                onPressed: () {
                  setState(() => _lastAction = 'Ghost');
                  return null;
                },
              ),
              tui.Button(
                label: 'Danger',
                variant: tui.ButtonVariant.danger,
                onPressed: () {
                  setState(() => _lastAction = 'Danger');
                  return null;
                },
              ),
              tui.Button(label: 'Disabled', enabled: false),
            ],
          ),
          tui.Row(
            gap: 1,
            children: [
              tui.Button(
                label: 'Small',
                size: tui.ButtonSize.small,
                onPressed: () {
                  setState(() => _lastAction = 'Small');
                  return null;
                },
              ),
              tui.Button(
                label: 'Medium',
                size: tui.ButtonSize.medium,
                onPressed: () {
                  setState(() => _lastAction = 'Medium');
                  return null;
                },
              ),
              tui.Button(
                label: 'Large',
                size: tui.ButtonSize.large,
                onPressed: () {
                  setState(() => _lastAction = 'Large');
                  return null;
                },
              ),
            ],
          ),
          tui.Row(
            gap: 1,
            children: [
              tui.Badge('New'),
              tui.Badge(
                'Beta',
                background: theme.warning,
                foreground: theme.onPrimary,
              ),
              tui.Badge(
                'Muted',
                background: theme.surface,
                foreground: theme.onSurface,
              ),
            ],
          ),
          tui.Text('Last action: $_lastAction', style: theme.labelSmall),
        ],
      ),
    );
  }

  tui.Widget _panelInputs() {
    return tui.PanelBox(
      title: 'Inputs',
      child: tui.Column(
        gap: 1,
        children: [
          tui.Checkbox(
            value: _checkboxValue,
            label: tui.Text('Email alerts'),
            onChanged: (value) {
              setState(() => _checkboxValue = value);
              return null;
            },
          ),
          tui.Switch(
            value: _switchValue,
            label: tui.Text('Auto sync'),
            onChanged: (value) {
              setState(() => _switchValue = value);
              return null;
            },
          ),
          tui.Column(
            gap: 0,
            children: [
              tui.Radio<int>(
                value: 1,
                groupValue: _radioValue,
                label: tui.Text('Alpha'),
                onChanged: (value) {
                  setState(() => _radioValue = value);
                  return null;
                },
              ),
              tui.Radio<int>(
                value: 2,
                groupValue: _radioValue,
                label: tui.Text('Beta'),
                onChanged: (value) {
                  setState(() => _radioValue = value);
                  return null;
                },
              ),
              tui.Radio<int>(
                value: 3,
                groupValue: _radioValue,
                label: tui.Text('Gamma'),
                onChanged: (value) {
                  setState(() => _radioValue = value);
                  return null;
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  tui.Widget _panelSelect() {
    return tui.PanelBox(
      title: 'Select + Status',
      child: tui.Column(
        gap: 1,
        children: [
          tui.Select<String>(
            options: _selectOptions,
            value: _selectValue,
            onChanged: (value) {
              setState(() => _selectValue = value);
              return null;
            },
          ),
          tui.Text('Selected: $_selectValue', style: theme.labelSmall),
        ],
      ),
    );
  }

  tui.Widget _panelIndicators() {
    return tui.PanelBox(
      title: 'Indicators',
      child: tui.Column(
        gap: 1,
        children: [
          tui.Row(
            gap: 2,
            children: [
              tui.ProgressIndicator(value: _progressValue, showLabel: true),
              tui.SpinnerIndicator(key: w.ValueKey<String>('spinner')),
            ],
          ),
          tui.Button(
            label: 'Advance',
            size: .small,
            onPressed: () {
              setState(() {
                final next = _progressValue + 0.1;
                _progressValue = next > 1 ? 0 : next;
              });
              return null;
            },
          ),
        ],
      ),
    );
  }

  tui.Widget _panelNavigation() {
    return tui.PanelBox(
      title: 'Navigation',
      child: tui.Column(
        gap: 1,
        children: [
          tui.Breadcrumbs(
            items: [
              tui.BreadcrumbItem(
                'Home',
                onTap: () {
                  setState(() => _lastAction = 'Home');
                  return null;
                },
              ),
              tui.BreadcrumbItem(
                'Projects',
                onTap: () {
                  setState(() => _lastAction = 'Projects');
                  return null;
                },
              ),
              const tui.BreadcrumbItem('Widgets'),
            ],
          ),
          tui.Pagination(
            page: _page,
            pageCount: 12,
            onChanged: (value) {
              setState(() => _page = value);
              return null;
            },
          ),
        ],
      ),
    );
  }

  tui.Widget _panelData() {
    return tui.PanelBox(
      title: 'Lists + Accordion',
      child: tui.Column(
        gap: 1,
        children: [
          tui.ListTile(
            title: 'Release Notes',
            subtitle: 'Today, 9:41 AM',
            leading: tui.Icon(tui.Icons.star, color: theme.primary),
            trailing: tui.Badge('New'),
            selected: true,
          ),
          tui.ListTile(
            title: 'System Status',
            subtitle: 'All services healthy',
            leading: tui.Icon(tui.Icons.check, color: theme.success),
          ),
          tui.Accordion(
            title: 'More details',
            expanded: _accordionExpanded,
            onChanged: (value) {
              setState(() => _accordionExpanded = value);
              return null;
            },
            child: tui.Text(
              'Accordions let you show and hide extra context.',
              style: theme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  tui.Widget _panelLayout() {
    final scrollContent = tui.Column(
      gap: 0,
      children: [
        for (var i = 0; i < 8; i++)
          tui.Text('Scrollable line ${i + 1}', style: theme.labelSmall),
      ],
    );

    return tui.PanelBox(
      title: 'Layout',
      child: tui.Column(
        gap: 1,
        children: [
          tui.SplitView(
            gap: 2,
            first: tui.Container(
              color: theme.background,
              padding: const tui.EdgeInsets.all(1),
              child: tui.Text('Left pane', style: theme.labelSmall),
            ),
            second: tui.Container(
              color: theme.background,
              padding: const tui.EdgeInsets.all(1),
              child: tui.Text('Right pane', style: theme.labelSmall),
            ),
          ),
          tui.Sidebar(
            width: 14,
            sidebar: tui.Container(
              color: theme.background,
              padding: const tui.EdgeInsets.all(1),
              child: tui.Text('Nav', style: theme.labelSmall),
            ),
            child: tui.Container(
              color: theme.surface,
              padding: const tui.EdgeInsets.all(1),
              child: tui.Text('Content', style: theme.labelSmall),
            ),
          ),
          tui.ScrollArea(
            height: 4,
            width: 32,
            showScrollbar: true,
            child: scrollContent,
          ),
        ],
      ),
    );
  }

  tui.Widget _panelOverlays() {
    final modalDialog = tui.Card(
      padding: const tui.EdgeInsets.all(1),
      child: tui.Column(
        gap: 1,
        children: [
          tui.Text('Modal Dialog', style: theme.titleSmall),
          tui.Text('Press close to dismiss.', style: theme.bodySmall),
          tui.Button(
            label: 'Close',
            size: tui.ButtonSize.small,
            onPressed: () {
              setState(() => _modalOpen = false);
              return null;
            },
          ),
        ],
      ),
    );

    final drawerPanel = tui.Container(
      color: theme.surface,
      padding: const tui.EdgeInsets.all(1),
      child: tui.Column(
        gap: 1,
        children: [
          tui.Text('Drawer', style: theme.titleSmall),
          tui.Text('Side panel content', style: theme.bodySmall),
          tui.Button(
            label: 'Close',
            size: tui.ButtonSize.small,
            onPressed: () {
              setState(() => _drawerOpen = false);
              return null;
            },
          ),
        ],
      ),
    );

    final modalPreview = tui.Modal(
      open: _modalOpen,
      onDismiss: () {
        setState(() => _modalOpen = false);
        return null;
      },
      dialog: modalDialog,
      child: tui.Container(
        color: theme.background,
        padding: const tui.EdgeInsets.all(1),
        child: tui.Row(
          gap: 1,
          children: [
            tui.Text('Modal preview', style: theme.labelSmall),
            tui.Button(
              label: 'Open',
              size: tui.ButtonSize.small,
              onPressed: () {
                setState(() => _modalOpen = true);
                return null;
              },
            ),
          ],
        ),
      ),
    );

    final drawerPreview = tui.Drawer(
      open: _drawerOpen,
      width: 20,
      onDismiss: () {
        setState(() => _drawerOpen = false);
        return null;
      },
      drawer: drawerPanel,
      child: tui.Container(
        color: theme.background,
        padding: const tui.EdgeInsets.all(1),
        child: tui.Row(
          gap: 1,
          children: [
            tui.Text('Drawer preview', style: theme.labelSmall),
            tui.Button(
              label: 'Open',
              size: tui.ButtonSize.small,
              onPressed: () {
                setState(() => _drawerOpen = true);
                return null;
              },
            ),
          ],
        ),
      ),
    );

    return tui.PanelBox(
      title: 'Overlays + Tooltip',
      child: tui.Column(
        gap: 1,
        children: [
          tui.Tooltip(
            message: 'Hover to preview tooltips',
            child: tui.Button(
              label: 'Hover me',
              size: tui.ButtonSize.small,
              onPressed: () {
                setState(() => _lastAction = 'Tooltip');
                return null;
              },
            ),
          ),
          modalPreview,
          drawerPreview,
        ],
      ),
    );
  }

  tui.Widget _buildTips() {
    return tui.SizedBox(
      width: 20,
      height: 7,
      child: tui.Frame(
        padding: const tui.EdgeInsets.all(1),
        background: theme.surface,
        child: tui.Column(
          gap: 1,
          children: [
            tui.Text('Mouse', style: theme.labelLarge),
            tui.Text('Click tabs', style: theme.labelSmall),
            tui.Text('Hover buttons', style: theme.labelSmall),
            tui.Text('Scroll for more', style: theme.labelSmall),
          ],
        ),
      ),
    );
  }

  tui.Widget _buildFooter() {
    return tui.Row(
      gap: 3,
      children: [
        tui.Text('1-4: tabs', style: theme.labelSmall),
        tui.Text('+/-: counter', style: theme.labelSmall),
        tui.Text('q: quit', style: theme.labelSmall),
      ],
    );
  }

  @override
  tui.Cmd? handleUpdate(tui.Msg msg) {
    if (msg is tui.KeyMsg) {
      final key = msg.key;
      _trace(
        'handleUpdate KeyMsg char=${key.char} type=${key.type} _counter=$_counter _selectedTab=$_selectedTab mounted=$mounted',
      );

      if (key.char == 'q' || key.char == 'Q') {
        return tui.Cmd.quit();
      }

      if (key.char == '+' || key.char == '=') {
        final before = _counter;
        setState(() => _counter++);
        _trace('handleUpdate +/= _counter $before -> $_counter');
      }
      if (key.char == '-') {
        final before = _counter;
        setState(() => _counter--);
        _trace('handleUpdate - _counter $before -> $_counter');
      }

      if (key.char == '1') {
        setState(() => _selectedTab = 0);
        _trace('handleUpdate tab -> 0');
      }
      if (key.char == '2') {
        setState(() => _selectedTab = 1);
        _trace('handleUpdate tab -> 1');
      }
      if (key.char == '3') {
        setState(() => _selectedTab = 2);
        _trace('handleUpdate tab -> 2');
      }
      if (key.char == '4') {
        setState(() => _selectedTab = 3);
        _trace('handleUpdate tab -> 3');
      }
    }

    if (msg is tui.ZoneInBoundsMsg) {
      _trace('handleUpdate ZoneInBoundsMsg zone=${msg.zone.id}');
    }

    return null;
  }
}

class ClickCounter extends tui.StatefulWidget {
  ClickCounter({super.key});

  @override
  tui.State createState() => _ClickCounterState();
}

class _ClickCounterState extends tui.State<ClickCounter> {
  int _clicks = 0;

  tui.Theme get theme => widget.theme;

  @override
  tui.Widget build(tui.BuildContext context) {
    return tui.GestureDetector(
      onTap: () {
        setState(() => _clicks++);
        return null;
      },
      child: tui.Stack(
        width: 20,
        height: 6,
        alignment: tui.Alignment.center,
        children: [
          tui.Container(
            width: 20,
            height: 6,
            color: theme.surface,
            alignment: tui.Alignment.center,
            child: tui.Column(
              gap: 1,
              children: [
                tui.Text('Clicks', style: theme.labelLarge),
                tui.Text('$_clicks', style: theme.titleMedium),
              ],
            ),
          ),
          tui.Positioned(
            right: 1,
            top: 0,
            child: tui.Text('tap', style: theme.labelSmall),
          ),
        ],
      ),
    );
  }
}
