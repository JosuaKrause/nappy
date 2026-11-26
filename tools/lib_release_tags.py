"""The grammar of this repository's version tags, and what follows from a set of them.

Two kinds of tag start with `v`:

- **a release**, `vX.Y.Z`: what `tools/release.sh <part>` cuts and the site's root serves;
- **a release candidate (RC)**, `vX.Y.Z-rc.N`: what `tools/release.sh rc <part>` cuts, the
  release `vX.Y.Z` it is a candidate for (its *target*) with a counter, served at `/rc/`.

Every reader of tags reads them through here, so an RC is never taken for a release: the next
release number (`tools/release.sh`), the previous release a tag's notes start from
(`tools/release-notes.py`), the windows `tools/goatcounter.py --by-release` cuts, and which
release and which candidate a deploy publishes (`tools/release-tags.py site`).

**Which candidate a deploy publishes.** The newest release is served at the root. The newest
candidate is served at `/rc/` while its target is above that release, so a patch release removes a
candidate only once it reaches the candidate's own number. **A minor or major release removes every
candidate cut before it, whatever its target** (the player's rule: a minor release removes the
RC): a candidate whose commit is the newest `.0` release's commit or an ancestor of it is not
published. That is read from the history rather than from the tags' dates, so the answer is the
same on every machine and on every re-run of a deploy.
"""

from __future__ import annotations

import re
import subprocess
from collections.abc import Callable, Iterable
from pathlib import Path

RELEASE_RE = re.compile(r"v(\d+)\.(\d+)\.(\d+)")
CANDIDATE_RE = re.compile(r"v(\d+)\.(\d+)\.(\d+)-rc\.(\d+)")

PARTS = ("major", "minor", "patch")

Version = tuple[int, int, int]
Candidate = tuple[Version, int]

# Whether the first tag's commit is the second tag's commit or an ancestor of it.
IsAncestor = Callable[[str, str], bool]


class TagError(RuntimeError):
    """A refusal that should print a message and exit non-zero rather than a traceback."""


def parse_release(name: str) -> Version | None:
    """`vX.Y.Z`'s three numbers, or None for any other name (an RC included)."""
    match = RELEASE_RE.fullmatch(name)
    if not match:
        return None
    return (int(match.group(1)), int(match.group(2)), int(match.group(3)))


def parse_candidate(name: str) -> Candidate | None:
    """`vX.Y.Z-rc.N`'s target and counter, or None for any other name (a release included)."""
    match = CANDIDATE_RE.fullmatch(name)
    if not match:
        return None
    target = (int(match.group(1)), int(match.group(2)), int(match.group(3)))
    return (target, int(match.group(4)))


def release_name(version: Version) -> str:
    return f"v{version[0]}.{version[1]}.{version[2]}"


def candidate_name(candidate: Candidate) -> str:
    return f"{release_name(candidate[0])}-rc.{candidate[1]}"


def kind(name: str) -> str | None:
    """`release`, `candidate`, or None for a name that is neither."""
    if parse_release(name) is not None:
        return "release"
    if parse_candidate(name) is not None:
        return "candidate"
    return None


def releases(names: Iterable[str]) -> list[Version]:
    return sorted(v for v in (parse_release(n) for n in names) if v is not None)


def candidates(names: Iterable[str]) -> list[Candidate]:
    return sorted(c for c in (parse_candidate(n) for n in names) if c is not None)


def latest_release(names: Iterable[str]) -> Version | None:
    found = releases(names)
    return found[-1] if found else None


def bump(version: Version, part: str) -> Version:
    if part == "major":
        return (version[0] + 1, 0, 0)
    if part == "minor":
        return (version[0], version[1] + 1, 0)
    if part == "patch":
        return (version[0], version[1], version[2] + 1)
    raise TagError(f"{part!r} is not one of {', '.join(PARTS)}")


def next_release(names: Iterable[str], part: str) -> Version:
    """The latest release bumped by `part`, from `v0.0.0` when there is none."""
    return bump(latest_release(names) or (0, 0, 0), part)


def next_candidate(names: Iterable[str], part: str) -> Candidate:
    """The next release `part` names, with a counter one above the last candidate for it."""
    listed = list(names)
    target = next_release(listed, part)
    counters = [n for t, n in candidates(listed) if t == target]
    return (target, max(counters, default=0) + 1)


def published_candidate(names: Iterable[str], is_ancestor: IsAncestor) -> str | None:
    """The candidate a deploy serves at `/rc/` beside the newest release, or None (the module's
    docstring says which)."""
    listed = list(names)
    release = latest_release(listed)
    dot_zero = [v for v in releases(listed) if v[2] == 0]
    newest_dot_zero = release_name(dot_zero[-1]) if dot_zero else None
    for candidate in reversed(candidates(listed)):
        if release is not None and candidate[0] <= release:
            continue
        name = candidate_name(candidate)
        if newest_dot_zero is not None and is_ancestor(name, newest_dot_zero):
            continue
        return name
    return None


# ------------------------------------------------------------------ git ---


def run_git(args: list[str], *, cwd: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(["git", *args], cwd=cwd, capture_output=True, text=True, check=False)


def tag_names(cwd: Path) -> list[str]:
    """Every tag starting with `v`, as git lists it."""
    result = run_git(["tag", "-l", "v*"], cwd=cwd)
    if result.returncode != 0:
        raise TagError(f"git tag -l failed: {result.stderr.strip()}")
    return [line.strip() for line in result.stdout.splitlines() if line.strip()]


def git_is_ancestor(cwd: Path) -> IsAncestor:
    """`git merge-base --is-ancestor` on two tags' commits, which answers yes for one commit too."""

    def answer(first: str, second: str) -> bool:
        result = run_git(["merge-base", "--is-ancestor", f"{first}^{{commit}}", f"{second}^{{commit}}"], cwd=cwd)
        if result.returncode not in (0, 1):
            raise TagError(f"git merge-base --is-ancestor {first} {second} failed: {result.stderr.strip()}")
        return result.returncode == 0

    return answer
