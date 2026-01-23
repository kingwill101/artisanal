#!/usr/bin/env python3
"""Find Artisanal examples by keyword.

Usage:
  python scripts/example.py list
  python scripts/example.py search <keyword>

Examples:
  python scripts/example.py search dashboard
  python scripts/example.py search textinput
"""

from __future__ import annotations

import os
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
EXAMPLES_DIR = os.path.join(ROOT, "packages", "artisanal", "example")


def iter_example_files() -> list[str]:
    matches: list[str] = []
    for dirpath, _, filenames in os.walk(EXAMPLES_DIR):
        for name in filenames:
            if name.endswith(".dart") or name.endswith(".md") or name.endswith(".gif"):
                path = os.path.join(dirpath, name)
                rel = os.path.relpath(path, ROOT)
                matches.append(rel)
    return sorted(matches)


def list_examples() -> int:
    for path in iter_example_files():
        print(path)
    return 0


def search_examples(keyword: str) -> int:
    keyword_lower = keyword.lower()
    found = [p for p in iter_example_files() if keyword_lower in p.lower()]
    for path in found:
        print(path)
    return 0 if found else 1


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print("Usage: example.py list|search <keyword>")
        return 2

    command = argv[1]
    if command == "list":
        return list_examples()

    if command == "search":
        if len(argv) < 3:
            print("Usage: example.py search <keyword>")
            return 2
        return search_examples(argv[2])

    print(f"Unknown command: {command}")
    return 2


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
