# Evidence Logging

The `evidence-logging` examples show how to emit structured runtime decision
events with `TuiEvidence` and how to parse the resulting JSONL file.

## Custom event example

```bash
dart run pkgs/artisanal/example/tui/examples/evidence-logging/main.dart
```

```bash
dart run pkgs/artisanal/example/tui/examples/evidence-logging/inspect.dart build/evidence-logging.jsonl
```

```bash
dart run pkgs/artisanal/example/tui/examples/evidence-logging/inspect.dart build/evidence-logging.jsonl example.evidence
```

Use this command to summarize parsed decision records:

```bash
dart run pkgs/artisanal/example/tui/examples/evidence-logging/summary.dart build/evidence-logging.jsonl
```

```bash
dart run pkgs/artisanal/example/tui/examples/evidence-logging/summary.dart build/evidence-logging.jsonl example.evidence
```

### Runtime toggle example

```bash
dart run pkgs/artisanal/example/tui/examples/evidence-logging/toggle.dart
dart run pkgs/artisanal/example/tui/examples/evidence-logging/toggle.dart disabled
```

## Render-budget diagnostics example

```bash
dart run pkgs/artisanal/example/tui/examples/evidence-logging/render_budget.dart
```

```bash
dart run pkgs/artisanal/example/tui/examples/evidence-logging/inspect.dart build/evidence-logging-budget.jsonl render_budget
```

```bash
dart run pkgs/artisanal/example/tui/examples/evidence-logging/summary.dart build/evidence-logging-budget.jsonl render_budget
```

```bash
dart run pkgs/artisanal/example/tui/examples/evidence-logging/inspect.dart build/evidence-logging-budget.jsonl
```
