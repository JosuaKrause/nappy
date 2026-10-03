"""Retirement safety against local repositories; gh is a deterministic fixture."""

import hashlib
import os
import shutil
import subprocess
import tarfile
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "tools/prune-merged.sh"


class RetirementTests(unittest.TestCase):
    def setUp(self) -> None:
        self.scratch = tempfile.TemporaryDirectory(prefix="prune-test-")
        self.addCleanup(self.scratch.cleanup)
        self.root = Path(self.scratch.name).resolve()
        self.repo = self.root / "main"
        self.remote = self.root / "origin.git"
        self.tree = self.root / "owned tree"
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.git = shutil.which("git") or "git"
        self.env = dict(os.environ)
        self.env.pop("NAPPY_AGENT_ROLE", None)
        self.env.update(GIT_CONFIG_NOSYSTEM="1", GIT_CONFIG_GLOBAL=os.devnull)
        self.run_git("init", "--bare", str(self.remote))
        self.run_git("init", "-b", "main", str(self.repo))
        self.run_git("config", "user.name", "Fixture", cwd=self.repo)
        self.run_git("config", "user.email", "fixture@example.invalid", cwd=self.repo)
        (self.repo / "tracked").write_text("base\n")
        (self.repo / ".gitignore").write_text(".claude/\n")
        self.run_git("add", ".", cwd=self.repo)
        self.run_git("commit", "-qm", "base", cwd=self.repo)
        self.base = self.run_git("rev-parse", "HEAD", cwd=self.repo).strip()
        self.run_git("remote", "add", "origin", str(self.remote), cwd=self.repo)
        self.run_git("worktree", "add", "-b", "feature/probe", str(self.tree), cwd=self.repo)
        (self.tree / "tracked").write_text("merged\n")
        self.run_git("commit", "-qam", "merged", cwd=self.tree)
        self.head = self.run_git("rev-parse", "HEAD", cwd=self.tree).strip()
        self.run_git("push", "-q", "origin", "feature/probe", cwd=self.repo)
        self.env.update(PATH=f"{self.bin}:{self.env['PATH']}", FIXTURE_HEAD=self.head, FIXTURE_OPEN="0")
        self.write_executable(
            "gh",
            '#!/bin/sh\nif [ "$2" = list ]; then echo "$FIXTURE_OPEN"; '
            'else echo "${FIXTURE_STATE:-MERGED} $FIXTURE_HEAD 123"; fi\n',
        )

    def write_executable(self, name: str, content: str) -> None:
        path = self.bin / name
        path.write_text(content)
        path.chmod(0o755)

    def run_git(self, *args: str, cwd: Path | None = None) -> str:
        return subprocess.check_output(
            [self.git, *args], cwd=cwd or self.root, env=self.env, text=True, stderr=subprocess.DEVNULL
        )

    def prune(self, *args: str, cwd: Path | None = None) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [str(SCRIPT), *args], cwd=cwd or self.repo, env=self.env, capture_output=True, text=True, check=False
        )

    def kept(self, result: subprocess.CompletedProcess[str], reason: str) -> None:
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn(reason, result.stdout + result.stderr)
        self.assertTrue(self.tree.exists())
        self.assertEqual(self.run_git("rev-parse", "feature/probe", cwd=self.repo).strip(), self.head)
        self.assertEqual(self.run_git("rev-parse", "feature/probe", cwd=self.remote).strip(), self.head)

    def test_exact_head_and_stale_ancestor_are_retired(self) -> None:
        self.run_git("reset", "--hard", self.base, cwd=self.tree)
        result = self.prune("feature/probe")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertFalse(self.tree.exists())
        self.assertEqual(self.run_git("branch", "--list", "feature/probe", cwd=self.repo), "")
        self.assertEqual(self.run_git("branch", "--list", "feature/probe", cwd=self.remote), "")

    def test_exact_head_is_retired(self) -> None:
        result = self.prune("feature/probe")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertFalse(self.tree.exists())

    def test_inventory_is_read_only_including_harness_refs(self) -> None:
        self.run_git("branch", "worktree-agent-old", cwd=self.repo)
        before = self.run_git("show-ref", cwd=self.repo)
        before_trees = self.run_git("worktree", "list", "--porcelain", cwd=self.repo)
        for args in [("--all",), ("--dry-run", "feature/probe")]:
            result = self.prune(*args)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn("KiB", result.stdout)
            self.assertEqual(self.run_git("show-ref", cwd=self.repo), before)
            self.assertEqual(self.run_git("worktree", "list", "--porcelain", cwd=self.repo), before_trees)
            self.assertTrue(self.tree.exists())

    def test_apply_inventory_removes_only_eligible(self) -> None:
        result = self.prune("--all", "--apply")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertFalse(self.tree.exists())
        self.assertTrue(self.repo.exists())

    def test_dirty_untracked_locked_and_active_work_stays(self) -> None:
        (self.tree / "tracked").write_text("unfinished\n")
        self.kept(self.prune("feature/probe"), "dirty or untracked")
        self.run_git("restore", "tracked", cwd=self.tree)
        (self.tree / "new").write_text("unfinished\n")
        self.kept(self.prune("feature/probe"), "dirty or untracked")
        (self.tree / "new").unlink()
        self.run_git("worktree", "lock", str(self.tree), cwd=self.repo)
        self.kept(self.prune("feature/probe"), "locked")
        self.assertIn("locked", self.run_git("worktree", "list", "--porcelain", cwd=self.repo))
        self.run_git("worktree", "unlock", str(self.tree), cwd=self.repo)
        brief = self.repo / ".claude/briefs/feature-probe.md"
        brief.parent.mkdir(parents=True)
        brief.write_text("agent: live\n\nTask\n")
        self.kept(self.prune("feature/probe"), "ownership")
        brief.write_text("agent: finished\ncleanup: ready\n\nTask\n")
        self.assertEqual(self.prune("feature/probe").returncode, 0)

    def test_open_and_reused_branch_stay(self) -> None:
        self.env["FIXTURE_STATE"] = "OPEN"
        self.kept(self.prune("feature/probe"), "not MERGED")
        self.env["FIXTURE_STATE"] = "MERGED"
        self.env["FIXTURE_OPEN"] = "1"
        self.kept(self.prune("feature/probe"), "open PR")

    def test_unpushed_work_stays(self) -> None:
        self.run_git("commit", "--allow-empty", "-qm", "unpushed", cwd=self.tree)
        local = self.run_git("rev-parse", "HEAD", cwd=self.tree)
        result = self.prune("feature/probe")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("not included", result.stdout)
        self.assertEqual(self.run_git("rev-parse", "HEAD", cwd=self.tree), local)

    def test_advanced_remote_stays_before_any_local_deletion(self) -> None:
        self.run_git("update-ref", "refs/heads/feature/probe", self.base, cwd=self.remote)
        result = self.prune("feature/probe")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("remote tip", result.stdout)
        self.assertTrue(self.tree.exists())
        self.assertEqual(self.run_git("rev-parse", "HEAD", cwd=self.tree).strip(), self.head)

    def test_missing_merged_object_stays(self) -> None:
        self.env["FIXTURE_HEAD"] = "f" * 40
        self.kept(self.prune("feature/probe"), "unavailable locally")

    def test_remote_change_during_delete_is_refused_by_lease(self) -> None:
        self.env.update(REAL_GIT=self.git, FIXTURE_REMOTE=str(self.remote), FIXTURE_BASE=self.base)
        self.write_executable(
            "git",
            '#!/bin/sh\nif [ "$1" = push ]; then\n'
            '  "$REAL_GIT" -C "$FIXTURE_REMOTE" update-ref refs/heads/feature/probe "$FIXTURE_BASE"\n'
            'fi\nexec "$REAL_GIT" "$@"\n',
        )
        result = self.prune("feature/probe")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("remote delete failed", result.stderr)
        self.assertTrue(self.tree.exists())
        self.assertEqual(self.run_git("rev-parse", "feature/probe", cwd=self.repo).strip(), self.head)
        self.assertEqual(self.run_git("rev-parse", "feature/probe", cwd=self.remote).strip(), self.base)

    def test_worktree_changes_before_mutation_are_rechecked(self) -> None:
        self.env.update(FIXTURE_MARKER=str(self.root / "seen"), FIXTURE_TREE=str(self.tree))
        self.write_executable(
            "gh",
            '#!/bin/sh\nif [ "$2" = list ]; then echo 0; exit; fi\n'
            'if [ -f "$FIXTURE_MARKER" ]; then echo valuable > "$FIXTURE_TREE/new"; fi\n'
            'touch "$FIXTURE_MARKER"\necho "MERGED $FIXTURE_HEAD 123"\n',
        )
        self.kept(self.prune("feature/probe"), "state changed")

    def test_main_checkout_and_caller_are_protected(self) -> None:
        self.kept(self.prune("feature/probe", cwd=self.tree), "caller")
        self.run_git("switch", "--detach", cwd=self.tree)
        self.run_git("switch", "feature/probe", cwd=self.repo)
        self.kept(self.prune("feature/probe"), "main checkout")

    def test_arguments_fail_before_network_or_mutation(self) -> None:
        self.write_executable("gh", '#!/bin/sh\necho unwanted > "$FIXTURE_SENTINEL"\nexit 1\n')
        sentinel = self.root / "called"
        self.env["FIXTURE_SENTINEL"] = str(sentinel)
        for args in [
            ("--all", "--apply", "--bogus"),
            ("--all", "feature/probe"),
            ("--apply",),
            ("--all", "--apply", "--dry-run"),
            ("--help", "--bogus"),
        ]:
            self.assertNotEqual(self.prune(*args).returncode, 0)
        self.assertFalse(sentinel.exists())
        self.assertTrue(self.tree.exists())


