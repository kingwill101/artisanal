# Widget memory soak

Run from the workspace root. For a short functional smoke:

```sh
dart run pkgs/artisanal_widgets/tool/memory_soak_profile.dart \
  --warmup=1 --batches=2 --iterations=2
```

For the production UV path and profiler artifacts:

```sh
dart run pkgs/artisanal_widgets/tool/memory_soak_profile.dart \
  --warmup=3 --batches=10 --iterations=25 \
  --json-output=build/memory-soak.json \
  --artifact-dir=build/devtools-profiler/memory-soak
```

The workload is deterministic and headless: a bounded `Expanded` scroll view is
scrolled down and back up, a real `Modal` overlay is opened, its input is reset
and typed into, and it is dismissed on every cycle. The harness asserts that
all three interactions occurred and that no widget error screen was rendered.
Renderer output is drained after each interaction cycle and the harness retains
no frame history. The slope uses equal measured batches only. A post-warmup
baseline and a teardown checkpoint are reported separately and excluded from
the slope. The workload function returns before teardown is sampled, dropping
its tester and root references.

`liveBytes`, `classCounts`, and `classBytes` are post-GC allocation-profile values;
without a VM service the harness fails rather than producing an incomplete
report. Profile connection and class aggregation happen in a separate Dart
process (`memory_soak_snapshot.dart`), targeting the workload's explicit isolate
ID. Each sample is written directly to a temporary file. The workload reads
sample history only after teardown measurement: neither maps nor serialized
sample strings accumulate in its heap during the soak.
Classes are keyed by library URI and class name, so same-named classes do not
collapse. `rssBytes` is process RSS and is reported only as capacity/context,
not as retained Dart heap. Two GC requests separated by a short delay allow
the target event loop to run finalizers before the checkpoint. Warmup reduces
startup/cache effects but does not guarantee JIT compilation has stopped.
Inspect growing class counts, repeat runs with identical options, and distinguish
bounded cache growth from objects retained once per interaction. The profiler's
whole-session start/end heap summary includes startup and is not the soak slope.

Do not run the target directly without VM service and expect a report:
`dart run pkgs/artisanal_widgets/tool/memory_soak.dart ...` intentionally exits
non-zero. A direct run can use `dart --enable-vm-service=0 run ...`. The wrapper
propagates profiler failures and does not use `--observe`, which can pause on exit.
Retain reports under `build/` (already ignored) rather than committing them.

For a control run with identical interactions but constant visible counters,
add `--vary-content=0`. The default varies counters, exercising caches with
distinct rendered strings rather than only repeatedly hitting the same keys.

## Measured lifecycle/cache regression

A local JIT run used 3 warmup batches and 10 measured batches of 25 cycles.
Each cycle scrolled down/up and opened, typed into, and dismissed the modal.
The baseline already included the cell/link ownership cleanup; the comparison
isolates the later inherited-dependency cleanup, app teardown, and string-key
cache budgets.

| Post-GC observation | Baseline | With lifecycle/cache fixes |
| --- | --- | --- |
| Live heap, first to last measured batch | 53.10 → 57.66 MiB | 51.86 → 52.77 MiB |
| Fitted live-byte growth per batch | 530,906 bytes | 107,256 bytes |
| `TextField` instances, first to last batch | 101 → 326 | 1 → 1 |
| `TextField` instances after teardown | 326 | 0 |
| Two-byte string storage growth during measured batches | 2.63 MiB | 0 |

The final run released the measured `Cell`, `Buffer`, `TextField`, and
`RenderObjectElement` instances at teardown. One registry slot remained as
identity bookkeeping, without a live link payload. Total live heap did not
become perfectly flat: the remaining growth includes VM code/metadata and
typed data. These results establish removal of the reproduced per-cycle
retention, not a guarantee that every application is leak-free.

Local evidence:

- `build/benchmarks/memory-soak-profiled.json` — baseline.
- `build/benchmarks/memory-soak-static.json` — constant-content control.
- `build/benchmarks/memory-soak-final.json` — fixed, varying-content run.
- Matching CPU/memory artifacts under `build/devtools-profiler/`.

These files are generated and may be absent in a fresh checkout. Repeat the
command above on the same machine with identical settings for new comparisons.
