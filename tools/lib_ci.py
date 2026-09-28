"""What CI's pull request checks share: the PR's changed files, its description, and one text normalization.

The checks under `tools/ci_*.py` each answer one question about a pull request, and each needs the
same three inputs, so they are read here once:

- **The changed files**, from `git diff --raw --no-renames <base>...<head>`: three dots, so the
  diff runs from where the branch started rather than from today's tip of the base, and no rename
  detection, so a renamed file is a deletion and an addition. `--raw` gives each side's blob id
  without reading any blob, which matters on CI's partial clone (`filter: blob:none`), where a blob
  is a network fetch. The PR's files, never its title, decide what kind of PR it is, since the
  agent writes the title and can get it wrong.
- **The description**, read through GitHub's API when the check runs (`gh api
  repos/<repo>/pulls/<n>`), never from the event that started the run: editing a description
  starts no run, so a description corrected after a red check is re-checked by re-running the job,
  and that re-run has to see the new text.
- **A normalization for "verbatim"**, `normalize()`, used wherever a check asks whether words the
  player wrote appear in a playtest file: a playtest wraps a quote across lines and marks it with
  `> `, and the words stay the same words.
"""

from __future__ import annotations

import json
import os
import re
import subprocess
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# The base a local run compares against when none is given; CI passes the PR's own base branch.
DEFAULT_BASE = "origin/main"

# A line of the description may carry a list marker before its keyword (`- Filed from #12`,
# `1. Filed from #12`).
LIST_MARKER = r"^[ \t]*(?:(?:[-*+]|\d+[.)])[ \t]+)?"


class CiError(Exception):
    """An input the check needs could not be read: git or gh failed, or answered in a shape not expected."""


@dataclass(frozen=True)
class Change:
    """One file the pull request changes: git's one-letter status (A, M, D, T) and each side's blob id."""

    status: str
    path: str
    old_blob: str
    new_blob: str


def git(*args: str, cwd: Path = ROOT) -> str:
    result = subprocess.run(["git", *args], cwd=cwd, capture_output=True, text=True, check=False)
    if result.returncode != 0:
        raise CiError(f"git {' '.join(args)} failed: {result.stderr.strip()}")
    return result.stdout


def parse_raw_diff(raw: str) -> list[Change]:
    """Parses `git diff --raw -z --no-renames --no-abbrev` output into one `Change` per file."""
    changes: list[Change] = []
    fields = raw.split("\0")
    index = 0
    while index < len(fields) and fields[index]:
        header = fields[index]
        if not header.startswith(":") or index + 1 >= len(fields):
            raise CiError(f"unexpected git diff --raw record: {header!r}")
        parts = header[1:].split()
        if len(parts) != 5:
            raise CiError(f"unexpected git diff --raw header: {header!r}")
        _old_mode, _new_mode, old_blob, new_blob, status = parts
        changes.append(Change(status=status[0], path=fields[index + 1], old_blob=old_blob, new_blob=new_blob))
        index += 2
    return changes


def changed_files(base: str, head: str = "HEAD", cwd: Path = ROOT) -> list[Change]:
    """Every file the branch changes since it left `base`, renames split into a deletion and an addition."""
    return parse_raw_diff(git("diff", "--raw", "-z", "--no-renames", "--no-abbrev", f"{base}...{head}", cwd=cwd))


def under(path: str, *folders: str) -> bool:
    """True when `path` sits inside one of `folders` (each given without a trailing slash)."""
    return any(path.startswith(folder + "/") for folder in folders)


