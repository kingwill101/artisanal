import 'package:ormed_cli/runtime.dart';
import 'package:ormed/ormed.dart';
import 'package:ormed_fullstack_example/orm_registry.g.dart';

import 'seeders/database_seeder.dart';
// <ORM-SEED-IMPORTS>
import 'seeders/genre_seeder.dart';
import 'seeders/movie_seeder.dart';// </ORM-SEED-IMPORTS>

/// Registered seeders for this project.
/// 
/// Used by `ormed seed` command and can be imported for programmatic seeding.
final List<SeederRegistration> seeders = <SeederRegistration>[
// <ORM-SEED-REGISTRY>
SeederRegistration(
    name: 'AppDatabaseSeeder',
    factory: (connection) => AppDatabaseSeeder(connection),
  ),
  SeederRegistration(
    name: 'GenreSeeder',
    factory: GenreSeeder.new,
  ),
  SeederRegistration(
    name: 'MovieSeeder',
    factory: MovieSeeder.new,
  ),// </ORM-SEED-REGISTRY>
];

/// Run project seeders on the given connection.
/// 
/// Example:
/// ```dart
/// await runProjectSeeds(connection);
/// await runProjectSeeds(connection, names: ['UserSeeder']);
/// ```
Future<void> runProjectSeeds(
  OrmConnection connection, {
  List<String>? names,
  bool pretend = false,
}) async {
  bootstrapOrm(registry: connection.context.registry);
  await SeederRunner().run(
    connection: connection,
    seeders: seeders,
    names: names,
    pretend: pretend,
  );
}

Future<void> main(List<String> args) => runSeedRegistryEntrypoint(
      args: args,
      seeds: seeders,
      beforeRun: (connection) =>
          bootstrapOrm(registry: connection.context.registry),
    );
