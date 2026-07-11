/// CLI inspector for artisanal TUI programs.
///
/// Connects to a running artisanal program via the VM service and
/// queries the `ext.artisanal.*` service extensions registered by
/// [ArtisanalDevTools].
///
/// ## Usage
///
/// 1. Run your artisanal app with `--enable-vm-service`:
///    ```bash
///    dart run --enable-vm-service bin/my_app.dart
///    ```
///
/// 2. Run the inspector with the VM service URI:
///    ```bash
///    dart run example/artisanal_inspector.dart ws://127.0.0.1:8181/AbCdEf=/ws
///    ```
///
/// 3. Interactive commands:
///    - `state`    — show current model state
///    - `log [n]`  — show last n messages (default 20)
///    - `stats`    — show render statistics
///    - `options`  — show program options
///    - `send <v>` — inject a CustomMsg with value v
///    - `repaint`  — trigger a repaint
///    - `watch`    — poll state every 500ms until Ctrl+C
///    - `help`     — show this help
///    - `quit`     — exit the inspector
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

// ignore_for_file: use_null_aware_elements
void main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run example/artisanal_inspector.dart <ws-uri>');
    stderr.writeln('');
    stderr.writeln('Example:');
    stderr.writeln(
      '  dart run example/artisanal_inspector.dart '
      'ws://127.0.0.1:8181/AbCdEf=/ws',
    );
    exit(1);
  }

  final wsUri = args[0];
  stdout.writeln('Connecting to $wsUri ...');

  late WebSocket ws;
  try {
    ws = await WebSocket.connect(wsUri);
  } catch (e) {
    stderr.writeln('Failed to connect: $e');
    exit(1);
  }

  stdout.writeln('Connected.\n');

  final inspector = _Inspector(ws);
  await inspector.init();

  stdout.writeln('Isolate: ${inspector.isolateId}');
  stdout.writeln('Type "help" for available commands.\n');

  // Interactive REPL.
  await inspector.repl();

  await ws.close();
  exit(0);
}

class _Inspector {
  _Inspector(this._ws) {
    _ws.listen(
      (data) {
        if (data is String) {
          final json = jsonDecode(data) as Map<String, dynamic>;
          final id = json['id'] as int?;
          if (id != null) {
            _pending[id]?.complete(json);
            _pending.remove(id);
          }
        }
      },
      onDone: () {
        stderr.writeln('WebSocket closed.');
        exit(0);
      },
    );
  }

  final WebSocket _ws;
  final Map<int, Completer<Map<String, dynamic>>> _pending = {};
  int _nextId = 1;
  String? isolateId;

