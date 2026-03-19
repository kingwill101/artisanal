import 'dart:io' show stdout;

import 'package:artisanal/style.dart';
import 'package:artisanal_widgets/widgets.dart';
import 'package:artisanal_widgets/testing.dart';

import '../example/buttons/main.dart' as demo;

Future<void> main(List<String> args) async {
  // Match the buttons example theme tweak so the dump reflects the live demo.
  setTheme(
    Theme.adaptive().copyWith(
      onPrimary: const AdaptiveColor(
        light: AnsiColor(255),
        dark: AnsiColor(255),
      ),
    ),
  );

  final escaped = args.contains('--escaped');
  final tester = WidgetTester();
  try {
    await tester.pumpWidget(demo.ButtonShowcase());
    final output = escaped
        ? tester.view.replaceAll('\x1b', r'\x1b')
        : tester.view;
    stdout.write(output);
  } finally {
    await tester.dispose();
  }
}
