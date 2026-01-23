# Documentation Code Snippets Inventory

This file tracks the health of documentation snippets embedded from `.site/examples/**` into `.site/docs/**` via `remark-code-region`.

## Snapshot (2025-12-17)

- Snippet references: `340`
- Missing references: `0`
- Max snippet size (non-blank lines): `25`
- Snippets ≥ 26 lines: `0`

## Validate

Run the checker from the repo root:

```bash
python3 .site/scripts/check_snippets.py --max-lines 25
```

## Region conventions

- **One concept per region**: if the section is about “where clauses”, the region should show only those calls (plus at most 1–2 context lines).
- **Prefix by topic/page** to keep names discoverable:
  - `intro-*`, `quickstart-*`, `getting-started-*`
  - `models-*`, `queries-*`, `migrations-*`, `guides-*`, `drivers-*`
- **Keep regions stable**: prefer adding a new region over renaming an existing one referenced by docs.
- **Keep regions small**:
  - Target: ≤ 15 non-blank lines
  - Hard limit: 25 non-blank lines (justify exceptions in the surrounding doc section)
- **Avoid setup boilerplate on concept pages**: put bootstrapping only on setup-focused docs (Getting Started, DataSource, Testing) and keep other pages focused.
