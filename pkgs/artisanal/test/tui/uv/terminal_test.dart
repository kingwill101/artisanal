import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:artisanal/src/uv/uv.dart';

void main() {
  group('Terminal', () {
    late StreamController<List<int>> inputController;
    late StringBuffer outputBuffer;
    late Terminal terminal;

    setUp(() {
      inputController = StreamController<List<int>>();
      outputBuffer = StringBuffer();
      terminal = Terminal(
        input: inputController.stream,
        output: _MockIOSink(outputBuffer),
      );
    });

    test('start and stop', () async {
      final eventFuture = terminal.events.firstWhere(
        (e) => e is WindowSizeEvent,
      );
      await terminal.start(handleSignals: false);
      await eventFuture;
      await terminal.stop();
    });

    test('receives key events', () async {
      await terminal.start(handleSignals: false);
      final eventFuture = terminal.events
          .where((e) => e is KeyPressEvent)
          .first;

      inputController.add('a'.codeUnits);

      final event = await eventFuture as KeyPressEvent;
      expect(event.key().code, 'a'.codeUnitAt(0));

      await terminal.stop();
    });

    test('draw writes to output', () async {
      await terminal.start(handleSignals: false);
      terminal.resize(10, 10);
      terminal.setCell(0, 0, Cell(content: 'X'));
      terminal.draw();

      expect(outputBuffer.toString(), isNotEmpty);
      await terminal.stop();
    });
  });
}

class _MockIOSink implements IOSink {
  _MockIOSink(this.buffer);
  final StringBuffer buffer;

  @override
  void add(List<int> data) {
    buffer.write(String.fromCharCodes(data));
  }

  @override
  void write(Object? obj) {
    buffer.write(obj);
  }

  @override
  void writeAll(Iterable objects, [String separator = ""]) {
    buffer.writeAll(objects, separator);
  }

  @override
  void writeCharCode(int charCode) {
    buffer.writeCharCode(charCode);
  }

  @override
  void writeln([Object? obj = ""]) {
    buffer.writeln(obj);
  }

  @override
  Future addStream(Stream<List<int>> stream) async {}

  @override
  Future close() async {}

  @override
  Future get done => Future.value();

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  set encoding(Encoding encoding) {}
  @override
  Encoding get encoding => utf8;

  @override
  Future flush() async {}
}
