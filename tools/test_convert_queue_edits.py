#!/usr/bin/env python3
"""Integration tests for tools/convert-queue-edits.py, on a throwaway git repository.

The repository gets the old-format fixtures of tools/test_migrate_queue.py as its base, a `main`
that migrated them and then moved on, and a pull request branch that edited the old files the way
open pull requests do: a record added at the top, an entry closed, an item closed, a review item
added, an entry's context edited. A real `git merge --no-commit` of `main` into the branch then
conflicts, and the conversion has to leave exactly the new-layout result behind -- or, for an edit
it cannot map, change nothing and name it.
"""

from __future__ import annotations

import importlib.util
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from types import ModuleType
from typing import Any

sys.path.insert(0, str(Path(__file__).resolve().parent))

import lib_queue as q
import test_migrate_queue as fixtures

TOOLS = Path(__file__).resolve().parent


def load(name: str, file: str) -> ModuleType:
    spec = importlib.util.spec_from_file_location(name, TOOLS / file)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


convert = load("convert_queue_edits", "convert-queue-edits.py")

DATE = "2026-01-05T12:00:00+0000"
NEW_RECORD = "## M7 — Something built on the branch · built 2026-09-26\n\nWhat was built.\n\n"
NEW_BULLET = "- **Walk the new thing** and say whether it reads.\n"


def replaced(text: str, old: str, new: str) -> str:
    """`str.replace` that fails loudly when the fixture no longer holds what the test edits."""
    if text.count(old) != 1:
        raise AssertionError(f"the fixture does not hold exactly one {old!r}")
    return text.replace(old, new)


class ConvertTests(unittest.TestCase):
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
        self.git("config", "rerere.enabled", "false")
        for path, text in fixtures.texts().items():
            self.write(path, text)
        self.commit("base")
        self.base = self.git("rev-parse", "HEAD").strip()

    def git(self, *args: str, check: bool = True) -> str:
        result = subprocess.run(["git", *args], cwd=self.repo, env=self.env, capture_output=True, text=True)
        if check and result.returncode != 0:
            raise AssertionError(f"git {' '.join(args)}: {result.stderr}")
        return result.stdout

    def write(self, path: str, text: str) -> None:
        target = self.repo / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(text)

    def commit(self, message: str) -> None:
        self.git("add", "-A")
        self.git("commit", "-q", "-m", message)

    def migrate_main(self) -> dict[str, str]:
        """`main` runs the migration, then files one more item in M5."""
        tree = q.migrate(fixtures.texts(), q.git_first_dates("HEAD", str(self.repo))).tree
        for path, text in tree.items():
            self.write(path, text)
        self.commit("migrate")
        self.write("docs/todo/2026-09-20-M5/filed-on-main.md", "**Filed on main** after the migration.\n")
        self.commit("main files an item")
        return tree

    def branch_edits(self, extra: dict[str, str] | None = None) -> None:
        self.git("checkout", "-q", "-b", "pr", self.base)
        texts = fixtures.texts()
        texts[q.DECISIONS] = replaced(texts[q.DECISIONS], "# Decisions\n\n", "# Decisions\n\n" + NEW_RECORD)
        todo = texts[q.TODO]
        todo = replaced(todo, "---\n\n## M6 — Undated entry\n\n- [ ] **Only item**\n", "")
        todo = replaced(todo, "- [ ] **First item** says what to do,\n      over two lines.\n", "")
        todo = replaced(todo, "PLAYTEST-9.md). Context.", "PLAYTEST-9.md). More.")
        texts[q.TODO] = todo
        bullet = "- **Look at the other thing.**\n"
        texts[q.REVIEW] = replaced(texts[q.REVIEW], bullet, bullet + NEW_BULLET)
        for path, text in {**texts, **(extra or {})}.items():
            self.write(path, text)
        self.commit("the PR's queue edits")
        self.git("merge", "--no-ff", "--no-commit", "main", check=False)

    def run_plan(self) -> Any:  # convert.Plan, from a module loaded by path that mypy cannot follow
        head = self.git("rev-parse", "HEAD").strip()
        main = self.git("rev-parse", "MERGE_HEAD").strip()
        return convert.plan(self.repo, self.base, head, main)

    def test_each_edit_becomes_its_file_operation(self) -> None:
        self.migrate_main()
        self.branch_edits()
        self.assertTrue(self.git("diff", "--name-only", "--diff-filter=U").strip(), "the merge was meant to conflict")
        plan = self.run_plan()
        self.assertEqual(plan.problems, [])
        convert.apply(self.repo, plan)
        self.assertEqual(self.git("diff", "--name-only", "--diff-filter=U").strip(), "")
        record = self.repo / "docs/decisions/2026-09-26-M7-something-built-on-the-branch.md"
        self.assertEqual(record.read_text(), NEW_RECORD.rstrip("\n") + "\n")
        self.assertFalse((self.repo / "docs/todo/2026-01-05-M6").exists(), "the closed entry's folder is gone")
        self.assertFalse((self.repo / "docs/todo/2026-09-20-M5/first-item.md").exists(), "the closed item is gone")
        self.assertTrue((self.repo / "docs/todo/2026-09-20-M5/filed-on-main.md").exists(), "main's own item stays")
        self.assertIn("). More.", (self.repo / "docs/todo/2026-09-20-M5/README.md").read_text())
        review = self.repo / "docs/review/2026-01-05-walk-the-new-thing.md"
        self.assertEqual(review.read_text(), "**Walk the new thing** and say whether it reads.\n")
        todo = (self.repo / q.TODO).read_text()
        self.assertNotIn("todo/2026-01-05-M6/", todo)
        self.assertIn("todo/2026-09-20-M5/", todo)
        self.assertEqual((self.repo / q.DECISIONS).read_text(), q.NEW_DECISIONS)
        self.assertEqual(self.git("diff", "--check", "--cached").strip(), "")

    def test_an_edit_it_cannot_map_changes_nothing(self) -> None:
        self.migrate_main()
        # main closes M5's second item; the branch rewrites the same item.
        self.git("rm", "-q", "docs/todo/2026-09-20-M5/second-item.md")
        self.commit("main closes the second item")
        rewritten = replaced(fixtures.TODO, "**Second item** is started.", "**Second item** is half done.")
        self.branch_edits({q.TODO: rewritten})
        before = self.git("status", "--porcelain")
        plan = self.run_plan()
        self.assertTrue(any("second-item.md" in problem for problem in plan.problems), plan.problems)
        self.assertEqual(self.git("status", "--porcelain"), before)

    def test_a_main_still_on_the_old_files_is_refused(self) -> None:
        self.write("docs/playtests/PLAYTEST-1.md", "# Playtest 1\n")
        self.commit("main moves on the old way")
        self.branch_edits()
        self.assertTrue(any("old single-file queue" in problem for problem in self.run_plan().problems))


if __name__ == "__main__":
    unittest.main()
