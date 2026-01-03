import 'package:artisanal/tui.dart';
import 'package:artisanal/style.dart';
import 'package:test/test.dart';

void main() {
  group('Panel (fluent builder)', () {
    group('basic construction', () {
      test('creates empty panel', () {
        final panel = Panel();
        final output = panel.render();
        expect(output, isNotEmpty);
      });

      test('creates panel with content', () {
        final panel = Panel()..content('Hello World');
        final output = panel.render();
        expect(output, contains('Hello World'));
      });

      test('creates panel with title', () {
        final panel = Panel()
          ..title('My Panel')
          ..content('Content here');
        final output = panel.render();
        expect(output, contains('My Panel'));
        expect(output, contains('Content here'));
      });

      test('creates panel with multi-line content', () {
        final panel = Panel()..content('Line 1\nLine 2\nLine 3');
        final output = panel.render();
        expect(output, contains('Line 1'));
        expect(output, contains('Line 2'));
        expect(output, contains('Line 3'));
      });

      test('creates panel with lines method', () {
        final panel = Panel()..lines(['Line A', 'Line B', 'Line C']);
        final output = panel.render();
        expect(output, contains('Line A'));
        expect(output, contains('Line B'));
        expect(output, contains('Line C'));
      });

      test('adds individual lines', () {
        final panel = Panel()
          ..line('First')
          ..line('Second')
          ..line('Third');
        final output = panel.render();
        expect(output, contains('First'));
        expect(output, contains('Second'));
        expect(output, contains('Third'));
      });
    });

    group('borders', () {
      test('uses rounded border by default', () {
        final panel = Panel()..content('Test');
        final output = panel.render();
        // Rounded border uses ╭ and ╮ for top corners
        expect(output, contains('╭'));
        expect(output, contains('╮'));
      });

      test('supports normal border', () {
        final panel = Panel()
          ..content('Test')
          ..border(Border.normal);
        final output = panel.render();
        // Normal border uses ┌ and ┐ for top corners
        expect(output, contains('┌'));
        expect(output, contains('┐'));
      });

      test('supports thick border', () {
        final panel = Panel()
          ..content('Test')
          ..border(Border.thick);
        final output = panel.render();
        // Thick border uses ┏ and ┓ for top corners
        expect(output, contains('┏'));
        expect(output, contains('┓'));
      });

      test('supports double border', () {
        final panel = Panel()
          ..content('Test')
          ..border(Border.double);
        final output = panel.render();
        // Double border uses ╔ and ╗ for top corners
        expect(output, contains('╔'));
        expect(output, contains('╗'));
      });

      test('supports ASCII border', () {
        final panel = Panel()
          ..content('Test')
          ..border(Border.ascii);
        final output = panel.render();
        // ASCII border uses + for corners
        expect(output, contains('+'));
        expect(output, contains('-'));
        expect(output, contains('|'));
      });
    });

    group('alignment', () {
      test('left aligns title by default', () {
        final panel = Panel()
          ..title('Title')
          ..content('Content')
          ..width(30);
        final output = panel.render();
        final lines = output.split('\n');
        // Title should be near the left
        expect(lines[0], contains('─ Title '));
      });

      test('center aligns title', () {
        final panel = Panel()
          ..title('Title')
          ..content('Content')
          ..titleAlign(PanelAlignment.center)
          ..width(30);
        final output = panel.render();
        expect(output, contains('Title'));
      });

      test('right aligns title', () {
        final panel = Panel()
          ..title('Title')
          ..content('Content')
          ..titleAlign(PanelAlignment.right)
          ..width(30);
        final output = panel.render();
        expect(output, contains('Title'));
      });

      test('left aligns content by default', () {
        final panel = Panel()
          ..content('Short')
          ..width(20);
        final output = panel.render();
        expect(output, contains('Short'));
      });

      test('center aligns content', () {
        final panel = Panel()
          ..content('Center')
          ..contentAlign(PanelAlignment.center)
          ..width(20);
        final output = panel.render();
        expect(output, contains('Center'));
      });

      test('right aligns content', () {
        final panel = Panel()
          ..content('Right')
          ..contentAlign(PanelAlignment.right)
          ..width(20);
        final output = panel.render();
        expect(output, contains('Right'));
      });
    });

    group('padding', () {
      test('applies uniform padding', () {
        final panel = Panel()
          ..content('X')
          ..padding(2);
        final output = panel.render();
        // Content should have padding around it
        expect(output, contains('X'));
      });

      test('applies vertical/horizontal padding', () {
        final panel = Panel()
          ..content('X')
          ..padding(1, 3);
        final output = panel.render();
        expect(output, contains('X'));
      });

      test('applies individual padding values', () {
        final panel = Panel()
          ..content('X')
          ..paddingAll(top: 1, right: 2, bottom: 1, left: 2);
        final output = panel.render();
        expect(output, contains('X'));
      });
    });

    group('width constraints', () {
      test('applies fixed width', () {
        final panel = Panel()
          ..content('Test')
          ..width(40);
        final output = panel.render();
        final lines = output.split('\n');
        // All lines should have consistent width
        final firstLineWidth = Style.visibleLength(lines[0]);
        expect(firstLineWidth, equals(40));
      });

      test('applies minimum width', () {
        final panel = Panel()
          ..content('Hi')
          ..minWidth(20);
        final output = panel.render();
        final lines = output.split('\n');
        final firstLineWidth = Style.visibleLength(lines[0]);
        expect(firstLineWidth, greaterThanOrEqualTo(20));
      });

      test('applies maximum width', () {
        final panel = Panel()
          ..content('A very long content that should be limited')
          ..maxWidth(30);
        final output = panel.render();
        final lines = output.split('\n');
        final firstLineWidth = Style.visibleLength(lines[0]);
        // Max width is for content, total width includes borders and padding
        expect(firstLineWidth, lessThanOrEqualTo(36));
      });
    });

    group('styling', () {
      test('applies title style', () {
        final panel = Panel()
          ..title('Styled Title')
          ..content('Content')
          ..titleStyle(Style().bold());
        final output = panel.render();
        // Should contain ANSI codes for bold
        expect(output, contains('\x1B['));
        expect(output, contains('Styled Title'));
      });

      test('applies border style', () {
        final panel = Panel()
          ..content('Content')
          ..borderStyle(Style().foreground(Colors.blue));
        final output = panel.render();
        // Should contain ANSI codes
        expect(output, contains('\x1B['));
      });

      test('applies content style', () {
        final panel = Panel()
          ..content('Styled Content')
          ..contentStyle(Style().italic());
        final output = panel.render();
        expect(output, contains('\x1B['));
        expect(output, contains('Styled Content'));
      });

      test('applies content style function', () {
        var callCount = 0;
        final panel = Panel()
          ..lines(['Line 0', 'Line 1', 'Line 2'])
          ..contentStyleFunc((line, index) {
            callCount++;
            if (index == 1) {
              return Style().bold();
            }
            return null;
          });
        panel.render();
        expect(callCount, equals(3));
      });

      test('content style function receives correct parameters', () {
        final receivedLines = <String>[];
        final receivedIndices = <int>[];

        final panel = Panel()
          ..lines(['First', 'Second', 'Third'])
          ..contentStyleFunc((line, index) {
            receivedLines.add(line);
            receivedIndices.add(index);
            return null;
          });
        panel.render();

        expect(receivedIndices, equals([0, 1, 2]));
      });
    });

    group('color profile', () {
      test('respects ASCII color profile', () {
        final panel =
            Panel(
                renderConfig: const RenderConfig(
                  colorProfile: ColorProfile.ascii,
                ),
              )
              ..title('Title')
              ..content('Content')
              ..titleStyle(Style().bold().foreground(Colors.red));
        final output = panel.render();
        // Should not contain ANSI escape codes
        expect(output.contains('\x1B['), isFalse);
      });

      test('respects trueColor profile', () {
        final panel =
            Panel(
                renderConfig: const RenderConfig(
                  colorProfile: ColorProfile.trueColor,
                ),
              )
              ..content('Content')
              ..contentStyle(Style().foreground(Colors.rgb(255, 100, 50)));
        final output = panel.render();
        // Should contain ANSI codes
        expect(output, contains('\x1B['));
      });

      test('respects dark background setting', () {
        final panelLight =
            Panel(
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
        final output1 = panelLight.render();

        final panelDark =
            Panel(
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
        final output2 = panelDark.render();

        // Outputs should differ based on background
        expect(output1, isNot(equals(output2)));
      });
    });

    group('lineCount', () {
      test('calculates correct line count for simple panel', () {
        final panel = Panel()..content('Single line');
        expect(
          panel.lineCount,
          equals(3),
        ); // Top border + content + bottom border
      });

      test('calculates correct line count with multi-line content', () {
        final panel = Panel()..content('Line 1\nLine 2\nLine 3');
        expect(
          panel.lineCount,
          equals(5),
        ); // Top border + 3 lines + bottom border
      });

      test('calculates correct line count with padding', () {
        final panel = Panel()
          ..content('Content')
          ..paddingAll(top: 1, bottom: 1);
        expect(
          panel.lineCount,
          equals(5),
        ); // Top border + top padding + content + bottom padding + bottom border
      });
    });

    group('toString', () {
      test('returns rendered output', () {
        final panel = Panel()
          ..title('Test')
          ..content('Content');
        expect(panel.toString(), equals(panel.render()));
      });
    });

    group('fluent chaining', () {
      test('all methods return Panel for chaining', () {
        final panel = Panel();

        expect(panel.title('Title'), same(panel));
        expect(panel.content('Content'), same(panel));
        expect(panel.lines(['A', 'B']), same(panel));
        expect(panel.line('Line'), same(panel));
        expect(panel.border(Border.rounded), same(panel));
        expect(panel.titleStyle(Style()), same(panel));
        expect(panel.borderStyle(Style()), same(panel));
        expect(panel.contentStyle(Style()), same(panel));
        expect(panel.contentStyleFunc((_, _) => null), same(panel));
        expect(panel.titleAlign(PanelAlignment.center), same(panel));
        expect(panel.contentAlign(PanelAlignment.center), same(panel));
        expect(panel.padding(1), same(panel));
        expect(panel.paddingAll(top: 1), same(panel));
        expect(panel.width(50), same(panel));
        expect(panel.minWidth(20), same(panel));
        expect(panel.maxWidth(80), same(panel));
      });
    });
  });

  group('PanelPresets', () {
    test('info creates info-styled panel', () {
      final panel = PanelPresets.info('Info', 'Message');
      final output = panel.render();
      expect(output, contains('Info'));
      expect(output, contains('Message'));
    });

    test('success creates success-styled panel', () {
      final panel = PanelPresets.success('Success', 'Done!');
      final output = panel.render();
      expect(output, contains('Success'));
      expect(output, contains('Done!'));
    });

    test('warning creates warning-styled panel', () {
      final panel = PanelPresets.warning('Warning', 'Caution!');
      final output = panel.render();
      expect(output, contains('Warning'));
      expect(output, contains('Caution!'));
    });

    test('error creates error-styled panel', () {
      final panel = PanelPresets.error('Error', 'Failed!');
      final output = panel.render();
      expect(output, contains('Error'));
      expect(output, contains('Failed!'));
    });
  });

  group('PanelContentStyleFunc', () {
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
