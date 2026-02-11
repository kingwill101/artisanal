#!/usr/bin/env bash
set -euo pipefail

EXECUTABLE="${EXECUTABLE:-./bin/command_center.exe}"
OUTPUT_DIR="${OUTPUT_DIR:-generated_files}"
DURATION="${DURATION:-10}"          # Total seconds to record
GEOMETRY="${GEOMETRY:-80x24}"       # Terminal size
MIN_FRAME_MS="${MIN_FRAME_MS:-1}"   # Capture every update
FPS="${FPS:-30}"                    # GIF frame rate
TEMPLATE="${TEMPLATE:-}"            # Optional termtosvg template name

FRAMES_SVG_DIR="$OUTPUT_DIR/frames_svg"
FRAMES_PNG_DIR="$OUTPUT_DIR/frames_png"
PALETTE_PNG="$OUTPUT_DIR/palette.png"
OUTPUT_GIF="$OUTPUT_DIR/artisanal_demo.gif"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing dependency: $1"
    exit 1
  fi
}

require_cmd termtosvg
require_cmd rsvg-convert
require_cmd ffmpeg

mkdir -p "$FRAMES_SVG_DIR" "$FRAMES_PNG_DIR"
rm -f "$FRAMES_SVG_DIR"/*.svg "$FRAMES_PNG_DIR"/frame*.png "$PALETTE_PNG" "$OUTPUT_GIF"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTE_COMPAT_DIR="$SCRIPT_DIR/tools/pyte_compat"

record_cmd=(termtosvg -s -g "$GEOMETRY" -m "$MIN_FRAME_MS")
if [[ -n "$TEMPLATE" ]]; then
  record_cmd+=(-t "$TEMPLATE")
fi
record_cmd+=(-c "$EXECUTABLE" "$FRAMES_SVG_DIR")

echo "Recording $EXECUTABLE for ${DURATION}s..."
if command -v timeout >/dev/null 2>&1; then
  set +e
  PYTHONPATH="$PYTE_COMPAT_DIR:${PYTHONPATH:-}" \
    TERM=xterm-256color COLORTERM=truecolor FORCE_COLOR=1 \
    timeout "${DURATION}s" "${record_cmd[@]}"
  timeout_status=$?
  set -e
  if [[ $timeout_status -ne 0 && $timeout_status -ne 124 ]]; then
    exit "$timeout_status"
  fi
else
  PYTHONPATH="$PYTE_COMPAT_DIR:${PYTHONPATH:-}" \
    TERM=xterm-256color COLORTERM=truecolor FORCE_COLOR=1 \
    "${record_cmd[@]}" &
  RECORD_PID=$!
  sleep "$DURATION"
  kill "$RECORD_PID" 2>/dev/null || true
fi

echo "Converting SVG frames to PNG..."
shopt -s nullglob
idx=0
for svg in "$FRAMES_SVG_DIR"/*.svg; do
  printf -v png "%s/frame%05d.png" "$FRAMES_PNG_DIR" "$idx"
  rsvg-convert -o "$png" "$svg"
  idx=$((idx + 1))
done
shopt -u nullglob

echo "Building GIF..."
ffmpeg -y -framerate "$FPS" -i "$FRAMES_PNG_DIR/frame%05d.png" -vf palettegen -frames:v 1 -update 1 "$PALETTE_PNG"
ffmpeg -y -framerate "$FPS" -i "$FRAMES_PNG_DIR/frame%05d.png" -i "$PALETTE_PNG" -lavfi paletteuse "$OUTPUT_GIF"

rm -f "$PALETTE_PNG"

echo "Recording complete. Frames in $FRAMES_SVG_DIR and GIF at $OUTPUT_GIF."
