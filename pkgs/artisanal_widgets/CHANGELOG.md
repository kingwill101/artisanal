# Changelog

## Unreleased

### Added

- Added a stable `package:artisanal_widgets/widgets.dart` entrypoint for the high-level widget framework surface.

### Changed

- Kept `package:artisanal_widgets/artisanal_widgets.dart` as the broader experimental compatibility surface while stabilizing the primary widget/app/layout/input/navigation APIs.
- Updated the widget docs to prefer the stable `package:artisanal_widgets/widgets.dart` import path.

## 0.1.0+1
- Documentation + assets
## 0.1.0

### Added

- Initial release of `artisanal_widgets`.
- Flutter-style terminal widget system built on top of `artisanal`.
- Core widget framework, layout primitives, focus/gesture/input systems, and component library.
- Charting widgets, scroll/selection support, and testing harnesses for TUI widget behavior.