class BuildScratchTests(unittest.TestCase):
    def setUp(self) -> None:
        self.scratch = tempfile.TemporaryDirectory(prefix="build-cleanup-test-")
        self.addCleanup(self.scratch.cleanup)
        self.root = Path(self.scratch.name)
        self.repo = self.root / "repo"
        config = self.repo / "tools/web-template"
        config.mkdir(parents=True)
        self.script = self.repo / "tools/build-web-template.sh"
        shutil.copy2(ROOT / "tools/build-web-template.sh", self.script)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.env = dict(os.environ, PATH=f"{self.bin}:{os.environ['PATH']}")
        hashes = {}
        for name in ("godot", "emsdk"):
            source = self.root / name
            source.mkdir()
            if name == "emsdk":
                installer = source / "emsdk"
                installer.write_text("#!/bin/sh\nexit 0\n")
                installer.chmod(0o755)
                (source / "emsdk_env.sh").write_text("# fixture\n")
            archive = self.root / f"{name}.tar.gz"
            with tarfile.open(archive, "w:gz") as package:
                package.add(source, arcname=name)
            hashes[name] = hashlib.sha256(archive.read_bytes()).hexdigest()
            self.env[f"FIXTURE_{name.upper()}_ARCHIVE"] = str(archive)
        (config / "pins.env").write_text(
            f"GODOT_REVISION=fixture\nGODOT_SHA256={hashes['godot']}\n"
            f"EMSDK_REVISION=fixture\nEMSDK_SHA256={hashes['emsdk']}\nEMSDK_VERSION=fixture\nSCONS_VERSION=fixture\n"
        )
        (config / "profile.args").write_text("# fixture\n")
        self.executable("emcc", "#!/bin/sh\nexit 0\n")
        self.executable(
            "curl",
            '#!/bin/sh\narchive="$FIXTURE_EMSDK_ARCHIVE"\n'
            'for arg in "$@"; do case "$arg" in *godotengine*) archive="$FIXTURE_GODOT_ARCHIVE";; esac; done\n'
            'while [ "$1" != -o ]; do shift; done\ncp "$archive" "$2"\n',
        )
        self.executable(
            "uv",
            '#!/bin/sh\n[ "${FIXTURE_BUILD_FAIL:-0}" = 0 ] || exit 17\n'
            "mkdir -p bin\necho template > bin/godot.web.template_release.wasm32.nothreads.zip\n",
        )

    def executable(self, name: str, content: str) -> None:
        file = self.bin / name
        file.write_text(content)
        file.chmod(0o755)

    def build(self, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run([str(self.script), *args], env=self.env, capture_output=True, text=True, check=False)

    def test_success_keeps_template_and_removes_owned_scratch(self) -> None:
        result = self.build()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue((self.repo / "build/web-template/template.zip").is_file())
        self.assertEqual(list((self.repo / "build/web-template-work").iterdir()), [])
        self.assertFalse((self.repo / "build/web-template/.build-lock").exists())
        self.assertEqual(self.build("--verify").returncode, 0)

    def test_failure_retains_diagnostics_and_releases_own_lock(self) -> None:
        self.env["FIXTURE_BUILD_FAIL"] = "1"
        result = self.build()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("scratch retained", result.stderr)
        self.assertTrue(list((self.repo / "build/web-template-work").iterdir()))
        self.assertFalse((self.repo / "build/web-template/.build-lock").exists())

    def test_existing_lock_is_not_removed(self) -> None:
        lock = self.repo / "build/web-template/.build-lock"
        lock.mkdir(parents=True)
        (lock / "pid").write_text("another owner\n")
        result = self.build()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("already owned", result.stderr)
        self.assertEqual((lock / "pid").read_text(), "another owner\n")
        self.assertFalse((self.repo / "build/web-template-work").exists())


if __name__ == "__main__":
    unittest.main()
