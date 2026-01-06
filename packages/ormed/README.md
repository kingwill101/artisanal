# ormed

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Documentation](https://img.shields.io/badge/docs-ormed.vercel.app-blue)](https://ormed.vercel.app/)
[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-support-yellow?logo=buy-me-a-coffee)](https://www.buymeacoffee.com/kingwill101)

A strongly-typed ORM (Object-Relational Mapping) core for Dart, inspired by Eloquent (Laravel), GORM, SQLAlchemy, and ActiveRecord. Combines compile-time code generation with runtime flexibility for type-safe database operations.

## Features

- **Annotations**: `@OrmModel`, `@OrmField`, `@OrmRelation`, `@OrmScope`, `@OrmEvent` to describe tables, columns, relationships, and behaviors
- **Code Generation**: Emits `ModelDefinition`, `FieldDefinition`, `ModelCodec`, DTOs, and tracked model classes
- **Query Builder**: Fluent, type-safe queries with filtering, ordering, pagination, aggregates, and eager loading
- **Relationships**: HasOne, HasMany, BelongsTo, ManyToMany, and polymorphic relations (MorphOne, MorphMany)
- **Migrations**: Schema builder with Laravel-style table blueprints and driver-specific overrides
- **Value Codecs**: Custom type serialization with driver-scoped codec registries
- **Soft Deletes**: Built-in support with `withTrashed()`, `onlyTrashed()` scopes
- **Event System**: Model lifecycle events (Creating, Created, Updating, Updated, Deleting, Deleted)
- **Testing**: `TestDatabaseManager` with database isolation strategies

## Installation

```yaml
dependencies:
  ormed: any
  ormed_sqlite: any # Or ormed_postgres, ormed_mysql

dev_dependencies:
  ormed_cli: any
  build_runner: ^2.4.0
```

## Analyzer Plugin (Preview)

Ormed ships an optional analyzer plugin (no separate package) that inspects your
query builder usage, DTOs, and model metadata during analysis. It helps catch
unsafe patterns, invalid field names, and other common pitfalls before runtime.

### Enable the plugin

1) Add `ormed` to `dev_dependencies`.
2) Enable the plugin in your project's `analysis_options.yaml`:

```yaml
analyzer:
  plugins:
    - ormed
```

> After changing `analysis_options.yaml`, restart the Dart Analysis Server.
> If you previously used the standalone `ormed_analyzer` package, remove it from
> your `pubspec.yaml` and switch to the `ormed` plugin above.

### How it works

- The plugin scans generated `*.orm.dart` files to build a model index. Run
  `build_runner` first so the definitions exist.
- Query modifiers are tracked within the same function body, including split
  chains and cascades:
  ```dart
  final q = query.where('email', '=', 'a@example.com');
  q.get(); // no warning because the earlier where() is tracked
  ```
- The tracker is intra-procedural (no cross-function tracking) and does not
  model control-flow branches precisely.
- Only literal field names can be validated. Dynamic strings are ignored.

### Diagnostics (grouped)

Field and selection validation:
- `ormed_unknown_field`: unknown field/column in query builder calls.
```dart
Model.query<Post>()
.where('missing_field', true); // ormed_unknown_field
```
- `ormed_unknown_select_field`: unknown column in `select([...])`.
```dart
Model.query<Post>()
.select(['missing_select']); // ormed_unknown_select_field
```
- `ormed_duplicate_select_field`: duplicate column in `select([...])`.
```dart
Model.query<Post>()
.select(['title', 'title']); // ormed_duplicate_select_field
```
- `ormed_unknown_order_field`: unknown column in `orderBy(...)`.
```dart
Model.query<Post>()
.orderBy('missing_order'); // ormed_unknown_order_field
```
- `ormed_unknown_group_field`: unknown column in `groupBy(...)`.
```dart
Model.query<Post>()
.groupBy(['missing_group']); // ormed_unknown_group_field
```
- `ormed_unknown_having_field`: unknown column in `having(...)`.
```dart
Model.query<Post>()
.having('missing_having', PredicateOperator.equals, 1); // ormed_unknown_having_field
```

