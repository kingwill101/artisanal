import 'dart:io';

import 'package:artisanal/artisanal.dart';
import 'package:orm_playground/orm_playground.dart';
import 'package:orm_playground/src/database/seeders.dart' as playground_seeders;
import 'package:ormed/ormed.dart';

/// Shared CLI IO for styled output.
final io = Console(
  renderer: TerminalRenderer(),
  out: stdout.writeln,
  err: stderr.writeln,
  stdout: stdout,
  stdin: stdin,
);

Future<void> main(List<String> arguments) async {
  final logSql =
      arguments.contains('--sql') ||
      Platform.environment['PLAYGROUND_LOG_SQL'] == 'true';
  final seedOverrides = _extractSeedArguments(arguments);
  final animate = !arguments.contains('--no-animate');

  io.title('ORM Playground');
  io.newLine();

  // Create the playground database helper
  final database = PlaygroundDatabase();
  // Get the DataSource for the default tenant
  DataSource? ds;

  await io.task(
    'Connecting to database',
    run: () async {
      ds = await database.dataSource();
      if (animate) await Future.delayed(Duration(milliseconds: 200));
      return TaskResult.success;
    },
  );

  try {
    // Check if schema is ready
    final schemaReady = await io.components.spin(
      'Checking schema',
      run: () async {
        if (animate) await Future.delayed(Duration(milliseconds: 300));
        return await _schemaReady(ds!);
      },
    );

    if (!schemaReady) {
      io.error('Schema not ready!');
      io.note(
        'Run the ORM CLI to apply migrations:\n'
        '  ormed migrate',
      );
      return;
    }

    // Seed the database with animation
    io.newLine();
    io.section('Seeding Database');
    await _animatedSeed(ds!, seedOverrides, animate: animate);

    // Enable SQL logging if requested
    if (logSql) {
      ds!.beforeExecuting((statement) {
        io.writeln(
          io.style
              .foreground(Colors.muted)
              .render('[SQL] ${statement.sqlWithBindings}'),
        );
      });
    }

    // Run the showcases with animation
    await _printPostSummaries(ds!, animate: animate);
    await _runQueryBuilderShowcase(ds!, animate: animate);
    await _runTableHelpers(ds!, animate: animate);
    await _runPretendPreview(ds!, animate: animate);
    await _runModelCrudShowcase(ds!, animate: animate);
    await _runRelationQueryShowcase(ds!);
    await _runPaginationShowcase(ds!);
    await _runChunkingShowcase(ds!);
    await _runTransactionShowcase(ds!);

    io.newLine();
    io.success('All showcases completed successfully!');
  } finally {
    await database.dispose();
  }
}

/// Animated seeding with step-by-step progress.
Future<void> _animatedSeed(
  DataSource ds,
  List<String> seedOverrides, {
  bool animate = true,
}) async {
  // Check what needs seeding
  final hasUsers = await ds.query<User>().exists();
  final hasPosts = await ds.query<Post>().exists();
  final hasTags = await ds.query<Tag>().exists();

  if (hasUsers && hasPosts && hasTags && seedOverrides.isEmpty) {
    io.info('Database already seeded.');
    return;
  }

  await io.task(
    'Creating users',
    run: () async {
      if (!hasUsers || seedOverrides.contains('users')) {
        await playground_seeders.runProjectSeeds(
          ds.connection,
          names: ['users'],
        );
        if (animate) await Future.delayed(Duration(milliseconds: 150));
      }
      return TaskResult.success;
    },
  );

  await io.task(
    'Creating tags',
    run: () async {
      if (!hasTags || seedOverrides.contains('tags')) {
        await playground_seeders.runProjectSeeds(ds.connection, names: ['tags']);
        if (animate) await Future.delayed(Duration(milliseconds: 100));
      }
      return TaskResult.success;
    },
  );

  await io.task(
    'Creating posts',
    run: () async {
      if (!hasPosts || seedOverrides.contains('posts')) {
        await playground_seeders.runProjectSeeds(
          ds.connection,
          names: ['posts'],
        );
        if (animate) await Future.delayed(Duration(milliseconds: 150));
      }
      return TaskResult.success;
    },
  );

  await io.task(
    'Creating comments',
    run: () async {
      await playground_seeders.runProjectSeeds(
        ds.connection,
        names: ['comments'],
      );
      if (animate) await Future.delayed(Duration(milliseconds: 100));
      return TaskResult.success;
    },
  );

  io.success('Seeding complete.');
}

