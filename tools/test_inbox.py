#!/usr/bin/env python3
"""Offline tests for tools/inbox.py: every read is answered by a fake `gh`, every write recorded.

No test reaches GitHub. What is checked is the part a mistake would cost the player: which issues
count as the player's notes, how a band is read, which `Filed from #N` lines name a batch, that a
write always goes through `tools/agent-identity.py run <role> --` and never runs without a role,
and that a batch is closed only when every note's current text is in the filing pull request's
playtest file, all of it or none.
"""

from __future__ import annotations

import base64
import importlib.util
import io
import json
import sys
import tempfile
import unittest
from collections.abc import Sequence
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path
from typing import Any
from unittest import mock

TOOLS = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("inbox", TOOLS / "inbox.py")
assert SPEC and SPEC.loader
inbox = importlib.util.module_from_spec(SPEC)
# Registered first: a dataclass reads its own module's namespace while it is being built.
sys.modules["inbox"] = inbox
SPEC.loader.exec_module(inbox)

REPO = "o/r"
BODY = "currently shadows are oval below objects. the shadow of a car goes all the way above the roof"


def issue(number: int, author: str = "JosuaKrause", labels: Sequence[str] = ("inbox",), **extra: Any) -> dict[str, Any]:
    data: dict[str, Any] = {
        "number": number,
        "title": f"note {number}",
        "user": {"login": author},
        "labels": [{"name": label} for label in labels],
        "body": BODY,
        "state": "open",
        "html_url": f"https://github.com/{REPO}/issues/{number}",
    }
    data.update(extra)
    return data


class FakeGh:
    """Answers `gh api <endpoint>` from a table (a list endpoint's first page; later pages empty) and records writes."""

    def __init__(self, reads: dict[str, Any]) -> None:
        self.reads = reads
        self.writes: list[tuple[list[str], str | None]] = []

    def __call__(self, args: Sequence[str], stdin: str | None) -> str:
        args = list(args)
        if args[:2] == ["gh", "api"]:
            endpoint = args[2]
            base, _, query = endpoint.partition("?")
            params = [part for part in query.split("&") if part and not part.startswith(("per_page=", "page="))]
            key = base + ("?" + "&".join(params) if params else "")
            if "page=" in query and "page=1" not in query.split("&"):
                return "[]"
            if key not in self.reads:
                raise inbox.InboxError(f"no fake answer for {key}")
            return json.dumps(self.reads[key])
        self.writes.append((args, stdin))
        if "create" in args:
            return "https://github.com/o/r/issues/77\n"
        return "https://github.com/o/r/issues/1#issuecomment-1\n"


def run(fake: FakeGh, *argv: str, stdin: str = "") -> tuple[int, str, str]:
    out, err = io.StringIO(), io.StringIO()
    with redirect_stdout(out), redirect_stderr(err), mock.patch.object(sys, "stdin", io.StringIO(stdin)):
        code = inbox.main(["--repo", REPO, *argv], fake)
    return code, out.getvalue(), err.getvalue()


def filing_pr(number: int, description: str, *, state: str = "open", merged: bool = False) -> dict[str, Any]:
    return {"number": number, "body": description, "state": state, "merged": merged, "head": {"sha": "abc"}}


def playtest_reads(pr: int, text: str) -> dict[str, Any]:
    path = "docs/playtests/2026-09-28-x-y.md"
    return {
        f"repos/{REPO}/pulls/{pr}/files": [
            {"filename": path, "status": "added"},
            {"filename": "docs/todo/2026-09-28-x-y/README.md", "status": "added"},
        ],
        f"repos/{REPO}/contents/{path}?ref=abc": {"content": base64.b64encode(text.encode()).decode()},
    }


