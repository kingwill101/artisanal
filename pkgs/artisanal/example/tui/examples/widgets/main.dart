// Widget Composition Example
//
// Demonstrates the widget system for building composable TUI components.
//
// Run with: dart run example/tui/examples/widgets/main.dart

import 'package:artisanal/tui.dart';
import 'package:artisanal/style.dart';

void main() async {
  // Optionally set a theme
  // setTheme(Theme.light());

  await runProgram(AppWidget(), options: const ProgramOptions(altScreen: true));
}

/// Main application widget demonstrating composition.
class AppWidget extends Widget {
  @override
  String get id => 'app';

  int _counter = 0;
  int _selectedTab = 0;

  @override
  Object view() {
    return VBox(
      gap: 1,
      children: [_buildHeader(), _buildTabs(), _buildContent(), _buildFooter()],
    ).view();
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: HBox(
        children: [
          Label('Widget Demo', style: theme.titleLarge),
          Spacer(size: 20),
          Label('Counter: $_counter', style: theme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return HBox(
      gap: 2,
      children: [_tab('Layout', 0), _tab('Theme', 1), _tab('Nesting', 2)],
    );
  }

  Widget _tab(String label, int index) {
    final isSelected = _selectedTab == index;
    final style = isSelected
        ? Style().bold().foreground(theme.primary)
        : Style().foreground(theme.muted);
    final prefix = isSelected ? '>' : ' ';
    return Label('$prefix $label', style: style);
  }

  Widget _buildContent() {
    return Container(
      padding: const EdgeInsets.all(1),
      width: 50,
      height: 10,
      background: theme.surface,
      child: _contentForTab(),
    );
  }

  Widget _contentForTab() {
    switch (_selectedTab) {
      case 0:
        return _layoutDemo();
      case 1:
        return _themeDemo();
      case 2:
        return _nestingDemo();
      default:
        return Label('Unknown tab');
    }
  }

  Widget _layoutDemo() {
    return VBox(
      gap: 1,
      children: [
        Label('Layout Widgets', style: theme.titleMedium),
        Divider(width: 30),
        HBox(
          gap: 3,
          children: [Label('HBox'), Label('arranges'), Label('horizontally')],
        ),
        VBox(children: [Label('VBox'), Label('stacks'), Label('vertically')]),
      ],
    );
  }

  Widget _themeDemo() {
    return VBox(
      gap: 1,
      children: [
        Label('Theme Colors', style: theme.titleMedium),
        Divider(width: 30),
        HBox(
          gap: 2,
          children: [
            Label('Primary', style: Style().foreground(theme.primary)),
            Label('Secondary', style: Style().foreground(theme.secondary)),
          ],
        ),
        HBox(
          gap: 2,
          children: [
            Label('Success', style: Style().foreground(theme.success)),
            Label('Error', style: Style().foreground(theme.error)),
            Label('Warning', style: Style().foreground(theme.warning)),
          ],
        ),
        HBox(
          gap: 2,
          children: [
            Label('Muted', style: Style().foreground(theme.muted)),
            Label('Border', style: Style().foreground(theme.border)),
          ],
        ),
      ],
    );
  }

  Widget _nestingDemo() {
    return VBox(
      children: [
        Label('Nested Widgets', style: theme.titleMedium),
        Divider(width: 30),
        Container(
          padding: const EdgeInsets.all(1),
          background: theme.background,
          child: VBox(
            children: [
              Label('Outer container'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: HBox(
                  gap: 1,
                  children: [Label('[A]'), Label('[B]'), Label('[C]')],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return HBox(
      gap: 3,
      children: [
        Label('1/2/3: tabs', style: theme.labelSmall),
        Label('+/-: counter', style: theme.labelSmall),
        Label('q: quit', style: theme.labelSmall),
      ],
    );
  }

  @override
  (Widget, Cmd?) handleUpdate(Msg msg) {
    if (msg is KeyMsg) {
      final key = msg.key;

      // Quit
      if (key.char == 'q') {
        return (this, Cmd.quit());
      }

      // Counter
      if (key.char == '+' || key.char == '=') {
        _counter++;
        return (this, null);
      }
      if (key.char == '-') {
        _counter--;
        return (this, null);
      }

      // Tabs
      if (key.char == '1') {
        _selectedTab = 0;
        return (this, null);
      }
      if (key.char == '2') {
        _selectedTab = 1;
        return (this, null);
      }
      if (key.char == '3') {
        _selectedTab = 2;
        return (this, null);
      }
    }

    return (this, null);
  }
}
