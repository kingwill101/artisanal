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

  test('rejects a symlink output alias even with force', () async {
    final alias = File('${temporary.path}/input-alias.md');
    try {
      await Link(alias.path).create(source.path);
    } on FileSystemException {
      return; // Symlink creation may be unavailable in restricted runners.
    }
    await runner.run([
      'render',
      source.path,
      '--format',
      'capture',
      '--output',
      alias.path,
      '--force',
    ]);
    expect(code, 64);
    expect(await source.readAsString(), 'Hello **world**');
  }, onPlatform: {'windows': const Skip('symlink privileges vary on Windows')});

  test('rejects an oversized source before decoding or writing', () async {
    await source.writeAsBytes(List<int>.filled(16 * 1024 * 1024 + 1, 65));
    await runner.run(captureArgs());
    expect(code, 64);
    expect(await destination.exists(), isFalse);
    expect(messages.join('\n'), contains('16 MiB'));
  });

  test('rejects a hardlink output alias even with force', () async {
    final alias = File('${temporary.path}/hardlink.md');
    final result = await Process.run('ln', [source.path, alias.path]);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    await runner.run([
      'render',
      source.path,
      '--format',
      'capture',
      '--output',
      alias.path,
      '--force',
    ]);
    expect(code, 64);
    expect(await source.readAsString(), 'Hello **world**');
  }, onPlatform: {'windows': const Skip('requires POSIX hardlink creation')});

  test('rejects a FIFO before opening it', () async {
    final fifo = File('${temporary.path}/input.fifo');
    final result = await Process.run('mkfifo', [fifo.path]);
    if (result.exitCode != 0) return;
    try {
      await runner
          .run([
            'render',
            fifo.path,
            '--format',
            'capture',
            '--output',
            destination.path,
          ])
          .timeout(const Duration(seconds: 2));
      expect(code, 64);
      expect(await destination.exists(), isFalse);
    } finally {
      await fifo.delete();
    }
  }, onPlatform: {'windows': const Skip('mkfifo is not available on Windows')});

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
