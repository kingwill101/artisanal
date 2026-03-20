import 'dart:convert';
import 'dart:io';

void main() {
  stdout.writeln(
    jsonEncode(<String, Object?>{
      'protocol': 'artisanal.remote_surface.v1alpha1',
      'type': 'plugin.hello',
      'payload': <String, Object?>{
        'pluginId': 'echo-plugin',
        'pluginVersion': '0.0.1',
      },
    }),
  );

  stdin
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen(stdout.writeln);
}
