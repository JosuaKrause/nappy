#!/usr/bin/env python3
"""Exercise Codex payloads through the real shared hooks in isolated fixtures."""

import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from typing import Any

SOURCE = Path(__file__).resolve().parent.parent


class CodexHooksTest(unittest.TestCase):
    def test_codex_skills_are_the_canonical_claude_files(self) -> None:
        # This must stay a directory link: adding a Claude skill then makes it
        # discoverable in Codex without adding a second file or per-skill link.
        shared = SOURCE / ".agents/skills"
        canonical = SOURCE / ".claude/skills"
        self.assertTrue(shared.is_symlink())
        self.assertEqual(shared.resolve(), canonical.resolve())
        skills = list(canonical.glob("*/SKILL.md"))
        self.assertTrue(skills)
        for skill in skills:
            self.assertTrue((shared / skill.relative_to(canonical)).samefile(skill))

    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name).resolve()
        self.root = self.make_repo("repo")
        self.env = dict(os.environ, TMPDIR=str(self.base / "state"))

    def make_repo(self, name: str) -> Path:
        root = self.base / name
        (root / "tools").mkdir(parents=True)
        shutil.copytree(SOURCE / ".claude/hooks", root / ".claude/hooks")
        for name in ("codex-hooks.py", "lint.sh"):
            shutil.copy2(SOURCE / "tools" / name, root / "tools" / name)
        for skill in (SOURCE / ".claude/skills").glob("*/SKILL.md"):
            target = root / ".claude/skills" / skill.parent.name / "SKILL.md"
            target.parent.mkdir(parents=True)
            target.write_text(f"RULE_CONTENT_{skill.parent.name}\n")
        return root

    def call(
        self,
        kind: str = "PreToolUse",
        tool: str = "apply_patch",
        command: str = "",
        root: Path | None = None,
        **extra: Any,
    ) -> str:
        root = root or self.root
        event: dict[str, Any] = {
            "hook_event_name": kind,
            "session_id": "session",
            "cwd": str(root),
            "tool_name": tool,
            "tool_input": {"command": command},
        }
        event.update(extra)
        result = subprocess.run(
            [sys.executable, str(root / "tools/codex-hooks.py")],
            input=json.dumps(event),
            text=True,
            capture_output=True,
            env=self.env,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        if not result.stdout.strip():
            return ""
        output = json.loads(result.stdout)
        self.assertNotIn("suppressOutput", output)
        specific = output["hookSpecificOutput"]
        self.assertEqual(specific["hookEventName"], kind)
        self.assertNotIn("suppressOutput", specific)
        context = specific["additionalContext"]
        assert isinstance(context, str)
        return context

    def call_raw(
        self,
        kind: str = "PreToolUse",
        tool: str = "Bash",
        command: str = "",
        root: Path | None = None,
        **extra: Any,
    ) -> dict[str, Any] | None:
        # Like call(), but for a response shaped as a permissionDecision rather than
        # additionalContext -- call()'s own assertions require the latter.
        root = root or self.root
        event: dict[str, Any] = {
            "hook_event_name": kind,
            "session_id": "session",
            "cwd": str(root),
            "tool_name": tool,
            "tool_input": {"command": command},
        }
        event.update(extra)
        result = subprocess.run(
            [sys.executable, str(root / "tools/codex-hooks.py")],
            input=json.dumps(event),
            text=True,
            capture_output=True,
            env=self.env,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        if not result.stdout.strip():
            return None
        output: dict[str, Any] = json.loads(result.stdout)
        return output

    def write(self, name: str, content: str = "- [x] Finished\n") -> None:
        target = self.root / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content)

    def test_multifile_patch_loads_all_matching_skills_once(self) -> None:
        text = self.call(
            command="*** Begin Patch\n*** Update File: src/events/a.gd\n"
            "*** Add File: src/city/b.gd\n*** Update File: src/events/c.gd\n"
            "*** End Patch\n"
        )
        for skill in ("events", "city", "godot", "orchestrating"):
            self.assertEqual(text.count(f"RULE_CONTENT_{skill}"), 1)
        self.assertNotIn("RULE_CONTENT_cues", text)
        self.assertEqual(self.call(command="*** Update File: src/events/a.gd\n"), "")

    def test_rename_destination_loads_its_rules(self) -> None:
        text = self.call(command="*** Update File: notes.txt\n*** Move to: src/ui/panel.gd\n")
        self.assertIn("RULE_CONTENT_cues", text)
        self.assertIn("RULE_CONTENT_godot", text)

    def test_compaction_reloads_session_and_path_rules(self) -> None:
        self.assertIn("RULE_CONTENT_orchestrating", self.call(kind="SessionStart", source="startup"))
        patch = "*** Update File: src/events/a.gd\n"
        self.assertIn("RULE_CONTENT_events", self.call(command=patch))
        self.assertEqual(self.call(command=patch), "")
        self.assertIn("RULE_CONTENT_orchestrating", self.call(kind="SessionStart", source="compact"))
        self.assertIn("RULE_CONTENT_events", self.call(command=patch))

    def test_tmp_without_tmpdir_reloads_the_shared_markers(self) -> None:
        # The Bash hooks use TMPDIR or /tmp. TMP alone must not send the adapter's
        # reset to a different directory from the markers the hooks write.
        alternate = self.base / "alternate-tmp"
        alternate.mkdir()
        original_env = self.env
        self.env = dict(os.environ, TMP=str(alternate))
        self.env.pop("TMPDIR", None)
        try:
            patch = "*** Update File: src/events/a.gd\n"
            self.assertIn("RULE_CONTENT_orchestrating", self.call(kind="SessionStart"))
            self.assertIn("RULE_CONTENT_events", self.call(command=patch))
            self.assertIn("RULE_CONTENT_orchestrating", self.call(kind="SessionStart", source="compact"))
            self.assertIn("RULE_CONTENT_events", self.call(command=patch))
        finally:
            self.env = original_env

    def test_sessions_worktrees_and_agents_do_not_share_rules(self) -> None:
        patch = "*** Update File: src/events/a.gd\n"
        self.call(command=patch)
        variants: tuple[dict[str, Any], ...] = (
            {"session_id": "other-session"},
            {"root": self.make_repo("worktree")},
            {"agent_id": "child"},
            {"transcript_path": "/tmp/child-transcript.jsonl"},
        )
        for variant in variants:
            with self.subTest(variant=variant):
                self.assertIn("RULE_CONTENT_events", self.call(command=patch, **variant))
                self.assertEqual(self.call(command=patch, **variant), "")
        self.assertIn("RULE_CONTENT_orchestrating", self.call(kind="SubagentStart", agent_id="fresh"))

    def test_shell_reminder_does_not_lint_every_command(self) -> None:
        text = self.call(tool="Bash", command="pwd")
        self.assertTrue(text)
        self.assertIn("committing", text)
        self.assertEqual(self.call(tool="Bash", command="pwd"), "")
        self.assertEqual(self.call(kind="PostToolUse", tool="Bash", command="pwd"), "")
        self.write("AGENTS.md")
        self.assertEqual(self.call(kind="PostToolUse", tool="Bash", command="pwd"), "")

    def test_document_lint_includes_agents_and_rename_destination(self) -> None:
        self.write("AGENTS.md")
        self.write("docs/GUIDE.md")
        text = self.call(
            kind="PostToolUse",
            command="*** Update File: AGENTS.md\n*** Update File: old.txt\n*** Move to: docs/GUIDE.md\n",
        )
        self.assertIn("AGENTS.md", text)
        self.assertIn("GUIDE.md", text)

    def test_history_exemptions_and_deleted_files_are_ignored(self) -> None:
        names = ("docs/DECISIONS.md", "docs/playtests/PLAYTEST-01.md", "docs/evidence/README.md")
        for name in names:
            self.write(name)
        patch = "".join(f"*** Update File: {name}\n" for name in names)
        patch += "*** Delete File: docs/REMOVED.md\n"
        self.assertEqual(self.call(kind="PostToolUse", command=patch), "")
        self.assertEqual(self.call(kind="PostToolUse", tool="Bash", command="pwd"), "")

    def test_git_grep_guard_denies_an_unbounded_git_grep(self) -> None:
        output = self.call_raw(command='git grep -n -i "foo\\|bar" origin/main -- docs/')
        assert output is not None
        specific = output["hookSpecificOutput"]
        self.assertEqual(specific["hookEventName"], "PreToolUse")
        self.assertEqual(specific["permissionDecision"], "deny")
        self.assertIn("-I", specific["permissionDecisionReason"])

    def test_git_grep_guard_allows_a_guarded_git_grep_and_still_reminds(self) -> None:
        # -I keeps it bounded (see git-grep-guard.sh's own header); the call is not denied,
        # so the ordinary shell-reminder still fires underneath it.
        text = self.call(tool="Bash", command="git grep -n -I -i foo origin/main -- docs/")
        self.assertIn("committing", text)

    def test_git_grep_guard_denies_a_git_grep_mention_in_a_commit_message(self) -> None:
        # This design prefers a false deny to a false allow and matches on the raw command text,
        # so a mention denies too -- confirming the adapter forwards that, not only a real
        # invocation's deny.
        output = self.call_raw(command='git commit -m "explains why git grep needs a guard"')
        assert output is not None
        self.assertEqual(output["hookSpecificOutput"]["permissionDecision"], "deny")

    def test_git_grep_guard_denies_a_wrapped_invocation(self) -> None:
        # Confirms the adapter forwards a deny for the wrapper-command shape too (timeout, sudo,
        # env, ... -- see git-grep-guard.sh's own header for the full list this closes).
        output = self.call_raw(command='timeout 5 git grep -n -i "foo" origin/main -- docs/')
        assert output is not None
        self.assertEqual(output["hookSpecificOutput"]["permissionDecision"], "deny")

    def test_git_grep_guard_denies_quoted_code_run_by_a_nested_interpreter(self) -> None:
        output = self.call_raw(command='bash -c "git grep -n -i pattern origin/main -- docs/"')
        assert output is not None
        self.assertEqual(output["hookSpecificOutput"]["permissionDecision"], "deny")

    def test_git_grep_guard_allows_git_log_grep_option(self) -> None:
        # The one mention still allowed: --grep is an option glued to a dash, never its own word.
        text = self.call(tool="Bash", command="git log --grep=foo")
        self.assertIn("committing", text)

    def test_git_grep_guard_denies_across_an_unquoted_newline(self) -> None:
        # The adapter forwards the guard's output verbatim, so a fix in the guard itself needs no
        # adapter change -- this only confirms that path stays wired up: an unquoted newline
        # separates commands like `;`, and the incident command was exactly this shape (a `git
        # fetch` on the line before the crashing `git grep`).
        output = self.call_raw(command='git fetch -q origin main\ngit grep -n -i "foo" origin/main -- docs/')
        assert output is not None
        self.assertEqual(output["hookSpecificOutput"]["permissionDecision"], "deny")

    def test_git_grep_guard_denies_past_an_unknown_global_option(self) -> None:
        # Fail-safe: an unrecognised global git option before `grep` (here, -c name=value) must
        # not stop the scan.
        output = self.call_raw(command='git -c pager.grep=false grep -n -i "foo" origin/main -- docs/')
        assert output is not None
        self.assertEqual(output["hookSpecificOutput"]["permissionDecision"], "deny")

    def test_git_grep_guard_denies_a_full_path_and_upper_case_invocation(self) -> None:
        # The adapter forwards the guard's output verbatim, so this only confirms the
        # normalise-before-tokenise fix (backslash-newline pairs and stray backslashes deleted,
        # git/grep compared by last path component case-insensitively) is wired through this path
        # too -- neither shape is an exact-string "git"/"grep" match without it.
        for command in (
            "/usr/bin/git grep -n -i pattern origin/main -- docs/",
            'GIT GREP -n -i "pattern" origin/main -- docs/',
        ):
            with self.subTest(command=command):
                output = self.call_raw(command=command)
                assert output is not None
                self.assertEqual(output["hookSpecificOutput"]["permissionDecision"], "deny")

    def test_git_grep_guard_denies_a_quoted_argument_and_a_python_list(self) -> None:
        # A quote mark used only to protect a `-C` path or to wrap a Python list element (not a
        # substitution, not an alias) reads as an ordinary shell/Python argument -- these must not
        # slip through just because the adapter, not the guard itself, is what's under test here.
        for command in (
            'git -C "/Users/krause/workspace/nappy-claude" grep -n -i "foo" origin/main -- docs/',
            '"git" grep -n -i foo origin/main -- docs/',
            'g"i"t grep -n -i foo origin/main -- docs/',
            'python3 -c \'import subprocess; subprocess.run(["git", "grep", "-n", "-i", "foo", '
            '"origin/main", "--", "docs/"])\'',
        ):
            with self.subTest(command=command):
                output = self.call_raw(command=command)
                assert output is not None
                self.assertEqual(output["hookSpecificOutput"]["permissionDecision"], "deny")

    def test_git_grep_guard_denies_a_glued_quote_and_a_command_given_as_a_list(self) -> None:
        # A word glued onto a quote (an f-string, VAR="...") is read with the quote as a space,
        # and a `command` sent as an argument list is joined rather than skipped.
        for command in (
            "python3 -c 'import subprocess; subprocess.run(f\"git grep -n -i {p} -- docs/\", shell=True)'",
            'cmd="git grep -n -i foo origin/main -- docs/"; $cmd',
            ["bash", "-lc", "git grep -n -i foo -- docs/"],
        ):
            with self.subTest(command=command):
                output = self.call_raw(tool_input={"command": command})
                assert output is not None
                self.assertEqual(output["hookSpecificOutput"]["permissionDecision"], "deny")
        text = self.call(tool="Bash", command="git grep -n foo -- '*.md' 2>/dev/null")
        self.assertIn("committing", text)

    def test_paths_outside_repository_do_not_load_rules(self) -> None:
        text = self.call(
            command="*** Update File: ../outside/src/events/a.gd\n*** Update File: /tmp/outside/src/city/b.gd\n"
        )
        self.assertEqual(text, "")


if __name__ == "__main__":
    unittest.main()
