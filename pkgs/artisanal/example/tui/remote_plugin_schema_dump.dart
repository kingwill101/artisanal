// tui:allow-stdout
import 'dart:convert';
import 'dart:io' as io;

import 'package:artisanal/artisanal.dart' as plugins;

void main(List<String> args) {
  if (args.contains('--help') || args.contains('-h')) {
    _printUsage();
    return;
  }

  try {
    final schema = _selectSchema(args);
    final normalized = jsonDecode(jsonEncode(schema)) as Map<String, Object?>;
    io.stdout.writeln(const JsonEncoder.withIndent('  ').convert(normalized));
  } on FormatException catch (error) {
    io.stderr.writeln(error.message);
    io.exitCode = 64;
  } on ArgumentError catch (error) {
    io.stderr.writeln(error.message);
    io.exitCode = 64;
  }
}

dynamic _selectSchema(List<String> args) {
  final messageTypeValue = _valueFor(args, '--message-type');
  if (messageTypeValue != null) {
    return plugins.RemotePluginProtocolSchemas.schemaForType(
      plugins.RemotePluginMessageType.parse(messageTypeValue),
    );
  }

  if (args.contains('--manifest')) {
    return plugins.RemotePluginManifestSchemas.manifest;
  }

  if (args.contains('--manifest-placement')) {
    return plugins.RemotePluginManifestSchemas.placement;
  }

  if (args.contains('--built-in-services')) {
    return <String, Object?>{
      'services':
          plugins.RemotePluginGenericHostService.builtInServiceDescriptors(
            clipboardRead: true,
            clipboardWrite: true,
            openUrl: true,
            notify: true,
            filePicker: true,
          ).map((descriptor) => descriptor.toJson()).toList(growable: false),
    };
  }

  return plugins.RemotePluginProtocolSchemas.message;
}

String? _valueFor(List<String> args, String name) {
  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (arg == name && index + 1 < args.length) {
      return args[index + 1];
    }
    if (arg.startsWith('$name=')) {
      return arg.substring(name.length + 1);
    }
  }
  return null;
}

void _printUsage() {
  io.stdout.writeln('Dump remote plugin JSON schemas for host/plugin tooling.');
  io.stdout.writeln();
  io.stdout.writeln(
    'Usage: dart run pkgs/artisanal/example/tui/remote_plugin_schema_dump.dart '
    '[options]',
  );
  io.stdout.writeln();
  io.stdout.writeln('Options:');
  io.stdout.writeln(
    '  --message-type=<wire-name>  Dump one remote plugin message envelope schema.',
  );
  io.stdout.writeln('  --manifest                  Dump the manifest schema.');
  io.stdout.writeln(
    '  --manifest-placement        Dump the manifest placement schema.',
  );
  io.stdout.writeln(
    '  --built-in-services         Dump built-in generic host service descriptors.',
  );
  io.stdout.writeln('  --help                      Show this usage text.');
}