List<String> _extractSeedArguments(List<String> args) {
  final seeds = <String>[];
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--seed') {
      if (i + 1 < args.length) {
        seeds.addAll(
          args[i + 1]
              .split(',')
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty),
        );
        i++;
      }
    } else if (arg.startsWith('--seed=')) {
      final value = arg.substring('--seed='.length);
      seeds.addAll(
        value
            .split(',')
            .map((entry) => entry.trim())
            .where((entry) => entry.isNotEmpty),
      );
    }
  }
  return seeds;
}

Future<bool> _schemaReady(DataSource ds) async {
  final driver = ds.connection.driver;
  if (driver is! SchemaDriver) {
    return false;
  }
  final schemaDriver = driver as SchemaDriver;
  final inspector = SchemaInspector(schemaDriver);
  final hasUsers = await inspector.hasTable('users');
  final hasPosts = await inspector.hasTable('posts');
  return hasUsers && hasPosts;
}

Future<void> _printPostSummaries(DataSource ds, {bool animate = true}) async {
  io.newLine();
  io.section('Latest Posts');

  final rows = await io.components.spin(
    'Fetching posts with relations',
    run: () async {
      final query = ds
          .query<Post>()
          .withRelation('author')
          .withRelation('tags')
          .withRelation('comments')
          .withCount('comments', alias: 'comments_count')
          .orderBy('published_at', descending: true);
      if (animate) await Future.delayed(Duration(milliseconds: 200));
      return await query.rows();
    },
  );

  if (rows.isEmpty) {
    io.warning('No posts found. Create one via the ORM CLI to continue.');
    return;
  }

  for (final row in rows) {
    final post = row.model;
    final tagList = post.tags.map((tag) => tag.name).join(', ');
    final commentCount =
        (row.row['comments_count'] as int?) ??
        row.relationList<Comment>('comments').length;
    io.writeln(
      '${io.style.foreground(Colors.success).render('•')} ${io.style.bold().render(post.title)} '
      'by ${post.author?.name ?? 'Unknown'} '
      '${io.style.foreground(Colors.muted).render('($commentCount comments, tags: ${tagList.isEmpty ? 'none' : tagList})')}',
    );
    if (animate) await Future.delayed(Duration(milliseconds: 80));
  }
}

Future<void> _runQueryBuilderShowcase(
  DataSource ds, {
  bool animate = true,
}) async {
  io.newLine();
  io.section('Query Builder Helpers');

  // Using query<T>() from DataSource
  await io.task(
    'Fetching posts with comment counts',
    run: () async {
      final rows = await ds
          .query<Post>()
          .withCount('comments', alias: 'comments_count')
          .orderBy('published_at', descending: true)
          .limit(3)
          .get();
      if (animate) await Future.delayed(Duration(milliseconds: 100));
      io.twoColumnDetail('  Found', '${rows.length} posts');
      return TaskResult.success;
    },
  );

  // Using table() for ad-hoc queries
  await io.task(
    'Querying active user IDs',
    run: () async {
      final activeUserIds = await ds
          .table('users')
          .whereEquals('active', true)
          .pluck<int>('id');
      if (animate) await Future.delayed(Duration(milliseconds: 100));
      io.twoColumnDetail('  Active IDs', activeUserIds.join(', '));
      return TaskResult.success;
    },
  );

  await io.task(
    'Finding latest comment',
    run: () async {
      final latestComment = await ds
          .query<Comment>()
          .orderBy('created_at', descending: true)
          .firstOrNull();
      if (animate) await Future.delayed(Duration(milliseconds: 100));
      io.twoColumnDetail('  Latest', latestComment?.body ?? 'none yet');
      return TaskResult.success;
    },
  );
}

