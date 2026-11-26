#!/usr/bin/env python3
"""Answer questions about this repository's version tags, through one grammar.

    tools/release-tags.py latest                  # the newest release tag
    tools/release-tags.py next minor              # the release `tools/release.sh minor` cuts
    tools/release-tags.py next minor --rc         # the candidate `tools/release.sh rc minor` cuts
    tools/release-tags.py kind v0.31.0-rc.2       # release, candidate, or a refusal
    tools/release-tags.py site                    # what a deploy publishes, for $GITHUB_OUTPUT

A release is `vX.Y.Z` and a release candidate (RC) `vX.Y.Z-rc.N`; `tools/lib_release_tags.py`
holds the grammar and the rules, and its docstring says which candidate a deploy publishes.
`tools/release.sh` reads `latest` and `next`, `.github/workflows/deploy.yml` reads `kind` and
`site`. Every answer is read from the local git repository alone.

Run through the locked environment: `uv run python tools/release-tags.py <question>`.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import lib_release_tags as tags

ROOT = Path(__file__).resolve().parent.parent


def answer(args: argparse.Namespace, cwd: Path) -> str:
    """The text a question prints, newline-terminated, or "" for none."""
    if args.question == "latest":
        latest = tags.latest_release(tags.tag_names(cwd))
        return f"{tags.release_name(latest)}\n" if latest else ""
    if args.question == "next":
        names = tags.tag_names(cwd)
        if args.rc:
            return f"{tags.candidate_name(tags.next_candidate(names, args.part))}\n"
        return f"{tags.release_name(tags.next_release(names, args.part))}\n"
    if args.question == "kind":
        found = tags.kind(args.tag)
        if found is None:
            raise tags.TagError(f"{args.tag!r} is neither a vX.Y.Z release nor a vX.Y.Z-rc.N candidate")
        return f"{found}\n"
    names = tags.tag_names(cwd)
    latest = tags.latest_release(names)
    if latest is None:
        raise tags.TagError("there is no vX.Y.Z release tag to publish at the root")
    candidate = tags.published_candidate(names, tags.git_is_ancestor(cwd))
    return f"release={tags.release_name(latest)}\ncandidate={candidate or ''}\n"


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="tools/release-tags.py",
        description=(
            "Answers questions about the version tags: a release is vX.Y.Z, a release candidate"
            " vX.Y.Z-rc.N. Read from the local git repository alone."
        ),
        epilog=(
            "  tools/release-tags.py latest\n"
            "  tools/release-tags.py next minor --rc\n"
            "  tools/release-tags.py kind v0.31.0-rc.2\n"
            "  tools/release-tags.py site\n"
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("-C", dest="repo", metavar="DIR", help="the git repository to read (default: this one)")
    questions = parser.add_subparsers(dest="question", required=True, metavar="QUESTION")
    questions.add_parser("latest", help="print the newest release tag, or nothing when there is none")
    nxt = questions.add_parser("next", help="print the next release tag, or with --rc the next candidate")
    nxt.add_argument("part", choices=tags.PARTS, help="the part of the latest release to bump")
    nxt.add_argument("--rc", action="store_true", help="the next candidate for that release instead")
    knd = questions.add_parser("kind", help="print release or candidate for TAG; refuse any other name")
    knd.add_argument("tag", help="the tag name to classify")
    questions.add_parser(
        "site",
        help="print release=<tag> and candidate=<tag or nothing>: what a deploy serves at / and /rc/",
    )
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    cwd = Path(args.repo) if args.repo else ROOT
    try:
        text = answer(args, cwd)
    except tags.TagError as error:
        print(f"refusing: {error}", file=sys.stderr)
        return 1
    sys.stdout.write(text)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
