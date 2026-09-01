import 'package:test/test.dart';
import 'package:ultraviolet/rendering.dart' as rendering;
import 'package:ultraviolet/ultraviolet.dart' as broad;
import 'package:ultraviolet/uv.dart' as uv;

void main() {
  test('public rendering entrypoints expose image protocol encoders', () {
    expect(rendering.KittyImage, isA<Type>());
    expect(rendering.ITerm2Image, isA<Type>());
    expect(rendering.SixelImage, isA<Type>());

    expect(broad.KittyImage, same(rendering.KittyImage));
    expect(broad.ITerm2Image, same(rendering.ITerm2Image));
    expect(broad.SixelImage, same(rendering.SixelImage));

    expect(uv.KittyImage, same(rendering.KittyImage));
    expect(uv.ITerm2Image, same(rendering.ITerm2Image));
    expect(uv.SixelImage, same(rendering.SixelImage));
  });
}
