# dev-6 Review

## Findings

- **Medium — Generated `copyWith` can produce invalid code for non‑nullable `Object` fields.**
  `_castValue` returns the raw `Object?` parameter when the field type is `Object`, so the ternary in `_userConstructorInvocation` widens to `Object?` and is passed into a non‑nullable `Object` constructor parameter. This can cause analyzer errors if any model has a non‑nullable `Object` field (or silently allow nulls). Consider casting to `Object` (non‑nullable) or handling `Object` separately in `copyWith` generation.
  Files:
  - `packages/ormed/lib/src/builder/emitters/model_subclass_emitter.dart:515-521`
  - `packages/ormed/lib/src/builder/emitters/model_subclass_emitter.dart:690-703`

- **Medium — Publish script can publish uncommitted formatting changes.**
  `tool/publish.dart` now runs `dart format .` unconditionally. If formatting changes files, the script still publishes without verifying a clean git state, so published artifacts may not match the tagged commit and CI runs can leave the tree dirty. Consider aborting if `git status --porcelain` is non‑empty after formatting, or run format in a temp copy.
  File:
  - `tool/publish.dart:40-70`

- **Low — Global log spacing behavior change may be a UX regression.**
  `_labeledBlock` no longer inserts a trailing blank line. This will make successive logs run together unless callers manually add `newLine()`. If existing CLIs relied on blank separation, output will get denser. Consider a toggle or doc note.
  File:
  - `packages/artisanal/lib/src/io/console.dart:671-676`

## Questions / Assumptions

- Do you expect any models to have **non‑nullable `Object`** fields? If yes, add a generator test to catch the copyWith issue explicitly.

## Change Summary

- Added driver extension framework + examples, typed predicate/relations helpers, generator tweaks, and new Postgres extensions package; updated logging injection, publish automation, and promoted artisanal to `0.1.0`.
