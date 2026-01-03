/// Files tree example - ported from lipgloss/examples/tree/files
///
/// Demonstrates building a tree from filesystem directories.
library;
import 'dart:io';

import 'package:artisanal/artisanal.dart';
import 'package:artisanal/style.dart';
import 'package:artisanal/tui.dart';

void addBranches(Tree root, String path) {
  final dir = Directory(path);
  final items = dir.listSync();

  for (final item in items) {
    final name = item.path.split(Platform.pathSeparator).last;

    // Skip hidden files/directories
    if (name.startsWith('.')) continue;

    if (item is Directory) {
      final treeBranch = Tree().root(name);
      root.child(treeBranch);

      // Recurse
      addBranches(treeBranch, item.path);
    } else {
      root.child(name);
    }
  }
}

void main() {
  final enumeratorStyle = Style().foreground(AnsiColor(240)).paddingRight(1);
  final itemStyle = Style().foreground(AnsiColor(99)).bold().paddingRight(1);

  final pwd = Directory.current.path;

  final t = Tree()
      .root(pwd)
      .enumeratorStyle(enumeratorStyle)
      .indenterStyle(enumeratorStyle)
      .rootStyle(itemStyle)
      .itemStyle(itemStyle);

  addBranches(t, '.');

  print(t);
}
