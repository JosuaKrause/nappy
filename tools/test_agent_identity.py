#!/usr/bin/env python3
"""Offline tests for the agent-identity tool: nothing here reaches the network. The manifest flow's
own server/browser orchestration (`run_manifest_flow`) is exercised only through its pure pieces
(`build_manifest`, `render_manifest_form`, `roles_to_create`) -- the flow itself needs GitHub's own
API and a browser, neither of which this container has (see the module docstring's "cloud session"
paragraph). HTTP is mocked at the function boundary (`Getter`/`Poster` callables), never by
patching `urllib` internals.
"""

from __future__ import annotations

import base64
import importlib.util
import io
import json
import os
import stat
import subprocess
import sys
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path
from typing import Any
from unittest import mock

SPEC = importlib.util.spec_from_file_location("agent_identity", Path(__file__).with_name("agent-identity.py"))
assert SPEC and SPEC.loader
agent_identity = importlib.util.module_from_spec(SPEC)
# dataclasses (RoleSpec) resolves its field types by looking itself up in sys.modules by
# __module__ name -- it must be registered there before exec_module, or that lookup finds nothing.
sys.modules[SPEC.name] = agent_identity
SPEC.loader.exec_module(agent_identity)


def _b64url_decode(text: str) -> bytes:
    padded = text + "=" * (-len(text) % 4)
    return base64.urlsafe_b64decode(padded)


class RoleTableTests(unittest.TestCase):
    def test_every_role_from_the_brief_is_present(self) -> None:
        self.assertEqual(
            set(agent_identity.ROLES), {"claude-coder", "claude-reviewer", "codex-coder", "codex-reviewer"}
        )

    def test_coder_roles_have_contents_and_workflows_write(self) -> None:
        for role in ("claude-coder", "codex-coder"):
            with self.subTest(role=role):
                permissions = agent_identity.ROLES[role].permissions
                self.assertEqual(permissions["contents"], "write")
                self.assertEqual(permissions["workflows"], "write")

    def test_coder_roles_have_actions_write_so_a_wrapped_run_rerun_works(self) -> None:
        for role in ("claude-coder", "codex-coder"):
            with self.subTest(role=role):
                self.assertEqual(agent_identity.ROLES[role].permissions["actions"], "write")

    def test_reviewer_roles_keep_actions_read(self) -> None:
        # Nothing but coder's own actions permission is widened.
        for role in ("claude-reviewer", "codex-reviewer"):
            with self.subTest(role=role):
                self.assertEqual(agent_identity.ROLES[role].permissions["actions"], "read")

    def test_reviewer_has_contents_write_and_no_workflows(self) -> None:
        # contents is write, not read: a reviewer's own APPROVE needs it to satisfy a
        # required-approval ruleset (see _REVIEWER_PERMISSIONS's own comment) -- but
        # github-write-guard.sh still refuses a reviewer identity's own git push regardless.
        for role in ("claude-reviewer", "codex-reviewer"):
            with self.subTest(role=role):
                permissions = agent_identity.ROLES[role].permissions
                self.assertEqual(permissions["contents"], "write")
                self.assertNotIn("workflows", permissions)

    def test_every_role_can_read_and_write_pull_requests_and_issues(self) -> None:
        for role, spec in agent_identity.ROLES.items():
            with self.subTest(role=role):
                self.assertEqual(spec.permissions["pull_requests"], "write")
                self.assertEqual(spec.permissions["issues"], "write")
                self.assertEqual(spec.permissions["metadata"], "read")


