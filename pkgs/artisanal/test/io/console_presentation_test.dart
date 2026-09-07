import 'package:artisanal/src/io/console_presentation.dart';
import 'package:artisanal/src/style/color.dart';
import 'package:artisanal/src/style/style.dart';
import 'package:artisanal/src/tui/bubbles/components/base.dart';
import 'package:test/test.dart';

final class _TextComponent extends DisplayComponent {
  const _TextComponent(this.content);

  final String content;

  @override
  String render() => content;
}

void main() {
  group('resolveConsoleComponentStyle', () {
    test('returns the themed style when no override is registered', () {
      final themed = Style().foreground(Colors.blue);

      expect(resolveConsoleComponentStyle(themed, null), same(themed));
    });

    test('preserves the theme while applying a semantic override', () {
      final themed = Style().foreground(Colors.blue);
      final resolved = resolveConsoleComponentStyle(themed, Style().bold());

      expect(resolved.render('value'), isNot(themed.render('value')));
      expect(themed.render('value'), isNot(resolved.render('value')));
    });
  });

  group('writeConsoleComponent', () {
    test('writes rendered output one line at a time', () {
      final lines = <String>[];

      writeConsoleComponent(const _TextComponent('one\ntwo'), lines.add);

      expect(lines, ['one', 'two']);
    });

    test('does not write an empty component', () {
      final lines = <String>[];

      writeConsoleComponent(const _TextComponent(''), lines.add);

      expect(lines, isEmpty);
    });
  });
}
