import 'package:nocterm/nocterm.dart';

void main() async {
  await runApp(const ShowcaseApp());
}

/// Interactive widget showcase - each demo is a standalone interactive widget
/// that users can play with directly in the browser.
class ShowcaseApp extends StatefulComponent {
  const ShowcaseApp({super.key});

  @override
  State<ShowcaseApp> createState() => _ShowcaseAppState();
}

class _ShowcaseAppState extends State<ShowcaseApp> {
  @override
  Component build(BuildContext context) {
    // Just show the TextField demo - landing page will reload for different demos
    return const Center(child: TextFieldDemo());
  }
}

// ============================================
// TextField Demo - Interactive text input
// ============================================

class TextFieldDemo extends StatefulComponent {
  const TextFieldDemo({super.key});

  @override
  State<TextFieldDemo> createState() => _TextFieldDemoState();
}

class _TextFieldDemoState extends State<TextFieldDemo> {
  final _controller = TextEditingController();
  final List<String> _messages = [];

  @override
  Component build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'TextField Demo',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan),
          ),
          Text('Type a message and press Enter',
              style: TextStyle(color: Colors.gray)),
          const SizedBox(height: 1),
          // Input area - centered
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('> ',
                  style: TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold)),
              SizedBox(
                width: 40,
                child: Container(
                  decoration: BoxDecoration(
                    border: BoxBorder.all(color: Colors.blue),
                  ),
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        setState(() {
                          _messages.insert(0, value);
                          if (_messages.length > 5) _messages.removeLast();
                        });
                        _controller.clear();
                      }
                    },
                    placeholder: 'Type here...',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 1),
          // Messages
          Expanded(
            child: SizedBox(
              width: 44,
              child: Container(
                decoration: BoxDecoration(
                  border: BoxBorder.all(color: Colors.gray),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: _messages.isEmpty
                    ? Center(
                        child: Text(
                          'Messages appear here',
                          style: TextStyle(color: Colors.gray),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < _messages.length; i++)
                            Text(
                              '${_messages.length - i}. ${_messages[i]}',
                              style: TextStyle(
                                color: i == 0 ? Colors.green : Colors.white,
                                fontWeight: i == 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// ============================================
// ListView Demo - Scrollable list with selection
// ============================================

class ListViewDemo extends StatefulComponent {
  const ListViewDemo({super.key});

  @override
  State<ListViewDemo> createState() => _ListViewDemoState();
}

class _ListViewDemoState extends State<ListViewDemo> {
  int _selectedIndex = 0;
  final _items = [
    ('🎯', 'Row', 'Horizontal layout'),
    ('📚', 'Column', 'Vertical layout'),
    ('📦', 'Container', 'Box decoration'),
    ('📜', 'ListView', 'Scrollable list'),
    ('📝', 'TextField', 'Text input'),
    ('🔲', 'Stack', 'Layered views'),
    ('↔️', 'Expanded', 'Fill space'),
    ('🎯', 'Center', 'Center child'),
  ];

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.keyJ ||
            event.logicalKey == LogicalKey.arrowDown) {
          setState(() {
            _selectedIndex = (_selectedIndex + 1) % _items.length;
          });
          return true;
        } else if (event.logicalKey == LogicalKey.keyK ||
            event.logicalKey == LogicalKey.arrowUp) {
          setState(() {
            _selectedIndex =
                (_selectedIndex - 1 + _items.length) % _items.length;
          });
          return true;
        }
        return false;
      },
      child: SizedBox(
        width: 46,
        height: 12,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'ListView Demo',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Navigate: ', style: TextStyle(color: Colors.gray)),
                Text('j/k',
                    style: TextStyle(
                        color: Colors.yellow, fontWeight: FontWeight.bold)),
                Text(' or ', style: TextStyle(color: Colors.gray)),
                Text('↑/↓',
                    style: TextStyle(
                        color: Colors.yellow, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 1),
            Expanded(
              child: SizedBox(
                width: 44,
                child: Container(
                  decoration: BoxDecoration(
                    border: BoxBorder.all(color: Colors.blue),
                  ),
                  child: ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final isSelected = index == _selectedIndex;
                      final item = _items[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue : null,
                        ),
                        child: Row(
                          children: [
                            Text(
                              isSelected ? ' › ' : '   ',
                              style: TextStyle(
                                  color: Colors.cyan,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text('${item.$1} ', style: TextStyle()),
                            SizedBox(
                              width: 10,
                              child: Text(
                                item.$2,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                item.$3,
                                style: TextStyle(color: Colors.gray),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// Counter Demo - Interactive state management
// ============================================

class CounterDemo extends StatefulComponent {
  const CounterDemo({super.key});

  @override
  State<CounterDemo> createState() => _CounterDemoState();
}

class _CounterDemoState extends State<CounterDemo> {
  int _count = 0;

  @override
  Component build(BuildContext context) {
    final progress = (_count % 20) / 20;
    final barWidth = 36;
    final filled = (progress * barWidth).round();

    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.space ||
            event.logicalKey == LogicalKey.enter ||
            event.logicalKey == LogicalKey.arrowUp) {
          setState(() => _count++);
          return true;
        } else if (event.logicalKey == LogicalKey.arrowDown) {
          setState(() => _count = (_count - 1).clamp(0, 999));
          return true;
        } else if (event.logicalKey == LogicalKey.keyR) {
          setState(() => _count = 0);
          return true;
        }
        return false;
      },
      child: SizedBox(
        width: 46,
        height: 12,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Counter Demo',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan),
            ),
            Text('setState() in action', style: TextStyle(color: Colors.gray)),
            const SizedBox(height: 1),
            // Big counter display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                border: BoxBorder.all(color: Colors.magenta),
              ),
              child: Text(
                '$_count',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _count > 0 ? Colors.green : Colors.gray,
                ),
              ),
            ),
            const SizedBox(height: 1),
            // Progress bar
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('[', style: TextStyle(color: Colors.gray)),
                Text('█' * filled, style: TextStyle(color: Colors.green)),
                Text('░' * (barWidth - filled),
                    style: TextStyle(color: Colors.gray)),
                Text(']', style: TextStyle(color: Colors.gray)),
              ],
            ),
            const SizedBox(height: 1),
            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Space',
                    style: TextStyle(
                        color: Colors.yellow, fontWeight: FontWeight.bold)),
                Text(' +1  ', style: TextStyle(color: Colors.gray)),
                Text('↓',
                    style: TextStyle(
                        color: Colors.yellow, fontWeight: FontWeight.bold)),
                Text(' -1  ', style: TextStyle(color: Colors.gray)),
                Text('R',
                    style: TextStyle(
                        color: Colors.yellow, fontWeight: FontWeight.bold)),
                Text(' reset', style: TextStyle(color: Colors.gray)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// Layout Demo - Visual nested layout showcase
// ============================================

class LayoutDemo extends StatelessComponent {
  const LayoutDemo({super.key});

  @override
  Component build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Layout Demo',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan),
          ),
          Text('Row + Column + Expanded', style: TextStyle(color: Colors.gray)),
          const SizedBox(height: 1),
          Expanded(
            child: SizedBox(
              width: 44,
              child: Row(
                children: [
                  // Left panel
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: BoxBorder.all(color: Colors.red),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Left',
                                style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold)),
                            Text('Expanded',
                                style: TextStyle(color: Colors.gray)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Right side - nested Column
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: BoxBorder.all(color: Colors.green),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Top',
                                      style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: BoxBorder.all(color: Colors.blue),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Bottom',
                                      style: TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
