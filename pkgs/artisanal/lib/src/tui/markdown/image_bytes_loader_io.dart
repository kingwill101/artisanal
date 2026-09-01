import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:pure_svg/svg.dart' show SvgStringLoader, renderSvgToPng;

Future<Uint8List?> loadMarkdownImageBytes(String url) async {
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

    if (_isSvg(url, response.headers.value('content-type') ?? '')) {
      final svgContent = utf8.decode(bytes);
      final loader = SvgStringLoader(svgContent);
      final pngBytes = await renderSvgToPng(loader, width: 200, height: 200);
      return pngBytes.isEmpty ? null : pngBytes;
    }

    return bytes;
  } catch (_) {
    return null;
  }
}

bool _isSvg(String url, String contentType) {
  if (contentType.contains('svg')) return true;
  final lower = url.toLowerCase();
  return lower.endsWith('.svg') || lower.contains('.svg?');
}
