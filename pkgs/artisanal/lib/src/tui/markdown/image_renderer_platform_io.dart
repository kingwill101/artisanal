import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:pure_svg/svg.dart' show SvgStringLoader, renderSvgToPng;

String environmentValue(String name) => Platform.environment[name] ?? '';

bool hasEnvironmentValue(String name) => Platform.environment.containsKey(name);

Future<(img.Image image, String mimeType)?> downloadImage(String url) async {
  try {
    final uri = Uri.parse(url);
    final client = HttpClient();
    final request = await client.getUrl(uri);
    final response = await request.close();

    if (response.statusCode != 200) {
      client.close();
      return null;
    }

    final bytes = await response.fold<Uint8List>(Uint8List(0), (prev, chunk) {
      final combined = Uint8List(prev.length + chunk.length);
      combined.setRange(0, prev.length, prev);
      combined.setRange(prev.length, combined.length, chunk);
      return combined;
    });
    client.close();

    final mimeType = response.headers.value('content-type') ?? '';
    if (mimeType.contains('svg') || url.toLowerCase().endsWith('.svg')) {
      final svgContent = utf8.decode(bytes);
      final loader = SvgStringLoader(svgContent);
      final pngBytes = await renderSvgToPng(loader, width: 200, height: 200);
      if (pngBytes.isEmpty) return null;
      final image = img.decodeImage(pngBytes);
      if (image == null) return null;
      return (image, mimeType);
    }

    final image = img.decodeImage(bytes);
    if (image == null) return null;
    return (image, mimeType);
  } catch (_) {
    return null;
  }
}

Future<img.Image?> svgToImage(
  String svgContent, {
  required int width,
  required int height,
}) async {
  try {
    final loader = SvgStringLoader(svgContent);
    final pngBytes = await renderSvgToPng(loader, width: width, height: height);
    if (pngBytes.isEmpty) return null;
    return img.decodeImage(pngBytes);
  } catch (_) {
    return null;
  }
}
