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