class AdmissionTests(unittest.TestCase):
    def note(self, **kwargs: Any) -> Any:
        return inbox.note_from_api(issue(1, **kwargs))

    def test_the_players_own_issue_is_a_note(self) -> None:
        self.assertIsNone(inbox.skip_reason(self.note()))

    def test_a_captured_issue_from_either_capture_identity_is_a_note(self) -> None:
        for bot in inbox.CAPTURE_BOTS:
            with self.subTest(bot=bot):
                self.assertIsNone(inbox.skip_reason(self.note(author=bot, labels=("inbox", "captured"))))

    def test_a_capture_identity_without_the_tag_is_skipped(self) -> None:
        reason = inbox.skip_reason(self.note(author="nappy-claude-orchestrator[bot]"))
        self.assertIn("without the `captured` label", reason or "")

    def test_anybody_else_is_skipped_whatever_the_labels(self) -> None:
        for author in ("someone", "nappy-claude-coder[bot]"):
            with self.subTest(author=author):
                reason = inbox.skip_reason(self.note(author=author, labels=("inbox", "captured")))
                self.assertIn("never an inbox note", reason or "")

    def test_a_pull_request_or_an_unlabelled_issue_is_skipped(self) -> None:
        self.assertIn("pull request", inbox.skip_reason(self.note(pull_request={})) or "")
        self.assertIn("not labelled", inbox.skip_reason(self.note(labels=())) or "")


class BandTests(unittest.TestCase):
    def test_a_band_is_read_by_its_exact_label(self) -> None:
        self.assertEqual(inbox.bands(["inbox", "queue_next"]), ["next"])
        self.assertEqual(inbox.bands(["queue_soon", "queue_now_please", "band: now", "Queue_now"]), [])
        self.assertEqual(inbox.band_text(["inbox"]), "no band")
        self.assertEqual(inbox.band_text(["queue_parked"]), "band parked")

    def test_two_bands_are_filed_under_neither(self) -> None:
        self.assertIn("filed under neither", inbox.band_text(["queue_now", "queue_later"]))


class FiledTests(unittest.TestCase):
    def test_each_line_names_one_note_once(self) -> None:
        text = "Files the inbox.\n\nFiled from #423\n- Filed from #424\n1. Filed from #423\n"
        self.assertEqual(inbox.filed_numbers(text), ([423, 424], []))

    def test_a_line_inside_a_fence_is_an_example_not_a_filing(self) -> None:
        self.assertEqual(inbox.filed_numbers("```\nFiled from #9\n```\nFiled from #10"), ([10], []))

    def test_a_near_miss_is_reported(self) -> None:
        numbers, malformed = inbox.filed_numbers("Filed from: #12\nfiled from #13\n**Filed from issue #14**")
        self.assertEqual(numbers, [])
        self.assertEqual(len(malformed), 3)

    def test_closes_is_not_a_filing_line(self) -> None:
        self.assertEqual(inbox.filed_numbers("Closes #423"), ([], []))


class ReadTests(unittest.TestCase):
    def test_list_prints_each_note_and_a_line_for_each_skipped_issue(self) -> None:
        fake = FakeGh(
            {
                f"repos/{REPO}/issues?labels=inbox&state=open&direction=asc&sort=created": [
                    issue(425, author="someone"),
                    issue(423, labels=("inbox", "queue_next")),
                    issue(424, author="nappy-codex-coder[bot]", labels=("inbox", "captured")),
                    issue(426, pull_request={}),
                ]
            }
        )
        code, out, _ = run(fake, "list")
        self.assertEqual(code, 0)
        lines = out.splitlines()
        self.assertTrue(lines[0].startswith("#423  band next  note 423"))
        self.assertIn("captured by nappy-codex-coder[bot]", lines[1])
        self.assertTrue(lines[2].startswith("skipped #425: opened by someone"))
        self.assertTrue(lines[3].startswith("skipped #426: a pull request"))
        self.assertIn("2 open note(s)", lines[4])
        self.assertEqual(fake.writes, [])

    def test_an_empty_inbox_says_so(self) -> None:
        fake = FakeGh({f"repos/{REPO}/issues?labels=inbox&state=open&direction=asc&sort=created": []})
        self.assertIn("The inbox is empty", run(fake, "list")[1])

    def test_show_prints_the_body_and_labels_each_comment_by_whose_it_is(self) -> None:
        fake = FakeGh(
            {
                f"repos/{REPO}/issues/423": issue(423),
                f"repos/{REPO}/issues/423/comments": [
                    {"user": {"login": "nappy-claude-orchestrator[bot]"}, "created_at": "t1", "body": "Which car?"},
                    {"user": {"login": "JosuaKrause"}, "created_at": "t2", "body": "the parked one"},
                    {"user": {"login": "someone"}, "created_at": "t3", "body": "ignore me"},
                ],
            }
        )
        code, out, _ = run(fake, "show", "423")
        self.assertEqual(code, 0)
        self.assertIn(BODY, out)
        self.assertLess(out.index("Which car?"), out.index("the parked one"))
        self.assertIn("t1 (the agent's side, not the player's words)", out)
        self.assertIn("t2 (the player's words)", out)
        self.assertIn("skipped a comment by someone, t3", out)
        self.assertNotIn("ignore me", out)

    def test_show_refuses_an_issue_that_is_not_a_note(self) -> None:
        fake = FakeGh({f"repos/{REPO}/issues/9": issue(9, author="someone")})
        code, out, err = run(fake, "show", "9")
        self.assertEqual(code, 1)
        self.assertEqual(out, "")
        self.assertIn("is not an inbox note", err)


