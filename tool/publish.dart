import 'dart:io';
import 'package:path/path.dart' as p;

/// Packages to publish in order of dependency
final packages = [
  'packages/artisanal',
  'packages/ormed',
  'packages/driver_tests',
  'packages/ormed_sqlite',
  'packages/ormed_mysql',
  'packages/ormed_postgres',
  'packages/ormed_cli',
];

Future<void> main(List<String> args) async {
  final isDryRun = !args.contains('--force');

  print('--- ORMed Release Automation ---');
  if (isDryRun) {
    print('[MODE] Dry Run (use --force to actually publish)');
  } else {
    print('[MODE] ACTUAL PUBLISH');
  }

  try {
    for (final pkgPath in packages) {
      await publishPackage(pkgPath, isDryRun);
    }
    print('\n[SUCCESS] All packages processed successfully!');
  } catch (e) {
    print('\n[FAILURE] Publishing interrupted: $e');
    exit(1);
  }
}

Future<void> publishPackage(String pkgPath, bool isDryRun) async {
  final fullPath = p.join(Directory.current.path, pkgPath);
  final pubspecFile = File(p.join(fullPath, 'pubspec.yaml'));

  if (!pubspecFile.existsSync()) {
    throw Exception('pubspec.yaml not found in $pkgPath');
  }

  final name = p.basename(pkgPath);
  print('\n--> Processing $name ($pkgPath)...');

  // 1. Dry run first (always)
  print('Running dry-run check...');
  final dryRunResult = await Process.run('dart', [
    'pub',
    'publish',
    '--dry-run',
  ], workingDirectory: fullPath);

  if (dryRunResult.exitCode != 0) {
    print('Dry-run failed for $name:');
    print(dryRunResult.stdout);
    print(dryRunResult.stderr);
    throw Exception('Dry-run failed for $name');
  }
  print('✓ Dry-run passed.');

  if (!isDryRun) {
    print('Publishing $name to pub.dev...');
    // We use inheritStdio to allow the user to see progress and handle any
    // unexpected prompts, though --force should skip them.
    final process = await Process.start(
      'dart',
      ['pub', 'publish', '--force'],
      workingDirectory: fullPath,
      mode: ProcessStartMode.inheritStdio,
    );

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw Exception('Failed to publish $name (exit code $exitCode)');
    }
    print('✓ Published $name.');
  }
}
