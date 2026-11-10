#!/usr/bin/env python3
"""What this repository's Claude Code sessions and sub-agents used, over date windows.

Reads every transcript under ~/.claude/projects/<dir>*/**/*.jsonl, where <dir> is the repository's
absolute path with every character that is not a letter or digit replaced by '-' (the repository's
worktrees' sessions share that prefix). Sub-agents are <session>/subagents/agent-*.jsonl with a
.meta.json beside (description, model). Per assistant turn, deduplicated by message id, the tool
takes the timestamp, model id (the harness's '<synthetic>' placeholders are skipped) and the usage
counts; a turn belongs to the window its own timestamp falls in, so a long session is split across windows.

Two measures per turn: weighted tokens (input 1, 5-minute cache write 1.25, 1-hour write 2, cache
read 0.1, output 5) and API-price dollars from PRICES below. The data is read, never written
into the repository; --save writes under ~/.claude/nappy-agent-stats/usage/<today>/.
"""

from __future__ import annotations

import argparse
import json
import re
import statistics
import subprocess
import sys
from collections.abc import Callable, Iterable
from dataclasses import dataclass, field
from datetime import UTC, datetime, timedelta
from itertools import pairwise
from pathlib import Path
from typing import Any

# Weighted-token units, the same as the hand-made reference report so its numbers compare.
W_INPUT = 1.0
W_WRITE_5M = 1.25
W_WRITE_1H = 2.0
W_READ = 0.1
W_OUTPUT = 5.0

# Dollars per million tokens: (input, output, cache read). A cache write costs 1.25x input for five
# minutes and 2x for one hour. From the Claude API reference cached 2026-11-03. A model with no
# entry is counted in tokens and listed as unpriced, never guessed.
PRICE_DATE = "2026-11-03"
Price = tuple[float, float, float]
PRICES: dict[str, Price] = {
    "claude-fable-5-2": (8.0, 40.0, 0.20),
    "claude-opus-5-5": (4.0, 20.0, 0.20),
    "claude-sonnet-5-5": (2.0, 10.0, 0.10),
    "claude-haiku-5-5": (0.10, 0.50, 0.01),
}
# Prices that are estimates rather than read from the reference (Haiku's cache read: a tenth of input).
ESTIMATED_PRICES = {"claude-haiku-5-5": "cache read"}
FAMILIES = ("fable", "opus", "sonnet", "haiku")

# The harness's own placeholder messages (no API call, no usage worth counting) are skipped.
SYNTHETIC_MODEL = "<synthetic>"
REWRITE_GAP_SECONDS = 300  # a pause this long lets the prompt cache expire
REWRITE_SHARE = 0.5  # a rewrite writes more than this share of its context
REWRITE_MIN_CONTEXT = 20000
LONG_TURNS = 150
LONG_CONTEXT = 300_000
REVIEW_PATTERN = re.compile(r"review|verdict|re-review|delta", re.IGNORECASE)
MAX_COMPACTIONS_SHOWN = 25

USAGE = """\
usage: tools/usage-report.py [--help|-h] [--window START..END]... [--compare-to FAMILY] [--top N]
                             [--no-prs] [--json] [--save] [--projects-dir DIR] [--repo DIR]

Report the tokens, cache rewrites and API-price dollars this repository's Claude Code sessions and
sub-agents used, per window, by kind (main session, build, review) and model family.

  --window START..END  a window; repeatable. START and END are ISO 8601 dates or datetimes (a bare
                       datetime is local time; Z or an offset is honoured); either may be empty for
                       open. Default: the last 7 days and the 7 days before them.
  --compare-to FAMILY  price every family's tokens also at this family's prices (fable, opus, sonnet
                       or haiku; default opus): "what this work would have cost there at the same
                       tokens", which assumes the same tokens would have been used.
  --top N              how many of the costliest sub-agents and main sessions to list (default 8).
  --no-prs             do not ask the GitHub CLI for the merged pull requests of each window.
  --json               print the rows (one per session and window) instead of the report.
  --save               also write the report and the rows under ~/.claude/nappy-agent-stats/usage/<today>/.
  --projects-dir DIR   the transcripts' root (default ~/.claude/projects).
  --repo DIR           the repository whose sessions are read (default: this repository's main checkout).
  --help, -h           this text.

example: tools/usage-report.py --window 2026-10-31T03:28Z..2026-11-06T16:47:53Z --save
"""


