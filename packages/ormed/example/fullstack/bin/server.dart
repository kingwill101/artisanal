import 'dart:io';

import 'package:ormed_fullstack_example/src/server/server.dart';

Future<void> main(List<String> args) async {
  final host = InternetAddress.anyIPv4.address;
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  await runServer(host: host, port: port);
}