Future<void> _runTableHelpers(DataSource ds, {bool animate = true}) async {
  io.newLine();
  io.section('Ad-hoc Table Demo');

  // Using DataSource.table() for joins
  final pivotPreview = await io.components.spin(
    'Joining post_tags with tags',
    run: () async {
      final result = await ds
          .table('post_tags')
          .join('tags', 'tags.id', '=', 'post_tags.tag_id')
          .selectRaw('post_tags.post_id', alias: 'post_id')
          .selectRaw('tags.name', alias: 'tag_name')
          .orderBy('post_id')
          .get();
      if (animate) await Future.delayed(Duration(milliseconds: 150));
      return result;
    },
  );

  if (pivotPreview.isEmpty) {
    io.info('No post-tag associations found.');
  } else {
    io.info('Post-tag associations:');
    for (final row in pivotPreview) {
      io.twoColumnDetail('  Post ${row['post_id']}', '${row['tag_name']}');
      if (animate) await Future.delayed(Duration(milliseconds: 50));
    }
  }
}

Future<void> _runPretendPreview(DataSource ds, {bool animate = true}) async {
  io.newLine();
  io.section('Pretend Mode Preview');

  // Using DataSource.pretend() to capture SQL without executing
  final statements = await io.components.spin(
    'Capturing SQL (without executing)',
    run: () async {
      final result = await ds.pretend(() async {
        await ds.repo<User>().insert(
          User(
            email:
                'pretend-${DateTime.now().millisecondsSinceEpoch}@example.com',
            name: 'Preview User',
            active: false,
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          ),
        );
      });
      if (animate) await Future.delayed(Duration(milliseconds: 150));
      return result;
    },
  );

  io.info('SQL that would be executed:');
  for (final entry in statements) {
    io.writeln(io.style.foreground(Colors.muted).render('  ${entry.sql}'));
    if (animate) await Future.delayed(Duration(milliseconds: 50));
  }
}

Future<void> _runModelCrudShowcase(DataSource ds, {bool animate = true}) async {
  io.newLine();
  io.section('Repository Helpers');

  // Using DataSource.repo<T>() for CRUD operations
  final tagRepo = ds.repo<Tag>();
  final now = DateTime.now().toUtc();
  final demoName = 'playground-demo-${now.microsecondsSinceEpoch}';

  Tag? inserted;
  await io.task(
    'Inserting demo tag',
    run: () async {
      await tagRepo.insert(Tag(name: demoName, createdAt: now, updatedAt: now));
      inserted = await ds
          .query<Tag>()
          .whereEquals('name', demoName)
          .firstOrFail();
      if (animate) await Future.delayed(Duration(milliseconds: 100));
      return TaskResult.success;
    },
  );
  io.twoColumnDetail('  Tag ID', '${inserted!.id}');
  io.twoColumnDetail('  Name', demoName);

  Tag? renamed;
  await io.task(
    'Renaming demo tag',
    run: () async {
      renamed = Tag(
        id: inserted!.id,
        name: '$demoName-updated',
        createdAt: inserted!.createdAt,
        updatedAt: DateTime.now().toUtc(),
      );
      await tagRepo.updateMany([renamed!]);
      if (animate) await Future.delayed(Duration(milliseconds: 100));
      return TaskResult.success;
    },
  );
  io.twoColumnDetail('  New name', renamed!.name);

  await io.task(
    'Deleting demo tag',
    run: () async {
      await tagRepo.deleteByKeys([
        {'id': renamed!.id},
      ]);
      if (animate) await Future.delayed(Duration(milliseconds: 100));
      return TaskResult.success;
    },
  );
}