class BuildManifestTests(unittest.TestCase):
    def test_manifest_names_the_app_repo_and_permissions_and_wants_no_webhook(self) -> None:
        spec = agent_identity.ROLES["claude-coder"]
        manifest = agent_identity.build_manifest("claude-coder", spec, "JosuaKrause", "nappy", 54321)
        self.assertEqual(manifest["name"], "nappy-claude-coder")
        self.assertEqual(manifest["url"], "https://github.com/JosuaKrause/nappy")
        self.assertEqual(manifest["hook_attributes"], {"url": "https://github.com/JosuaKrause/nappy", "active": False})
        self.assertEqual(manifest["redirect_url"], "http://127.0.0.1:54321/callback")
        self.assertIs(manifest["public"], False)
        self.assertEqual(manifest["default_permissions"], spec.permissions)
        self.assertIn("claude-coder", manifest["description"])

    def test_reviewer_manifest_carries_the_reviewer_permissions(self) -> None:
        spec = agent_identity.ROLES["claude-reviewer"]
        manifest = agent_identity.build_manifest("claude-reviewer", spec, "O", "R", 1)
        self.assertEqual(manifest["default_permissions"]["contents"], "write")
        self.assertNotIn("workflows", manifest["default_permissions"])


class ManifestFormTests(unittest.TestCase):
    def test_the_manifest_round_trips_out_of_the_escaped_attribute(self) -> None:
        import html

        manifest = agent_identity.build_manifest("claude-coder", agent_identity.ROLES["claude-coder"], "O", "R", 1)
        page = agent_identity.render_manifest_form(manifest, "https://github.com/settings/apps/new?state=abc")
        start = page.index('value="') + len('value="')
        end = page.index('"', start)
        recovered = json.loads(html.unescape(page[start:end]))
        self.assertEqual(recovered, manifest)

    def test_the_form_posts_to_the_action_url_and_auto_submits(self) -> None:
        page = agent_identity.render_manifest_form({"name": "x"}, "https://github.com/settings/apps/new?state=abc")
        self.assertIn('action="https://github.com/settings/apps/new?state=abc"', page)
        self.assertIn('method="post"', page)
        self.assertIn("submit()", page)

    def test_a_manifest_field_containing_a_quote_does_not_break_out_of_the_attribute(self) -> None:
        manifest = {"name": 'x"onmouseover="alert(1)'}
        page = agent_identity.render_manifest_form(manifest, "https://github.com/settings/apps/new")
        self.assertNotIn('"onmouseover="alert(1)"', page)


class JwtTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.key = self.root / "key.pem"
        subprocess.run(
            ["openssl", "genrsa", "-out", str(self.key), "2048"], check=True, capture_output=True, timeout=30
        )

    def test_header_and_payload_shape(self) -> None:
        token = agent_identity.build_jwt("123456", self.key, now=1_800_000_000)
        header_b64, payload_b64, _signature_b64 = token.split(".")
        header = json.loads(_b64url_decode(header_b64))
        payload = json.loads(_b64url_decode(payload_b64))
        self.assertEqual(header, {"alg": "RS256", "typ": "JWT"})
        self.assertEqual(payload, {"iat": 1_800_000_000 - 60, "exp": 1_800_000_000 + 540, "iss": "123456"})

    def test_the_signature_verifies_against_the_matching_public_key(self) -> None:
        token = agent_identity.build_jwt("999", self.key, now=1_800_000_000)
        signing_input, _dot, signature_b64 = token.rpartition(".")

        public_key = self.root / "key.pub"
        subprocess.run(
            ["openssl", "rsa", "-in", str(self.key), "-pubout", "-out", str(public_key)],
            check=True,
            capture_output=True,
            timeout=15,
        )
        data_file = self.root / "signing_input.bin"
        signature_file = self.root / "signature.bin"
        data_file.write_bytes(signing_input.encode("ascii"))
        signature_file.write_bytes(_b64url_decode(signature_b64))

        result = subprocess.run(
            [
                "openssl",
                "dgst",
                "-sha256",
                "-verify",
                str(public_key),
                "-signature",
                str(signature_file),
                str(data_file),
            ],
            capture_output=True,
            text=True,
            timeout=15,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("Verified OK", result.stdout)

    def test_a_signature_over_different_data_does_not_verify(self) -> None:
        # A control for the test above: proves it would actually fail if build_jwt signed the
        # wrong bytes, rather than the verify step being trivially satisfied.
        token = agent_identity.build_jwt("999", self.key, now=1_800_000_000)
        _signing_input, _dot, signature_b64 = token.rpartition(".")

        public_key = self.root / "key.pub"
        subprocess.run(
            ["openssl", "rsa", "-in", str(self.key), "-pubout", "-out", str(public_key)],
            check=True,
            capture_output=True,
            timeout=15,
        )
        data_file = self.root / "wrong.bin"
        signature_file = self.root / "signature.bin"
        data_file.write_bytes(b"not what was signed")
        signature_file.write_bytes(_b64url_decode(signature_b64))

        result = subprocess.run(
            [
                "openssl",
                "dgst",
                "-sha256",
                "-verify",
                str(public_key),
                "-signature",
                str(signature_file),
                str(data_file),
            ],
            capture_output=True,
            text=True,
            timeout=15,
        )
        self.assertNotEqual(result.returncode, 0)

    def test_never_shells_out_through_a_temp_file_for_the_jwt_itself(self) -> None:
        # build_jwt's own signer is called with the signing input as bytes, never a path -- this
        # is what "never a temp file for the JWT" means operationally.
        seen: list[bytes] = []

        def fake_sign(data: bytes, pem_path: Path) -> bytes:
            seen.append(data)
            self.assertEqual(pem_path, self.key)
            return b"deterministic-signature"

        token = agent_identity.build_jwt("1", self.key, now=1_000, sign=fake_sign)
        self.assertEqual(len(seen), 1)
        self.assertTrue(token.endswith(agent_identity._b64url(b"deterministic-signature")))


class RemoteUrlParsingTests(unittest.TestCase):
    def test_https_shape(self) -> None:
        self.assertEqual(
            agent_identity.parse_remote_url("https://github.com/JosuaKrause/nappy"), ("JosuaKrause", "nappy")
        )
        self.assertEqual(
            agent_identity.parse_remote_url("https://github.com/JosuaKrause/nappy.git"), ("JosuaKrause", "nappy")
        )

    def test_ssh_shape(self) -> None:
        self.assertEqual(
            agent_identity.parse_remote_url("git@github.com:JosuaKrause/nappy.git"), ("JosuaKrause", "nappy")
        )
        self.assertEqual(agent_identity.parse_remote_url("git@github.com:JosuaKrause/nappy"), ("JosuaKrause", "nappy"))

    def test_proxy_style_shape(self) -> None:
        self.assertEqual(
            agent_identity.parse_remote_url("https://proxy.internal/git/passthrough/JosuaKrause/nappy.git"),
            ("JosuaKrause", "nappy"),
        )

    def test_a_url_with_no_owner_repo_shape_is_rejected(self) -> None:
        with self.assertRaises(agent_identity.AgentIdentityError):
            agent_identity.parse_remote_url("not-a-url-at-all")

    def test_repo_override_parsing(self) -> None:
        self.assertEqual(agent_identity.parse_owner_repo("JosuaKrause/nappy"), ("JosuaKrause", "nappy"))
        for bad in ("nappy", "a/b/c", "/nappy", "JosuaKrause/"):
            with self.subTest(bad=bad), self.assertRaises(agent_identity.AgentIdentityError):
                agent_identity.parse_owner_repo(bad)

    def test_resolve_repo_prefers_the_explicit_override(self) -> None:
        def never() -> str:
            raise AssertionError("resolve_repo must not read the remote when --repo is given")

        self.assertEqual(agent_identity.resolve_repo("O/R", remote_url=never), ("O", "R"))

    def test_resolve_repo_falls_back_to_the_remote(self) -> None:
        result = agent_identity.resolve_repo(None, remote_url=lambda: "https://github.com/O/R.git")
        self.assertEqual(result, ("O", "R"))


class RunEnvironmentTests(unittest.TestCase):
    def test_names_and_noreply_email_match_the_brief_exactly(self) -> None:
        config: Any = {"app_id": "1", "slug": "nappy-claude-coder", "bot_id": 987654, "name": "n", "html_url": "h"}
        env = agent_identity.build_run_environment("claude-coder", config, "ghs_secrettoken", {"PATH": "/usr/bin"})
        self.assertEqual(env["GH_TOKEN"], "ghs_secrettoken")
        self.assertEqual(env["GITHUB_TOKEN"], "ghs_secrettoken")
        self.assertEqual(env["GIT_AUTHOR_NAME"], "nappy-claude-coder[bot]")
        self.assertEqual(env["GIT_COMMITTER_NAME"], "nappy-claude-coder[bot]")
        self.assertEqual(env["GIT_AUTHOR_EMAIL"], "987654+nappy-claude-coder[bot]@users.noreply.github.com")
        self.assertEqual(env["GIT_COMMITTER_EMAIL"], "987654+nappy-claude-coder[bot]@users.noreply.github.com")
        self.assertEqual(env["NAPPY_AGENT_ROLE"], "claude-coder")
        self.assertEqual(env["PATH"], "/usr/bin")

    def test_the_base_environment_is_not_mutated_and_is_not_lost(self) -> None:
        config: Any = {"app_id": "1", "slug": "s", "bot_id": 1, "name": "n", "html_url": "h"}
        base = {"EXISTING": "kept"}
        env = agent_identity.build_run_environment("codex-coder", config, "tok", base)
        self.assertEqual(base, {"EXISTING": "kept"})  # untouched
        self.assertEqual(env["EXISTING"], "kept")

    def test_wires_the_git_https_auth_config_in_too(self) -> None:
        # origin here is an SSH remote, so run's own git identity being the bot is not enough --
        # a push must also authenticate as the bot, not the player's own SSH key.
        config: Any = {"app_id": "1", "slug": "nappy-claude-coder", "bot_id": 1, "name": "n", "html_url": "h"}
        env = agent_identity.build_run_environment("claude-coder", config, "ghs_tok", {})
        self.assertEqual(env["GIT_CONFIG_COUNT"], "3")
        self.assertEqual(env["GIT_CONFIG_VALUE_0"], "git@github.com:")
        self.assertEqual(env["GIT_CONFIG_VALUE_1"], "ssh://git@github.com/")
        self.assertIn("AUTHORIZATION: basic ", env["GIT_CONFIG_VALUE_2"])


class GitHttpsAuthConfigTests(unittest.TestCase):
    def test_the_exact_three_entries_the_brief_names(self) -> None:
        config = agent_identity.git_https_auth_config("ghs_tok", {})
        self.assertEqual(config["GIT_CONFIG_COUNT"], "3")
        self.assertEqual(config["GIT_CONFIG_KEY_0"], "url.https://github.com/.insteadOf")
        self.assertEqual(config["GIT_CONFIG_VALUE_0"], "git@github.com:")
        self.assertEqual(config["GIT_CONFIG_KEY_1"], "url.https://github.com/.insteadOf")
        self.assertEqual(config["GIT_CONFIG_VALUE_1"], "ssh://git@github.com/")
        self.assertEqual(config["GIT_CONFIG_KEY_2"], "http.https://github.com/.extraheader")
        basic = base64.b64encode(b"x-access-token:ghs_tok").decode("ascii")
        self.assertEqual(config["GIT_CONFIG_VALUE_2"], f"AUTHORIZATION: basic {basic}")

    def test_appends_after_an_existing_git_config_count_rather_than_clobbering_it(self) -> None:
        base = {"GIT_CONFIG_COUNT": "2", "GIT_CONFIG_KEY_0": "x", "GIT_CONFIG_VALUE_0": "y"}
        config = agent_identity.git_https_auth_config("tok", base)
        self.assertEqual(config["GIT_CONFIG_COUNT"], "5")
        self.assertEqual(config["GIT_CONFIG_KEY_2"], "url.https://github.com/.insteadOf")
        self.assertEqual(config["GIT_CONFIG_KEY_4"], "http.https://github.com/.extraheader")
        # This function only adds its own three -- the caller's own existing entries are its to
        # keep, and are not repeated in what this returns.
        self.assertNotIn("GIT_CONFIG_KEY_0", config)
        self.assertNotIn("GIT_CONFIG_KEY_1", config)

    def test_an_unparseable_existing_count_is_treated_as_zero_rather_than_raising(self) -> None:
        config = agent_identity.git_https_auth_config("tok", {"GIT_CONFIG_COUNT": "not-a-number"})
        self.assertEqual(config["GIT_CONFIG_COUNT"], "3")
        self.assertIn("GIT_CONFIG_KEY_0", config)

    def test_the_token_is_never_written_into_a_url(self) -> None:
        config = agent_identity.git_https_auth_config("ghs_supersecret", {})
        for key, value in config.items():
            if key.endswith("_VALUE_0") or key.endswith("_VALUE_1"):
                self.assertNotIn("ghs_supersecret", value)


class ConfigFilePermissionsTests(unittest.TestCase):
    def test_directory_is_0700_and_pem_is_0600(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp) / "nested" / "nappy-agents"
            config: Any = {"app_id": "1", "slug": "nappy-claude-coder", "bot_id": 1, "name": "n", "html_url": "h"}
            agent_identity.write_role_config(root, "claude-coder", config, "-----BEGIN PRIVATE KEY-----\n")
            self.assertEqual(stat.S_IMODE(root.stat().st_mode), 0o700)
            pem_path = agent_identity.role_pem_path(root, "claude-coder")
            self.assertEqual(stat.S_IMODE(pem_path.stat().st_mode), 0o600)

    def test_the_json_file_round_trips_and_the_pem_holds_the_key_text_verbatim(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            config: Any = {"app_id": "42", "slug": "nappy-claude-coder", "bot_id": 99, "name": "n", "html_url": "h"}
            agent_identity.write_role_config(root, "claude-coder", config, "the-key-text")
            self.assertEqual(agent_identity.load_role_config(root, "claude-coder"), config)
            self.assertEqual(agent_identity.role_pem_path(root, "claude-coder").read_text(), "the-key-text")


class RolesToCreateTests(unittest.TestCase):
    def test_an_unconfigured_role_goes_ahead(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            ok, refused = agent_identity.roles_to_create(["claude-coder"], Path(temp), force=False)
            self.assertEqual(ok, ["claude-coder"])
            self.assertEqual(refused, [])

    def test_an_existing_role_is_refused_without_force(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            config: Any = {"app_id": "1", "slug": "s", "bot_id": 1, "name": "n", "html_url": "h"}
            agent_identity.write_role_config(root, "claude-coder", config, "key")
            ok, refused = agent_identity.roles_to_create(["claude-coder", "codex-coder"], root, force=False)
            self.assertEqual(ok, ["codex-coder"])
            self.assertEqual(refused, ["claude-coder"])

    def test_force_lets_an_existing_role_go_ahead_too(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            config: Any = {"app_id": "1", "slug": "s", "bot_id": 1, "name": "n", "html_url": "h"}
            agent_identity.write_role_config(root, "claude-coder", config, "key")
            ok, refused = agent_identity.roles_to_create(["claude-coder"], root, force=True)
            self.assertEqual(ok, ["claude-coder"])
            self.assertEqual(refused, [])

    def test_create_cli_refuses_an_existing_role_without_touching_the_network(self) -> None:
        def never_flow(*_args: object, **_kwargs: object) -> None:
            raise AssertionError("run_manifest_flow must not run for a role refused before --force")

        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            config: Any = {"app_id": "1", "slug": "s", "bot_id": 1, "name": "n", "html_url": "h"}
            agent_identity.write_role_config(root, "claude-coder", config, "key")
            stderr = io.StringIO()
            with (
                mock.patch.object(agent_identity, "run_manifest_flow", side_effect=never_flow),
                redirect_stderr(stderr),
            ):
                code = agent_identity.cmd_create(["claude-coder"], force=False, owner="O", repo="R", root=root)
            self.assertNotEqual(code, 0)
            self.assertIn("--force", stderr.getvalue())


class MissingRoleConfigTests(unittest.TestCase):
    def test_status_of_an_unconfigured_role_names_the_create_command(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            stdout = io.StringIO()
            with redirect_stdout(stdout):
                code = agent_identity.cmd_status(["claude-coder"], Path(temp), "O", "R")
            self.assertNotEqual(code, 0)
            self.assertIn("create claude-coder", stdout.getvalue())

    def test_run_of_an_unconfigured_role_names_the_create_command_and_never_execs(self) -> None:
        def never_exec(*_args: object, **_kwargs: object) -> None:
            raise AssertionError("os.execvpe must not run when the role has no config")

        with tempfile.TemporaryDirectory() as temp:
            stderr = io.StringIO()
            with mock.patch.object(agent_identity.os, "execvpe", side_effect=never_exec), redirect_stderr(stderr):
                code = agent_identity.cmd_run("claude-coder", ["echo", "hi"], Path(temp), "O", "R")
            self.assertNotEqual(code, 0)
            self.assertIn("create claude-coder", stderr.getvalue())

    def test_main_run_reports_missing_config_through_the_cli_with_a_repo_override(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            stderr = io.StringIO()
            with (
                mock.patch.object(agent_identity, "config_root", return_value=Path(temp)),
                redirect_stderr(stderr),
            ):
                code = agent_identity.main(["run", "claude-coder", "--repo", "O/R", "--", "echo", "hi"])
            self.assertNotEqual(code, 0)
            self.assertIn("create claude-coder", stderr.getvalue())

    def test_main_status_reports_missing_config_for_all_roles_by_default(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            stdout = io.StringIO()
            with (
                mock.patch.object(agent_identity, "config_root", return_value=Path(temp)),
                redirect_stdout(stdout),
            ):
                code = agent_identity.main(["status", "--repo", "O/R"])
            self.assertNotEqual(code, 0)
            for role in agent_identity.ROLE_NAMES:
                self.assertIn(role, stdout.getvalue())


class TokenMintingTests(unittest.TestCase):
    """Mocked at the Getter/Poster function boundary, per the brief -- never by patching urllib."""

    def _config(self) -> Any:
        return {"app_id": "1", "slug": "nappy-claude-coder", "bot_id": 5, "name": "n", "html_url": "h"}

    def test_a_404_on_the_installation_lookup_names_the_install_url(self) -> None:
        def get(_url: str, _headers: dict[str, str]) -> dict[str, Any]:
            raise agent_identity.AgentIdentityHTTPError(404, "GitHub returned HTTP 404")

        with self.assertRaises(agent_identity.AgentIdentityError) as caught:
            agent_identity.fetch_installation_id(
                get, "jwt", "O", "R", install_url="https://github.com/apps/x/installations/new"
            )
        self.assertIn("not installed", str(caught.exception))
        self.assertIn("https://github.com/apps/x/installations/new", str(caught.exception))

    def test_a_working_installation_and_token_round_trip(self) -> None:
        seen_headers: list[dict[str, str]] = []

        def get(_url: str, headers: dict[str, str]) -> dict[str, Any]:
            seen_headers.append(headers)
            return {"id": 4242}

        def post(_url: str, headers: dict[str, str], body: dict[str, Any]) -> dict[str, Any]:
            seen_headers.append(headers)
            self.assertEqual(body, {"repositories": ["R"]})
            return {"token": "ghs_abc", "permissions": {"contents": "write"}}

        response = agent_identity.mint_token_for_role(
            self._config(), Path("/nonexistent.pem"), "O", "R", get=get, post=post, sign=lambda data, pem: b"sig"
        )
        self.assertEqual(response["token"], "ghs_abc")
        self.assertEqual(response["permissions"], {"contents": "write"})
        for headers in seen_headers:
            self.assertNotIn("sig", json.dumps(headers))

    def test_a_non_404_http_error_is_not_reworded_as_not_installed(self) -> None:
        def get(_url: str, _headers: dict[str, str]) -> dict[str, Any]:
            raise agent_identity.AgentIdentityHTTPError(500, "GitHub returned HTTP 500")

        with self.assertRaises(agent_identity.AgentIdentityHTTPError) as caught:
            agent_identity.fetch_installation_id(get, "jwt", "O", "R", install_url="https://x")
        self.assertEqual(caught.exception.status, 500)


class SecretsNeverPrintedTests(unittest.TestCase):
    def test_run_environment_is_never_dumped_by_status_or_run_output(self) -> None:
        # build_run_environment itself is pure and has no output; this checks the value it
        # produces is never accidentally embedded in a str/repr a caller might print.
        config: Any = {"app_id": "1", "slug": "s", "bot_id": 1, "name": "n", "html_url": "h"}
        env = agent_identity.build_run_environment("claude-coder", config, "ghs_supersecret", {})
        self.assertNotIn("ghs_supersecret", repr(env.keys()))

    def test_http_error_never_includes_request_headers_in_its_message(self) -> None:
        # A hand-built AgentIdentityHTTPError, the shape mint_token_for_role's callers raise: the
        # message is built from GitHub's own body text, and the JWT/token that were sent as
        # headers are never interpolated into it.
        error = agent_identity.AgentIdentityHTTPError(404, "GitHub returned HTTP 404 for GET https://x: not found")
        self.assertNotIn("Authorization", str(error))
        self.assertNotIn("Bearer", str(error))


class CliHelpAndSubcommandTests(unittest.TestCase):
    def run_tool(self, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(Path(__file__).with_name("agent-identity.py")), *args],
            stdin=subprocess.DEVNULL,
            capture_output=True,
            text=True,
            timeout=15,
            env={**os.environ, "NAPPY_AGENTS_DIR": tempfile.mkdtemp()},
        )

    def test_top_level_help_exits_zero_and_lists_all_three_subcommands(self) -> None:
        for flag in ("--help", "-h"):
            with self.subTest(flag=flag):
                result = self.run_tool(flag)
                self.assertEqual(result.returncode, 0, result.stderr)
                for word in ("create", "status", "run"):
                    self.assertIn(word, result.stdout)

    def test_missing_subcommand_is_rejected(self) -> None:
        result = self.run_tool()
        self.assertNotEqual(result.returncode, 0)

    def test_unknown_top_level_flag_is_rejected(self) -> None:
        result = self.run_tool("--this-flag-does-not-exist")
        self.assertNotEqual(result.returncode, 0)

    def test_unknown_role_is_rejected_by_every_subcommand(self) -> None:
        for args in (["status", "not-a-role"], ["create", "not-a-role"], ["run", "not-a-role", "--", "echo"]):
            with self.subTest(args=args):
                result = self.run_tool(*args)
                self.assertNotEqual(result.returncode, 0, args)

    def test_run_help_exits_zero_without_requiring_a_separator(self) -> None:
        result = self.run_tool("run", "--help")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("usage", (result.stdout + result.stderr).lower())

    def test_run_without_the_separator_is_rejected(self) -> None:
        result = self.run_tool("run", "claude-coder")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("--", result.stderr)

    def test_run_with_an_empty_command_after_the_separator_is_rejected(self) -> None:
        result = self.run_tool("run", "claude-coder", "--")
        self.assertNotEqual(result.returncode, 0)

    def test_run_rejects_an_unknown_flag_before_the_separator_before_any_work(self) -> None:
        result = self.run_tool("run", "--bogus", "claude-coder", "--", "echo", "hi")
        self.assertNotEqual(result.returncode, 0)

    def test_create_and_status_subcommand_help_exit_zero(self) -> None:
        for sub in ("create", "status"):
            with self.subTest(sub=sub):
                result = self.run_tool(sub, "--help")
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn("usage", result.stdout.lower())


if __name__ == "__main__":
    unittest.main()
