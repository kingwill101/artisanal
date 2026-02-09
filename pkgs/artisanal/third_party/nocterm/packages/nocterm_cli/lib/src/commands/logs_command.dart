import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:nocterm/nocterm.dart';
import 'package:nocterm_cli/src/deps/fs.dart';
import 'package:nocterm_cli/utils/cli_command.dart';

/// Run the logs command to stream logs from a running nocterm app
class LogsCommand extends CliCommand {
  LogsCommand() {
    argParser.addOption(
      'pid',
      abbr: 'p',
      help: 'Connect to a specific instance by PID',
    );
    argParser.addOption(
      'mode',
      abbr: 'm',
      help: 'Output mode: "get" fetches buffered logs and exits, '
          '"listen" streams continuously (default)',
      allowed: ['get', 'listen'],
      defaultsTo: 'listen',
    );
  }

  @override
  String get description => '''
Stream logs from a running nocterm app via WebSocket.

Modes:
  listen  - Stream logs continuously in real-time (default). Press Ctrl+C to exit.
  get     - Fetch all buffered logs and exit immediately. Ideal for LLM agents.

Examples:
  nocterm logs              # Stream logs continuously
  nocterm logs --mode get   # Fetch current logs and exit
  nocterm logs -m get       # Short form''';

  @override
  String get name => 'logs';

  /// Check if a process with the given PID is alive.
  bool _isProcessAlive(int pid) {
    try {
      // Sending signal 0 checks if process exists without affecting it
      return Process.killPid(pid, ProcessSignal.sigcont);
    } catch (_) {
      return false;
    }
  }

  /// Clean up a stale port file.
  Future<void> _cleanupStalePortFile(String path) async {
    try {
      await fs.file(path).delete();
    } catch (_) {
      // Ignore deletion errors
    }
  }

  /// Discover live nocterm instances, cleaning up stale ones.
  Future<List<({int pid, int port, String path})>> _discoverInstances() async {
    final portFiles = await listLogPortFiles();
    final liveInstances = <({int pid, int port, String path})>[];

    for (final file in portFiles) {
      // Check if process is alive
      if (!_isProcessAlive(file.pid)) {
        // Clean up stale port file
        await _cleanupStalePortFile(file.path);
        continue;
      }

      // Read port from file
      try {
        final portFile = fs.file(file.path);
        final portString = await portFile.readAsString();
        final port = int.tryParse(portString.trim());

        if (port != null) {
          liveInstances.add((pid: file.pid, port: port, path: file.path));
        } else {
          // Invalid port file, clean it up
          await _cleanupStalePortFile(file.path);
        }
      } catch (_) {
        // Failed to read port file, clean it up
        await _cleanupStalePortFile(file.path);
      }
    }

    return liveInstances;
  }

  /// Prompt user to select an instance from multiple running instances.
  ({int pid, int port})? _selectInstance(
    List<({int pid, int port, String path})> instances,
  ) {
    stdout.writeln('Multiple nocterm instances running:');
    for (var i = 0; i < instances.length; i++) {
      final instance = instances[i];
      stdout.writeln('  ${i + 1}. PID ${instance.pid} (port ${instance.port})');
    }
    stdout.write('Select instance [1-${instances.length}]: ');

    final input = stdin.readLineSync();
    if (input == null) return null;

    final selection = int.tryParse(input.trim());
    if (selection == null || selection < 1 || selection > instances.length) {
      stderr.writeln('Invalid selection: $input');
      return null;
    }

    final selected = instances[selection - 1];
    return (pid: selected.pid, port: selected.port);
  }

  @override
  Future<int> run() async {
    try {
      final pidArg = argResults['pid'] as String?;
      final targetPid = pidArg != null ? int.tryParse(pidArg) : null;
      final mode = argResults['mode'] as String;
      final isGetMode = mode == 'get';

      if (pidArg != null && targetPid == null) {
        stderr.writeln('Error: Invalid PID: $pidArg');
        return 1;
      }

      // Discover all live instances
      final instances = await _discoverInstances();

      if (instances.isEmpty) {
        stderr.writeln(
          'Error: No nocterm app is running (no log_port files found)',
        );
        stderr.writeln('Make sure a nocterm app is running in this directory.');
        return 1;
      }

      int port;

      if (targetPid != null) {
        // User specified a PID, find that instance
        final instance = instances.where((i) => i.pid == targetPid).firstOrNull;
        if (instance == null) {
          stderr
              .writeln('Error: No nocterm instance found with PID $targetPid');
          stderr.writeln('Running instances:');
          for (final i in instances) {
            stderr.writeln('  PID ${i.pid} (port ${i.port})');
          }
          return 1;
        }
        port = instance.port;
      } else if (instances.length == 1) {
        // Single instance, connect directly
        port = instances.first.port;
      } else {
        // Multiple instances, prompt user to select
        final selected = _selectInstance(instances);
        if (selected == null) {
          return 1;
        }
        port = selected.port;
      }

      // Connect to WebSocket
      final url = 'ws://127.0.0.1:$port/logs';
      WebSocket? socket;

      try {
        socket = await WebSocket.connect(url);
      } catch (e) {
        stderr.writeln('Error: Failed to connect to log server at $url');
        stderr.writeln('The nocterm app may have exited. Details: $e');
        return 1;
      }

      // Stream log messages to stdout
      try {
        if (isGetMode) {
          // Get mode: fetch buffered logs and exit
          // The server sends all buffered logs immediately on connect,
          // so we wait briefly for them and then exit.
          final logs = <String>[];
          Timer? exitTimer;

          await for (final message in socket) {
            // Reset/start timer on each message - exit after 100ms of no new messages
            exitTimer?.cancel();
            exitTimer = Timer(const Duration(milliseconds: 100), () {
              socket?.close();
            });

            try {
              final json =
                  jsonDecode(message as String) as Map<String, dynamic>;
              final logMessage = json['message'] as String;
              logs.add(logMessage);
            } catch (e) {
              logs.add(message.toString());
            }
          }

          // Print all collected logs
          for (final log in logs) {
            stdout.writeln(log);
          }
        } else {
          // Listen mode: stream continuously
          await for (final message in socket) {
            try {
              final json =
                  jsonDecode(message as String) as Map<String, dynamic>;
              final logMessage = json['message'] as String;

              // Note: message already includes timestamp from logger
              stdout.writeln(logMessage);
            } catch (e) {
              // If JSON parsing fails, print raw message
              stderr.writeln('Warning: Failed to parse log message: $e');
              stdout.writeln(message);
            }
          }
        }
      } catch (e) {
        // Connection closed or error reading
        if (e is! WebSocketException) {
          stderr.writeln('Connection closed: $e');
        }
      } finally {
        await socket.close();
      }
    } catch (e) {
      stderr.writeln('Error: $e');
      return 1;
    }

    return 0;
  }
}