Relation validation:
- `ormed_unknown_relation`: unknown relation in `withRelation(...)` or similar.
```dart
Model.query<Post>()
.withRelation('missingRelation'); // ormed_unknown_relation
```
- `ormed_unknown_nested_relation`: unknown nested relation path.
```dart
Model.query<Post>()
.withRelation('comments.missingRelation'); // ormed_unknown_nested_relation
```
- `ormed_invalid_where_has`: `whereHas(...)` targets a missing relation.
```dart
Model.query<Post>()
.whereHas('missingRelation'); // ormed_invalid_where_has
```
- `ormed_relation_field_mismatch`: relation callback uses a field from the wrong model.
```dart
Model.query<Post>()
.whereHas('comments', (q) => q.where('email', 'oops')); // ormed_relation_field_mismatch
```
- `ormed_missing_pivot_field`: missing pivot field in many-to-many definitions.
```dart
Model.query<Post>()
.withRelation(const RelationDefinition(name: 'tags', kind: RelationKind.manyToMany, targetModel: 'Tag', pivotColumns: ['missing_pivot'], pivotModel: 'PostTag')); // ormed_missing_pivot_field
```

Type-aware predicate checks:
- `ormed_type_mismatch_eq`: `whereEquals(...)` value type mismatches the field.
```dart
Model.query<Post>()
.whereEquals('userId', 'not_an_int'); // ormed_type_mismatch_eq
```
- `ormed_where_in_type_mismatch`: `whereIn(...)` values mismatch the field type.
```dart
Model.query<Post>()
.whereIn('userId', ['not_an_int']); // ormed_where_in_type_mismatch
```
- `ormed_where_between_type_mismatch`: `whereBetween(...)` values mismatch the field type.
```dart
Model.query<Post>()
.whereBetween('userId', 'a', 'z'); // ormed_where_between_type_mismatch
```
- `ormed_typed_predicate_field`: typed predicate field does not exist on the model.
```dart
Model.query<Post>()
.whereTyped((q) => q.legacy.eq('oops')); // ormed_typed_predicate_field
```

Query safety and performance:
- `ormed_update_delete_without_where`: `update()` or `delete()` without constraints.
```dart
Model.query<Post>()
.update({'title': 'updated'}); // ormed_update_delete_without_where
```
```dart
Model.query<Post>()
.delete(); // ormed_update_delete_without_where
```
- `ormed_offset_without_order`: `offset()` without `orderBy`.
```dart
Model.query<Post>()
.offset(10); // ormed_offset_without_order
```
- `ormed_limit_without_order`: `limit()` without `orderBy`.
```dart
Model.query<Post>()
.limit(10); // ormed_limit_without_order
```
- `ormed_get_without_limit`: `get()`, `rows()`, `getPartial()`,
  `Model.all()`, `ModelCompanion.all()`, or generated companion `Posts.all()`
  used without a `limit()` or chunk/paginate alternative.
```dart
Model.query<Post>()
.get(); // ormed_get_without_limit
```
```dart
Posts.all(); // ormed_get_without_limit
```

Raw SQL safety:
- `ormed_raw_sql_interpolation`: raw SQL with string interpolation and no bindings.
```dart
Model.query<Post>()
.whereRaw('title = $title'); // ormed_raw_sql_interpolation
```
- `ormed_raw_sql_alias_missing`: `selectRaw(...)` without an alias.
```dart
Model.query<Post>()
.selectRaw('count(*)'); // ormed_raw_sql_alias_missing
```

DTO validation:
- `ormed_insert_missing_required`: insert DTO missing required fields.
```dart
Model.repository<Post>()
.insert(PostInsertDto()); // ormed_insert_missing_required
```
- `ormed_update_missing_pk`: update DTO missing a primary key (or missing where).
```dart
Model.repository<Post>()
.update(PostUpdateDto(title: 'updated')); // ormed_update_missing_pk
```

Soft delete and timestamp checks:
- `ormed_with_trashed_on_non_soft_delete`
```dart
Model.query<User>()
.withTrashed(); // ormed_with_trashed_on_non_soft_delete
```
- `ormed_without_timestamps_on_timestamped_model`
```dart
User(email: 'a@b.com', name: 'Test')
.withoutTimestamps(() {}); // ormed_without_timestamps_on_timestamped_model
```
- `ormed_updated_at_access_on_without_timestamps`
```dart
Tag(id: 1, name: 'ormed')
.updatedAt; // ormed_updated_at_access_on_without_timestamps
```

### Suppressing diagnostics

Suppress a single diagnostic with:

```dart
// ignore: ormed/ormed_unknown_field
```

Or suppress an entire file:

