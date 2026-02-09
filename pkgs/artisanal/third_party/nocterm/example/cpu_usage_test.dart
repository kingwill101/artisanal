import 'dart:async';
import 'package:nocterm/nocterm.dart';

/// Test app to measure CPU usage from different sources:
/// - Spinners (Timer.periodic every 100ms)
/// - Cursor blink (Timer.periodic every 500ms)
/// - ListView with many items
///
/// Run with: dart run example/cpu_usage_test.dart
/// Watch CPU in Activity Monitor to see the impact of each feature.
void main() {
  runApp(const CpuUsageTestApp());
}

class CpuUsageTestApp extends StatefulComponent {
  const CpuUsageTestApp({super.key});

  @override
  State<CpuUsageTestApp> createState() => _CpuUsageTestAppState();
}

class _CpuUsageTestAppState extends State<CpuUsageTestApp> {
  bool _showSpinner = true;
  bool _showCursorBlink = false;
  bool _showListView = false;
  int _listItemCount = 100;
  int _frameCount = 0;
  Timer? _frameCountTimer;

  @override
  void initState() {
    super.initState();
    // Count frames every second
    _frameCountTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      print('Frames in last second: $_frameCount');
      _frameCount = 0;
    });
  }

  @override
  void dispose() {
    _frameCountTimer?.cancel();
    super.dispose();
  }

  bool _handleKeyEvent(KeyboardEvent event) {
    if (event.logicalKey == LogicalKey.digit1) {
      setState(() => _showSpinner = !_showSpinner);
      return true;
    }
    if (event.logicalKey == LogicalKey.digit2) {
      setState(() => _showCursorBlink = !_showCursorBlink);
      return true;
    }
    if (event.logicalKey == LogicalKey.digit3) {
      setState(() => _showListView = !_showListView);
      return true;
    }
    if (event.logicalKey == LogicalKey.equal || event.character == '+') {
      setState(() => _listItemCount = (_listItemCount * 10).clamp(10, 100000));
      return true;
    }
    if (event.logicalKey == LogicalKey.minus) {
      setState(() => _listItemCount = (_listItemCount ~/ 10).clamp(10, 100000));
      return true;
    }
    if (event.logicalKey == LogicalKey.keyQ) {
      TerminalBinding.instance.requestShutdown();
      return true;
    }
    return false;
  }

  @override
  Component build(BuildContext context) {
    _frameCount++;

    return Focusable(
      focused: true,
      onKeyEvent: _handleKeyEvent,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('CPU Usage Test',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const Text('Watch nocterm logs for frame count'),
              ],
            ),
          ),

          // Controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Row(
              children: [
                Text('[1] Spinner: ${_showSpinner ? "ON" : "OFF"}  '),
                Text('[2] Cursor: ${_showCursorBlink ? "ON" : "OFF"}  '),
                Text('[3] ListView: ${_showListView ? "ON" : "OFF"}  '),
                Text('[+/-] Items: $_listItemCount  '),
                const Text('[Q] Quit'),
              ],
            ),
          ),

          const SizedBox(height: 1),

          // Test area
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: BoxBorder.all(),
              ),
              child: Column(
                children: [
                  // Spinner area
                  if (_showSpinner)
                    Padding(
                      padding: const EdgeInsets.all(1),
                      child: Row(
                        children: [
                          const _TestSpinner(),
                          const SizedBox(width: 1),
                          const Text('Spinner running (100ms timer)'),
                        ],
                      ),
                    ),

                  // Cursor blink area
                  if (_showCursorBlink)
                    Padding(
                      padding: const EdgeInsets.all(1),
                      child: Row(
                        children: [
                          const _TestCursorBlink(),
                          const SizedBox(width: 1),
                          const Text('Cursor blinking (500ms timer)'),
                        ],
                      ),
                    ),

                  // ListView area
                  if (_showListView)
                    Expanded(
                      child: ListView.builder(
                        lazy: true,
                        itemCount: _listItemCount,
                        itemBuilder: (context, index) {
                          return Text('Item $index');
                        },
                      ),
                    ),

                  if (!_showSpinner && !_showCursorBlink && !_showListView)
                    Expanded(
                      child: Center(
                        child: const Text(
                            'All features disabled - should be ~0% CPU'),
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

/// Test spinner component - rebuilds every 100ms
class _TestSpinner extends StatefulComponent {
  const _TestSpinner();

  @override
  State<_TestSpinner> createState() => _TestSpinnerState();
}

class _TestSpinnerState extends State<_TestSpinner> {
  static const _frames = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      setState(() {
        _index = (_index + 1) % _frames.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    return Text(_frames[_index], style: const TextStyle(color: Colors.blue));
  }
}

/// Test cursor blink component - rebuilds every 500ms
class _TestCursorBlink extends StatefulComponent {
  const _TestCursorBlink();

  @override
  State<_TestCursorBlink> createState() => _TestCursorBlinkState();
}

class _TestCursorBlinkState extends State<_TestCursorBlink> {
  Timer? _timer;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      setState(() {
        _visible = !_visible;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    return Text(
      _visible ? '█' : ' ',
      style: const TextStyle(color: Colors.green),
    );
  }
}
