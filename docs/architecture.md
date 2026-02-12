# Dash Architecture

Dash is the Pi‑equivalent core used to build an OpenClaw‑like assistant layer.
Keep the core lean and composable; build product UX on top.

## Package Boundaries
1. `dash_ai`: provider SDK and model/runtime types.
2. `dash_agent`: agent loop, events, tool protocol, steering.
3. `dash`: core library (config, permissions, sessions, tool implementations).
4. `dash_cli`: CLI runtime and print‑mode renderer.
5. Assistant UX (TUI/web/server/MCP surfaces) should live in a separate app/package.

## Core Principles
1. Minimal prompt + minimal core tools in `dash_agent`.
2. Extensions/skills add UI and domain behavior, not the core.
3. Sessions are trees; extension state belongs in custom messages.
4. MCP is not a core dependency; integrate via a higher‑level package.

## Non‑Goals (for `dash`)
1. Rich UI (TUI/web) or assistant orchestration UI.
2. Embedded MCP servers/clients.
3. Opinionated assistant workflows (those belong in the higher‑level package).

## References
- https://lucumr.pocoo.org/2026/1/31/pi/