```dart
// ignore_for_file: ormed/ormed_get_without_limit
```

### Generated code warnings

The plugin analyzes generated `.orm.dart` files by default (it needs them to
build the model index). If you do not want warnings in generated files, add
excludes to `analysis_options.yaml`:

```yaml
analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.orm.dart"
```

### AOT snapshot workaround

If your project uses `ormed_sqlite`, the analyzer plugin may fail to compile
an AOT snapshot because `ormed_sqlite` depends on build hooks. In that case,
run analysis with:

```bash
dart analyze --no-use-aot-snapshot
```

## Getting Started

The recommended way to use Ormed is via the `ormed` CLI, which manages migrations, seeders, and project scaffolding.

### 1. Install the CLI

You can install the CLI globally (recommended for smaller dependency trees) or add it to your `dev_dependencies`:

```bash
# Global installation
dart pub global activate ormed_cli
```

> **Note:** Adding `ormed_cli` to `dev_dependencies` ensures version parity with your project but will include all database drivers and their dependencies in your `pubspec.lock`.

### 2. Initialize the Project

Scaffold the configuration and directory structure:

```bash
ormed init
```

(Or use `dart run ormed_cli:ormed init` if not installed globally).

This creates `ormed.yaml` and the `lib/src/database` directory.

### 3. Define a Model

Create a model file (e.g., `lib/src/models/user.dart`):

```dart
import 'package:ormed/ormed.dart';

part 'user.orm.dart';

@OrmModel()
class User extends Model<User> {
  final String name;
  final String email;

  User({required this.name, required this.email});
}
```

### 3. Generate ORM Code

Run `build_runner` to generate model definitions and tracked classes:

```bash
dart run build_runner build
```

### 4. Create and Run Migrations

Generate a migration for your model:

```bash
dart run ormed_cli:ormed make --name create_users_table --create --table users
```

Edit the generated migration in `lib/src/database/migrations/` to add columns:

```dart
void up(SchemaBuilder schema) {
  schema.create('users', (table) {
    table.id();
    table.string('name');
    table.string('email').unique();
    table.timestamps();
  });
}
```

Apply the migration:

```bash
dart run ormed_cli:ormed migrate
```

### 5. Seed the Database

Create a seeder:

```bash
dart run ormed_cli:ormed make --name UserSeeder --seeder
```

Add data in `lib/src/database/seeders/user_seeder.dart`:

```dart
Future<void> run() async {
  await seed<User>([
    {'name': 'John Doe', 'email': 'john@example.com'},
  ]);
}
```

Run the seeders:

```bash
dart run ormed_cli:ormed seed
```

### 6. Bootstrap and Use

The recommended way to initialize Ormed is using the generated `datasource.dart` entrypoint created by `ormed init`:

```dart
import 'package:ormed/ormed.dart';
import 'src/database/datasource.dart'; // Generated by ormed init

void main() async {
  // 1. Create the DataSource using project configuration
  final ds = createDataSource();

  // 2. Initialize connections
  await ds.init();

  // 3. Query with type-safety
  final users = await ds.query<$User>().get();
}
```

#### Manual Initialization

If you prefer manual setup without `ormed.yaml`, you can use `DataSourceOptions`:

```dart
import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';
import 'orm_registry.g.dart';

void main() async {
  final ds = DataSource(DataSourceOptions(
    driver: SqliteDriverAdapter.file('database.sqlite'),
    registry: bootstrapOrm(),
  ));
  
  await ds.init();
}
```

## Migrations

Ormed supports two migration formats, which can be mixed in the same project. The migration runner is format-agnostic, allowing you to use the best tool for each change.

### Dart Migrations (Default)
Type-safe migrations using a fluent `SchemaBuilder`. Best for most use cases.

```bash
dart run ormed_cli:ormed make --name add_bio_to_users
```

### SQL Migrations
Raw `.sql` files for complex schema changes or when porting existing SQL scripts.

```bash
dart run ormed_cli:ormed make --name add_bio_to_users --format sql
```

This creates a directory with `up.sql` and `down.sql` files.

### Simultaneous Support
You can have Dart and SQL migrations in the same project. The runner executes them in chronological order based on their timestamps, regardless of format. This flexibility allows you to use Dart for standard schema changes and SQL for database-specific features or complex optimizations.

## Annotations

### `@OrmModel`

By default, Ormed infers the table name by pluralizing and snake_casing the class name (e.g., `User` -> `users`, `UserRole` -> `user_roles`).