Future<void> _runRelationQueryShowcase(DataSource ds) async {
  io.newLine();
  io.section('Relation-aware Queries');

  final relationRows = await ds
      .query<Post>()
      .withCount('comments', alias: 'comments_count')
      .withExists('comments', alias: 'has_comments')
      .whereHas('tags', (builder) => builder.whereIn('name', ['dart', 'orm']))
      .orderByRelation('comments', descending: true)
      .limit(2)
      .rows();

  for (final row in relationRows) {
    final post = row.model;
    final count = row.row['comments_count'];
    final hasComments = row.row['has_comments'];
    io.writeln(
      '${io.style.foreground(Colors.success).render('•')} ${io.style.bold().render(post.title)} → $count comments (exists: $hasComments)',
    );
  }

  final eager = await ds
      .query<Post>()
      .withRelation('comments')
      .withRelation('tags')
      .limit(1)
      .rows();

  if (eager.isNotEmpty) {
    final row = eager.first;
    final commentBodies = row
        .relationList<Comment>('comments')
        .map((comment) => comment.body)
        .toList();
    final tagNames = row
        .relationList<Tag>('tags')
        .map((tag) => tag.name)
        .toList();
    io.info('Eager loaded "${row.model.title}":');
    io.twoColumnDetail('  Tags', tagNames.join(', '));
    io.twoColumnDetail('  Comments', commentBodies.join(', '));
  }
}

Future<void> _runPaginationShowcase(DataSource ds) async {
  io.newLine();
  io.section('Pagination Helpers');

  final page = await ds
      .query<Post>()
      .orderBy('id')
      .paginate(perPage: 2, page: 1);
  io.twoColumnDetail(
    'paginate()',
    'items=${page.items.length}, total=${page.total}, hasMore=${page.hasMorePages}',
  );

  final simple = await ds
      .query<Post>()
      .orderBy('id')
      .simplePaginate(perPage: 2, page: 1);
  io.twoColumnDetail(
    'simplePaginate()',
    'items=${simple.items.length}, hasMore=${simple.hasMorePages}',
  );

  final cursor = await ds
      .query<Post>()
      .orderBy('id')
      .cursorPaginate(perPage: 1);
  io.twoColumnDetail(
    'cursorPaginate()',
    'nextCursor=${cursor.nextCursor}, hasMore=${cursor.hasMore}',
  );
}

Future<void> _runChunkingShowcase(DataSource ds) async {
  io.newLine();
  io.section('Chunk + chunkById Demos');

  await ds.query<Post>().orderBy('id').chunk(2, (rows) {
    final ids = rows.map((row) => row.model.id).toList();
    io.twoColumnDetail('chunk()', 'processed post IDs $ids');
    return true;
  });

  await ds.query<Comment>().chunkById(1, (rows) {
    final bodies = rows.map((row) => row.model.body).toList();
    io.twoColumnDetail('chunkById()', 'latest comments $bodies');
    return true;
  });
}

Future<void> _runTransactionShowcase(DataSource ds) async {
  io.newLine();
  io.section('Transaction Demo');

  // Using DataSource.transaction() for atomic operations
  final now = DateTime.now().toUtc();
  final tempTagName = 'tx-demo-${now.microsecondsSinceEpoch}';

  try {
    await ds.transaction(() async {
      // Create a tag inside transaction
      await ds.repo<Tag>().insert(
        Tag(name: tempTagName, createdAt: now, updatedAt: now),
      );

      // Verify it exists
      final exists = await ds
          .query<Tag>()
          .whereEquals('name', tempTagName)
          .exists();
      io.twoColumnDetail('Tag created in transaction', exists ? 'yes' : 'no');

      // Clean up inside same transaction
      await ds.query<Tag>().whereEquals('name', tempTagName).forceDelete();
      io.writeln(
        '${io.style.foreground(Colors.success).render('✓')} Tag deleted in transaction',
      );
    });
    io.success('Transaction committed successfully');
  } catch (e) {
    io.error('Transaction rolled back: $e');
  }
}