def default_repo() -> str:
    """`owner/name`: GitHub Actions' own variable in CI, otherwise what `gh` resolves for this checkout."""
    repo = os.environ.get("GITHUB_REPOSITORY", "")
    if repo:
        return repo
    result = subprocess.run(
        ["gh", "repo", "view", "--json", "nameWithOwner", "-q", ".nameWithOwner"],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0 or not result.stdout.strip():
        raise CiError(f"could not tell which repository this is; pass --repo ({result.stderr.strip()})")
    return result.stdout.strip()


def default_pr() -> int | None:
    """The pull request number CI puts in `PR_NUMBER`, or None outside a pull request run."""
    value = os.environ.get("PR_NUMBER", "")
    return int(value) if value.isdigit() else None


def gh_api(endpoint: str) -> dict[str, object]:
    """One GET through `gh api`; the token is `gh`'s own (`GH_TOKEN` in CI)."""
    result = subprocess.run(["gh", "api", endpoint], cwd=ROOT, capture_output=True, text=True, check=False)
    if result.returncode != 0:
        raise CiError(f"gh api {endpoint} failed: {result.stderr.strip()}")
    data = json.loads(result.stdout)
    if not isinstance(data, dict):
        raise CiError(f"gh api {endpoint} did not return an object")
    return data


def pr_description(repo: str, number: int) -> str:
    """The pull request's description as it stands now, not as it stood when the run started."""
    body = gh_api(f"repos/{repo}/pulls/{number}").get("body")
    return body if isinstance(body, str) else ""


FENCE = re.compile(r"^[ \t]{0,3}(`{3,}|~{3,})")


def without_fences(description: str) -> str:
    """The description with every fenced code block blanked, fence lines included, line breaks kept.

    A description that shows a line's form inside a fence -- a `Filed from #N`, a `Dropped:` or a
    `No queue item:` quoted as an example -- is explaining the line, not writing it, so no check
    that reads the description matches inside one. A fence opens with three or more backticks or
    tildes and closes with at least as many of the same; one left open runs to the end, as
    GitHub renders it.
    """
    lines = description.replace("\r\n", "\n").split("\n")
    kept: list[str] = []
    fence = ""
    for line in lines:
        match = FENCE.match(line)
        if not fence:
            if match:
                fence = match.group(1)
                kept.append("")
            else:
                kept.append(line)
            continue
        # A closing fence is the same character, at least as long, and nothing after it.
        closes = match is not None and match.group(1)[0] == fence[0] and len(match.group(1)) >= len(fence)
        if closes and not line.strip().lstrip(fence[0]):
            fence = ""
        kept.append("")
    return "\n".join(kept)


def normalize(text: str) -> str:
    """The text as words: blockquote markers dropped from each line's start, every run of whitespace one space.

    This is what "verbatim" means to every check comparing the player's words with a playtest
    file: a playtest quotes a note inside `> ` lines, wrapped wherever the file wraps, and an issue
    or a PR description wraps wherever its author pressed return. Nothing else is forgiven: a
    changed word, a changed letter's case, a changed punctuation mark or a straightened quote mark
    is a difference.
    """
    lines = [re.sub(r"^[ \t]*(?:>[ \t]?)+", "", line) for line in text.replace("\r\n", "\n").split("\n")]
    return " ".join(" ".join(lines).split())


def playtest_texts(cwd: Path = ROOT) -> dict[str, str]:
    """Every playtest file in the working tree, by its path relative to the repository."""
    folder = cwd / "docs" / "playtests"
    return {f"docs/playtests/{path.name}": path.read_text(encoding="utf-8") for path in sorted(folder.glob("*.md"))}


def write_summary(markdown: str) -> None:
    """Appends to the job's summary page in CI (`GITHUB_STEP_SUMMARY`); prints it anywhere else."""
    target = os.environ.get("GITHUB_STEP_SUMMARY", "")
    if target:
        with Path(target).open("a", encoding="utf-8") as handle:
            handle.write(markdown.rstrip("\n") + "\n")
    else:
        print(markdown.rstrip("\n"))


def report(name: str, failures: list[str], passed: str) -> int:
    """Prints each failure as `FAILED: ...` and returns the exit code; every failure names the file and the rule."""
    if failures:
        for failure in failures:
            print(f"FAILED: {failure}")
        print(f"{name}: {len(failures)} failure(s)")
        return 1
    print(f"OK: {passed}")
    return 0
