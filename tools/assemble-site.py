#!/usr/bin/env python3
"""Lay out the Pages site a deploy publishes: the release at the root, the candidate under `rc/`.

    tools/assemble-site.py --release build/release --candidate build/candidate \\
        --social-card art/social-card.png --out build/site
    tools/assemble-site.py --release build/release --social-card art/social-card.png --out build/site

GitHub Pages keeps nothing between deploys, so every deploy publishes the whole site in one
artifact: the newest release's Web export (`tools/export-web.sh`'s `build/web/`) at the root, and
the newest release candidate's export, a separate build of its own commit, under `rc/` with its
own versioned directory inside (`.claude/skills/committing/references/releasing.md`;
`tools/release-tags.py site` says which two). Each export's page names its files by relative
paths, so the candidate's page works unchanged one directory down.

Two small pages tie the two together, written here rather than in the export, since the release
at the root may be a build of a commit from before they existed:

- **The root page forwards `?rc=1` to `rc/`**, its query kept, by a script put at the top of its
  `<head>` before the engine's own scripts.
- **With no candidate published, `rc/` holds a page that forwards to the root**, its query kept
  but for `rc`, so an old link to the candidate plays the release (the title screen's version
  says which build it is) and the two forwards can never send a page back and forth.

The social card the root page's `og:image` names is copied beside it (`export_presets.cfg`).
"""

from __future__ import annotations

import argparse
import re
import shutil
import sys
from pathlib import Path

CANDIDATE_DIR = "rc"

# Put first in the root page's <head>: a page asked for ?rc=1 goes to the candidate at once.
ROOT_FORWARD = (
    "<script>if (new URLSearchParams(location.search).get('rc') === '1') "
    "{ location.replace('rc/' + location.search + location.hash) }</script>"
)

# rc/index.html when no candidate is published: back to the root, without the rc parameter that
# would send it straight here again.
EMPTY_CANDIDATE_PAGE = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Nappy</title>
<meta name="robots" content="noindex">
<script>var query = new URLSearchParams(location.search); query.delete('rc');
var rest = query.toString();
location.replace('../' + (rest ? '?' + rest : '') + location.hash)</script>
</head>
<body><p>No release candidate is out right now. <a href="../">Play the release.</a></p></body>
</html>
"""

HEAD_RE = re.compile(r"<head(\s[^>]*)?>", re.IGNORECASE)


class AssembleError(RuntimeError):
    """A refusal that should print a message and exit non-zero rather than a traceback."""


def check_export(directory: Path, label: str) -> None:
    if not (directory / "index.html").is_file():
        raise AssembleError(f"the {label} export {directory} has no index.html")


def add_root_forward(page: Path) -> None:
    html = page.read_text(encoding="utf-8")
    heads = HEAD_RE.findall(html)
    if len(heads) != 1:
        raise AssembleError(f"expected exactly one <head> in {page}, found {len(heads)}")
    html = HEAD_RE.sub(lambda match: match.group(0) + ROOT_FORWARD, html, count=1)
    page.write_text(html, encoding="utf-8")


def assemble(release: Path, candidate: Path | None, social_card: Path, out: Path) -> None:
    check_export(release, "release")
    if candidate is not None:
        check_export(candidate, "candidate")
    if not social_card.is_file():
        raise AssembleError(f"no social card at {social_card}")
    if (release / CANDIDATE_DIR).exists():
        raise AssembleError(f"the release export already has a {CANDIDATE_DIR}/ of its own")
    if out.exists() and any(out.iterdir()):
        raise AssembleError(f"{out} is not empty")

    shutil.copytree(release, out, dirs_exist_ok=True)
    add_root_forward(out / "index.html")
    shutil.copy2(social_card, out / "social-card.png")
    if candidate is not None:
        shutil.copytree(candidate, out / CANDIDATE_DIR)
    else:
        (out / CANDIDATE_DIR).mkdir()
        (out / CANDIDATE_DIR / "index.html").write_text(EMPTY_CANDIDATE_PAGE, encoding="utf-8")


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="tools/assemble-site.py",
        description=(
            "Lays out the Pages site a deploy publishes: the release export at the root with a"
            " forward of ?rc=1 to rc/, and the candidate export under rc/, or a page there that"
            " forwards to the root when no candidate is given."
        ),
        epilog=(
            "  tools/assemble-site.py --release build/release --candidate build/candidate \\\n"
            "      --social-card art/social-card.png --out build/site\n"
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("--release", required=True, type=Path, metavar="DIR", help="the release's Web export")
    parser.add_argument("--candidate", type=Path, metavar="DIR", help="the candidate's Web export, if one is out")
    parser.add_argument(
        "--social-card", required=True, type=Path, metavar="PNG", help="the image the root page's og:image names"
    )
    parser.add_argument("--out", required=True, type=Path, metavar="DIR", help="where the site goes (empty or new)")
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    try:
        assemble(args.release, args.candidate, args.social_card, args.out)
    except AssembleError as error:
        print(f"refusing: {error}", file=sys.stderr)
        return 1
    published = (
        f"{args.candidate} under {CANDIDATE_DIR}/" if args.candidate else f"no candidate ({CANDIDATE_DIR}/ forwards)"
    )
    print(f"assembled {args.out}: {args.release} at the root, {published}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
