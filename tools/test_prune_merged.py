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

    def prepare_update(self, mode: str, *, existing: bool = False) -> None:
        """Use the real updater/merges with cheap verification scripts and a local remote."""
        scripts = self.tree / "tools"
        scripts.mkdir()
        lint = scripts / "lint.sh"
        lint.write_text("#!/bin/sh\nexit 0\n")
        lint.chmod(0o755)
        check = scripts / "check.sh"
        check.write_text(
            '#!/bin/sh\ncase "$FIXTURE_UPDATE_MODE" in\n'
            "  fail-clean) exit 1;;\n"
            "  fail-dirty) echo diagnostic > unfinished; exit 1;;\n"
            "  success-dirty) echo useful > unfinished;;\n"
            '  success-locked) git worktree lock "$PWD";;\n'
            "esac\nexit 0\n"
        )
        check.chmod(0o755)
        self.run_git("add", "tools", cwd=self.tree)
        self.run_git("commit", "-qm", "verification fixtures", cwd=self.tree)
        self.run_git("push", "-q", "origin", "feature/probe", cwd=self.repo)
        tools_dir = self.repo / "tools"
        tools_dir.mkdir()
        for name in ("update-pr.sh", "lib_agent_role.sh", "lib_old_queue.sh"):
            shutil.copy2(ROOT / "tools" / name, tools_dir / name)
        (self.repo / "upstream").write_text("new main work\n")
        self.run_git("add", "upstream", cwd=self.repo)
        self.run_git("commit", "-qm", "main advance", cwd=self.repo)
        self.run_git("push", "-q", "origin", "main", cwd=self.repo)
        if not existing:
            self.run_git("worktree", "remove", str(self.tree), cwd=self.repo)
        scratch = self.root / "scratch"
        scratch.mkdir()
        self.env.update(TMPDIR=str(scratch), FIXTURE_UPDATE_MODE=mode)

    def update(self) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [str(self.repo / "tools/update-pr.sh"), "feature/probe"],
            env=self.env,
            capture_output=True,
            text=True,
            check=False,
        )

    def test_update_success_removes_its_clean_scratch(self) -> None:
        self.prepare_update("success")
        result = self.update()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(list((self.root / "scratch").glob("update-pr.*")), [])
        self.assertNotIn("update-pr.", self.run_git("worktree", "list", cwd=self.repo))
        self.assertEqual(
            self.run_git("rev-parse", "feature/probe", cwd=self.repo),
            self.run_git("rev-parse", "feature/probe", cwd=self.remote),
        )

    def test_update_failed_verification_retains_even_clean_scratch(self) -> None:
        self.prepare_update("fail-clean")
        result = self.update()
        self.assertNotEqual(result.returncode, 0)
        trees = list((self.root / "scratch").glob("update-pr.*"))
        self.assertEqual(len(trees), 1)
        self.assertIn(str(trees[0]), result.stderr)
        self.assertIn("retained after failed run", result.stderr)
        self.assertEqual(self.run_git("status", "--porcelain", cwd=trees[0]), "")

    def test_update_failed_verification_retains_untracked_diagnostics(self) -> None:
        self.prepare_update("fail-dirty")
        result = self.update()
        self.assertNotEqual(result.returncode, 0)
        trees = list((self.root / "scratch").glob("update-pr.*"))
        self.assertEqual(len(trees), 1)
        self.assertEqual((trees[0] / "unfinished").read_text(), "diagnostic\n")

    def test_update_success_keeps_untracked_work(self) -> None:
        self.prepare_update("success-dirty")
        result = self.update()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        trees = list((self.root / "scratch").glob("update-pr.*"))
        self.assertEqual(len(trees), 1)
        self.assertEqual((trees[0] / "unfinished").read_text(), "useful\n")
        self.assertIn("normal removal refused", result.stderr)

    def test_update_success_keeps_locked_worktree(self) -> None:
        self.prepare_update("success-locked")
        result = self.update()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(len(list((self.root / "scratch").glob("update-pr.*"))), 1)
        self.assertIn("locked", self.run_git("worktree", "list", "--porcelain", cwd=self.repo))

    def test_update_keeps_existing_checkout(self) -> None:
        self.prepare_update("success", existing=True)
        result = self.update()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue(self.tree.is_dir())
        self.assertEqual(list((self.root / "scratch").glob("update-pr.*")), [])

    def test_update_failed_creation_removes_only_empty_unregistered_directory(self) -> None:
        self.prepare_update("success")
        self.env["REAL_GIT"] = self.git
        self.write_executable(
            "git",
            '#!/bin/sh\nif [ "$1" = worktree ] && [ "$2" = add ]; then\n'
            '  [ "${FIXTURE_NONEMPTY:-0}" = 0 ] || echo valuable > "$4/keep"\n'
            '  exit 1\nfi\nexec "$REAL_GIT" "$@"\n',
        )
        self.assertNotEqual(self.update().returncode, 0)
        self.assertEqual(list((self.root / "scratch").glob("update-pr.*")), [])
        self.env["FIXTURE_NONEMPTY"] = "1"
        result = self.update()
        self.assertNotEqual(result.returncode, 0)
        trees = list((self.root / "scratch").glob("update-pr.*"))
        self.assertEqual(len(trees), 1)
        self.assertEqual((trees[0] / "keep").read_text(), "valuable\n")
        self.assertIn("creation failed; directory is not empty", result.stderr)


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


