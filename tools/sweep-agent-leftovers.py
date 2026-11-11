#!/usr/bin/env python3
"""Sweeps what finished agents left behind in the main checkout, listing first.

Two kinds of leftover, both under the main checkout's git-ignored .claude/:

  briefs     .claude/briefs/<branch with / as ->.md, the brief tools/agent-setup.sh starts for an
             agent's branch. tools/prune-merged.sh deletes a released one as it retires the
             branch; a brief whose branch went any other way stays behind.
  checkouts  .claude/worktrees/<name> with no branch: the detached checkouts
             tools/agent-setup.sh --detach makes for a review or a measurement.

Without --apply nothing is removed. Every branch brief and every detached checkout gets one line,
"sweep" or "keep" with the reason, and the counts follow; the other files in the briefs folder are
counted and get no line. With --apply, each thing marked sweep is checked once more against the
checkout as it stands then, and removed.

A brief is swept when all of this holds:
  - It is a branch brief: its header (the lines up to the first empty one) has a "branch:" line,
    and the file is named for that branch. A draft, a plan, a review brief and any other file or
    folder there is another kind, and no rule here removes one.
  - Its branch exists nowhere: no local branch, no branch on origin, no open pull request with
    that head, and no directory where its "worktree:" line points.
  - Its own pull request merged, so what the task was is in the pull request: the newest pull
    request with that head is a merged one, and it merged on or after the brief's "spawned:"
    date. A branch name is used again now and then, and an earlier use that merged says nothing
    about this brief. With no such pull request, or no "spawned:" date, the brief may be the only
    record of its task, and it stays.
  - Its agent is not running: neither the brief nor the transcript of any agent its "agent:" lines
    name was written in the last 24 hours.
"cleanup: ready" is not required. That line releases a branch and a worktree for retirement, and
here both are already gone; each sweep line says "released" or "never released".

A detached checkout is swept when all of this holds:
  - It holds no commit of its own: every commit its HEAD is at or has been at is reachable from a
    ref, the commit the checkout was made at excepted. One that does hold such a commit is listed
    with each commit and is never removed; a branch at a commit (git branch <name> <commit>)
    keeps it.
  - No file in it is changed or untracked, and no ignored file is anything but a regenerable
    cache (tools/prune-merged.sh --help lists those).
  - It is not locked, not the caller's own, and no rebase, merge, cherry-pick, revert or bisect
    is under way in it.
  - No brief claims it for a branch that is still there: no file in the briefs folder whose
    header names it on its "worktree:" line has a "branch:" that exists locally or on origin or
    has an open pull request. An agent's worktree left on a detached HEAD is such a checkout.
  - It is quiet: no file in it changed in the last 24 hours, and neither did its HEAD.
The removal is tools/agent-setup.sh --remove <name>, never anything forced; what that refuses
stays, and the refusal is printed. A checkout counts as removed once its directory is gone.

Never touched: a worktree that has a branch (tools/prune-merged.sh retires those), a worktree
outside .claude/worktrees/, a brief inside a worktree, any branch, and anything on GitHub. The
sweep reads GitHub twice per run, the branches on origin (git ls-remote) and the pull requests
(gh pr list), and writes nothing to it; if either read fails, or origin answers with no branch at
all, the run ends with nothing removed.

Exit status: 0 for a listing, and for an applying run that removed everything it set out to; 1
when a read failed or a removal was refused; 2 for a bad argument.

  uv run python tools/sweep-agent-leftovers.py
  uv run python tools/sweep-agent-leftovers.py --apply
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import time
from collections import Counter
from collections.abc import Mapping
from dataclasses import dataclass
from datetime import UTC, date, datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
# The one way a detached checkout is removed; its refusals are the sweep's too.
AGENT_SETUP = ROOT / "tools" / "agent-setup.sh"
# classify_ignored: which ignored files are regenerable caches, the list the two removers share.
IGNORED_LIB = ROOT / "tools" / "lib_regenerable_ignored.sh"

# How long a brief, an agent's transcript or a checkout must have gone unwritten. This tool's own
# choice: an agent that is running writes its transcript every few minutes, and a day is past any
# review or measurement that is still being worked in.
QUIET_HOURS = 24
# More pull requests than `gh pr list` is asked for would hide an open one, so the run refuses.
PR_LIMIT = 100_000
# What a rebase, a merge, a cherry-pick, a revert or a bisect leaves in a worktree's git directory
# while it is under way. A branch's worktree in the middle of a rebase reads as detached.
IN_PROGRESS = ("rebase-merge", "rebase-apply", "MERGE_HEAD", "CHERRY_PICK_HEAD", "REVERT_HEAD", "BISECT_LOG")

BRIEF, CHECKOUT = "brief", "checkout"
SWEEP = "sweep"
# The summary's word for a file in the briefs folder that no rule here is about; such a file is
# counted and gets no line of its own.
OTHER_KIND = "not a branch brief"
NOT_MERGED = "no merged pull request of its own"


class SweepError(Exception):
    """A read the sweep cannot do without failed."""


@dataclass(frozen=True)
class Worktree:
    path: Path
    branch: str | None
    detached: bool
    locked: bool


@dataclass(frozen=True)
class Local:
    """What the repository on disk says, read in one go and again before each removal."""

    main: Path
    branches: frozenset[str]
    worktrees: tuple[Worktree, ...]


@dataclass(frozen=True)
class PullRequest:
    number: int
    state: str  # OPEN, CLOSED or MERGED
    # The day it merged, the later of the local and the UTC one: a "spawned:" line is written in
    # either, by tools/agent-setup.sh in local time and by hand in both.
    merged_on: date | None
    fork: bool  # its head is another repository's branch of the same name


@dataclass(frozen=True)
class Remote:
    """What GitHub says, read once per run."""

    branches: frozenset[str]
    open_prs: Mapping[str, int]
    newest_prs: Mapping[str, PullRequest]  # by head, the pull request with the highest number


@dataclass(frozen=True)
class Header:
    branch: str | None
    worktree: str | None
    spawned: date | None
    agents: tuple[str, ...]
    released: bool


@dataclass(frozen=True)
class Verdict:
    kind: str
    name: str
    group: str  # SWEEP, or the summary's word for why it is kept
    reason: str
    notes: tuple[str, ...] = ()

    @property
    def sweep(self) -> bool:
        return self.group == SWEEP

    def lines(self) -> list[str]:
        word = "sweep" if self.sweep else "keep"
        return [f"{word} {self.kind} {self.name}: {self.reason}", *(f"    {note}" for note in self.notes)]


def run(args: list[str], cwd: Path | None = None) -> subprocess.CompletedProcess[str]:
    try:
        return subprocess.run(args, cwd=cwd, capture_output=True, text=True, check=False)
    except OSError as e:
        raise SweepError(f"cannot run {args[0]}: {e}") from e


def git(checkout: Path, *args: str) -> str:
    result = run(["git", "--no-optional-locks", "-C", str(checkout), *args])
    if result.returncode != 0:
        raise SweepError(f"git {' '.join(args)} failed in {checkout}: {result.stderr.strip()}")
    return result.stdout


def read_worktrees(checkout: Path) -> tuple[Worktree, ...]:
    found = []
    for block in git(checkout, "worktree", "list", "--porcelain").split("\n\n"):
        lines = block.splitlines()
        if not lines or not lines[0].startswith("worktree "):
            continue
        branches = [line.removeprefix("branch refs/heads/") for line in lines if line.startswith("branch ")]
        found.append(
            Worktree(
                path=Path(lines[0].removeprefix("worktree ")).resolve(),
                branch=branches[0] if branches else None,
                detached="detached" in lines,
                locked=any(line == "locked" or line.startswith("locked ") for line in lines),
            )
        )
    return tuple(found)


def read_local() -> Local:
    """The repository this script sits in; `git worktree list` names its main checkout first."""
    worktrees = read_worktrees(ROOT)
    if not worktrees:
        raise SweepError(f"{ROOT} is not inside a git repository")
    main = worktrees[0].path
    branches = git(main, "for-each-ref", "--format=%(refname:short)", "refs/heads").split()
    return Local(main=main, branches=frozenset(branches), worktrees=worktrees)


def day_merged(merged_at: str) -> date:
    moment = datetime.fromisoformat(merged_at)
    return max(moment.astimezone(UTC).date(), moment.astimezone().date())


def read_remote(main: Path) -> Remote:
    heads = git(main, "ls-remote", "--heads", "origin")
    branches = frozenset(
        line.split("\t", 1)[1].removeprefix("refs/heads/") for line in heads.splitlines() if "\t" in line
    )
    if not branches:
        # GitHub never answers this way; an origin pointed somewhere else does, and every brief's
        # branch would then read as gone.
        raise SweepError("origin answered with no branch at all")
    fields = "number,state,headRefName,isCrossRepository,mergedAt"
    listed = run(["gh", "pr", "list", "--state", "all", "--limit", str(PR_LIMIT), "--json", fields], cwd=main)
    if listed.returncode != 0:
        raise SweepError(f"gh pr list failed: {listed.stderr.strip()}")
    try:
        prs = json.loads(listed.stdout)
    except json.JSONDecodeError as e:
        raise SweepError(f"gh pr list printed no JSON: {e}") from e
    if not isinstance(prs, list) or len(prs) >= PR_LIMIT:
        raise SweepError(f"gh pr list did not return every pull request (the limit is {PR_LIMIT})")
    open_prs: dict[str, int] = {}
    newest_prs: dict[str, PullRequest] = {}
    try:
        for pr in prs:
            head, number, state = str(pr["headRefName"]), int(pr["number"]), str(pr["state"])
            merged_at = pr.get("mergedAt")
            found = PullRequest(
                number=number,
                state=state,
                merged_on=day_merged(merged_at) if merged_at else None,
                fork=bool(pr.get("isCrossRepository")),
            )
            if state == "OPEN":
                open_prs[head] = max(number, open_prs.get(head, 0))
            if head not in newest_prs or number > newest_prs[head].number:
                newest_prs[head] = found
    except (KeyError, TypeError, ValueError) as e:
        raise SweepError(f"the pull-request list holds an entry that cannot be read: {e!r}") from e
    return Remote(branches=branches, open_prs=open_prs, newest_prs=newest_prs)


def default_project_dir(main: Path) -> Path:
    """Claude Code's folder for the main checkout, which holds every session's sub-agents."""
    return Path.home() / ".claude" / "projects" / re.sub(r"[^A-Za-z0-9]", "-", str(main))


def transcript_times(project_dir: Path) -> dict[str, float]:
    """When each sub-agent's transcript was last written, by agent id."""
    times: dict[str, float] = {}
    for path in project_dir.glob("*/subagents/agent-*.jsonl"):
        agent = path.name.removeprefix("agent-").removesuffix(".jsonl")
        try:
            times[agent] = max(times.get(agent, 0.0), path.stat().st_mtime)
        except OSError:
            continue
    return times


