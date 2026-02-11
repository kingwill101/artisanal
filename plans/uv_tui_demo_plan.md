# UV + TUI Demo Roadmap (Artisanal)

Goal: ship a technically impressive, interactive multi‑page demo that pushes UV/TUI capabilities, and identify library features to make Artisanal more useful (physics, charting, shader/filter pipeline, tag renderer).

Scope: `pkgs/artisanal/example/uv_tui_demo/**` (demo), `pkgs/artisanal/lib/src/**` (framework additions), `pkgs/artisanal/lib/physics.dart` (exports).

---

## Phase 0: Baseline + Hygiene (now)
- [ ] Confirm demo boots: `dart run pkgs/artisanal/example/uv_tui_demo.dart`
- [ ] Capture current issues/UX papercuts (e.g., table visibility, key exits)
- [ ] Lock a “hero path” (what the demo shows in the first 20s)

Deliverable: stable run + known issue list.

---

## Phase 1: Multi‑Page Experience (short)
Purpose: make the demo feel like a product with modes.

TODO
- [ ] Add a global page switcher (tabs or carousel) with clear header state
- [ ] Define 3–4 pages with distinct visual identities
  - [ ] Nexus (existing dashboard)
  - [ ] Physics (Forge2D sandbox)
  - [ ] Charts (time series + heatmap)
  - [ ] Canvas/FX (shader + filter pipeline demos)
- [ ] Add a per‑page help overlay + keymap
- [ ] Add per‑page status footer (fps, last input, render mode)

Files to touch
- `pkgs/artisanal/example/uv_tui_demo/model.dart`
- `pkgs/artisanal/example/uv_tui_demo/widgets.dart`
- `pkgs/artisanal/example/uv_tui_demo/uv_tui_demo.dart`

Deliverable: user can cycle pages and each page feels distinct.

---

## Phase 2: Physics + ASCII Renderer (mid)
Purpose: show that TUI can simulate + render complex scenes.

TODO
- [ ] Expand Physics scene with multiple emitters (particles, blobs, debris)
- [ ] Add tuning knobs (gravity, damping, collider size, spawn rate)
- [ ] Implement collision‑aware “spark” trails
- [ ] Add debug overlays (bodies count, broadphase stats, fps)
- [ ] Add deterministic seed mode for shareable scenes

Files to touch
- `pkgs/artisanal/example/uv_tui_demo/physics_scene.dart`
- `pkgs/artisanal/lib/src/physics/physics.dart`
- `pkgs/artisanal/lib/physics.dart`

Deliverable: physics page is visually busy, interactive, and stable.

---

## Phase 3: Charting Library (mid)
Purpose: make reusable charts a core differentiator.

TODO
- [ ] Add `chart/` module with primitives
  - [ ] sparkline, area, histogram, heatmap
  - [ ] stacked/ribbon time series
- [ ] Support viewport + clipping for large series
- [ ] Add consistent theming hooks
- [ ] Build a “Charts” page in the demo

Files to touch
- `pkgs/artisanal/lib/src/charting/*` (new)
- `pkgs/artisanal/example/uv_tui_demo/widgets.dart`
- `pkgs/artisanal/example/uv_tui_demo/model.dart`

Deliverable: charts are reusable outside the demo.

---

## Phase 4: Shader/Filter Pipeline + Liquify (advanced)
Purpose: prove UV can do per‑cell post‑processing.

TODO
- [ ] Introduce “buffer filters” API
  - [ ] filter stack (compose, order, bounds)
  - [ ] simple blend + brightness + blur (box)
- [ ] Implement `LiquifyFilter`
  - [ ] velocity field + displacement map per frame
  - [ ] configurable strength + damping
- [ ] Demo page: animated distortion on a sub‑buffer

Files to touch
- `pkgs/artisanal/lib/src/glamour/renderer.dart`
- `pkgs/artisanal/lib/src/uv/*` (if needed)
- `pkgs/artisanal/example/uv_tui_demo/model.dart`

Deliverable: visible, controllable liquify effect in demo.

---

## Phase 5: Tag Renderer / Declarative UI (advanced)
Purpose: turn the demo into a showcase for a new API.

TODO
- [ ] Define lightweight tag grammar (e.g. `<panel>`, `<spark>`, `<grid>`)
- [ ] Map tags to TUI widgets / UV layers
- [ ] Add hot‑swap theme packs (tag attribute driven)
- [ ] Demo: “live layout” page editing tags

Files to touch
- `pkgs/artisanal/lib/src/tui/*` (parser + renderer)
- `pkgs/artisanal/example/uv_tui_demo/widgets.dart`
- `pkgs/artisanal/example/uv_tui_demo/model.dart`

Deliverable: mini DSL that renders into UV buffers.

---

## Phase 6: Polish + Release (wrap‑up)
TODO
- [ ] Optimize diff rendering + frame budget
- [ ] Add runtime flags (low‑power mode, disable FX)
- [ ] Add tests for physics + charts
- [ ] Update README + example docs + gif

Files to touch
- `pkgs/artisanal/README.md`
- `pkgs/artisanal/example/*`
- `pkgs/artisanal/test/*`

Deliverable: demo is stable, fast, and documented.

---

## Next Action (choose one to start)
1) Charts primitives module
2) Liquify filter pipeline
3) Tag renderer MVP
4) Physics scene expansion

Decision rule: pick the one that best showcases “wow” in 60 seconds.