  Future<Map<String, dynamic>> _send(
    String method, [
    Map<String, dynamic>? params,
  ]) {
    final id = _nextId++;
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;

    final request = <String, dynamic>{
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      if (params != null) 'params': params,
    };
    _ws.add(jsonEncode(request));
    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _pending.remove(id);
        throw TimeoutException('Request timed out: $method');
      },
    );
  }

  Future<void> init() async {
    // Get the VM to find the main isolate.
    final vmResponse = await _send('getVM');
    final result = vmResponse['result'] as Map<String, dynamic>;
    final isolates = result['isolates'] as List<dynamic>;
    if (isolates.isEmpty) {
      stderr.writeln('No isolates found.');
      exit(1);
    }
    isolateId = (isolates.first as Map<String, dynamic>)['id'] as String;
  }

  Future<Map<String, dynamic>?> _callExtension(
    String extension, [
    Map<String, String>? params,
  ]) async {
    try {
      final response = await _send(extension, <String, dynamic>{
        'isolateId': isolateId,
        ...?params,
      });
      if (response.containsKey('error')) {
        final error = response['error'] as Map<String, dynamic>;
        stderr.writeln('Error: ${error['message']}');
        return null;
      }
      final result = response['result'] as Map<String, dynamic>;
      // The service extension result is JSON-encoded in 'value'.
      if (result.containsKey('value')) {
        return jsonDecode(result['value'] as String) as Map<String, dynamic>;
      }
      return result;
    } catch (e) {
      stderr.writeln('Request failed: $e');
      return null;
    }
  }

  Future<void> repl() async {
    while (true) {
      stdout.write('artisanal> ');
      final line = stdin.readLineSync()?.trim();
      if (line == null || line == 'quit' || line == 'exit') break;
      if (line.isEmpty) continue;

      final parts = line.split(RegExp(r'\s+'));
      final cmd = parts[0];

      switch (cmd) {
        case 'state':
          await _doState();
        case 'log':
          final count = parts.length > 1 ? int.tryParse(parts[1]) ?? 20 : 20;
          await _doLog(count);
        case 'stats':
          await _doStats();
        case 'options':
          await _doOptions();
        case 'send':
          if (parts.length < 2) {
            stderr.writeln('Usage: send <value>');
          } else {
            final value = parts.sublist(1).join(' ');
            await _doSend(value);
          }
        case 'repaint':
          await _doRepaint();
        case 'watch':
          await _doWatch();
        case 'help':
          _doHelp();
        default:
          stderr.writeln('Unknown command: $cmd (type "help" for commands)');
      }
    }
  }

  Future<void> _doState() async {
    final result = await _callExtension('ext.artisanal.getState');
    if (result == null) return;
    _printJson(result);
  }

  Future<void> _doLog(int count) async {
    final result = await _callExtension('ext.artisanal.getMessageLog', {
      'count': count.toString(),
    });
    if (result == null) return;

    final entries = result['entries'] as List<dynamic>?;
    if (entries == null || entries.isEmpty) {
      stdout.writeln('(no messages)');
      return;
    }
    for (final entry in entries) {
      final e = entry as Map<String, dynamic>;
      final time = e['timestamp'] as String? ?? '';
      final type = e['messageType'] as String? ?? '';
      final summary = e['summary'] as String? ?? '';
      final us = e['processingTimeUs'] ?? 0;
      // Compact timestamp: just time portion.
      final timePart = time.contains('T')
          ? time.split('T').last.replaceAll('Z', '')
          : time;
      stdout.writeln('$timePart  [$type]  $summary  ($us\u00b5s)');
    }
    stdout.writeln('--- ${entries.length} entries ---');
  }

  Future<void> _doStats() async {
    final result = await _callExtension('ext.artisanal.getRenderStats');
    if (result == null) return;

    final fc = result['frameCount'] ?? 0;
    final avg = result['avgRenderUs'] ?? 0;
    final min = result['minRenderUs'] ?? 0;
    final max = result['maxRenderUs'] ?? 0;
    final last = result['lastRenderUs'] ?? 0;
    final deg = result['lastDegradation'] ?? 'unknown';
    final w = result['lastWidth'];
    final h = result['lastHeight'];

    stdout.writeln('Frames:      $fc');
    stdout.writeln('Render Avg:  $avg\u00b5s');
    stdout.writeln('Render Min:  $min\u00b5s');
    stdout.writeln('Render Max:  $max\u00b5s');
    stdout.writeln('Render Last: $last\u00b5s');
    stdout.writeln('Degradation: $deg');
    if (w != null && h != null) {
      stdout.writeln('Terminal:    ${w}x$h');
    }
  }

  Future<void> _doOptions() async {
    final result = await _callExtension('ext.artisanal.getOptions');
    if (result == null) return;
    _printJson(result);
  }

  Future<void> _doSend(String value) async {
    final result = await _callExtension('ext.artisanal.sendCustomMessage', {
      'value': value,
    });
    if (result == null) return;
    stdout.writeln('Sent: $value');
  }

  Future<void> _doRepaint() async {
    final result = await _callExtension('ext.artisanal.requestRepaint');
    if (result == null) return;
    stdout.writeln('Repaint requested.');
  }

  Future<void> _doWatch() async {
    stdout.writeln('Watching state (Ctrl+C to stop)...\n');
    // We can't truly Ctrl+C from stdin.readLineSync, so we poll with
    // a timer and check for stdin input.
    var running = true;
    final sub = ProcessSignal.sigint.watch().listen((_) {
      running = false;
    });

    while (running) {
      final result = await _callExtension('ext.artisanal.getState');
      if (result == null) break;

      // Clear line and reprint.
      stdout.write('\x1B[2K\r');
      final model = result['lastModel'] ?? '<unknown>';
      final gen = result['renderGeneration'] ?? 0;
      final pending = result['pendingMessages'] ?? 0;
      stdout.write('gen=$gen  pending=$pending  model=$model');

      await Future<void>.delayed(const Duration(milliseconds: 500));
    }

    await sub.cancel();
    stdout.writeln('\nStopped watching.');
  }

  void _doHelp() {
    stdout.writeln('Commands:');
    stdout.writeln('  state        Show current model state');
    stdout.writeln('  log [n]      Show last n messages (default 20)');
    stdout.writeln('  stats        Show render statistics');
    stdout.writeln('  options      Show program options');
    stdout.writeln('  send <val>   Inject a CustomMsg<String>');
    stdout.writeln('  repaint      Force repaint');
    stdout.writeln('  watch        Poll state every 500ms');
    stdout.writeln('  help         Show this help');
    stdout.writeln('  quit         Exit inspector');
  }

  void _printJson(Map<String, dynamic> json) {
    const encoder = JsonEncoder.withIndent('  ');
    stdout.writeln(encoder.convert(json));
  }
}
