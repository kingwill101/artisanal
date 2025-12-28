# Release Tooling

## Publish automation

The publish script processes packages in dependency order. It runs a `dart pub publish --dry-run` for each package and optionally publishes to pub.dev.

### Usage

- Dry-run all changed packages:

```bash
dart tool/publish.dart
```

- Publish all changed packages:

```bash
dart tool/publish.dart --force
```

- Include unchanged packages (override change detection):

```bash
dart tool/publish.dart --include-unchanged
```

- Skip packages that already have the requested version on pub.dev:

```bash
dart tool/publish.dart --skip-published
```

### Notes

- The script compares each package against the latest git tag (`git describe --tags --abbrev=0`).
- If no tag is found, all packages are processed.
- Run from the repo root with a clean git state before publishing.
