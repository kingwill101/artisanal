import 'package:nocterm/nocterm.dart';

/// Demonstrates the debug overlay feature in nocterm.
///
/// This example shows:
/// - Press Ctrl+G to toggle the debug overlay (works in ANY nocterm app!)
/// - The overlay shows real-time performance metrics
/// - Repaint rainbow is enabled when debug mode is active
/// - Extended logging is sent to `nocterm logs`
///
/// Note: Debug overlay is automatically available in all nocterm apps.
/// No manual wrapping required - just press Ctrl+G!
///
/// Run with: dart run example/debug_overlay_demo.dart
/// View logs with: nocterm logs (in another terminal)
void main() {
  // No need to wrap with DebugOverlay - it's automatic!
  runApp(const _DebugOverlayDemo());
}

class _DebugOverlayDemo extends StatefulComponent {
  const _DebugOverlayDemo();

  @override
  State<_DebugOverlayDemo> createState() => _DebugOverlayDemoState();
}

class _DebugOverlayDemoState extends State<_DebugOverlayDemo> {
  int _counter = 0;
  late DebugModeCallback _debugCallback;

  @override
  void initState() {
    super.initState();
    _debugCallback = (_) => setState(() {});
    addDebugModeListener(_debugCallback);
  }

  @override
  void dispose() {
    removeDebugModeListener(_debugCallback);
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        // Handle counter keys
        if (event.logicalKey == LogicalKey.equal || event.character == '+') {
          setState(() => _counter++);
          return true;
        }
        if (event.logicalKey == LogicalKey.minus || event.character == '-') {
          setState(() => _counter--);
          return true;
        }
        return false;
      },
      child: Container(
        padding: const EdgeInsets.all(2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Debug Overlay Demo',
              style: TextStyle(
                color: Colors.cyan,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 1),
            Container(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.3),
                border: BoxBorder.all(style: BoxBorderStyle.rounded),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Press Ctrl+G to toggle debug mode'),
                  SizedBox(height: 1),
                  Text('When enabled, you will see:'),
                  Text('  - Performance overlay in top-right corner'),
                  Text('  - Repaint rainbow (colors on repainted areas)'),
                  Text('  - Extended logging (view with `nocterm logs`)'),
                ],
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Current Status:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 1),
            _buildStatusIndicator(),
            const SizedBox(height: 2),
            const Text(
              'Interactive Elements (to generate repaints):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 1),
            _buildCounter(),
            const SizedBox(height: 1),
            const Text(
              'Press + or - to change the counter and trigger repaints.',
              style: TextStyle(color: Colors.gray),
            ),
            const SizedBox(height: 1),
            const Text(
              'With debug mode ON, you\'ll see the repaint rainbow effect!',
              style: TextStyle(color: Colors.gray),
            ),
          ],
        ),
      ),
    );
  }

  Component _buildStatusIndicator() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
          color: debugMode ? Colors.green : Colors.red,
          child: Text(
            debugMode ? ' ON ' : ' OFF ',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 1),
        Text(
          debugMode
              ? 'Debug mode is ACTIVE - overlay visible'
              : 'Debug mode is OFF - press Ctrl+G',
          style: TextStyle(
            color: debugMode ? Colors.green : Colors.gray,
          ),
        ),
      ],
    );
  }

  Component _buildCounter() {
    return Row(
      children: [
        const Text('Counter: '),
        Container(
          width: 8,
          color: Colors.magenta.withOpacity(0.5),
          child: Center(
            child: Text(
              '$_counter',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 1),
        const Text('(Press + or - to change)'),
      ],
    );
  }
}