# ---------------------------------------------------------------------------------------------
# Data


@dataclass(frozen=True)
class Turn:
    t: datetime
    model: str
    inp: int
    w1: int
    w5: int
    read: int
    out: int

    @property
    def context(self) -> int:
        return self.inp + self.w1 + self.w5 + self.read

    @property
    def writes(self) -> int:
        return self.w1 + self.w5

    def weighted(self) -> float:
        return (
            W_INPUT * self.inp + W_WRITE_5M * self.w5 + W_WRITE_1H * self.w1 + W_READ * self.read + W_OUTPUT * self.out
        )

    def write_dollars(self, price: Price) -> float:
        return price[0] * (1.25 * self.w5 + 2.0 * self.w1) / 1e6

    def dollars(self, price: Price) -> float:
        inp, out, read = price
        return (inp * self.inp + read * self.read + out * self.out) / 1e6 + self.write_dollars(price)


@dataclass(frozen=True)
class Compaction:
    t: datetime
    trigger: str
    pre_tokens: int


@dataclass
class Session:
    path: str
    session_id: str
    is_sub: bool
    description: str
    turns: list[Turn] = field(default_factory=list)
    compactions: list[Compaction] = field(default_factory=list)

    @property
    def kind(self) -> str:
        if not self.is_sub:
            return "main"
        return "review" if REVIEW_PATTERN.search(self.description) else "build"


@dataclass(frozen=True)
class Window:
    start: datetime | None
    end: datetime | None

    def contains(self, t: datetime) -> bool:
        return (self.start is None or t >= self.start) and (self.end is None or t < self.end)

    def label(self) -> str:
        return f"{stamp(self.start)}..{stamp(self.end)}"


def stamp(d: datetime | None, open_text: str = "open") -> str:
    return open_text if d is None else d.astimezone(UTC).strftime("%Y-%m-%dT%H:%M:%SZ")


def family(model: str) -> str:
    for name in FAMILIES:
        if name in model:
            return name
    return model


def family_price(name: str) -> Price | None:
    for model, price in PRICES.items():
        if family(model) == name:
            return price
    return None


def parse_time(text: str) -> datetime:
    t = datetime.fromisoformat(text.replace("Z", "+00:00"))
    return t if t.tzinfo else t.astimezone()


def project_dir_name(repo: Path) -> str:
    return re.sub(r"[^A-Za-z0-9]", "-", str(repo))


# ---------------------------------------------------------------------------------------------
# Reading transcripts


def read_session(path: Path) -> Session | None:
    is_sub = "subagents" in path.parts
    description = ""
    if is_sub:
        try:
            description = str(json.loads(path.with_suffix(".meta.json").read_text()).get("description", ""))
        except OSError, ValueError, AttributeError:
            description = ""
    session_id = path.parent.parent.name if is_sub else path.stem
    session = Session(str(path), session_id, is_sub, description)
    seen: set[str] = set()
    for line in path.read_text(errors="replace").splitlines():
        if '"usage"' not in line and '"compact_boundary"' not in line:
            continue
        try:
            d = json.loads(line)
            if d.get("subtype") == "compact_boundary":
                meta = d.get("compactMetadata") or {}
                session.compactions.append(
                    Compaction(parse_time(d["timestamp"]), str(meta.get("trigger", "?")), int(meta.get("preTokens", 0)))
                )
                continue
            message = d.get("message") or {}
            usage = message.get("usage")
            mid = message.get("id")
            if d.get("type") != "assistant" or not usage or not mid or mid in seen:
                continue
            seen.add(mid)
            if message.get("model") == SYNTHETIC_MODEL:
                continue
            created = usage.get("cache_creation") or {}
            w1 = int(created.get("ephemeral_1h_input_tokens", 0) or 0)
            w5 = int(created.get("ephemeral_5m_input_tokens", 0) or 0)
            total = int(usage.get("cache_creation_input_tokens", 0) or 0)
            if w1 + w5 < total:
                w5 += total - w1 - w5
            session.turns.append(
                Turn(
                    parse_time(d["timestamp"]),
                    str(message.get("model", "?")),
                    int(usage.get("input_tokens", 0) or 0),
                    w1,
                    w5,
                    int(usage.get("cache_read_input_tokens", 0) or 0),
                    int(usage.get("output_tokens", 0) or 0),
                )
            )
        except ValueError, KeyError, TypeError, AttributeError:
            continue
    session.turns.sort(key=lambda x: x.t)
    return session if session.turns or session.compactions else None


