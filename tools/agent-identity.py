#!/usr/bin/env python3
"""Let each agent that works on this repository post to GitHub under its own identity, instead of
everything landing under the player's own account. The player's own words are why: *"it's
basically me talking to myself when in reality it's me and claude and other agents talking to each
other."* Without this, every commit, pull request, comment and review on `JosuaKrause/nappy` reads
as the player talking to themself.

The mechanism is one GitHub App per role, each posting as `<slug>[bot]`; `ROLES` below is the one
place the role table lives, so a later role is one row. Three subcommands:

    create <role>... [--force]
        Runs the GitHub App manifest flow for each role in turn -- on the player's own machine,
        since it needs their logged-in browser. Refuses a role that already has a config unless
        --force. See the module's own "create" section below for the exact steps.

    status [<role>...]
        For each role (all four with none given): configured or not, and if configured, mints an
        installation token (never printed) and reports the app's slug, bot id, whether it is
        installed on the repository, and the token's granted permissions. Exits non-zero if any
        requested role is not usable, naming what is missing and the command that fixes it.

    run <role> -- <command> [args...]
        Mints a token for <role> and os.execvpe()s <command> with it: GH_TOKEN/GITHUB_TOKEN set to
        the installation token, GIT_AUTHOR_NAME/GIT_COMMITTER_NAME set to "<slug>[bot]",
        GIT_AUTHOR_EMAIL/GIT_COMMITTER_EMAIL set to the noreply address GitHub attributes to that
        bot, NAPPY_AGENT_ROLE set to the role, and git's own HTTPS auth (GIT_CONFIG_COUNT/KEY_n/
        VALUE_n) pointed at the same token for this one child process, so a push authenticates as
        the bot even when the remote is an SSH URL (see build_run_environment's own docstring).
        The literal `--` is required; everything after it is the command, unvalidated.

Configuration lives under $NAPPY_AGENTS_DIR, or ~/.config/nappy-agents if that is unset: one
<role>.json (app_id, slug, bot_id, name, html_url) and one <role>.pem per role. The directory is
created 0700 and every .pem is written 0600. Nothing secret is ever printed or logged -- not a
private key, not a JWT, not an installation token -- in an error message included; an HTTP error
body from GitHub may be printed (it carries no secret of ours), a request's headers may not.

The repository is <owner>/<repo>, parsed from `git remote get-url origin` (an https:// URL, an
ssh git@github.com: URL, or a proxy-style URL whose path ends in /<owner>/<repo>, .git optional on
each); --repo OWNER/REPO overrides it.

**In a Claude Code cloud session, none of the four works.** The session's own proxy allows only
repository-scoped GitHub API endpoints under the session's own authorization -- a bare
`GET /users/octocat` there answers "This GitHub API path is not available: sessions are bound to
their configured repositories" -- `gh` is not installed, and there is no browser to run the
manifest flow's confirm page in. So all four are expected to fail in that environment,
and the "not configured" message says identities are set up on the player's own machine.
"""

from __future__ import annotations

import argparse
import base64
import html
import http.server
import json
import os
import re
import secrets
import socket
import ssl
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import webbrowser
from collections.abc import Callable, Mapping, Sequence
from dataclasses import dataclass
from pathlib import Path
from typing import Any, TypedDict

GITHUB_API = "https://api.github.com"
GITHUB_APP_MANIFEST_URL = "https://github.com/settings/apps/new"
API_VERSION = "2022-11-28"
USER_AGENT = "nappy-agent-identity"
CREATE_TIMEOUT_SECONDS = 600.0


class AgentIdentityError(RuntimeError):
    """An actionable failure -- printed on stderr and never carrying a secret."""


class AgentIdentityHTTPError(AgentIdentityError):
    """A GitHub HTTP error, carrying the status code so a 404 (not installed) can be told apart
    from a real failure.
    """

    def __init__(self, status: int, message: str) -> None:
        super().__init__(message)
        self.status = status


# --------------------------------------------------------------------------------- the role table ---


@dataclass(frozen=True)
class RoleSpec:
    """One row of the role table: the GitHub App's own name and its default repository
    permissions, exactly as the manifest flow sends them.
    """

    app_name: str
    description: str
    permissions: dict[str, str]


