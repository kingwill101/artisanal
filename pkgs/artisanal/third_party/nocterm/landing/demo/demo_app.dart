import 'package:nocterm/nocterm.dart';

void main() async {
  await runApp(const DemoApp());
}

class DemoApp extends StatefulComponent {
  const DemoApp({super.key});

  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  int _selectedIndex = 0;
  int _counter = 0;

  final _items = [
    'Counter',
    'Colors',
    'Components',
    'About',
  ];

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        print('Key event received: ${event.logicalKey}');
        if (event.logicalKey == LogicalKey.arrowUp ||
            event.logicalKey == LogicalKey.keyK) {
          print('Arrow up or K - moving up');
          setState(() {
            _selectedIndex = (_selectedIndex - 1).clamp(0, _items.length - 1);
          });
          return true;
        } else if (event.logicalKey == LogicalKey.arrowDown ||
            event.logicalKey == LogicalKey.keyJ) {
          print('Arrow down or J - moving down');
          setState(() {
            _selectedIndex = (_selectedIndex + 1).clamp(0, _items.length - 1);
          });
          return true;
        } else if (event.logicalKey == LogicalKey.space ||
            event.logicalKey == LogicalKey.enter) {
          print('Space or Enter - incrementing counter');
          if (_selectedIndex == 0) {
            setState(() => _counter++);
          }
          return true;
        } else if (event.logicalKey == LogicalKey.keyR) {
          print('R - resetting counter');
          setState(() => _counter = 0);
          return true;
        }
        return false;
      },
      child: Container(
        decoration: BoxDecoration(
          border: BoxBorder.all(color: Colors.blue),
        ),
        child: Column(
          children: [
            // Header
            Container(
              decoration: const BoxDecoration(color: Colors.blue),
              child: Row(
                children: [
                  Text(
                    ' nocterm demo ',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    ' j/k:navigate  Enter:select  r:reset ',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Row(
                children: [
                  // Sidebar
                  Container(
                    width: 16,
                    decoration: const BoxDecoration(
                      border: BoxBorder(right: BorderSide(color: Colors.blue)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < _items.length; i++)
                          _MenuItem(
                            label: _items[i],
                            selected: i == _selectedIndex,
                          ),
                      ],
                    ),
                  ),
                  // Main content
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(1),
                      child: _buildContent(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Component _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _CounterContent(count: _counter);
      case 1:
        return const _ColorsContent();
      case 2:
        return const _ComponentsContent();
      case 3:
        return const _AboutContent();
      default:
        return const Text('Select an item');
    }
  }
}

class _MenuItem extends StatelessComponent {
  final String label;
  final bool selected;

  const _MenuItem({required this.label, required this.selected});

  @override
  Component build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: selected ? Colors.blue : null,
      ),
      child: Row(
        children: [
          Text(
            selected ? ' > ' : '   ',
            style: TextStyle(
              color: selected ? Colors.white : Colors.blue,
            ),
          ),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.gray,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CounterContent extends StatelessComponent {
  final int count;

  const _CounterContent({required this.count});

  @override
  Component build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Counter Demo',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan),
        ),
        const SizedBox(height: 1),
        const Text('Press SPACE or ENTER to increment'),
        const Text('Press R to reset'),
        const SizedBox(height: 1),
        Row(
          children: [
            const Text('Count: '),
            Text(
              '$count',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 1),
        _ProgressBar(value: count % 20, max: 20),
      ],
    );
  }
}

class _ProgressBar extends StatelessComponent {
  final int value;
  final int max;

  const _ProgressBar({required this.value, required this.max});

  @override
  Component build(BuildContext context) {
    final filled = (value * 20 / max).round();
    final empty = 20 - filled;

    return Row(
      children: [
        const Text('['),
        Text(
          '=' * filled,
          style: TextStyle(color: Colors.green),
        ),
        Text(
          '-' * empty,
          style: TextStyle(color: Colors.gray),
        ),
        const Text(']'),
        Text(' $value/$max'),
      ],
    );
  }
}

class _ColorsContent extends StatelessComponent {
  const _ColorsContent();

  @override
  Component build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Color Palette',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan),
        ),
        const SizedBox(height: 1),
        const Text('Standard ANSI colors:'),
        Row(
          children: [
            Container(width: 2, decoration: BoxDecoration(color: Colors.black)),
            Container(width: 2, decoration: BoxDecoration(color: Colors.red)),
            Container(width: 2, decoration: BoxDecoration(color: Colors.green)),
            Container(
                width: 2, decoration: BoxDecoration(color: Colors.yellow)),
            Container(width: 2, decoration: BoxDecoration(color: Colors.blue)),
            Container(
                width: 2, decoration: BoxDecoration(color: Colors.magenta)),
            Container(width: 2, decoration: BoxDecoration(color: Colors.cyan)),
            Container(width: 2, decoration: BoxDecoration(color: Colors.white)),
          ],
        ),
        const SizedBox(height: 1),
        const Text('Text styles:'),
        const Text('Normal text'),
        Text('Bold text', style: TextStyle(fontWeight: FontWeight.bold)),
        Text('Italic text', style: TextStyle(fontStyle: FontStyle.italic)),
        Text('Colored text', style: TextStyle(color: Colors.magenta)),
      ],
    );
  }
}

class _ComponentsContent extends StatelessComponent {
  const _ComponentsContent();

  @override
  Component build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Component Library',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan),
        ),
        const SizedBox(height: 1),
        Text('Layout', style: TextStyle(color: Colors.yellow)),
        const Text('  Row, Column, Stack, Expanded'),
        const SizedBox(height: 1),
        Text('Scrolling', style: TextStyle(color: Colors.yellow)),
        const Text('  ListView, SingleChildScrollView'),
        const SizedBox(height: 1),
        Text('Input', style: TextStyle(color: Colors.yellow)),
        const Text('  TextField, Focusable, Button'),
        const SizedBox(height: 1),
        Text(
          '45+ components total!',
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _AboutContent extends StatelessComponent {
  const _AboutContent();

  @override
  Component build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About nocterm',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan),
        ),
        const SizedBox(height: 1),
        const Text('Flutter-inspired TUI framework'),
        const Text('for Dart terminal applications.'),
        const SizedBox(height: 1),
        Text('Features:', style: TextStyle(color: Colors.yellow)),
        const Text('  * Declarative UI'),
        const Text('  * Hot reload'),
        const Text('  * Built-in testing'),
        const Text('  * 6 themes'),
        const SizedBox(height: 1),
        Text(
          'pub.dev/packages/nocterm',
          style: TextStyle(color: Colors.blue),
        ),
      ],
    );
  }
}
