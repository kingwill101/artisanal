# Changelog

## 0.1.0-dev+9

- **Updated**: Synced with core schema migration changes to avoid transaction issues in MySQL.

## 0.1.0-dev+8

- **Improved**: CLI now prints structured OrmException hints.
- **Fixed**: Seed registry scaffolding avoids analyzer dependency warnings.
- **Added**: `make:model` scaffolds models in `lib/src/database/models`.
- **Added**: `init --with-analyzer` writes analyzer plugin configuration.
- **Updated**: Synced dependency versions for dev+8.

## 0.1.0-dev+7

- **Updated**: Synced dependency versions for dev+7.

## 0.1.0-dev+6

- **Updated**: Synchronized ormed changes.

## 0.1.0-dev+5

- **Updated**: Align dependencies on `ormed` `0.1.0-dev+5`.
- **Added**: `ormed init --only` to scaffold selected artifacts.
- **Fixed**: Dependency prompt now treats `dependencies`, `dev_dependencies`, and `dependency_overrides` as valid declarations.

## 0.1.0-dev+4

- **Improved**: `ormed init` now scaffolds a `datasource.dart` file that automatically handles driver registration and provides a type-safe `DataSource` instance.
- **Improved**: `ormed init` now automatically adds the appropriate driver dependency (e.g., `ormed_sqlite`) to `pubspec.yaml` based on the selected driver.
- **Improved**: Updated configuration loading to use the new core `loadOrmProjectConfig` and `findOrmConfigFile` utilities.
- **Changed**: Default SQLite database path is now `database/{project_name}.sqlite` for better project organization.
- **Added**: Package example and improved help text for all commands.

## 0.1.0-dev+3

- Synchronized release.

## 0.1.0-dev+2

- **BREAKING**: Renamed CLI executable from `orm` to `ormed`.
- **BREAKING**: Renamed default configuration file from `orm.yaml` to `ormed.yaml` (with backward compatibility for `orm.yaml`).
- Updated `ormed init` to scaffold `ormed.yaml` and offer to rename legacy `orm.yaml`.
- Improved documentation and installation instructions.

## 0.1.0-dev+1

- Added automatic dependency management to `orm init` (prompts to add `ormed`, `ormed_cli`, and `build_runner`).
- Improved `orm init` output with better spacing and summary tables.
- Added support for SQL-based migrations (`up.sql`/`down.sql`) alongside Dart migrations.
- Switched CLI table output to `horizontalTable` for better readability.

## 0.1.0-dev

- Initial release.
