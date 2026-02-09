import 'package:nocterm/nocterm.dart';

/// Performance test for lazy ListView with very large item counts
void main() {
  runApp(const ListViewPerformanceTest());
}

class ListViewPerformanceTest extends StatefulComponent {
  const ListViewPerformanceTest({super.key});

  @override
  State<ListViewPerformanceTest> createState() =>
      _ListViewPerformanceTestState();
}

class _ListViewPerformanceTestState extends State<ListViewPerformanceTest> {
  final ScrollController _scrollController = ScrollController();
  int _itemCount = 1000;
  bool _useLazy = true;
  int _buildCount = 0;

  // Track which items have been built
  final Set<int> _builtItems = {};

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: _handleKeyEvent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with controls
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0066CC),
              border: BoxBorder(bottom: BorderSide()),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            child: Row(
              children: [
                const Text(
                  'ListView Performance Test',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFFFFF),
                  ),
                ),
                const Spacer(),
                Text(
                  'Items: $_itemCount | Lazy: $_useLazy',
                  style: const TextStyle(color: Color(0xFFFFFFFF)),
                ),
              ],
            ),
          ),

          // Stats bar
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF333333),
              border: BoxBorder(bottom: BorderSide()),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              children: [
                Text(
                  'Build count: $_buildCount',
                  style: const TextStyle(color: Color(0xFF00FF00)),
                ),
                const SizedBox(width: 4),
                Text(
                  'Unique items built: ${_builtItems.length}',
                  style: const TextStyle(color: Color(0xFFFFAA00)),
                ),
                const SizedBox(width: 4),
                Text(
                  'Scroll: ${_scrollController.offset.toStringAsFixed(0)} / ${_scrollController.maxScrollExtent.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: _scrollController.offset >
                            _scrollController.maxScrollExtent
                        ? const Color(0xFFFF0000)
                        : const Color(0xFF00AAFF),
                  ),
                ),
              ],
            ),
          ),

          // Controls
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF222222),
              border: BoxBorder(bottom: BorderSide()),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: const Row(
              children: [
                Text('Press: ', style: TextStyle(color: Color(0xFF888888))),
                Text('[1] 100  ', style: TextStyle(color: Color(0xFFFFFFFF))),
                Text('[2] 1K  ', style: TextStyle(color: Color(0xFFFFFFFF))),
                Text('[3] 10K  ', style: TextStyle(color: Color(0xFFFFFFFF))),
                Text('[4] 100K  ', style: TextStyle(color: Color(0xFFFFFFFF))),
                Text('[5] 1M  ', style: TextStyle(color: Color(0xFFFFFFFF))),
                Text('[L] lazy', style: TextStyle(color: Color(0xFFFFFFFF))),
              ],
            ),
          ),

          // The list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              lazy: _useLazy,
              itemCount: _itemCount,
              itemBuilder: (context, index) {
                _buildCount++;
                _builtItems.add(index);
                return _buildItem(index);
              },
            ),
          ),

          // Footer
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF222222),
              border: BoxBorder(top: BorderSide()),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: const Text(
              'Scroll with mouse wheel or arrow keys | Q to quit',
              style: TextStyle(color: Color(0xFF666666)),
            ),
          ),
        ],
      ),
    );
  }

  Component _buildItem(int index) {
    final colors = [
      const Color(0xFFFF6B6B),
      const Color(0xFF4ECDC4),
      const Color(0xFF45B7D1),
      const Color(0xFFFFA07A),
      const Color(0xFF98D8C8),
      const Color(0xFFF7DC6F),
      const Color(0xFFBB8FCE),
      const Color(0xFF85C1E9),
    ];
    final color = colors[index % colors.length];

    return Container(
      decoration: const BoxDecoration(
        border: BoxBorder(bottom: BorderSide()),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          Container(
            width: 10,
            alignment: Alignment.centerRight,
            child: Text(
              '$index',
              style: TextStyle(color: color),
            ),
          ),
          const SizedBox(width: 2),
          Text(
            '|',
            style: TextStyle(color: color),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Text(
              'Item number $index - ${_getItemDescription(index)}',
              style: const TextStyle(color: Color(0xFFCCCCCC)),
            ),
          ),
        ],
      ),
    );
  }

  String _getItemDescription(int index) {
    if (index % 1000 == 0) return 'MILESTONE: ${index ~/ 1000}K';
    if (index % 100 == 0) return 'Hundred marker';
    if (index % 10 == 0) return 'Ten marker';
    return 'Regular item';
  }

  bool _handleKeyEvent(KeyboardEvent event) {
    switch (event.logicalKey) {
      case LogicalKey.digit1:
        setState(() => _setItemCount(100));
        return true;
      case LogicalKey.digit2:
        setState(() => _setItemCount(1000));
        return true;
      case LogicalKey.digit3:
        setState(() => _setItemCount(10000));
        return true;
      case LogicalKey.digit4:
        setState(() => _setItemCount(100000));
        return true;
      case LogicalKey.digit5:
        setState(() => _setItemCount(1000000));
        return true;
      case LogicalKey.keyL:
        setState(() {
          _useLazy = !_useLazy;
          _resetStats();
        });
        return true;
      case LogicalKey.arrowDown:
        _scrollController.scrollDown(1.0);
        setState(() {});
        return true;
      case LogicalKey.arrowUp:
        _scrollController.scrollUp(1.0);
        setState(() {});
        return true;
      case LogicalKey.pageDown:
        _scrollController.scrollDown(20.0);
        setState(() {});
        return true;
      case LogicalKey.pageUp:
        _scrollController.scrollUp(20.0);
        setState(() {});
        return true;
      case LogicalKey.home:
        _scrollController.jumpTo(0);
        setState(() {});
        return true;
      case LogicalKey.end:
        _scrollController.scrollToEnd();
        setState(() {});
        return true;
      case LogicalKey.keyQ:
        shutdownApp();
        return true;
      default:
        return false;
    }
  }

  void _setItemCount(int count) {
    _itemCount = count;
    _resetStats();
    _scrollController.jumpTo(0);
  }

  void _resetStats() {
    _buildCount = 0;
    _builtItems.clear();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
