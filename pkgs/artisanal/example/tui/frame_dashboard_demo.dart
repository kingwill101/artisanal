import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart';

/// A responsive, core-only TEA dashboard using positioned styled strings.
///
/// Run with:
///
/// ```sh
/// dart run example/tui/frame_dashboard_demo.dart
/// ```
///
/// Use the arrow keys or `j`/`k` to move, Enter to toggle the detail overlay,
/// and `q` to quit.
Future<void> main() async {
  await runProgram(
    DashboardModel(),
    options: const ProgramOptions(altScreen: true),
  );
}

/// Model used by the positioned-frame dashboard example.
final class DashboardModel implements Model {
  DashboardModel({this.selected = 0, this.showOverlay = false});

  static const projects = <({String name, String status, String detail})>[
    (
      name: 'renderer',
      status: 'healthy',
      detail: 'Cell-buffer rendering and terminal diff output.',
    ),
    (
      name: 'runtime',
      status: 'healthy',
      detail: 'TEA message loop, commands, replay, and tracing.',
    ),
    (
      name: 'markdown',
      status: 'building',
      detail: 'ANSI markdown rendering and syntax highlighting.',
    ),
    (
      name: 'charts',
      status: 'healthy',
      detail: 'Sparklines, gauges, histograms, and heatmaps.',
    ),
    (
      name: 'editor',
      status: 'attention',
      detail: 'Text documents, undo history, and decorations.',
    ),
  ];

  int selected;
  bool showOverlay;

  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) {
    switch (msg) {
      case KeyMsg(key: Key(type: KeyType.up)):
      case KeyMsg(key: Key(type: KeyType.runes, runes: [0x6B])):
        selected = (selected - 1).clamp(0, projects.length - 1);
      case KeyMsg(key: Key(type: KeyType.down)):
      case KeyMsg(key: Key(type: KeyType.runes, runes: [0x6A])):
        selected = (selected + 1).clamp(0, projects.length - 1);
      case KeyMsg(key: Key(type: KeyType.enter)):
        showOverlay = !showOverlay;
      case KeyMsg(key: Key(type: KeyType.escape)):
        showOverlay = false;
      case KeyMsg(key: Key(type: KeyType.runes, runes: [0x71])):
        return (this, Cmd.quit());
      case _:
        break;
    }
    return (this, null);
  }

  @override
  Object view() => FrameView(
    content: _fallback(),
    windowTitle: 'Artisanal positioned-frame dashboard',
    paint: (frame) {
      final sections = FrameLayout.vertical(frame.area, const [
        FrameLength(2),
        FrameFill(),
        FrameLength(1),
      ]);
      frame.write(_header(sections[0]), target: sections[0], wrap: false);

      if (sections[1].width >= 60) {
        final panes = FrameLayout.horizontal(sections[1], const [
          FramePercentage(36),
          FrameFill(),
        ], gap: 1);
        frame.write(_projectPane(panes[0]), target: panes[0], wrap: false);
        frame.write(_detailPane(panes[1]), target: panes[1], wrap: false);
      } else {
        final panes = FrameLayout.vertical(sections[1], const [
          FrameFill(),
          FrameFill(),
        ]);
        frame.write(_projectPane(panes[0]), target: panes[0], wrap: false);
        frame.write(_detailPane(panes[1]), target: panes[1], wrap: false);
      }

      frame.write(_footer(sections[2]), target: sections[2], wrap: false);
      if (showOverlay) _paintOverlay(frame);
    },
  );

  String _header(FrameArea area) {
    final title = Style()
        .foreground(Colors.cyan)
        .bold()
        .render('ARTISANAL PROJECT STATUS');
    return Style().width(area.width).render('$title\n${'─' * area.width}');
  }

  String _projectPane(FrameArea area) {
    final rows = <String>[
      Style().foreground(Colors.yellow).bold().render('PROJECTS'),
    ];
    final visibleItems = (area.height - 3).clamp(0, projects.length);
    for (var i = 0; i < visibleItems; i++) {
      final marker = i == selected ? '›' : ' ';
      final text = '$marker ${projects[i].name}';
      rows.add(
        i == selected
            ? Style()
                  .foreground(Colors.black)
                  .background(Colors.cyan)
                  .bold()
                  .width((area.width - 2).clamp(0, area.width))
                  .render(text)
            : text,
      );
    }
    return _panel(rows, area);
  }

  String _detailPane(FrameArea area) {
    final project = projects[selected];
    final statusColor = switch (project.status) {
      'healthy' => Colors.green,
      'building' => Colors.yellow,
      _ => Colors.red,
    };
    return _panel([
      Style().foreground(Colors.yellow).bold().render('DETAIL'),
      '',
      Style().bold().render(project.name),
      Style().foreground(statusColor).render('● ${project.status}'),
      '',
      project.detail,
    ], area);
  }

  String _footer(FrameArea area) => Style()
      .foreground(Colors.gray)
      .width(area.width)
      .render('↑/↓ or j/k: select   enter: inspect   q: quit');

  void _paintOverlay(Frame frame) {
    final area = frame.area.centered(width: 42, height: 7);
    final project = projects[selected];
    frame.write(
      _panel([
        Style().foreground(Colors.cyan).bold().render('INSPECT'),
        '',
        Style().bold().render(project.name),
        project.detail,
        '',
        Style().foreground(Colors.gray).render('enter/esc: close'),
      ], area),
      target: area,
      wrap: false,
    );
  }

  String _panel(List<String> sourceRows, FrameArea area) {
    if (area.width < 2 || area.height < 2) return '';
    final innerWidth = area.width - 2;
    final innerHeight = area.height - 2;
    final rows = sourceRows.take(innerHeight).toList();
    while (rows.length < innerHeight) {
      rows.add('');
    }
    return Style()
        .foreground(Colors.white)
        .border(Border.rounded)
        .width(innerWidth)
        .render(rows.join('\n'));
  }

  String _fallback() {
    final project = projects[selected];
    return 'Projects\n'
        '${projects.map((item) => item.name).join('\n')}\n\n'
        '${project.name}: ${project.detail}';
  }
}
