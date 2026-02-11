#!/usr/bin/env python3

from __future__ import annotations

import argparse
import csv
import math
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Sequence, TypeVar


@dataclass(frozen=True)
class DispatchEvent:
    line: int
    msg_id: int
    msg_type: str
    duration_us: int


@dataclass(frozen=True)
class RenderEvent:
    line: int
    duration_us: int


@dataclass(frozen=True)
class LayoutCounterEvent:
    line: int
    get_width_count: int
    get_width_us: int
    get_height_count: int
    get_height_us: int
    visible_length_count: int
    visible_length_us: int
    pad_count: int
    pad_us: int


@dataclass(frozen=True)
class TextInputViewEvent:
    line: int
    length: int
    duration_us: int


DISPATCH_RE = re.compile(r"\[dispatch\] msg#(\d+) (\w+) (\d+)us")
RENDER_RE = re.compile(r"element_tree\.render .* (\d+)us")
COUNTERS_RE = re.compile(
    r"layout\.counters "
    r"getWidth=(\d+)/(\d+)us "
    r"getHeight=(\d+)/(\d+)us "
    r"visibleLength=(\d+)/(\d+)us "
    r"pad=(\d+)/(\d+)us"
)
TEXT_VIEW_RE = re.compile(r"TextInputModel\.view len=(\d+) .* (\d+)us")


def percentile(sorted_values: list[int], p: float) -> float:
    if not sorted_values:
        return 0.0
    if len(sorted_values) == 1:
        return float(sorted_values[0])
    idx = (len(sorted_values) - 1) * p
    low = math.floor(idx)
    high = math.ceil(idx)
    if low == high:
        return float(sorted_values[low])
    return sorted_values[low] * (high - idx) + sorted_values[high] * (idx - low)


def summarize(values_us: list[int]) -> dict[str, float]:
    if not values_us:
        return {
            "count": 0,
            "avg": 0.0,
            "p50": 0.0,
            "p95": 0.0,
            "p99": 0.0,
            "max": 0.0,
        }
    ordered = sorted(values_us)
    count = len(ordered)
    return {
        "count": float(count),
        "avg": sum(ordered) / count,
        "p50": percentile(ordered, 0.50),
        "p95": percentile(ordered, 0.95),
        "p99": percentile(ordered, 0.99),
        "max": float(ordered[-1]),
    }


def pearson(xs: list[float], ys: list[float]) -> float:
    if len(xs) != len(ys) or len(xs) < 2:
        return 0.0
    mean_x = sum(xs) / len(xs)
    mean_y = sum(ys) / len(ys)
    numerator = sum((x - mean_x) * (y - mean_y) for x, y in zip(xs, ys))
    denom_x = sum((x - mean_x) ** 2 for x in xs)
    denom_y = sum((y - mean_y) ** 2 for y in ys)
    denom = math.sqrt(denom_x * denom_y)
    if denom == 0:
        return 0.0
    return numerator / denom


T = TypeVar("T")


def latest_before_line(events: Sequence[tuple[int, T]], line: int) -> T | None:
    low = 0
    high = len(events)
    while low < high:
        mid = (low + high) // 2
        if events[mid][0] <= line:
            low = mid + 1
        else:
            high = mid
    if low == 0:
        return None
    return events[low - 1][1]


def find_latest_trace(traces_dir: Path) -> Path:
    candidates = sorted(traces_dir.glob("*.log"), key=lambda p: p.stat().st_mtime)
    if not candidates:
        raise FileNotFoundError(f"No .log files in {traces_dir}")
    return candidates[-1]


def find_matching_traces(traces_dir: Path, pattern: str) -> list[Path]:
    return sorted(traces_dir.glob(pattern), key=lambda p: p.stat().st_mtime)


