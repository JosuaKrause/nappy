#!/usr/bin/env python3
"""Compare two trees' placement rows: every cell that moved by more than two standard deviations.

Reads the logs `tests/probes/placement_rows.gd` prints (`RD day seeds placed moments`,
`RV day row view count`, `RK day row kind count`, each summed over a sample's cities), one pair per
sample of cities, and a role table (`ROLE day row role`, role 1 a wall and 2 friction) that
`tests/probes/placement_roles.gd` prints once for both trees, since an older tree has no
`EventScheduler.role_for()`.

Rule: a cell is a count summed over the samples' cities; z = (head - main) / sqrt(head + main).
(b) lists every cell with |z| > 2 pooled over all samples; (c) every cell with |z| > 2 on at least
two samples with the same sign. Cells: row x kind of ground, row x view, row x day, view x day,
walls and friction x view x day, walls and friction x view, and the day's whole count. Counts are
per city per day: (count / cities / days), the days being 14 for a whole-run cell and 1 otherwise.

Lines of the logs (a line of another kind is ignored; the runner's other output may be mixed in):
  RD day cities placed moments   the day's whole count; `cities` is the sample's city count
  RV day row view count          view is 0 (on her route), 1 (route-adjacent) or 2 (off the route)
  RK day row kind count          kind of ground
  ROLE day row role              the role table, role 1 a wall and 2 friction (other roles are ignored)

Refused with exit 2, usage or message on stderr and nothing on stdout: an unreadable or non-UTF-8
file; a log without exactly one RD line for each of the days 1 to 14 (cut short, or a day repeated)
or with a malformed or out-of-range line; an RD line whose city count is not
CITIES (so the two logs of a sample agree); a role table with no ROLE line or a malformed one; a
CITIES that is not a positive decimal number.
"""

from __future__ import annotations

import argparse
import collections
import math
import sys
from dataclasses import dataclass
from pathlib import Path

VIEWS = ("on her route", "route-adjacent", "off the route")
ROLE_NAMES = {1: "walls", 2: "friction"}
DAYS = 14
# The whole-run cell families count over every day; the others are per day or per a day's own cell.
Cell = tuple[str, str, str, int]
Counts = collections.Counter[Cell]


@dataclass(frozen=True)
class Sample:
    name: str
    cities: int
    main: Path
    head: Path


class InputError(Exception):
    """A log or an argument the tool cannot read."""


def whole_number(text: str) -> int:
    """A non-negative decimal number written in ASCII digits."""
    if not (text.isascii() and text.isdecimal()):
        raise ValueError(text)
    return int(text)


def read_lines(path: Path) -> list[str]:
    try:
        return path.read_text(encoding="utf-8").splitlines()
    except OSError as exc:
        raise InputError(f"cannot read {path}: {exc.strerror}") from exc
    except UnicodeDecodeError as exc:
        raise InputError(f"{path} is not UTF-8 text") from exc


def read_roles(path: Path) -> dict[tuple[int, str], str]:
    roles: dict[tuple[int, str], str] = {}
    seen = False
    for line in read_lines(path):
        f = line.split()
        if not f or f[0] != "ROLE":
            continue
        try:
            if len(f) != 4:
                raise ValueError(line)
            day, row, role = whole_number(f[1]), f[2], whole_number(f[3])
        except ValueError as exc:
            raise InputError(f"{path}: cannot read the line {line!r}") from exc
        seen = True
        if role in ROLE_NAMES:
            roles[(day, row)] = ROLE_NAMES[role]
    if not seen:
        raise InputError(f"{path} has no ROLE line")
    return roles


def cells(path: Path, roles: dict[tuple[int, str], str], cities: int) -> Counts:
    c: Counts = collections.Counter()
    days_seen: set[int] = set()
    for line in read_lines(path):
        f = line.split()
        if not f:
            continue
        try:
            if f[0] == "RD":
                d = whole_number(f[1])
                if whole_number(f[2]) != cities:
                    raise InputError(f"{path}: the line {line!r} counts {f[2]} cities, not {cities}")
                if d in days_seen:
                    raise InputError(f"{path}: day {d} has more than one RD line")
                days_seen.add(d)
                c[("the day's whole count", "", f"day {d}", 1)] += whole_number(f[3])
            elif f[0] == "RV":
                d, row, v, n = whole_number(f[1]), f[2], whole_number(f[3]), whole_number(f[4])
                if v >= len(VIEWS):
                    raise ValueError(line)
                c[("row by view", row, VIEWS[v], DAYS)] += n
                c[("_row by view and day", row, f"{VIEWS[v]} day {d}", 1)] += n
                c[("row by day", row, f"day {d}", 1)] += n
                c[("view by day", VIEWS[v], f"day {d}", 1)] += n
                role = roles.get((d, row))
                if role:
                    c[(f"{role} by view and day", VIEWS[v], f"day {d}", 1)] += n
                    c[(f"{role} by view", VIEWS[v], "all days", DAYS)] += n
            elif f[0] == "RK":
                c[("row by kind of ground", f[2], f[3], DAYS)] += whole_number(f[4])
        except (ValueError, IndexError) as exc:
            raise InputError(f"{path}: cannot read the line {line!r}") from exc
    if not days_seen:
        raise InputError(f"{path} has no RD line")
    for d in range(1, DAYS + 1):
        if d not in days_seen:
            raise InputError(f"{path}: day {d} has no RD line")
    return c


def z(a: int, b: int) -> float:
    return (b - a) / math.sqrt(a + b) if a + b else 0.0


