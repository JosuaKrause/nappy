#!/usr/bin/env python3
"""Unit tests for tools/lib_queue.py, the old queue's move into one file per thing.

Small old-format fixtures stand in for the three real files, so every shape the real files carry
-- an undated heading, a `# ` part heading, a quoted superseded document with its own `##`
headings, a fenced `## `, an entry inside the order, a mid-way item, a review item across two
sections -- is exercised here without git; the real files are the migration's own verification.
"""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import lib_queue as q


def undated(path: str, line: int) -> str:
    return f"2026-01-{line:02d}" if line < 29 else "2026-02-01"


DECISIONS = """\
# Decisions

## M3 — The newest record · built 2026-09-25

See [PLAYTEST-9](playtests/PLAYTEST-9.md) and [the site](https://example.com/x) and [top](#top).

```
## not a heading, fenced
```

## M2 — A record with no date

Text with [the evidence](evidence/x/README.md).

---

# The archive

Everything below is old.

## M1 — Old one — 2026-09-01

### Superseded text from docs/X.md

# X document

## X's own section

Quoted.

---

## M0 — After the quote — 2026-08-31

The end.
"""

TODO_ENTRY = """\
## M5 — Do a thing · asked for 2026-09-20

> "the player's words"

[PLAYTEST-9](playtests/PLAYTEST-9.md). Context.

- [ ] **First item** says what to do,
      over two lines.
- [~] **Second item** is started.

      A second paragraph of it.

**A lead-in for later items:**

- [ ] Accessibility: colourblind-safe meters
"""

TODO = (
    q.OLD_TODO_HEADER
    + """
---

## The order

### M4 — Inside the order

Why it is first.

- [ ] Inventory everything.

### Gameplay queue

Prose about the order.

"""
    + q.OLD_ORDER_TAIL
    + """
---

"""
    + TODO_ENTRY
    + """
---

## M6 — Undated entry

- [ ] **Only item**
"""
)

REVIEW = (
    q.OLD_REVIEW_HEADER
    + """
- **Walk the thing** ([PLAYTEST-9](playtests/PLAYTEST-9.md)) and
  judge it.

  Second paragraph.
- **Look at the other thing.**

"""
    + q.REVIEW_UNTESTED
    + """

- **An old question** nobody has felt.
"""
)


def texts() -> dict[str, str]:
    return {q.DECISIONS: DECISIONS, q.TODO: TODO, q.REVIEW: REVIEW}


class HelperTests(unittest.TestCase):
    def test_links_are_prefixed_and_come_back(self) -> None:
        line = "[a](playtests/P.md) [b](https://x.y) [c](#top) [d](../up.md) ![e](evidence/p.png)"
        moved = q.rewrite_links(line, "../../")
        self.assertEqual(
            moved, "[a](../../playtests/P.md) [b](https://x.y) [c](#top) [d](../../../up.md) ![e](../../evidence/p.png)"
        )
        self.assertEqual(q.unrewrite_links(moved, "../../"), line)

    def test_slug_drops_the_date_and_the_state_word_and_keeps_the_number(self) -> None:
        self.assertEqual(q.slugify("M201 — A CI job's checkout · built 2026-09-25"), "M201-a-ci-jobs-checkout")
        self.assertEqual(q.slugify("M0 — Setup · `feature/project-setup`"), "M0-setup")
        self.assertEqual(q.slugify("Café — 2026-01-01"), "cafe")
        self.assertLessEqual(len(q.slugify("word " * 60)), 80)

    def test_short_name_takes_the_bold_lead_or_the_first_phrase(self) -> None:
        lead = "**A stack is drawn in front of her when** she stands"
        self.assertEqual(q.short_name(lead), "stack-is-drawn-in-front-of")
        self.assertEqual(q.short_name("Accessibility: colourblind-safe meters"), "accessibility")
        self.assertEqual(q.short_name("Controller support"), "controller-support")

    def test_unique_suffixes_a_second_use(self) -> None:
        taken: set[str] = set()
        self.assertEqual([q.unique("a", taken) for _ in range(3)], ["a", "a-2", "a-3"])


