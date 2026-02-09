import 'package:test/test.dart';
import 'package:nocterm/nocterm.dart';

// Example component for testing
class Counter extends StatefulComponent {
  const Counter({super.key});

  @override
  State<Counter> createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  int _count = 0;

  void _increment() {
    setState(() {
      _count++;
    });
  }

  void _decrement() {
    setState(() {
      _count--;
    });
  }

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.add) {
          _increment();
          return true;
        }
        if (event.logicalKey == LogicalKey.minus) {
          _decrement();
          return true;
        }
        return false;
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Counter Demo',
            style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 1),
          Text('Count: $_count'),
          const SizedBox(height: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('[+] Increment  ', style: TextStyle(color: Colors.green)),
              Text('[-] Decrement', style: TextStyle(color: Colors.red)),
            ],
          ),
        ],
      ),
    );
  }
}

void main() {
  group('TUI Testing Framework', () {
    test('can debug render output', () async {
      await testNocterm('debug output', (tester) async {
        await tester.pumpComponent(
          Container(
            padding: const EdgeInsets.all(1),
            child: const Text('Debug Me'),
          ),
        );

        // Get debug output
        final output = tester.renderToString(showBorders: true);

        // Output should contain the text
        expect(output, contains('Debug Me'));

        await tester.pumpComponent(const Counter());
        final output2 = tester.renderToString(showBorders: true);

        expect(output2, contains('Count: 0'));
      });
    });
  });
}
