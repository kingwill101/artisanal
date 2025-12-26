# Changelog

## 0.1.0-dev+4

- **Added**: Through relations support with `hasOneThrough` and `hasManyThrough` relation types.
- **Added**: Polymorphic relations with `morphTo`, `morphToMany`, and `morphedByMany` support.
- **Added**: Attribute accessors and mutators for get/set interception.
- **Added**: Appended/computed attributes for serialization.
- **Added**: Extended attribute casting system with custom cast handlers.
- **Added**: Pivot enhancements including `withPivot` field selection and pivot timestamps.
- **Added**: Raw query helpers `orderByRaw` and `groupByRaw`.
- **Fixed**: `updatedAt` now respects explicitly provided values during updates (dirty-check aware).
- **Added**: Object input support for `fill`, `forceFill`, and `fillIfAbsent` methods.
- **Refactored**: Decoupled database drivers from the core package. Drivers now register themselves via `DriverAdapterRegistry`.
- **Added**: `DataSource.fromConfig` as the standard, driver-agnostic entry point for ORM initialization.
- **Added**: `syncWithoutDetaching`, `syncWithPivotValues`, `toggle`, and `updateExistingPivot` methods for `ManyToMany` relationships.
- **Added**: Support for eager loading nested relations (e.g., `ds.query<User>().with('posts.comments').get()`).
- **Added**: `copyWith` method generation for DTOs and partial models.
- **Added**: `suppressEvents` option to `Query` for optimized bulk operations.
- **Added**: `loadOrmConfig()` and `findOrmConfigFile()` convenience helpers for configuration management.
- **Fixed**: Eager loading for models with custom primary keys (Issue #12).
- **Fixed**: Improved relation inference for complex naming conventions and ambiguous foreign keys (Issue #7).
- **Fixed**: Missing relation accessors in generated models for certain edge cases (Issue #6).
- **Fixed**: Resolved bugs #4, #11, and #13 related to query builder edge cases.
- **Improved**: Code generator now emits dartdoc comments for all generated models and members.
- **Improved**: Reached 160/160 pub score with expanded documentation and examples.

## 0.1.0-dev+3

- **Fixed**: Timestamp getters (`createdAt`, `updatedAt`, `deletedAt`) now return **immutable** Carbon instances to prevent accidental mutation of model state when chaining date methods like `subDay()`.
- Refactored `Timestamps` and `SoftDeletes` mixins to use `CarbonInterface` for getters and `Object?` for setters.
- Exported `carbonized` package directly from `ormed.dart`.
- Improved `DateTimeCodec` to handle `Carbon` instances during decoding.
- Fixed mass assignment to handle both field and column names for excluded attributes.
- Optimized Postgres test performance using transactional isolation.
- Fixed SQLite test cleanup issue where `test_g*` files were left behind.
- Expanded testing documentation with isolation strategies and concurrency guides.
- Updated doc comments to follow Effective Dart guidelines.

## 0.1.0-dev+2

- Synchronized release with ormed_cli rebranding.

## 0.1.0-dev+1

- Added automatic `snake_case` column name inference for model fields.
- Fixed `DatabaseSeeder.seed<T>()` to use repositories for correct data encoding.
- Fixed `bootstrapOrm()` to ensure model registration in existing registries.
- Improved documentation for naming conventions and CLI-first workflow.

## 0.1.0-dev

- Initial release.
