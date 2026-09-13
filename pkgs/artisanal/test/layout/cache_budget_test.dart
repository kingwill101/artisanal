import 'package:artisanal/artisanal.dart';
import 'package:test/test.dart';

import 'package:artisanal/src/layout/bounded_string_int_cache.dart';

void main() {
  test('layout sizing remains correct for oversized keys', () {
    final content = 'a' * (256 * 1024 + 1);

    expect(Layout.visibleLength(content), content.length);
    expect(Layout.getWidth(content), content.length);
    expect(Layout.getHeight(content), 1);
  });

  test('oversized keys are skipped without retaining bytes', () {
    final cache = BoundedStringIntCache(
      maxEntries: 4096,
      maxKeyBytes: 256 * 1024,
    );
    cache['a' * (256 * 1024 + 1)] = 1;

    expect(cache.entryCount, 0);
    expect(cache.retainedKeyBytes, 0);
  });

  test('evicts oldest keys FIFO and stays within both budgets', () {
    final cache = BoundedStringIntCache(
      maxEntries: 4096,
      maxKeyBytes: 256 * 1024,
    );
    final keys = List<String>.generate(160, (i) => 'x' * 2048 + i.toString());
    for (var i = 0; i < keys.length; i++) {
      cache[keys[i]] = i;
    }
    final retainedBytes = cache.retainedKeyBytes;

    expect(cache[keys.first], isNull);
    expect(cache.entryCount, lessThanOrEqualTo(4096));
    expect(retainedBytes, lessThanOrEqualTo(256 * 1024));
    expect(
      retainedBytes,
      cache.keys.fold<int>(0, (sum, key) => sum + key.length * 2),
    );
  });

  test('enforces the entry cap independently of the byte budget', () {
    final cache = BoundedStringIntCache(maxEntries: 3, maxKeyBytes: 256 * 1024);
    for (var i = 0; i < 4; i++) {
      cache['key-$i'] = i;
    }

    expect(cache['key-0'], isNull);
    expect(cache.entryCount, 3);
  });
}
