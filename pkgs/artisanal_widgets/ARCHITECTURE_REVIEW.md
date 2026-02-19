# artisanal_widgets Architecture Review

Last updated: 2026-02-19

This document captures the current implementation state and near-term plans for
widget architecture in `pkgs/artisanal_widgets`, plus direct integration
boundaries in `pkgs/artisanal`.

## 1) Current-state summary by subsystem

### Architecture layers

- The package follows a Flutter-like stack: `Widget -> Element -> RenderObject`,
  wired into the artisanal TEA runtime (`Model`/`Msg`/`Cmd`) through
  `WidgetApp`.
- Core framework primitives (`StatelessWidget`, `StatefulWidget`, `State`,
  `InheritedWidget`) are present and aligned with familiar Flutter lifecycle
  semantics.

### State and update pattern

- State updates are message-driven. `Element.dispatch` performs
  intercept/children/self phases and coalesces commands.
- `State.setState()` only marks the owning element dirty; rebuilds happen during
  build scope execution managed by `BuildOwner`.
- `BuildOwner` tracks dirty elements, paint requests, mouse capture, and frame
  timing metrics.

### Rendering pipeline

- `WidgetApp.update()` handles runtime messages, hit-testing, overlay/metrics
  updates, and dirty-state propagation.
- `WidgetApp.view()` caches rendered output (`String` or `View`) and reuses it
  when tree, background color, and overlay state are unchanged.
- `ElementTree.render()` performs build/layout/paint timing and reports it to
  `BuildOwner`.

### Event and gesture model

- Mouse input defaults to render-tree hit-testing and bubbles as
  `HitTestMouseMsg` from deepest hit to ancestors.
- Mouse capture is supported for drag-like flows.
- `GestureDetector` currently contains integrated recognizer wiring and event
  orchestration in state logic.

### Layout and composition

- Render objects implement constraint-based layout, paint, and hit-testing.
- Flex-style layouts (`RenderRow`/`RenderColumn`) support two-pass flex
  measurement and child paint caching.
- Render-object parents flatten descendants to collect concrete render children;
  non-render wrappers are expected to be explicit pass-throughs.

### Theming and styling

- Theme model includes semantic color slots, text styles, and optional
  component-specific theme data.
- Theme propagation supports both global state and scoped inheritance via
  `ThemeScope`.
- Terminal background auto-detection updates dark/light adaptive resolution.

### Animation status

- No general animation subsystem is implemented yet (curves, tweens,
  controller, listenables, animated builders).
- Spinner-based timer ticks demonstrate the intended TEA-compatible scheduling
  approach.
- A detailed phased plan exists to introduce TEA-native animation primitives.

### Testing strategy

- `WidgetTester` runs a real `Program` with a mock terminal to keep runtime
  semantics (message queueing, command execution, update->render ordering)
  faithful in tests.
- Package guidance emphasizes public-barrel imports in tests/examples and full
  package test runs.

### Developer ergonomics

- AGENTS and README documentation provide strong onboarding for architecture,
  import conventions, testing, and examples.
- The package intentionally mirrors Flutter idioms while preserving artisanal's
  TEA command model.

### Dependency and example ownership boundaries

- `artisanal_widgets` now keeps OpenCode example state models local to
  `example/opencode/models/*` and imports those directly from example widgets.
- The package dependency surface is intentionally minimal: runtime deps are
  `artisanal`, `image`, and `meta`; dev deps are `lints` and `test`.
- This keeps package architecture independent from external app-package model
  libraries while still allowing rich example apps.

## 2) Concrete strengths

1. Clear layering (`Widget -> Element -> RenderObject`) backed by explicit
   package guidance.
2. Familiar Flutter-style widget/state APIs reduce cognitive load.
3. Deterministic message dispatch pipeline with explicit interception and
   keyboard one-winner behavior.
4. Strong runtime bridge in `WidgetApp` with command coalescing and robust
   dirty-state handling.
5. Cached view pipeline avoids unnecessary rendering work.
6. Render-tree hit-testing and bubble-up dispatch supports stateful wrappers
   without render objects.
7. Flex layout implementation includes two-pass sizing and child paint caching.
8. Theming includes semantic slots plus component-specific extension points.
9. Adaptive terminal background handling is integrated into runtime updates.
10. High-fidelity widget testing harness runs through real program semantics.
11. Performance/debug instrumentation is built into `BuildOwner`/`WidgetApp`.
12. Integration boundaries are documented and consistently tied to artisanal's
    public barrels.
13. OpenCode example model ownership is self-contained, reducing cross-package
    coupling risk for `artisanal_widgets`.

## 3) Concrete gaps and risks

1. Animation foundation is still missing (curves/tweens/controller/listenables).
2. Gesture architecture remains partially centralized in `GestureDetector`
   state logic instead of being fully recognizer-led end-to-end.
3. Render hit-testing currently always adds self and does not yet express full
   behavior semantics in the base render object API.
4. Rich gesture interactions are still mid-migration risk (typed details,
   arena conflict model, call-site consistency).
5. No shared/global animation tick source yet, creating potential per-controller
   timer overhead once animations scale.
6. Command-chaining patterns for animation status transitions are not yet a
   first-class API.
7. Some architecture guidance still references older zone-era behavior for
   compatibility paths, increasing conceptual surface area.
8. Global mutable theme state can create coupling in larger apps if `ThemeScope`
   usage is inconsistent.
