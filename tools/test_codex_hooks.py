#!/usr/bin/env python3
"""Exercise Codex payloads through the real shared hooks in isolated fixtures."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


SOURCE = Path(__file__).resolve().parent.parent


class CodexHooksTest(unittest.TestCase):
    def test_codex_skills_are_the_canonical_claude_files(self):
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

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name).resolve()
        self.root = self.make_repo("repo")
        self.env = dict(os.environ, TMPDIR=str(self.base / "state"))

    def make_repo(self, name):
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

    def call(self, kind="PreToolUse", tool="apply_patch", command="", root=None, **extra):
        root = root or self.root
        event = dict(hook_event_name=kind, session_id="session", cwd=str(root),
                     tool_name=tool, tool_input={"command": command})
        event.update(extra)
        result = subprocess.run(
            [sys.executable, str(root / "tools/codex-hooks.py")],
            input=json.dumps(event), text=True, capture_output=True, env=self.env,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        if not result.stdout.strip():
            return ""
        output = json.loads(result.stdout)
        self.assertNotIn("suppressOutput", output)
        specific = output["hookSpecificOutput"]
        self.assertEqual(specific["hookEventName"], kind)
        self.assertNotIn("suppressOutput", specific)
        return specific["additionalContext"]

    def write(self, name, content="- [x] Finished\n"):
        target = self.root / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content)

    def test_multifile_patch_loads_all_matching_skills_once(self):
        text = self.call(command="*** Begin Patch\n*** Update File: src/events/a.gd\n"
                         "*** Add File: src/city/b.gd\n*** Update File: src/events/c.gd\n"
                         "*** End Patch\n")
        for skill in ("events", "city", "godot", "orchestrating"):
            self.assertEqual(text.count(f"RULE_CONTENT_{skill}"), 1)
        self.assertNotIn("RULE_CONTENT_cues", text)
        self.assertEqual(self.call(command="*** Update File: src/events/a.gd\n"), "")

    def test_rename_destination_loads_its_rules(self):
        text = self.call(command="*** Update File: notes.txt\n*** Move to: src/ui/panel.gd\n")
        self.assertIn("RULE_CONTENT_cues", text)
        self.assertIn("RULE_CONTENT_godot", text)

    def test_compaction_reloads_session_and_path_rules(self):
        self.assertIn("RULE_CONTENT_orchestrating", self.call(kind="SessionStart", source="startup"))
        patch = "*** Update File: src/events/a.gd\n"
        self.assertIn("RULE_CONTENT_events", self.call(command=patch))
        self.assertEqual(self.call(command=patch), "")
        self.assertIn("RULE_CONTENT_orchestrating", self.call(kind="SessionStart", source="compact"))
        self.assertIn("RULE_CONTENT_events", self.call(command=patch))

    def test_sessions_worktrees_and_agents_do_not_share_rules(self):
        patch = "*** Update File: src/events/a.gd\n"
        self.call(command=patch)
        variants = ({"session_id": "other-session"},
                    {"root": self.make_repo("worktree")}, {"agent_id": "child"},
                    {"transcript_path": "/tmp/child-transcript.jsonl"})
        for variant in variants:
            with self.subTest(variant=variant):
                self.assertIn("RULE_CONTENT_events", self.call(command=patch, **variant))
                self.assertEqual(self.call(command=patch, **variant), "")
        self.assertIn("RULE_CONTENT_orchestrating", self.call(kind="SubagentStart", agent_id="fresh"))

    def test_shell_reminder_and_post_command_lint(self):
        text = self.call(tool="Bash", command="pwd")
        self.assertTrue(text)
        self.assertIn("committing", text)
        self.assertEqual(self.call(tool="Bash", command="pwd"), "")
        self.assertEqual(self.call(kind="PostToolUse", tool="Bash", command="pwd"), "")
        self.write("AGENTS.md")
        self.assertIn("AGENTS.md", self.call(kind="PostToolUse", tool="Bash", command="pwd"))

    def test_document_lint_includes_agents_and_rename_destination(self):
        self.write("AGENTS.md")
        self.write("docs/GUIDE.md")
        text = self.call(kind="PostToolUse", command="*** Update File: AGENTS.md\n"
                         "*** Update File: old.txt\n*** Move to: docs/GUIDE.md\n")
        self.assertIn("AGENTS.md", text)
        self.assertIn("GUIDE.md", text)

    def test_history_exemptions_and_deleted_files_are_ignored(self):
        names = ("docs/DECISIONS.md", "docs/PLAYTEST-01.md", "docs/evidence/README.md")
        for name in names:
            self.write(name)
        patch = "".join(f"*** Update File: {name}\n" for name in names)
        patch += "*** Delete File: docs/REMOVED.md\n"
        self.assertEqual(self.call(kind="PostToolUse", command=patch), "")
        self.assertEqual(self.call(kind="PostToolUse", tool="Bash", command="pwd"), "")

    def test_paths_outside_repository_do_not_load_rules(self):
        text = self.call(command="*** Update File: ../outside/src/events/a.gd\n"
                         "*** Update File: /tmp/outside/src/city/b.gd\n")
        self.assertEqual(text, "")


if __name__ == "__main__":
    unittest.main()