def fig(a: int, b: int, n: int, days: int) -> str:
    pct = f"{100.0 * (b - a) / a:+.0f}%" if a else "new"
    return f"{a / n / days:.2f} \u2192 {b / n / days:.2f} ({pct}, z {z(a, b):+.1f})"


def report(
    samples: list[Sample],
    roles: dict[tuple[int, str], str],
    main_label: str,
    head_label: str,
) -> list[str]:
    data = [(s, cells(s.main, roles, s.cities), cells(s.head, roles, s.cities)) for s in samples]
    n = sum(s.cities for s, _, _ in data)
    keys: set[Cell] = set()
    for _, a, b in data:
        keys |= set(a) | set(b)
    shown = sorted(k for k in keys if not k[0].startswith("_"))
    pooled: list[tuple[float, str]] = []
    repeated: list[tuple[float, str]] = []
    for key in shown:
        fam, what, where, days = key
        a_sum = sum(d[1][key] for d in data)
        b_sum = sum(d[2][key] for d in data)
        zs = [z(a[key], b[key]) for _, a, b in data]
        line = (
            f"{fam}: {what + ' ' if what else ''}{where}, {fig(a_sum, b_sum, n, days)}; "
            f"z per sample {' / '.join(f'{x:+.1f}' for x in zs)}"
        )
        if abs(z(a_sum, b_sum)) > 2:
            pooled.append((abs(z(a_sum, b_sum)), line))
        if sum(1 for x in zs if x > 2) >= 2 or sum(1 for x in zs if x < -2) >= 2:
            repeated.append((max(abs(x) for x in zs), line))

    def order(item: tuple[float, str]) -> tuple[str, float]:
        return (item[1].split(":")[0], -item[0])

    names = ", ".join(f"{s.name} ({s.cities})" for s, _, _ in data)
    out = [
        f"(b) Outside 2\u03c3 pooled over all {n} cities ({names}), "
        f"events per city per day, {main_label} \u2192 {head_label}:"
    ]
    out += ["- " + line for _, line in sorted(pooled, key=order)]
    out += ["", "(c) Outside 2\u03c3 on at least two samples with the same sign (z per sample in the order of (b)):"]
    out += ["- " + line for _, line in sorted(repeated, key=order)]
    out += ["", f"Summary, pooled over all {n} cities:"]
    for fam in ("walls by view", "friction by view"):
        for v in VIEWS:
            key = (fam, v, "all days", DAYS)
            a_sum = sum(d[1][key] for d in data)
            b_sum = sum(d[2][key] for d in data)
            out.append(f"- {fam}, {v}: {fig(a_sum, b_sum, n, DAYS)}")
    for fam, label in (("row by kind of ground", "each row per kind of ground"), ("row by view", "each row per view")):
        out.append(summarize(fam, label, shown, data))
    out += [
        "",
        f"Cells compared: {len(shown)}. Outside 2\u03c3 pooled: {len(pooled)}. "
        f"Outside on two samples or more, same sign: {len(repeated)}.",
    ]
    return out


def summarize(
    fam: str,
    label: str,
    shown: list[Cell],
    data: list[tuple[Sample, Counts, Counts]],
) -> str:
    changes: list[tuple[float, Cell, bool]] = []
    for key in shown:
        if key[0] != fam:
            continue
        a_sum = sum(d[1][key] for d in data)
        b_sum = sum(d[2][key] for d in data)
        if a_sum:
            changes.append((100.0 * (b_sum - a_sum) / a_sum, key, abs(z(a_sum, b_sum)) > 2))
        elif b_sum:
            changes.append((float("inf"), key, abs(z(a_sum, b_sum)) > 2))
    if not changes:
        return f"- {label}: no cells"
    changes.sort()
    inside = [c for c in changes if not c[2]]
    low, high = changes[0], changes[-1]
    within = f"within 2\u03c3, from {inside[0][0]:+.0f}% to {inside[-1][0]:+.0f}%" if inside else "none within 2\u03c3"
    return (
        f"- {label}: {len(changes)} cells, every cell main or head has, "
        f"from {low[0]:+.0f}% ({low[1][1]} {low[1][2]}) to {high[0]:+.0f}% ({high[1][1]} {high[1][2]}); {within}"
    )


def parse_args(argv: list[str]) -> argparse.Namespace:
    p = argparse.ArgumentParser(
        prog="compare-placement-rows.py",
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=("Example: tools/compare-placement-rows.py --roles roles.log --sample 90210+31i 18 main.log head.log"),
    )
    p.add_argument(
        "--sample",
        nargs=4,
        action="append",
        default=[],
        metavar=("NAME", "CITIES", "MAIN_LOG", "HEAD_LOG"),
        help="one sample of cities with its count and both trees' logs; repeat for more samples",
    )
    p.add_argument("--roles", required=True, metavar="FILE", help="the role table (ROLE lines)")
    p.add_argument("--main-label", default="main", help="what the first log's tree is called in the headings")
    p.add_argument("--head-label", default="head", help="what the second log's tree is called in the headings")
    args = p.parse_args(argv)
    if not args.sample:
        p.error("at least one --sample is required")
    return args


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    samples: list[Sample] = []
    for name, count, main_log, head_log in args.sample:
        if not (count.isascii() and count.isdecimal()) or int(count) < 1:
            print(
                f"compare-placement-rows.py: the city count of {name} is not a positive number: {count}",
                file=sys.stderr,
            )
            return 2
        samples.append(Sample(name, int(count), Path(main_log), Path(head_log)))
    try:
        roles = read_roles(Path(args.roles))
        lines = report(samples, roles, args.main_label, args.head_label)
    except InputError as exc:
        print(f"compare-placement-rows.py: {exc}", file=sys.stderr)
        return 2
    print("\n".join(lines))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
