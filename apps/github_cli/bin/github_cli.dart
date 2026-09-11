#!/usr/bin/env dart

import 'package:github_cli/src/app/app_io.dart';

Future<void> main(List<String> arguments) async {
  await GithubCliRunner().run(arguments);
}
