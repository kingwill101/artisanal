import 'dart:io';

import 'package:artisanal_capture/cli.dart';

Future<void> main(List<String> arguments) async {
  try {
    await CaptureCommandRunner().run(arguments);
  } on FileSystemException catch (error) {
    stderr.writeln('Capture failed: ${error.message} (${error.path ?? ''})');
    exitCode = 74;
  } on StateError catch (error) {
    stderr.writeln('Capture failed: ${error.message}');
    exitCode = 1;
  } on UnsupportedError catch (error) {
    stderr.writeln('Capture failed: ${error.message}');
    exitCode = 1;
  } on Exception catch (error) {
    stderr.writeln('Capture failed: $error');
    exitCode = 1;
  }
}