```dart
@OrmModel(
  table: 'users',
  schema: 'public',           // Optional schema/namespace
  softDeletes: true,          // Enable soft deletes
  primaryKey: 'id',           // Alternative to @OrmField(isPrimaryKey: true)
  fillable: ['email', 'name'], // Mass assignment whitelist
  guarded: ['role'],          // Mass assignment blacklist
  hidden: ['password'],       // Hidden from serialization
  connection: 'analytics',    // Connection name override
)
```

### `@OrmField`

By default, Ormed infers the column name by snake_casing the field name (e.g., `emailAddress` -> `email_address`).

```dart
@OrmField(
  columnName: 'user_email',   // Custom column name
  isPrimaryKey: true,
  autoIncrement: true,
  isNullable: true,
  isUnique: true,
  isIndexed: true,
  codec: JsonMapCodec,        // Custom value codec
  columnType: ColumnType.text, // Override column type
  defaultValueSql: 'NOW()',   // SQL default expression
  driverOverrides: {...},     // Per-driver customizations
)
```

### `@OrmRelation`

```dart
// One-to-One (foreign key on related table)
@OrmRelation.hasOne(related: Profile, foreignKey: 'user_id')
final Profile? profile;

// One-to-Many
@OrmRelation.hasMany(related: Post, foreignKey: 'author_id')
final List<Post> posts;

// Inverse relation
@OrmRelation.belongsTo(related: User, foreignKey: 'user_id')
final User author;

// Many-to-Many
@OrmRelation.manyToMany(
  related: Tag,
  pivot: 'post_tags',
  foreignPivotKey: 'post_id',
  relatedPivotKey: 'tag_id',
)
final List<Tag> tags;

// Polymorphic
@OrmRelation.morphMany(related: Comment, morphName: 'commentable')
final List<Comment> comments;
```

## Query Builder

```dart
final posts = await ds.query<Post>()
    // Filtering
    .whereTyped((q) => q.status.eq('published'))
    .whereIn('category_id', [1, 2, 3])
    .whereNull('deleted_at')
    .whereBetween('views', 100, 1000)
    .whereHasComments((q) => q.body.like('%approved%'))
    
    // Eager loading
    .with_(['author', 'tags'])
    .withCount('comments')
    
    // Ordering & Pagination
    .orderByDesc('created_at')
    .limit(20)
    .offset(40)
    
    // Execute
    .get();

// Aggregates
final count = await ds.query<Post>().count();
final avgViews = await ds.query<Post>().avg('views');

// Pagination
final page = await ds.query<Post>().paginate(page: 2, perPage: 15);
```

## Migrations

```dart
class CreateUsersTable extends Migration {
  @override
  void up(SchemaBuilder schema) {
    schema.create('users', (table) {
      table.id();                              // bigIncrements primary key
      table.string('email').unique();
      table.string('name').nullable();
      table.boolean('active').defaultValue(true);
      table.timestamps();                      // created_at, updated_at
      table.softDeletes();                     // deleted_at
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('users');
  }
}
```

### Column Types

| Method | Description |
|--------|-------------|
| `id()` | Auto-incrementing big integer primary key |
| `string(name, length?)` | VARCHAR column |
| `text(name)` | TEXT column |
| `integer(name)` / `bigInteger(name)` | Integer columns |
| `decimal(name, precision?, scale?)` | Decimal column |
| `boolean(name)` | Boolean column |
| `dateTime(name)` / `timestamp(name)` | DateTime columns |
| `json(name)` / `jsonb(name)` | JSON columns |
| `binary(name)` | Binary/BLOB column |
| `enum_(name, values)` | Enum column |

### Column Modifiers

```dart
table.string('locale')
    .nullable()
    .unique()
    .defaultValue('en')
    .comment('User locale')
    .driverType('postgres', ColumnType.jsonb())  // Per-driver type
    .driverDefault('postgres', "'{}'::jsonb");   // Per-driver default
```

## Value Codecs

Custom type serialization for database ↔ Dart conversion:

```dart
class UuidCodec extends ValueCodec<UuidValue> {
  const UuidCodec();

  @override
  UuidValue? decode(Object? value) =>
      value == null ? null : UuidValue.fromString(value as String);

  @override
  Object? encode(UuidValue? value) => value?.uuid;
}

// Register globally
ValueCodecRegistry.instance.registerCodecFor(UuidCodec, const UuidCodec());

// Or per-driver
ValueCodecRegistry.instance.forDriver('postgres')
    .registerCodec(key: 'UuidValue', codec: const PostgresUuidCodec());
```

