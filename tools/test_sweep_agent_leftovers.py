"""tools/sweep-agent-leftovers.py against a scratch repository, never the real one.

The scratch main checkout holds copies of the sweep and of what it calls, so every path the
script derives from its own location lands in the scratch; gh is a fixture that only answers
`pr list`, and origin is a bare repository beside it.
"""

import importlib.util
import json
import os
import shutil
import subprocess
import sys
import tempfile
import time
import unittest
import unittest.mock
from pathlib import Path
from types import ModuleType

ROOT = Path(__file__).resolve().parents[1]
# The sweep, the remover it calls, and the two files that remover sources.
COPIED = ("sweep-agent-leftovers.py", "agent-setup.sh", "lib_regenerable_ignored.sh", "lib_disk_headroom.sh")
OLD_HOURS = 72

FAKE_GH = """#!/bin/sh
printf '%s\\n' "$*" >> "$FIXTURE_GH_CALLS"
[ "$1 $2" = "pr list" ] || exit 9
[ -z "${FIXTURE_GH_FAIL:-}" ] || { echo "gh: no network" >&2; exit 1; }
cat "$FIXTURE_PRS"
"""


class SweepTests(unittest.TestCase):
    def setUp(self) -> None:
        scratch = tempfile.TemporaryDirectory(prefix="sweep-test-")
        self.addCleanup(scratch.cleanup)
        self.root = Path(scratch.name).resolve()
        self.repo = self.root / "main"
        self.origin = self.root / "origin.git"
        self.projects = self.root / "projects"
        self.briefs = self.repo / ".claude" / "briefs"
        self.worktrees = self.repo / ".claude" / "worktrees"
        self.tool = self.repo / "tools" / "sweep-agent-leftovers.py"
        self.prs_file = self.root / "prs.json"
        self.gh_calls = self.root / "gh-calls"
        self.prs: list[dict[str, object]] = []
        bin_dir = self.root / "bin"
        for folder in (bin_dir, self.projects, self.repo / "tools"):
            folder.mkdir(parents=True)
        (bin_dir / "gh").write_text(FAKE_GH)
        (bin_dir / "gh").chmod(0o755)
        self.git = shutil.which("git") or "git"
        self.env = dict(os.environ)
        self.env.pop("NAPPY_AGENT_ROLE", None)
        self.env.pop("FIXTURE_GH_FAIL", None)
        self.env.update(
            GIT_CONFIG_NOSYSTEM="1",
            GIT_CONFIG_GLOBAL=os.devnull,
            GIT_AUTHOR_NAME="Fixture",
            GIT_AUTHOR_EMAIL="fixture@example.invalid",
            GIT_COMMITTER_NAME="Fixture",
            GIT_COMMITTER_EMAIL="fixture@example.invalid",
            PATH=f"{bin_dir}{os.pathsep}{os.environ['PATH']}",
            FIXTURE_PRS=str(self.prs_file),
            FIXTURE_GH_CALLS=str(self.gh_calls),
        )
        self.run_git("init", "--bare", "-b", "main", str(self.origin))
        self.run_git("init", "-b", "main", str(self.repo))
        for name in COPIED:
            shutil.copy2(ROOT / "tools" / name, self.repo / "tools" / name)
        (self.repo / ".gitignore").write_text(".claude/briefs/\n.claude/worktrees/\n.godot/\nbuild/\n")
        (self.repo / "tracked").write_text("base\n")
        self.run_git("add", ".", cwd=self.repo)
        self.run_git("commit", "-qm", "base", cwd=self.repo)
        self.run_git("remote", "add", "origin", str(self.origin), cwd=self.repo)
        self.run_git("push", "-q", "origin", "main", cwd=self.repo)
        self.briefs.mkdir(parents=True)
        self.write_prs()

    # ------------------------------------------------------------------------------ fixture ---
    def run_git(self, *args: str, cwd: Path | None = None) -> str:
        return subprocess.check_output(
            [self.git, *args], cwd=cwd or self.root, env=self.env, text=True, stderr=subprocess.DEVNULL
        )

    def write_prs(self) -> None:
        self.prs_file.write_text(json.dumps(self.prs))

    def pr(self, branch: str, state: str = "MERGED", number: int = 0, fork: bool = False) -> None:
        number = number or len(self.prs) + 1
        self.prs.append({"number": number, "state": state, "headRefName": branch, "isCrossRepository": fork})
        self.write_prs()

    def age(self, path: Path, hours: float = OLD_HOURS) -> None:
        """Backdates a file, or a checkout with everything in it and its HEAD."""
        then = time.time() - hours * 3600
        paths = [path]
        if path.is_dir():
            paths += list(path.rglob("*"))
            git_dir = Path(self.run_git("rev-parse", "--absolute-git-dir", cwd=path).strip())
            paths += [git_dir / "HEAD", git_dir / "logs" / "HEAD"]
        for each in paths:
            if each.exists() and not each.is_symlink():
                os.utime(each, (then, then))

    def brief(
        self,
        branch: str,
        *,
        merged: bool = True,
        released: bool = True,
        agents: tuple[str, ...] = (),
        worktree: str = "",
        hours: float = OLD_HOURS,
        name: str = "",
    ) -> Path:
        """A branch's brief as tools/agent-setup.sh starts it, old, its pull request merged."""
        path = self.briefs / (name or branch.replace("/", "-") + ".md")
        header = [f"branch: {branch}", f"worktree: {worktree or self.worktrees / 'gone'}", "spawned: 2026-01-01"]
        header += [f"agent: {agent}" for agent in agents]
        header += ["cleanup: ready"] if released else []
        path.write_text("\n".join(header) + "\n\n# The task\n\nbranch: not-the-header\n")
        self.age(path, hours)
        if merged:
            self.pr(branch)
        return path

    def transcript(self, agent: str, hours: float) -> None:
        path = self.projects / "session-1" / "subagents" / f"agent-{agent}.jsonl"
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("{}\n")
        self.age(path, hours)

    def checkout(self, name: str, hours: float = OLD_HOURS) -> Path:
        """A detached checkout under .claude/worktrees/, old and clean."""
        path = self.worktrees / name
        self.run_git("worktree", "add", "-q", "--detach", str(path), "HEAD", cwd=self.repo)
        self.age(path, hours)
        return path

    def sweep(self, *args: str, cwd: Path | None = None, **env: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(self.tool), "--project-dir", str(self.projects), *args],
            cwd=cwd or self.repo,
            env={**self.env, **env},
            capture_output=True,
            text=True,
            check=False,
            timeout=120,
        )

    def registered(self) -> str:
        return self.run_git("worktree", "list", "--porcelain", cwd=self.repo)

    def line(self, result: subprocess.CompletedProcess[str], start: str) -> str:
        found = [line for line in result.stdout.splitlines() if line.startswith(start)]
        self.assertEqual(len(found), 1, f"one line starting {start!r} in:\n{result.stdout}{result.stderr}")
        return found[0]

    # ------------------------------------------------------------------------------- briefs ---
    def test_listing_marks_a_finished_brief_and_removes_nothing(self) -> None:
        brief = self.brief("feature/done")
        refs = self.run_git("show-ref", cwd=self.repo)
        result = self.sweep()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("PR #1 merged", self.line(result, "sweep brief feature-done.md:"))
        self.assertIn("briefs: 1 to sweep, 0 kept", result.stdout)
        self.assertIn("Nothing was removed", result.stdout)
        self.assertTrue(brief.exists())
        self.assertEqual(self.run_git("show-ref", cwd=self.repo), refs)

    def test_apply_removes_a_finished_brief_released_or_not(self) -> None:
        released = self.brief("feature/done")
        unreleased = self.brief("fix-old", released=False)
        listing = self.sweep()
        self.assertTrue(self.line(listing, "sweep brief feature-done.md:").endswith(", released"))
        self.assertTrue(self.line(listing, "sweep brief fix-old.md:").endswith(", never released"))
        result = self.sweep("--apply")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.line(result, "removed brief feature-done.md:")
        self.line(result, "removed brief fix-old.md:")
        self.assertIn("briefs: 2 removed, 0 kept", result.stdout)
        self.assertFalse(released.exists())
        self.assertFalse(unreleased.exists())

    def test_a_brief_stays_while_its_branch_is_anywhere(self) -> None:
        self.run_git("branch", "feature/local", cwd=self.repo)
        self.run_git("push", "-q", "origin", "main:refs/heads/feature/remote", cwd=self.repo)
        still_there = self.root / "still-there"
        still_there.mkdir()
        kept = {
            self.brief("feature/local"): "the branch feature/local exists locally",
            self.brief("feature/remote"): "origin has the branch feature/remote",
            self.brief("feature/tree", worktree=str(still_there)): f"its worktree is still there: {still_there}",
            self.brief("feature/reopened"): "PR #5 of feature/reopened is open",
        }
        self.pr("feature/reopened", "OPEN")
        result = self.sweep("--apply")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        for brief, reason in kept.items():
            self.assertEqual(self.line(result, f"keep brief {brief.name}:"), f"keep brief {brief.name}: {reason}")
            self.assertTrue(brief.exists(), brief.name)
        self.assertIn("briefs: 0 removed, 4 kept", result.stdout)

    def test_a_brief_stays_without_a_merged_pull_request(self) -> None:
        none = self.brief("feature/dropped", merged=False)
        closed = self.brief("feature/closed", merged=False)
        fork = self.brief("feature/forked", merged=False)
        self.pr("feature/closed", "CLOSED")
        self.pr("feature/forked", "MERGED", fork=True)
        result = self.sweep("--apply")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        for brief in (none, closed, fork):
            self.assertIn("may be the only record of its task", self.line(result, f"keep brief {brief.name}:"))
            self.assertTrue(brief.exists(), brief.name)

    def test_a_brief_stays_while_it_or_its_agent_was_written_recently(self) -> None:
        fresh = self.brief("feature/fresh", hours=1)
        running = self.brief("feature/running", agents=("a-old", "a-live"))
        finished = self.brief("feature/finished", agents=("a-old", "a-unknown"))
        self.transcript("a-old", OLD_HOURS)
        self.transcript("a-live", 1)
        result = self.sweep("--apply")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("written in the last 24 hours", self.line(result, f"keep brief {fresh.name}:"))
        self.assertIn("its agent a-live wrote its transcript", self.line(result, f"keep brief {running.name}:"))
        self.line(result, f"removed brief {finished.name}:")
        self.assertTrue(fresh.exists())
        self.assertTrue(running.exists())
        self.assertFalse(finished.exists())

    def test_files_of_another_kind_are_counted_and_never_removed(self) -> None:
        # Named like a branch's brief, but its "branch:" line is below the header's end.
        draft = self.briefs / "feature-idea.md"
        draft.write_text("# A draft\n\nbranch: feature/idea\ncleanup: ready\n")
        # A review brief names the branch it reviews; the branch's own brief has another name.
        review = self.brief("feature/reviewed", name="review-7.md")
        notes = self.briefs / "owned.txt"
        notes.write_text("branch: feature/reviewed\n\n")
        folder = self.briefs / "shared"
        folder.mkdir()
        inner = folder / "feature-reviewed.md"
        inner.write_text("branch: feature/reviewed\ncleanup: ready\n\n")
        target = self.root / "elsewhere.md"
        target.write_text("branch: feature/linked\ncleanup: ready\n\n")
        link = self.briefs / "feature-linked.md"
        link.symlink_to(target)
        self.pr("feature/idea")
        self.pr("feature/linked")
        for path in (draft, notes, inner, target):
            self.age(path)
        result = self.sweep("--apply")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("briefs: 0 removed, 5 kept (5 not a branch brief (not listed))", result.stdout)
        self.assertEqual([line for line in result.stdout.splitlines() if " brief " in line.split(":")[0]], [])
        for path in (draft, review, notes, inner, target):
            self.assertTrue(path.exists(), path.name)
        self.assertTrue(link.is_symlink())

    def test_a_failed_read_ends_the_run_with_nothing_removed(self) -> None:
        brief = self.brief("feature/done")
        checkout = self.checkout("review-old")
        no_gh = self.sweep("--apply", FIXTURE_GH_FAIL="1")
        self.assertEqual(no_gh.returncode, 1, no_gh.stdout + no_gh.stderr)
        self.assertIn("gh pr list failed", no_gh.stderr)
        self.prs_file.write_text("not json")
        no_json = self.sweep("--apply")
        self.assertEqual(no_json.returncode, 1, no_json.stdout + no_json.stderr)
        self.write_prs()
        self.run_git("remote", "set-url", "origin", str(self.root / "no-such-origin.git"), cwd=self.repo)
        no_origin = self.sweep("--apply")
        self.assertEqual(no_origin.returncode, 1, no_origin.stdout + no_origin.stderr)
        self.assertIn("ls-remote", no_origin.stderr)
        for result in (no_gh, no_json, no_origin):
            self.assertIn("nothing was removed", result.stderr)
            self.assertEqual(result.stdout, "")
        self.assertTrue(brief.exists())
        self.assertTrue(checkout.exists())

    def test_a_pull_request_list_that_may_be_cut_off_is_refused(self) -> None:
        self.pr("feature/one")
        self.pr("feature/two")
        tool = self.load()
        with unittest.mock.patch.dict(os.environ, self.env), unittest.mock.patch.object(tool, "PR_LIMIT", 3):
            self.assertEqual(tool.read_remote(self.repo).merged_prs, {"feature/one": 1, "feature/two": 2})
        with (
            unittest.mock.patch.dict(os.environ, self.env),
            unittest.mock.patch.object(tool, "PR_LIMIT", 2),
            self.assertRaisesRegex(tool.SweepError, "did not return every pull request"),
        ):
            tool.read_remote(self.repo)

    def test_github_is_read_and_never_written(self) -> None:
        self.brief("feature/done")
        self.checkout("review-old")
        before = self.run_git("show-ref", cwd=self.origin)
        self.assertEqual(self.sweep().returncode, 0)
        self.assertEqual(self.sweep("--apply").returncode, 0)
        calls = self.gh_calls.read_text().splitlines()
        self.assertEqual(len(calls), 2)
        self.assertTrue(all(call.startswith("pr list ") for call in calls), calls)
        self.assertEqual(self.run_git("show-ref", cwd=self.origin), before)

    # ---------------------------------------------------------------------------- checkouts ---
    def test_a_quiet_clean_checkout_is_listed_then_removed_caches_and_all(self) -> None:
        checkout = self.checkout("review-old")
        (checkout / ".godot").mkdir()
        (checkout / ".godot" / "cache.bin").write_text("regenerable\n")
        self.age(checkout)
        listing = self.sweep()
        self.assertEqual(listing.returncode, 0, listing.stdout + listing.stderr)
        self.assertIn("unchanged for 3 day(s)", self.line(listing, "sweep checkout review-old:"))
        self.assertIn("checkouts: 1 to sweep, 0 kept", listing.stdout)
        self.assertTrue(checkout.exists())
        self.assertIn(str(checkout), self.registered())
        result = self.sweep("--apply")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.line(result, "removed checkout review-old:")
        self.assertIn("checkouts: 1 removed, 0 kept", result.stdout)
        self.assertFalse(checkout.exists())
        self.assertNotIn(str(checkout), self.registered())

    def test_a_checkout_with_a_commit_of_its_own_is_listed_with_it_and_never_removed(self) -> None:
        checkout = self.checkout("committed-in")
        (checkout / "tracked").write_text("made here\n")
        self.run_git("commit", "-qam", "work made on the detached head", cwd=checkout)
        made = self.run_git("rev-parse", "HEAD", cwd=checkout).strip()
        # Stepping HEAD back off the commit leaves the HEAD log as the one thing that names it.
        self.run_git("checkout", "-q", "--detach", "HEAD~1", cwd=checkout)
        self.age(checkout)
        for args in ((), ("--apply",)):
            result = self.sweep(*args)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn("it holds 1 commit no ref reaches", self.line(result, "keep checkout committed-in:"))
            self.assertIn(f"    {made} work made on the detached head", result.stdout)
            self.assertIn("branch <name> <commit>", result.stdout)
            self.assertTrue(checkout.exists())
        # A branch at the commit keeps it, and the checkout then holds nothing of its own.
        self.run_git("branch", "kept", made, cwd=self.repo)
        result = self.sweep("--apply")
        self.line(result, "removed checkout committed-in:")
        self.assertFalse(checkout.exists())
        self.assertEqual(self.run_git("rev-parse", "kept", cwd=self.repo).strip(), made)

    def test_a_checkout_made_at_a_commit_no_ref_reaches_still_goes(self) -> None:
        self.run_git("checkout", "-q", "-b", "feature/squashed", cwd=self.repo)
        (self.repo / "tracked").write_text("reviewed\n")
        self.run_git("commit", "-qam", "reviewed work", cwd=self.repo)
        checkout = self.checkout("review-squashed")
        self.run_git("checkout", "-q", "main", cwd=self.repo)
        self.run_git("branch", "-qD", "feature/squashed", cwd=self.repo)
        result = self.sweep("--apply")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.line(result, "removed checkout review-squashed:")
        self.assertFalse(checkout.exists())

    def test_a_checkout_in_use_or_holding_work_stays(self) -> None:
        changed = self.checkout("changed")
        (changed / "tracked").write_text("unfinished\n")
        untracked = self.checkout("untracked")
        (untracked / "new").write_text("unfinished\n")
        capture = self.checkout("capture")
        (capture / "build").mkdir()
        (capture / "build" / "capture.png").write_text("evidence\n")
        locked = self.checkout("locked")
        self.run_git("worktree", "lock", str(locked), cwd=self.repo)
        merging = self.checkout("merging")
        merge_head = Path(self.run_git("rev-parse", "--absolute-git-dir", cwd=merging).strip()) / "MERGE_HEAD"
        merge_head.write_text(self.run_git("rev-parse", "HEAD", cwd=merging))
        for path in (changed, untracked, capture, locked, merging):
            self.age(path)
        fresh = self.checkout("fresh", hours=1)
        kept = {
            changed: "1 changed or untracked file(s)",
            untracked: "1 changed or untracked file(s)",
            capture: "1 ignored file(s) that are no regenerable cache",
            locked: "it is locked",
            merging: "an operation is under way in it (MERGE_HEAD)",
            fresh: "something in it changed in the last 24 hours",
        }
        before = self.registered()
        result = self.sweep("--apply")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        for path, reason in kept.items():
            self.assertEqual(self.line(result, f"keep checkout {path.name}:"), f"keep checkout {path.name}: {reason}")
            self.assertTrue(path.exists(), path.name)
        self.assertIn("    build/capture.png", result.stdout)
        self.assertIn("checkouts: 0 removed, 6 kept", result.stdout)
        self.assertEqual(self.registered(), before)
        self.assertEqual((changed / "tracked").read_text(), "unfinished\n")

    def test_the_callers_own_checkout_stays(self) -> None:
        checkout = self.checkout("mine")
        (checkout / "sub").mkdir()
        self.age(checkout)
        result = self.sweep("--apply", cwd=checkout / "sub")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(self.line(result, "keep checkout mine:"), "keep checkout mine: the caller is inside it")
        self.assertTrue(checkout.exists())

    def test_a_worktree_with_a_branch_or_outside_the_folder_is_not_the_sweeps(self) -> None:
        branch_tree = self.worktrees / "agent"
        self.run_git("worktree", "add", "-q", "-b", "feature/agent", str(branch_tree), cwd=self.repo)
        outside = self.root / "outside"
        self.run_git("worktree", "add", "-q", "--detach", str(outside), "HEAD", cwd=self.repo)
        self.age(branch_tree)
        self.age(outside)
        result = self.sweep("--apply")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("checkouts: 0 removed, 0 kept", result.stdout)
        self.assertEqual([line for line in result.stdout.splitlines() if " checkout " in line.split(":")[0]], [])
        self.assertTrue(branch_tree.exists())
        self.assertTrue(outside.exists())
        self.assertIn("feature/agent", self.run_git("branch", "--list", cwd=self.repo))

    def test_the_removers_refusal_keeps_the_checkout_and_fails_the_run(self) -> None:
        checkout = self.checkout("review-old")
        brief = self.brief("feature/done")
        remover = self.repo / "tools" / "agent-setup.sh"
        remover.write_text('#!/bin/sh\necho "refused: $*" >&2\nexit 1\n')
        result = self.sweep("--apply")
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.line(result, "keep checkout review-old: tools/agent-setup.sh --remove refused it:")
        self.assertIn("    refused: --remove review-old", result.stdout)
        self.assertIn("checkouts: 0 removed, 1 marked sweep and not removed, 0 kept", result.stdout)
        self.assertTrue(checkout.exists())
        # The run goes on past a refusal: the brief it listed is still removed.
        self.assertFalse(brief.exists())

    # ------------------------------------------------------------- between listing and removal ---
    def load(self) -> ModuleType:
        """The scratch copy as a module, so a test can change the checkout between its two steps."""
        spec = importlib.util.spec_from_file_location("sweep_scratch", self.tool)
        assert spec is not None and spec.loader is not None
        module = importlib.util.module_from_spec(spec)
        sys.modules["sweep_scratch"] = module
        self.addCleanup(sys.modules.pop, "sweep_scratch", None)
        spec.loader.exec_module(module)
        return module

    def test_what_changed_after_the_listing_is_kept(self) -> None:
        brief = self.brief("feature/done")
        checkout = self.checkout("review-old")
        tool = self.load()
        remote = tool.Remote(branches=frozenset(), open_prs={}, merged_prs={"feature/done": 1})
        verdicts = tool.inventory(tool.read_local(), remote, {}, time.time())
        self.assertEqual(
            [(verdict.name, verdict.sweep) for verdict in verdicts], [(brief.name, True), ("review-old", True)]
        )
        # The branch comes back and a file is written in the checkout before the removals run.
        self.run_git("branch", "feature/done", cwd=self.repo)
        (checkout / "notes").write_text("work in progress\n")
        for verdict, reason in zip(
            verdicts, ("the branch feature/done exists locally", "1 changed or untracked"), strict=True
        ):
            went, lines = tool.remove(verdict, remote, {})
            self.assertFalse(went)
            self.assertIn("changed since it was listed", lines[0])
            self.assertIn(reason, lines[0])
        self.assertTrue(brief.exists())
        self.assertTrue(checkout.exists())


if __name__ == "__main__":
    unittest.main()
