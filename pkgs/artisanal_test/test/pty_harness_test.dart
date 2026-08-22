import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:artisanal_test/artisanal_test.dart';
import 'package:test/test.dart';

void main() {
  group('PtySession', () {
    late _FakePtyBackend backend;
    late PtySession session;

    setUp(() async {
      backend = _FakePtyBackend();
      final harness = PtyHarness(backendFactory: (_) => backend);
      session = await harness.spawn(
        PtySpawnRequest(
          executable: 'fixture',
          arguments: const <String>['--interactive'],
          columns: 80,
          rows: 24,
        ),
      );
    });

    tearDown(() async {
      if (!session.isClosed) {
        await session.close(terminate: false);
      }
    });

    test('matches output across arbitrary backend chunks', () async {
      final matchFuture = session.waitForText('Count: 1');

      backend.emitText('Count');
      backend.emitText(': ');
      backend.emitText('1');

      final match = await matchFuture;
      expect(match.start, 0);
      expect(match.end, utf8.encode('Count: 1').length);
      expect(utf8.decode(match.output), 'Count: 1');
      expect(session.outputText, 'Count: 1');
    });

    test('records successful input, resize, output, and exit in order', () async {
      await session.sendText('j');
      await session.sendBytes(const <int>[0x03]);
      await session.resize(columns: 40, rows: 12);
      backend.emitText('done');
      await backend.finish(0);

      expect(await session.waitForExit(), 0);
      final trace = await session.close(terminate: false);

      expect(
        backend.writes,
        <List<int>>[
          utf8.encode('j'),
          const <int>[0x03],
        ],
      );
      expect(backend.resizes, const <_Resize>[_Resize(40, 12)]);
      expect(
        trace.events.map((event) => event.type),
        <String>['input', 'input', 'resize', 'output', 'exit'],
      );
      expect(trace.inputBytes, orderedEquals(<int>[0x6a, 0x03]));
      expect(trace.outputText, 'done');
    });

    test('fails immediately when output closes before a pattern appears', () async {
      final wait = session.waitForText('never');
      backend.emitText('partial');
      await backend.finish(0);

      await expectLater(wait, throwsA(isA<PtyOutputClosedException>()));
    });

    test('reports timeout with a raw output snapshot', () async {
      backend.emitText('partial');

      await expectLater(
        session.waitForText(
          'complete',
          timeout: const Duration(milliseconds: 20),
        ),
        throwsA(
          isA<PtyTimeoutException>().having(
            (error) => utf8.decode(error.output),
            'output',
            'partial',
          ),
        ),
      );
    });
  });

  group('PtyTrace', () {
    test('round-trips JSONL and preserves raw bytes', () {
      final request = PtySpawnRequest(
        executable: 'dart',
        arguments: const <String>['run', 'example.dart'],
        workingDirectory: '/workspace',
        environment: const <String, String>{'TOKEN': 'do-not-serialize'},
        columns: 100,
        rows: 30,
      );
      final trace = PtyTrace(
        request: request,
        events: <PtyEvent>[
          PtyOutputEvent(
            elapsed: const Duration(microseconds: 10),
            bytes: const <int>[0x1b, 0x5b, 0x32, 0x4a],
          ),
          PtyInputEvent(
            elapsed: const Duration(microseconds: 20),
            bytes: const <int>[0x03],
          ),
          const PtyResizeEvent(
            elapsed: Duration(microseconds: 30),
            columns: 40,
            rows: 12,
          ),
          const PtyExitEvent(
            elapsed: Duration(microseconds: 40),
            exitCode: 0,
          ),
        ],
      );

      final encoded = trace.toJsonLines();
      final decoded = PtyTrace.fromJsonLines(encoded);

      expect(encoded, isNot(contains('do-not-serialize')));
      expect(decoded.request.executable, 'dart');
      expect(decoded.request.arguments, <String>['run', 'example.dart']);
      expect(decoded.request.workingDirectory, '/workspace');
      expect(decoded.request.environment, isNull);
      expect(decoded.request.columns, 100);
      expect(decoded.request.rows, 30);
      expect(decoded.outputBytes, orderedEquals(<int>[0x1b, 0x5b, 0x32, 0x4a]));
      expect(decoded.inputBytes, orderedEquals(<int>[0x03]));
      expect(decoded.events.map((event) => event.type), <String>[
        'output',
        'input',
        'resize',
        'exit',
      ]);
      expect(decoded.duration, const Duration(microseconds: 40));
    });
  });
}

final class _FakePtyBackend implements PtyBackend {
  final StreamController<Uint8List> _outputController =
      StreamController<Uint8List>(sync: true);
  final Completer<int> _exitCompleter = Completer<int>();

  final List<List<int>> writes = <List<int>>[];
  final List<_Resize> resizes = <_Resize>[];

  bool _outputClosed = false;
  bool _closed = false;

  @override
  Stream<Uint8List> get output => _outputController.stream;

  @override
  Future<int> get exitCode => _exitCompleter.future;

  void emitText(String text) {
    _outputController.add(Uint8List.fromList(utf8.encode(text)));
  }

  Future<void> finish(int exitCode) async {
    if (!_exitCompleter.isCompleted) {
      _exitCompleter.complete(exitCode);
    }
    await _closeOutput();
  }

  @override
  Future<void> write(Uint8List bytes) async {
    _ensureOpen();
    writes.add(List<int>.unmodifiable(bytes));
  }

  @override
  Future<void> resize({required int columns, required int rows}) async {
    _ensureOpen();
    resizes.add(_Resize(columns, rows));
  }

  @override
  Future<void> kill() async {
    if (_closed) {
      return;
    }
    await finish(143);
  }

  @override
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    if (!_exitCompleter.isCompleted) {
      _exitCompleter.complete(0);
    }
    await _closeOutput();
  }

  Future<void> _closeOutput() async {
    if (_outputClosed) {
      return;
    }
    _outputClosed = true;
    await _outputController.close();
  }

  void _ensureOpen() {
    if (_closed) {
      throw StateError('Fake PTY backend is closed.');
    }
  }
}

final class _Resize {
  const _Resize(this.columns, this.rows);

  final int columns;
  final int rows;

  @override
  bool operator ==(Object other) =>
      other is _Resize && other.columns == columns && other.rows == rows;

  @override
  int get hashCode => Object.hash(columns, rows);

  @override
  String toString() => '_Resize($columns, $rows)';
}
