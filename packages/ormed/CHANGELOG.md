# Changelog

## 0.1.0-dev+4

- **Refactored**: Decoupled database drivers from the core package. Drivers now register themselves via `DriverAdapterRegistry`.
- **Added**: `DataSource.fromConfig` as the standard, driver-agnostic entry point for ORM initialization.
- **Fixed**: Eager loading for models with custom primary keys (Issue #12).
- **Fixed**: Improved relation inference for complex naming conventions and ambiguous foreign keys (Issue #7).
- **Fixed**: Missing relation accessors in generated models for certain edge cases (Issue #6).
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
