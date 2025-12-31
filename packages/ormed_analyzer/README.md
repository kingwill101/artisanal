# ormed_analyzer

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Documentation](https://img.shields.io/badge/docs-ormed.vercel.app-blue)](https://ormed.vercel.app/)
[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-support-yellow?logo=buy-me-a-coffee)](https://www.buymeacoffee.com/kingwill101)

Analyzer plugin for Ormed that flags unsafe raw SQL and unknown fields/relations in queries.

## Features

- Warns on unknown field or column names in query builder calls
- Warns on unknown relation names for relation helpers
- Warns on missing typed predicate fields in `whereTyped` callbacks
- Warns on raw SQL string interpolation without bindings

## Installation

Add the plugin to `dev_dependencies`:

```yaml
dev_dependencies:
  ormed_analyzer: any
```

Enable the plugin in your **workspace root** `analysis_options.yaml`:

```yaml
plugins:
  ormed_analyzer: ^0.1.0-dev+6
```

> After changing `analysis_options.yaml`, restart the Dart Analysis Server.

## Diagnostics

The plugin reports warnings with these codes:

- `ormed_unknown_field`
- `ormed_unknown_relation`
- `ormed_typed_predicate_field`
- `ormed_raw_sql_interpolation`

You can suppress a diagnostic with:

```dart
// ignore: ormed_analyzer/ormed_unknown_field
```

## Local Development

To use a local checkout:

```yaml
plugins:
  ormed_analyzer:
    path: ../ormed_analyzer
```

