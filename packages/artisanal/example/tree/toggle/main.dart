/// Toggle tree example - ported from lipgloss/examples/tree/toggle
///
/// Demonstrates a tree with collapsible directory-style nodes.
library;
import 'package:artisanal/artisanal.dart';
import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart';

// Style definitions
class Styles {
  late final Style base;
  late final Style block;
  late final Style enumerator;
  late final Style dir;
  late final Style toggle;
  late final Style file;

  Styles() {
    base = Style().background(AnsiColor(57)).foreground(AnsiColor(225));
    block = base.copy().padding(1, 3).margin(1, 3).width(40);
    enumerator = base.copy().foreground(AnsiColor(212)).paddingRight(1);
    dir = base.copy().inline();
    toggle = base.copy().foreground(AnsiColor(207)).paddingRight(1);
    file = base.copy();
  }
}

// Directory node representation
class Dir {
  final String name;
  final bool open;
  final Styles styles;

  Dir(this.name, this.open, this.styles);

  @override
  String toString() {
    final t = styles.toggle.render;
    final n = styles.dir.render;
    if (open) {
      return t('▼') + n(name);
    }
    return t('▶') + n(name);
  }
}

// File node representation
class FileNode {
  final String name;
  final Styles styles;

  FileNode(this.name, this.styles);

  @override
  String toString() => styles.file.render(name);
}

void main() {
  final s = Styles();

  final t = Tree()
      .root(Dir('~/charm', true, s).toString())
      .enumerator(TreeEnumerator.rounded)
      .enumeratorStyle(s.enumerator)
      .indenterStyle(s.enumerator)
      .children([
        Dir('ayman', false, s).toString(),
        Tree()
            .root(Dir('bash', true, s).toString())
            .child(
              Tree().root(Dir('tools', true, s).toString()).children([
                FileNode('zsh', s).toString(),
                FileNode('doom-emacs', s).toString(),
              ]),
            ),
        Tree()
            .root(Dir('carlos', true, s).toString())
            .child(
              Tree().root(Dir('emotes', true, s).toString()).children([
                FileNode('chefkiss.png', s).toString(),
                FileNode('kekw.png', s).toString(),
              ]),
            ),
        Dir('maas', false, s).toString(),
      ]);

  print(s.block.render(t.render()));
}