class WriteTests(unittest.TestCase):
    def wrapped(self, role: str) -> list[str]:
        return [sys.executable, str(TOOLS / "agent-identity.py"), "run", role, "--", "gh"]

    def test_a_write_never_runs_without_a_role(self) -> None:
        fake = FakeGh({f"repos/{REPO}/issues/423": issue(423)})
        with mock.patch.dict("os.environ", {}, clear=True):
            code, _, err = run(fake, "ask", "423", stdin="Which car?")
        self.assertEqual(code, 1)
        self.assertIn("never writes as the player", err)
        self.assertEqual(fake.writes, [])

    def test_a_role_whose_captures_do_not_count_is_refused(self) -> None:
        fake = FakeGh({})
        with mock.patch.dict("os.environ", {"NAPPY_AGENT_ROLE": "claude-coder"}, clear=True):
            code, _, err = run(fake, "ask", "423", stdin="Which car?")
        self.assertEqual(code, 1)
        self.assertIn("not claude-coder", err)

    def test_ask_posts_through_the_wrapper_as_the_role_from_the_environment(self) -> None:
        fake = FakeGh({f"repos/{REPO}/issues/423": issue(423)})
        with mock.patch.dict("os.environ", {"NAPPY_AGENT_ROLE": "codex-coder"}, clear=True):
            code, _, _ = run(fake, "ask", "423", stdin="Which car?\n")
        self.assertEqual(code, 0)
        self.assertEqual(
            fake.writes,
            [
                (
                    [*self.wrapped("codex-coder"), "issue", "comment", "423", "-R", REPO, "--body-file", "-"],
                    "Which car?\n",
                )
            ],
        )

    def test_ask_refuses_a_closed_note_and_an_empty_question(self) -> None:
        fake = FakeGh({f"repos/{REPO}/issues/423": issue(423, state="closed")})
        self.assertIn("is closed", run(fake, "--role", "claude-orchestrator", "ask", "423", stdin="Why?")[2])
        self.assertIn("is empty", run(fake, "--role", "claude-orchestrator", "ask", "423", stdin=" \n")[2])
        self.assertEqual(fake.writes, [])

    def test_capture_opens_one_tagged_note_with_the_words_verbatim(self) -> None:
        fake = FakeGh({})
        words = "the car's shadow reaches above its roof.\nit should sit under the wheels\n"
        with mock.patch.dict("os.environ", {"NAPPY_AGENT_ROLE": "claude-orchestrator"}, clear=True):
            code, out, _ = run(fake, "capture", "--band", "next", stdin=words)
        self.assertEqual(code, 0)
        self.assertIn("/issues/77", out)
        self.assertEqual(len(fake.writes), 1)
        args, stdin = fake.writes[0]
        self.assertEqual(stdin, words)
        self.assertEqual(args[: len(self.wrapped("claude-orchestrator"))], self.wrapped("claude-orchestrator"))
        self.assertEqual(args[6:8], ["issue", "create"])
        labels = [args[i + 1] for i, arg in enumerate(args) if arg == "--label"]
        self.assertEqual(labels, ["inbox", "captured", "queue_next"])
        self.assertEqual(args[args.index("--title") + 1], "the car's shadow reaches above its roof.")
        self.assertEqual(args[args.index("--body-file") + 1], "-")

    def test_capture_takes_the_role_after_the_subcommand_and_no_band(self) -> None:
        fake = FakeGh({})
        with mock.patch.dict("os.environ", {}, clear=True):
            code, _, _ = run(fake, "capture", "--role", "codex-coder", "--title", "T", stdin="words")
        self.assertEqual(code, 0)
        args, _ = fake.writes[0]
        self.assertEqual(args[3], "codex-coder")
        self.assertEqual([args[i + 1] for i, arg in enumerate(args) if arg == "--label"], ["inbox", "captured"])

    def test_capture_refuses_no_role_an_empty_text_and_a_band_outside_the_set(self) -> None:
        fake = FakeGh({})
        with mock.patch.dict("os.environ", {}, clear=True):
            self.assertIn("never writes as the player", run(fake, "capture", stdin="words")[2])
            self.assertIn("is empty", run(fake, "--role", "claude-orchestrator", "capture", stdin="\n")[2])
            with self.assertRaises(SystemExit):
                run(fake, "--role", "claude-orchestrator", "capture", "--band", "soon", stdin="words")
        self.assertEqual(fake.writes, [])

    def test_capture_posts_what_the_words_answered_as_the_first_comment(self) -> None:
        fake = FakeGh({})
        with tempfile.TemporaryDirectory() as folder:
            context = Path(folder) / "context.md"
            context.write_text("Asked: which band?", encoding="utf-8")
            code, out, _ = run(
                fake, "--role", "claude-orchestrator", "capture", "--context-file", str(context), stdin="x"
            )
        self.assertEqual(code, 0)
        self.assertIn("posted the context on #77", out)
        self.assertEqual(
            [args[6:9] for args, _ in fake.writes], [["issue", "create", "-R"], ["issue", "comment", "77"]]
        )
        self.assertEqual([stdin for _, stdin in fake.writes], ["x", "Asked: which band?"])

    def test_a_long_first_line_is_cut_at_a_word_for_the_title(self) -> None:
        title = inbox.default_title("> " + "word " * 30)
        self.assertTrue(title.endswith("…"))
        self.assertLessEqual(len(title), inbox.TITLE_LENGTH + 1)
        self.assertFalse(title.startswith(">"))

    def batch(self, description: str, playtest: str, **pr: Any) -> FakeGh:
        reads: dict[str, Any] = {
            f"repos/{REPO}/pulls/430": filing_pr(430, description, **pr),
            f"repos/{REPO}/issues/423": issue(423),
            f"repos/{REPO}/issues/423/comments": [],
            f"repos/{REPO}/issues/424": issue(424, state="closed"),
        }
        reads.update(playtest_reads(430, playtest))
        return FakeGh(reads)

    def test_close_closes_every_named_note_through_the_wrapper(self) -> None:
        cut = BODY.index(" ", 40)
        quoted = "> " + BODY[:cut] + "\n> " + BODY[cut + 1 :] + "\n"
        fake = self.batch("Files the inbox.\n\nFiled from #423\nFiled from #424\n", "# Playtest\n\n" + quoted)
        code, out, _ = run(fake, "--role", "claude-orchestrator", "close", "--pr", "430")
        self.assertEqual(code, 0, out)
        self.assertIn("#424 is already closed", out)
        self.assertIn("closed #423", out)
        self.assertEqual(len(fake.writes), 1)
        args, _ = fake.writes[0]
        self.assertEqual(args[: len(self.wrapped("claude-orchestrator"))], self.wrapped("claude-orchestrator"))
        self.assertEqual(args[6:9], ["issue", "close", "423"])
        self.assertIn("Filed in #430.", args[-1])

    def test_close_closes_nothing_when_a_note_changed_since_it_was_copied(self) -> None:
        fake = self.batch("Filed from #423", "# Playtest\n\n> an older wording of the note\n")
        code, _, err = run(fake, "--role", "claude-orchestrator", "close", "--pr", "430")
        self.assertEqual(code, 1)
        self.assertIn("not closing anything", err)
        self.assertEqual(fake.writes, [])

    def test_close_closes_nothing_when_a_comment_of_the_players_is_not_copied(self) -> None:
        # The player's answer on the note is their words too, copied with the body; one missing
        # from the playtest file stops the close, while the agent's own question need not be there.
        comments = [
            {"user": {"login": "nappy-claude-orchestrator[bot]"}, "created_at": "t1", "body": "Which tasks?"},
            {
                "user": {"login": "JosuaKrause"},
                "created_at": "2026-10-02T09:00:00Z",
                "body": "this applies to almost all tasks",
            },
        ]
        fake = self.batch("Filed from #423", "# Playtest\n\n> " + BODY + "\n")
        fake.reads[f"repos/{REPO}/issues/423/comments"] = comments
        code, _, err = run(fake, "--role", "claude-orchestrator", "close", "--pr", "430")
        self.assertEqual(code, 1)
        self.assertIn("not closing anything", err)
        self.assertIn("the player's comment on #423 of 2026-10-02T09:00:00Z", err)
        self.assertEqual(fake.writes, [])
        fake = self.batch("Filed from #423", "# Playtest\n\n> " + BODY + "\n\n> this applies to\n> almost all tasks\n")
        fake.reads[f"repos/{REPO}/issues/423/comments"] = comments
        code, out, _ = run(fake, "--role", "claude-orchestrator", "close", "--pr", "430")
        self.assertEqual(code, 0, out)
        self.assertEqual([args[6:9] for args, _ in fake.writes], [["issue", "close", "423"]])

    def test_close_refuses_a_note_with_no_body(self) -> None:
        # An empty body is in every text; CI fails such a note, so closing it would leave the
        # filing pull request red with the note already closed.
        fake = self.batch("Filed from #423", "# Playtest\n\n> anything\n")
        fake.reads[f"repos/{REPO}/issues/423"] = issue(423, body="")
        code, _, err = run(fake, "--role", "claude-orchestrator", "close", "--pr", "430")
        self.assertEqual(code, 1)
        self.assertIn("#423: the note has no body to transcribe", err)
        self.assertEqual(fake.writes, [])

    def test_close_refuses_a_merged_pull_request_and_a_note_that_is_not_the_players(self) -> None:
        fake = self.batch("Filed from #423", BODY, state="closed", merged=True)
        self.assertIn("is merged", run(fake, "--role", "claude-orchestrator", "close", "--pr", "430")[2])
        fake = self.batch("Filed from #423", BODY)
        fake.reads[f"repos/{REPO}/issues/423"] = issue(423, author="someone")
        self.assertIn("not every note", run(fake, "--role", "claude-orchestrator", "close", "--pr", "430")[2])
        self.assertEqual(fake.writes, [])

    def test_close_dry_run_needs_no_role_and_writes_nothing(self) -> None:
        fake = self.batch("Filed from #423", BODY)
        with mock.patch.dict("os.environ", {}, clear=True):
            code, out, _ = run(fake, "close", "--pr", "430", "--dry-run")
        self.assertEqual(code, 0)
        self.assertIn("would close #423", out)
        self.assertEqual(fake.writes, [])

    def test_reopen_only_after_the_filing_pull_request_was_closed_unmerged(self) -> None:
        fake = self.batch("Filed from #423\nFiled from #424", BODY)
        self.assertIn("is open", run(fake, "--role", "claude-orchestrator", "reopen", "--pr", "430")[2])
        fake = self.batch("Filed from #423\nFiled from #424", BODY, state="closed")
        code, out, _ = run(fake, "--role", "claude-orchestrator", "reopen", "--pr", "430")
        self.assertEqual(code, 0)
        self.assertIn("#423 is already open", out)
        self.assertEqual([args[6:9] for args, _ in fake.writes], [["issue", "reopen", "424"]])


