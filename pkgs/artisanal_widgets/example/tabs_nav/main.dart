// Tabs, Breadcrumbs & Pagination Showcase
//
// Demonstrates Tabs with TabItem, Breadcrumbs with BreadcrumbItem,
// and Pagination with interactive page switching.
//
// Run with: dart run example/tabs_nav/main.dart

import 'package:artisanal/style.dart' hide Padding, Align;
import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/artisanal_widgets.dart' as w;

void main() async {
  final app = tui.WidgetApp(TabsNavShowcase());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouse: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class TabsNavShowcase extends w.StatefulWidget {
  TabsNavShowcase({super.key});

  @override
  w.State createState() => _TabsNavShowcaseState();
}

class _TabsNavShowcaseState extends w.State<TabsNavShowcase> {
  final w.WidgetScrollController _scrollController = w.WidgetScrollController();
  int _tabIndex = 0;
  int _page = 1;
  String _lastBreadcrumb = 'Widgets';

  static const _tabs = [
    w.TabItem('Overview'),
    w.TabItem('Details'),
    w.TabItem('Settings'),
    w.TabItem('Disabled', enabled: false),
  ];

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
              w.Text('Tabs, Breadcrumbs & Pagination', style: theme.titleLarge),
              w.Text('Click to navigate. q to quit.', style: label),
              w.Divider(width: 55),

              // -- Tabs --
              w.Text('Tabs', style: theme.titleMedium),
              w.Tabs(
                tabs: _tabs,
                index: _tabIndex,
                onChanged: (index) {
                  setState(() => _tabIndex = index);
                  return null;
                },
              ),
              w.Container(
                width: 40,
                height: 3,
                color: theme.surface,
                alignment: w.Alignment.center,
                child: w.Text(
                  'Tab content: ${_tabs[_tabIndex].label}',
                  style: theme.bodyMedium,
                ),
              ),
              w.Divider(width: 55),

              // -- Breadcrumbs --
              w.Text('Breadcrumbs', style: theme.titleMedium),
              w.Breadcrumbs(
                items: [
                  w.BreadcrumbItem(
                    'Home',
                    onTap: () {
                      setState(() => _lastBreadcrumb = 'Home');
                      return null;
                    },
                  ),
                  w.BreadcrumbItem(
                    'Projects',
                    onTap: () {
                      setState(() => _lastBreadcrumb = 'Projects');
                      return null;
                    },
                  ),
                  w.BreadcrumbItem(
                    'Artisanal',
                    onTap: () {
                      setState(() => _lastBreadcrumb = 'Artisanal');
                      return null;
                    },
                  ),
                  const w.BreadcrumbItem('Widgets'),
                ],
              ),
              w.Text('Current: $_lastBreadcrumb', style: label),

              // Breadcrumbs with custom separator
              w.Breadcrumbs(
                separator: '>',
                gap: 1,
                items: [
                  const w.BreadcrumbItem('Root'),
                  const w.BreadcrumbItem('Folder'),
                  const w.BreadcrumbItem('File.dart'),
                ],
              ),
              w.Divider(width: 55),

              // -- Pagination --
              w.Text('Pagination', style: theme.titleMedium),
              w.Pagination(
                page: _page,
                pageCount: 10,
                onChanged: (page) {
                  setState(() => _page = page);
                  return null;
                },
              ),
              w.Text('Page: $_page / 10', style: label),

              // Pagination with edges
              w.Text('Pagination (showEdges)', style: theme.labelMedium),
              w.Pagination(
                page: _page,
                pageCount: 10,
                showEdges: true,
                onChanged: (page) {
                  setState(() => _page = page);
                  return null;
                },
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
