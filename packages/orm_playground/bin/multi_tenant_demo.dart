/// Demonstrates querying multiple tenants using the DataSource API.
library;

import 'dart:io';

import 'package:artisanal/artisanal.dart';
import 'package:orm_playground/src/database/seeders.dart' as playground_seeders;
import 'package:ormed/ormed.dart';
import 'package:orm_playground/orm_playground.dart';

/// Shared CLI IO for styled output.
final io = Console(
  renderer: TerminalRenderer(),
  out: stdout.writeln,
  err: stderr.writeln,
  stdout: stdout,
  stdin: stdin,
);

Future<void> main(List<String> arguments) async {
  final database = PlaygroundDatabase();
  final logSql = arguments.contains('--sql');
  final animate = !arguments.contains('--no-animate');

  io.title('Multi-Tenant Demo');
  io.newLine();

  // Get available tenants from configuration
  final tenants = database.tenantNames.toList();
  io.twoColumnDetail('Available tenants', tenants.join(', '));
  io.newLine();

  // Store data sources for each tenant
  final dataSources = <String, DataSource>{};

  try {
    // Initialize and prepare each tenant
    io.section('Initializing Tenants');
    for (final tenant in tenants) {
      await io.task(
        'Connecting to "$tenant"',
        run: () async {
          final ds = await database.dataSource(tenant: tenant);
          dataSources[tenant] = ds;
          if (animate) await Future.delayed(Duration(milliseconds: 150));
          return TaskResult.success;
        },
      );

      await _prepareTenant(
        dataSources[tenant]!,
        tenant,
        logSql: logSql,
        animate: animate,
      );
    }

    io.newLine();
    io.section('Tenant Summary');

    // Summarize each tenant
    for (final tenant in tenants) {
      final ds = dataSources[tenant]!;
      await _summarizeTenant(tenant, ds, animate: animate);
    }

    // Demonstrate tenant isolation
    io.newLine();
    io.section('Tenant Isolation Demo');
    await _demonstrateTenantIsolation(dataSources, animate: animate);

    io.newLine();
    io.success('Multi-tenant demo completed successfully.');
  } finally {
    await database.dispose();
  }
}

/// Seeds [tenant] if it has no users and optionally logs SQL.
Future<void> _prepareTenant(
  DataSource ds,
  String tenant, {
  required bool logSql,
  bool animate = true,
}) async {
  final hasData = await _hasUsers(ds);

  if (!hasData) {
    await io.task(
      'Seeding "$tenant"',
      run: () async {
        await playground_seeders.runProjectSeeds(ds.connection);
        if (animate) await Future.delayed(Duration(milliseconds: 200));
        return TaskResult.success;
      },
    );
  } else {
    io.writeln(
      '${io.style.foreground(Colors.muted).render('○')} Tenant ${io.style.bold().render(tenant)} already has data',
    );
  }

  if (logSql) {
    ds.beforeExecuting((statement) {
      io.writeln(
        io.style
            .foreground(Colors.muted)
            .render('[Tenant $tenant SQL] ${statement.sqlWithBindings}'),
      );
    });
  }
}

Future<bool> _hasUsers(DataSource ds) async {
  final users = await ds.query<User>().limit(1).get();
  return users.isNotEmpty;
}

/// Prints per-tenant user counts using the DataSource API.
Future<void> _summarizeTenant(
  String tenant,
  DataSource ds, {
  bool animate = true,
}) async {
  await io.components.spin(
    'Querying tenant "$tenant"',
    run: () async {
      final users = await ds.query<User>().orderBy('id').get();
      final emails = users.map((user) => user.email).join(', ');
      final postCount = await ds.query<Post>().count();

      io.writeln(io.style.emphasize('Tenant "$tenant"'));
      io.twoColumnDetail(
        '  Users',
        '${users.length} (${emails.isEmpty ? 'none' : emails})',
      );
      io.twoColumnDetail('  Posts', '$postCount');
      if (animate) await Future.delayed(Duration(milliseconds: 100));
    },
  );
}

/// Demonstrates that each DataSource operates independently.
Future<void> _demonstrateTenantIsolation(
  Map<String, DataSource> dataSources, {
  bool animate = true,
}) async {
  final defaultDs = dataSources['default'];
  final analyticsDs = dataSources['analytics'];

  if (defaultDs == null || analyticsDs == null) {
    io.warning('Not all tenants available for isolation demo.');
    return;
  }

  // Count users in each tenant
  await io.task(
    'Counting users in each tenant',
    run: () async {
      final defaultUserCount = await defaultDs.query<User>().count();
      final analyticsUserCount = await analyticsDs.query<User>().count();

      io.twoColumnDetail('  Default tenant users', '$defaultUserCount');
      io.twoColumnDetail('  Analytics tenant users', '$analyticsUserCount');
      if (animate) await Future.delayed(Duration(milliseconds: 100));
      return TaskResult.success;
    },
  );

  // Demonstrate using repo<T>() and query<T>() on different tenants
  io.newLine();
  io.info('Latest user from each tenant:');

  await io.task(
    'Querying latest user (default)',
    run: () async {
      final latestDefault = await defaultDs
          .query<User>()
          .orderBy('id', descending: true)
          .firstOrNull();
      if (latestDefault != null) {
        io.twoColumnDetail('  Default', latestDefault.email);
      }
      if (animate) await Future.delayed(Duration(milliseconds: 100));
      return TaskResult.success;
    },
  );

  await io.task(
    'Querying latest user (analytics)',
    run: () async {
      final latestAnalytics = await analyticsDs
          .query<User>()
          .orderBy('id', descending: true)
          .firstOrNull();
      if (latestAnalytics != null) {
        io.twoColumnDetail('  Analytics', latestAnalytics.email);
      }
      if (animate) await Future.delayed(Duration(milliseconds: 100));
      return TaskResult.success;
    },
  );

  // Demonstrate transaction on specific tenant
  io.newLine();
  await io.task(
    'Running transaction on default tenant',
    run: () async {
      final now = DateTime.now().toUtc();
      final tempTagName = 'multi-tenant-demo-${now.microsecondsSinceEpoch}';

      await defaultDs.transaction(() async {
        await defaultDs.repo<Tag>().insert(
          Tag(name: tempTagName, createdAt: now, updatedAt: now),
        );

        // Verify it doesn't exist in analytics tenant
        final existsInAnalytics = await analyticsDs
            .query<Tag>()
            .whereEquals('name', tempTagName)
            .exists();
        io.twoColumnDetail(
          '  Tag exists in analytics',
          existsInAnalytics ? 'yes' : 'no',
        );

        // Clean up
        await defaultDs
            .query<Tag>()
            .whereEquals('name', tempTagName)
            .forceDelete();
      });
      if (animate) await Future.delayed(Duration(milliseconds: 100));
      return TaskResult.success;
    },
  );

  io.success('Transaction completed - tenants remain isolated.');
}
