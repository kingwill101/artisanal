import 'dart:io' show stdout;

import 'package:artisanal_widgets/testing.dart';

import '../example/card_panel_frame/main.dart' as demo;

Future<void> main(List<String> args) async {
  final escaped = args.contains('--escaped');
  final width = _parseSizeArg(args, '--width') ?? 80;
  final height = _parseSizeArg(args, '--height') ?? 40;
  final tester = WidgetTester();
  try {
    await tester.pumpWidget(
      demo.CardPanelShowcase(),
      width: width,
      height: height,
    );
    final output = escaped
        ? tester.view.replaceAll('\x1b', r'\x1b')
        : tester.view;
    stdout.write(output);
  } finally {
    await tester.dispose();
  }
}

int? _parseSizeArg(List<String> args, String key) {
  for (final arg in args) {
    if (!arg.startsWith('$key=')) continue;
    return int.tryParse(arg.substring(key.length + 1));
  }
  return null;
}
