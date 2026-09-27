#!/usr/bin/env python3
"""Offline tests for the agent-identity tool: nothing here reaches GitHub. The manifest flow
(`run_manifest_flow`) runs its real local server, visited by a fake browser on 127.0.0.1, with its
two GitHub calls (`exchange_manifest_code`, `fetch_bot_id`) mocked. Other HTTP is mocked at the
function boundary (`Getter`/`Poster` callables), or, where a test has to run the production
`status`/`run` paths whole, by replacing `_opener()`'s return value -- never by patching `urllib`
internals.
"""

from __future__ import annotations

import base64
import email.message
import importlib.util
import io
import json
import os
import re
import stat
import subprocess
import sys
import tempfile
import threading
import time
import unittest
import urllib.error
import urllib.request
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path
from typing import Any, ClassVar
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
        self.assertEqual(env["GIT_CONFIG_COUNT"], "4")
        self.assertEqual(env["GIT_CONFIG_VALUE_0"], "git@github.com:")
        self.assertEqual(env["GIT_CONFIG_VALUE_1"], "ssh://git@github.com/")
        self.assertEqual(env["GIT_CONFIG_VALUE_2"], "")
        self.assertIn("AUTHORIZATION: basic ", env["GIT_CONFIG_VALUE_3"])


class GitHttpsAuthConfigTests(unittest.TestCase):
    def test_the_exact_four_entries_this_writes(self) -> None:
        # Four, not three: an empty http.<base>.extraheader resets any accumulated value before
        # the real one is set, every time (see the function's own docstring on why).
        config = agent_identity.git_https_auth_config("ghs_tok", {})
        self.assertEqual(config["GIT_CONFIG_COUNT"], "4")
        self.assertEqual(config["GIT_CONFIG_KEY_0"], "url.https://github.com/.insteadOf")
        self.assertEqual(config["GIT_CONFIG_VALUE_0"], "git@github.com:")
        self.assertEqual(config["GIT_CONFIG_KEY_1"], "url.https://github.com/.insteadOf")
        self.assertEqual(config["GIT_CONFIG_VALUE_1"], "ssh://git@github.com/")
        self.assertEqual(config["GIT_CONFIG_KEY_2"], "http.https://github.com/.extraheader")
        self.assertEqual(config["GIT_CONFIG_VALUE_2"], "")
        self.assertEqual(config["GIT_CONFIG_KEY_3"], "http.https://github.com/.extraheader")
        basic = base64.b64encode(b"x-access-token:ghs_tok").decode("ascii")
        self.assertEqual(config["GIT_CONFIG_VALUE_3"], f"AUTHORIZATION: basic {basic}")

    def test_appends_after_an_existing_git_config_count_rather_than_clobbering_it(self) -> None:
        base = {"GIT_CONFIG_COUNT": "2", "GIT_CONFIG_KEY_0": "x", "GIT_CONFIG_VALUE_0": "y"}
        config = agent_identity.git_https_auth_config("tok", base)
        self.assertEqual(config["GIT_CONFIG_COUNT"], "6")
        self.assertEqual(config["GIT_CONFIG_KEY_2"], "url.https://github.com/.insteadOf")
        self.assertEqual(config["GIT_CONFIG_KEY_4"], "http.https://github.com/.extraheader")
        self.assertEqual(config["GIT_CONFIG_VALUE_4"], "")
        self.assertEqual(config["GIT_CONFIG_KEY_5"], "http.https://github.com/.extraheader")
        # This function only adds its own four -- the caller's own existing entries are its to
        # keep, and are not repeated in what this returns.
        self.assertNotIn("GIT_CONFIG_KEY_0", config)
        self.assertNotIn("GIT_CONFIG_KEY_1", config)

    def test_an_unparseable_existing_count_is_treated_as_zero_rather_than_raising(self) -> None:
        config = agent_identity.git_https_auth_config("tok", {"GIT_CONFIG_COUNT": "not-a-number"})
        self.assertEqual(config["GIT_CONFIG_COUNT"], "4")
        self.assertIn("GIT_CONFIG_KEY_0", config)

    def test_the_token_is_never_written_into_a_url(self) -> None:
        config = agent_identity.git_https_auth_config("ghs_supersecret", {})
        for key, value in config.items():
            if key.endswith("_VALUE_0") or key.endswith("_VALUE_1"):
                self.assertNotIn("ghs_supersecret", value)

    def test_a_nested_run_resets_the_outer_extraheader_rather_than_stacking_it(self) -> None:
        # Without the empty-value reset, an inner run's own extraheader would be appended after
        # an outer run's, and git would send both -- a possibly expired outer token first, then
        # the fresh inner one, over the same request.
        outer = agent_identity.git_https_auth_config("outer_stale_token", {})
        inner = agent_identity.git_https_auth_config("inner_fresh_token", outer)
        merged = {**outer, **inner}
        count = int(merged["GIT_CONFIG_COUNT"])
        values = [merged[f"GIT_CONFIG_VALUE_{i}"] for i in range(count)]
        # The last extraheader-shaped entry is the fresh token; an empty entry sits directly
        # before it, resetting whatever the outer run had already set.
        extraheader_indices = [
            i for i in range(count) if merged[f"GIT_CONFIG_KEY_{i}"] == "http.https://github.com/.extraheader"
        ]
        self.assertEqual(values[extraheader_indices[-1] - 1], "")
        self.assertIn("inner_fresh_token", self._decode(values[extraheader_indices[-1]]))
        self.assertNotIn("outer_stale_token", self._decode(values[extraheader_indices[-1]]))

    @staticmethod
    def _decode(header_value: str) -> str:
        # "AUTHORIZATION: basic <base64>" -> the decoded "x-access-token:<token>" text.
        encoded = header_value.split(" ", 2)[-1]
        return base64.b64decode(encoded + "=" * (-len(encoded) % 4)).decode()


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