def hours_since(written: float, now: float) -> float:
    return (now - written) / 3600


def read_header(path: Path) -> Header:
    """A brief's header as tools/agent-setup.sh writes it: the lines up to the first empty one."""
    lines = []
    with path.open(encoding="utf-8", errors="replace") as handle:
        for raw in handle:
            line = raw.rstrip("\r\n")
            if not line:
                break
            lines.append(line)

    def values(key: str) -> list[str]:
        return [line.removeprefix(f"{key}: ").strip() for line in lines if line.startswith(f"{key}: ")]

    def day(texts: list[str]) -> date | None:
        # A date, with or without a time after it: "2026-10-03" and "2026-10-03T22:07Z" both occur.
        try:
            return date.fromisoformat(texts[0][:10])
        except IndexError, ValueError:
            return None

    branches, worktrees = values("branch"), values("worktree")
    return Header(
        branch=branches[0] if branches else None,
        worktree=worktrees[0] if worktrees else None,
        spawned=day(values("spawned")),
        agents=tuple(values("agent")),
        released="cleanup: ready" in lines,
    )


def inspect_brief(path: Path, local: Local, remote: Remote, transcripts: Mapping[str, float], now: float) -> Verdict:
    def keep(group: str, reason: str) -> Verdict:
        return Verdict(BRIEF, path.name, group, reason)

    try:
        if path.is_symlink() or not path.is_file():
            return keep(OTHER_KIND, "a folder or a link, not a brief file")
        header = read_header(path)
        written = path.stat().st_mtime
    except OSError as e:
        return keep("could not be read", f"cannot read it: {e}")
    branch = header.branch
    if branch is None:
        return keep(OTHER_KIND, 'no "branch:" line in its header, so it is not a branch\'s brief')
    own_name = branch.replace("/", "-") + ".md"
    if own_name != path.name:
        return keep(OTHER_KIND, f"it names the branch {branch}, whose own brief is {own_name}")
    if branch in local.branches:
        return keep("branch still exists", f"the branch {branch} exists locally")
    if header.worktree and Path(header.worktree).exists():
        return keep("worktree still exists", f"its worktree is still there: {header.worktree}")
    if branch in remote.branches:
        return keep("branch still exists", f"origin has the branch {branch}")
    if branch in remote.open_prs:
        return keep("open pull request", f"PR #{remote.open_prs[branch]} of {branch} is open")
    only_record = "so the brief may be the only record of its task"
    newest = remote.newest_prs.get(branch)
    if newest is None:
        return keep(NOT_MERGED, f"no pull request of {branch} at all, {only_record}")
    if newest.state != "MERGED" or newest.fork or newest.merged_on is None:
        state = "another repository's" if newest.fork else newest.state.lower()
        return keep(NOT_MERGED, f"the newest pull request of {branch}, #{newest.number}, is {state}, {only_record}")
    if header.spawned is None:
        return keep(NOT_MERGED, f'no "spawned:" date in its header to hold the merge of PR #{newest.number} against')
    if newest.merged_on < header.spawned:
        return keep(
            NOT_MERGED,
            f"PR #{newest.number} merged on {newest.merged_on}, before the brief was spawned on {header.spawned}:"
            f" an earlier use of the branch name, {only_record}",
        )
    if hours_since(written, now) < QUIET_HOURS:
        return keep("written recently", f"written in the last {QUIET_HOURS} hours")
    for agent in header.agents:
        if agent in transcripts and hours_since(transcripts[agent], now) < QUIET_HOURS:
            return keep("written recently", f"its agent {agent} wrote its transcript in the last {QUIET_HOURS} hours")
    released = "released" if header.released else "never released"
    return Verdict(
        BRIEF,
        path.name,
        SWEEP,
        f"PR #{newest.number} merged, {branch} is gone here and on origin, {released}",
    )


