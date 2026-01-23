import 'package:artisanal/src/uv/uv.dart';
import 'package:test/test.dart';

// Upstream parity:
// - `third_party/ultraviolet/cursor_test.go`
// - `third_party/ultraviolet/cursor.go`

void main() {
  test('CursorShape.encode', () {
    expect(CursorShape.block.encode(blink: true), 1);
    expect(CursorShape.block.encode(blink: false), 2);
    expect(CursorShape.underline.encode(blink: true), 3);
    expect(CursorShape.underline.encode(blink: false), 4);
    expect(CursorShape.bar.encode(blink: true), 5);
    expect(CursorShape.bar.encode(blink: false), 6);
  });
}