def parse_trace(trace_path: Path) -> tuple[
    list[DispatchEvent],
    list[RenderEvent],
    list[LayoutCounterEvent],
    list[TextInputViewEvent],
]:
    dispatch: list[DispatchEvent] = []
    renders: list[RenderEvent] = []
    counters: list[LayoutCounterEvent] = []
    text_views: list[TextInputViewEvent] = []

    for line_num, line in enumerate(trace_path.read_text().splitlines(), start=1):
        match = DISPATCH_RE.search(line)
        if match:
            dispatch.append(
                DispatchEvent(
                    line=line_num,
                    msg_id=int(match.group(1)),
                    msg_type=match.group(2),
                    duration_us=int(match.group(3)),
                )
            )

        match = RENDER_RE.search(line)
        if match:
            renders.append(RenderEvent(line=line_num, duration_us=int(match.group(1))))

        match = COUNTERS_RE.search(line)
        if match:
            counters.append(
                LayoutCounterEvent(
                    line=line_num,
                    get_width_count=int(match.group(1)),
                    get_width_us=int(match.group(2)),
                    get_height_count=int(match.group(3)),
                    get_height_us=int(match.group(4)),
                    visible_length_count=int(match.group(5)),
                    visible_length_us=int(match.group(6)),
                    pad_count=int(match.group(7)),
                    pad_us=int(match.group(8)),
                )
            )

        match = TEXT_VIEW_RE.search(line)
        if match:
            text_views.append(
                TextInputViewEvent(
                    line=line_num,
                    length=int(match.group(1)),
                    duration_us=int(match.group(2)),
                )
            )

    return dispatch, renders, counters, text_views


def print_stats_row(label: str, metrics: dict[str, float]) -> None:
    print(
        f"{label:<22} "
        f"n={int(metrics['count']):>4} "
        f"avg={metrics['avg'] / 1000:>8.2f}ms "
        f"p95={metrics['p95'] / 1000:>8.2f}ms "
        f"max={metrics['max'] / 1000:>8.2f}ms"
    )


def format_ms(value_us: float) -> str:
    return f"{value_us / 1000:.2f}ms"


def format_delta_us(delta_us: float) -> str:
    sign = "+" if delta_us >= 0 else "-"
    return f"{sign}{abs(delta_us) / 1000:.2f}ms"


def collect_summary_metrics(
    dispatch: list[DispatchEvent],
    renders: list[RenderEvent],
    counters: list[LayoutCounterEvent],
    text_views: list[TextInputViewEvent],
) -> dict[str, float]:
    by_type: dict[str, list[int]] = {}
    for event in dispatch:
        by_type.setdefault(event.msg_type, []).append(event.duration_us)

    key_values = by_type.get("KeyMsg", [])
    mouse_values = by_type.get("MouseMsg", [])
    wheel_values = by_type.get("_VirtualListWheelTickMsg", [])

    key_stats = summarize(key_values)
    key_ex_stats = summarize(sorted(key_values)[:-1]) if len(key_values) > 1 else summarize([])
    mouse_stats = summarize(mouse_values)
    wheel_stats = summarize(wheel_values)

    render_stats = summarize([event.duration_us for event in renders])
    width_stats = summarize([event.get_width_us for event in counters])
    visible_stats = summarize([event.visible_length_us for event in counters])
    text_stats = summarize([event.duration_us for event in text_views])

    return {
        "key_avg": key_stats["avg"],
        "key_p95": key_stats["p95"],
        "key_max": key_stats["max"],
        "key_excluding_max_avg": key_ex_stats["avg"],
        "key_excluding_max_p95": key_ex_stats["p95"],
        "mouse_avg": mouse_stats["avg"],
        "mouse_p95": mouse_stats["p95"],
        "wheel_avg": wheel_stats["avg"],
        "wheel_p95": wheel_stats["p95"],
        "render_avg": render_stats["avg"],
        "render_p95": render_stats["p95"],
        "render_max": render_stats["max"],
        "get_width_avg": width_stats["avg"],
        "get_width_p95": width_stats["p95"],
        "visible_length_avg": visible_stats["avg"],
        "visible_length_p95": visible_stats["p95"],
        "text_view_avg": text_stats["avg"],
        "text_view_p95": text_stats["p95"],
    }