class DecisionTests(unittest.TestCase):
    def setUp(self) -> None:
        self.report = q.Report()
        self.tree = q.decision_tree(DECISIONS, undated, self.report)

    def test_every_record_heading_is_one_file(self) -> None:
        self.assertEqual(
            sorted(self.tree),
            [
                "docs/decisions/2026-01-11-M2-a-record-with-no-date.md",
                "docs/decisions/2026-01-17-the-archive.md",
                "docs/decisions/2026-08-31-M0-after-the-quote.md",
                "docs/decisions/2026-09-01-M1-old-one.md",
                "docs/decisions/2026-09-25-M3-the-newest-record.md",
            ],
        )
        self.assertEqual(self.report.decision_undated, 2)

    def test_quoted_documents_and_fenced_headings_stay_inside_their_record(self) -> None:
        old = self.tree["docs/decisions/2026-09-01-M1-old-one.md"]
        self.assertIn("# X document\n\n## X's own section\n\nQuoted.\n", old)
        self.assertEqual(self.report.decision_embedded_headings, 2)
        self.assertIn("## not a heading, fenced", self.tree["docs/decisions/2026-09-25-M3-the-newest-record.md"])

    def test_every_line_is_accounted_for(self) -> None:
        r = self.report
        total = r.decision_lines_records + r.decision_lines_header + r.decision_lines_separators
        self.assertEqual(total, r.decision_lines_old)
        self.assertEqual(r.decision_lines_old, len(DECISIONS.rstrip("\n").split("\n")))

    def test_links_work_from_the_folder_and_separators_are_dropped(self) -> None:
        newest = self.tree["docs/decisions/2026-09-25-M3-the-newest-record.md"]
        self.assertIn("(../playtests/PLAYTEST-9.md)", newest)
        self.assertIn("(https://example.com/x)", newest)
        self.assertIn("(#top)", newest)
        self.assertFalse(self.tree["docs/decisions/2026-01-11-M2-a-record-with-no-date.md"].endswith("---\n"))

    def test_a_same_named_newcomer_takes_the_suffix(self) -> None:
        doubled = DECISIONS.replace(
            "# Decisions\n\n", "# Decisions\n\n## M3 — The newest record · built 2026-09-25\n\nNewer.\n\n", 1
        )
        tree = q.decision_tree(doubled, undated, q.Report())
        self.assertIn("Newer.", tree["docs/decisions/2026-09-25-M3-the-newest-record-2.md"])
        self.assertIn("PLAYTEST-9", tree["docs/decisions/2026-09-25-M3-the-newest-record.md"])

    def test_a_migrated_file_is_refused(self) -> None:
        with self.assertRaises(q.QueueFormatError):
            q.decision_tree(q.NEW_DECISIONS, undated, q.Report())

    def test_an_unclosed_fence_is_refused(self) -> None:
        with self.assertRaises(q.QueueFormatError):
            q.decision_tree(DECISIONS + "```\n", undated, q.Report())


