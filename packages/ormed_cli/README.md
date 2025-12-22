# ormed_cli

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Documentation](https://img.shields.io/badge/docs-ormed.vercel.app-blue)](https://ormed.vercel.app/)
[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-support-yellow?logo=buy-me-a-coffee)](https://www.buymeacoffee.com/kingwill101)

Command-line interface for the ormed ORM. Provides migration management, schema operations, seeding, and project scaffolding—similar to Laravel's Artisan CLI.

## Installation

### Global (Recommended)

Install the CLI globally to use the `ormed` command directly from anywhere:

```bash
dart pub global activate ormed_cli
```

### Local

Add it to your `dev_dependencies` in `pubspec.yaml`. This ensures you always have the version of the CLI that matches your project's ORM version:

```yaml
dev_dependencies:
  ormed_cli: any
```

> **Note:** Adding `ormed_cli` as a local dependency will pull in all supported database drivers (SQLite, MySQL, Postgres) and their respective native dependencies. If you want to keep your project's dependency tree minimal, use the **Global** installation instead.

The CLI is available as the `ormed` executable:

```bash
# If installed globally
ormed <command>

# If using local dependency
dart run ormed_cli:ormed <command>
```

## Commands

For a complete walkthrough of setting up a project with the CLI, see the [Getting Started Guide](https://github.com/kingwill101/ormed/tree/main/packages/ormed#getting-started).

### Project Initialization

```bash
# Scaffold ormed.yaml, migration registry, and DataSource entrypoint
ormed init

# Overwrite existing files
ormed init --force
```

The `init` command creates:
- `ormed.yaml`: Project configuration (connections, drivers, paths)
- `lib/src/database/datasource.dart`: The recommended entrypoint for your application
- `lib/src/database/migrations.dart`: Migration registry
- `lib/src/database/seeders.dart`: Seeder registry

### Migration Management

```bash
# Create a new migration
ormed make --name create_users_table
ormed make --name create_posts_table --create --table posts
ormed make --name add_column --format sql  # SQL format instead of Dart

# Run pending migrations
ormed migrate
ormed migrate --pretend      # Preview SQL without executing
ormed migrate --step         # Apply one migration at a time
ormed migrate --seed         # Run default seeder after
ormed migrate --force        # Skip production confirmation

# Rollback migrations
ormed migrate:rollback              # Rollback 1 migration
ormed migrate:rollback --steps 3    # Rollback 3 migrations
ormed migrate:rollback --batch 2    # Rollback specific batch
ormed migrate:rollback --pretend    # Preview rollback SQL

# Reset/Refresh
ormed migrate:reset      # Rollback ALL migrations
ormed migrate:refresh    # Reset + re-migrate
ormed migrate:fresh      # Drop all tables + re-migrate
ormed migrate:fresh --seed

# Migration status
ormed migrate:status
ormed migrate:status --pending  # Only show pending

# Export SQL files
ormed migrate:export        # Export pending migrations
ormed migrate:export --all  # Export all migrations
```

### Database Operations

```bash
# Run seeders
dart run ormed_cli:ormed seed
dart run ormed_cli:ormed seed --class UserSeeder  # Specific seeder
dart run ormed_cli:ormed seed --pretend           # Preview SQL

# Wipe database
dart run ormed_cli:ormed db:wipe --force
dart run ormed_cli:ormed db:wipe --drop-views

# Schema operations
dart run ormed_cli:ormed schema:dump
dart run ormed_cli:ormed schema:dump --prune  # Delete migration files after dump
dart run ormed_cli:ormed schema:describe
dart run ormed_cli:ormed schema:describe --json
```

### Multi-Database Support

```bash
# Target specific connection
dart run ormed_cli:ormed migrate --connection analytics
dart run ormed_cli:ormed seed --connection analytics
dart run ormed_cli:ormed migrate:status --connection analytics
```

## Configuration (ormed.yaml)

The `init` command scaffolds this configuration file:

```yaml
driver:
  type: sqlite                              # sqlite, mysql, postgres
  options:
    database: database.sqlite               # Connection-specific options

migrations:
  directory: lib/src/database/migrations    # Migration files location
  registry: lib/src/database/migrations.dart # Migration registry file
  ledger_table: orm_migrations              # Table tracking applied migrations
  schema_dump: database/schema.sql          # Schema dump output
  format: dart                              # Migration format: dart or sql

seeds:
  directory: lib/src/database/seeders
  registry: lib/src/database/seeders.dart
```

### Multi-Connection Configuration

```yaml
connections:
  default:
    type: sqlite
    options:
      database: main.sqlite
  analytics:
    type: postgres
    options:
      host: localhost
      port: 5432
      database: analytics
      username: user
      password: secret

default_connection: default
```

## Directory Structure

After running `init`:

```
project/
├── ormed.yaml
├── database/
│   └── schema.sql
└── lib/src/database/
    ├── migrations/
    │   └── m_YYYYMMDDHHMMSS_migration_name.dart
    ├── migrations.dart   (registry)
    ├── seeders/
    │   └── database_seeder.dart
    └── seeders.dart      (registry)
```

## Migration Formats

Ormed supports both Dart and SQL migrations in the same project. The CLI automatically registers them in your migration registry.

### Dart Migrations (default)
Type-safe migrations using a fluent `SchemaBuilder`.

```bash
dart run ormed_cli:ormed make --name create_users_table
```

```dart
class CreateUsersTable extends Migration {
  @override
  void up(SchemaBuilder schema) {
    schema.create('users', (table) {
      table.id();
      table.string('email').unique();
      table.timestamps();
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('users');
  }
}
```

### SQL Migrations
Raw `.sql` files for complex schema changes.

```bash
dart run ormed_cli:ormed make --name add_bio_to_users --format sql
```

This creates a directory:
```
m_20251220120000_add_bio_to_users/
├── up.sql
└── down.sql
```

### Simultaneous Support
The CLI runner is format-agnostic. It builds a unified timeline of all registered migrations based on their timestamps. When you run `migrate`, it will execute Dart classes and SQL files in the correct chronological order. This allows you to use Dart for standard schema changes and drop down to SQL for complex, database-specific logic without breaking the migration flow.

## Runtime Bootstrapping

When using the CLI, you should use the generated `bootstrapOrm()` function to initialize your `ModelRegistry`. This ensures all models, factories, and metadata are correctly registered.

```dart
import 'package:ormed/ormed.dart';
import 'orm_registry.g.dart';

void main() {
  final registry = bootstrapOrm();
  // ...
}
```

## Global Options

Most commands support these flags:

| Flag | Description |
|------|-------------|
| `--config, -c` | Path to ormed.yaml |
| `--database, -d` | Override database connection |
| `--connection` | Select connection from ormed.yaml |
| `--path` | Override migration registry path |
| `--force, -f` | Skip production confirmation |
| `--pretend` | Preview SQL without executing |
| `--graceful` | Treat errors as warnings |

## Creating Seeders

```bash
dart run ormed_cli:ormed make --name UserSeeder --seeder
```

```dart
class UserSeeder extends DatabaseSeeder {
  @override
  Future<void> run() async {
    await seed<User>([
      {'email': 'admin@example.com', 'name': 'Admin'},
      {'email': 'user@example.com', 'name': 'User'},
    ]);
  }
}
```