def load_summary_metrics(trace_path: Path) -> dict[str, float]:
    dispatch, renders, counters, text_views = parse_trace(trace_path)
    return collect_summary_metrics(dispatch, renders, counters, text_views)


def analyze_trace(trace_path: Path, top_n: int) -> None:
    dispatch, renders, counters, text_views = parse_trace(trace_path)

    print(f"Trace: {trace_path}")
    print()
    print("Message stats")
    by_type: dict[str, list[int]] = {}
    for event in dispatch:
        by_type.setdefault(event.msg_type, []).append(event.duration_us)
    for msg_type in sorted(by_type):
        print_stats_row(msg_type, summarize(by_type[msg_type]))

    key_events = [event for event in dispatch if event.msg_type == "KeyMsg"]
    key_values = [event.duration_us for event in key_events]

    if key_events:
        print()
        print("KeyMsg focus")
        print_stats_row("KeyMsg all", summarize(key_values))
        if len(key_values) > 1:
            print_stats_row("KeyMsg excluding max", summarize(sorted(key_values)[:-1]))

        print()
        print(f"Top {top_n} slowest KeyMsg with nearby render/layout")
        render_indexed = [(event.line, event) for event in renders]
        counter_indexed = [(event.line, event) for event in counters]
        text_view_indexed = [(event.line, event) for event in text_views]

        for event in sorted(key_events, key=lambda e: e.duration_us, reverse=True)[:top_n]:
            render_event = latest_before_line(render_indexed, event.line)
            counter_event = latest_before_line(counter_indexed, event.line)
            text_event = latest_before_line(text_view_indexed, event.line)

            render_ms = "n/a"
            if isinstance(render_event, RenderEvent):
                render_ms = f"{render_event.duration_us / 1000:.2f}ms"

            get_width = "n/a"
            visible_length = "n/a"
            if isinstance(counter_event, LayoutCounterEvent):
                get_width = f"{counter_event.get_width_us / 1000:.2f}ms"
                visible_length = f"{counter_event.visible_length_us / 1000:.2f}ms"

            text_view = "n/a"
            if isinstance(text_event, TextInputViewEvent):
                text_view = f"len={text_event.length} cost={text_event.duration_us}us"

            print(
                f"msg#{event.msg_id:<4} line={event.line:<7} "
                f"dur={event.duration_us / 1000:>8.2f}ms "
                f"render={render_ms:>9} "
                f"getWidth={get_width:>9} "
                f"visibleLength={visible_length:>9} "
                f"textView={text_view}"
            )

        if text_views:
            print()
            print("KeyMsg vs text length")
            text_view_indexed = [(event.line, event) for event in text_views]
            pairs: list[tuple[int, int]] = []
            for event in key_events:
                text_event = latest_before_line(text_view_indexed, event.line)
                if isinstance(text_event, TextInputViewEvent) and text_event.length > 0:
                    pairs.append((text_event.length, event.duration_us))

            if pairs:
                lengths = [float(length) for length, _ in pairs]
                durations = [float(duration) for _, duration in pairs]
                print(f"pairs={len(pairs)} corr(length, key_duration)={pearson(lengths, durations):.3f}")

                bucket_size = 50
                max_len = max(length for length, _ in pairs)
                for bucket_start in range(1, max_len + 1, bucket_size):
                    bucket_end = bucket_start + bucket_size - 1
                    bucket = [
                        duration
                        for length, duration in pairs
                        if bucket_start <= length <= bucket_end
                    ]
                    if not bucket:
                        continue
                    bucket_stats = summarize(bucket)
                    print(
                        f"len {bucket_start:>3}-{bucket_end:>3} "
                        f"n={int(bucket_stats['count']):>4} "
                        f"avg={bucket_stats['avg'] / 1000:>8.2f}ms "
                        f"p95={bucket_stats['p95'] / 1000:>8.2f}ms "
                        f"max={bucket_stats['max'] / 1000:>8.2f}ms"
                    )

    if renders:
        print()
        print("Render and layout stats")
        print_stats_row("element_tree.render", summarize([event.duration_us for event in renders]))

    if counters:
        print_stats_row("layout.getWidth", summarize([event.get_width_us for event in counters]))
        print_stats_row(
            "layout.visibleLength",
            summarize([event.visible_length_us for event in counters]),
        )

    if text_views:
        print()
        print("TextInputModel.view stats")
        print_stats_row("TextInputModel.view", summarize([event.duration_us for event in text_views]))


