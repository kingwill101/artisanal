# Changelog

## 0.1.0-dev+10

- **Fixed**: Query deletes using fallback row identifiers now project the identifier, avoiding `ctid` lookup errors.
- **Added**: Session option allowlist and validation for `session` keys.
- **Improved**: Full-text language identifiers are validated and preview SQL formatting ignores placeholders inside string literals.

## 0.1.0-dev+9

- **Refactor**: Relocated dialect-specific integration tests and grammar tests from core into the driver package.
- **Improved**: Standardized schema migration behavior to avoid transaction-related DDL errors.
- **Fixed**: Verified support for recursive JSON encoding of nested ORM objects (implemented in core).

## 0.1.0-dev+8

- **Updated**: Synced dependency versions for dev+8.

## 0.1.0-dev+7

- **Added**: `session` options to set connection-level settings (via `SET ...`) on connect.
- **Added**: `init` statements list to run initialization SQL on connect.

## 0.1.0-dev+6

- **Added**: Full-text query compilation for `whereFullText`, including websearch/phrase/boolean modes.
- **Added**: Driver extension registry integration for custom query clauses.

## 0.1.0-dev+5

- **Fixed**: Insert builders now omit columns not provided so Postgres defaults (e.g., timestamps) apply.

## 0.1.0-dev+4

- **Added**: Support for through relations, polymorphic relations, and advanced query helpers.
- **Added**: Pivot timestamp support for many-to-many relationships.
- **Added**: Raw query helpers for `orderByRaw` and `groupByRaw`.

## 0.1.0-dev+3

- **Added**: `ensurePostgresDriverRegistration()` to register the driver with the core ORM.
- **Added**: Package example demonstrating `DataSource.fromConfig` usage.
- **Fixed**: Type-safe filter generation for certain PostgreSQL-specific queries (Issue #9).
- **Fixed**: Updated codec decoding to correctly unwrap `TypedValue` for round-trip compatibility in insert/upsert paths.
- **Improved**: Aligned with core `0.1.0-dev+4` refactor for driver-agnostic initialization.

## 0.1.0-dev+3

- Optimized test performance using transactional isolation.
- Synchronized release.

## 0.1.0-dev+2

- Synchronized release with ormed_cli rebranding.

## 0.1.0-dev+1

- Internal version bump to align with ORMed release.

## 0.1.0-dev

- Initial release.
