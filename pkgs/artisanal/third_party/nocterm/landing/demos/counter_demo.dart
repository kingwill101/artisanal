import 'package:nocterm/nocterm.dart';

void main() async {
  await runApp(const CounterDemo());
}

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
    final barWidth = 30;
    final filled = (progress * barWidth).round();

    return SizedBox.expand(
      child: Center(
        child: Focusable(
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '⚡ Counter',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 1),
              Text(
                '$_count',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.cyan,
                ),
              ),
              const SizedBox(height: 1),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('▕', style: TextStyle(color: Colors.gray)),
                  Text('█' * filled, style: TextStyle(color: Colors.magenta)),
                  Text('░' * (barWidth - filled),
                      style: TextStyle(color: Colors.gray)),
                  Text('▏', style: TextStyle(color: Colors.gray)),
                ],
              ),
              const SizedBox(height: 1),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Space', style: TextStyle(color: Colors.yellow)),
                  Text(' +1  ', style: TextStyle(color: Colors.gray)),
                  Text('R', style: TextStyle(color: Colors.yellow)),
                  Text(' reset', style: TextStyle(color: Colors.gray)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
