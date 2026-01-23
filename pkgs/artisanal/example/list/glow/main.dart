import 'package:artisanal/style.dart';

class Document {
  final String name;
  final String time;
  Document(this.name, this.time);

  @override
  String toString() {
    final faint = Style().dim();
    return '$name\n${faint.render(time)}';
  }
}

final docs = [
  Document('README.md', '2 minutes ago'),
  Document('Example.md', '1 hour ago'),
  Document('secrets.md', '1 week ago'),
];

const selected = 1;

void main() {
  final baseStyle = Style().marginBottom(1).marginLeft(1);
  final dimColor = AnsiColor(250);
  final highlightColor = BasicColor('#EE6FF8');

  final l = LipList()
      .enumerator((items, i) {
        if (i == selected) {
          return '│\n│';
        }
        return ' ';
      })
      .itemStyleFunc((items, i) {
        if (selected == i) {
          return baseStyle.copy().foreground(highlightColor);
        }
        return baseStyle.copy().foreground(dimColor);
      })
      .enumeratorStyleFunc((items, i) {
        if (selected == i) {
          return Style().foreground(highlightColor);
        }
        return Style().foreground(dimColor);
      });

  for (final d in docs) {
    l.item(d.toString());
  }

  print(l);
}