_CODER_PERMISSIONS: dict[str, str] = {
    "contents": "write",
    "pull_requests": "write",
    "issues": "write",
    "workflows": "write",
    "checks": "read",
    "actions": "read",
    "metadata": "read",
}

_REVIEWER_PERMISSIONS: dict[str, str] = {
    "contents": "read",
    "pull_requests": "write",
    "issues": "write",
    "checks": "read",
    "actions": "read",
    "metadata": "read",
}

# The one place the role table lives -- a later role is one row here and nowhere else.
ROLES: dict[str, RoleSpec] = {
    "claude-coder": RoleSpec(
        "nappy-claude-coder", "Claude Code's own coding commits, pushes and pull requests.", _CODER_PERMISSIONS
    ),
    "claude-reviewer": RoleSpec(
        "nappy-claude-reviewer", "Claude's adversarial pull request reviews.", _REVIEWER_PERMISSIONS
    ),
    "codex-coder": RoleSpec(
        "nappy-codex-coder", "Codex's own coding commits, pushes and pull requests.", _CODER_PERMISSIONS
    ),
    "codex-reviewer": RoleSpec(
        "nappy-codex-reviewer", "Codex's adversarial pull request reviews.", _REVIEWER_PERMISSIONS
    ),
}

ROLE_NAMES = sorted(ROLES)


class RoleConfig(TypedDict):
    """`<role>.json`'s own shape -- none of it secret; the matching `<role>.pem` is."""

    app_id: str
    slug: str
    bot_id: int
    name: str
    html_url: str


def install_url_for(slug: str) -> str:
    return f"https://github.com/apps/{slug}/installations/new"


def bot_identity(config: RoleConfig) -> str:
    return f"{config['slug']}[bot]"


def bot_noreply_email(config: RoleConfig) -> str:
    """The address GitHub attributes to `<slug>[bot]`'s commits, so a commit shows its avatar."""
    return f"{config['bot_id']}+{bot_identity(config)}@users.noreply.github.com"


# --------------------------------------------------------------------------------------- config ---


def config_root() -> Path:
    override = os.environ.get("NAPPY_AGENTS_DIR")
    if override:
        return Path(override)
    return Path.home() / ".config" / "nappy-agents"


def role_json_path(root: Path, role: str) -> Path:
    return root / f"{role}.json"


def role_pem_path(root: Path, role: str) -> Path:
    return root / f"{role}.pem"


def role_already_configured(root: Path, role: str) -> bool:
    return role_json_path(root, role).exists()


def roles_to_create(requested: Sequence[str], root: Path, *, force: bool) -> tuple[list[str], list[str]]:
    """Splits `requested` into (goes ahead, refused for already having a config without --force)."""
    ok: list[str] = []
    refused: list[str] = []
    for role in requested:
        if not force and role_already_configured(root, role):
            refused.append(role)
        else:
            ok.append(role)
    return ok, refused


def load_role_config(root: Path, role: str) -> RoleConfig | None:
    """`role`'s config, or None when it has never been created. Raises rather than returning a
    half-shaped config when the file exists but is missing a field a hand edit could have dropped.
    """
    path = role_json_path(root, role)
    try:
        text = path.read_text(encoding="utf-8")
    except OSError:
        return None
    data = json.loads(text)
    if not isinstance(data, dict):
        raise AgentIdentityError(f"{path} is not a JSON object")
    missing = [key for key in ("app_id", "slug", "bot_id", "name", "html_url") if key not in data]
    if missing:
        raise AgentIdentityError(f"{path} is missing {missing!r} -- recreate it with 'create {role} --force'")
    return {
        "app_id": str(data["app_id"]),
        "slug": str(data["slug"]),
        "bot_id": int(data["bot_id"]),
        "name": str(data["name"]),
        "html_url": str(data["html_url"]),
    }