def compare_traces(base_trace: Path, target_trace: Path) -> None:
    base = load_summary_metrics(base_trace)
    target = load_summary_metrics(target_trace)

    rows = [
        ("Key avg", "key_avg"),
        ("Key p95", "key_p95"),
        ("Key max", "key_max"),
        ("Key avg (ex max)", "key_excluding_max_avg"),
        ("Key p95 (ex max)", "key_excluding_max_p95"),
        ("Mouse avg", "mouse_avg"),
        ("Mouse p95", "mouse_p95"),
        ("Wheel avg", "wheel_avg"),
        ("Wheel p95", "wheel_p95"),
        ("Render avg", "render_avg"),
        ("Render p95", "render_p95"),
        ("layout.getWidth avg", "get_width_avg"),
        ("layout.getWidth p95", "get_width_p95"),
        ("layout.visibleLength avg", "visible_length_avg"),
        ("layout.visibleLength p95", "visible_length_p95"),
        ("TextInputModel.view avg", "text_view_avg"),
        ("TextInputModel.view p95", "text_view_p95"),
    ]

    print(f"Base:   {base_trace}")
    print(f"Target: {target_trace}")
    print()
    print("Comparison (lower is better)")
    print(f"{'Metric':<24} {'Base':>10} {'Target':>10} {'Delta':>10} {'Delta%':>9}")
    for label, key in rows:
        base_value = base.get(key, 0.0)
        target_value = target.get(key, 0.0)
        delta = target_value - base_value
        if abs(base_value) < 500.0:
            delta_pct_display = "      n/a"
        else:
            delta_pct = (delta / base_value) * 100.0
            pct_sign = "+" if delta_pct >= 0 else ""
            delta_pct_display = f"{pct_sign}{delta_pct:>8.1f}%"
        print(
            f"{label:<24} "
            f"{format_ms(base_value):>10} "
            f"{format_ms(target_value):>10} "
            f"{format_delta_us(delta):>10} "
            f"{delta_pct_display}"
        )


def list_recent_traces(traces_dir: Path, limit: int) -> None:
    files = sorted(traces_dir.glob("*.log"), key=lambda p: p.stat().st_mtime, reverse=True)
    selected = files[: max(1, limit)]
    if not selected:
        print(f"No traces found in {traces_dir}")
        return

    print(f"Recent traces ({len(selected)}/{len(files)} shown)")
    print(f"{'Trace':<36} {'Key avg':>8} {'Key p95':>8} {'Mouse p95':>9} {'Render p95':>10}")
    for trace in selected:
        metrics = load_summary_metrics(trace)
        print(
            f"{trace.name:<36} "
            f"{metrics['key_avg'] / 1000:>8.2f} "
            f"{metrics['key_p95'] / 1000:>8.2f} "
            f"{metrics['mouse_p95'] / 1000:>9.2f} "
            f"{metrics['render_p95'] / 1000:>10.2f}"
        )


