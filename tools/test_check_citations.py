#!/usr/bin/env python3
"""`tools/check_citations.py` on a fixture tree: two playtests, a record, CLAUDE.md and a skill."""

from __future__ import annotations

import io
import sys
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path
from typing import ClassVar

sys.path.insert(0, str(Path(__file__).resolve().parent))

import check_citations


class CheckCitationsTests(unittest.TestCase):
    FILES: ClassVar[dict[str, str]] = {
        "docs/playtests/2026-10-17-woolly-penguin.md": "# Woolly penguin\n\n## #759\n\n> words\n",
        "docs/playtests/PLAYTEST-63.md": "# Playtest 63\n\n## A car crash\n",
        "docs/playtests/2026-10-03-twin-name.md": "# One\n",
        "docs/decisions/2026-10-04-twin-name.md": "# Two\n",
        "docs/decisions/2026-09-26-polite-marten.md": "# Polite marten\n",
        "README.md": "Not governed (no-such-name).\n",
    }

    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        for name, text in self.FILES.items():
            self.write(name, text)

    def write(self, name: str, text: str) -> None:
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")

    def run_check(self, *files: str) -> tuple[int, str, str]:
        out, err = io.StringIO(), io.StringIO()
        with redirect_stdout(out), redirect_stderr(err):
            code = check_citations.main(["--root", str(self.root), *files])
        return code, out.getvalue(), err.getvalue()

    def skill(self, text: str) -> None:
        self.write(".claude/skills/demo/SKILL.md", text)

    def test_bare_citations_that_resolve_pass(self) -> None:
        self.write("CLAUDE.md", "A rule (woolly-penguin #759). Another (PLAYTEST-63; polite-marten).\n")
        self.skill("Three\ntimes (woolly-penguin\n#759), split over lines.\n")
        code, out, _ = self.run_check()
        self.assertEqual((code, out), (0, ""))

    def test_a_link_into_the_playtests_is_flagged_once(self) -> None:
        self.skill("Line one.\nSee [three times](../../../docs/playtests/2026-10-17-woolly-penguin.md#759).\n")
        code, out, _ = self.run_check()
        self.assertEqual(code, 1)
        self.assertEqual(out.count("\n"), 1)
        self.assertIn(".claude/skills/demo/SKILL.md:2: a link into docs/playtests/", out)

    def test_a_path_citation_is_flagged(self) -> None:
        self.skill("Asked for it (docs/decisions/2026-09-26-polite-marten.md, the handoff).\n")
        code, out, _ = self.run_check()
        self.assertEqual(code, 1)
        self.assertIn("a path citation", out)

    def test_a_placeholder_or_glob_path_is_not_a_citation(self) -> None:
        self.skill("A playtest is docs/playtests/<date>-<name>.md; lint skips docs/playtests/*.md.\n")
        self.assertEqual(self.run_check()[0], 0)

    def test_a_name_that_is_no_file_is_flagged(self) -> None:
        self.skill("A rule (woolly-pengiun #759).\n")
        code, out, _ = self.run_check()
        self.assertEqual(code, 1)
        self.assertIn("(woolly-pengiun) names no file", out)

    def test_a_name_that_is_two_files_is_flagged(self) -> None:
        self.skill("A rule (twin-name).\n")
        code, out, _ = self.run_check()
        self.assertEqual(code, 1)
        self.assertIn("(twin-name) names more than one file", out)

    def test_a_number_with_no_heading_is_flagged(self) -> None:
        self.skill("A rule (woolly-penguin #760).\n")
        code, out, _ = self.run_check()
        self.assertEqual(code, 1)
        self.assertIn("has no `## #760` heading", out)

    def test_code_fences_and_lint_allow_are_not_read(self) -> None:
        self.skill(
            "Run `tools/x.sh (not-a-name)` here.\n```\n(also-not-a-name)\n```\n"
            "A ready (non-draft) PR. <!-- lint-allow -->\n"
        )
        self.assertEqual(self.run_check()[0], 0)

    def test_given_files_only_claude_md_and_skills_are_checked(self) -> None:
        self.skill("A rule (no-such-name).\n")
        code, out, _ = self.run_check("README.md")
        self.assertEqual((code, out), (0, ""))
        code, _, _ = self.run_check(".claude/skills/demo/SKILL.md")
        self.assertEqual(code, 1)

    def test_a_missing_file_is_an_error(self) -> None:
        code, _, err = self.run_check("CLAUDE.md")
        self.assertEqual(code, 2)
        self.assertIn("no such file: CLAUDE.md", err)


if __name__ == "__main__":
    unittest.main()
