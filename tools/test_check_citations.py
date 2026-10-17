#!/usr/bin/env python3
"""`tools/check_citations.py` on a fixture tree, and `tools/lint.sh` running it.

The fixture has a playtest of `## #N` notes, one of numbered findings, one of numbered statements,
one with a single statement, a name two files share, and a record.
"""

from __future__ import annotations

import io
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path
from typing import ClassVar

TOOLS = Path(__file__).resolve().parent
sys.path.insert(0, str(TOOLS))

import check_citations  # noqa: E402


class CheckCitationsTests(unittest.TestCase):
    FILES: ClassVar[dict[str, str]] = {
        "docs/playtests/2026-10-17-woolly-penguin.md": "# Woolly penguin\n\n## #758\n\n> a\n\n## #759\n\n> b\n",
        "docs/playtests/PLAYTEST-16.md": "# Playtest 16\n\n## 1. Cars\n\n## 7. The resistance\n",
        "docs/playtests/2026-09-26-brisk-heron.md": (
            "# Brisk heron\n\n> a\n\n1. **One.**\n2. **Two.**\n\n> b\n\n13. **X.**\n"
        ),
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

    def flagged(self, text: str, label: str) -> None:
        self.skill(text)
        code, out, _ = self.run_check()
        self.assertEqual(code, 1, out)
        self.assertIn(label, out)

    def test_citations_in_every_form_that_resolve_pass(self) -> None:
        self.write("CLAUDE.md", "A rule (woolly-penguin #759). Another (PLAYTEST-16 7; polite-marten).\n")
        self.skill(
            "Three\ntimes (woolly-penguin\n#759), split over lines. Two (woolly-penguin #758, #759).\n"
            "A range (brisk-heron 1-2), a list (brisk-heron 1, 13), one statement (PLAYTEST-63).\n"
            "Filed: inbox #759 in woolly-penguin, and inbox #758 and #759 in woolly-penguin.\n"
        )
        code, out, _ = self.run_check()
        self.assertEqual((code, out), (0, ""))

    def test_a_link_into_the_playtests_is_flagged_once(self) -> None:
        self.skill("Line one.\nSee [three times](../../../docs/playtests/2026-10-17-woolly-penguin.md#759).\n")
        code, out, _ = self.run_check()
        self.assertEqual(code, 1)
        self.assertEqual(out.count("\n"), 1)
        self.assertIn(".claude/skills/demo/SKILL.md:2: a link into docs/playtests/", out)

    def test_a_path_citation_is_flagged_inside_a_code_span_too(self) -> None:
        self.flagged("Asked for it (docs/decisions/2026-09-26-polite-marten.md, the handoff).\n", "a path citation")
        self.flagged("See `docs/playtests/PLAYTEST-63.md`.\n", "a path citation")

    def test_a_placeholder_or_glob_path_is_not_a_citation(self) -> None:
        self.skill("A playtest is docs/playtests/<date>-<name>.md; lint skips docs/playtests/*.md.\n")
        self.assertEqual(self.run_check()[0], 0)

    def test_a_name_that_is_no_file_is_flagged(self) -> None:
        self.flagged("A rule (woolly-pengiun #759).\n", "(woolly-pengiun) names no file")

    def test_a_name_that_is_two_files_is_flagged(self) -> None:
        self.flagged("A rule (twin-name).\n", "(twin-name) names more than one file")

    def test_a_note_with_no_heading_is_flagged(self) -> None:
        self.flagged("A rule (woolly-penguin #760).\n", "has no `## #760` heading")

    def test_a_bare_name_for_a_file_of_several_statements_is_flagged(self) -> None:
        self.flagged("A rule (woolly-penguin).\n", "cite one with #N")
        self.flagged("A rule (PLAYTEST-16).\n", "cite one with the statement's number")
        self.flagged("A rule (brisk-heron).\n", "cite one with the statement's number")

    def test_a_number_the_file_does_not_have_is_flagged(self) -> None:
        self.flagged("A rule (PLAYTEST-16 8).\n", "has no statement 8")
        self.flagged("A rule (brisk-heron 2-5).\n", "has no statement 5")

    def test_a_plain_number_for_a_file_of_notes_is_flagged(self) -> None:
        self.flagged("A rule (woolly-penguin 759).\n", "cite the note as #N")

    def test_text_after_a_comma_does_not_hide_the_citation(self) -> None:
        self.flagged("A rule (woolly-penguin #999, the rule).\n", "has no `## #999` heading")
        self.flagged("A rule (PLAYTEST-16, finding 7).\n", "cite one with the statement's number")

    def test_an_inbox_citation_names_a_playtest_holding_the_note(self) -> None:
        self.flagged("Filed as inbox #760 in woolly-penguin.\n", "(inbox #760 in woolly-penguin)")
        self.flagged("Filed as inbox #759 in woolly-pengiun.\n", "(woolly-pengiun) names no file")

    def test_an_unhyphenated_word_after_inbox_n_in_is_prose(self) -> None:
        self.skill("Filed as inbox #12 in March, and inbox #5 in PR #700.\n")
        self.assertEqual(self.run_check(), (0, "", ""))

    def test_a_number_both_a_heading_and_a_statement_is_accepted(self) -> None:
        self.write("docs/playtests/PLAYTEST-05.md", "# Playtest 5\n\n## Finding 3\n\n1. a\n2. b\n3. c\n")
        self.skill("A rule (PLAYTEST-05 3).\n")
        self.assertEqual(self.run_check()[0], 0)

    def test_code_spans_fences_and_lint_allow_are_not_read_for_citations(self) -> None:
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

    def test_a_missing_file_or_one_outside_the_repository_is_a_clean_error(self) -> None:
        code, _, err = self.run_check("CLAUDE.md")
        self.assertEqual(code, 2)
        self.assertIn("no such file: CLAUDE.md", err)
        with tempfile.NamedTemporaryFile(suffix=".md") as outside:
            code, _, err = self.run_check(outside.name)
        self.assertEqual(code, 2)
        self.assertIn("not in the repository", err)
        self.assertNotIn("Traceback", err)


class LintRunsTheCheckTests(unittest.TestCase):
    """`tools/lint.sh` runs the check: on a skill it is given, on every skill when given a playtest."""

    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        (self.root / "tools").mkdir()
        for name in ("lint.sh", "check_citations.py", "queue.sh"):
            shutil.copy2(TOOLS / name, self.root / "tools" / name)
        shutil.copytree(TOOLS / "names", self.root / "tools/names")
        for name, text in {
            "docs/playtests/2026-10-17-woolly-penguin.md": "# Woolly penguin\n\n## #759\n\n## #760\n",
            ".claude/skills/good/SKILL.md": "A rule (woolly-penguin #759).\n",
            ".claude/skills/bad/SKILL.md": "A rule (woolly-penguin #999).\n",
        }.items():
            path = self.root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(text, encoding="utf-8")

    def lint(self, *args: str, env: dict[str, str] | None = None) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["bash", str(self.root / "tools/lint.sh"), *args],
            cwd=self.root,
            env=env,
            capture_output=True,
            text=True,
            check=False,
        )

    def test_a_skill_it_is_given_is_checked(self) -> None:
        self.assertEqual(self.lint(".claude/skills/good/SKILL.md").returncode, 0)
        result = self.lint(".claude/skills/bad/SKILL.md")
        self.assertEqual(result.returncode, 1)
        self.assertIn(".claude/skills/bad/SKILL.md:1: (woolly-penguin #999)", result.stdout)

    def test_a_playtest_it_is_given_checks_every_skill(self) -> None:
        result = self.lint("docs/playtests/2026-10-17-woolly-penguin.md")
        self.assertEqual(result.returncode, 1)
        self.assertIn(".claude/skills/bad/SKILL.md:1:", result.stdout)

    def test_a_missing_python3_is_a_hit_not_a_skip(self) -> None:
        bin_dir = self.root / "bin"
        bin_dir.mkdir()
        for directory in os.environ.get("PATH", "").split(os.pathsep):
            if not directory or not Path(directory).is_dir():
                continue
            for tool in Path(directory).iterdir():
                if tool.name.startswith("python") or (bin_dir / tool.name).exists():
                    continue
                (bin_dir / tool.name).symlink_to(tool)
        result = self.lint(".claude/skills/good/SKILL.md", env={"PATH": str(bin_dir)})
        self.assertEqual(result.returncode, 1)
        self.assertIn("python3 is needed to check the citations", result.stderr)


if __name__ == "__main__":
    unittest.main()
