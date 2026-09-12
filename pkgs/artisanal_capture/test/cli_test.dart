import 'dart:convert';
import 'dart:io';

import 'package:artisanal_capture/artisanal_capture.dart';
import 'package:artisanal_capture/cli.dart';
import 'package:test/test.dart';

void main() {
  late Directory temporary;
  late File source;
  late File destination;
  late int code;
  late List<String> messages;
  late CaptureCommandRunner runner;

  setUp(() async {
    temporary = await Directory.systemTemp.createTemp(
      'artisanal-capture-test-',
    );
    source = File('${temporary.path}/input.md')
      ..writeAsStringSync('Hello **world**');
    destination = File('${temporary.path}/capture.json');
    code = 0;
    messages = [];
    runner = CaptureCommandRunner(
      out: messages.add,
      err: messages.add,
      setExitCode: (value) => code = value,
    );
  });

  tearDown(() async => temporary.delete(recursive: true));

  List<String> captureArgs() => [
    'render',
    source.path,
    '--output',
    destination.path,
    '--format',
    'capture',
    '--columns',
    '20',
  ];

  test('renders Markdown into lossless cell JSON without a font', () async {
    await runner.run(captureArgs());
    expect(code, 0);
    final capture = TerminalCapture.fromJson(
      jsonDecode(await destination.readAsString()) as Map<String, dynamic>,
    );
    expect(capture.columns, 20);
    expect(capture.rows, 1);
    expect(capture.toBuffer().cellAt(6, 0)!.content, 'w');
    expect(capture.toBuffer().cellAt(6, 0)!.style.attrs, isNot(0));
  });

  test('saved capture dimensions and styles survive re-export', () async {
    await runner.run(captureArgs());
    final copy = File('${temporary.path}/copy.json');
    await runner.run([
      'render',
      destination.path,
      '--input-format',
      'capture',
      '--format',
      'capture',
      '--output',
      copy.path,
    ]);
    expect(code, 0);
    expect(
      jsonDecode(await copy.readAsString()),
      jsonDecode(await destination.readAsString()),
    );
  });

  test('refuses overwrite unless explicitly requested', () async {
    await destination.writeAsString('keep');
    await runner.run(captureArgs());
    expect(code, 64);
    expect(await destination.readAsString(), 'keep');
    code = 0;
    await runner.run([...captureArgs(), '--force']);
    expect(code, 0);
    expect(await destination.readAsString(), isNot('keep'));
  });

  test('rejects the input file as output even with force', () async {
    await runner.run([
      'render',
      source.path,
      '--format',
      'capture',
      '--output',
      source.path,
      '--force',
    ]);
    expect(code, 64);
    expect(await source.readAsString(), 'Hello **world**');
  });

  test('reports a missing font before writing PNG output', () async {
    await runner.run(['render', source.path, '--output', destination.path]);
    expect(code, 64);
    expect(messages.join('\n'), contains('--font'));
    expect(await destination.exists(), isFalse);
  });

  test('rejects terminal transport sequences in styled-view mode', () async {
    await source.writeAsString('\x1b[2Jhidden');
    await runner.run([...captureArgs(), '--input-format', 'ansi']);
    expect(code, 64);
    expect(await destination.exists(), isFalse);
  });

  test('rejects invalid viewport size', () async {
    final args = captureArgs();
    args[args.length - 1] = '0';
    await runner.run(args);
    expect(code, 64);
    expect(await destination.exists(), isFalse);
  });
}
