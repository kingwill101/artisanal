import 'dart:io';

import 'package:artisanal_capture/src/cli/bounded_file.dart';
import 'package:test/test.dart';

void main() {
  late Directory temp;
  late File empty;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('bounded-capture-');
    empty = await File('${temp.path}/empty').writeAsString('');
  });
  tearDown(() => temp.delete(recursive: true));

  test(
    'enforces observed bytes before UTF-8 decoding despite small stat',
    () async {
      final source = _GrowingFile(empty, [
        [0xff],
        List.filled(8, 65),
      ]);
      await expectLater(
        readBoundedString(source, 8, 'Source'),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('8 bytes limit'),
          ),
        ),
      );
      expect(source.requestedEnd, 9);
      expect(source.closed, isTrue);
      expect(source.readPastLimit, isFalse);
    },
  );

  test('accepts exactly the byte limit', () async {
    await empty.writeAsString('four');
    expect(await readBoundedString(empty, 4, 'Source'), 'four');
  });
}

// A deterministic append/race probe: metadata still describes an empty regular
// file, while the stream delivers more bytes than that snapshot advertised.
class _GrowingFile implements File {
  _GrowingFile(this.metadata, this.chunks);
  final File metadata;
  final List<List<int>> chunks;
  int? requestedEnd;
  bool closed = false;
  bool readPastLimit = false;

  @override
  Future<FileStat> stat() => metadata.stat();

  @override
  Stream<List<int>> openRead([int? start, int? end]) async* {
    requestedEnd = end;
    try {
      for (final chunk in chunks) {
        yield chunk;
      }
      readPastLimit = true;
    } finally {
      closed = true;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