class _FakeResponse:
    def __init__(self, body: dict[str, Any]) -> None:
        self._raw = json.dumps(body).encode("utf-8")

    def __enter__(self) -> _FakeResponse:
        return self

    def __exit__(self, *_exc: object) -> None:
        return None

    def read(self) -> bytes:
        return self._raw


class _FakeGitHub:
    """Stands in for `_opener()`'s own return value, so the production `_request`, `default_get`,
    `default_post`, `mint_token_for_role`, `cmd_status` and `cmd_run` all run unchanged; records
    every Authorization header it was sent, so a test can look for that exact secret in the output.
    """

    def __init__(self, token: str, *, fail_with: int | None = None) -> None:
        self.token = token
        self.fail_with = fail_with
        self.authorizations: list[str] = []

    def open(self, request: urllib.request.Request, timeout: float = 0.0) -> _FakeResponse:
        authorization = request.get_header("Authorization")
        if authorization:
            self.authorizations.append(authorization)
        if self.fail_with is not None:
            raise urllib.error.HTTPError(
                request.full_url, self.fail_with, "error", email.message.Message(), io.BytesIO(b"Bad credentials")
            )
        if request.get_method() == "GET":
            return _FakeResponse({"id": 4242})
        return _FakeResponse({"token": self.token, "permissions": {"contents": "write"}})