def write_role_config(root: Path, role: str, config: RoleConfig, pem_text: str) -> None:
    """Writes `<role>.json` and `<role>.pem`, creating the directory 0700 and the key 0600."""
    root.mkdir(parents=True, exist_ok=True)
    root.chmod(0o700)
    role_json_path(root, role).write_text(json.dumps(config, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    pem_path = role_pem_path(root, role)
    pem_path.write_text(pem_text, encoding="utf-8")
    pem_path.chmod(0o600)


# ---------------------------------------------------------------------------- the origin remote ---


def parse_owner_repo(text: str) -> tuple[str, str]:
    """`--repo`'s own OWNER/REPO shape: exactly one slash, both sides non-empty."""
    parts = text.split("/")
    if len(parts) != 2 or not parts[0] or not parts[1]:
        raise AgentIdentityError(f"--repo must be OWNER/REPO, not {text!r}")
    return parts[0], parts[1]


# Matches the trailing /<owner>/<repo>(.git)?(/)? of any of the three shapes the brief names:
# https://github.com/O/R(.git), git@github.com:O/R(.git), and a proxy URL whose path ends the same
# way -- the separator right before the owner is ':' for the ssh shape and '/' for the other two.
_REMOTE_RE = re.compile(r"[:/]([^/:]+)/([^/]+?)(?:\.git)?/?$")


def parse_remote_url(url: str) -> tuple[str, str]:
    match = _REMOTE_RE.search(url.strip())
    if not match or not match.group(1) or not match.group(2):
        raise AgentIdentityError(f"could not find OWNER/REPO in the origin remote {url!r} -- pass --repo OWNER/REPO")
    return match.group(1), match.group(2)


def _git_remote_origin() -> str:
    result = subprocess.run(
        ["git", "remote", "get-url", "origin"], capture_output=True, text=True, check=False, timeout=15
    )
    if result.returncode != 0:
        raise AgentIdentityError(
            f"git remote get-url origin failed: {result.stderr.strip()} -- pass --repo OWNER/REPO instead"
        )
    return result.stdout.strip()


def resolve_repo(explicit: str | None, *, remote_url: Callable[[], str] = _git_remote_origin) -> tuple[str, str]:
    if explicit:
        return parse_owner_repo(explicit)
    return parse_remote_url(remote_url())


# ------------------------------------------------------------------------------------------ JWT ---


def _b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode("ascii")


def _openssl_sign(data: bytes, pem_path: Path) -> bytes:
    """Signs `data` (RS256: SHA-256 then PKCS#1 v1.5) with the key at `pem_path` through
    `openssl dgst -sha256 -sign`, stdin/stdout only -- never a temp file for the JWT.
    """
    result = subprocess.run(
        ["openssl", "dgst", "-sha256", "-sign", str(pem_path)],
        input=data,
        capture_output=True,
        check=False,
        timeout=15,
    )
    if result.returncode != 0:
        detail = result.stderr.decode("utf-8", "replace").strip()
        raise AgentIdentityError(f"openssl could not sign the JWT: {detail}")
    return result.stdout


def build_jwt(
    app_id: str,
    pem_path: Path,
    *,
    now: int | None = None,
    sign: Callable[[bytes, Path], bytes] = _openssl_sign,
) -> str:
    """A short-lived (10 minute, backdated 60s for clock skew) App JWT, RS256-signed. Never printed
    by anything that calls this -- see the module docstring.
    """
    moment = now if now is not None else int(time.time())
    header = {"alg": "RS256", "typ": "JWT"}
    payload = {"iat": moment - 60, "exp": moment + 540, "iss": str(app_id)}
    signing_input = (
        f"{_b64url(json.dumps(header, separators=(',', ':')).encode('ascii'))}."
        f"{_b64url(json.dumps(payload, separators=(',', ':')).encode('ascii'))}"
    )
    signature = sign(signing_input.encode("ascii"), pem_path)
    return f"{signing_input}.{_b64url(signature)}"


# ------------------------------------------------------------------------------------------ HTTP ---


def _opener() -> urllib.request.OpenerDirector:
    # Mirrors goatcounter.py's own opener: ssl.create_default_context() already honours the
    # OpenSSL-level SSL_CERT_FILE/SSL_CERT_DIR and the system trust store; REQUESTS_CA_BUNDLE is
    # read explicitly here too, for a cloud session's proxy whose CA bundle is only published
    # under that name.
    cafile = os.environ.get("SSL_CERT_FILE") or os.environ.get("REQUESTS_CA_BUNDLE")
    context = ssl.create_default_context(cafile=cafile) if cafile else ssl.create_default_context()
    return urllib.request.build_opener(urllib.request.HTTPSHandler(context=context))


def _request(
    method: str, url: str, headers: dict[str, str], body: bytes | None = None, *, timeout: float = 20.0
) -> dict[str, Any]:
    """One GitHub HTTP call, decoded as JSON. Never receives or logs anything from `headers` in an
    error message; a GitHub error body may be included, since it is GitHub's own text, not ours.
    """
    request = urllib.request.Request(url, data=body, headers=headers, method=method)
    try:
        with _opener().open(request, timeout=timeout) as response:
            raw = response.read()
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", "replace").strip()
        message = f"GitHub returned HTTP {exc.code} for {method} {url}"
        raise AgentIdentityHTTPError(exc.code, f"{message}: {detail}" if detail else message) from exc
    except urllib.error.URLError as exc:
        raise AgentIdentityError(f"could not reach GitHub: {exc.reason}") from exc
    except OSError as exc:
        raise AgentIdentityError(f"network error reaching GitHub: {exc}") from exc
    if not raw:
        return {}
    try:
        decoded: Any = json.loads(raw.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise AgentIdentityError(f"GitHub's response from {url} was not valid JSON: {exc}") from exc
    if not isinstance(decoded, dict):
        raise AgentIdentityError(f"GitHub's response from {url} was not a JSON object")
    return decoded


# A GET/POST-JSON pair, kept as callables so the token-minting logic below never needs to know
# whether it is talking to the real network or a test's canned responses (see goatcounter.py's own
# Fetcher for the same reason).
Getter = Callable[[str, dict[str, str]], dict[str, Any]]
Poster = Callable[[str, dict[str, str], dict[str, Any]], dict[str, Any]]


def default_get(url: str, headers: dict[str, str]) -> dict[str, Any]:
    return _request("GET", url, headers)


def default_post(url: str, headers: dict[str, str], body: dict[str, Any]) -> dict[str, Any]:
    return _request("POST", url, headers, json.dumps(body).encode("utf-8"))


def _github_headers(jwt: str) -> dict[str, str]:
    return {
        "Authorization": f"Bearer {jwt}",
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": API_VERSION,
        "User-Agent": USER_AGENT,
    }


def fetch_installation_id(get: Getter, jwt: str, owner: str, repo: str, *, install_url: str) -> int:
    """The installation id for `<owner>/<repo>`, via the repository-scoped endpoint on purpose --
    see the module docstring's "cloud session" paragraph for why a broader one is not used. A 404
    means the app exists but is not installed on this repository.
    """
    try:
        data = get(f"{GITHUB_API}/repos/{owner}/{repo}/installation", _github_headers(jwt))
    except AgentIdentityHTTPError as exc:
        if exc.status == 404:
            raise AgentIdentityError(f"not installed on {owner}/{repo} -- install it at {install_url}") from exc
        raise
    installation_id = data.get("id")
    if not isinstance(installation_id, int):
        raise AgentIdentityError("GitHub's installation lookup had no numeric 'id'")
    return installation_id


def mint_installation_token(post: Poster, jwt: str, installation_id: int, repo: str) -> dict[str, Any]:
    """A repository-scoped installation access token, minted fresh every call -- never cached, so
    a token this prints or stores never outlives the process that asked for it.
    """
    data = post(
        f"{GITHUB_API}/app/installations/{installation_id}/access_tokens",
        _github_headers(jwt),
        {"repositories": [repo]},
    )
    token = data.get("token")
    if not isinstance(token, str) or not token:
        raise AgentIdentityError("GitHub's access-token response had no 'token'")
    return data


def mint_token_for_role(
    config: RoleConfig,
    pem_path: Path,
    owner: str,
    repo: str,
    *,
    get: Getter = default_get,
    post: Poster = default_post,
    sign: Callable[[bytes, Path], bytes] = _openssl_sign,
) -> dict[str, Any]:
    """The access-token response for `config`'s role against `<owner>/<repo>` -- shared by `status`
    and `run`. Raises with the install URL when the app is not installed there.
    """
    jwt = build_jwt(config["app_id"], pem_path, sign=sign)
    installation_id = fetch_installation_id(get, jwt, owner, repo, install_url=install_url_for(config["slug"]))
    return mint_installation_token(post, jwt, installation_id, repo)


# --------------------------------------------------------------------------------- create's flow ---


def build_manifest(role: str, spec: RoleSpec, owner: str, repo: str, port: int) -> dict[str, Any]:
    """The GitHub App manifest for `role`, exactly as posted to the manifest flow. `hook_attributes`
    names a URL only because the manifest schema requires one; `active: false` means no webhook is
    ever actually wanted.
    """
    repo_url = f"https://github.com/{owner}/{repo}"
    return {
        "name": spec.app_name,
        "url": repo_url,
        "hook_attributes": {"url": repo_url, "active": False},
        "redirect_url": f"http://127.0.0.1:{port}/callback",
        "description": f"nappy {role}: {spec.description}",
        "public": False,
        "default_permissions": dict(spec.permissions),
    }


def render_manifest_form(manifest: dict[str, Any], action_url: str) -> str:
    """The local page the browser is opened to: it auto-submits `manifest` as a POST to
    `action_url`, HTML-escaped into the hidden input's `value` attribute.
    """
    escaped_manifest = html.escape(json.dumps(manifest), quote=True)
    escaped_action = html.escape(action_url, quote=True)
    return (
        '<!doctype html><html><body onload="document.forms[0].submit()">'
        f'<form method="post" action="{escaped_action}">'
        f'<input type="hidden" name="manifest" value="{escaped_manifest}">'
        "</form>"
        "<p>Creating the GitHub App&hellip; if nothing happens in a few seconds, "
        "submit this form by hand.</p>"
        "</body></html>"
    )


def render_success_page(role: str, slug: str, install_url: str, owner: str, repo: str) -> str:
    escaped_install = html.escape(install_url, quote=True)
    return (
        "<!doctype html><html><body>"
        f"<p>{html.escape(slug)} exists for {html.escape(role)}. Install it on "
        f"<strong>only {html.escape(owner)}/{html.escape(repo)}</strong>: "
        f'<a href="{escaped_install}">{escaped_install}</a></p>'
        "</body></html>"
    )


def exchange_manifest_code(code: str) -> dict[str, Any]:
    """`POST /app-manifests/<code>/conversions` -- no auth; the code is single-use and valid for
    one hour. The response has id, slug, name, html_url, pem and more.
    """
    return _request(
        "POST",
        f"{GITHUB_API}/app-manifests/{urllib.parse.quote(code)}/conversions",
        {"Accept": "application/vnd.github+json", "X-GitHub-Api-Version": API_VERSION, "User-Agent": USER_AGENT},
    )


def fetch_bot_id(slug: str) -> int:
    """`GET /users/<slug>%5Bbot%5D` -- the bot account's own numeric id."""
    data = _request(
        "GET",
        f"{GITHUB_API}/users/{urllib.parse.quote(slug, safe='')}%5Bbot%5D",
        {"Accept": "application/vnd.github+json", "X-GitHub-Api-Version": API_VERSION, "User-Agent": USER_AGENT},
    )
    bot_id = data.get("id")
    if not isinstance(bot_id, int):
        raise AgentIdentityError(f"GitHub's user lookup for {slug}[bot] had no numeric 'id'")
    return bot_id


def _free_port() -> int:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as probe:
        probe.bind(("127.0.0.1", 0))
        return int(probe.getsockname()[1])


def run_manifest_flow(
    role: str,
    spec: RoleSpec,
    owner: str,
    repo: str,
    root: Path,
    *,
    open_browser: Callable[[str], bool] = webbrowser.open,
    timeout_seconds: float = CREATE_TIMEOUT_SECONDS,
) -> None:
    """The manifest flow for one role: local server, browser, GitHub's confirm page and redirect,
    the code exchange, the bot id lookup, and writing the config -- run on the player's own
    machine, since it needs their logged-in browser (see the module docstring).
    """
    state = secrets.token_urlsafe(32)
    port = _free_port()
    manifest = build_manifest(role, spec, owner, repo, port)
    action_url = f"{GITHUB_APP_MANIFEST_URL}?state={urllib.parse.quote(state)}"
    page = render_manifest_form(manifest, action_url)
    outcome: dict[str, Any] = {}

    class _Handler(http.server.BaseHTTPRequestHandler):
        def log_message(self, log_format: str, *args: Any) -> None:
            pass  # silences BaseHTTPRequestHandler's default per-request access log

        def _send(self, status: int, body: str) -> None:
            encoded = body.encode("utf-8")
            self.send_response(status)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(encoded)))
            self.end_headers()
            self.wfile.write(encoded)

        def do_GET(self) -> None:
            parsed = urllib.parse.urlsplit(self.path)
            if parsed.path == "/":
                self._send(200, page)
                return
            if parsed.path != "/callback":
                self._send(404, "not found")
                return
            query = urllib.parse.parse_qs(parsed.query)
            code = query.get("code", [""])[0]
            got_state = query.get("state", [""])[0]
            if got_state != state:
                self._send(400, "<html><body>state did not match -- nothing was created.</body></html>")
                outcome["error"] = "the callback's state did not match what was sent"
                return
            if not code:
                self._send(400, "<html><body>GitHub sent no code.</body></html>")
                outcome["error"] = "GitHub's callback carried no code"
                return
            try:
                created = exchange_manifest_code(code)
                slug = str(created["slug"])
                bot_id = fetch_bot_id(slug)
                config: RoleConfig = {
                    "app_id": str(created["id"]),
                    "slug": slug,
                    "bot_id": bot_id,
                    "name": str(created["name"]),
                    "html_url": str(created["html_url"]),
                }
                write_role_config(root, role, config, str(created["pem"]))
            except (AgentIdentityError, KeyError) as exc:
                self._send(500, f"<html><body>{html.escape(str(exc))}</body></html>")
                outcome["error"] = str(exc)
                return
            outcome["slug"] = slug
            outcome["install_url"] = install_url_for(slug)
            self._send(200, render_success_page(role, slug, outcome["install_url"], owner, repo))

    server = http.server.HTTPServer(("127.0.0.1", port), _Handler)
    local_url = f"http://127.0.0.1:{port}/"
    print(
        f"agent-identity: opening {local_url} to create {spec.app_name}",
        "-- open it by hand if a browser does not appear",
    )
    open_browser(local_url)
    deadline = time.monotonic() + timeout_seconds
    try:
        while "install_url" not in outcome and "error" not in outcome:
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                raise AgentIdentityError(f"timed out waiting for GitHub's callback for {role} after 10 minutes")
            server.timeout = min(remaining, 5.0)
            server.handle_request()
    finally:
        server.server_close()

    if "error" in outcome:
        raise AgentIdentityError(f"could not finish creating {role}: {outcome['error']}")

    print(
        f"agent-identity: {role} created as {outcome['slug']} -- install it on {owner}/{repo} only: "
        f"{outcome['install_url']}"
    )
    open_browser(str(outcome["install_url"]))


# --------------------------------------------------------------------------------------- run's env ---


def git_https_auth_config(token: str, base_env: Mapping[str, str]) -> dict[str, str]:
    """`GIT_CONFIG_COUNT`/`GIT_CONFIG_KEY_n`/`GIT_CONFIG_VALUE_n` that make git talk to GitHub over
    HTTPS with `token`, for this one child process only -- appended after any `GIT_CONFIG_COUNT`
    `base_env` already carries, never clobbering it. Needed because `origin` here is an SSH remote
    (`git@github.com:JosuaKrause/nappy.git`): without this, `run`'s own git identity is the bot but
    a push still authenticates with the player's own SSH key. Two `url.<base>.insteadOf` entries
    redirect both SSH forms `origin` may use (`git@github.com:owner/repo.git` and
    `ssh://git@github.com/owner/repo.git`) to the HTTPS remote, and one `http.<base>.extraheader`
    carries the installation token as a Basic `Authorization` header (the same header curl sends
    for `x-access-token:<token>`, base64-encoded) -- so nothing writes the token into a URL git
    might echo in a log or an error, and nothing touches a git config file on disk.
    """
    try:
        start = int(base_env.get("GIT_CONFIG_COUNT", "0"))
    except ValueError:
        start = 0
    basic = base64.b64encode(f"x-access-token:{token}".encode()).decode("ascii")
    entries = [
        ("url.https://github.com/.insteadOf", "git@github.com:"),
        ("url.https://github.com/.insteadOf", "ssh://git@github.com/"),
        ("http.https://github.com/.extraheader", f"AUTHORIZATION: basic {basic}"),
    ]
    config: dict[str, str] = {"GIT_CONFIG_COUNT": str(start + len(entries))}
    for offset, (key, value) in enumerate(entries):
        index = start + offset
        config[f"GIT_CONFIG_KEY_{index}"] = key
        config[f"GIT_CONFIG_VALUE_{index}"] = value
    return config


def build_run_environment(role: str, config: RoleConfig, token: str, base_env: Mapping[str, str]) -> dict[str, str]:
    """`base_env` plus what `run` adds: the token under both names GitHub tooling looks for it
    under, the bot's git identity, the same token wired into git's own HTTPS auth for this child
    process (see `git_https_auth_config`), and the role for anything downstream that wants to know it.
    """
    identity = bot_identity(config)
    noreply = bot_noreply_email(config)
    env = dict(base_env)
    env.update(
        {
            "GH_TOKEN": token,
            "GITHUB_TOKEN": token,
            "GIT_AUTHOR_NAME": identity,
            "GIT_COMMITTER_NAME": identity,
            "GIT_AUTHOR_EMAIL": noreply,
            "GIT_COMMITTER_EMAIL": noreply,
            "NAPPY_AGENT_ROLE": role,
        }
    )
    env.update(git_https_auth_config(token, base_env))
    return env


def resolve_run_token(role: str, root: Path, owner: str, repo: str) -> tuple[RoleConfig, str]:
    config = load_role_config(root, role)
    if config is None:
        raise AgentIdentityError(
            f"{role} is not configured -- run 'uv run python tools/agent-identity.py create {role}' on your "
            "own machine (identities are set up there, not in a cloud session)"
        )
    token_response = mint_token_for_role(config, role_pem_path(root, role), owner, repo)
    return config, str(token_response["token"])


# ------------------------------------------------------------------------------------------- CLI ---


def cmd_create(roles: Sequence[str], *, force: bool, owner: str, repo: str, root: Path) -> int:
    ok, refused = roles_to_create(roles, root, force=force)
    for role in refused:
        print(
            f"agent-identity: {role} already has {role_json_path(root, role)} -- use --force to replace it",
            file=sys.stderr,
        )
    exit_code = 1 if refused else 0
    for role in ok:
        try:
            run_manifest_flow(role, ROLES[role], owner, repo, root)
        except AgentIdentityError as exc:
            print(f"agent-identity: could not create {role}: {exc}", file=sys.stderr)
            exit_code = 1
    return exit_code


def cmd_status(roles: Sequence[str], root: Path, owner: str, repo: str) -> int:
    exit_code = 0
    for role in roles:
        try:
            config = load_role_config(root, role)
        except AgentIdentityError as exc:
            print(f"{role}: {exc}", file=sys.stderr)
            exit_code = 1
            continue
        if config is None:
            print(f"{role}: not configured -- run: uv run python tools/agent-identity.py create {role}")
            exit_code = 1
            continue
        try:
            token_response = mint_token_for_role(config, role_pem_path(root, role), owner, repo)
        except AgentIdentityError as exc:
            print(f"{role}: {config['slug']} -- {exc}")
            exit_code = 1
            continue
        print(
            f"{role}: {config['slug']} (bot id {config['bot_id']}) -- installed on {owner}/{repo}, "
            f"permissions {token_response.get('permissions')!r}"
        )
    return exit_code


def cmd_run(role: str, command: list[str], root: Path, owner: str, repo: str) -> int:
    try:
        config, token = resolve_run_token(role, root, owner, repo)
    except AgentIdentityError as exc:
        print(f"agent-identity: {exc}", file=sys.stderr)
        return 1
    env = build_run_environment(role, config, token, os.environ)
    os.execvpe(command[0], command, env)
    return 1  # pragma: no cover -- os.execvpe never returns on success


def _add_repo_option(parser: argparse.ArgumentParser) -> None:
    parser.add_argument(
        "--repo",
        type=str,
        default=None,
        metavar="OWNER/REPO",
        help="override the origin remote's own owner/repo",
    )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="agent-identity.py",
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "examples:\n"
            "  uv run python tools/agent-identity.py create claude-coder claude-reviewer codex-coder codex-reviewer\n"
            "  uv run python tools/agent-identity.py status\n"
            "  uv run python tools/agent-identity.py run claude-coder -- git push\n"
        ),
    )
    subparsers = parser.add_subparsers(dest="subcommand", required=True, metavar="{create,status,run}")

    create = subparsers.add_parser(
        "create",
        help="run the GitHub App manifest flow for one or more roles (player's own machine only)",
        description="Run the GitHub App manifest flow for one or more roles.",
    )
    create.add_argument(
        "roles", nargs="+", choices=ROLE_NAMES, metavar="ROLE", help=f"one or more of: {', '.join(ROLE_NAMES)}"
    )
    create.add_argument("--force", action="store_true", help="replace a role that already has a config")
    _add_repo_option(create)

    status = subparsers.add_parser(
        "status",
        help="report whether each role is configured, installed, and usable",
        description="Report whether each role is configured, installed, and usable.",
    )
    status.add_argument(
        "roles", nargs="*", choices=ROLE_NAMES, metavar="ROLE", help=f"defaults to all four: {', '.join(ROLE_NAMES)}"
    )
    _add_repo_option(status)

    # "run" is not registered as a real subparser: its command tail is unvalidated and split out
    # by hand in _main_run before argparse ever sees it (see that function). This entry exists
    # only so --help lists it; agent-identity.py run --help is handled by _main_run's own parser.
    subparsers.add_parser(
        "run",
        help="mint a token for ROLE and exec COMMAND as that identity: run ROLE -- COMMAND [ARGS...]",
        description="Mint a token for ROLE and exec COMMAND as that identity.",
        add_help=False,
    )
    return parser


