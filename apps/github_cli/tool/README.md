# GitHub CLI development benchmarks

Run the offline PR conversation scroll benchmark from this package directory:

```sh
dart run tool/github_pull_request_scroll_benchmark.dart \
  --rounds=10 --warmup=3 --steps=40 \
  --out=../../build/benchmarks/github-cli-scroll/timing.json
```

The harness mounts the real `GithubPullRequestView` with the production
Ultraviolet renderer in the alternate screen at `110x34`. It feeds the exact
PR #49 body and five conversation comments from
`tool/fixtures/pr49_scroll.json`; no GitHub or avatar request is made during a
run. It waits for all six Markdown bodies, not just the asynchronously loaded
PR title. Each round sends 40 Down and 40 Up keys through the normal `Program`
pipeline, clearing renderer output after every key without retaining frame
history. Warmup and correctness checks are excluded from timings. The JSON
includes per-round microseconds, mean time per key, dimensions, source hashes,
and scroll movement checks.

All numeric options above are optional; `--columns=N` and `--rows=N` select
other terminal dimensions. `--warmup=0` is supported for smoke tests, not
recommended for performance comparisons. The fixture records source API URLs
and SHA-256 checksums of the fetched responses.

For intermittent stalls, inspect `keyLatencyUs` (p50, p95, p99, and maximum),
not just the mean. The samples cover individual scroll inputs and renderer
output consumption; percentile calculation is outside the timed region.

Match the actual terminal dimensions and whether F12 was open:

```sh
dart run tool/github_pull_request_scroll_benchmark.dart \
  --columns=300 --rows=60 --overlay --rounds=5 --warmup=3 --steps=20 \
  --out=../../build/benchmarks/github-cli-scroll/wide-overlay.json
```

`--overlay` toggles the real Program DevTools overlay. Since that overlay
consumes arrow keys, this mode uses the app's equivalent `j`/`k` bindings
and still verifies that the conversation moves and returns to its starting
position. The JSON records which keys were used. Also run without the overlay
to separate app costs from diagnostics composition.

## CPU profiling

Use `--profile` with `devtools-profiler` to capture the measured rounds in a
named CPU-only region, `github_cli.conversation_scroll`. No terminal flag is
needed for this headless harness:

```sh
devtools-profiler run \
  --artifact-dir=../../build/benchmarks/github-cli-scroll/profile \
  -- dart run tool/github_pull_request_scroll_benchmark.dart \
  --rounds=10 --warmup=3 --steps=40 --profile \
  --out=../../build/benchmarks/github-cli-scroll/profile-timing.json
```

Compare identical fixtures, dimensions, key counts, and warmup settings.
Profiler overhead changes absolute timings: do not compare a profiled run to
an unprofiled run. Recursive layout frames can occur several times in one CPU
stack; count each sample once when interpreting inclusive percentages.

## Retained heap

Run forced-GC measurements separately from CPU profiling:

```sh
dart --enable-vm-service=0 run tool/github_pull_request_scroll_benchmark.dart \
  --rounds=10 --warmup=3 --steps=40 \
  --heap-dir=../../build/benchmarks/github-cli-scroll/heap \
  --out=../../build/benchmarks/github-cli-scroll/heap-timing.json
```

This reuses the widget memory-soak collector in a separate process. It
requests two GCs separated by an event-loop yield, then writes class counts
and bytes after warmup, after each round, and after widget teardown.
Collection time is excluded from the stopwatch; parsed heap reports are
never retained in the workload process. `--heap-dir` requires the VM service
and cannot be combined with `--profile`.

These checkpoints distinguish retained growth from cold-start JIT work,
loaded document state, and garbage awaiting collection. A normal profiler
session's startup-to-exit memory delta is not a post-GC leak measurement.

## PR #49 scrolling result

Local Linux/Dart 3.13.1 comparison against commit `5aab080b`, using the same
offline fixture at `110x34`, three warmup rounds and ten measured rounds
(800 keys):

| Measurement | Before | Scroll-layout reuse + lazy cell tokens |
|---|---:|---:|
| Unprofiled mean per key | 19.04 ms | 13.09 ms |
| Profiled measured region | 26.85 s | 19.04 s |
| Post-GC heap after warmup | 63.26 MiB | 62.32 MiB |
| Post-GC heap after 800 keys | 63.75 MiB | 62.88 MiB |
| Cells after warmup / 800 keys | 7,481 / 7,481 | 7,481 / 7,481 |
| Cells after teardown | 0 | 0 |
| Two-byte strings after warmup / 800 keys | 2,764 / 2,764 | 2,693 / 2,692 |

This run shows about 31% lower time per key. Both versions had stable
post-GC cell/string counts; neither demonstrated an accumulating frame leak
in this repeated workload. The remaining total-heap change is not zero and
the result is not a claim about all documents, dimensions, or interactions.
Local reports and CPU artifacts are under `build/benchmarks/github-cli-scroll`
at the workspace root (generated, not committed).

### Large-window composition follow-up

The next comparison kept the scroll-layout and lazy-token fixes on both sides.
It used `300x60`, F12 enabled, three warmup rounds, five measured rounds, and
20 steps each direction (200 inputs). With F12 enabled the harness uses `j/k`
to scroll the conversation, not the overlay's arrow-key-controlled log list.

| Per-input latency | Before composition changes | Direct composition + metadata reuse |
|---|---:|---:|
| Mean | 40.86 ms | 29.23 ms |
| p50 | 38.59 ms | 28.61 ms |
| p95 | 60.86 ms | 33.17 ms |
| p99 | 69.97 ms | 43.82 ms |
| Maximum | 72.22 ms | 51.69 ms |

This is an additional large-window comparison, not the same workload as the
`110x34` table above. The optimized path avoids redundant background-cell
clones, the full-size container's temporary grid and per-cell copy, and dirty
metadata replacements for ranges already covered by a dirty span.
Unsupported controls/graphics and nonmatching geometry use the established
composition path. Mean and tail latency improved, but these numbers do not
claim stall-free rendering at every terminal size.

Reports: `composition-before-wide-overlay.json`,
`composition-after-wide-overlay.json` (fill/metadata changes only), and
`composition-direct-wide-overlay.json` in the workspace-root benchmark folder.
