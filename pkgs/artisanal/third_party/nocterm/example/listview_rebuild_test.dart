import 'package:nocterm/nocterm.dart';

/// Test to verify ListView items rebuild when state changes (e.g., selection)
void main() {
  runApp(const ListViewRebuildTest());
}

class ListViewRebuildTest extends StatefulComponent {
  const ListViewRebuildTest({super.key});

  @override
  State<ListViewRebuildTest> createState() => _ListViewRebuildTestState();
}

class _ListViewRebuildTestState extends State<ListViewRebuildTest> {
  int _selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: _handleKeyEvent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0066CC),
              border: BoxBorder(bottom: BorderSide()),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            child: Row(
              children: [
                const Text(
                  'ListView Rebuild Test',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFFFFF),
                  ),
                ),
                const Spacer(),
                Text(
                  'Selected: $_selectedIndex',
                  style: const TextStyle(color: Color(0xFFFFFFFF)),
                ),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF333333),
              border: BoxBorder(bottom: BorderSide()),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: const Text(
              'Use Arrow Up/Down to move selection. Selection should highlight!',
              style: TextStyle(color: Color(0xFFFFAA00)),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              lazy: true,
              itemCount: 20,
              itemBuilder: (context, index) {
                final isSelected = index == _selectedIndex;
                return Container(
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF00AA00) : null,
                    border: const BoxBorder(bottom: BorderSide()),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    '${isSelected ? ">" : " "} Item $index ${isSelected ? "<" : " "}',
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFFFFFFFF)
                          : const Color(0xFFCCCCCC),
                      fontWeight: isSelected ? FontWeight.bold : null,
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF222222),
              border: BoxBorder(top: BorderSide()),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: const Text(
              'Q to quit',
              style: TextStyle(color: Color(0xFF666666)),
            ),
          ),
        ],
      ),
    );
  }

  bool _handleKeyEvent(KeyboardEvent event) {
    switch (event.logicalKey) {
      case LogicalKey.arrowDown:
        setState(() {
          _selectedIndex = (_selectedIndex + 1).clamp(0, 19);
        });
        return true;
      case LogicalKey.arrowUp:
        setState(() {
          _selectedIndex = (_selectedIndex - 1).clamp(0, 19);
        });
        return true;
      case LogicalKey.keyQ:
        shutdownApp();
        return true;
      default:
        return false;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