def read_sessions(projects_dir: Path, repo: Path) -> list[Session]:
    sessions: list[Session] = []
    prefix = project_dir_name(repo)
    for project in sorted(projects_dir.glob(prefix + "*")):
        for path in sorted(project.rglob("*.jsonl")):
            s = read_session(path)
            if s:
                sessions.append(s)
    return sessions


# ---------------------------------------------------------------------------------------------
# Per window rows


@dataclass
class Row:
    window: int
    session: Session
    turns: list[Turn]
    model: str
    weighted: float
    dollars: float
    unpriced_turns: int
    max_context: int
    rewrites: list[float]  # the pause, in seconds, before each rewriting turn
    rewrite_weighted: float
    rewrite_dollars: float

    @property
    def family(self) -> str:
        return family(self.model)

    @property
    def kind(self) -> str:
        return self.session.kind

    def as_json(self) -> dict[str, Any]:
        return {
            "window": self.window,
            "session": self.session.session_id,
            "path": self.session.path,
            "sub": self.session.is_sub,
            "kind": self.kind,
            "description": self.session.description,
            "model": self.model,
            "turns": len(self.turns),
            "first": self.turns[0].t.isoformat(),
            "last": self.turns[-1].t.isoformat(),
            "weighted": self.weighted,
            "dollars": self.dollars,
            "unpriced_turns": self.unpriced_turns,
            "max_context": self.max_context,
            "rewrites": self.rewrites,
            "rewrite_weighted": self.rewrite_weighted,
            "rewrite_dollars": self.rewrite_dollars,
            "write_1h": sum(x.w1 for x in self.turns),
            "write_5m": sum(x.w5 for x in self.turns),
        }


def make_row(index: int, session: Session, turns: list[Turn]) -> Row:
    counts: dict[str, int] = {}
    for x in turns:
        counts[x.model] = counts.get(x.model, 0) + 1
    gaps: list[float] = []
    rewrite_weighted = 0.0
    rewrite_dollars = 0.0
    for prev, cur in pairwise(turns):
        gap = (cur.t - prev.t).total_seconds()
        if (
            gap >= REWRITE_GAP_SECONDS
            and cur.writes > REWRITE_SHARE * cur.context
            and cur.context > REWRITE_MIN_CONTEXT
        ):
            gaps.append(gap)
            rewrite_weighted += W_WRITE_5M * cur.w5 + W_WRITE_1H * cur.w1
            price = PRICES.get(cur.model)
            if price:
                rewrite_dollars += cur.write_dollars(price)
    dollars = 0.0
    unpriced = 0
    for x in turns:
        price = PRICES.get(x.model)
        if price is None:
            unpriced += 1
        else:
            dollars += x.dollars(price)
    return Row(
        index,
        session,
        turns,
        max(counts, key=lambda m: counts[m]),
        sum(x.weighted() for x in turns),
        dollars,
        unpriced,
        max(x.context for x in turns),
        gaps,
        rewrite_weighted,
        rewrite_dollars,
    )


def build_rows(sessions: Iterable[Session], windows: list[Window]) -> list[Row]:
    rows: list[Row] = []
    for s in sessions:
        for i, w in enumerate(windows):
            turns = [x for x in s.turns if w.contains(x.t)]
            if turns:
                rows.append(make_row(i, s, turns))
    return rows


# ---------------------------------------------------------------------------------------------
# Merged pull requests