class SecretsNeverPrintedTests(unittest.TestCase):
    """Runs the real `status`, `run` and HTTP-error paths against a real private key and a faked
    GitHub, capturing stdout and stderr, and looks for the key, the JWT and the installation token
    in what they print or raise.
    """

    TOKEN = "ghs_SECRET_installation_token_value"

    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        pem = agent_identity.role_pem_path(self.root, "claude-coder")
        subprocess.run(["openssl", "genrsa", "-out", str(pem), "2048"], check=True, capture_output=True, timeout=30)
        self.pem_body = pem.read_text(encoding="utf-8").splitlines()[1]
        config = {"app_id": "1", "slug": "nappy-claude-coder", "bot_id": 5, "name": "n", "html_url": "h"}
        agent_identity.role_json_path(self.root, "claude-coder").write_text(json.dumps(config), encoding="utf-8")

    def _assert_no_secret(self, fake: _FakeGitHub, *texts: str) -> None:
        self.assertTrue(fake.authorizations, "the faked GitHub was never called, so this proves nothing")
        secrets_sent = [self.TOKEN, self.pem_body]
        for authorization in fake.authorizations:
            secrets_sent.append(authorization.split(" ", 1)[1])  # the JWT itself
        for text in texts:
            for secret in secrets_sent:
                self.assertNotIn(secret, text)

    def _status(self, fake: _FakeGitHub) -> tuple[int, str, str]:
        stdout, stderr = io.StringIO(), io.StringIO()
        with (
            mock.patch.object(agent_identity, "_opener", return_value=fake),
            redirect_stdout(stdout),
            redirect_stderr(stderr),
        ):
            code = agent_identity.cmd_status(["claude-coder"], self.root, "O", "R")
        return code, stdout.getvalue(), stderr.getvalue()

    def test_status_prints_neither_the_key_nor_the_jwt_nor_the_token(self) -> None:
        fake = _FakeGitHub(self.TOKEN)
        code, out, err = self._status(fake)
        self.assertEqual(code, 0, out + err)
        self.assertIn("installed on O/R", out)
        self._assert_no_secret(fake, out, err)

    def test_status_on_an_http_error_prints_github_s_text_but_no_secret(self) -> None:
        fake = _FakeGitHub(self.TOKEN, fail_with=401)
        code, out, err = self._status(fake)
        self.assertNotEqual(code, 0)
        self.assertIn("Bad credentials", out + err)
        self._assert_no_secret(fake, out, err)

    def test_run_hands_the_token_to_the_child_only_and_prints_nothing_secret(self) -> None:
        fake = _FakeGitHub(self.TOKEN)
        handed: dict[str, str] = {}

        def fake_exec(_file: str, _args: list[str], env: dict[str, str]) -> None:
            handed.update(env)

        stdout, stderr = io.StringIO(), io.StringIO()
        with (
            mock.patch.object(agent_identity, "_opener", return_value=fake),
            mock.patch.object(agent_identity.os, "execvpe", side_effect=fake_exec),
            redirect_stdout(stdout),
            redirect_stderr(stderr),
        ):
            agent_identity.cmd_run("claude-coder", ["echo", "hi"], self.root, "O", "R")
        self.assertEqual(handed.get("GH_TOKEN"), self.TOKEN)
        self._assert_no_secret(fake, stdout.getvalue(), stderr.getvalue())

    def test_run_on_an_http_error_prints_no_secret(self) -> None:
        fake = _FakeGitHub(self.TOKEN, fail_with=500)
        stdout, stderr = io.StringIO(), io.StringIO()
        with (
            mock.patch.object(agent_identity, "_opener", return_value=fake),
            redirect_stdout(stdout),
            redirect_stderr(stderr),
        ):
            code = agent_identity.cmd_run("claude-coder", ["echo", "hi"], self.root, "O", "R")
        self.assertNotEqual(code, 0)
        self.assertIn("HTTP 500", stderr.getvalue())
        self._assert_no_secret(fake, stdout.getvalue(), stderr.getvalue())

    def test_an_http_error_s_own_text_never_carries_the_request_headers(self) -> None:
        fake = _FakeGitHub(self.TOKEN, fail_with=401)
        with (
            mock.patch.object(agent_identity, "_opener", return_value=fake),
            self.assertRaises(agent_identity.AgentIdentityHTTPError) as caught,
        ):
            agent_identity.default_get("https://api.github.com/x", {"Authorization": "Bearer JWT_SECRET_VALUE"})
        self.assertIn("Bad credentials", str(caught.exception))
        self.assertNotIn("JWT_SECRET_VALUE", str(caught.exception))
        self.assertNotIn("JWT_SECRET_VALUE", repr(caught.exception.args))