## Repository Operations

```dart
final repo = ds.repo<$User>();

// Create
await repo.insert($UserInsertDto(email: 'new@example.com'));
await repo.insertMany([dto1, dto2, dto3]);

// Read
final user = await repo.find(1);
final all = await repo.all();
final first = await repo.first();

// Update (accepts DTOs, models, or maps)
await repo.update(dto, where: {'id': 1});
await repo.update(dto, where: (q) => q.whereEquals('email', 'old@example.com'));

// Delete
await repo.delete(model);
await repo.deleteByIds([1, 2, 3]);

// Upsert
await repo.upsert(dto, uniqueBy: ['email']);
```

## Transactions

```dart
await ds.transaction(() async {
  await ds.repo<$User>().insert(userDto);
  await ds.repo<$Profile>().insert(profileDto);
  // Automatically rolls back on exception
});
```

## Naming Conventions

`ormed` follows a "convention over configuration" approach for database names:

- **Tables**: Inferred from the model class name using plural snake_case.
  - `User` → `users`
  - `UserProfile` → `user_profiles`
- **Columns**: Inferred from field names using snake_case.
  - `emailAddress` → `email_address`
  - `createdAt` → `created_at`

You can override these using the `@OrmModel` and `@OrmField` annotations:

```dart
@OrmModel(tableName: 'legacy_users')
class User extends Model<User> {
  @OrmField(columnName: 'user_email')
  final String email;
}
```

## Database Drivers

Ormed requires a database driver to connect to your database. Choose the driver that matches your database:

### SQLite (`ormed_sqlite`)

[![pub package](https://img.shields.io/pub/v/ormed_sqlite.svg)](https://pub.dev/packages/ormed_sqlite)

Best for: Local development, mobile apps, embedded databases, testing.

```yaml
dependencies:
  ormed_sqlite: any
```

```dart
import 'package:ormed_sqlite/ormed_sqlite.dart';

// In-memory (great for testing)
final adapter = SqliteDriverAdapter.inMemory();

// File-based
final adapter = SqliteDriverAdapter.file('app.sqlite');
```

**Features:** In-memory & file databases, JSON1 extension, FTS5 full-text search, window functions, R*Tree spatial indexes.

### PostgreSQL (`ormed_postgres`)

[![pub package](https://img.shields.io/pub/v/ormed_postgres.svg)](https://pub.dev/packages/ormed_postgres)

Best for: Production applications, complex queries, advanced data types.

```yaml
dependencies:
  ormed_postgres: any
```

```dart
import 'package:ormed_postgres/ormed_postgres.dart';

final adapter = PostgresDriverAdapter.fromUrl(
  'postgres://user:pass@localhost:5432/mydb',
);
```

**Features:** UUID, JSONB, arrays, geometric types, full-text search (tsvector), range types, RETURNING clause, connection pooling.

### MySQL/MariaDB (`ormed_mysql`)

[![pub package](https://img.shields.io/pub/v/ormed_mysql.svg)](https://pub.dev/packages/ormed_mysql)

Best for: Existing MySQL infrastructure, WordPress/Laravel migrations, web hosting.

```yaml
dependencies:
  ormed_mysql: any
```

```dart
import 'package:ormed_mysql/ormed_mysql.dart';

final adapter = MySqlDriverAdapter.fromUrl(
  'mysql://user:pass@localhost:3306/mydb',
);
```

**Features:** MySQL 8.0+, MariaDB 10.5+, JSON columns, ENUM/SET types, spatial types, Laravel-compatible configuration.

## Related Packages

| Package | Description |
|---------|-------------|
| [`ormed_sqlite`](https://pub.dev/packages/ormed_sqlite) | SQLite driver adapter |
| [`ormed_postgres`](https://pub.dev/packages/ormed_postgres) | PostgreSQL driver adapter |
| [`ormed_mysql`](https://pub.dev/packages/ormed_mysql) | MySQL/MariaDB driver adapter |
| [`ormed_cli`](https://pub.dev/packages/ormed_cli) | CLI tool for migrations and scaffolding |

## Examples

See the `example/` directory and `packages/orm_playground` for comprehensive usage examples.