def count_merged_prs(
    window: Window, cwd: Path, run: Callable[..., subprocess.CompletedProcess[str]] = subprocess.run
) -> int | None:
    """Merged pull requests in the window by the GitHub CLI's search; None when the lookup fails."""
    cmd = [
        "gh",
        "pr",
        "list",
        "--state",
        "merged",
        "--search",
        f"merged:{stamp(window.start, '*')}..{stamp(window.end, '*')}",
        "--json",
        "number",
        "--limit",
        "5000",
    ]
    try:
        done = run(cmd, capture_output=True, text=True, check=False, cwd=cwd, timeout=60)
        if done.returncode != 0:
            return None
        return len(json.loads(done.stdout))
    except OSError, ValueError, subprocess.SubprocessError:
        return None


# ---------------------------------------------------------------------------------------------
# The report


def fmt_m(x: float) -> str:
    return f"{x / 1e6:.1f}M"


def fmt_usd(x: float) -> str:
    return f"${x:,.0f}" if abs(x) >= 100 else f"${x:,.2f}"


def p90(values: list[int]) -> int:
    return sorted(values)[int(0.9 * len(values))]


def family_sort(f: str) -> tuple[int, str]:
    return (FAMILIES.index(f) if f in FAMILIES else 99, f)


def family_order(rows: list[Row]) -> list[str]:
    return sorted({r.family for r in rows}, key=family_sort)


def window_hours(window: Window, rows: list[Row], now: datetime) -> float:
    lo = window.start or min((r.turns[0].t for r in rows), default=now)
    hi = window.end or now
    return max((hi - lo).total_seconds() / 3600, 1e-9)


def describe_group(rows: list[Row], total: float) -> str:
    turns = [len(r.turns) for r in rows]
    return (
        f"n={len(rows):4d} share={sum(r.weighted for r in rows) / total:5.1%} ${sum(r.dollars for r in rows):>9,.2f} "
        f"turns med={statistics.median(turns):5.0f} p90={p90(turns):4d} max={max(turns):4d} "
        f"maxctx med={statistics.median(r.max_context for r in rows) / 1e3:4.0f}k "
        f">{LONG_TURNS}t={sum(t > LONG_TURNS for t in turns)} "
        f">{LONG_CONTEXT // 1000}kctx={sum(r.max_context > LONG_CONTEXT for r in rows)} "
        f"per agent med={statistics.median(r.weighted for r in rows) / 1e6:.2f}M "
        f"${statistics.median(r.dollars for r in rows):.2f}"
    )


def comparison(rows: list[Row], compare_to: str) -> list[str]:
    other = family_price(compare_to)
    assert other is not None
    out = [
        f" model comparison (all turns; 'at {compare_to}' prices the same tokens at {compare_to} prices):",
        f"  {'family':8} {'weighted':>9} {'actual $':>10} {'at ' + compare_to:>10} {'ratio':>6}",
    ]
    for fam in sorted({family(x.model) for r in rows for x in r.turns}, key=family_sort):
        turns = [x for r in rows for x in r.turns if family(x.model) == fam]
        weighted = fmt_m(sum(x.weighted() for x in turns))
        at_other = sum(x.dollars(other) for x in turns)
        if any(x.model not in PRICES for x in turns):
            out.append(f"  {fam:8} {weighted:>9} {'unpriced':>10} {fmt_usd(at_other):>10} {'n/a':>6}")
            continue
        actual = sum(x.dollars(PRICES[x.model]) for x in turns)
        ratio = f"{actual / at_other:5.2f}x" if at_other else "n/a"
        out.append(f"  {fam:8} {weighted:>9} {fmt_usd(actual):>10} {fmt_usd(at_other):>10} {ratio:>6}")
    out.append(
        "  (the 'at' column assumes the same tokens: another model would take other turn counts, contexts "
        "and cache hits)"
    )
    return out


