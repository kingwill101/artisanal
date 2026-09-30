#!/bin/sh
printf '%s\n' "$@" > "$0.args"
printf '%s\n' "$$" > "$0.pid"
if test -f "$0.stall"; then exec /bin/sleep 30; fi
printf 'discarded output\n'
printf 'discarded error\n' >&2
exit 0
