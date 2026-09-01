import 'package:image/image.dart' as img;

String environmentValue(String name) => '';

bool hasEnvironmentValue(String name) => false;

Future<(img.Image image, String mimeType)?> downloadImage(String url) async =>
    null;

Future<img.Image?> svgToImage(
  String svgContent, {
  required int width,
  required int height,
}) async => null;