def window_report(
    index: int,
    window: Window,
    rows: list[Row],
    sessions: list[Session],
    compare_to: str,
    top: int,
    prs: str,
    now: datetime,
) -> list[str]:
    hours = window_hours(window, rows, now)
    total = sum(r.weighted for r in rows) or 1.0
    dollars = sum(r.dollars for r in rows)
    main = [r for r in rows if not r.session.is_sub]
    sub = [r for r in rows if r.session.is_sub]
    out = [
        f"\n=== window {index + 1}: {window.label()} ({hours:.0f}h): total weighted {total / 1e6:.1f}M "
        f"({total / 1e6 / hours:.2f}M/h), {fmt_usd(dollars)} at API prices ({fmt_usd(dollars / hours)}/h)",
        f" main {len(main)} sessions {sum(r.weighted for r in main) / total:.0%} of tokens, "
        f"{fmt_usd(sum(r.dollars for r in main))}; sub-agents {len(sub)} {sum(r.weighted for r in sub) / total:.0%}, "
        f"{fmt_usd(sum(r.dollars for r in sub))}; merged PRs {prs}",
    ]
    unpriced = sorted({x.model for r in rows for x in r.turns if x.model not in PRICES})
    if unpriced:
        n = sum(r.unpriced_turns for r in rows)
        out.append(f" unpriced models (tokens counted, no dollars): {', '.join(unpriced)} ({n} turns)")

    rw_w = sum(r.rewrite_weighted for r in rows)
    out.append(
        f" cache rewrites after a pause of >={REWRITE_GAP_SECONDS // 60}min: {sum(len(r.rewrites) for r in rows)} "
        f"costing {fmt_m(rw_w)} = {rw_w / total:.1%} of tokens, {fmt_usd(sum(r.rewrite_dollars for r in rows))} "
        f"in write prices; sub-agent rewrites {sum(len(r.rewrites) for r in sub)} "
        f"({sum(r.rewrite_weighted for r in sub) / total:.1%})"
    )
    gaps = [g for r in sub for g in r.rewrites]
    if gaps:
        out.append(
            f"  sub-agent rewrite pauses: <1h {sum(g < 3600 for g in gaps)}  >=1h {sum(g >= 3600 for g in gaps)}"
        )
    all_turns = [x for r in rows for x in r.turns]
    sub_turns = [x for r in sub for x in r.turns]
    out.append(
        f" cache writes: 1h {fmt_m(sum(x.w1 for x in all_turns))}  5m {fmt_m(sum(x.w5 for x in all_turns))} "
        f"(sub-agents: 1h {fmt_m(sum(x.w1 for x in sub_turns))}  5m {fmt_m(sum(x.w5 for x in sub_turns))})"
    )

    out.append(" per kind and model family:")
    for kind in ("main", "build", "review"):
        for fam in family_order(rows):
            group = [r for r in rows if r.kind == kind and r.family == fam]
            if group:
                out.append(f"  {kind:6} {fam:6} {describe_group(group, total)}")
    out.extend(comparison(rows, compare_to))

    def listing(title: str, group: list[Row]) -> None:
        out.append(f" {title}:")
        for r in sorted(group, key=lambda r: (-r.dollars, -r.weighted))[:top]:
            label = r.session.description[:60] if r.session.is_sub else "main session"
            out.append(
                f"   {fmt_usd(r.dollars):>8} {r.weighted / total:5.1%} {r.family:6} {len(r.turns):5d}t "
                f"maxctx {r.max_context / 1e3:4.0f}k rw {len(r.rewrites)} {r.turns[0].t.date()} "
                f"{r.session.session_id[:8]} {label}"
            )

    listing(f"top {top} sub-agents by cost", sub)
    listing(f"top {top} main sessions by cost", main)

    found = sorted(
        ((c, s.is_sub) for s in sessions for c in s.compactions if window.contains(c.t)), key=lambda p: p[0].t
    )
    n_sub = sum(is_sub for _, is_sub in found)
    out.append(f" compactions: {len(found)} ({len(found) - n_sub} main, {n_sub} sub-agent)")
    shown = sorted(sorted(found, key=lambda p: -p[0].pre_tokens)[:MAX_COMPACTIONS_SHOWN], key=lambda p: p[0].t)
    if len(found) > len(shown):
        out.append(f"  the largest {len(shown)} by tokens before:")
    for c, is_sub in shown:
        out.append(
            f"  {c.t.astimezone(UTC):%Y-%m-%d %H:%MZ} {c.trigger:7} {c.pre_tokens / 1e3:5.0f}k "
            f"{'sub-agent' if is_sub else 'main'}"
        )
    return out


