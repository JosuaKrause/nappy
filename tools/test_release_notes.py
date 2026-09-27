#!/usr/bin/env python3
"""Integration tests for tools/release-notes.py, on a throwaway git repository in $TMPDIR.

A real repo, not a fixture of strings, because the whole point of the script is what `git tag
--merged`, `git log --first-parent` and `git diff-tree` say about a real history -- the range
rules (a patch since the previous tag, a minor folding the patches since the previous `.0` tag,
the first tag covering from the root) and the Game/Tooling split are properties of that history,
not of a data structure this file could construct by hand as easily.
"""

from __future__ import annotations

import importlib.util
import os
import subprocess
import tempfile
import unittest
from pathlib import Path
from types import ModuleType
from typing import Any

TOOLS = Path(__file__).resolve().parent

DATE = "2026-01-01T12:00:00+0000"


def load(name: str, file: str) -> ModuleType:
    spec = importlib.util.spec_from_file_location(name, TOOLS / file)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


rn = load("release_notes", "release-notes.py")


class ReleaseNotesTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.repo = Path(self.temp.name)
        self.env = dict(
            os.environ,
            GIT_AUTHOR_DATE=DATE,
            GIT_COMMITTER_DATE=DATE,
            GIT_AUTHOR_NAME="t",
            GIT_AUTHOR_EMAIL="t@example.com",
            GIT_COMMITTER_NAME="t",
            GIT_COMMITTER_EMAIL="t@example.com",
        )
        self.git("init", "-q", "-b", "main")

    def git(self, *args: str) -> str:
        result = subprocess.run(["git", *args], cwd=self.repo, env=self.env, capture_output=True, text=True)
        if result.returncode != 0:
            raise AssertionError(f"git {' '.join(args)}: {result.stderr}")
        return result.stdout

    def commit(self, path: str, subject: str) -> str:
        target = self.repo / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(f"{subject}\n")
        self.git("add", "-A")
        self.git("commit", "-q", "-m", subject)
        return self.git("rev-parse", "HEAD").strip()

    def tag(self, name: str) -> None:
        self.git("tag", "-a", name, "-m", name)

    def notes(self, tag: str, **kwargs: str) -> Any:  # str, from a module loaded by path mypy cannot follow
        return rn.build_notes(tag, cwd=self.repo, **kwargs)

    # ---------------------------------------------------------------------------- range rules ---

    def test_first_tag_covers_from_the_root(self) -> None:
        self.commit("src/a.gd", "root game commit (#1)")
        self.tag("v0.0.0")
        out = self.notes("v0.0.0")
        self.assertIn("root game commit (#1)", out)
        self.assertNotIn("Full Changelog", out, "the first tag has no previous tag to compare against")

    def test_patch_covers_only_since_the_previous_tag(self) -> None:
        self.commit("src/a.gd", "root game commit (#1)")
        self.tag("v0.0.0")
        self.commit("docs/a.md", "docs only (#2)")
        self.tag("v0.1.0")
        self.commit("tools/a.py", "tooling patch (#3)")
        self.tag("v0.1.1")
        self.commit("src/b.gd", "game patch (#4)")
        self.tag("v0.1.2")

        out_patch_one = self.notes("v0.1.1", repo="owner/repo")
        self.assertIn("tooling patch (#3)", out_patch_one)
        self.assertNotIn("docs only (#2)", out_patch_one)
        self.assertIn("compare/v0.1.0...v0.1.1", out_patch_one)

        out_patch_two = self.notes("v0.1.2", repo="owner/repo")
        self.assertIn("game patch (#4)", out_patch_two)
        self.assertNotIn("tooling patch (#3)", out_patch_two, "v0.1.2 must not fold in the previous patch")
        self.assertIn("compare/v0.1.1...v0.1.2", out_patch_two)

    def test_minor_folds_every_patch_since_the_previous_dot_zero_tag(self) -> None:
        self.commit("src/a.gd", "root game commit (#1)")
        self.tag("v0.0.0")
        self.commit("docs/a.md", "docs only (#2)")
        self.tag("v0.1.0")
        self.commit("tools/a.py", "tooling patch (#3)")
        self.tag("v0.1.1")
        self.commit("src/b.gd", "game patch (#4)")
        self.tag("v0.1.2")
        self.commit("docs/c.md", "unreleased docs (#5)")
        self.commit("assets/c.json", "unreleased game asset (#6)")
        self.tag("v0.2.0")

        out = self.notes("v0.2.0", repo="owner/repo")
        for subject in (
            "tooling patch (#3)",
            "game patch (#4)",
            "unreleased docs (#5)",
            "unreleased game asset (#6)",
        ):
            self.assertIn(subject, out, f"{subject!r} missing from the folded minor release")
        self.assertNotIn("docs only (#2)", out, "v0.2.0 must stop at the previous .0 tag, not the root")
        self.assertIn("compare/v0.1.0...v0.2.0", out, "the compare link must name the previous .0 tag")

        # Newest first, one block per section.
        game_index = out.index("## Game")
        tooling_index = out.index("## Tooling and docs")
        asset_index = out.index("unreleased game asset (#6)")
        patch_index = out.index("game patch (#4)")
        self.assertLess(game_index, tooling_index)
        self.assertLess(asset_index, patch_index, "the newer game commit must be listed first")

    def test_major_tag_is_treated_like_a_minor_tag(self) -> None:
        self.commit("src/a.gd", "root game commit (#1)")
        self.tag("v0.0.0")
        self.commit("docs/a.md", "docs only (#2)")
        self.tag("v0.1.0")
        self.commit("src/b.gd", "pre-major game commit (#3)")
        self.tag("v1.0.0")
        out = self.notes("v1.0.0", repo="owner/repo")
        self.assertIn("pre-major game commit (#3)", out)
        self.assertNotIn("docs only (#2)", out)
        self.assertIn("compare/v0.1.0...v1.0.0", out)

    def test_commit_override_previews_a_tag_that_does_not_exist_yet(self) -> None:
        self.commit("src/a.gd", "root game commit (#1)")
        self.tag("v0.0.0")
        self.commit("docs/a.md", "docs only (#2)")
        self.tag("v0.1.0")
        head = self.commit("src/b.gd", "not tagged yet (#3)")
        out = self.notes("v0.1.1", commit=head, repo="owner/repo")
        self.assertIn("not tagged yet (#3)", out)
        self.assertIn("compare/v0.1.0...v0.1.1", out)

    def test_missing_tag_without_commit_override_refuses(self) -> None:
        self.commit("src/a.gd", "root game commit (#1)")
        self.tag("v0.0.0")
        with self.assertRaises(rn.ReleaseNotesError):
            self.notes("v9.9.9")

    def test_malformed_tag_refuses(self) -> None:
        self.commit("src/a.gd", "root game commit (#1)")
        self.tag("v0.0.0")
        with self.assertRaises(rn.ReleaseNotesError):
            self.notes("not-a-tag")

    def test_first_parent_excludes_a_merged_side_branchs_own_commits(self) -> None:
        """Pins `commit_range`'s own `--first-parent` flag: dropping it from the `git log` call
        would leave every existing test passing (they all build a linear history), but it would
        leak a merged side branch's own commits into the notes. `main` here never carries a merge
        commit itself (the repository disallows one), but `commit_range` reads whatever tag it is
        given, so the flag still has to hold if an old tag is ever backfilled."""
        self.commit("src/a.gd", "root game commit (#1)")
        self.tag("v0.0.0")
        self.git("checkout", "-q", "-b", "feature")
        self.commit("src/side.gd", "side branch commit (#9)")
        self.git("checkout", "-q", "main")
        self.commit("src/main.gd", "main line commit (#10)")
        self.git("merge", "-q", "--no-ff", "-m", "Merge feature branch (#11)", "feature")
        self.tag("v0.1.0")

        out = self.notes("v0.1.0")
        self.assertIn("main line commit (#10)", out, "the first-parent line's own commit must be listed")
        self.assertNotIn(
            "side branch commit (#9)",
            out,
            "a commit reachable only through the merge's second parent must not be listed",
        )

    # ------------------------------------------------------------------------------ grouping ---

    def test_game_tooling_grouping_and_omitted_empty_section(self) -> None:
        self.commit("src/a.gd", "root game commit (#1)")
        self.tag("v0.0.0")
        self.commit("project.godot", "project settings change (#2)")
        self.commit("icon.png", "new app icon (#3)")
        self.commit("art/social-card.png", "new social card (#4)")
        self.commit("scenes/main.tscn", "scene tweak (#5)")
        self.tag("v0.1.0")
        out = self.notes("v0.1.0")
        self.assertIn("## Game", out)
        self.assertNotIn("## Tooling and docs", out, "an all-Game range must omit the empty section")
        for subject in (
            "project settings change (#2)",
            "new app icon (#3)",
            "new social card (#4)",
            "scene tweak (#5)",
        ):
            self.assertIn(subject, out)

    def test_a_commit_touching_both_kinds_of_path_counts_as_game(self) -> None:
        self.commit("src/a.gd", "root game commit (#1)")
        self.tag("v0.0.0")
        target = self.repo / "docs" / "a.md"
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text("docs\n")
        (self.repo / "src" / "b.gd").write_text("game\n")
        self.git("add", "-A")
        self.git("commit", "-q", "-m", "mixed commit (#2)")
        self.tag("v0.1.0")
        out = self.notes("v0.1.0")
        self.assertIn("## Game", out)
        self.assertNotIn("## Tooling and docs", out)
        self.assertIn("mixed commit (#2)", out)

    def test_a_pure_tooling_and_docs_range_omits_the_game_section(self) -> None:
        self.commit("src/a.gd", "root game commit (#1)")
        self.tag("v0.0.0")
        self.commit("tools/a.py", "tooling only (#2)")
        self.commit("docs/a.md", "docs only (#3)")
        self.tag("v0.1.0")
        out = self.notes("v0.1.0")
        self.assertNotIn("## Game", out)
        self.assertIn("## Tooling and docs", out)

    # ------------------------------------------------------------------------------- repo slug ---

    def test_repo_slug_is_read_from_the_origin_remote(self) -> None:
        self.commit("src/a.gd", "root game commit (#1)")
        self.tag("v0.0.0")
        self.commit("docs/a.md", "docs only (#2)")
        self.tag("v0.1.0")
        self.git("remote", "add", "origin", "git@github.com:JosuaKrause/nappy.git")
        out = self.notes("v0.1.0")
        self.assertIn("https://github.com/JosuaKrause/nappy/compare/v0.0.0...v0.1.0", out)

    def test_repo_flag_overrides_the_origin_remote(self) -> None:
        self.commit("src/a.gd", "root game commit (#1)")
        self.tag("v0.0.0")
        self.commit("docs/a.md", "docs only (#2)")
        self.tag("v0.1.0")
        self.git("remote", "add", "origin", "git@github.com:JosuaKrause/nappy.git")
        out = self.notes("v0.1.0", repo="someone-else/fork")
        self.assertIn("https://github.com/someone-else/fork/compare/v0.0.0...v0.1.0", out)

    def test_no_origin_remote_omits_the_compare_link_rather_than_failing(self) -> None:
        self.commit("src/a.gd", "root game commit (#1)")
        self.tag("v0.0.0")
        self.commit("docs/a.md", "docs only (#2)")
        self.tag("v0.1.0")
        out = self.notes("v0.1.0")
        self.assertNotIn("Full Changelog", out)
        self.assertIn("docs only (#2)", out)

    def test_output_is_deterministic(self) -> None:
        self.commit("src/a.gd", "root game commit (#1)")
        self.tag("v0.0.0")
        self.commit("docs/a.md", "docs only (#2)")
        self.tag("v0.1.0")
        self.assertEqual(self.notes("v0.1.0"), self.notes("v0.1.0"))


if __name__ == "__main__":
    unittest.main()
