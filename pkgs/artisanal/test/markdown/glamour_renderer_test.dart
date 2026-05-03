import 'package:artisanal/glamour.dart';
import 'package:artisanal/src/terminal/ansi.dart';
import 'package:test/test.dart';

void main() {
  group('Glamour markdown backend', () {
    test('renders raw inline HTML semantically', () {
      final result = renderStyle(
        'This is <strong>bold</strong>, <em>em</em>, '
        '<code>x</code>, and <a href="https://example.test">link</a>.',
        theme: GlamourTheme.ascii,
      );
      final plain = Ansi.stripAnsi(result);

      expect(plain, contains('This is bold, em, x, and link.'));
      expect(plain, isNot(contains('<strong>')));
      expect(result, contains('\x1b]8;;https://example.test\x1b\\'));
    });

    test('renders raw HTML lists without leaking tags', () {
      final result = renderStyle('''
<ul>
  <li>First item</li>
  <li><p>Second item</p></li>
</ul>
''', theme: GlamourTheme.ascii);
      final plain = Ansi.stripAnsi(result);

      expect(plain, contains('* First item'));
      expect(plain, contains('* Second item'));
      expect(plain, isNot(contains('<li>')));
    });

    test('renders GitHub task lists without bullet prefixes', () {
      final result = renderStyle('''
- [x] Done item
- [ ] Todo item
''', theme: GlamourTheme.ascii);
      final plain = Ansi.stripAnsi(result);

      expect(plain, contains('[x] Done item'));
      expect(plain, contains('[ ] Todo item'));
      expect(plain, isNot(contains('* [x]')));
      expect(plain, isNot(contains('* [ ]')));
    });

    test('renders raw HTML details as collapsed summaries by default', () {
      final result = renderStyle('''
<details>
<summary>Release notes</summary>
<p>Hidden release body</p>
</details>
''', theme: GlamourTheme.ascii);
      final plain = Ansi.stripAnsi(result);

      expect(plain, contains('\u25b8 Release notes'));
      expect(plain, isNot(contains('Hidden release body')));
      expect(plain, isNot(contains('<details>')));
    });

    test('renders open raw HTML details with body content', () {
      final result = renderStyle('''
<details open>
<summary>Release notes</summary>
<p>Visible release body</p>
</details>
''', theme: GlamourTheme.ascii);
      final plain = Ansi.stripAnsi(result);

      expect(plain, contains('\u25be Release notes'));
      expect(plain, contains('Visible release body'));
    });
  });
}
