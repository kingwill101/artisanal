import 'package:artisanal/src/colorprofile/downsample.dart';
import 'package:artisanal/src/colorprofile/profile.dart';
import 'package:test/test.dart';

void main() {
  group('colorprofile.downsampleSgr', () {
    test('downsamples truecolor to ansi256', () {
      const input = '\x1B[38;2;107;80;255mCute\x1B[m';
      final out = downsampleSgr(input, Profile.ansi256);
      expect(out, contains('\x1B[38;5;'));
      expect(out, isNot(contains(';2;107;80;255m')));
    });

    test('downsamples truecolor to ansi16', () {
      const input = '\x1B[38;2;255;0;0mX\x1B[m';
      final out = downsampleSgr(input, Profile.ansi);
      expect(out, isNot(contains('[38;')));
      expect(out, contains('\x1B['));
      expect(out, contains('mX'));
    });

    test('ascii drops colors but keeps decoration params', () {
      const input = '\x1B[1;38;2;255;0;0mX\x1B[0m';
      final out = downsampleSgr(input, Profile.ascii);
      expect(out, contains('\x1B[1m'));
      expect(out, isNot(contains('38;')));
      expect(out, contains('X'));
    });

    test('noTty strips SGR sequences', () {
      const input = '\x1B[1;38;2;255;0;0mX\x1B[0m';
      final out = downsampleSgr(input, Profile.noTty);
      expect(out, equals('X'));
    });
  });
}
