/// Simple tree example - demonstrates basic tree structure with nested children.
///
/// This is a port of the Go lipgloss example: examples/tree/simple/main.go
library;

import 'package:artisanal/tui.dart';

void main() {
  final t = Tree()
      .root('.')
      .child('macOS')
      .child(
        Tree()
            .root('Linux')
            .child('NixOS')
            .child('Arch Linux (btw)')
            .child('Void Linux'),
      )
      .child(Tree().root('BSD').child('FreeBSD').child('OpenBSD'));

  print(t.render());
}
