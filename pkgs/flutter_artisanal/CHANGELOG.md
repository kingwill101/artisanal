# Changelog

## 0.2.1

### Changed

- Updated the supported Artisanal workspace releases to `artisanal` 0.5.x,
  `artisanal_widgets` 0.3.x, and `ultraviolet` 0.5.x.

## 0.2.0

### Changed

- Refactored library exports to use targeted `show` directives instead of
  broad `hide` lists, surfacing only stable public types (`WidgetApp`,
  `ArtisanalApp`, `ReloadController`, `ReloadHost`, `Transport`, etc.).
- Added re-exports from `artisanal_widgets/widgets.dart` for `ImageAutoMode`,
  `Theme`, and `ThemeMode`.
- Consolidated widget app controller imports.

## 0.1.0

* Initial release.
