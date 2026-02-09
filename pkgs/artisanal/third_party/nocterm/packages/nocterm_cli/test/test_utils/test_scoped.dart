import 'dart:async';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:meta/meta.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nocterm_cli/src/deps/fs.dart';
import 'package:nocterm_cli/src/deps/log.dart';
import 'package:scoped_deps/scoped_deps.dart';
import 'package:test/test.dart';

/// A utility function to test Commands that depend on scoped dependencies.
@isTest
void testScoped(
  String description,
  FutureOr<void> Function() fn, {
  Object? skip,
  Logger Function()? logger,
  FileSystem Function()? fs,
}) {
  test(description, skip: skip, () async {
    final mockLogger = _MockLogger();

    final testProviders = {
      logProvider.overrideWith(() => logger?.call() ?? mockLogger),
      if (fs?.call() case final fs?)
        fsProvider.overrideWith(() => fs)
      else
        fsProvider.overrideWith(() => MemoryFileSystem.test()),
    };

    await runScoped(values: testProviders, () async {
      switch (fn) {
        case final Future<void> Function() fn:
          await fn();
        case final void Function() fn:
          fn();
      }
    });
  });
}

class _MockLogger extends Mock implements Logger {}
