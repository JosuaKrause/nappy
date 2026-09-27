#!/usr/bin/env python3
"""Print a version tag's release notes as Markdown, computed from git alone.

    tools/release-notes.py v0.20.0
    tools/release-notes.py v0.20.1 --commit HEAD    # a tag that does not exist yet

No model and no network call anything here: the notes are one bullet per commit's own subject
line, grouped by what the commit changed, plus a compare link -- all of it read out of the local
git history.

**Range.** A patch tag (`vX.Y.Z`, `Z>0`) covers everything since the previous tag. A minor tag
(`vX.Y.0`) covers everything since the previous `.0` tag, so any patches in between are folded in;
a major tag (`vX.0.0`) is treated the same as a minor one -- since the previous `.0` tag -- which is
open to overturn (the player asked only about a minor and a patch release; a major one just
reuses the same rule rather than leaving it undefined). The "previous" tag is found with `git tag
--merged <commit>`, which lists every `v*` tag that is an ancestor of (or equal to) that commit, so
this needs no assumption that tags were created in version order. The first tag ever -- nothing
found by that search -- covers from the root of history.

**Content.** One bullet per commit on `main`'s first-parent history in the range, its subject line
verbatim -- this repository's own convention (see .claude/skills/committing/SKILL.md, "The squash
commit is the pull request's title and description") already ends every one in `(#N)`, which GitHub
turns into a pull request link wherever the notes are posted. Commits are grouped into two
sections, newest first: **Game** for a commit that touched `src/`, `art/`, `assets/`, `scenes/`,
`project.godot` or `icon.png`, **Tooling and docs** for everything else. An empty section is
omitted entirely, and so is the compare link when there is no previous tag to compare against.

**Why these paths are "Game".** `export_presets.cfg`'s Web preset packs `export_filter=
"all_resources"` -- everything Godot's own import pass sees -- into the `.pck`, except a directory
carrying its own `.gdignore` (`art/.gdignore`, `tools/.gdignore`, `docs/.gdignore` exclude those
three trees from the import pass entirely) or a path `export_presets.cfg`'s own `exclude_filter`
names. So `assets/`, `scenes/`, `project.godot` and `icon.png` ship inside the `.pck`, and `src/`'s
own `.gd` files compile into it. `art/` itself carries a `.gdignore` and never reaches the `.pck`
as source, but `tools/export-web.sh` runs `tools/bake-atlases.sh` before exporting, which bakes
every picture `assets/atlases/membership.json` names -- `art/buildings/*.svg`, `art/events/*.svg`,
`art/props/*.svg` and the rest -- into `assets/atlases/baked/`, and that directory is what actually
ships inside the `.pck`. So a change under `art/` reaches the build as the baked atlases' own
source; `.github/workflows/deploy.yml`'s "Publish the social card image" step, which copies
`art/social-card.png` straight into `build/web/`, is a second, narrower reason. Everything else --
`tools/`, `tests/`, `docs/`, `.claude/`, `.github/`, `.codex/`, the repository's own top-level
tooling files (`pyproject.toml`, `uv.lock`, `.python-version`), `README.md`, the license files --
is Tooling and docs.

Run through the locked environment: `uv run python tools/release-notes.py <tag>`.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

TAG_RE = re.compile(r"^v(\d+)\.(\d+)\.(\d+)$")

Version = tuple[int, int, int]

# See the module docstring's "Why these paths are 'Game'" for the reasoning behind each entry.
GAME_PREFIXES = ("src/", "art/", "assets/", "scenes/")
GAME_FILES = ("project.godot", "icon.png")


class ReleaseNotesError(RuntimeError):
    """A refusal that should print a message and exit non-zero rather than a traceback."""


def run_git(args: list[str], *, cwd: Path = ROOT) -> str:
    result = subprocess.run(["git", *args], cwd=cwd, capture_output=True, text=True, check=False)
    if result.returncode != 0:
        raise ReleaseNotesError(f"git {' '.join(args)} failed: {result.stderr.strip()}")
    return result.stdout


def parse_tag(tag: str) -> Version:
    match = TAG_RE.fullmatch(tag)
    if not match:
        raise ReleaseNotesError(f"{tag!r} is not a vMAJOR.MINOR.PATCH tag")
    return (int(match.group(1)), int(match.group(2)), int(match.group(3)))


def tag_str(version: Version) -> str:
    return f"v{version[0]}.{version[1]}.{version[2]}"


def resolve_commit(tag: str, commit: str | None, *, cwd: Path) -> str:
    """The commit `tag` should be read as: `commit` when the tag does not exist yet (a dry run
    previewing a release before it is tagged), else `tag`'s own commit, dereferencing an annotated
    tag the same way `tools/release.sh` does."""
    if commit is not None:
        return run_git(["rev-parse", commit], cwd=cwd).strip()
    try:
        return run_git(["rev-parse", f"{tag}^{{commit}}"], cwd=cwd).strip()
    except ReleaseNotesError as error:
        raise ReleaseNotesError(
            f"no tag {tag!r} in this repository -- pass --commit for a tag that does not exist yet"
        ) from error


def ancestor_version_tags(until: str, *, exclude: str, cwd: Path) -> list[Version]:
    """Every `v<digits>.<digits>.<digits>` tag that is `until` itself or an ancestor of it, parsed,
    `exclude` left out by name. `git tag --merged` is the ancestor test."""
    output = run_git(["tag", "--merged", until, "-l", "v[0-9]*"], cwd=cwd)
    versions = []
    for line in output.splitlines():
        name = line.strip()
        if not name or name == exclude:
            continue
        try:
            versions.append(parse_tag(name))
        except ReleaseNotesError:
            continue
    return versions


def find_predecessor(versions: list[Version], level: str) -> Version | None:
    pool = versions if level == "patch" else [v for v in versions if v[2] == 0]
    return max(pool) if pool else None


def commit_range(since: str | None, until: str, *, cwd: Path) -> list[tuple[str, str]]:
    """`[(commit hash, subject)]` on `until`'s first-parent history, newest first, since `since`
    exclusive -- or from the root when `since` is None (the first tag ever)."""
    range_arg = f"{since}..{until}" if since else until
    output = run_git(["log", "--first-parent", "--format=%H%x1f%s", range_arg], cwd=cwd)
    commits = []
    for line in output.splitlines():
        if not line:
            continue
        commit_hash, _, subject = line.partition("\x1f")
        commits.append((commit_hash, subject))
    return commits


def changed_paths(commit_hash: str, *, cwd: Path) -> list[str]:
    """The paths `commit_hash` changed. Plain `git diff-tree -r` prints nothing for a merge commit
    (it needs `-m --first-parent` to diff against the first parent instead of showing no combined
    diff) or for the repository's own root commit (it needs `--root` to be diffed against the
    empty tree instead of being treated as having no parent to diff against at all) -- either gap
    would sort that commit as Tooling regardless of what it actually changed."""
    output = run_git(
        ["diff-tree", "--root", "-m", "--first-parent", "--no-commit-id", "--name-only", "-r", commit_hash],
        cwd=cwd,
    )
    return [line for line in output.splitlines() if line]


def is_game_change(paths: list[str]) -> bool:
    return any(path in GAME_FILES or any(path.startswith(prefix) for prefix in GAME_PREFIXES) for path in paths)


def default_repo_slug(*, cwd: Path) -> str | None:
    try:
        url = run_git(["remote", "get-url", "origin"], cwd=cwd).strip()
    except ReleaseNotesError:
        return None
    match = re.search(r"github\.com[:/]([^/]+/[^/.]+)(?:\.git)?/?$", url)
    return match.group(1) if match else None


def render_notes(
    commits: list[tuple[str, str]],
    *,
    since: str | None,
    until_tag: str,
    repo_slug: str | None,
    cwd: Path,
) -> str:
    game_lines: list[str] = []
    tooling_lines: list[str] = []
    for commit_hash, subject in commits:
        paths = changed_paths(commit_hash, cwd=cwd)
        (game_lines if is_game_change(paths) else tooling_lines).append(f"- {subject}")

    sections = []
    if game_lines:
        sections.append("## Game\n" + "\n".join(game_lines))
    if tooling_lines:
        sections.append("## Tooling and docs\n" + "\n".join(tooling_lines))

    body = "\n\n".join(sections)
    if since and repo_slug:
        compare = f"**Full Changelog**: https://github.com/{repo_slug}/compare/{since}...{until_tag}"
        body = f"{body}\n\n{compare}" if body else compare
    return f"{body}\n" if body else ""


def build_notes(tag: str, *, commit: str | None = None, repo: str | None = None, cwd: Path = ROOT) -> str:
    version = parse_tag(tag)
    until = resolve_commit(tag, commit, cwd=cwd)
    level = "patch" if version[2] > 0 else "minor-or-major"
    versions = ancestor_version_tags(until, exclude=tag, cwd=cwd)
    predecessor = find_predecessor(versions, level)
    since = tag_str(predecessor) if predecessor else None
    commits = commit_range(since, until, cwd=cwd)
    repo_slug = repo or default_repo_slug(cwd=cwd)
    return render_notes(commits, since=since, until_tag=tag, repo_slug=repo_slug, cwd=cwd)


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="tools/release-notes.py",
        description=(
            "Prints TAG's release notes as Markdown: one bullet per commit's subject line since the"
            " previous tag (folding in every patch since the previous .0 tag for a minor or major"
            " tag), grouped into a Game and a Tooling and docs section, with a compare link. Computed"
            " from the local git history alone -- no model, no network call."
        ),
        epilog="  tools/release-notes.py v0.20.0\n  tools/release-notes.py v0.20.1 --commit HEAD\n",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("tag", help="the vMAJOR.MINOR.PATCH tag to print notes for")
    parser.add_argument(
        "--commit",
        metavar="COMMITTISH",
        help="the commit TAG would point at, for a tag that does not exist yet (tools/release.sh's dry run)",
    )
    parser.add_argument(
        "--repo",
        metavar="OWNER/REPO",
        help="the compare link's repository slug, instead of parsing origin's remote URL",
    )
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    try:
        notes = build_notes(args.tag, commit=args.commit, repo=args.repo)
    except ReleaseNotesError as error:
        print(f"refusing: {error}", file=sys.stderr)
        return 1
    sys.stdout.write(notes)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
