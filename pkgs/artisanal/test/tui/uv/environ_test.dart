import 'package:artisanal/src/uv/uv.dart';

import 'package:test/test.dart';

void main() {
  group('Environ', () {
    test('getenv returns empty for missing keys', () {
      expect(const Environ([]).getenv('TERM'), equals(''));
    });

    test('lookupEnv finds existing value', () {
      final env = Environ(['TERM=xterm-256color']);
      expect(
        env.lookupEnv('TERM'),
        equals((value: 'xterm-256color', found: true)),
      );
    });

    test('last entry wins when duplicated', () {
      final env = Environ(['TERM=vt100', 'OTHER=1', 'TERM=xterm']);
      expect(env.getenv('TERM'), equals('xterm'));
    });
  });
}
