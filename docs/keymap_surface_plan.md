# Keymap / Shortcut Surface Plan

**Status:** complete through Phase 4 (hub, widgets, OpenCode multi-surface, docs + examples)  





**Goal:** Move artisanal toward an OpenTUI-`@opentui/keymap`-class model:  
**surface-first layered shortcuts** that both **dispatch keys** and **describe themselves** (which-key + shortcuts popup).

**References:**

- OpenTUI: `@opentui/keymap` (priority layers, focus-scoped maps, pending sequences, command catalog, cheat-sheet helpers)
- OpenCode: named keybind ids + leader + `ctrl+p` palette; Solid contexts; focus decides who eats keys
- Artisanal today: `ProgramInterceptor` (single), `KeyChordInterceptor`, `KeyMap` / `HelpView`, `ChordController` / `ChordHost` / `WhichKeySlot`

---

## 1. Problem

Today three concerns are split:

| Concern | Where it lives |
|--------|----------------|
| Intercept keys early | One fixed `ProgramOptions.interceptor` |
| Multi-key chords | `KeyChordInterceptor` + app `handleUpdate` |
| Discoverability | Hand-fed `WhichKeyPanel` / `HelpView` / palette labels |

That causes:

1. **Discord** — bindings list ≠ which-key list ≠ palette shortcuts  
2. **No honest dialog/route maps** — interceptor cannot be “surface first” without a stack  
3. **Hard to show “shortcuts for this view”** — no active-layer query API  

OpenTUI solved this with **layers + pending sequence + command catalog**. We should not invent a weaker parallel; we should map that design onto artisanal’s TEA + widget tree.

---

## 2. Target architecture

### 2.1 Mental model (OpenTUI → artisanal)

| OpenTUI `@opentui/keymap` | Artisanal target |
|---------------------------|------------------|
| `Keymap` runtime | `KeymapHub` (name TBD; aka interceptor hub) |
| Priority-ordered layers | Stack: **surface first**, then base/global |
| Focus / focus-within layers | `ShortcutSurface` mounted on route/dialog/focus scope |
| Fallthrough / preventDefault | `fallthrough` / `exclusive` on surface |
| Pending multi-key sequence | Chord / sequence state on hub (active layer) |
| Invalidate on focus change | Reset pending when top surface changes |
| Command catalog + tiers | Named actions + `active` / `reachable` queries |
| Cheat-sheet helpers | `ShortcutsSheet` + `WhichKeySlot` over same data |
| Leader / timed leader addons | Leader token + timeout (OpenCode-compatible) |

### 2.2 Dispatch order (locked)

```
KeyMsg (or raw key)
  → top ShortcutSurface          // dialog, then session, …
  → lower surfaces (if fallthrough)
  → base layers                  // replay, devtools, true globals
  → widget tree handleUpdate
```

**Surface-first** so modals win. Unclaimed keys under `exclusive: true` do **not** fall through (true modal).

### 2.3 One unit of truth: `ShortcutSurface`

```dart
class ShortcutSurface {
  final String id;                    // 'session', 'confirm-dialog'
  final List<ShortcutBinding> bindings; // singles + sequences (unified)
  final bool exclusive;               // default false; dialogs true
  final bool fallthrough;             // inverse of exclusive for unclaimed
  // metadata for help: group, title, …
}
```

**Binding shapes (conceptual):**

- Single: `ctrl+p` → `command_list`
- Sequence: `ctrl+x` then `b` → `sidebar_toggle` (leader style)
- Optional: longer sequences later (`g` `g`)

**Not two parallel systems** (KeyMap + KeyChordBinding forever). Migration path may keep both as *views* over one binding list.

### 2.4 Runtime: `KeymapHub`

Single `ProgramInterceptor` installed at `runProgram`:

```dart
final hub = KeymapHub(
  base: [replayInterceptor, devtools], // always last
);

runProgram(app, options: ProgramOptions(interceptor: hub));
```

API sketch:

