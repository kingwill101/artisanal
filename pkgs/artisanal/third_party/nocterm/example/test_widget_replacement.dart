import 'dart:async';
import 'package:nocterm/nocterm.dart';

void main() async {
  await runApp(const WidgetReplacementTest());
}

class WidgetReplacementTest extends StatefulComponent {
  const WidgetReplacementTest({super.key});

  @override
  State<WidgetReplacementTest> createState() => _WidgetReplacementTestState();
}

class _WidgetReplacementTestState extends State<WidgetReplacementTest> {
  int phase = 0;

  @override
  void initState() {
    super.initState();

    // Phase 1: Switch to DecoratedBox after 1 second
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        phase = 1;
      });
    });

    // Phase 2: Switch back to Text after 2 seconds
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        phase = 2;
      });
    });
  }

  @override
  Component build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Phase: $phase'),
          const SizedBox(height: 2),

          // This child changes type during rebuild
          if (phase == 0)
            const Text('Initial Text Widget')
          else if (phase == 1)
            DecoratedBox(
              decoration: BoxDecoration(
                border: BoxBorder.all(color: Colors.green),
                color: Color.fromRGB(0, 64, 0),
              ),
              child: const Text('Decorated Box'),
            )
          else
            const Text('Back to Text Widget'),
        ],
      ),
    );
  }
}
