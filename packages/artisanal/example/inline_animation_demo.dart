#!/usr/bin/env dart

/// Demo of inline animations that can disappear after completion.
///
/// Run this directly: dart run example/inline_animation_demo.dart

import 'dart:io';
import 'package:artisanal/artisanal.dart';

void main() async {
  final console = Console();

  print('=== Inline Animation Demo ===\n');

  // Demo 1: Spinner that stays visible after completion
  print('1. Normal spinner (stays visible):');
  await console.spin(
    'Fetching data...',
    run: () async {
      await Future<void>.delayed(const Duration(seconds: 2));
      return 'data';
    },
    doneMessage: '   Done fetching data!',
  );

  print('\n2. Spinner that DISAPPEARS after completion:');
  print('   (Watch the spinner vanish!)');
  await console.spin(
    'Loading...',
    run: () async {
      await Future<void>.delayed(const Duration(seconds: 2));
      return 'loaded';
    },
    clearOnDone: true,
  );
  print('   ^ The spinner was here but now it\'s gone!\n');

  // Demo 3: Progress bar that stays
  print('3. Normal progress bar (stays visible):');
  await console.progress(
    'Downloading',
    run: (setProgress) async {
      for (var i = 0; i <= 20; i++) {
        setProgress(i / 20);
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      return null;
    },
    doneMessage: '   Download complete!',
  );

  // Demo 4: Progress bar that disappears
  print('\n4. Progress bar that DISAPPEARS after completion:');
  print('   (Watch the progress bar vanish!)');
  await console.progress(
    'Installing',
    run: (setProgress) async {
      for (var i = 0; i <= 20; i++) {
        setProgress(i / 20);
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      return null;
    },
    clearOnDone: true,
  );
  print('   ^ The progress bar was here but now it\'s gone!\n');

  // Demo 5: Task that disappears
  print('5. Task that DISAPPEARS after completion:');
  print('   (Watch the task vanish!)');
  await console.task(
    'Compiling...',
    run: () async {
      await Future<void>.delayed(const Duration(seconds: 2));
      return TaskResult.success;
    },
    clearOnDone: true,
  );
  print('   ^ The task was here but now it\'s gone!\n');

  // Demo 6: Progress iterate that disappears
  print('6. Iterating with progress that DISAPPEARS:');
  print('   (Watch the progress vanish!)');
  final items = List.generate(10, (i) => 'item_$i');
  for (final item in console.progressIterate(items, clearOnDone: true)) {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    // Process item...
    item; // Use the item to avoid unused variable warning
  }
  print('   ^ The progress was here but now it\'s gone!\n');

  // Demo 7: Using InlineAnimation directly for more control
  print('7. Using InlineAnimation directly with spinAll:');
  final terminal = StdioTerminal(stdout: stdout, stdin: stdin);
  final animation = InlineAnimation(terminal: terminal);

  await animation.spinAll(
    tasks: [
      (
        'Step 1: Preparing',
        () async {
          await Future<void>.delayed(const Duration(seconds: 1));
          return 'prepared';
        },
      ),
      (
        'Step 2: Building',
        () async {
          await Future<void>.delayed(const Duration(seconds: 1));
          return 'built';
        },
      ),
      (
        'Step 3: Deploying',
        () async {
          await Future<void>.delayed(const Duration(seconds: 1));
          return 'deployed';
        },
      ),
    ],
    showCheckmarks: true,
    spinner: Spinners.dot,
  );

  print('\n8. Different spinner styles:');
  for (final entry in [
    ('line', Spinners.line),
    ('dot', Spinners.dot),
    ('miniDot', Spinners.miniDot),
    ('circle', Spinners.circle),
    ('arc', Spinners.arc),
  ]) {
    await console.spin(
      'Spinner: ${entry.$1}',
      run: () async {
        await Future<void>.delayed(const Duration(milliseconds: 1500));
      },
      spinner: entry.$2,
    );
  }

  print('\n=== Demo Complete ===');
}