```dart
class KeymapHub implements ProgramInterceptor {
  void push(ShortcutSurface surface);
  void pop(String id);
  void replace(String id, ShortcutSurface surface);
  ShortcutSurface? get top;
  List<ShortcutSurface> get stack;

  /// Pending multi-key state (which-key).
  PendingSequence? get pending;
  List<ShortcutBinding> get activeContinuations;

  /// Discovery (shortcuts popup).
  List<ResolvedShortcut> activeShortcuts({bool includeReachable = false});

  /// Cancel pending (surface change, escape policy).
  void resetPending();

  void Function(String actionId)? onAction; // or emit msgs
}
```

`onSend`:

1. If `pending` → try continue / cancel / timeout  
2. Else walk stack **top → base**; first claim wins  
3. Emit action resolution as `KeymapActionMsg(id: …)` (preferred over opaque side effects) so TEA stays pure  

### 2.5 Widgets: `ShortcutSurfaceScope`

```dart
ShortcutSurfaceScope(
  surface: ShortcutSurface(
    id: 'session',
    exclusive: false,
    bindings: sessionBindings,
  ),
  child: SessionShell(...),
)
```

Lifecycle:

- **mount / became top** → `hub.push(surface)`  
- **dispose / covered by exclusive** → `hub.pop` or deactivate  
- **DialogRoute** → `exclusive: true` by default  

Inherited:

```dart
ShortcutSurface.of(context);           // nearest / active
KeymapHub.of(context);                 // hub for pending + catalog
```

### 2.6 Discoverability (same data)

| UI | Source |
|----|--------|
| `WhichKeySlot` | `hub.pending` + `activeContinuations` |
| `ShortcutsSheet` / `?` | `hub.activeShortcuts()` for top surface (+ optional reachable parents) |
| `HelpView` | Adapter: build `KeyMap` from active surface bindings |
| Command palette | Can list **actions** registered on hub (optional later) |

No second hand-maintained help list.

---

## 3. Package split

| Package | Owns |
|---------|------|
| **`artisanal` (tui)** | `KeymapHub`, binding model, sequence engine, `KeymapActionMsg`, `ResettableInterceptor`, leader timeout, compose with existing `ProgramInterceptor` |
| **`artisanal_widgets`** | `ShortcutSurfaceScope`, hub scope, `WhichKeySlot` (rewired), `ShortcutsSheet`, migrate `ChordController` → thin facade over hub/surface |
| **OpenCode example** | Surfaces per route/dialog; leader map; `?` sheet; palette ids align with action ids |

**Do not** put hub only in widgets — pure TEA apps need layers too.

---

## 4. Migration from current chord work

Keep working demos; fold, don’t rewrite overnight.

| Today | After |
|-------|--------|
| `KeyChordInterceptor` | Sequence engine inside hub (or hub wraps it per layer) |
| `ChordController` | Facade: one surface’s chords + listenable pending from hub |
| `ChordHost` | Merge into `ShortcutSurfaceScope` + hub listener |
| `openCodeChordBindings()` | `ShortcutSurface(id: 'session', bindings: …)` |
| Example-local which-key entries | Deleted (already mostly gone) |

Compatibility:

```dart
// Phase 1–2 still allowed
ChordController(bindings: …) 
// implements / feeds a ShortcutSurface under the hood
```

Deprecate “app owns `_chordActive` bool” patterns (already reduced).

---

## 5. Phased delivery

### Phase 0 — Core hub (artisanal tui) ✅

**Deliverables**

- [x] `KeymapHub` implements `ProgramInterceptor` (`lib/src/tui/keymap_hub.dart`)
- [x] Stack: `push` / `pop` / `replace` / `popUntil` / `top` / `clearSurfaces`
- [x] Surface-first `onSend` order; `exclusive` blocks fallthrough
- [x] `ResettableInterceptor` + `KeyChordInterceptor.reset()`; hub resets on pop
- [x] Unit tests: `test/tui/keymap_hub_test.dart`