def report(
    windows: list[Window],
    rows: list[Row],
    sessions: list[Session],
    compare_to: str,
    top: int,
    prs: list[str],
    now: datetime,
) -> str:
    lines = [
        f"usage report, generated {now.astimezone(UTC):%Y-%m-%d %H:%MZ}; prices read {PRICE_DATE}: "
        + ", ".join(f"{m} {p[0]:g}/{p[1]:g}/{p[2]:g}" for m, p in PRICES.items())
        + " (input/output/cache read per million tokens)",
        "estimated, not read from the reference: "
        + ", ".join(f"{m} {what} price" for m, what in ESTIMATED_PRICES.items()),
        "weighted tokens: input 1, 5-minute write 1.25, 1-hour write 2, cache read 0.1, output 5",
    ]
    for i, w in enumerate(windows):
        lines.extend(window_report(i, w, [r for r in rows if r.window == i], sessions, compare_to, top, prs[i], now))
    return "\n".join(lines) + "\n"


# ---------------------------------------------------------------------------------------------
# Command line


class UsageError(Exception):
    pass


class Parser(argparse.ArgumentParser):
    def error(self, message: str) -> Any:
        raise UsageError(message)


def parse_window(text: str) -> Window:
    if ".." not in text:
        raise UsageError(f"--window {text!r} is not START..END")
    a, b = text.split("..", 1)
    try:
        return Window(parse_time(a) if a else None, parse_time(b) if b else None)
    except ValueError as e:
        raise UsageError(f"--window {text!r}: {e}") from e


def main_repo() -> Path:
    here = Path(__file__).resolve().parents[1]
    try:
        done = subprocess.run(
            ["git", "rev-parse", "--path-format=absolute", "--git-common-dir"],
            capture_output=True,
            text=True,
            check=False,
            cwd=here,
        )
        if done.returncode == 0 and done.stdout.strip():
            return Path(done.stdout.strip()).parent
    except OSError:
        pass
    return here


def run(argv: list[str], now: datetime | None = None) -> int:
    now = now or datetime.now(UTC)
    parser = Parser(add_help=False)
    parser.add_argument("--window", action="append", default=[])
    parser.add_argument("--compare-to", default="opus")
    parser.add_argument("--top", type=int, default=8)
    parser.add_argument("--no-prs", action="store_true")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--save", action="store_true")
    parser.add_argument("--projects-dir", type=Path, default=Path.home() / ".claude" / "projects")
    parser.add_argument("--repo", type=Path, default=None)
    parser.add_argument("--help", "-h", action="store_true")
    try:
        args = parser.parse_args(argv)
        if args.help:
            print(USAGE, end="")
            return 0
        if args.compare_to not in FAMILIES or family_price(args.compare_to) is None:
            raise UsageError(f"--compare-to {args.compare_to!r} is not a priced family ({', '.join(FAMILIES)})")
        if args.top < 1:
            raise UsageError("--top must be at least 1")
        windows = [parse_window(w) for w in args.window] or [
            Window(now - timedelta(days=7), now),
            Window(now - timedelta(days=14), now - timedelta(days=7)),
        ]
    except UsageError as e:
        print(f"usage-report.py: {e}", file=sys.stderr)
        print(USAGE, end="", file=sys.stderr)
        return 2

    repo = (args.repo or main_repo()).resolve()
    sessions = read_sessions(args.projects_dir, repo)
    rows = build_rows(sessions, windows)
    rows_text = json.dumps([r.as_json() for r in rows], indent=1) + "\n"
    if args.json:
        text = rows_text
    else:
        prs = ["n/a (skipped)"] * len(windows)
        if not args.no_prs:
            counts = [count_merged_prs(w, repo) for w in windows]
            prs = ["n/a" if n is None else str(n) for n in counts]
        text = report(windows, rows, sessions, args.compare_to, args.top, prs, now)
    print(text, end="")
    if args.save:
        folder = Path.home() / ".claude" / "nappy-agent-stats" / "usage" / now.astimezone().strftime("%Y-%m-%d")
        folder.mkdir(parents=True, exist_ok=True)
        if not args.json:
            (folder / "report.txt").write_text(text)
        (folder / "rows.json").write_text(rows_text)
        print(f"saved under {folder}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(run(sys.argv[1:]))
