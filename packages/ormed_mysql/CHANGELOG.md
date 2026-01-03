# Changelog

## 0.1.0-dev+7

- **Changed**: MySQL session variables now use the `session` option (removed `sessionVariables` alias).

## 0.1.0-dev+6

- **Added**: Full-text query compilation for `whereFullText`, including boolean/phrase/websearch modes.
- **Added**: Driver extension registry integration for custom query clauses.

## 0.1.0-dev+5

- **Updated**: Align dependency on `ormed` `0.1.0-dev+5`.

## 0.1.0-dev+4

- **Added**: Support for through relations, polymorphic relations, and advanced query helpers.
- **Added**: Pivot timestamp support for many-to-many relationships.
- **Added**: Raw query helpers for `orderByRaw` and `groupByRaw`.

## 0.1.0-dev+3

- **Added**: `ensureMySqlDriverRegistration()` to register the driver with the core ORM.
- **Added**: Package example demonstrating `DataSource.fromConfig` usage.
- **Fixed**: Default and current timestamp expressions in `MySqlSchemaDialect`.
- **Improved**: Aligned with core `0.1.0-dev+4` refactor for driver-agnostic initialization.

## 0.1.0-dev+3

- Fixed microsecond precision loss in `DateTime` formatting.

## 0.1.0-dev+2

- Synchronized release with ormed_cli rebranding.

## 0.1.0-dev+1

- Internal version bump to align with ORMed release.

## 0.1.0-dev

- Initial release.
