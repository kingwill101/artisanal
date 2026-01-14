#!/usr/bin/env dart

import 'dart:io';
import 'package:artisanal/tui.dart';

/// Run this directly: dart run example/spinner_demo.dart
void main() async {
  final terminal = StdioTerminal(stdout: stdout, stdin: stdin);

  print('Testing animated spinner...\n');

  // Test 1: Basic spinner with dots
  print('1. Dots spinner (default):');
  await runSpinnerTask<void>(
    message: 'Loading data...',
    terminal: terminal,
    task: () async {
      await Future<void>.delayed(const Duration(seconds: 5));
    },
  );

  print('\n2. Line spinner:');
  await runSpinnerTask<void>(
    message: 'Processing...',
    spinner: Spinners.line,
    terminal: terminal,
    task: () async {
      await Future<void>.delayed(const Duration(seconds: 2));
    },
  );

  print('\n3. Circle spinner:');
  await runSpinnerTask<void>(
    message: 'Compiling...',
    spinner: Spinners.circle,
    terminal: terminal,
    task: () async {
      await Future<void>.delayed(const Duration(seconds: 2));
    },
  );

  print('\n4. Arc spinner:');
  await runSpinnerTask<void>(
    message: 'Uploading...',
    spinner: Spinners.arc,
    terminal: terminal,
    task: () async {
      await Future<void>.delayed(const Duration(seconds: 2));
    },
  );

  print('\n5. Arrows spinner:');
  await runSpinnerTask<void>(
    message: 'Syncing...',
    spinner: Spinners.arrows,
    terminal: terminal,
    task: () async {
      await Future<void>.delayed(const Duration(seconds: 2));
    },
  );

  print('\n6. Error spinner:');
  try {
    await runSpinnerTask<void>(
      message: 'This will fail...',
      terminal: terminal,
      task: () async {
        await Future<void>.delayed(const Duration(seconds: 2));
        throw Exception('Simulated error');
      },
    );
  } catch (_) {
    // Ignore.
  }

  print('\nAll spinners tested!');
}