9. Render-metrics consumers must handle conditional availability based on app
   flags.
10. The broader artisanal package is explicitly marked work-in-progress and API
    instability remains an integration risk.
11. Example-local OpenCode models can drift from external app ecosystems if
    model evolution is not periodically reviewed.

## 4) Evidence (file references)

- Architecture and package rules: `pkgs/artisanal_widgets/AGENTS.md:5`,
  `pkgs/artisanal_widgets/AGENTS.md:7`,
  `pkgs/artisanal_widgets/AGENTS.md:66`,
  `pkgs/artisanal_widgets/AGENTS.md:84`,
  `pkgs/artisanal_widgets/AGENTS.md:88`.
- Widget model/update flow: `pkgs/artisanal_widgets/lib/src/widgets/core/widget.dart:37`,
  `pkgs/artisanal_widgets/lib/src/widgets/core/widget.dart:99`,
  `pkgs/artisanal_widgets/lib/src/widgets/core/widget.dart:121`.
- Framework lifecycle primitives: `pkgs/artisanal_widgets/lib/src/widgets/core/framework.dart:32`,
  `pkgs/artisanal_widgets/lib/src/widgets/core/framework.dart:47`,
  `pkgs/artisanal_widgets/lib/src/widgets/core/framework.dart:61`,
  `pkgs/artisanal_widgets/lib/src/widgets/core/framework.dart:111`.
- Element dispatch/build ownership: `pkgs/artisanal_widgets/lib/src/widgets/core/element.dart:342`,
  `pkgs/artisanal_widgets/lib/src/widgets/core/element.dart:416`,
  `pkgs/artisanal_widgets/lib/src/widgets/core/element.dart:1041`,
  `pkgs/artisanal_widgets/lib/src/widgets/core/element.dart:1185`,
  `pkgs/artisanal_widgets/lib/src/widgets/core/element.dart:1212`.
- App integration/rendering/event pipeline:
  `pkgs/artisanal_widgets/lib/src/widgets/app/widget_app.dart:231`,
  `pkgs/artisanal_widgets/lib/src/widgets/app/widget_app.dart:303`,
  `pkgs/artisanal_widgets/lib/src/widgets/app/widget_app.dart:327`,
  `pkgs/artisanal_widgets/lib/src/widgets/app/widget_app.dart:443`.
- Render layer/layout: `pkgs/artisanal_widgets/lib/src/widgets/rendering/render_object.dart:13`,
  `pkgs/artisanal_widgets/lib/src/widgets/rendering/render_object.dart:51`,
  `pkgs/artisanal_widgets/lib/src/widgets/rendering/render_layout.dart:99`,
  `pkgs/artisanal_widgets/lib/src/widgets/rendering/render_layout.dart:155`.
- Gesture implementation: `pkgs/artisanal_widgets/lib/src/widgets/layout/gesture_detector.dart:3`,
  `pkgs/artisanal_widgets/lib/src/widgets/layout/gesture_detector.dart:71`,
  `pkgs/artisanal_widgets/lib/src/widgets/layout/gesture_detector.dart:238`,
  `pkgs/artisanal_widgets/lib/src/widgets/layout/gesture_detector.dart:362`.
- Theme system: `pkgs/artisanal_widgets/lib/src/widgets/theme/theme.dart:259`,
  `pkgs/artisanal_widgets/lib/src/widgets/theme/theme.dart:795`,
  `pkgs/artisanal_widgets/lib/src/widgets/theme/theme.dart:823`,
  `pkgs/artisanal_widgets/lib/src/widgets/theme/theme_scope.dart:7`.
- Animation status and plan: `pkgs/artisanal_widgets/ANIMATION_PLAN.md:19`,
  `pkgs/artisanal_widgets/ANIMATION_PLAN.md:25`,
  `pkgs/artisanal_widgets/ANIMATION_PLAN.md:67`,
  `pkgs/artisanal_widgets/ANIMATION_PLAN.md:112`.
- Gesture roadmap and migration risk: `pkgs/artisanal_widgets/GESTURE_PLAN.md:18`,
  `pkgs/artisanal_widgets/GESTURE_PLAN.md:39`,
  `pkgs/artisanal_widgets/GESTURE_PLAN.md:80`,
  `pkgs/artisanal_widgets/GESTURE_PLAN.md:174`.
- Testing approach: `pkgs/artisanal_widgets/lib/src/widgets/testing/widget_tester.dart:1`,
  `pkgs/artisanal_widgets/lib/src/widgets/testing/widget_tester.dart:6`,
  `pkgs/artisanal_widgets/lib/src/widgets/testing/widget_tester.dart:68`.
- Example model ownership and dependency boundary:
  `pkgs/artisanal_widgets/example/opencode/main.dart:14`,
  `pkgs/artisanal_widgets/example/opencode/main.dart:15`,
  `pkgs/artisanal_widgets/example/opencode/models/chat_model.dart:1`,
  `pkgs/artisanal_widgets/example/opencode/models/message.dart:1`,
  `pkgs/artisanal_widgets/pubspec.yaml:19`,
  `pkgs/artisanal_widgets/pubspec.yaml:25`.
- Integration boundary in core package: `pkgs/artisanal/README.md:27`,
  `pkgs/artisanal/README.md:43`, `pkgs/artisanal/README.md:50`.