def export_csv(
    output_path: Path,
    traces: list[Path],
) -> None:
    if not traces:
        raise FileNotFoundError("No traces selected for CSV export")

    fields = [
        "trace",
        "key_avg_ms",
        "key_p95_ms",
        "key_max_ms",
        "key_excluding_max_avg_ms",
        "key_excluding_max_p95_ms",
        "mouse_avg_ms",
        "mouse_p95_ms",
        "wheel_avg_ms",
        "wheel_p95_ms",
        "render_avg_ms",
        "render_p95_ms",
        "render_max_ms",
        "layout_get_width_avg_ms",
        "layout_get_width_p95_ms",
        "layout_visible_length_avg_ms",
        "layout_visible_length_p95_ms",
        "text_input_view_avg_ms",
        "text_input_view_p95_ms",
    ]

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("w", newline="") as file:
        writer = csv.DictWriter(file, fieldnames=fields)
        writer.writeheader()
        for trace in traces:
            metrics = load_summary_metrics(trace)
            writer.writerow(
                {
                    "trace": trace.name,
                    "key_avg_ms": f"{metrics['key_avg'] / 1000:.4f}",
                    "key_p95_ms": f"{metrics['key_p95'] / 1000:.4f}",
                    "key_max_ms": f"{metrics['key_max'] / 1000:.4f}",
                    "key_excluding_max_avg_ms": f"{metrics['key_excluding_max_avg'] / 1000:.4f}",
                    "key_excluding_max_p95_ms": f"{metrics['key_excluding_max_p95'] / 1000:.4f}",
                    "mouse_avg_ms": f"{metrics['mouse_avg'] / 1000:.4f}",
                    "mouse_p95_ms": f"{metrics['mouse_p95'] / 1000:.4f}",
                    "wheel_avg_ms": f"{metrics['wheel_avg'] / 1000:.4f}",
                    "wheel_p95_ms": f"{metrics['wheel_p95'] / 1000:.4f}",
                    "render_avg_ms": f"{metrics['render_avg'] / 1000:.4f}",
                    "render_p95_ms": f"{metrics['render_p95'] / 1000:.4f}",
                    "render_max_ms": f"{metrics['render_max'] / 1000:.4f}",
                    "layout_get_width_avg_ms": f"{metrics['get_width_avg'] / 1000:.4f}",
                    "layout_get_width_p95_ms": f"{metrics['get_width_p95'] / 1000:.4f}",
                    "layout_visible_length_avg_ms": f"{metrics['visible_length_avg'] / 1000:.4f}",
                    "layout_visible_length_p95_ms": f"{metrics['visible_length_p95'] / 1000:.4f}",
                    "text_input_view_avg_ms": f"{metrics['text_view_avg'] / 1000:.4f}",
                    "text_input_view_p95_ms": f"{metrics['text_view_p95'] / 1000:.4f}",
                }
            )

    print(f"Wrote {len(traces)} traces to {output_path}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Analyze artisanal trace logs")
    parser.add_argument(
        "trace",
        nargs="?",
        help="Target trace path. Defaults to latest log in traces/.",
    )
    parser.add_argument(
        "--top",
        type=int,
        default=10,
        help="Number of slowest KeyMsg rows to show.",
    )
    parser.add_argument(
        "--compare",
        metavar="BASE_TRACE",
        help=(
            "Compare BASE_TRACE against target trace. "
            "Target defaults to latest trace when positional trace is omitted."
        ),
    )
    parser.add_argument(
        "--list",
        action="store_true",
        help="List recent traces with quick latency summary.",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=10,
        help="Maximum traces shown by --list.",
    )
    parser.add_argument(
        "--csv",
        metavar="OUTPUT_CSV",
        help=(
            "Export summary metrics to CSV. Uses all traces in traces/ by default, "
            "or the positional trace when provided."
        ),
    )
    parser.add_argument(
        "--glob",
        default="*.log",
        help="Glob pattern for selecting traces when using --csv (default: *.log).",
    )
    args = parser.parse_args()

    default_traces_dir = Path(__file__).parent / "traces"

    if args.csv:
        if args.trace:
            selected_traces = [Path(args.trace)]
        else:
            selected_traces = find_matching_traces(default_traces_dir, args.glob)
        export_csv(output_path=Path(args.csv), traces=selected_traces)
        return 0

    if args.list:
        list_recent_traces(default_traces_dir, limit=max(1, args.limit))
        return 0

    target_trace = Path(args.trace) if args.trace else find_latest_trace(default_traces_dir)
    if args.compare:
        compare_traces(base_trace=Path(args.compare), target_trace=target_trace)
        return 0

    analyze_trace(target_trace, top_n=max(1, args.top))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