def claimed_worktrees(local: Local, remote: Remote) -> dict[Path, str]:
    """The directories a brief claims for a branch that is still there, each with that brief's name.

    Any file in the briefs folder whose header has a "branch:" and a "worktree:" line counts, a
    review brief too: while the branch exists locally or on origin or has an open pull request,
    the work the directory was made for is not finished.
    """
    claimed: dict[Path, str] = {}
    for path in brief_files(local):
        try:
            if path.is_symlink() or not path.is_file():
                continue
            header = read_header(path)
        except OSError:
            continue
        branch = header.branch
        if branch is None or not header.worktree:
            continue
        if branch in local.branches or branch in remote.branches or branch in remote.open_prs:
            claimed.setdefault(Path(header.worktree).resolve(), path.name)
    return claimed


def commits_of_its_own(worktree: Path, main: Path) -> list[str]:
    """The commits only this checkout names, by the rule of tools/agent-setup.sh --remove.

    The worktree's HEAD log is all that names a commit made in a detached checkout, and it goes
    with the worktree. So every commit that log names, HEAD's first, has to be reachable from a
    ref; the commit the checkout was made at, the log's first entry when it follows no other, was
    there before the checkout was and is exempt.
    """
    head = git(worktree, "rev-parse", "--verify", "--quiet", "HEAD^{commit}").strip()
    log = Path(git(worktree, "rev-parse", "--git-path", "logs/HEAD").strip())
    if not log.is_absolute():
        log = worktree / log
    made_at = ""
    visited = [head]
    if log.is_file():
        for index, line in enumerate(log.read_text(encoding="utf-8", errors="replace").splitlines()):
            fields = line.split()
            if len(fields) < 2:
                continue
            before, after = fields[0], fields[1]
            if index == 0 and set(before) == {"0"}:
                made_at = after
            if set(after) != {"0"}:
                visited.append(after)
    candidates = [commit for commit in dict.fromkeys(visited) if commit != made_at]
    if not candidates:
        return []
    unheld = set(git(main, "rev-list", *candidates, "--not", "--glob=refs/*").split())
    return [commit for commit in candidates if commit in unheld]