**Non-goals:** widgets, which-key UI, OpenCode migration

**Exit:** TEA test program can push two layers; dialog layer steals keys; pop restores session.

---

### Phase 1 — Sequence + actions (artisanal tui) ✅

**Deliverables**

- [x] `ShortcutBinding` (+ `fromChord` / `toChordBinding` bridges)
- [x] Pending sequence engine on `ShortcutSurface` (start / continue / cancel / `sequenceTimeout`)
- [x] `KeymapActionMsg`, `KeymapSequencePrefixMsg`, `KeymapSequenceCancelledMsg`
- [x] Hub queries: `pending`, `activeContinuations`, `pendingPrefixLabel`, `pendingStatusHint`, `resetPending`
- [x] Push new surface / pop resets pending; exclusive dialogs block lower maps
- [x] Tests: `test/tui/keymap_sequence_test.dart`

**Exit:** Leader `ctrl+x` then `b` resolves only on active surface; switch surface mid-chord cancels.

---

### Phase 2 — Widget surface scope (artisanal_widgets) ✅

**Deliverables**

- [x] `KeymapHubScope` + `ShortcutSurfaceScope` (`surfaceId`, auto push on `handleInit`)
- [x] Hub `addListener` / stack+pending rebuilds; `onAction` for `KeymapActionMsg`
- [x] `WhichKeySlot` prefers hub pending; falls back to `ChordController`
- [x] `whichKeyEntriesFromContinuations`; `ChordController` also handles Keymap* msgs
- [x] Tests: `test/chords/keymap_hub_scope_test.dart` (+ legacy chord tests)

**Exit:** Apps can use hub + surface scopes without dual binding lists.

---

### Phase 3 — Shortcuts sheet (discovery) ✅

**Deliverables**

- [x] `ShortcutsSheet` + `ShortcutsSheet.forHub` / `.of(context)`
- [x] `KeymapHub.activeShortcuts(includeReachable:)` for reachable parents
- [x] `KeymapHubScope` toggles sheet on `help_show` (`ShortcutBinding.help()` / `?`); esc closes
- [x] `keyMapFromShortcutBindings` + `formatShortcutKeys` for `HelpView`
- [x] Tests: `test/chords/shortcuts_sheet_test.dart`

**Exit:** From session, open sheet → see `ctrl+x b` sidebar etc.; dialog sheet shows only dialog keys.

---

### Phase 4 — OpenCode example + polish ✅

**Deliverables**

- [x] OpenCode routes use `ShortcutSurfaceScope`: `home`, `session`, `review`, `agent`
- [x] Action ids from `AppChord` + `command_list` / `help_show`; palette shares handlers
- [x] Program interceptor is `KeymapHub` (`openCodeKeymapHub`)
- [x] TEA example: `pkgs/artisanal/example/tui/examples/keymap-hub/`
- [x] Docs: `TUI.md`, `WIDGETS.md`, `DOCS_INDEX.md`, this plan

**Exit:** Route change + dialog stack behave like OpenTUI layers; `?` and which-key stay consistent.

**Follow-ups (optional):** exclusive modal dialogs in OpenCode (session list/theme), prompt-focus leader policy.

**Bugfix (nav reset):** `KeymapHubScope` must keep a **stable** child slot when toggling the help overlay. Using `Modal` (bare child when closed, `Stack` when open) remounted the `Navigator` and reset to `/`. Overlay is now a fixed `Stack`. `ShortcutSurfaceScope` uses `replace`/`activate` instead of re-`push` so lower routes cannot steal the top surface.

---

## 6. Key API decisions (frozen for this plan)

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Stack order | **Surface first**, base last | Dialogs/modals must win |
| Exclusive unclaimed | **No fallthrough** | True modal |
| Action delivery | Prefer **msgs** (`KeymapActionMsg`) | TEA purity; widgets handle in `onResolved` / `handleUpdate` |
| Leader | First-class sequence prefix (OpenCode `ctrl+x`) | Parity |
| Globals (`ctrl+p`) | Base layer **or** re-declared on surfaces | Prefer base non-exclusive for true globals; exclusive dialogs re-list if needed |
| Naming | `KeymapHub` + `ShortcutSurface` | OpenTUI “keymap” + our surface vocabulary |

