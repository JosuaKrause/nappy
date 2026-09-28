#!/usr/bin/env python3
"""Every telemetry kind the code writes has a row in `docs/TELEMETRY.md`, and every row is still written.

The table in `docs/TELEMETRY.md`, "The entry kinds", is how a reader learns what a line of a run log
means. `chat` was written by `EventManager` with no row there for a whole milestone before anybody
noticed, because nothing compared the two lists. There is no enumeration of kinds in the code to
compare with instead (`TelemetryLog.note()` takes any `String`), so this reads both sides the way a
person auditing the drift by hand would, and requires them to be exactly equal: a kind written and
undocumented, or documented and never written, both fail.

- **Written**: every `Telemetry.note(<kind>, ...)` call under `src/`, and the bare `note(<kind>, ...)`
  it becomes inside `src/autoload/telemetry.gd` itself. The kind is everything up to the first
  comma after the open parenthesis, and every double-quoted `[a-z_]+` literal in it counts, so a
  call that picks its kind at runtime from two literals (`"calm" if calm else "left"`) names both.
  Scanned one line at a time, since `[^,]*` has no bound on a newline and would run on past a
  definition with no comma on its line; a `#` comment line is skipped, and so is a bare `note(`
  whose argument holds a `:`, which is the definition `func note(kind: String, ...)`.
- **Documented**: every backticked `[a-z_]+` in the first cell of a table line that opens with
  ``| `kind` ``, so a backticked word in the "Answers" prose is never taken for a row.

It is a check of the repository's own consistency, not of the game, so it runs on every pull
request, a docs-only one included; it needs nothing but Python.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
QUALIFIED = re.compile(r"Telemetry\.note\(([^,]*),")
BARE = re.compile(r"(?<![\w.])note\(([^,]*),")
LITERAL = re.compile(r"\"([a-z_]+)\"")
DOC_WORD = re.compile(r"`([a-z_]+)`")

EPILOG = """\
examples:
  uv run python tools/ci_telemetry_kinds.py
"""


def kinds_written(sources: dict[str, str]) -> set[str]:
    kinds: set[str] = set()
    for text in sources.values():
        for line in text.splitlines():
            if line.strip().startswith("#"):
                continue
            for call in QUALIFIED.finditer(line):
                kinds.update(LITERAL.findall(call.group(1)))
            for call in BARE.finditer(line):
                argument = call.group(1)
                if ":" in argument:
                    continue
                kinds.update(LITERAL.findall(argument))
    return kinds


def kinds_documented(table: str) -> set[str]:
    kinds: set[str] = set()
    for line in table.splitlines():
        if not line.startswith("| `"):
            continue
        kinds.update(DOC_WORD.findall(line.split("|")[1]))
    return kinds


def check(sources: dict[str, str], table: str) -> list[str]:
    written = kinds_written(sources)
    documented = kinds_documented(table)
    failures: list[str] = []
    # A guard that the scan was not vacuous: a pattern that stopped matching would pass both sets empty.
    if len(written) <= 10:
        failures.append(f"src/: the scan found only {len(written)} telemetry kind(s) written; the pattern broke")
    if len(documented) <= 10:
        failures.append(f"docs/TELEMETRY.md: the scan found only {len(documented)} row(s); the table's shape moved")
    for missing in sorted(written - documented):
        failures.append(f"docs/TELEMETRY.md: the code writes the kind `{missing}` and the table has no row for it")
    for stale in sorted(documented - written):
        failures.append(f"docs/TELEMETRY.md: the table has a row for `{stale}` and nothing under src/ writes it")
    return failures


def gd_sources(root: Path) -> dict[str, str]:
    sources: dict[str, str] = {}
    for path in sorted((root / "src").rglob("*.gd")):
        relative = path.relative_to(root)
        if any(part.startswith(".") for part in relative.parts):
            continue
        sources[str(relative)] = path.read_text(encoding="utf-8")
    return sources


def parse(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="tools/ci_telemetry_kinds.py",
        description=(
            'Fails unless the telemetry kinds written under src/ (Telemetry.note("kind", ...)) and the rows'
            " of docs/TELEMETRY.md's entry-kinds table are the same set. Takes no arguments."
        ),
        epilog=EPILOG,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    parse(argv)
    failures = check(gd_sources(ROOT), (ROOT / "docs" / "TELEMETRY.md").read_text(encoding="utf-8"))
    for failure in failures:
        print(f"FAILED: {failure}")
    if failures:
        return 1
    print("OK: every telemetry kind the code writes has a row in docs/TELEMETRY.md, and every row is written")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
