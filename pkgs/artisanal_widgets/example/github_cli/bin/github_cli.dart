#!/usr/bin/env dart

import 'package:github_cli/github_cli.dart';

Future<void> main(List<String> arguments) async {
  await GithubCliRunner().run(arguments);
}
