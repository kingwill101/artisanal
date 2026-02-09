import 'package:nocterm/nocterm.dart';

void main() async {
  await runApp(const LayoutDemo());
}

class LayoutDemo extends StatelessComponent {
  const LayoutDemo({super.key});

  @override
  Component build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '⊞ Layout',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text('Row + Column + Expanded', style: TextStyle(color: Colors.gray)),
          const SizedBox(height: 1),
          SizedBox(
            width: 40,
            height: 8,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: BoxBorder.all(color: Colors.magenta),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Left',
                              style: TextStyle(
                                  color: Colors.magenta,
                                  fontWeight: FontWeight.bold)),
                          Text('Panel', style: TextStyle(color: Colors.gray)),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: BoxBorder.all(color: Colors.cyan),
                          ),
                          child: Center(
                            child: Text('Top',
                                style: TextStyle(
                                    color: Colors.cyan,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: BoxBorder.all(color: Colors.yellow),
                          ),
                          child: Center(
                            child: Text('Bottom',
                                style: TextStyle(
                                    color: Colors.yellow,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
