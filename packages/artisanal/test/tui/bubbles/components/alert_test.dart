import 'package:artisanal/tui.dart';
import 'package:artisanal/style.dart';
import 'package:test/test.dart';

void main() {
  group('Alert (fluent builder)', () {
    group('basic construction', () {
      test('creates empty alert', () {
        final alert = Alert();
        final output = alert.render();
        expect(output, isNotEmpty);
      });

      test('creates alert with message', () {
        final alert = Alert()..message('Hello World');
        final output = alert.render();
        expect(output, contains('Hello World'));
      });

      test('creates alert with multi-line message', () {
        final alert = Alert()..message('Line 1\nLine 2\nLine 3');
        final output = alert.render();
        expect(output, contains('Line 1'));
        expect(output, contains('Line 2'));
        expect(output, contains('Line 3'));
      });
    });

    group('alert types', () {
      test('info type has INFO prefix', () {
        final alert = Alert()
          ..info()
          ..message('Info message');
        final output = alert.render();
        expect(output, contains('[INFO]'));
        expect(output, contains('Info message'));
      });

      test('success type has OK prefix', () {
        final alert = Alert()
          ..success()
          ..message('Success message');
        final output = alert.render();
        expect(output, contains('[OK]'));
        expect(output, contains('Success message'));
      });

      test('warning type has WARNING prefix', () {
        final alert = Alert()
          ..warning()
          ..message('Warning message');
        final output = alert.render();
        expect(output, contains('[WARNING]'));
        expect(output, contains('Warning message'));
      });

      test('error type has ERROR prefix', () {
        final alert = Alert()
          ..error()
          ..message('Error message');
        final output = alert.render();
        expect(output, contains('[ERROR]'));
        expect(output, contains('Error message'));
      });

      test('note type has NOTE prefix', () {
        final alert = Alert()
          ..note()
          ..message('Note message');
        final output = alert.render();
        expect(output, contains('[NOTE]'));
        expect(output, contains('Note message'));
      });

      test('type method sets type', () {
        final alert = Alert()
          ..type(AlertType.warning)
          ..message('Test');
        final output = alert.render();
        expect(output, contains('[WARNING]'));
      });

      test('custom prefix overrides type prefix', () {
        final alert = Alert()
          ..info()
          ..prefix('[CUSTOM]')
          ..message('Test');
        final output = alert.render();
        expect(output, contains('[CUSTOM]'));
        expect(output.contains('[INFO]'), isFalse);
      });
    });

    group('display styles', () {
      test('inline display is default', () {
        final alert = Alert()
          ..info()
          ..message('Inline message');
        final output = alert.render();
        // Inline format: [PREFIX] message (prefix may have ANSI codes)
        expect(output, contains('[INFO]'));
        expect(output, contains('Inline message'));
      });

      test('inline method sets inline display', () {
        final alert = Alert()
          ..info()
          ..inline()
          ..message('Test');
        final output = alert.render();
        expect(output, contains('[INFO]'));
        expect(output, contains('Test'));
      });

      test('block display includes border', () {
        final alert = Alert()
          ..info()
          ..block()
          ..message('Block message');
        final output = alert.render();
        // Block format has borders
        expect(output, contains('[INFO]'));
        expect(output, contains('Block message'));
        // Should have top and bottom borders
        final lines = output.split('\n');
        expect(lines.length, greaterThan(2));
      });

      test('large display includes padding', () {
        final alert = Alert()
          ..info()
          ..large()
          ..message('Large message');
        final output = alert.render();
        // Large format has more lines due to padding
        final lines = output.split('\n');
        expect(lines.length, greaterThan(4));
      });

      test('displayStyle method sets display', () {
        final alert = Alert()
          ..displayStyle(AlertDisplayStyle.block)
          ..message('Test');
        final output = alert.render();
        final lines = output.split('\n');
        expect(lines.length, greaterThan(2));
      });
    });

    group('borders', () {
      test('block uses rounded border by default', () {
        final alert = Alert()
          ..block()
          ..message('Test');
        final output = alert.render();
        expect(output, contains('╭'));
        expect(output, contains('╮'));
      });

      test('block supports custom border', () {
        final alert = Alert()
          ..block()
          ..border(Border.ascii)
          ..message('Test');
        final output = alert.render();
        expect(output, contains('+'));
        expect(output, contains('-'));
      });

      test('large uses rounded border by default', () {
        final alert = Alert()
          ..large()
          ..message('Test');
        final output = alert.render();
        expect(output, contains('╭'));
        expect(output, contains('╮'));
      });

      test('large supports custom border', () {
        final alert = Alert()
          ..large()
          ..border(Border.double)
          ..message('Test');
        final output = alert.render();
        expect(output, contains('╔'));
        expect(output, contains('╗'));
      });
    });

    group('styling', () {
      test('applies prefix style', () {
        final alert =
            Alert(
                renderConfig: const RenderConfig(
                  colorProfile: ColorProfile.trueColor,
                ),
              )
              ..info()
              ..message('Test')
              ..prefixStyle(Style().bold().foreground(Colors.magenta));
        final output = alert.render();
        expect(output, contains('\x1B['));
        expect(output, contains('[INFO]'));
      });

      test('applies message style', () {
        final alert =
            Alert(
                renderConfig: const RenderConfig(
                  colorProfile: ColorProfile.trueColor,
                ),
              )
              ..info()
              ..message('Styled message')
              ..messageStyle(Style().italic());
        final output = alert.render();
        expect(output, contains('\x1B['));
      });

      test('applies message style function', () {
        var callCount = 0;
        final alert =
            Alert(
                renderConfig: const RenderConfig(
                  colorProfile: ColorProfile.trueColor,
                ),
              )
              ..info()
              ..message('Line 0\nLine 1\nLine 2')
              ..messageStyleFunc((line, index) {
                callCount++;
                if (index == 1) {
                  return Style().bold();
                }
                return null;
              });
        alert.render();
        expect(callCount, equals(3));
      });

      test('applies border style for block', () {
        final alert =
            Alert(
                renderConfig: const RenderConfig(
                  colorProfile: ColorProfile.trueColor,
                ),
              )
              ..block()
              ..message('Test')
              ..borderStyle(Style().foreground(Colors.cyan));
        final output = alert.render();
        expect(output, contains('\x1B['));
      });
    });

    group('dimensions', () {
      test('applies padding for block', () {
        final alert = Alert()
          ..block()
          ..message('Test')
          ..padding(2);
        final output = alert.render();
        expect(output, isNotEmpty);
      });

      test('applies width for block', () {
        final alert = Alert()
          ..block()
          ..message('Test')
          ..width(50);
        final output = alert.render();
        final lines = output.split('\n');
        expect(Style.visibleLength(lines[0]), equals(50));
      });

      test('applies padding for large', () {
        final alert = Alert()
          ..large()
          ..message('Test')
          ..padding(3);
        final output = alert.render();
        expect(output, isNotEmpty);
      });
    });

    group('color profile', () {
      test('respects ASCII color profile', () {
        final alert =
            Alert(
                renderConfig: const RenderConfig(
                  colorProfile: ColorProfile.ascii,
                ),
              )
              ..info()
              ..message('Test')
              ..prefixStyle(Style().bold().foreground(Colors.red));
        final output = alert.render();
        expect(output.contains('\x1B['), isFalse);
      });

      test('respects trueColor profile', () {
        final alert =
            Alert(
                renderConfig: const RenderConfig(
                  colorProfile: ColorProfile.trueColor,
                ),
              )
              ..info()
              ..message('Test')
              ..prefixStyle(Style().foreground(Colors.rgb(100, 150, 200)));
        final output = alert.render();
        expect(output, contains('\x1B['));
      });

      test('respects dark background setting', () {
        final alertLight =
            Alert(
                renderConfig: const RenderConfig(
                  colorProfile: ColorProfile.trueColor,
                  hasDarkBackground: true,
                ),
              )
              ..info()
              ..message('Test')
              ..prefixStyle(
                Style().foreground(
                  AdaptiveColor(light: Colors.black, dark: Colors.white),
                ),
              );
        final output1 = alertLight.render();

        final alertDark =
            Alert(
                renderConfig: const RenderConfig(
                  colorProfile: ColorProfile.trueColor,
                  hasDarkBackground: false,
                ),
              )
              ..info()
              ..message('Test')
              ..prefixStyle(
                Style().foreground(
                  AdaptiveColor(light: Colors.black, dark: Colors.white),
                ),
              );
        final output2 = alertDark.render();

        expect(output1, isNot(equals(output2)));
      });
    });

    group('lineCount', () {
      test('inline has correct line count', () {
        final alert = Alert()
          ..inline()
          ..message('Single line');
        expect(alert.lineCount, equals(1));
      });

      test('inline with multi-line message', () {
        final alert = Alert()
          ..inline()
          ..message('Line 1\nLine 2\nLine 3');
        expect(alert.lineCount, equals(3));
      });

      test('block has correct line count', () {
        final alert = Alert()
          ..block()
          ..message('Single line');
        // 2 borders + prefix + message
        expect(alert.lineCount, equals(4));
      });

      test('large has correct line count', () {
        final alert = Alert()
          ..large()
          ..message('Single line');
        // 2 borders + 2 padding + prefix + empty + message + extra newline
        expect(alert.lineCount, greaterThan(5));
      });
    });

    group('toString', () {
      test('returns rendered output', () {
        final alert = Alert()
          ..info()
          ..message('Test message');
        expect(alert.toString(), equals(alert.render()));
      });
    });

    group('fluent chaining', () {
      test('all methods return Alert for chaining', () {
        final alert = Alert();

        expect(alert.message('Test'), same(alert));
        expect(alert.type(AlertType.info), same(alert));
        expect(alert.info(), same(alert));
        expect(alert.success(), same(alert));
        expect(alert.warning(), same(alert));
        expect(alert.error(), same(alert));
        expect(alert.note(), same(alert));
        expect(alert.displayStyle(AlertDisplayStyle.inline), same(alert));
        expect(alert.inline(), same(alert));
        expect(alert.block(), same(alert));
        expect(alert.large(), same(alert));
        expect(alert.prefix('[TEST]'), same(alert));
        expect(alert.prefixStyle(Style()), same(alert));
        expect(alert.messageStyle(Style()), same(alert));
        expect(alert.messageStyleFunc((_, _) => null), same(alert));
        expect(alert.border(Border.rounded), same(alert));
        expect(alert.borderStyle(Style()), same(alert));
        expect(alert.padding(1), same(alert));
        expect(alert.width(50), same(alert));
      });
    });
  });

  group('AlertFactory', () {
    test('infoAlert creates info alert', () {
      final alert = AlertFactory.infoAlert('Info message');
      final output = alert.render();
      expect(output, contains('[INFO]'));
      expect(output, contains('Info message'));
    });

    test('successAlert creates success alert', () {
      final alert = AlertFactory.successAlert('Success message');
      final output = alert.render();
      expect(output, contains('[OK]'));
      expect(output, contains('Success message'));
    });

    test('warningAlert creates warning alert', () {
      final alert = AlertFactory.warningAlert('Warning message');
      final output = alert.render();
      expect(output, contains('[WARNING]'));
      expect(output, contains('Warning message'));
    });

    test('errorAlert creates error alert', () {
      final alert = AlertFactory.errorAlert('Error message');
      final output = alert.render();
      expect(output, contains('[ERROR]'));
      expect(output, contains('Error message'));
    });

    test('noteAlert creates note alert', () {
      final alert = AlertFactory.noteAlert('Note message');
      final output = alert.render();
      expect(output, contains('[NOTE]'));
      expect(output, contains('Note message'));
    });

    test('infoBlock creates block info alert', () {
      final alert = AlertFactory.infoBlock('Block info');
      final output = alert.render();
      final lines = output.split('\n');
      expect(lines.length, greaterThan(2));
      expect(output, contains('[INFO]'));
    });

    test('successBlock creates block success alert', () {
      final alert = AlertFactory.successBlock('Block success');
      final output = alert.render();
      final lines = output.split('\n');
      expect(lines.length, greaterThan(2));
    });

    test('warningBlock creates block warning alert', () {
      final alert = AlertFactory.warningBlock('Block warning');
      final output = alert.render();
      final lines = output.split('\n');
      expect(lines.length, greaterThan(2));
    });

    test('errorBlock creates block error alert', () {
      final alert = AlertFactory.errorBlock('Block error');
      final output = alert.render();
      final lines = output.split('\n');
      expect(lines.length, greaterThan(2));
    });

    test('infoLarge creates large info alert', () {
      final alert = AlertFactory.infoLarge('Large info');
      final output = alert.render();
      final lines = output.split('\n');
      expect(lines.length, greaterThan(5));
    });

    test('successLarge creates large success alert', () {
      final alert = AlertFactory.successLarge('Large success');
      final output = alert.render();
      final lines = output.split('\n');
      expect(lines.length, greaterThan(5));
    });

    test('warningLarge creates large warning alert', () {
      final alert = AlertFactory.warningLarge('Large warning');
      final output = alert.render();
      final lines = output.split('\n');
      expect(lines.length, greaterThan(5));
    });

    test('errorLarge creates large error alert', () {
      final alert = AlertFactory.errorLarge('Large error');
      final output = alert.render();
      final lines = output.split('\n');
      expect(lines.length, greaterThan(5));
    });
  });

  group('AlertStyleFunc', () {
    test('typedef accepts correct signature', () {
      Style? func(String line, int lineIndex) {
        return Style().bold();
      }
      expect(func('test', 0), isA<Style>());
    });

    test('can return null', () {
      Style? func(String line, int lineIndex) {
        return null;
      }
      expect(func('test', 0), isNull);
    });
  });
}
