import 'package:artisanal/artisanal.dart';
import 'package:artisanal/tui.dart';
import 'package:artisanal/style.dart';
import 'package:test/test.dart';

void main() {
  group('DefinitionList (fluent builder)', () {
    group('basic construction', () {
      test('creates empty definition list', () {
        final list = DefinitionList();
        final output = list.render();
        expect(output, isEmpty);
      });

      test('creates list with single item', () {
        final list = DefinitionList()..item('Name', 'John');
        final output = list.render();
        expect(output, contains('Name'));
        expect(output, contains('John'));
      });

      test('creates list with multiple items', () {
        final list = DefinitionList()
          ..item('Name', 'John')
          ..item('Age', '30')
          ..item('City', 'NYC');
        final output = list.render();
        expect(output, contains('Name'));
        expect(output, contains('John'));
        expect(output, contains('Age'));
        expect(output, contains('30'));
        expect(output, contains('City'));
        expect(output, contains('NYC'));
      });

      test('creates list from map', () {
        final list = DefinitionList()
          ..items({'Key1': 'Value1', 'Key2': 'Value2', 'Key3': 'Value3'});
        final output = list.render();
        expect(output, contains('Key1'));
        expect(output, contains('Value1'));
        expect(output, contains('Key2'));
        expect(output, contains('Value2'));
        expect(output, contains('Key3'));
        expect(output, contains('Value3'));
      });
    });

    group('separator', () {
      test('uses colon separator by default', () {
        final list = DefinitionList()..item('Key', 'Value');
        final output = list.render();
        expect(output, contains(':'));
      });

      test('supports custom separator', () {
        final list = DefinitionList()
          ..item('Key', 'Value')
          ..separator('→');
        final output = list.render();
        expect(output, contains('→'));
        expect(output.contains(':'), isFalse);
      });

      test('supports equals separator', () {
        final list = DefinitionList()
          ..item('Key', 'Value')
          ..separator('=');
        final output = list.render();
        expect(output, contains('='));
      });

      test('supports no separator', () {
        final list = DefinitionList()
          ..item('Key', 'Value')
          ..separator('');
        final output = list.render();
        expect(output, contains('Key'));
        expect(output, contains('Value'));
      });
    });

    group('indentation', () {
      test('uses default indent of 2', () {
        final list = DefinitionList()..item('Key', 'Value');
        final output = list.render();
        expect(output.startsWith('  '), isTrue);
      });

      test('supports custom indent', () {
        final list = DefinitionList()
          ..item('Key', 'Value')
          ..indent(4);
        final output = list.render();
        expect(output.startsWith('    '), isTrue);
      });

      test('supports no indent', () {
        final list = DefinitionList()
          ..item('Key', 'Value')
          ..indent(0);
        final output = list.render();
        expect(output.startsWith('Key'), isTrue);
      });
    });

    group('gap', () {
      test('uses default gap of 1', () {
        final list = DefinitionList()..item('Key', 'Value');
        final output = list.render();
        expect(output, contains(': '));
      });

      test('supports custom gap', () {
        final list = DefinitionList()
          ..item('Key', 'Value')
          ..gap(3);
        final output = list.render();
        expect(output, contains(':   '));
      });

      test('supports no gap', () {
        final list = DefinitionList()
          ..item('Key', 'Value')
          ..gap(0);
        final output = list.render();
        expect(output, contains(':Value'));
      });
    });

    group('term alignment', () {
      test('aligns terms by default', () {
        final list = DefinitionList()
          ..item('Short', 'Value1')
          ..item('Much Longer Key', 'Value2');
        final output = list.render();
        final lines = output.split('\n');
        // Terms should be padded to same width
        expect(lines.length, equals(2));
      });

      test('can disable term alignment', () {
        final list = DefinitionList()
          ..item('Short', 'Value1')
          ..item('Much Longer Key', 'Value2')
          ..alignTerms(false);
        final output = list.render();
        expect(output, contains('Short'));
        expect(output, contains('Much Longer Key'));
      });
    });

    group('styling', () {
      test('applies term style', () {
        final list = DefinitionList()
          ..item('Key', 'Value')
          ..termStyle(Style().bold());
        final output = list.render();
        expect(output, contains('\x1B['));
        expect(output, contains('Key'));
      });

      test('applies description style', () {
        final list = DefinitionList()
          ..item('Key', 'Value')
          ..descriptionStyle(Style().italic());
        final output = list.render();
        expect(output, contains('\x1B['));
        expect(output, contains('Value'));
      });

      test('applies separator style', () {
        final list = DefinitionList()
          ..item('Key', 'Value')
          ..separatorStyle(Style().dim());
        final output = list.render();
        expect(output, contains('\x1B['));
      });

      test('applies style function', () {
        var callCount = 0;
        final list = DefinitionList()
          ..items({'A': '1', 'B': '2', 'C': '3'})
          ..styleFunc((term, desc, index, isTerm) {
            callCount++;
            if (isTerm && index == 1) {
              return Style().bold();
            }
            return null;
          });
        list.render();
        // Called for both term and description of each item
        expect(callCount, equals(6));
      });

      test('style function receives correct parameters', () {
        final receivedTerms = <String>[];
        final receivedDescs = <String>[];
        final receivedIndices = <int>[];
        final receivedIsTerms = <bool>[];

        final list = DefinitionList()
          ..items({'Key1': 'Val1', 'Key2': 'Val2'})
          ..styleFunc((term, desc, index, isTerm) {
            receivedTerms.add(term);
            receivedDescs.add(desc);
            receivedIndices.add(index);
            receivedIsTerms.add(isTerm);
            return null;
          });
        list.render();

        expect(receivedIndices, contains(0));
        expect(receivedIndices, contains(1));
        expect(receivedIsTerms, contains(true));
        expect(receivedIsTerms, contains(false));
      });
    });

    group('color profile', () {
      test('respects ASCII color profile', () {
        final list =
            DefinitionList(
                renderConfig: const RenderConfig(
                  colorProfile: ColorProfile.ascii,
                ),
              )
              ..item('Key', 'Value')
              ..termStyle(Style().bold().foreground(Colors.red));
        final output = list.render();
        expect(output.contains('\x1B['), isFalse);
      });

      test('respects trueColor profile', () {
        final list =
            DefinitionList(
                renderConfig: const RenderConfig(
                  colorProfile: ColorProfile.trueColor,
                ),
              )
              ..item('Key', 'Value')
              ..termStyle(Style().foreground(Colors.rgb(255, 100, 50)));
        final output = list.render();
        expect(output, contains('\x1B['));
      });

      test('respects dark background setting', () {
        final listLight =
            DefinitionList(
                renderConfig: const RenderConfig(
                  colorProfile: ColorProfile.trueColor,
                  hasDarkBackground: true,
                ),
              )
              ..item('Key', 'Value')
              ..termStyle(
                Style().foreground(
                  AdaptiveColor(light: Colors.black, dark: Colors.white),
                ),
              );
        final output1 = listLight.render();

        final listDark =
            DefinitionList(
                renderConfig: const RenderConfig(
                  colorProfile: ColorProfile.trueColor,
                  hasDarkBackground: false,
                ),
              )
              ..item('Key', 'Value')
              ..termStyle(
                Style().foreground(
                  AdaptiveColor(light: Colors.black, dark: Colors.white),
                ),
              );
        final output2 = listDark.render();

        expect(output1, isNot(equals(output2)));
      });
    });

    group('lineCount', () {
      test('returns 0 for empty list', () {
        final list = DefinitionList();
        expect(list.lineCount, equals(0));
      });

      test('returns correct count for single item', () {
        final list = DefinitionList()..item('Key', 'Value');
        expect(list.lineCount, equals(1));
      });

      test('returns correct count for multiple items', () {
        final list = DefinitionList()
          ..item('A', '1')
          ..item('B', '2')
          ..item('C', '3');
        expect(list.lineCount, equals(3));
      });
    });

    group('toString', () {
      test('returns rendered output', () {
        final list = DefinitionList()..item('Key', 'Value');
        expect(list.toString(), equals(list.render()));
      });
    });

    group('fluent chaining', () {
      test('all methods return DefinitionList for chaining', () {
        final list = DefinitionList();

        expect(list.item('Key', 'Value'), same(list));
        expect(list.items({'A': '1'}), same(list));
        expect(list.separator(':'), same(list));
        expect(list.indent(2), same(list));
        expect(list.gap(1), same(list));
        expect(list.alignTerms(true), same(list));
        expect(list.termStyle(Style()), same(list));
        expect(list.descriptionStyle(Style()), same(list));
        expect(list.separatorStyle(Style()), same(list));
        expect(list.styleFunc((_, _, _, _) => null), same(list));
      });
    });
  });

  group('GroupedDefinitionList', () {
    group('basic construction', () {
      test('creates empty grouped list', () {
        final list = GroupedDefinitionList();
        final output = list.render();
        expect(output, isEmpty);
      });

      test('creates list with single group', () {
        final list = GroupedDefinitionList()..group('Header', {'Key': 'Value'});
        final output = list.render();
        expect(output, contains('Header'));
        expect(output, contains('Key'));
        expect(output, contains('Value'));
      });

      test('creates list with multiple groups', () {
        final list = GroupedDefinitionList()
          ..group('Group 1', {'A': '1', 'B': '2'})
          ..group('Group 2', {'C': '3', 'D': '4'});
        final output = list.render();
        expect(output, contains('Group 1'));
        expect(output, contains('A'));
        expect(output, contains('Group 2'));
        expect(output, contains('C'));
      });
    });

    group('header styling', () {
      test('applies header style', () {
        final list = GroupedDefinitionList()
          ..group('Header', {'Key': 'Value'})
          ..headerStyle(Style().bold().underline());
        final output = list.render();
        expect(output, contains('\x1B['));
        expect(Ansi.stripAnsi(output), contains('Header'));
      });

      test('defaults to bold header', () {
        final list = GroupedDefinitionList()..group('Header', {'Key': 'Value'});
        final output = list.render();
        expect(output, contains('\x1B['));
      });
    });

    group('group spacing', () {
      test('uses default spacing of 1', () {
        final list = GroupedDefinitionList()
          ..group('Group 1', {'A': '1'})
          ..group('Group 2', {'B': '2'});
        final output = list.render();
        expect(output, contains('\n'));
      });

      test('supports custom group spacing', () {
        final list = GroupedDefinitionList()
          ..group('Group 1', {'A': '1'})
          ..group('Group 2', {'B': '2'})
          ..groupSpacing(2);
        final output = list.render();
        expect(output, contains('\n\n'));
      });
    });

    group('indentation', () {
      test('supports group indent', () {
        final list = GroupedDefinitionList()
          ..group('Header', {'Key': 'Value'})
          ..groupIndent(4);
        final output = list.render();
        final lines = output.split('\n');
        expect(lines[0].startsWith('    '), isTrue);
      });

      test('supports item indent', () {
        final list = GroupedDefinitionList()
          ..group('Header', {'Key': 'Value'})
          ..indent(6);
        final output = list.render();
        expect(output, contains('Key'));
      });
    });

    group('lineCount', () {
      test('returns 0 for empty list', () {
        final list = GroupedDefinitionList();
        expect(list.lineCount, equals(0));
      });

      test('returns correct count for single group', () {
        final list = GroupedDefinitionList()
          ..group('Header', {'A': '1', 'B': '2'});
        expect(list.lineCount, equals(3)); // 1 header + 2 items
      });

      test('returns correct count for multiple groups', () {
        final list = GroupedDefinitionList()
          ..group('Group 1', {'A': '1'})
          ..group('Group 2', {'B': '2'})
          ..groupSpacing(1);
        expect(
          list.lineCount,
          equals(5),
        ); // header + item + spacing + header + item
      });
    });

    group('fluent chaining', () {
      test('all methods return GroupedDefinitionList for chaining', () {
        final list = GroupedDefinitionList();

        expect(list.group('Header', {'Key': 'Value'}), same(list));
        expect(list.separator(':'), same(list));
        expect(list.indent(2), same(list));
        expect(list.groupIndent(0), same(list));
        expect(list.gap(1), same(list));
        expect(list.alignTerms(true), same(list));
        expect(list.alignAcrossGroups(false), same(list));
        expect(list.groupSpacing(1), same(list));
        expect(list.headerStyle(Style()), same(list));
        expect(list.termStyle(Style()), same(list));
        expect(list.descriptionStyle(Style()), same(list));
        expect(list.separatorStyle(Style()), same(list));
        expect(list.styleFunc((_, _, _, _) => null), same(list));
      });
    });
  });

  group('DefinitionListFactory', () {
    test('fromMap creates list from map', () {
      final list = DefinitionListFactory.fromMap({'A': '1', 'B': '2'});
      final output = list.render();
      expect(output, contains('A'));
      expect(output, contains('1'));
      expect(output, contains('B'));
      expect(output, contains('2'));
    });

    test('boldTerms creates list with bold terms', () {
      final list = DefinitionListFactory.boldTerms({'Key': 'Value'});
      final output = list.render();
      expect(output, contains('\x1B['));
      expect(output, contains('Key'));
    });

    test('coloredTerms creates list with colored terms', () {
      final list = DefinitionListFactory.coloredTerms({
        'Key': 'Value',
      }, Colors.blue);
      final output = list.render();
      expect(output, contains('\x1B['));
    });

    test('info creates info-styled list', () {
      final list = DefinitionListFactory.info({'Key': 'Value'});
      final output = list.render();
      expect(output, contains('\x1B['));
    });

    test('muted creates muted-styled list', () {
      final list = DefinitionListFactory.muted({'Key': 'Value'});
      final output = list.render();
      expect(output, contains('\x1B['));
    });

    test('compact creates list without alignment', () {
      final list = DefinitionListFactory.compact({
        'Short': 'V1',
        'Longer Key': 'V2',
      });
      final output = list.render();
      expect(output, contains('Short'));
      expect(output, contains('Longer Key'));
    });

    test('arrows creates list with arrow separator', () {
      final list = DefinitionListFactory.arrows({'Key': 'Value'});
      final output = list.render();
      expect(output, contains('→'));
    });

    test('equals creates list with equals separator', () {
      final list = DefinitionListFactory.equals({'Key': 'Value'});
      final output = list.render();
      expect(output, contains('='));
    });
  });

  group('DefinitionStyleFunc', () {
    test('typedef accepts correct signature', () {
      Style? func(String term, String desc, int index, bool isTerm) {
        return Style().bold();
      }

      expect(func('term', 'desc', 0, true), isA<Style>());
    });

    test('can return null', () {
      Style? func(String term, String desc, int index, bool isTerm) {
        return null;
      }

      expect(func('term', 'desc', 0, true), isNull);
    });
  });
}