class MalformedRoleConfigTests(unittest.TestCase):
    def test_status_reports_a_broken_role_json_and_goes_on_to_the_other_roles(self) -> None:
        for broken in ("{bad", '{"app_id": "1", "slug": "s", "bot_id": "abc", "name": "n", "html_url": "h"}'):
            with self.subTest(broken=broken), tempfile.TemporaryDirectory() as temp:
                root = Path(temp)
                agent_identity.role_json_path(root, "claude-coder").write_text(broken, encoding="utf-8")
                stdout, stderr = io.StringIO(), io.StringIO()
                with redirect_stdout(stdout), redirect_stderr(stderr):
                    code = agent_identity.cmd_status(list(agent_identity.ROLE_NAMES), root, "O", "R")
                self.assertNotEqual(code, 0)
                self.assertIn("claude-coder:", stderr.getvalue())
                self.assertIn("create claude-coder --force", stderr.getvalue())
                for role in agent_identity.ROLE_NAMES:
                    if role != "claude-coder":
                        self.assertIn(f"{role}: not configured", stdout.getvalue())


class ManifestCallbackTests(unittest.TestCase):
    """Drives `run_manifest_flow`'s real local server the way a browser would -- the form page, then
    GitHub's redirect to /callback with the state that page carries -- with only the two GitHub
    calls mocked. Nothing here reaches GitHub.
    """

    CREATED: ClassVar[dict[str, Any]] = {
        "id": 77,
        "slug": "nappy-claude-coder",
        "name": "nappy-claude-coder",
        "html_url": "https://github.com/apps/nappy-claude-coder",
        "pem": "-----BEGIN RSA PRIVATE KEY-----\nabc\n-----END RSA PRIVATE KEY-----\n",
    }

    def _browser(self, opened: list[str]) -> Any:
        direct = urllib.request.build_opener(urllib.request.ProxyHandler({}))

        def visit(local_url: str) -> None:
            page = direct.open(local_url, timeout=10).read().decode("utf-8")
            match = re.search(r"state=([A-Za-z0-9_-]+)", page)
            assert match, "the form page carried no state"
            try:
                direct.open(f"{local_url}callback?code=abc&state={match.group(1)}", timeout=10).read()
            except urllib.error.HTTPError as error_page:
                error_page.close()  # a 500; the flow's own result is what the test checks

        def open_browser(url: str) -> bool:
            opened.append(url)
            if url.startswith("http://127.0.0.1:"):
                threading.Thread(target=visit, args=(url,), daemon=True).start()
            return True

        return open_browser

    def _run(self, root: Path, opened: list[str]) -> None:
        with redirect_stdout(io.StringIO()):
            agent_identity.run_manifest_flow(
                "claude-coder",
                agent_identity.ROLES["claude-coder"],
                "O",
                "R",
                root,
                open_browser=self._browser(opened),
                timeout_seconds=60,
            )

    def test_a_successful_callback_saves_the_config_and_opens_the_install_page(self) -> None:
        opened: list[str] = []
        with (
            tempfile.TemporaryDirectory() as temp,
            mock.patch.object(agent_identity, "exchange_manifest_code", return_value=dict(self.CREATED)),
            mock.patch.object(agent_identity, "fetch_bot_id", return_value=4242),
        ):
            root = Path(temp) / "agents"
            self._run(root, opened)
            config = agent_identity.load_role_config(root, "claude-coder")
            assert config is not None
            self.assertEqual(config["bot_id"], 4242)
        self.assertEqual(len(opened), 2)
        self.assertIn("nappy-claude-coder", opened[1])

    def test_a_failed_save_ends_the_wait_at_once_and_says_how_to_recover(self) -> None:
        opened: list[str] = []
        with (
            tempfile.TemporaryDirectory() as temp,
            mock.patch.object(agent_identity, "exchange_manifest_code", return_value=dict(self.CREATED)),
            mock.patch.object(agent_identity, "fetch_bot_id", return_value=4242),
            mock.patch.object(agent_identity, "write_role_config", side_effect=OSError("simulated disk full")),
        ):
            started = time.monotonic()
            with self.assertRaises(agent_identity.AgentIdentityError) as caught:
                self._run(Path(temp), opened)
            elapsed = time.monotonic() - started
        message = str(caught.exception)
        self.assertLess(elapsed, 15, "the flow waited out its timeout instead of ending on the error")
        self.assertIn("simulated disk full", message)
        self.assertIn("https://github.com/settings/apps/nappy-claude-coder", message)
        self.assertIn("create claude-coder --force", message)
        self.assertNotIn("timed out", message)
        self.assertEqual(len(opened), 1, "the install page must not open for an app whose key was lost")


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
