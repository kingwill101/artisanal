import 'package:artisanal/src/colorprofile/detect.dart';
import 'package:artisanal/src/colorprofile/profile.dart';
import 'package:test/test.dart';

void main() {
  group('colorprofile.detect', () {
    test('TERM=dumb is treated as noTty', () {
      final p = detect(isTty: true, env: {'TERM': 'dumb'}, isWindows: false);
      expect(p, equals(Profile.noTty));
    });

    test('TERM=xterm implies ANSI', () {
      final p = detect(isTty: true, env: {'TERM': 'xterm'}, isWindows: false);
      expect(p, equals(Profile.ansi));
    });

    test('TERM=rio implies trueColor', () {
      final p = detect(isTty: true, env: {'TERM': 'rio'}, isWindows: false);
      expect(p, equals(Profile.trueColor));
    });

    test('TERM=xterm-256color implies ansi256', () {
      final p = detect(
        isTty: true,
        env: {'TERM': 'xterm-256color'},
        isWindows: false,
      );
      expect(p, equals(Profile.ansi256));
    });

    test('NO_COLOR disables colors but keeps ANSI capability', () {
      final p = detect(
        isTty: true,
        env: {'TERM': 'xterm-256color', 'NO_COLOR': ''},
        isWindows: false,
      );
      expect(p, equals(Profile.ascii));
    });

    test('CLICOLOR_FORCE forces colors even when not a TTY', () {
      final p = detect(
        isTty: false,
        env: {'TERM': 'xterm-256color', 'CLICOLOR_FORCE': '1'},
        isWindows: false,
      );
      expect(p, equals(Profile.ansi256));
    });
  });
}