Revisit only if implementation hits a wall.

---

## 7. Prompt / text-field policy

OpenCode complexity: input captures most keys; leader still works from chrome.

**Rule (v1):**

- Surfaces may set `capturesPrintable: true` (prompt/editor)
- Leader / chord prefixes still handled by hub **before** content if configured as “chrome bindings”
- Or: surface deactivates leader while a child text field is focused (simpler, slightly less OpenCode-like)

**Phase 4** picks one and documents it; default recommendation: **hub handles bindings marked `scope: chrome` even when text focused; printables go to field.**

---

## 8. Testing matrix

| Case | Expect |
|------|--------|
| Session only + `ctrl+x` `b` | Sidebar action; which-key during pending |
| Dialog exclusive open | Session chords dead; dialog `y`/`n` work |
| Pending chord then push dialog | Pending cleared |
| Pop dialog | Session map restored |
| `?` on session | Sheet lists session bindings |
| `?` on dialog | Sheet lists dialog only |
| Base replay interceptor | Still under hub; scripts inject |
| Exclusive + unclaimed `ctrl+p` | Dropped unless dialog declares it or exclusive false |

---

## 9. Risks & mitigations

| Risk | Mitigation |
|------|------------|
| Over-building full OpenTUI keymap | Phases 0–2 only: stack + sequences + surface scope |
| Breaking existing chord tests | Facade `ChordController` until Phase 4 |
| Navigator lifecycle races | Explicit push on route didPush / pop on dispose; tests |
| Double-dispatch (hub + handleIntercept) | Hub claims → drop KeyMsg or convert to action msg; document single owner |
| Naming churn | One doc (this file); rename only at phase boundaries |

---

## 10. Non-goals (for this move)

- Full Neovim keymap language / ex commands  
- DOM/HTML adapter (OpenTUI has it; we don’t need it)  
- Replacing command palette with only the sheet  
- Config file format parity with OpenCode `tui.json` (optional later)  
- Zig/FFI keyboard path  

---

## 11. Suggested PR sequence

1. **PR1:** `KeymapHub` stack + exclusive + tests (Phase 0)  
2. **PR2:** Sequences + `KeymapActionMsg` + pending API (Phase 1)  
3. **PR3:** Widget scopes + rewire which-key (Phase 2)  
4. **PR4:** `ShortcutsSheet` + help action (Phase 3)  
5. **PR5:** OpenCode example multi-surface (Phase 4)  

Each PR shippable; OpenCode example stays green via facade until PR5.

---

## 12. Success criteria

1. **One declaration** of shortcuts per surface drives intercept, which-key, and shortcuts popup.  
2. **Dialogs** can own maps without rebinding the process interceptor.  
3. **Surface-first** dispatch matches OpenTUI layer intuition.  
4. OpenCode example maps read as thin **surfaces + action handlers**, not triple-wired chords.  
5. Docs point at OpenTUI keymap as design reference; artisanal API stays idiomatic Dart/TEA.

---

## 13. Open questions (resolve before PR3)

1. Exact type name: `KeymapHub` vs `InterceptorHub` vs `ShortcutRegistry`?  
   → Prefer **`KeymapHub`** (OpenTUI-aligned).  
2. Should `KeyMap` class gain sequences natively, or new `ShortcutBinding` supersede?  
   → Prefer new model + adapters to `KeyMap`/`HelpView`.  
3. Dialog exclusive default on all `DialogRoute`s?  
   → **Yes**, opt-out for non-modal overlays.  

---

## 14. Next step

Implement **Phase 0** (`KeymapHub` in `artisanal` tui) as the first code PR; keep `ChordController` working unchanged until Phase 2 rewires it.
