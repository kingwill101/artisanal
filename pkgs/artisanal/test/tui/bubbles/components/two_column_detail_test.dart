import 'package:artisanal/tui.dart';
import 'package:artisanal/style.dart';
import 'package:test/test.dart';

void main() {
  group('TwoColumnDetail (fluent builder)', () {
    group('basic construction', () {
      test('creates empty detail', () {
        final detail = TwoColumnDetail();
        final output = detail.render();
        expect(output, isNotEmpty);
      });

      test('creates detail with left and right', () {
        final detail = TwoColumnDetail()
          ..left('Status')
          ..right('OK');
        final output = detail.render();
        expect(output, contains('Status'));
        expect(output, contains('OK'));
      });

      test('creates detail with fill between columns', () {
        final detail = TwoColumnDetail()
          ..left('Name')
          ..right('Value')
          ..width(40);
        final output = detail.render();
        expect(output, contains('Name'));
        expect(output, contains('Value'));
        expect(output, contains('.'));
      });
    });

    group('fill character', () {
      test('uses dot fill by default', () {
        final detail = TwoColumnDetail()
          ..left('Key')
          ..right('Value')
          ..width(30);
        final output = detail.render();
        expect(output, contains('.'));
      });

      test('supports custom fill character', () {
        final detail = TwoColumnDetail()
          ..left('Key')
          ..right('Value')
          ..fillChar('-')
          ..width(30);
        final output = detail.render();
        expect(output, contains('-'));
        expect(output.contains('.'), isFalse);
      });

      test('supports space fill', () {
        final detail = TwoColumnDetail()
          ..left('Key')
          ..right('Value')
          ..fillChar(' ')
          ..width(30);
        final output = detail.render();
        expect(output.contains('.'), isFalse);
      });

      test('supports equals fill', () {
        final detail = TwoColumnDetail()
          ..left('Key')
          ..right('Value')
          ..fillChar('=')
          ..width(30);
        final output = detail.render();
        expect(output, contains('='));
      });
    });

    group('indentation', () {
      test('uses default indent of 2', () {
        final detail = TwoColumnDetail()
          ..left('Key')
          ..right('Value');
        final output = detail.render();
        expect(output.startsWith('  '), isTrue);
      });

      test('supports custom indent', () {
        final detail = TwoColumnDetail()
          ..left('Key')
          ..right('Value')
          ..indent(4);
        final output = detail.render();
        expect(output.startsWith('    '), isTrue);
      });

      test('supports no indent', () {
        final detail = TwoColumnDetail()
          ..left('Key')
          ..right('Value')
          ..indent(0);
        final output = detail.render();
        expect(output.startsWith('Key'), isTrue);
      });
    });

    group('width', () {
      test('uses default width of 80', () {
        final detail = TwoColumnDetail()
          ..left('Key')
          ..right('Value');
        final output = detail.render();
        expect(output, isNotEmpty);
      });

      test('supports custom width', () {
        final detail = TwoColumnDetail()
          ..left('Key')
          ..right('Value')
          ..width(50);
        final output = detail.render();
        expect(output, isNotEmpty);
      });

      test('handles narrow width gracefully', () {
        final detail = TwoColumnDetail()
          ..left('Key')
          ..right('Value')
          ..width(15)
          ..indent(0);
        final output = detail.render();
        expect(output, contains('Key'));
        expect(output, contains('Value'));
      });
    });

    group('styling', () {
      test('applies left style', () {
        final detail = TwoColumnDetail()
          ..left('Key')
          ..right('Value')
          ..leftStyle(Style().bold());
        final output = detail.render();
        expect(output, contains('\x1B['));
        expect(output, contains('Key'));
      });

      test('applies right style', () {
        final detail = TwoColumnDetail()
          ..left('Key')
          ..right('Value')
          ..rightStyle(Style().italic());
        final output = detail.render();
        expect(output, contains('\x1B['));
        expect(output, contains('Value'));
      });

      test('applies fill style', () {
        final detail = TwoColumnDetail()
          ..left('Key')
          ..right('Value')
          ..fillStyle(Style().dim())
          ..width(40);
        final output = detail.render();
        expect(output, contains('\x1B['));
      });

      test('applies style function', () {
        var callCount = 0;
        final detail = TwoColumnDetail()
          ..left('Key')
          ..right('Value')
          ..styleFunc((text, isLeft) {
            callCount++;
            if (isLeft) {
              return Style().bold();
            }
            return Style().italic();
          });
        detail.render();
        expect(callCount, equals(2)); // Called for left and right
      });

      test('style function receives correct parameters', () {
        String? receivedLeft;
        String? receivedRight;
        bool? receivedIsLeft;
        bool? receivedIsRight;

        final detail = TwoColumnDetail()
          ..left('MyKey')
          ..right('MyValue')
          ..styleFunc((text, isLeft) {
            if (isLeft) {
              receivedLeft = text;
              receivedIsLeft = isLeft;
            } else {
              receivedRight = text;
              receivedIsRight = isLeft;
            }
            return null;
          });
        detail.render();

        expect(receivedLeft, equals('MyKey'));
        expect(receivedRight, equals('MyValue'));
        expect(receivedIsLeft, isTrue);
        expect(receivedIsRight, isFalse);
      });

      test('style function takes precedence over individual styles', () {
        var funcCalled = false;
        final detail = TwoColumnDetail()
          ..left('Key')
          ..right('Value')
          ..leftStyle(Style().bold())
          ..styleFunc((text, isLeft) {
            funcCalled = true;
            return Style().italic();
          });
        detail.render();
        expect(funcCalled, isTrue);
      });
    });

    group('color profile', () {
      test('respects ASCII color profile', () {
        final detail =
            TwoColumnDetail(
                renderConfig: const RenderConfig(
                  colorProfile: ColorProfile.ascii,
                ),
              )
              ..left('Key')
              ..right('Value')
              ..leftStyle(Style().bold().foreground(Colors.red));
        final output = detail.render();
        expect(output.contains('\x1B['), isFalse);
      });

      test('respects trueColor profile', () {
        final detail =
            TwoColumnDetail(
                renderConfig: const RenderConfig(
                  colorProfile: ColorProfile.trueColor,
                ),
              )
              ..left('Key')
              ..right('Value')
              ..leftStyle(Style().foreground(Colors.rgb(255, 100, 50)));
        final output = detail.render();
        expect(output, contains('\x1B['));
      });

      test('respects dark background setting', () {
        final detailLight =
            TwoColumnDetail(
                renderConfig: const RenderConfig(
                  colorProfile: ColorProfile.trueColor,
                  hasDarkBackground: true,
                ),
              )
              ..left('Key')
              ..right('Value')
              ..leftStyle(
                Style().foreground(
                  AdaptiveColor(light: Colors.black, dark: Colors.white),
                ),
              );
        final output1 = detailLight.render();

        final detailDark =
            TwoColumnDetail(
                renderConfig: const RenderConfig(
                  colorProfile: ColorProfile.trueColor,
                  hasDarkBackground: false,
                ),
              )
              ..left('Key')
              ..right('Value')
              ..leftStyle(
                Style().foreground(
                  AdaptiveColor(light: Colors.black, dark: Colors.white),
                ),
              );
        final output2 = detailDark.render();

        expect(output1, isNot(equals(output2)));
      });
    });

    group('lineCount', () {
      test('always returns 1', () {
        final detail = TwoColumnDetail()
          ..left('Key')
          ..right('Value');
        expect(detail.lineCount, equals(1));
      });
    });

    group('toString', () {
      test('returns rendered output', () {
        final detail = TwoColumnDetail()
          ..left('Key')
          ..right('Value');
        expect(detail.toString(), equals(detail.render()));
      });
    });

    group('fluent chaining', () {
      test('all methods return TwoColumnDetail for chaining', () {
        final detail = TwoColumnDetail();

        expect(detail.left('Key'), same(detail));
        expect(detail.right('Value'), same(detail));
        expect(detail.fillChar('.'), same(detail));
        expect(detail.indent(2), same(detail));
        expect(detail.width(80), same(detail));
        expect(detail.leftStyle(Style()), same(detail));
        expect(detail.rightStyle(Style()), same(detail));
        expect(detail.fillStyle(Style()), same(detail));
        expect(detail.styleFunc((_, _) => null), same(detail));
      });
    });
  });

  group('TwoColumnDetailList', () {
    group('basic construction', () {
      test('creates empty list', () {
        final list = TwoColumnDetailList();
        final output = list.render();
        expect(output, isEmpty);
      });

      test('creates list with single row', () {
        final list = TwoColumnDetailList()..row('Key', 'Value');
        final output = list.render();
        expect(output, contains('Key'));
        expect(output, contains('Value'));
      });

      test('creates list with multiple rows', () {
        final list = TwoColumnDetailList()
          ..row('Name', 'John')
          ..row('Age', '30')
          ..row('City', 'NYC');
        final output = list.render();
        expect(output, contains('Name'));
        expect(output, contains('John'));
        expect(output, contains('Age'));
        expect(output, contains('30'));
        expect(output, contains('City'));
        expect(output, contains('NYC'));
      });

      test('creates list from map', () {
        final list = TwoColumnDetailList()
          ..rows({'Key1': 'Value1', 'Key2': 'Value2', 'Key3': 'Value3'});
        final output = list.render();
        expect(output, contains('Key1'));
        expect(output, contains('Value1'));
        expect(output, contains('Key2'));
        expect(output, contains('Value2'));
        expect(output, contains('Key3'));
        expect(output, contains('Value3'));
      });
    });

    group('configuration', () {
      test('applies fill character to all rows', () {
        final list = TwoColumnDetailList()
          ..row('A', '1')
          ..row('B', '2')
          ..fillChar('-')
          ..width(30);
        final output = list.render();
        expect(output, contains('-'));
      });

      test('applies indent to all rows', () {
        final list = TwoColumnDetailList()
          ..row('A', '1')
          ..row('B', '2')
          ..indent(4);
        final output = list.render();
        final lines = output.split('\n');
        for (final line in lines) {
          expect(line.startsWith('    '), isTrue);
        }
      });

      test('applies width to all rows', () {
        final list = TwoColumnDetailList()
          ..row('A', '1')
          ..row('B', '2')
          ..width(40);
        final output = list.render();
        expect(output, isNotEmpty);
      });

      test('applies left style to all rows', () {
        final list = TwoColumnDetailList()
          ..row('A', '1')
          ..row('B', '2')
          ..leftStyle(Style().bold());
        final output = list.render();
        expect(output, contains('\x1B['));
      });

      test('applies right style to all rows', () {
        final list = TwoColumnDetailList()
          ..row('A', '1')
          ..row('B', '2')
          ..rightStyle(Style().italic());
        final output = list.render();
        expect(output, contains('\x1B['));
      });

      test('applies style function to all rows', () {
        var callCount = 0;
        final list = TwoColumnDetailList()
          ..row('A', '1')
          ..row('B', '2')
          ..styleFunc((text, isLeft) {
            callCount++;
            return null;
          });
        list.render();
        expect(callCount, equals(4)); // 2 rows * 2 (left + right)
      });
    });

    group('lineCount', () {
      test('returns 0 for empty list', () {
        final list = TwoColumnDetailList();
        expect(list.lineCount, equals(0));
      });

      test('returns correct count for single row', () {
        final list = TwoColumnDetailList()..row('Key', 'Value');
        expect(list.lineCount, equals(1));
      });

      test('returns correct count for multiple rows', () {
        final list = TwoColumnDetailList()
          ..row('A', '1')
          ..row('B', '2')
          ..row('C', '3');
        expect(list.lineCount, equals(3));
      });
    });

    group('toString', () {
      test('returns rendered output', () {
        final list = TwoColumnDetailList()
          ..row('A', '1')
          ..row('B', '2');
        expect(list.toString(), equals(list.render()));
      });
    });

    group('fluent chaining', () {
      test('all methods return TwoColumnDetailList for chaining', () {
        final list = TwoColumnDetailList();

        expect(list.row('Key', 'Value'), same(list));
        expect(list.rows({'A': '1'}), same(list));
        expect(list.fillChar('.'), same(list));
        expect(list.indent(2), same(list));
        expect(list.width(80), same(list));
        expect(list.leftStyle(Style()), same(list));
        expect(list.rightStyle(Style()), same(list));
        expect(list.fillStyle(Style()), same(list));
        expect(list.styleFunc((_, _) => null), same(list));
      });
    });
  });

  group('TwoColumnDetailFactory', () {
    test('status creates status-style row with success', () {
      final detail = TwoColumnDetailFactory.status(
        'Status',
        'OK',
        success: true,
      );
      final output = detail.render();
      expect(output, contains('Status'));
      expect(output, contains('OK'));
      expect(output, contains('\x1B[')); // Has styling
    });

    test('status creates status-style row with failure', () {
      final detail = TwoColumnDetailFactory.status(
        'Status',
        'FAIL',
        success: false,
      );
      final output = detail.render();
      expect(output, contains('Status'));
      expect(output, contains('FAIL'));
      expect(output, contains('\x1B[')); // Has styling
    });

    test('info creates info-style row', () {
      final detail = TwoColumnDetailFactory.info('Key', 'Value');
      final output = detail.render();
      expect(output, contains('Key'));
      expect(output, contains('Value'));
      expect(output, contains('\x1B[')); // Has styling
    });

    test('muted creates muted-style row', () {
      final detail = TwoColumnDetailFactory.muted('Key', 'Value');
      final output = detail.render();
      expect(output, contains('Key'));
      expect(output, contains('Value'));
      expect(output, contains('\x1B[')); // Has styling
    });

    test('spaceFill creates row with space fill', () {
      final detail = TwoColumnDetailFactory.spaceFill('Key', 'Value');
      detail.width(30);
      final output = detail.render();
      expect(output, contains('Key'));
      expect(output, contains('Value'));
      expect(output.contains('.'), isFalse);
    });

    test('dashFill creates row with dash fill', () {
      final detail = TwoColumnDetailFactory.dashFill('Key', 'Value');
      detail.width(30);
      final output = detail.render();
      expect(output, contains('Key'));
      expect(output, contains('Value'));
      expect(output, contains('-'));
    });
  });

  group('TwoColumnStyleFunc', () {
    test('typedef accepts correct signature', () {
      Style? func(String text, bool isLeft) {
        return Style().bold();
      }

      expect(func('test', true), isA<Style>());
    });

    test('can return null', () {
      Style? func(String text, bool isLeft) {
        return null;
      }

      expect(func('test', true), isNull);
    });

    test('receives correct isLeft value for left column', () {
      bool? received;
      Style? func(String text, bool isLeft) {
        received = isLeft;
        return null;
      }

      func('left', true);
      expect(received, isTrue);
    });

    test('receives correct isLeft value for right column', () {
      bool? received;
      Style? func(String text, bool isLeft) {
        received = isLeft;
        return null;
      }

      func('right', false);
      expect(received, isFalse);
    });
  });
}