def kept_ignored_files(worktree: Path) -> list[str]:
    """The ignored files in a worktree that are no regenerable cache, by the removers' own list."""
    script = 'set -o pipefail; source "$1" && classify_ignored "$2" ""'
    result = run(["bash", "-c", script, "classify", str(IGNORED_LIB), str(worktree)])
    if result.returncode != 0:
        raise SweepError(f"cannot list the ignored files of {worktree}: {result.stderr.strip()}")
    return [line.split("\t", 1)[1] for line in result.stdout.splitlines() if line.startswith("keep\t")]


def last_written(worktree: Path, git_dir: Path) -> tuple[float, int]:
    """When anything in a checkout last changed, and the bytes its files are allocated.

    Its files and folders, and its HEAD with HEAD's log, which a commit or a checkout moves. The
    index is left out: a `git status` run from anywhere rewrites it.
    """
    newest = worktree.lstat().st_mtime
    blocks = 0
    for path in worktree.rglob("*"):
        stat = path.lstat()
        newest = max(newest, stat.st_mtime)
        blocks += stat.st_blocks
    for name in ("HEAD", "logs/HEAD"):
        moved = git_dir / name
        if moved.exists():
            newest = max(newest, moved.stat().st_mtime)
    return newest, blocks * 512


def inspect_checkout(worktree: Worktree, local: Local, claimed: Mapping[Path, str], now: float) -> Verdict:
    path, name = worktree.path, worktree.path.name

    def keep(group: str, reason: str, notes: tuple[str, ...] = ()) -> Verdict:
        return Verdict(CHECKOUT, name, group, reason, notes)

    try:
        if not path.is_dir():
            return keep("directory is gone", "its directory is gone; an applying tools/prune-merged.sh unregisters it")
        if worktree.locked:
            return keep("locked", "it is locked")
        if Path.cwd().resolve().is_relative_to(path):
            return keep("the caller's own", "the caller is inside it")
        git_dir = Path(git(path, "rev-parse", "--absolute-git-dir").strip())
        under_way = [mark for mark in IN_PROGRESS if (git_dir / mark).exists()]
        if under_way:
            return keep("operation under way", f"an operation is under way in it ({', '.join(under_way)})")
        own = commits_of_its_own(path, local.main)
        if own:
            subjects = git(local.main, "log", "--no-walk=unsorted", "--format=%H %s", *own).splitlines()
            count = "1 commit" if len(own) == 1 else f"{len(own)} commits"
            return keep(
                "holds its own commits",
                f"it holds {count} no ref reaches, and is never removed while it does:",
                (*subjects, f"a branch at one keeps it: git -C {local.main} branch <name> <commit>"),
            )
        if path in claimed:
            reason = f"{claimed[path]}, the brief of a branch that is still there, names it"
            return keep("claimed by a live branch's brief", reason)
        changed = git(path, "status", "--porcelain", "--untracked-files=all").splitlines()
        if changed:
            return keep(
                "changed or untracked files", f"{len(changed)} changed or untracked file(s)", tuple(changed[:5])
            )
        ignored = kept_ignored_files(path)
        if ignored:
            return keep(
                "ignored files that are no cache",
                f"{len(ignored)} ignored file(s) that are no regenerable cache",
                tuple(ignored[:5]),
            )
        written, allocated = last_written(path, git_dir)
        quiet = hours_since(written, now)
        if quiet < QUIET_HOURS:
            return keep("written recently", f"something in it changed in the last {QUIET_HOURS} hours")
        head = git(path, "rev-parse", "--short", "HEAD").strip()
    except (SweepError, OSError) as e:
        return keep("could not be read", f"cannot read it: {e}")
    return Verdict(
        CHECKOUT,
        name,
        SWEEP,
        f"detached at {head}, nothing of its own, unchanged for {int(quiet // 24)} day(s),"
        f" {allocated // (1024 * 1024)} MiB allocated",
    )


