import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:artisanal_editor/src/lsp/dart_language_service.dart';
import 'package:artisanal_editor/src/lsp/editor_language_service.dart';
import 'package:test/test.dart';

void main() {
  test(
    'closing a document after the LSP transport disconnects is safe',
    () async {
      final process = _FakeLanguageServerProcess();
      final service = DartLanguageService(
        workspaceRoot: Directory.current.path,
        startProcess: () async => process,
      );
      addTearDown(service.dispose);

      final ready = Completer<void>();
      final subscription = service.events.listen((event) {
        if (event is EditorLanguageStatus &&
            event.ready == true &&
            !ready.isCompleted) {
          ready.complete();
        }
      });
      addTearDown(subscription.cancel);

      service.openDocument(
        path: '${Directory.current.path}/main.dart',
        languageId: 'dart',
        text: 'void main() {}',
      );
      await ready.future;

      // The document has been opened before the transport disappears. Closing
      // it must still remove the editor-side bookkeeping and cancel its timer.
      process.disconnect();
      await Future<void>.delayed(Duration.zero);
      expect(
        () => service.closeDocument('${Directory.current.path}/main.dart'),
        returnsNormally,
      );
    },
  );

  test('disposing after the LSP input pipe breaks is safe', () async {
    final process = _FakeLanguageServerProcess();
    final service = DartLanguageService(
      workspaceRoot: Directory.current.path,
      startProcess: () async => process,
    );
    addTearDown(service.dispose);

    final ready = Completer<void>();
    final subscription = service.events.listen((event) {
      if (event is EditorLanguageStatus &&
          event.ready == true &&
          !ready.isCompleted) {
        ready.complete();
      }
    });
    addTearDown(subscription.cancel);

    service.openDocument(
      path: '${Directory.current.path}/main.dart',
      languageId: 'dart',
      text: 'void main() {}',
    );
    await ready.future;

    process.rejectWrites();
    await expectLater(service.dispose(), completes);
  });
}

final class _FakeLanguageServerProcess implements Process {
  final StreamController<List<int>> _stdout = StreamController();
  late final _languageServer = _LanguageServerConsumer(_stdout);
  late final IOSink _stdin = IOSink(_languageServer);
  final StreamController<List<int>> _stderr = StreamController();
  final Completer<int> _exitCode = Completer();

  @override
  Stream<List<int>> get stdout => _stdout.stream;

  @override
  IOSink get stdin => _stdin;

  @override
  Stream<List<int>> get stderr => _stderr.stream;

  @override
  Future<int> get exitCode => _exitCode.future;

  @override
  int get pid => 1;

  void disconnect() {
    _stdout.close();
    _stderr.close();
  }

  void rejectWrites() => _languageServer.rejectWrites = true;

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    if (!_exitCode.isCompleted) _exitCode.complete(0);
    disconnect();
    return true;
  }
}

final class _LanguageServerConsumer implements StreamConsumer<List<int>> {
  _LanguageServerConsumer(this.output);

  final StreamController<List<int>> output;
  var _respondedToInitialize = false;
  var rejectWrites = false;

  @override
  Future<bool> addStream(Stream<List<int>> stream) async {
    await for (final _ in stream) {
      if (rejectWrites) {
        throw const SocketException('Write failed: broken pipe');
      }
      if (_respondedToInitialize) continue;
      _respondedToInitialize = true;
      final response = jsonEncode({
        'jsonrpc': '2.0',
        'id': 0,
        'result': {'capabilities': <String, Object?>{}},
      });
      final bytes = utf8.encode(response);
      output.add(utf8.encode('Content-Length: ${bytes.length}\r\n\r\n'));
      output.add(bytes);
    }
    return true;
  }

  @override
  Future<void> close() async {}
}
