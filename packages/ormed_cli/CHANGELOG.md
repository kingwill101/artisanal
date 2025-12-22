# Changelog

## 0.1.0-dev+4

- **Improved**: `ormed init` now scaffolds a `datasource.dart` file that automatically handles driver registration.
- **Improved**: Updated configuration loading to use the new core `loadOrmProjectConfig` and `findOrmConfigFile` utilities.
- **Added**: Package example.

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