def brief_files(local: Local) -> list[Path]:
    """Everything directly in the main checkout's briefs folder, a folder that is really there."""
    folder = local.main / ".claude" / "briefs"
    if not folder.is_dir():
        return []
    if folder.resolve() != folder:
        raise SweepError(f"{folder} resolves elsewhere, to {folder.resolve()}")
    return sorted(folder.iterdir())


def detached_checkouts(local: Local) -> list[Worktree]:
    """The registered worktrees directly under .claude/worktrees/ that have no branch."""
    home = local.main / ".claude" / "worktrees"
    found = [worktree for worktree in local.worktrees if worktree.detached and worktree.path.parent == home]
    return sorted(found, key=lambda worktree: worktree.path.name)


def inventory(local: Local, remote: Remote, transcripts: Mapping[str, float], now: float) -> list[Verdict]:
    briefs = [inspect_brief(path, local, remote, transcripts, now) for path in brief_files(local)]
    claimed = claimed_worktrees(local, remote)
    checkouts = [inspect_checkout(worktree, local, claimed, now) for worktree in detached_checkouts(local)]
    return briefs + checkouts


def remove(verdict: Verdict, remote: Remote, transcripts: Mapping[str, float]) -> tuple[bool, list[str]]:
    """Removes one thing marked sweep if it still is; whether it went, and what to print."""
    local, now = read_local(), time.time()
    if verdict.kind == BRIEF:
        path = local.main / ".claude" / "briefs" / verdict.name
        again = inspect_brief(path, local, remote, transcripts, now)
    else:
        named = [worktree for worktree in detached_checkouts(local) if worktree.path.name == verdict.name]
        if not named:
            return False, [f"keep {CHECKOUT} {verdict.name}: no longer a detached checkout"]
        again = inspect_checkout(named[0], local, claimed_worktrees(local, remote), now)
    if not again.sweep:
        return False, [
            f"keep {again.kind} {again.name}: changed since it was listed: {again.reason}",
            *again.lines()[1:],
        ]
    if verdict.kind == BRIEF:
        try:
            path.unlink()
        except OSError as e:
            return False, [f"keep {BRIEF} {verdict.name}: could not delete it: {e}"]
        return True, [f"removed {BRIEF} {verdict.name}: {again.reason}"]
    result = run([str(AGENT_SETUP), "--remove", verdict.name], cwd=local.main)
    if result.returncode != 0:
        refusal = (result.stderr or result.stdout).strip().splitlines()
        return False, [
            f"keep {CHECKOUT} {verdict.name}: tools/agent-setup.sh --remove refused it:",
            *(f"    {line}" for line in refusal),
        ]
    if (local.main / ".claude" / "worktrees" / verdict.name).exists():
        # The remover's exit status is not the directory: a name it reads as a flag exits 0 too.
        still = "tools/agent-setup.sh --remove exited 0 and the directory is still there"
        return False, [f"keep {CHECKOUT} {verdict.name}: {still}"]
    return True, [f"removed {CHECKOUT} {verdict.name}: {again.reason}"]