def _build_run_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="agent-identity.py run",
        usage="agent-identity.py run [-h] [--repo OWNER/REPO] ROLE -- COMMAND [ARGS...]",
        description=(
            "Mint a token for ROLE and exec COMMAND as that GitHub identity.\n"
            "The literal -- is required; everything after it is COMMAND, unvalidated."
        ),
        epilog="  uv run python tools/agent-identity.py run claude-coder -- git push -u origin my-branch\n",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("role", choices=ROLE_NAMES, metavar="ROLE")
    _add_repo_option(parser)
    return parser


def _split_on_separator(args: list[str]) -> tuple[list[str], list[str] | None]:
    """`args` split at the first literal `--`: (before, after), or (args, None) with no `--` at
    all -- told apart from an empty command (args, []) after a `--` with nothing following it.
    """
    if "--" not in args:
        return args, None
    index = args.index("--")
    return args[:index], args[index + 1 :]


def _main_run(rest: list[str]) -> int:
    parser = _build_run_parser()
    pre, command = _split_on_separator(rest)
    args = parser.parse_args(pre)  # --help/-h or an unknown flag here exits before anything else.
    if command is None:
        parser.error("a literal -- and a command are required: run ROLE -- COMMAND [ARGS...]")
    if not command:
        parser.error("no command was given after --")
    try:
        owner, repo = resolve_repo(args.repo)
    except AgentIdentityError as exc:
        print(f"agent-identity: {exc}", file=sys.stderr)
        return 2
    return cmd_run(args.role, command, config_root(), owner, repo)


def main(argv: list[str] | None = None) -> int:
    argv = list(sys.argv[1:] if argv is None else argv)
    if argv[:1] == ["run"]:
        return _main_run(argv[1:])

    args = build_parser().parse_args(argv)
    try:
        owner, repo = resolve_repo(args.repo)
    except AgentIdentityError as exc:
        print(f"agent-identity: {exc}", file=sys.stderr)
        return 2

    root = config_root()
    if args.subcommand == "create":
        return cmd_create(args.roles, force=args.force, owner=owner, repo=repo, root=root)
    if args.subcommand == "status":
        return cmd_status(args.roles or ROLE_NAMES, root, owner, repo)
    raise AssertionError(f"unhandled subcommand {args.subcommand!r}")  # argparse's own choices exhaust this


if __name__ == "__main__":
    sys.exit(main())
