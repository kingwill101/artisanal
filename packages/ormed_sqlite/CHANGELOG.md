# Changelog

## 0.1.0-dev+9

- **Refactor**: Relocated dialect-specific integration tests and grammar tests from core into the driver package.
- **Improved**: `applySchemaPlan` no longer wraps operations in transactions to ensure compatibility with standardized migration runner behavior.
- **Added**: Regression that boots the helper-provided multi-datasource setup without `ormedGroup` to ensure `ConnectionManager` isolation stays intact.

## 0.1.0-dev+8

- **Improved**: SQLite migration error now explains primary key limitations.
- **Updated**: Synced dependency versions for dev+8.

## 0.1.0-dev+7

- **Added**: `session` options to apply PRAGMA settings on connect.
- **Added**: `init` statements list to run initialization SQL on connect.
- **Changed**: SQLite driver registration now preserves `database`/`path` options when building connections.

## 0.1.0-dev+6

- **Added**: SQLite full-text query compilation for `whereFullText`, including optional index targeting.
- **Added**: Driver extension registry integration for custom query clauses.

## 0.1.0-dev+5

- **Fixed**: Insert builders now omit columns not provided so SQLite defaults (including timestamps) apply.
- **Fixed**: JSON cast encoding/decoding now uses cast semantics to accept scalar JSON values.

## 0.1.0-dev+4

- **Added**: Support for through relations, polymorphic relations, and advanced query helpers.
- **Added**: Pivot timestamp support for many-to-many relationships.
- **Added**: Raw query helpers for `orderByRaw` and `groupByRaw`.

## 0.1.0-dev+3

- **Added**: `ensureSqliteDriverRegistration()` to register the driver with the core ORM.
- **Added**: Package example demonstrating `DataSource.fromConfig` usage.
- **Improved**: Aligned with core `0.1.0-dev+4` refactor for driver-agnostic initialization.
- **Improved**: Better handling of relative database paths in CLI-scaffolded projects.

## 0.1.0-dev+3

- Fixed test cleanup issue where `test_g*` files were left behind.
- Synchronized release.

## 0.1.0-dev+2

- Synchronized release with ormed_cli rebranding.

## 0.1.0-dev+1

- Internal version bump to align with ORMed release.

## 0.1.0-dev

- Initial release.
