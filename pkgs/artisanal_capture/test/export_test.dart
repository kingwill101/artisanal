import 'dart:convert';
import 'dart:typed_data';

import 'package:artisanal_capture/rendering.dart';
import 'package:image/image.dart' as img;
import 'package:test/test.dart';

void main() {
  test('HTML embeds the exact PNG at native size with escaped labels', () {
    final pixels = img.Image(width: 3, height: 2)
      ..setPixelRgb(0, 0, 10, 20, 30);
    final bytes = Uint8List.fromList(img.encodePng(pixels));
    final capture = CaptureImage(
      png: bytes,
      width: 3,
      height: 2,
      columns: 1,
      rows: 1,
      diagnostics: ['Missing <glyph> & variant'],
    );
    final html = capture.toHtml(title: '</title><script>bad()</script>');
    expect(html, contains('data:image/png;base64,${base64Encode(bytes)}'));
    expect(html, contains('width="3" height="2"'));
    expect(html, isNot(contains('<script>')));
    expect(html, contains('&lt;glyph&gt; &amp; variant'));
    expect(html, contains('Content-Security-Policy'));
    expect(html, isNot(contains('https://')));
    bytes[0] = 0;
    expect(capture.png[0], 137);
    expect(() => capture.png[0] = 0, throwsUnsupportedError);
  });
}
