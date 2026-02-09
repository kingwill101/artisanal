import 'package:nocterm/nocterm.dart';

void main() async {
  await runApp(const ListViewDemo());
}

class ListViewDemo extends StatefulComponent {
  const ListViewDemo({super.key});

  @override
  State<ListViewDemo> createState() => _ListViewDemoState();
}

class _ListViewDemoState extends State<ListViewDemo> {
  int _selectedIndex = 0;
  final _items = [
    ('Row', 'Horizontal layout'),
    ('Column', 'Vertical layout'),
    ('Container', 'Box decoration'),
    ('ListView', 'Scrollable list'),
    ('TextField', 'Text input'),
    ('Stack', 'Layered views'),
    ('Expanded', 'Fill space'),
    ('Center', 'Center child'),
  ];

  @override
  Component build(BuildContext context) {
    return Center(
      child: Focusable(
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '☰ ListView',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('↑↓', style: TextStyle(color: Colors.yellow)),
                Text(' navigate', style: TextStyle(color: Colors.gray)),
              ],
            ),
            const SizedBox(height: 1),
            SizedBox(
              width: 36,
              height: 8,
              child: Container(
                decoration: BoxDecoration(
                  border: BoxBorder.all(color: Colors.gray),
                ),
                child: ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final isSelected = index == _selectedIndex;
                    final item = _items[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.magenta : null,
                      ),
                      child: Row(
                        children: [
                          Text(
                            isSelected ? ' › ' : '   ',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(
                            width: 10,
                            child: Text(
                              item.$1,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.cyan,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              item.$2,
                              style: TextStyle(
                                  color:
                                      isSelected ? Colors.white : Colors.gray),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
