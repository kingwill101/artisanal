import 'package:artisanal/tui.dart';
import 'package:artisanal/style.dart';
import 'package:test/test.dart';

void main() {
  group('BoxBuilder (fluent builder)', () {
    group('basic construction', () {
      test('creates empty box', () {
        final box = BoxBuilder();
        final output = box.render();
        expect(output, isNotEmpty);
      });

      test('creates box with content', () {
        final box = BoxBuilder()..content('Hello World');
        final output = box.render();
        expect(output, contains('Hello World'));
      });

      test('creates box with title', () {
        final box = BoxBuilder()
          ..title('My Box')
          ..content('Content here');
        final output = box.render();
        expect(output, contains('My Box'));
        expect(output, contains('Content here'));
      });

      test('creates box with multi-line content', () {
        final box = BoxBuilder()..content('Line 1\nLine 2\nLine 3');
        final output = box.render();
        expect(output, contains('Line 1'));
        expect(output, contains('Line 2'));
        expect(output, contains('Line 3'));
      });

      test('creates box with lines method', () {
        final box = BoxBuilder()..lines(['Line A', 'Line B', 'Line C']);
        final output = box.render();
        expect(output, contains('Line A'));
        expect(output, contains('Line B'));
        expect(output, contains('Line C'));
      });

      test('adds individual lines', () {
        final box = BoxBuilder()
          ..line('First')
          ..line('Second')
          ..line('Third');
        final output = box.render();
        expect(output, contains('First'));
        expect(output, contains('Second'));
        expect(output, contains('Third'));
      });
    });

    group('borders', () {
      test('uses rounded border by default', () {
        final box = BoxBuilder()..content('Test');
        final output = box.render();
        expect(output, contains('╭'));
        expect(output, contains('╮'));
      });

      test('supports normal border', () {
        final box = BoxBuilder()
          ..content('Test')
          ..border(Border.normal);
        final output = box.render();
        expect(output, contains('┌'));
        expect(output, contains('┐'));
      });

      test('supports thick border', () {
        final box = BoxBuilder()
          ..content('Test')
          ..border(Border.thick);
        final output = box.render();
        expect(output, contains('┏'));
        expect(output, contains('┓'));
      });

      test('supports double border', () {
        final box = BoxBuilder()
          ..content('Test')
          ..border(Border.double);
        final output = box.render();
        expect(output, contains('╔'));
        expect(output, contains('╗'));
      });

      test('supports ASCII border', () {
        final box = BoxBuilder()
          ..content('Test')
          ..border(Border.ascii);
        final output = box.render();
        expect(output, contains('+'));
        expect(output, contains('-'));
        expect(output, contains('|'));
      });

      test('supports block border', () {
        final box = BoxBuilder()
          ..content('Test')
          ..border(Border.block);
        final output = box.render();
        expect(output, contains('█'));
      });
    });

    group('alignment', () {
      test('left aligns title by default', () {
        final box = BoxBuilder()
          ..title('Title')
          ..content('Content')
          ..width(30);
        final output = box.render();
        final lines = output.split('\n');
        expect(lines[0], contains('─ Title '));
      });

      test('center aligns title', () {
        final box = BoxBuilder()
          ..title('Title')
          ..content('Content')
          ..titleAlign(BoxAlign.center)
          ..width(30);
        final output = box.render();
        expect(output, contains('Title'));
      });

      test('right aligns title', () {
        final box = BoxBuilder()
          ..title('Title')
          ..content('Content')
          ..titleAlign(BoxAlign.right)
          ..width(30);
        final output = box.render();
        expect(output, contains('Title'));
      });

      test('left aligns content by default', () {
        final box = BoxBuilder()
          ..content('Short')
          ..width(20);
        final output = box.render();
        expect(output, contains('Short'));
      });

      test('center aligns content', () {
        final box = BoxBuilder()
          ..content('Center')
          ..contentAlign(BoxAlign.center)
          ..width(20);
        final output = box.render();
        expect(output, contains('Center'));
      });

      test('right aligns content', () {
        final box = BoxBuilder()
          ..content('Right')
          ..contentAlign(BoxAlign.right)
          ..width(20);
        final output = box.render();
        expect(output, contains('Right'));
      });
    });

    group('padding', () {
      test('applies uniform padding', () {
        final box = BoxBuilder()
          ..content('X')
          ..padding(2);
        final output = box.render();
        expect(output, contains('X'));
      });

      test('applies vertical/horizontal padding', () {
        final box = BoxBuilder()
          ..content('X')
          ..padding(1, 3);
        final output = box.render();
        expect(output, contains('X'));
      });

      test('applies individual padding values', () {
        final box = BoxBuilder()
          ..content('X')
          ..paddingAll(top: 1, right: 2, bottom: 1, left: 2);
        final output = box.render();
        expect(output, contains('X'));
      });
    });

    group('margin', () {
      test('applies uniform margin', () {
        final box = BoxBuilder()
          ..content('X')
          ..margin(1);
        final output = box.render();
        expect(output, contains('X'));
      });

      test('applies vertical/horizontal margin', () {
        final box = BoxBuilder()
          ..content('X')
          ..margin(1, 2);
        final output = box.render();
        expect(output, contains('X'));
      });

      test('applies individual margin values', () {
        final box = BoxBuilder()
          ..content('X')
          ..marginAll(top: 1, right: 2, bottom: 1, left: 2);
        final output = box.render();
        expect(output, contains('X'));
      });

      test('top margin adds blank lines', () {
        final box = BoxBuilder()
          ..content('X')
          ..marginAll(top: 2);
        final output = box.render();
        expect(output.startsWith('\n\n'), isTrue);
      });

      test('left margin indents box', () {
        final box = BoxBuilder()
          ..content('X')
          ..marginAll(left: 3);
        final output = box.render();
        final lines = output.split('\n');
        expect(lines[0].startsWith('   '), isTrue);
      });
    });

    group('width constraints', () {
      test('applies fixed width', () {
        final box = BoxBuilder()
          ..content('Test')
          ..width(40);
        final output = box.render();
        final lines = output.split('\n');
        final firstLineWidth = Style.visibleLength(lines[0]);
        expect(firstLineWidth, equals(40));
      });

      test('applies minimum width', () {
        final box = BoxBuilder()
          ..content('Hi')
          ..minWidth(20);
        final output = box.render();
        final lines = output.split('\n');
        final firstLineWidth = Style.visibleLength(lines[0]);
        expect(firstLineWidth, greaterThanOrEqualTo(20));
      });

      test('applies maximum width', () {
        final box = BoxBuilder()
          ..content('A very long content that should be limited')
          ..maxWidth(30);
        final output = box.render();
        final lines = output.split('\n');
        final firstLineWidth = Style.visibleLength(lines[0]);
        // Max width is for content, total width includes borders and padding
        expect(firstLineWidth, lessThanOrEqualTo(36));
      });
    });

    group('styling', () {
      test('applies title style', () {
        final box = BoxBuilder()
          ..title('Styled Title')
          ..content('Content')
          ..titleStyle(Style().bold());
        final output = box.render();
        expect(output, contains('\x1B['));
        expect(output, contains('Styled Title'));
      });

      test('applies border style', () {
        final box = BoxBuilder()
          ..content('Content')
          ..borderStyle(Style().foreground(Colors.blue));
        final output = box.render();
        expect(output, contains('\x1B['));
      });

      test('applies content style', () {
        final box = BoxBuilder()
          ..content('Styled Content')
          ..contentStyle(Style().italic());
        final output = box.render();
        expect(output, contains('\x1B['));
        expect(output, contains('Styled Content'));
      });

      test('applies content style function', () {
        var callCount = 0;
        final box = BoxBuilder()
          ..lines(['Line 0', 'Line 1', 'Line 2'])
          ..contentStyleFunc((line, index) {
            callCount++;
            if (index == 1) {
              return Style().bold();
            }
            return null;
          });
        box.render();
        expect(callCount, equals(3));
      });

      test('content style function receives correct parameters', () {
        final receivedLines = <String>[];
        final receivedIndices = <int>[];

        final box = BoxBuilder()
          ..lines(['First', 'Second', 'Third'])
          ..contentStyleFunc((line, index) {
            receivedLines.add(line);
            receivedIndices.add(index);
            return null;
          });
        box.render();

        expect(receivedIndices, equals([0, 1, 2]));
      });
    });

    group('color profile', () {
      test('respects ASCII color profile', () {
        final box =
            BoxBuilder(
                renderConfig: const RenderConfig(
                  colorProfile: ColorProfile.ascii,
                ),
              )
              ..title('Title')
              ..content('Content')
              ..titleStyle(Style().bold().foreground(Colors.red));
        final output = box.render();
        expect(output.contains('\x1B['), isFalse);
      });

      test('respects trueColor profile', () {
        final box =
            BoxBuilder(
                renderConfig: const RenderConfig(
                  colorProfile: ColorProfile.trueColor,
                ),
              )
              ..content('Content')
              ..contentStyle(Style().foreground(Colors.rgb(255, 100, 50)));
        final output = box.render();
        expect(output, contains('\x1B['));
      });

      test('respects dark background setting', () {
        final boxLight =
            BoxBuilder(
                renderConfig: const RenderConfig(
                  colorProfile: ColorProfile.trueColor,
                  hasDarkBackground: true,
                ),
              )
              ..content('Content')
              ..contentStyle(
                Style().foreground(
                  AdaptiveColor(light: Colors.black, dark: Colors.white),
                ),
              );
        final output1 = boxLight.render();

        final boxDark =
            BoxBuilder(
                renderConfig: const RenderConfig(
                  colorProfile: ColorProfile.trueColor,
                  hasDarkBackground: false,
                ),
              )
              ..content('Content')
              ..contentStyle(
                Style().foreground(
                  AdaptiveColor(light: Colors.black, dark: Colors.white),
                ),
              );
        final output2 = boxDark.render();

        expect(output1, isNot(equals(output2)));
      });
    });

    group('lineCount', () {
      test('calculates correct line count for simple box', () {
        final box = BoxBuilder()..content('Single line');
        expect(
          box.lineCount,
          equals(3),
        ); // Top border + content + bottom border
      });

      test('calculates correct line count with multi-line content', () {
        final box = BoxBuilder()..content('Line 1\nLine 2\nLine 3');
        expect(
          box.lineCount,
          equals(5),
        ); // Top border + 3 lines + bottom border
      });

      test('calculates correct line count with padding', () {
        final box = BoxBuilder()
          ..content('Content')
          ..paddingAll(top: 1, bottom: 1);
        expect(
          box.lineCount,
          equals(5),
        ); // Top border + top padding + content + bottom padding + bottom border
      });

      test('calculates correct line count with margin', () {
        final box = BoxBuilder()
          ..content('Content')
          ..marginAll(top: 2, bottom: 1);
        expect(
          box.lineCount,
          equals(6),
        ); // 2 top margin + top border + content + bottom border + 1 bottom margin
      });
    });

    group('toString', () {
      test('returns rendered output', () {
        final box = BoxBuilder()
          ..title('Test')
          ..content('Content');
        expect(box.toString(), equals(box.render()));
      });
    });

    group('fluent chaining', () {
      test('all methods return BoxBuilder for chaining', () {
        final box = BoxBuilder();

        expect(box.title('Title'), same(box));
        expect(box.content('Content'), same(box));
        expect(box.lines(['A', 'B']), same(box));
        expect(box.line('Line'), same(box));
        expect(box.border(Border.rounded), same(box));
        expect(box.titleStyle(Style()), same(box));
        expect(box.borderStyle(Style()), same(box));
        expect(box.contentStyle(Style()), same(box));
        expect(box.contentStyleFunc((_, _) => null), same(box));
        expect(box.titleAlign(BoxAlign.center), same(box));
        expect(box.contentAlign(BoxAlign.center), same(box));
        expect(box.padding(1), same(box));
        expect(box.paddingAll(top: 1), same(box));
        expect(box.margin(1), same(box));
        expect(box.marginAll(top: 1), same(box));
        expect(box.width(50), same(box));
        expect(box.minWidth(20), same(box));
        expect(box.maxWidth(80), same(box));
      });
    });
  });

  group('BoxPresets', () {
    test('info creates info-styled box', () {
      final box = BoxPresets.info('Info', 'Message');
      final output = box.render();
      expect(output, contains('Info'));
      expect(output, contains('Message'));
    });

    test('success creates success-styled box', () {
      final box = BoxPresets.success('Success', 'Done!');
      final output = box.render();
      expect(output, contains('Success'));
      expect(output, contains('Done!'));
    });

    test('warning creates warning-styled box', () {
      final box = BoxPresets.warning('Warning', 'Caution!');
      final output = box.render();
      expect(output, contains('Warning'));
      expect(output, contains('Caution!'));
    });

    test('error creates error-styled box', () {
      final box = BoxPresets.error('Error', 'Failed!');
      final output = box.render();
      expect(output, contains('Error'));
      expect(output, contains('Failed!'));
    });

    test('simple creates box without title', () {
      final box = BoxPresets.simple('Simple content');
      final output = box.render();
      expect(output, contains('Simple content'));
    });

    test('doubleBorder creates double-bordered box', () {
      final box = BoxPresets.doubleBorder('Title', 'Content');
      final output = box.render();
      expect(output, contains('╔'));
      expect(output, contains('╗'));
      expect(output, contains('Title'));
      expect(output, contains('Content'));
    });

    test('ascii creates ASCII-compatible box', () {
      final box = BoxPresets.ascii('ASCII content', title: 'Title');
      final output = box.render();
      expect(output, contains('+'));
      expect(output, contains('-'));
      expect(output, contains('Title'));
      expect(output, contains('ASCII content'));
    });

    test('ascii without title', () {
      final box = BoxPresets.ascii('No title');
      final output = box.render();
      expect(output, contains('+'));
      expect(output, contains('No title'));
    });
  });

  group('BoxContentStyleFunc', () {
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

  group('BoxAlign enum', () {
    test('has left value', () {
      expect(BoxAlign.left, isNotNull);
    });

    test('has center value', () {
      expect(BoxAlign.center, isNotNull);
    });

    test('has right value', () {
      expect(BoxAlign.right, isNotNull);
    });
  });
}
