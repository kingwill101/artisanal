import 'package:artisanal/src/uv/uv.dart';
import 'package:test/test.dart';


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
