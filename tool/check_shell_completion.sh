#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
fixture="$repo_root/pkgs/artisanal/tool/shell_completion_smoke.dart"
binary_name="artisanal-shell-smoke"

for command_name in dart bash zsh; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Required command not found: $command_name" >&2
    exit 1
  fi
done

temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/artisanal-shell-completion.XXXXXX")"
cleanup() {
  rm -rf -- "$temp_dir"
}
trap cleanup EXIT

web_output="$temp_dir/$binary_name.js"
native_output="$temp_dir/$binary_name"

dart compile js "$fixture" -o "$web_output"
dart compile exe "$fixture" -o "$native_output"

completion_script="$($native_output --completion-script)"
printf '%s\n' "$completion_script" | bash -n
printf '%s\n' "$completion_script" | zsh -n

printf '%s\n' "$completion_script" |
  BINARY_NAME="$binary_name" bash --noprofile --norc -c \
    'source /dev/stdin; complete -p "$BINARY_NAME" >/dev/null'

expected_function="__${binary_name//./_}_completion"
printf '%s\n' "$completion_script" |
  BINARY_NAME="$binary_name" EXPECTED_FUNCTION="$expected_function" \
    zsh -f -c \
      'autoload -Uz compinit && compinit; source /dev/stdin; (( $+functions[$EXPECTED_FUNCTION] )) && (( $+_comps[$BINARY_NAME] ))'

if ! grep -Fq "###-begin-$binary_name-completion-###" <<<"$completion_script"; then
  echo "Generated completion script does not target $binary_name." >&2
  exit 1
fi

completion_line="$binary_name he"
completion_output="$(
  COMP_CWORD=1 \
  COMP_LINE="$completion_line" \
  COMP_POINT="${#completion_line}" \
    "$native_output" completion -- "$binary_name" he
)"

if ! grep -Fxq 'hello' <<<"$completion_output"; then
  echo "Completion protocol did not suggest the hello command." >&2
  printf '%s\n' "$completion_output" >&2
  exit 1
fi

echo "Shell completion smoke check passed for JavaScript, native AOT, Bash, and Zsh."