class AgreementTests(unittest.TestCase):
    """The CI check that reads a filing (tools/ci_transcription.py) and this tool must read it the same way."""

    def setUp(self) -> None:
        path = TOOLS / "ci_transcription.py"
        if not path.exists():
            self.skipTest("tools/ci_transcription.py is not in this checkout")
        sys.path.insert(0, str(TOOLS))
        spec = importlib.util.spec_from_file_location("ci_transcription", path)
        assert spec and spec.loader
        self.ci = importlib.util.module_from_spec(spec)
        sys.modules["ci_transcription"] = self.ci
        spec.loader.exec_module(self.ci)

    def test_the_author_rule_is_the_same(self) -> None:
        self.assertEqual(self.ci.PLAYER, inbox.PLAYER)
        self.assertEqual(tuple(self.ci.CAPTURE_BOTS), inbox.CAPTURE_BOTS)
        self.assertEqual(self.ci.CAPTURE_LABEL, inbox.CAPTURE_LABEL)
        self.assertEqual(self.ci.INBOX_LABEL, inbox.INBOX_LABEL)
        self.assertEqual(set(inbox.WRITE_ROLES.values()), set(inbox.CAPTURE_BOTS))

    def test_the_same_notes_are_filable(self) -> None:
        # Both rules run over the same notes and agree on every one. The label rule is the player's
        # (2026-10-03: "if an issue has no inbox label it shouldn't get filed"): without `inbox` a
        # note is not filed, whoever opened it and whatever else it carries.
        bot = inbox.CAPTURE_BOTS[0]
        samples = [
            ("the player, labelled inbox", inbox.PLAYER, ("inbox", "queue_next"), False, True),
            ("the player, no inbox label", inbox.PLAYER, ("queue_next",), False, False),
            ("the capture bot, inbox and captured", bot, ("inbox", "captured"), False, True),
            ("the capture bot, captured but no inbox", bot, ("captured",), False, False),
            ("the capture bot, inbox but not captured", bot, ("inbox",), False, False),
            ("somebody else, inbox and captured", "someone", ("inbox", "captured"), False, False),
            ("a pull request by the player, inbox", inbox.PLAYER, ("inbox",), True, False),
        ]
        for label, author, labels, is_pr, filable in samples:
            with self.subTest(label):
                ours = inbox.Note(
                    number=7,
                    title="t",
                    author=author,
                    labels=labels,
                    body="b",
                    state="open",
                    url="u",
                    is_pull_request=is_pr,
                )
                theirs = self.ci.Note(number=7, author=author, labels=labels, body="b", is_pull_request=is_pr)
                self.assertEqual(inbox.skip_reason(ours) is None, filable)
                self.assertEqual(self.ci.author_failure(theirs) is None, filable)

    def test_a_note_with_no_body_fails_both_alike(self) -> None:
        # The same note, the same playtest file: both refuse it, in the same words.
        text = {"docs/playtests/2026-10-03-x-y.md": "# Playtest\n\n> anything\n"}
        for body in ("", " \n> \n"):
            with self.subTest(body=body):
                ours = inbox.Note(
                    number=7,
                    title="t",
                    author=inbox.PLAYER,
                    labels=("inbox",),
                    body=body,
                    state="open",
                    url="u",
                    is_pull_request=False,
                )
                theirs = self.ci.Note(
                    number=7, author=inbox.PLAYER, labels=("inbox",), body=body, is_pull_request=False
                )
                normalized = {path: inbox.normalize(t) for path, t in text.items()}
                self.assertEqual(inbox.unfiled_words(ours, [], normalized), self.ci.check([theirs], text))

    def test_a_description_names_the_same_notes(self) -> None:
        for text in ("Filed from #1\n- Filed from #2\n```\nFiled from #3\n```\nfiled from #4", "Closes #5"):
            with self.subTest(text=text):
                self.assertEqual(self.ci.filed_numbers(text)[0], inbox.filed_numbers(text)[0])
                self.assertEqual(len(self.ci.filed_numbers(text)[1]), len(inbox.filed_numbers(text)[1]))


if __name__ == "__main__":
    unittest.main()
