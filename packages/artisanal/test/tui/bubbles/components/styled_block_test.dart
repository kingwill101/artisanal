import 'package:artisanal/tui.dart';
import 'package:artisanal/style.dart';
import 'package:test/test.dart';

void main() {
  group('StyledBlock (fluent builder)', () {
    group('basic construction', () {
      test('creates empty styled block', () {
        final block = StyledBlock();
        final output = block.render();
        expect(output, isNotEmpty);
      });

      test('creates block with message', () {
        final block = StyledBlock()..message('Hello World');
        final output = block.render();
        expect(output, contains('Hello World'));
      });

      test('creates block with multi-line message', () {
        final block = StyledBlock()..message('Line 1\nLine 2\nLine 3');
        final output = block.render();
        expect(output, contains('Line 1'));
        expect(output, contains('Line 2'));
        expect(output, contains('Line 3'));
      });
    });

    group('block types', () {
      test('info type has INFO prefix', () {
        final block = StyledBlock()
          ..info()
          ..message('Info message');
        final output = block.render();
        expect(output, contains('[INFO]'));
        expect(output, contains('Info message'));
      });

      test('success type has OK prefix', () {
        final block = StyledBlock()
          ..success()
          ..message('Success message');
        final output = block.render();
        expect(output, contains('[OK]'));
        expect(output, contains('Success message'));
      });

      test('warning type has WARNING prefix', () {
        final block = StyledBlock()
          ..warning()
          ..message('Warning message');
        final output = block.render();
        expect(output, contains('[WARNING]'));
        expect(output, contains('Warning message'));
      });

      test('error type has ERROR prefix', () {
        final block = StyledBlock()
          ..error()
          ..message('Error message');
        final output = block.render();
        expect(output, contains('[ERROR]'));
        expect(output, contains('Error message'));
      });

      test('note type has NOTE prefix', () {
        final block = StyledBlock()
          ..note()
          ..message('Note message');
        final output = block.render();
        expect(output, contains('[NOTE]'));
        expect(output, contains('Note message'));
      });

      test('type method sets type', () {
        final block = StyledBlock()
          ..type(BlockStyleType.warning)
          ..message('Test');
        final output = block.render();
        expect(output, contains('[WARNING]'));
      });

      test('custom prefix overrides type prefix', () {
        final block = StyledBlock()
          ..info()
          ..prefix('[CUSTOM]')
          ..message('Test');
        final output = block.render();
        expect(output, contains('[CUSTOM]'));
        expect(output.contains('[INFO]'), isFalse);
      });
    });

    group('display styles', () {
      test('inline display is default', () {
        final block = StyledBlock()
          ..info()
          ..message('Inline message');
        final output = block.render();
        expect(output, contains('[INFO]'));
        expect(output, contains('Inline message'));
      });

      test('inline method sets inline display', () {
        final block = StyledBlock()
          ..info()
          ..inline()
          ..message('Test');
        final output = block.render();
        expect(output, contains('[INFO]'));
      });

      test('fullWidth display includes background', () {
        final block = StyledBlock()
          ..info()
          ..fullWidth()
          ..message('Full width message');
        final output = block.render();
        // Full width format has more lines
        final lines = output.split('\n');
        expect(lines.length, greaterThan(2));
      });

      test('bordered display includes border', () {
        final block = StyledBlock()
          ..info()
          ..bordered()
          ..message('Bordered message');
        final output = block.render();
        // Should have top and bottom borders
        expect(output, contains('╭'));
        expect(output, contains('╮'));
      });

      test('displayStyle method sets display', () {
        final block = StyledBlock()
          ..displayStyle(StyledBlockDisplayStyle.bordered)
          ..message('Test');
        final output = block.render();
        expect(output, contains('╭'));
      });
    });

    group('colors', () {
      test('applies background color for fullWidth', () {
        final block = StyledBlock()
          ..fullWidth()
          ..backgroundColor(Colors.blue)
          ..message('Test');
        final output = block.render();
        expect(output, contains('\x1B['));
      });

      test('applies foreground color', () {
        final block = StyledBlock()
          ..fullWidth()
          ..foregroundColor(Colors.white)
          ..message('Test');
        final output = block.render();
        expect(output, contains('\x1B['));
      });

      test('applies both background and foreground colors', () {
        final block = StyledBlock()
          ..fullWidth()
          ..backgroundColor(Colors.red)
          ..foregroundColor(Colors.white)
          ..message('Test');
        final output = block.render();
        expect(output, contains('\x1B['));
      });
    });

    group('borders', () {
      test('bordered uses rounded border by default', () {
        final block = StyledBlock()
          ..bordered()
          ..message('Test');
        final output = block.render();
        expect(output, contains('╭'));
        expect(output, contains('╮'));
      });

      test('bordered supports custom border', () {
        final block = StyledBlock()
          ..bordered()
          ..border(Border.ascii)
          ..message('Test');
        final output = block.render();
        expect(output, contains('+'));
        expect(output, contains('-'));
      });

      test('bordered supports double border', () {
        final block = StyledBlock()
          ..bordered()
          ..border(Border.double)
          ..message('Test');
        final output = block.render();
        expect(output, contains('╔'));
        expect(output, contains('╗'));
      });
    });

    group('styling', () {
      test('applies prefix style', () {
        final block = StyledBlock()
          ..info()
          ..message('Test')
          ..prefixStyle(Style().bold().foreground(Colors.magenta));
        final output = block.render();
        expect(output, contains('\x1B['));
        expect(output, contains('[INFO]'));
      });

      test('applies content style', () {
        final block = StyledBlock()
          ..info()
          ..message('Styled content')
          ..contentStyle(Style().italic());
        final output = block.render();
        expect(output, contains('\x1B['));
      });

      test('applies content style function', () {
        var callCount = 0;
        final block = StyledBlock()
          ..info()
          ..message('Line 0\nLine 1\nLine 2')
          ..contentStyleFunc((line, index) {
            callCount++;
            if (index == 1) {
              return Style().bold();
            }
            return null;
          });
        block.render();
        expect(callCount, equals(3));
      });

      test('applies border style for bordered', () {
        final block = StyledBlock()
          ..bordered()
          ..message('Test')
          ..borderStyle(Style().foreground(Colors.cyan));
        final output = block.render();
        expect(output, contains('\x1B['));
      });
    });

    group('dimensions', () {
      test('applies padding', () {
        final block = StyledBlock()
          ..bordered()
          ..message('Test')
          ..padding(2);
        final output = block.render();
        expect(output, isNotEmpty);
      });

      test('applies width', () {
        final block = StyledBlock()
          ..bordered()
          ..message('Test')
          ..width(50);
        final output = block.render();
        expect(output, isNotEmpty);
      });

      test('applies maxWidth', () {
        final block = StyledBlock()
          ..bordered()
          ..message('A very long message that might exceed the max width')
          ..maxWidth(40);
        final output = block.render();
        expect(output, isNotEmpty);
      });
    });

    group('color profile', () {
      test('respects ASCII color profile', () {
        final block =
            StyledBlock(
                renderConfig: const RenderConfig(
                  colorProfile: ColorProfile.ascii,
                ),
              )
              ..info()
              ..message('Test')
              ..prefixStyle(Style().bold().foreground(Colors.red));
        final output = block.render();
        expect(output.contains('\x1B['), isFalse);
      });

      test('respects trueColor profile', () {
        final block =
            StyledBlock(
                renderConfig: const RenderConfig(
                  colorProfile: ColorProfile.trueColor,
                ),
              )
              ..info()
              ..message('Test')
              ..prefixStyle(Style().foreground(Colors.rgb(100, 150, 200)));
        final output = block.render();
        expect(output, contains('\x1B['));
      });

      test('respects dark background setting', () {
        final blockLight =
            StyledBlock(
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
        final output1 = blockLight.render();

        final blockDark =
            StyledBlock(
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
        final output2 = blockDark.render();

        expect(output1, isNot(equals(output2)));
      });
    });

    group('lineCount', () {
      test('inline has correct line count', () {
        final block = StyledBlock()
          ..inline()
          ..message('Single line');
        // Inline adds leading newline
        expect(block.lineCount, equals(2));
      });

      test('inline with multi-line message', () {
        final block = StyledBlock()
          ..inline()
          ..message('Line 1\nLine 2\nLine 3');
        expect(block.lineCount, equals(4)); // 3 lines + leading newline
      });

      test('fullWidth has correct line count', () {
        final block = StyledBlock()
          ..fullWidth()
          ..message('Single line');
        // top padding + prefix + content + bottom padding + leading newline
        expect(block.lineCount, greaterThan(3));
      });

      test('bordered has correct line count', () {
        final block = StyledBlock()
          ..bordered()
          ..message('Single line');
        // 2 borders + prefix + empty line + message
        expect(block.lineCount, equals(5));
      });
    });

    group('toString', () {
      test('returns rendered output', () {
        final block = StyledBlock()
          ..info()
          ..message('Test message');
        expect(block.toString(), equals(block.render()));
      });
    });

    group('fluent chaining', () {
      test('all methods return StyledBlock for chaining', () {
        final block = StyledBlock();

        expect(block.message('Test'), same(block));
        expect(block.type(BlockStyleType.info), same(block));
        expect(block.info(), same(block));
        expect(block.success(), same(block));
        expect(block.warning(), same(block));
        expect(block.error(), same(block));
        expect(block.note(), same(block));
        expect(block.displayStyle(StyledBlockDisplayStyle.inline), same(block));
        expect(block.inline(), same(block));
        expect(block.fullWidth(), same(block));
        expect(block.bordered(), same(block));
        expect(block.prefix('[TEST]'), same(block));
        expect(block.backgroundColor(Colors.blue), same(block));
        expect(block.foregroundColor(Colors.white), same(block));
        expect(block.prefixStyle(Style()), same(block));
        expect(block.contentStyle(Style()), same(block));
        expect(block.contentStyleFunc((_, _) => null), same(block));
        expect(block.border(Border.rounded), same(block));
        expect(block.borderStyle(Style()), same(block));
        expect(block.padding(1), same(block));
        expect(block.width(50), same(block));
        expect(block.maxWidth(80), same(block));
      });
    });
  });

  group('StyledBlockFactory', () {
    test('infoBlock creates info block', () {
      final block = StyledBlockFactory.infoBlock('Info message');
      final output = block.render();
      expect(output, contains('[INFO]'));
      expect(output, contains('Info message'));
    });

    test('successBlock creates success block', () {
      final block = StyledBlockFactory.successBlock('Success message');
      final output = block.render();
      expect(output, contains('[OK]'));
      expect(output, contains('Success message'));
    });

    test('warningBlock creates warning block', () {
      final block = StyledBlockFactory.warningBlock('Warning message');
      final output = block.render();
      expect(output, contains('[WARNING]'));
      expect(output, contains('Warning message'));
    });

    test('errorBlock creates error block', () {
      final block = StyledBlockFactory.errorBlock('Error message');
      final output = block.render();
      expect(output, contains('[ERROR]'));
      expect(output, contains('Error message'));
    });

    test('noteBlock creates note block', () {
      final block = StyledBlockFactory.noteBlock('Note message');
      final output = block.render();
      expect(output, contains('[NOTE]'));
      expect(output, contains('Note message'));
    });

    test('infoFullWidth creates full-width info block', () {
      final block = StyledBlockFactory.infoFullWidth('Full width info');
      final output = block.render();
      final lines = output.split('\n');
      expect(lines.length, greaterThan(3));
    });

    test('successFullWidth creates full-width success block', () {
      final block = StyledBlockFactory.successFullWidth('Full width success');
      final output = block.render();
      final lines = output.split('\n');
      expect(lines.length, greaterThan(3));
    });

    test('warningFullWidth creates full-width warning block', () {
      final block = StyledBlockFactory.warningFullWidth('Full width warning');
      final output = block.render();
      final lines = output.split('\n');
      expect(lines.length, greaterThan(3));
    });

    test('errorFullWidth creates full-width error block', () {
      final block = StyledBlockFactory.errorFullWidth('Full width error');
      final output = block.render();
      final lines = output.split('\n');
      expect(lines.length, greaterThan(3));
    });

    test('infoBordered creates bordered info block', () {
      final block = StyledBlockFactory.infoBordered('Bordered info');
      final output = block.render();
      expect(output, contains('╭'));
      expect(output, contains('[INFO]'));
    });

    test('successBordered creates bordered success block', () {
      final block = StyledBlockFactory.successBordered('Bordered success');
      final output = block.render();
      expect(output, contains('╭'));
      expect(output, contains('[OK]'));
    });

    test('warningBordered creates bordered warning block', () {
      final block = StyledBlockFactory.warningBordered('Bordered warning');
      final output = block.render();
      expect(output, contains('╭'));
      expect(output, contains('[WARNING]'));
    });

    test('errorBordered creates bordered error block', () {
      final block = StyledBlockFactory.errorBordered('Bordered error');
      final output = block.render();
      expect(output, contains('╭'));
      expect(output, contains('[ERROR]'));
    });
  });

  group('StyledBlockStyleFunc', () {
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

  group('StyledBlockDisplayStyle enum', () {
    test('has inline value', () {
      expect(StyledBlockDisplayStyle.inline, isNotNull);
    });

    test('has fullWidth value', () {
      expect(StyledBlockDisplayStyle.fullWidth, isNotNull);
    });

    test('has bordered value', () {
      expect(StyledBlockDisplayStyle.bordered, isNotNull);
    });
  });

  group('Comment (fluent builder)', () {
    group('basic construction', () {
      test('creates empty comment', () {
        final comment = Comment();
        final output = comment.render();
        expect(output, isNotEmpty);
      });

      test('creates comment with text', () {
        final comment = Comment()..text('This is a comment');
        final output = comment.render();
        expect(output, contains('This is a comment'));
      });

      test('creates comment with multi-line text', () {
        final comment = Comment()..text('Line 1\nLine 2\nLine 3');
        final output = comment.render();
        expect(output, contains('Line 1'));
        expect(output, contains('Line 2'));
        expect(output, contains('Line 3'));
      });
    });

    group('prefix', () {
      test('uses // prefix by default', () {
        final comment = Comment()..text('Comment');
        final output = comment.render();
        expect(output, contains('// Comment'));
      });

      test('supports custom prefix', () {
        final comment = Comment()
          ..text('Comment')
          ..prefix('#');
        final output = comment.render();
        expect(output, contains('# Comment'));
        expect(output.contains('//'), isFalse);
      });

      test('supports multi-character prefix', () {
        final comment = Comment()
          ..text('Comment')
          ..prefix('/*');
        final output = comment.render();
        expect(output, contains('/* Comment'));
      });

      test('supports empty prefix', () {
        final comment = Comment()
          ..text('Comment')
          ..prefix('');
        final output = comment.render();
        expect(output, contains(' Comment'));
      });
    });

    group('styling', () {
      test('applies default dim style', () {
        final comment = Comment()..text('Comment');
        final output = comment.render();
        // Should have ANSI codes for dim
        expect(output, contains('\x1B['));
      });

      test('applies custom style', () {
        final comment = Comment()
          ..text('Comment')
          ..style(Style().italic().foreground(Colors.gray));
        final output = comment.render();
        expect(output, contains('\x1B['));
      });
    });

    group('color profile', () {
      test('respects ASCII color profile', () {
        final comment =
            Comment(
                renderConfig: const RenderConfig(
                  colorProfile: ColorProfile.ascii,
                ),
              )
              ..text('Comment')
              ..style(Style().bold().foreground(Colors.red));
        final output = comment.render();
        expect(output.contains('\x1B['), isFalse);
      });

      test('respects trueColor profile', () {
        final comment =
            Comment(
                renderConfig: const RenderConfig(
                  colorProfile: ColorProfile.trueColor,
                ),
              )
              ..text('Comment')
              ..style(Style().foreground(Colors.rgb(100, 100, 100)));
        final output = comment.render();
        expect(output, contains('\x1B['));
      });
    });

    group('multi-line handling', () {
      test('each line has prefix', () {
        final comment = Comment()..text('Line 1\nLine 2\nLine 3');
        final output = comment.render();
        final lines = output.split('\n');
        expect(lines.length, equals(3));
        for (final line in lines) {
          expect(line, contains('//'));
        }
      });
    });

    group('lineCount', () {
      test('returns correct count for single line', () {
        final comment = Comment()..text('Single line');
        expect(comment.lineCount, equals(1));
      });

      test('returns correct count for multi-line', () {
        final comment = Comment()..text('Line 1\nLine 2\nLine 3');
        expect(comment.lineCount, equals(3));
      });
    });

    group('toString', () {
      test('returns rendered output', () {
        final comment = Comment()..text('Test comment');
        expect(comment.toString(), equals(comment.render()));
      });
    });

    group('fluent chaining', () {
      test('all methods return Comment for chaining', () {
        final comment = Comment();

        expect(comment.text('Text'), same(comment));
        expect(comment.prefix('//'), same(comment));
        expect(comment.style(Style()), same(comment));
      });
    });
  });
}
