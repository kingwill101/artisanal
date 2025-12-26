# Changelog

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
