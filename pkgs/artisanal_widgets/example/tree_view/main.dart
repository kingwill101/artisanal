// TreeView Showcase
import 'package:artisanal_widgets/artisanal_widgets.dart';
//
// Demonstrates TreeView with hierarchical data, icons, nested children,
// and a file-system-like tree structure.
//
// Run with: dart run example/tree_view/main.dart

import 'package:artisanal/tui.dart' as tui;
import 'package:artisanal_widgets/widgets.dart' as w;

void main() async {
  final app = WidgetApp(TreeViewShowcase());
  await tui.runProgram(
    app,
    options: const tui.ProgramOptions(
      altScreen: true,
      mouse: true,
      mouseMode: tui.MouseMode.allMotion,
    ),
  );
}

class TreeViewShowcase extends w.StatefulWidget {
  TreeViewShowcase({super.key});

  @override
  w.State createState() => _TreeViewShowcaseState();
}

class _TreeViewShowcaseState extends w.State<TreeViewShowcase> {
  @override
  w.Widget build(w.BuildContext context) {
    final theme = widget.theme;
    final label = theme.labelSmall.copy()..foreground(theme.onBackground);

    return w.Container(
      padding: const w.EdgeInsets.all(1),
      color: theme.background,
      child: w.Column(
        gap: 1,
        children: [
          w.Text('TreeView Showcase', style: theme.titleLarge),
          w.Text('q: quit', style: label),
          w.Divider(width: 60),

          // -- File system tree --
          w.Text('Project Structure', style: theme.titleMedium),
          w.TreeView(
            nodes: [
              w.TreeViewNode(
                label: 'artisanal',
                icon: '\u{1F4C1}',
                children: [
                  w.TreeViewNode(
                    label: 'lib',
                    icon: '\u{1F4C1}',
                    children: [
                      w.TreeViewNode(
                        label: 'src',
                        icon: '\u{1F4C1}',
                        children: [
                          w.TreeViewNode(
                            label: 'style.dart',
                            icon: '\u{1F4C4}',
                          ),
                          w.TreeViewNode(
                            label: 'terminal.dart',
                            icon: '\u{1F4C4}',
                          ),
                          w.TreeViewNode(label: 'tui.dart', icon: '\u{1F4C4}'),
                        ],
                      ),
                      w.TreeViewNode(
                        label: 'artisanal.dart',
                        icon: '\u{1F4C4}',
                      ),
                    ],
                  ),
                  w.TreeViewNode(
                    label: 'test',
                    icon: '\u{1F4C1}',
                    children: [
                      w.TreeViewNode(
                        label: 'style_test.dart',
                        icon: '\u{1F9EA}',
                      ),
                      w.TreeViewNode(label: 'tui_test.dart', icon: '\u{1F9EA}'),
                    ],
                  ),
                  w.TreeViewNode(label: 'pubspec.yaml', icon: '\u{2699}'),
                  w.TreeViewNode(label: 'README.md', icon: '\u{1F4DD}'),
                ],
              ),
            ],
          ),
          w.Divider(width: 60),

          // -- Simple config tree --
          w.Text('Configuration Hierarchy', style: theme.titleMedium),
          w.TreeView(
            nodes: [
              w.TreeViewNode(
                label: 'database',
                children: [
                  w.TreeViewNode(
                    label: 'primary',
                    children: [
                      w.TreeViewNode(label: 'host: localhost'),
                      w.TreeViewNode(label: 'port: 5432'),
                      w.TreeViewNode(label: 'name: app_db'),
                    ],
                  ),
                  w.TreeViewNode(
                    label: 'replica',
                    children: [
                      w.TreeViewNode(label: 'host: replica-1.local'),
                      w.TreeViewNode(label: 'port: 5432'),
                      w.TreeViewNode(label: 'readonly: true'),
                    ],
                  ),
                ],
              ),
              w.TreeViewNode(
                label: 'cache',
                children: [
                  w.TreeViewNode(label: 'driver: redis'),
                  w.TreeViewNode(label: 'ttl: 3600'),
                ],
              ),
              w.TreeViewNode(
                label: 'logging',
                children: [
                  w.TreeViewNode(label: 'level: info'),
                  w.TreeViewNode(label: 'format: json'),
                ],
              ),
            ],
          ),
          w.Divider(width: 60),

          // -- Single-level flat tree --
          w.Text('Flat List (no nesting)', style: theme.titleMedium),
          w.TreeView(
            nodes: [
              w.TreeViewNode(label: 'Item A'),
              w.TreeViewNode(label: 'Item B'),
              w.TreeViewNode(label: 'Item C'),
            ],
          ),
        ],
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
