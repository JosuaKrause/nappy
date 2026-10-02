#!/usr/bin/env python3
"""Exercise Codex payloads through the real shared hooks in isolated fixtures."""

import importlib.util
import json
import os
import shutil
import subprocess
import sys
import tempfile
import time
import unittest
from pathlib import Path
from typing import Any
from unittest import mock

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
        # Pinned to a machine with identities set up, so the write guard's own deny is what every
        # test below sees wherever the suite runs: a Claude Code cloud session, or a CI runner with
        # no identity directory, would otherwise turn an ordinary write into an ask (see
        # test_github_write_guard_ask_reaches_codex_as_a_deny for that path).
        (self.base / "agents").mkdir()
        self.env = dict(os.environ, TMPDIR=str(self.base / "state"), NAPPY_AGENTS_DIR=str(self.base / "agents"))
        self.env.pop("CLAUDE_CODE_REMOTE", None)
        self.env.pop("NAPPY_ASK_FOR_PLAYER_WRITES", None)

    def make_repo(self, name: str) -> Path:
        root = self.base / name
        (root / "tools").mkdir(parents=True)
        shutil.copytree(SOURCE / ".claude/hooks", root / ".claude/hooks")
        for name in ("codex-hooks.py", "lint.sh"):
            shutil.copy2(SOURCE / "tools" / name, root / "tools" / name)
        # lint.sh reads the name word lists to check a playtest's or a record's name against the rest.
        shutil.copytree(SOURCE / "tools/names", root / "tools/names")
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

    def test_evidence_edit_loads_verify_through_the_adapter(self) -> None:
        text = self.call(command="*** Update File: docs/evidence/experiment/README.md\n")
        self.assertEqual(text.count("RULE_CONTENT_verify"), 1)

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
        # --grep is an option glued to a dash, never its own word, so this is no git grep.
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

    def test_git_grep_guard_falls_back_to_a_cmd_field(self) -> None:
        # A fail-safe, not a payload Codex is known to send: Codex reports shell calls as Bash
        # with `command` (measured with Codex CLI 0.157.1). `cmd` is the argument name of the
        # model-facing exec tool, so if a Codex version ever passed it through, the adapter
        # still checks it rather than skipping the guard.
        output = self.call_raw(tool="exec_command", tool_input={"cmd": "git grep -n -i foo -- docs/"})
        assert output is not None
        self.assertEqual(output["hookSpecificOutput"]["permissionDecision"], "deny")
        allowed = self.call_raw(tool="exec_command", tool_input={"cmd": "git grep -I -n -i foo -- docs/"})
        assert allowed is not None
        self.assertNotIn("permissionDecision", allowed["hookSpecificOutput"])

    def test_git_grep_guard_over_the_bound_is_one_fast_regex(self) -> None:
        # Past too_long (32 KB), a backslash-newline pair, a lone backslash, a quote mark or $
        # between the letters of git/grep still reads as the word, so an obscured pair over the
        # bound denies, through the adapter the same as directly; naming only "git" (no "grep"
        # anywhere) allows, and so do lines ending in "g" and starting with "it"/"rep", which the
        # shell never joins.
        padding = "a" * 40000
        for command in (
            f"echo '{padding}'; g\\it status; g\"r\"ep foo",
            f"echo '{padding}'; g$'i't status; gr$'e'p foo",
            f"echo '{padding}'; g\\\nit status; gr\\\nep foo",
        ):
            with self.subTest(command=command[-30:]):
                output = self.call_raw(command=command)
                assert output is not None
                self.assertEqual(output["hookSpecificOutput"]["permissionDecision"], "deny")
        text = self.call(tool="Bash", command=f"echo '{padding}'; git status")
        self.assertIn("committing", text)
        self.assertIsNone(self.call_raw(command=f"cat <<EOF\n{padding} drawing\nitem, PNG\nreplacement\nEOF"))
        # Over hard_cap (1 MB) every command denies without being read.
        output = self.call_raw(command="echo '" + "a" * 1100000 + "'")
        assert output is not None
        self.assertEqual(output["hookSpecificOutput"]["permissionDecision"], "deny")
        self.assertIn("over 1 MB", output["hookSpecificOutput"]["permissionDecisionReason"])
        # These two shapes are dense in the characters the full readings drop; past 32 KB the
        # guard never builds those readings, so timed alone (the adapter also runs
        # github-write-guard.sh, whose cost is its own) each is decided in well under a second.
        guard = self.root / ".claude/hooks/git-grep-guard.sh"
        for command in ("echo " + "a'" * 500000, "echo " + "x\\\n" * 330000):
            with self.subTest(command=command[:20]):
                payload = json.dumps({"tool_name": "Bash", "tool_input": {"command": command}})
                started = time.monotonic()
                result = subprocess.run([str(guard)], input=payload, text=True, capture_output=True)
                self.assertLess(time.monotonic() - started, 1.5)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout.strip(), "")

    def test_github_write_guard_denies_an_unwrapped_git_push(self) -> None:
        output = self.call_raw(command="git push origin main")
        assert output is not None
        specific = output["hookSpecificOutput"]
        self.assertEqual(specific["hookEventName"], "PreToolUse")
        self.assertEqual(specific["permissionDecision"], "deny")
        self.assertIn("agent-identity.py run", specific["permissionDecisionReason"])

    def test_github_write_guard_ask_reaches_codex_as_a_deny(self) -> None:
        # Where no identity can work the guard asks Claude Code's player about an ordinary write;
        # Codex always refuses one instead (2026-10-02: "make the codex version always refuse").
        for env in (
            dict(self.env, CLAUDE_CODE_REMOTE="true"),
            dict(self.env, NAPPY_AGENTS_DIR=str(self.base / "no-such-dir")),
        ):
            with self.subTest(remote=env.get("CLAUDE_CODE_REMOTE"), agents=env["NAPPY_AGENTS_DIR"]):
                self.env = env
                output = self.call_raw(command="git push origin feature/x")
                assert output is not None
                specific = output["hookSpecificOutput"]
                self.assertEqual(specific["permissionDecision"], "deny")
                self.assertIn("Codex never runs this as the player", specific["permissionDecisionReason"])

    def test_github_write_guard_denies_an_unwrapped_gh_pr_comment(self) -> None:
        output = self.call_raw(command='gh pr comment 391 --body "hi"')
        assert output is not None
        self.assertEqual(output["hookSpecificOutput"]["permissionDecision"], "deny")

    def test_github_write_guard_allows_the_wrapped_form_and_still_reminds(self) -> None:
        # codex-coder, not claude-coder: this is Codex's own adapter, and the guard accepts any
        # role either way, but a reader copying the example should see the one Codex actually uses.
        text = self.call(
            tool="Bash",
            command="uv run python tools/agent-identity.py run codex-coder -- git push origin main",
        )
        self.assertIn("committing", text)

    def test_github_write_guard_allows_a_read(self) -> None:
        text = self.call(tool="Bash", command="gh pr view 391")
        self.assertIn("committing", text)

    def test_github_write_guard_denies_a_reviewer_identitys_push(self) -> None:
        # A reviewer never pushes through this tool, whatever GitHub's own contents:write
        # permission allows -- same call the hook makes for Claude Code, confirmed through the
        # adapter since nothing here is Codex-specific.
        output = self.call_raw(
            command="uv run python tools/agent-identity.py run codex-reviewer -- git push origin main"
        )
        assert output is not None
        specific = output["hookSpecificOutput"]
        self.assertEqual(specific["permissionDecision"], "deny")
        self.assertIn("reviewers never push", specific["permissionDecisionReason"])

    def test_github_write_guard_denies_a_gh_api_flag_before_the_endpoint(self) -> None:
        # A flag before the endpoint is how gh itself accepts a write, so the scan has to see it
        # rather than start past the call's leading options.
        output = self.call_raw(command="gh api -X PUT repos/o/r/pulls/1/merge")
        assert output is not None
        self.assertEqual(output["hookSpecificOutput"]["permissionDecision"], "deny")

    def test_github_write_guard_allows_a_graphql_query_but_denies_a_mutation(self) -> None:
        text = self.call(tool="Bash", command="gh api graphql -f query=query{me{login}}")
        self.assertIn("committing", text)
        output = self.call_raw(command="gh api graphql -f query=mutation{resolveReviewThread(x:1){id}}")
        assert output is not None
        self.assertEqual(output["hookSpecificOutput"]["permissionDecision"], "deny")

    def test_github_write_guard_denies_a_reviewers_merge_too(self) -> None:
        output = self.call_raw(command="uv run python tools/agent-identity.py run codex-reviewer -- gh pr merge 1")
        assert output is not None
        specific = output["hookSpecificOutput"]
        self.assertEqual(specific["permissionDecision"], "deny")
        self.assertIn("never push or merge", specific["permissionDecisionReason"])

    def test_github_write_guard_denies_a_graphql_query_from_a_file(self) -> None:
        # The query's own text is not on the command line, so it cannot be checked for
        # "mutation" at all.
        output = self.call_raw(command="gh api graphql -F query=@resolve.graphql -F id=PRRT_x")
        assert output is not None
        self.assertEqual(output["hookSpecificOutput"]["permissionDecision"], "deny")

    def test_github_write_guard_denies_a_multiline_graphql_mutation_after_a_comment(self) -> None:
        # The quoted query's newline splits it here, so the mutation sits past the first line.
        for query in (
            '# Resolve the thread\nmutation { resolveReviewThread(input:{threadId:"x"}) { thread { id } } }',
            'fragment F on PullRequest { id }\nmutation { mergePullRequest(input:{pullRequestId:"x"}) { id } }',
        ):
            with self.subTest(query=query):
                output = self.call_raw(command=f"gh api graphql -f 'query={query}'")
                assert output is not None
                self.assertEqual(output["hookSpecificOutput"]["permissionDecision"], "deny")

    def test_github_write_guard_sees_a_write_flag_after_a_quoted_separator(self) -> None:
        # A quoted `|`, `(` or `;` belongs to its argument, so the flags after it are still read.
        for command in (
            "gh api repos/o/r/issues --jq '.html_url | ascii_downcase' -f title=x",
            "gh api graphql -f query='query($id: ID!) { node(id: $id) { id } }' --input body.json",
            "gh api repos/o/r/issues/1/comments --jq '.id; .url' -f body=x",
        ):
            with self.subTest(command=command):
                output = self.call_raw(command=command)
                assert output is not None
                self.assertEqual(output["hookSpecificOutput"]["permissionDecision"], "deny")

    def test_github_write_guard_ends_a_wrapper_inside_a_quoted_script_at_its_separator(self) -> None:
        # The shell running the quoted script ends the wrapper's reach at the script's own `;`,
        # `&&` or newline, so the write after it is the player's and is denied.
        wrap = "uv run python tools/agent-identity.py run"
        for command in (
            f'bash -c "{wrap} codex-coder -- git fetch; git push"',
            f"bash -c '{wrap} codex-coder -- git commit -m x && git push'",
            f'sh -c "cd /tmp && {wrap} codex-coder -- gh pr view 1 && gh pr merge 1"',
            f'bash -lc "{wrap} codex-coder -- git status\ngit push"',
        ):
            with self.subTest(command=command):
                output = self.call_raw(command=command)
                assert output is not None
                self.assertEqual(output["hookSpecificOutput"]["permissionDecision"], "deny")

    def test_github_write_guard_lets_a_wrapper_outside_the_quotes_cover_the_script(self) -> None:
        text = self.call(
            tool="Bash",
            command='uv run python tools/agent-identity.py run codex-coder -- bash -c "git status; git push"',
        )
        self.assertIn("committing", text)

    def test_github_write_guard_reads_a_comment_and_an_ansi_c_string_as_the_shell_does(self) -> None:
        # An apostrophe in a `#` comment opens no quote, so the wrapper still ends at the newline;
        # a `$'...'` string keeps its own escapes (`\'` stays inside it, `\n` is a newline).
        wrap = "uv run python tools/agent-identity.py run codex-coder --"
        for command in (
            f'{wrap} git commit -m "Fix the ask"  # the player\'s words\ngit push',
            f"{wrap} git commit -m x # it's fine; git push",
            f"{wrap} git commit -m $'Don\\'t break'\ngit push",
            f"{wrap} git commit -m $'Don\\'t break'; git push",
            "bash -c $'git status\\ngit push'",
        ):
            with self.subTest(command=command):
                output = self.call_raw(command=command)
                assert output is not None
                self.assertEqual(output["hookSpecificOutput"]["permissionDecision"], "deny")
        text = self.call(tool="Bash", command=f"{wrap} git push # it's pushed")
        self.assertIn("committing", text)

    def test_github_write_guard_reads_a_heredoc_commit_unsure(self) -> None:
        # A heredoc or a `$(` inside quotes is a quoting context the pass does not model, so every
        # separator ends the wrapper's exemption there; the forgotten push after it is denied.
        wrap = "uv run python tools/agent-identity.py run codex-coder --"

        def heredoc_commit(body: str) -> str:
            return f"{wrap} git commit -m \"$(cat <<'EOF'\n{body}\nEOF\n)\""

        bodies = (
            'Fix the "can\'t push" error',
            'the "x" thing',
            '"can\'t" and "won\'t"',
            "it's and it's",
            'a lone " here',
        )
        commands = [heredoc_commit(body) + sep + "git push" for body in bodies for sep in ("\n", "; ")]
        commands.append(f'{wrap} git commit -m "$(printf \'%s\' "it\'s")"; git push')
        commands.append("cat <<'EOF'\nit's\nEOF\ngh api repos/o/r/issues --jq '.a | b' -f title=x")
        commands.append("gh api repos/o/r/issues --jq '.a | b' -f title=x")
        for command in commands:
            with self.subTest(command=command):
                output = self.call_raw(command=command)
                assert output is not None
                self.assertEqual(output["hookSpecificOutput"]["permissionDecision"], "deny")
        text = self.call(tool="Bash", command=heredoc_commit('Fix the "can\'t push" error') + f"\n{wrap} git push")
        self.assertIn("committing", text)

    def test_github_write_guard_joins_lines_only_where_the_shell_does(self) -> None:
        # An escaped backslash or a comment ending in a backslash leaves the newline a separator.
        for command in (
            "echo C:\\\\\ngit push",
            "uv run python tools/agent-identity.py run codex-coder -- git fetch # note \\\ngit push",
        ):
            with self.subTest(command=command):
                output = self.call_raw(command=command)
                assert output is not None
                self.assertEqual(output["hookSpecificOutput"]["permissionDecision"], "deny")
        text = self.call(tool="Bash", command="uv run python tools/agent-identity.py run codex-coder -- git \\\npush")
        self.assertIn("committing", text)

    def test_github_write_guard_denies_a_long_command_without_reading_it(self) -> None:
        # A hook past its timeout lets the command through, so over 64 KB a command naming git or
        # gh is denied at once, with the hint to use a file.
        long_text = "a" * 70000
        output = self.call_raw(
            command=f"uv run python tools/agent-identity.py run codex-coder -- git commit -m '{long_text}'"
        )
        assert output is not None
        specific = output["hookSpecificOutput"]
        self.assertEqual(specific["permissionDecision"], "deny")
        self.assertIn("over 64 KB", specific["permissionDecisionReason"])
        self.assertIn("git commit -F file", specific["permissionDecisionReason"])
        text = self.call(tool="Bash", command=f"echo '{long_text}'")
        self.assertIn("committing", text)
        # A backslash-newline the pass would join still counts as the word it joins into.
        output = self.call_raw(command=f"echo '{long_text}'; gi\\\nt push")
        assert output is not None
        self.assertEqual(output["hookSpecificOutput"]["permissionDecision"], "deny")

    def test_github_write_guard_over_the_bound_is_one_dumb_fast_search(self) -> None:
        # Over 64 KB, backslash-newline pairs, backslashes and quotes are skipped wherever they
        # fall, so no mix of joined and unjoined lines hides a name, while a newline on its own
        # still separates two words; over 1 MB nothing is read and every command denies.
        padding = "x" * 70000
        for command in (
            f"echo {padding}\necho x\\\\\ngi\\\nt push",
            f"echo {padding}; 'g'\"i\"t push",
            f"echo {padding}; g$''it push",
            f'echo {padding}; g$""it push',
            "echo " + "a" * 1100000,
        ):
            with self.subTest(command=command[-40:]):
                output = self.call_raw(command=command)
                assert output is not None
                self.assertEqual(output["hookSpecificOutput"]["permissionDecision"], "deny")
        # Just under the cap, the guard itself (timed alone: the adapter also runs git-grep-guard.sh,
        # whose cost is its own) decides in well under a second and allows what names nothing.
        guard = self.root / ".claude/hooks/github-write-guard.sh"
        for command in ("echo " + "a'" * 500000, "echo " + "x\\\n" * 330000):
            with self.subTest(command=command[:20]):
                payload = json.dumps({"tool_name": "Bash", "tool_input": {"command": command}})
                started = time.monotonic()
                result = subprocess.run([str(guard)], input=payload, text=True, capture_output=True)
                self.assertLess(time.monotonic() - started, 1.5)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout.strip(), "")

    def test_both_guards_decide_chains_of_swallowing_options_well_inside_the_budget(self) -> None:
        # The adapter runs git-grep-guard.sh and then github-write-guard.sh on the same command,
        # under the one 10-second budget Codex gives the hook, so the two costs add up. In a chain
        # of `git -c git -c ...` every git's run of options reaches the end of the chain, and both
        # guards read those runs from a table built once, so the whole call stays well inside the
        # budget: at about 10 KB with a guarded search (which the search guard allows, so the
        # write guard reads the command too) and an unwrapped push at the end; at the search
        # guard's 32 KB bound, read in full by both and allowed; at the write guard's 64 KB bound
        # (past the search guard's, where one regex finds no second word and allows), with and
        # without a push; and a heredoc naming gh api on every line.
        unit = "git -c "
        line = "we call gh api here and there\n"
        cases = []
        for size, tail, expected in (
            (10000, "; git grep -I x; git push origin main", "deny"),
            (32700, "; git grep -I x", None),
            (65400, "; git push origin main", "deny"),
            (65400, "; echo done", None),
        ):
            cases.append((unit * ((size - len(tail)) // len(unit)) + tail, expected))
        cases.append(("cat <<EOF\n" + line * 2170 + "EOF", None))
        # A quoted script at the search guard's bound, every -C argument quoted with a space: all
        # four of its readings and the write guard's grouped reading run to the end.
        cases.append(("bash -c '" + 'git -C "a b" ' * 2512 + "'; git grep -I x", None))
        for command, expected in cases:
            with self.subTest(size=len(command), expected=expected):
                started = time.monotonic()
                output = self.call_raw(command=command)
                self.assertLess(time.monotonic() - started, 5.0)
                # An allowed call prints the shell reminder once per session, then nothing.
                decision = (output or {}).get("hookSpecificOutput", {}).get("permissionDecision")
                self.assertEqual(decision, expected)

    def test_a_quoted_option_argument_is_one_word_to_both_guards(self) -> None:
        # A -C/-c argument with a space in it is one shell word, so the word after it is the
        # subcommand, at the top level and inside a quoted script alike; a wrapper's own
        # argument-taking option, and the script after bash -c, leave a pushing script in command
        # position. The wrapped push still allows.
        wrap = "uv run python tools/agent-identity.py run codex-coder -- "
        for command in (
            'git -C "/x y" push',
            "git -c 'a=b c' push",
            'git -C "$(pwd)/my dir" push',
            "bash -c 'git -C \"/x y\" push'",
            "bash -c 'git -C \"/x y\" grep x'",
            "sudo -u root tools/prune-merged.sh x",
            "bash -c 'tools/prune-merged.sh x'",
        ):
            with self.subTest(command=command):
                output = self.call_raw(command=command)
                assert output is not None
                self.assertEqual(output["hookSpecificOutput"]["permissionDecision"], "deny")
        for command in (wrap + 'git -C "/x y" push', "gh -R 'a b' pr view 1", "bash -c 'cat tools/prune-merged.sh'"):
            with self.subTest(command=command):
                output = self.call_raw(command=command)
                decision = (output or {}).get("hookSpecificOutput", {}).get("permissionDecision")
                self.assertIsNone(decision)

    def test_a_guard_past_the_shared_budget_denies_rather_than_lets_through(self) -> None:
        # Codex lets a call through when the hook outruns its 10 seconds, so the adapter gives the
        # two guards a shared budget short of that and denies when a guard is still running at its
        # end, killing it and whatever it started (here a sleep holding the guard's stdout open,
        # as jq does). The reply comes back inside Codex's timeout, not after the guard.
        (self.root / ".claude/hooks/github-write-guard.sh").write_text("#!/usr/bin/env bash\nsleep 30\n")
        started = time.monotonic()
        output = self.call_raw(command="git status")
        self.assertLess(time.monotonic() - started, 9.5)
        assert output is not None
        specific = output["hookSpecificOutput"]
        self.assertEqual(specific["permissionDecision"], "deny")
        self.assertIn("github-write-guard.sh did not finish", specific["permissionDecisionReason"])

    def test_a_guard_that_fails_denies_rather_than_crashes_the_adapter(self) -> None:
        # An adapter that raises exits non-zero, which Codex does not treat as a deny, so every way
        # a guard can fail -- a non-zero exit, a reply that is not JSON -- denies instead.
        guard = self.root / ".claude/hooks/github-write-guard.sh"
        for body, error in (("exit 3\n", "CalledProcessError"), ("echo not-json\n", "JSONDecodeError")):
            with self.subTest(error=error):
                guard.write_text("#!/usr/bin/env bash\n" + body)
                output = self.call_raw(command="git status")
                assert output is not None
                specific = output["hookSpecificOutput"]
                self.assertEqual(specific["permissionDecision"], "deny")
                self.assertIn(error, specific["permissionDecisionReason"])

    def test_a_kill_that_raises_still_denies(self) -> None:
        # macOS answers killpg on a group holding only an unreaped zombie with EPERM; the timeout's
        # deny stands however the kill fails.
        spec = importlib.util.spec_from_file_location("codex_hooks", self.root / "tools/codex-hooks.py")
        assert spec is not None and spec.loader is not None
        adapter = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(adapter)
        script = self.base / "slow.sh"
        script.write_text("#!/usr/bin/env bash\nsleep 2\n")

        def refuse(pid: int, sig: int) -> None:
            raise PermissionError(1, "Operation not permitted")

        with mock.patch.object(adapter.os, "killpg", refuse):
            output = adapter.run_guard(script, "{}", time.monotonic() + 0.3)
        self.assertEqual(output["hookSpecificOutput"]["permissionDecision"], "deny")
        self.assertIn("did not finish", output["hookSpecificOutput"]["permissionDecisionReason"])

    def test_commands_after_a_reserved_word_and_empty_arguments_are_read(self) -> None:
        # A command after `do`, `then`, `{`, `time` or `exec` starts a command of its own, so a
        # write there is scanned in full; a field after a quoted separator counts even under an
        # earlier GET; an empty quoted -C argument is still the argument; and an assignment whose
        # value names a pushing script is not that script.
        loop = (
            "gh api -X GET repos/o/r/issues --jq '.[].number' > ids; for n in $(cat ids); do "
            "gh api repos/o/r/issues/$n/comments --jq '.id | tostring' -f body=ping; done"
        )
        for command in (loop, 'git -C "" push', "git -C '' grep x", "time tools/prune-merged.sh x"):
            with self.subTest(command=command[:40]):
                output = self.call_raw(command=command)
                assert output is not None
                self.assertEqual(output["hookSpecificOutput"]["permissionDecision"], "deny")
        output = self.call_raw(command='echo $(date); p=tools/prune-merged.sh; sed -n 1,5p "$p"')
        self.assertIsNone((output or {}).get("hookSpecificOutput", {}).get("permissionDecision"))

    def test_a_call_after_sh_c_starts_a_command_and_a_get_field_after_jq_reads(self) -> None:
        # The script after `sh -c` is a command of its own, so a call there ends a GraphQL read's
        # scan and is scanned in full; a field right after a quoted `--jq '.a | .b'` is still the
        # GET call's own.
        output = self.call_raw(
            command="gh api graphql -f query='{viewer{login}}' | sh -c \"gh api repos/o/r/issues/1/comments "
            "--jq '.a | .b' -f body=x\"; echo $(true)"
        )
        assert output is not None
        self.assertEqual(output["hookSpecificOutput"]["permissionDecision"], "deny")
        for command in (
            "gh api graphql -f query='{viewer{login}}' | /usr/bin/env gh api repos/o/r/issues/1/comments "
            "--jq '.a | .b' -f body=x; echo $(true)",
            "gh api repos/o/r/issues/1/comments --jq '.x; sh -c git' -X POST",
            "/usr/bin/env tools/prune-merged.sh x",
        ):
            with self.subTest(command=command[:50]):
                output = self.call_raw(command=command)
                assert output is not None
                self.assertEqual(output["hookSpecificOutput"]["permissionDecision"], "deny")
        output = self.call_raw(command="gh api -X GET search/issues --jq '.items[] | .number' -f q='repo:a/b is:open'")
        self.assertIsNone((output or {}).get("hookSpecificOutput", {}).get("permissionDecision"))

    def test_github_write_guard_explains_a_wrapped_heredoc_false_deny(self) -> None:
        command = (
            "uv run python tools/agent-identity.py run codex-coder -- gh pr create --title t --body "
            "\"$(cat <<'EOF'\nRun `git push` through the wrapper.\nEOF\n)\""
        )
        output = self.call_raw(command=command)
        assert output is not None
        specific = output["hookSpecificOutput"]
        self.assertEqual(specific["permissionDecision"], "deny")
        self.assertIn("If this command is already wrapped", specific["permissionDecisionReason"])
        self.assertIn("--body-file", specific["permissionDecisionReason"])

    def test_github_write_guard_allows_a_read_with_a_piped_jq(self) -> None:
        text = self.call(tool="Bash", command="gh api repos/o/r/issues --jq '.[] | .title'")
        self.assertIn("committing", text)

    def test_github_write_guard_denies_a_graphql_body_from_input(self) -> None:
        output = self.call_raw(command="gh api graphql --input payload.json")
        assert output is not None
        self.assertEqual(output["hookSpecificOutput"]["permissionDecision"], "deny")

    def test_github_write_guard_allows_an_explicit_get_with_a_field(self) -> None:
        text = self.call(tool="Bash", command="gh api -X GET search/issues -f q=foo")
        self.assertIn("committing", text)

    def test_github_write_guard_denies_a_reviewers_update_branch_api_call(self) -> None:
        output = self.call_raw(
            command="uv run python tools/agent-identity.py run codex-reviewer -- "
            "gh api -X PUT repos/o/r/pulls/1/update-branch"
        )
        assert output is not None
        specific = output["hookSpecificOutput"]
        self.assertEqual(specific["permissionDecision"], "deny")
        self.assertIn("never push or merge", specific["permissionDecisionReason"])

    def test_github_write_guard_runs_after_git_grep_guard_denies_first(self) -> None:
        # Both guards run in order; an unbounded git grep denies before github-write-guard.sh is
        # ever reached, so its reason -- not a GitHub-write one -- is what comes back.
        output = self.call_raw(command='git grep -n -i "foo" origin/main -- docs/')
        assert output is not None
        self.assertEqual(output["hookSpecificOutput"]["permissionDecision"], "deny")
        self.assertIn("-I", output["hookSpecificOutput"]["permissionDecisionReason"])

    def test_paths_outside_repository_do_not_load_rules(self) -> None:
        text = self.call(
            command="*** Update File: ../outside/src/events/a.gd\n*** Update File: /tmp/outside/src/city/b.gd\n"
        )
        self.assertEqual(text, "")


if __name__ == "__main__":
    unittest.main()
