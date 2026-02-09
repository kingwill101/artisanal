import 'dart:io';
import 'package:nocterm/nocterm.dart';

class LoggerDemoApp extends StatefulComponent {
  @override
  State<LoggerDemoApp> createState() => _LoggerDemoAppState();
}

class _LoggerDemoAppState extends State<LoggerDemoApp> {
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    // Log some messages when the app starts
    print('App started at ${DateTime.now()}');
    print('Logs are streamed via WebSocket');
    print('Run "nocterm logs" in another terminal to see logs');
    print('Multiple log entries are buffered in memory');

    // Schedule periodic logs to demonstrate streaming
    Future.delayed(const Duration(seconds: 1), _logPeriodically);
  }

  void _logPeriodically() {
    _counter++;
    print('Periodic log #$_counter at ${DateTime.now()}');

    if (_counter < 10) {
      Future.delayed(const Duration(seconds: 1), _logPeriodically);
    } else {
      print('Demo complete - generated $_counter log messages');
    }
  }

  @override
  Component build(BuildContext context) {
    return Column(
      children: [
        const Text('WebSocket Logger Demo'),
        const Text(''),
        const Text('Logs are streamed via WebSocket to connected clients.'),
        const Text(''),
        const Text('To view logs:'),
        const Text('  1. Open another terminal'),
        const Text('  2. Run: nocterm logs'),
        const Text(''),
        Text('Generated $_counter log messages so far'),
        const Text(''),
        const Text('Press Ctrl+C to exit'),
      ],
    );
  }
}

void main() async {
  // Run the app with WebSocket-based logging
  await runApp(LoggerDemoApp());

  // After app exits, show info about how to view logs
  stdout.writeln('\n=== Logger Demo Complete ===');
  stdout.writeln('Logs were streamed via WebSocket during execution.');
  stdout.writeln('To view logs from a running app, use: nocterm logs');
  stdout.writeln('===============================\n');
}
