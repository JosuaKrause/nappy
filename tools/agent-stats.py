#!/usr/bin/env python3
"""Counter of what each sub-agent did and how it went.

The data stays outside the repository, in ~/.claude/nappy-agent-stats/: log.jsonl holds the
orchestrator's grades (this tool writes it, one JSON line per agent), runs.jsonl holds what the
SubagentStop hook (.claude/hooks/agent-stats.py) measured for every finished agent. The two join
by agent id, a prefix match, since a grade may carry a shortened id.

Kinds: build-parity, build-play, investigate, measure, capture, fix, review, filing.
rounds: how many times the agent's work came back not ready, or needed another agent to correct it.
--redone: the orchestrator redid or overrode the agent's own conclusion; it counts as a correction,
and a task handed out whole is graded on what the agent itself concluded, never on what the
orchestrator added.
"""

from __future__ import annotations

import argparse
import json
import statistics
import sys
from collections import defaultdict
from datetime import date
from pathlib import Path
from typing import Any

DATA = Path.home() / ".claude" / "nappy-agent-stats"
KINDS = ["build-parity", "build-play", "investigate", "measure", "capture", "fix", "review", "filing"]
MODELS = ["haiku", "sonnet", "opus", "fable"]
GRADES = ("good", "ok", "bad")
MIN_PREFIX = 6

Row = dict[str, Any]


def read_lines(name: str) -> list[Row]:
    path = DATA / name
    if not path.exists():
        return []
    rows: list[Row] = []
    for line in path.read_text().splitlines():
        if line.strip():
            rows.append(json.loads(line))
    return rows


class AmbiguousAgentError(Exception):
    """More than one run's agent id starts with the given prefix."""


def run_for(agent: str, runs: list[Row]) -> Row | None:
    """The latest run of the one agent whose id starts with the given prefix.

    A prefix shorter than MIN_PREFIX joins nothing; a prefix several distinct agents share raises.
    """
    if len(agent) < MIN_PREFIX:
        return None
    found: dict[str, Row] = {}
    for run in runs:
        full = str(run.get("agent") or run.get("agent_id") or "")
        if full.startswith(agent):
            found[full] = run
    if len(found) > 1:
        raise AmbiguousAgentError(f"agent prefix {agent!r} matches {', '.join(sorted(found))}")
    return next(iter(found.values()), None)


def add(args: argparse.Namespace) -> int:
    try:
        run = run_for(args.agent, read_lines("runs.jsonl"))
    except AmbiguousAgentError as e:
        print(f"agent-stats.py: {e}; give more of the id", file=sys.stderr)
        return 2
    tokens = args.tokens if args.tokens is not None else (run or {}).get("tokens")
    tools = args.tools if args.tools is not None else (run or {}).get("tools")
    if tokens is None:
        print("agent-stats.py: --tokens is required when runs.jsonl has no run for --agent", file=sys.stderr)
        return 2
    row: Row = {
        "kind": args.kind,
        "model": args.model,
        "pr": args.pr,
        "tokens": tokens,
        "tools": tools,
        "rounds": args.rounds,
        "grade": args.grade,
        "redone": args.redone,
        "note": args.note,
        "agent": args.agent,
        "date": args.date,
    }
    DATA.mkdir(parents=True, exist_ok=True)
    with (DATA / "log.jsonl").open("a") as f:
        f.write(json.dumps(row) + "\n")
    print(f"recorded {row['kind']} / {row['model']} ({row['grade']}), tokens {tokens}, tools {tools}")
    return 0


def summary() -> int:
    runs = read_lines("runs.jsonl")
    groups: defaultdict[tuple[str, str], list[Row]] = defaultdict(list)
    for row in read_lines("log.jsonl"):
        if row.get("tokens") is None:
            try:
                row["tokens"] = (run_for(row.get("agent", ""), runs) or {}).get("tokens")
            except AmbiguousAgentError:
                row["tokens"] = None
        groups[(row["kind"], row["model"])].append(row)
    print(f"{'kind':14} {'model':7} {'n':>3} {'tokens':>8} {'rounds':>6} {'redone':>6}  good/ok/bad")
    for (kind, model), rows in sorted(groups.items()):
        tokens = [r["tokens"] for r in rows if r["tokens"] is not None]
        mean_tokens = int(statistics.mean(tokens)) if tokens else 0
        grades = "/".join(str(sum(r["grade"] == g for r in rows)) for g in GRADES)
        redone = sum(bool(r.get("redone")) for r in rows)
        mean_rounds = statistics.mean(r["rounds"] for r in rows)
        print(f"{kind:14} {model:7} {len(rows):>3} {mean_tokens:>8} {mean_rounds:>6.1f} {redone:>6}  {grades}")
    return 0


def list_rows(last: int) -> int:
    for row in read_lines("log.jsonl")[-last:]:
        print(json.dumps(row))
    return 0


def parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="agent-stats.py", description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    sub = p.add_subparsers(dest="cmd", required=True)
    a = sub.add_parser("add", help="record one agent's grade")
    a.add_argument("--kind", required=True, choices=KINDS)
    a.add_argument("--model", required=True, choices=MODELS)
    a.add_argument("--pr", type=int)
    a.add_argument("--tokens", type=int, help="default: the hook's measure of --agent")
    a.add_argument("--tools", type=int, help="default: the hook's measure of --agent")
    a.add_argument("--rounds", type=int, required=True)
    a.add_argument("--grade", required=True, choices=GRADES)
    a.add_argument("--redone", action="store_true", help="the orchestrator redid or overrode the agent's conclusion")
    a.add_argument("--note", default="")
    a.add_argument("--agent", default="", help="the agent id, full or shortened")
    a.add_argument("--date", default=date.today().isoformat())
    sub.add_parser("summary", help="per kind and model: count, mean tokens, mean rounds, redone, grades")
    ls = sub.add_parser("list", help="the raw entries")
    ls.add_argument("--last", type=int, default=20)
    return p


def main() -> int:
    args = parser().parse_args()
    if args.cmd == "add":
        return add(args)
    if args.cmd == "list":
        return list_rows(args.last)
    return summary()


if __name__ == "__main__":
    sys.exit(main())
