/// Simple list example - demonstrates basic nested lists with different enumerators.
///
/// This is a port of the Go lipgloss example: examples/list/simple/main.go
library;

import 'package:artisanal/style.dart';

void main() {
  final l = LipList.create([
    'A',
    'B',
    'C',
    LipList.create(['D', 'E', 'F']).enumerator(ListEnumerators.roman),
    'G',
  ]);

  print(l);
}
