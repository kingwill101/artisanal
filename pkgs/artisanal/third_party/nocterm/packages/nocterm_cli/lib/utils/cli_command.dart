import 'dart:async';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';

abstract class CliCommand extends Command<int> {
  CliCommand();

  @override
  ArgResults get argResults => switch (super.argResults) {
        final results? => results,
        null => throw Exception('argResults is null'),
      };

  @override
  String get description;

  @override
  String get name;

  @override
  Future<int> run() async {
    return 0;
  }
}