class TodoTests(unittest.TestCase):
    def setUp(self) -> None:
        self.report = q.Report()
        self.tree = q.todo_tree(TODO, undated, True, self.report)

    def test_entries_are_folders_and_items_are_files(self) -> None:
        self.assertEqual(
            sorted(p for p in self.tree if p.startswith("docs/todo/")),
            [
                "docs/todo/2026-01-17-M4/README.md",
                "docs/todo/2026-01-17-M4/inventory-everything.md",
                "docs/todo/2026-02-01-M6/README.md",
                "docs/todo/2026-02-01-M6/only-item.md",
                "docs/todo/2026-09-20-M5/README.md",
                "docs/todo/2026-09-20-M5/accessibility.md",
                "docs/todo/2026-09-20-M5/first-item.md",
                "docs/todo/2026-09-20-M5/second-item.md",
            ],
        )
        self.assertEqual((self.report.todo_entries, self.report.todo_items, self.report.todo_items_midway), (3, 5, 1))

    def test_an_item_moves_as_written_without_its_checkbox(self) -> None:
        self.assertEqual(
            self.tree["docs/todo/2026-09-20-M5/first-item.md"], "**First item** says what to do,\nover two lines.\n"
        )
        self.assertEqual(
            self.tree["docs/todo/2026-09-20-M5/second-item.md"],
            f"{q.MIDWAY}\n\n**Second item** is started.\n\nA second paragraph of it.\n",
        )

    def test_the_context_file_holds_everything_but_the_items(self) -> None:
        readme = self.tree["docs/todo/2026-09-20-M5/README.md"]
        self.assertTrue(readme.startswith("## M5 — Do a thing · asked for 2026-09-20\n"))
        self.assertIn("(../../playtests/PLAYTEST-9.md)", readme)
        self.assertIn("**A lead-in for later items:**", readme)
        self.assertNotIn("- [", readme)

    def test_the_order_names_entries_by_their_folders(self) -> None:
        todo = self.tree[q.TODO]
        self.assertTrue(todo.startswith(q.NEW_TODO_HEADER))
        self.assertIn("### [M4 — Inside the order](todo/2026-01-17-M4/)\n", todo)
        self.assertIn(
            q.NEW_ORDER_TAIL
            + "\n- [M5 — Do a thing](todo/2026-09-20-M5/)\n- [M6 — Undated entry](todo/2026-02-01-M6/)\n",
            todo,
        )
        self.assertNotIn("Everything below", todo)
        self.assertNotIn("- [ ]", todo)

    def test_a_changed_header_is_refused_unless_lenient(self) -> None:
        changed = TODO.replace("Open work only.", "Open work, only.")
        with self.assertRaises(q.QueueFormatError):
            q.todo_tree(changed, undated, True, q.Report())
        self.assertIn(q.TODO, q.todo_tree(changed, undated, False, q.Report()))

    def test_a_ticked_or_nested_checkbox_is_refused(self) -> None:
        for bad in ("- [x] **Done thing**\n", "- [ ] **Outer**\n      - [ ] inner\n"):
            with self.subTest(bad=bad), self.assertRaises(q.QueueFormatError):
                q.todo_tree(TODO + "\n" + bad, undated, True, q.Report())


class ReviewTests(unittest.TestCase):
    def test_every_bullet_is_a_file_and_the_header_is_rewritten(self) -> None:
        report = q.Report()
        tree = q.review_tree(REVIEW, undated, True, report)
        self.assertEqual(tree[q.REVIEW], q.NEW_REVIEW)
        items = sorted(p for p in tree if p.startswith("docs/review/"))
        self.assertEqual(len(items), 3)
        self.assertEqual(report.review_items, 3)
        self.assertIn("nobody has felt", "".join(tree[p] for p in items))
        walk = next(tree[p] for p in items if "walk-the-thing" in p)
        self.assertEqual(
            walk, "**Walk the thing** ([PLAYTEST-9](../playtests/PLAYTEST-9.md)) and\njudge it.\n\nSecond paragraph.\n"
        )

    def test_a_stray_paragraph_among_the_next_run_is_refused(self) -> None:
        stray = REVIEW.replace("- **Look at the other thing.**", "A stray paragraph.")
        with self.assertRaises(q.QueueFormatError):
            q.review_tree(stray, undated, True, q.Report())


class MigrateTests(unittest.TestCase):
    def test_the_whole_tree(self) -> None:
        migration = q.migrate(texts(), undated)
        self.assertEqual(migration.tree[q.DECISIONS], q.NEW_DECISIONS)
        self.assertTrue(q.is_old_format(texts()))
        self.assertFalse(q.is_old_format({**texts(), q.DECISIONS: q.NEW_DECISIONS}))
        self.assertTrue(any("5 files" in line for line in migration.report.lines()))


if __name__ == "__main__":
    unittest.main()