def summary(kind: str, plural: str, verdicts: list[Verdict], removed: set[tuple[str, str]], applied: bool) -> str:
    mine = [verdict for verdict in verdicts if verdict.kind == kind]
    marked = [verdict for verdict in mine if verdict.sweep]
    kept = Counter(verdict.group for verdict in mine if not verdict.sweep)
    went = sum(1 for verdict in marked if (verdict.kind, verdict.name) in removed)
    kept_total = len(mine) - len(marked)
    words = [f"{count} {group}{' (not listed)' if group == OTHER_KIND else ''}" for group, count in kept.most_common()]
    why = f" ({', '.join(words)})" if words else ""
    if not applied:
        return f"{plural}: {len(marked)} to sweep, {kept_total} kept{why}"
    refused = f", {len(marked) - went} marked sweep and not removed" if went < len(marked) else ""
    return f"{plural}: {went} removed{refused}, {kept_total} kept{why}"


def existing_dir(text: str) -> Path:
    path = Path(text)
    if not path.is_dir():
        raise argparse.ArgumentTypeError(f"no such folder: {text}")
    return path


def parser() -> argparse.ArgumentParser:
    # No abbreviations: `--a` is not the explicit --apply the removing run is asked for by.
    p = argparse.ArgumentParser(
        prog="sweep-agent-leftovers.py",
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
        allow_abbrev=False,
    )
    p.add_argument(
        "--apply",
        action="store_true",
        help="remove what is marked sweep, after checking each thing again; without it nothing is removed",
    )
    p.add_argument(
        "--project-dir",
        type=existing_dir,
        metavar="DIR",
        help="the folder holding the sessions' transcripts; default: Claude Code's folder for the main checkout",
    )
    return p


def main(argv: list[str] | None = None) -> int:
    args = parser().parse_args(argv)
    try:
        local = read_local()
        transcripts = transcript_times(args.project_dir or default_project_dir(local.main))
        remote = read_remote(local.main)
        verdicts = inventory(local, remote, transcripts, time.time())
    except SweepError as e:
        print(f"sweep-agent-leftovers.py: {e}; nothing was removed", file=sys.stderr)
        return 1
    removed: set[tuple[str, str]] = set()
    failed = False
    for verdict in verdicts:
        if verdict.group == OTHER_KIND:
            continue
        if not (args.apply and verdict.sweep):
            print("\n".join(verdict.lines()))
            continue
        try:
            went, lines = remove(verdict, remote, transcripts)
        except SweepError as e:
            went, lines = False, [f"keep {verdict.kind} {verdict.name}: {e}"]
        print("\n".join(lines))
        if went:
            removed.add((verdict.kind, verdict.name))
        else:
            failed = True
    print()
    print(summary(BRIEF, "briefs", verdicts, removed, args.apply))
    print(summary(CHECKOUT, "checkouts", verdicts, removed, args.apply))
    if not args.apply:
        print("Nothing was removed. --apply removes what is marked sweep, after checking each thing again.")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