class SparseLintTests(unittest.TestCase):
    def setUp(self) -> None:
        self.scratch = tempfile.TemporaryDirectory(prefix="sparse-lint-test-")
        self.addCleanup(self.scratch.cleanup)
        self.root = Path(self.scratch.name)
        (self.root / "tools").mkdir()
        (self.root / "README.md").write_text("# Fixture\n")
        (self.root / "docs/todo").mkdir(parents=True)
        for tool in ("lint.sh", "queue.sh"):
            shutil.copy2(ROOT / "tools" / tool, self.root / "tools" / tool)
        (self.root / "art").mkdir()
        self.svg = self.root / "art/image.svg"
        self.svg.write_text('<svg xmlns="http://www.w3.org/2000/svg"/>\n')
        self.git("init", "-q")
        self.git("add", "art")

    def git(self, *args: str) -> None:
        subprocess.run(["git", *args], cwd=self.root, check=True, capture_output=True)

    def lint(self, *args: str, env: dict[str, str] | None = None) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [str(self.root / "tools/lint.sh"), *args], env=env, capture_output=True, text=True, check=False
        )

    def test_missing_tracked_svg_fails_instead_of_printing_ok(self) -> None:
        self.svg.unlink()
        result = self.lint()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("cannot read SVG", result.stdout)
        self.assertNotIn("\nOK\n", result.stdout)

    def test_corrupt_svg_fails_and_names_file(self) -> None:
        self.svg.write_text("<svg><broken></svg>\n")
        result = self.lint()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("art/image.svg:1: not well-formed XML", result.stdout)

    def test_sparse_omission_is_explicit_and_direct_missing_path_fails(self) -> None:
        self.git("update-index", "--skip-worktree", "art/image.svg")
        self.svg.unlink()
        result = self.lint()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("1 absent skip-worktree files omitted", result.stdout)
        self.assertNotEqual(self.lint("art/image.svg").returncode, 0)

    def test_materialized_skip_worktree_file_is_still_validated(self) -> None:
        self.git("update-index", "--skip-worktree", "art/image.svg")
        self.svg.write_text("invalid xml\n")
        self.assertNotEqual(self.lint().returncode, 0)

    def test_parser_failure_propagates_even_without_output(self) -> None:
        executable = self.root / "bin/python3"
        executable.parent.mkdir()
        executable.write_text("#!/bin/sh\nexit 42\n")
        executable.chmod(0o755)
        env = dict(os.environ, PATH=f"{executable.parent}:{os.environ['PATH']}")
        result = self.lint("art/image.svg", env=env)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("SVG validation failed", result.stderr)

    def test_discovery_failure_propagates(self) -> None:
        executable = self.root / "bin/git"
        executable.parent.mkdir()
        executable.write_text("#!/bin/sh\nexit 42\n")
        executable.chmod(0o755)
        env = dict(os.environ, PATH=f"{executable.parent}:{os.environ['PATH']}")
        result = self.lint(env=env)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("SVG validation failed", result.stderr)


if __name__ == "__main__":
    unittest.main()
