#!/usr/bin/env python3
"""Read GoatCounter's `nappy-` event counts back as a per-day funnel.

Run it through the wrapper, which owns the environment:

    tools/goatcounter.sh
    tools/goatcounter.sh --days 7
    tools/goatcounter.sh --start 2026-09-01 --end 2026-09-15
    tools/goatcounter.sh --json
    tools/goatcounter.sh --encounters

`VisitCounter` (`src/autoload/visit_counter.gd`) sends one GoatCounter event per moment worth
counting, each path starting `nappy-`, to the game's own site, `nappy.goatcounter.com` -- see
`docs/TELEMETRY.md`, "The page counts visits". This reads them back through GoatCounter's own read
API (`GET /api/v0/stats/hits`), groups them the way the names are shaped, and prints the result for
a person or an assistant to read. The page visit is counted on the same site, under the path
`nappy.josuakrause.com/`, which GoatCounter stores and `--raw` lists as `/nappy.josuakrause.com`;
the site keeps sessions for it, so its count is visitors. `josuakrause.goatcounter.com` holds only
the page visits and events from before the page counted everything on the game's own site; `--site`
with that site's API URL, and that site's key in `GOATCOUNTER_TOKEN`, reads that history.

The API key is a read-only token from the GoatCounter site's own Settings -> API page, passed only
through the environment variable `GOATCOUNTER_TOKEN` -- never as a command-line flag, since a flag
lands in shell history and process listings. `GOATCOUNTER_SITE` overrides the default site the same
way. A process environment variable always wins; when one is not set, a `.env` file at the
repository root (`KEY=value` per line, blank lines and `#` comments ignored, optional surrounding
quotes stripped -- git-ignored, so it never reaches a commit) is read for it instead, which is
mainly for a local checkout where exporting the variable in every shell is more friction than a
file read once. In a linked git worktree the main checkout's `.env` is read after the worktree's
own. Nothing here prints either value.

The key goes only to the site it was set for: a `--site` or `GOATCOUNTER_SITE` that is not an
`https://` URL is refused before any request, since it would send the key in the clear, and a
redirect that leaves the site's own `https://` host is refused rather than followed, since urllib
carries the `Authorization` header across a redirect to any host.

`GET /api/v0/stats/hits` answers `{hits: [...], more, total}`, paginated by passing every path id
already seen as ONE comma-separated `exclude_paths=1,2,3` while `more` stays true (see
`https://nappy.goatcounter.com/api.json`, the endpoint's own Swagger spec). The comma form is the
only one that works: the spec says `exclude_paths` is an array, but the server honours only the first
value of a repeated `exclude_paths=1&exclude_paths=2`, so repeating it re-sent the same hits page after
page (duplicated counts) and, with the list growing by ~24 bytes an id, ended in a query of ~32 KB that
the server answers by closing the connection (the "Remote end closed connection without response" of a
long range). Comma-joined, an id costs ~10 bytes, and a range whose list would still pass ~30 KB is
refused with a message to narrow it rather than sent. A page that says `more` while none of its hits
carries a `path_id` cannot be paged past, and is an error rather than a quietly short count.
`count` on each hit is "Number of visitors for the selected date range", the API's own wording. The
page visit keeps the
site's sessions, so its count is visitors; every event opts out of them (`count.js`'s `no_session`,
sent as the hit's `ns` parameter), and GoatCounter counts a hit without a session as a visit of its
own: an event's count is every time it was sent, a retry by the same person included.

Grouping follows the shape `docs/TELEMETRY.md` documents rather than a hard-coded list of event
names, since the catalogue keeps growing: a name is either run-level (`run-*`, `ending-*`,
`escape-*`, `controls-*`), a day event (`day-<N>-<rest>`), or -- if it matches neither shape --
printed anyway, at the end, rather than silently dropped. `--raw` skips the grouping and the
`--prefix` filter and prints every path GoatCounter has for the range, events and the page visit
alike -- what an assistant would otherwise reach for a hand-written request to answer.

`--encounters` reads the encounter events instead of the funnel: for each event type, how many
encounters were seen (`day-<N>-seen-<event>`), how many of those were meaningful
(`day-<N>-influenced-<event>`), influenced / seen, and the meaningful encounters she never saw
(`day-<N>-influenced-unseen-<event>`) as a column of their own -- overall and per day. The ratio is
left blank when nothing was seen rather than divided by nothing. The fire's older
`nappy-day-3-seen-fire` is a moment of its own, not an encounter, and stays out of the table.

`--check` proves the key works with `GET /api/v0/stats/total` for the last hour, which needs only
the "Read statistics" permission -- the one every read-only key has. It then tries `GET /api/v0/me`
for the token's own name and permissions, which is optional extra information: on a 403 or 404
there it says so and still succeeds, since the statistics call already proved the key works; only a
failure of the statistics call itself (401/403, or a network error) is the real "this key does not
work". Never prints the key.

**GoatCounter's API is reached only through this script.** An assistant that needs something this
cannot yet answer adds a flag here rather than writing a one-off `curl` or web request against the
API directly -- see `.claude/skills/using-tools/SKILL.md`'s own row for why.
"""

from __future__ import annotations

import argparse
import http.client
import json
import os
import re
import ssl
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from collections.abc import Callable
from datetime import UTC, datetime, timedelta
from pathlib import Path
from typing import Any, NamedTuple

DEFAULT_SITE = "https://nappy.goatcounter.com/api/v0/"
DEFAULT_PREFIX = "nappy-"
DEFAULT_DAYS = 30
PAGE_LIMIT = 100

# 429 is a rate limit, not a failure -- back off and try again a few times before giving up.
MAX_RETRIES = 5
RETRY_BACKOFF_SECONDS = 2.0
# The server closes the connection on a request line of roughly 32 KB (measured: 31 KB answered, 33 KB
# closed); stay under it and say so, rather than send a query that can only end in a dropped connection.
MAX_QUERY_BYTES = 30_000

# The shapes VisitCounter sends outside a day, from docs/TELEMETRY.md's own list -- not the full
# set of run-level names, which grows; a name starting with one of these is run-level regardless.
RUN_LEVEL_PREFIXES = ("run-", "ending-", "escape-", "controls-")
DAY_RE = re.compile(r"^day-(\d+)-(.+)$")

# A lost day's own name, VisitCounter._loss_event_suffix()'s own shape: the kind
# (crying/hard-fail/timeout) with its cause folded on, unprefixed -- lost-crying-traffic,
# lost-hard-fail-car, lost-timeout (never a cause). The old two-event shape's bare lost-crying /
# lost-hard-fail (no cause -- one playthrough, from before this fold) matches with group(2) empty,
# which is exactly the "still listed, no special handling" the funnel owes it: it folds into the
# kind's own subtotal with no cause line of its own.
LOST_RE = re.compile(r"^lost-(crying|hard-fail|timeout)(?:-(.+))?$")

# A day's encounter names, EncounterWatch's three readings: seen-<event>, influenced-<event> and
# influenced-unseen-<event>, the longer alternative tried first so an unseen influence is never read
# as an influence of an event called "unseen-...".
ENCOUNTER_RE = re.compile(r"^(seen|influenced-unseen|influenced)-(.+)$")
# Day names that match the shape and are not encounters: the burning building's own first sighting,
# sent beside the encounter set, whose `fire` is no catalogue row.
NOT_ENCOUNTERS = frozenset({"seen-fire"})
ENCOUNTER_COLUMNS = ("seen", "influenced", "influenced-unseen")

# One HTTP request as {query params} -> decoded JSON body; a real fetcher talks to GoatCounter,
# a test fetcher is a closure over canned pages. Kept as a callable so fetch_hits and the grouping
# below never need to know which.
Fetcher = Callable[[dict[str, Any]], dict[str, Any]]


class GoatCounterError(RuntimeError):
    """An actionable failure reading GoatCounter or its own input."""


class GoatCounterHTTPError(GoatCounterError):
    """A GoatCounter HTTP error, carrying the status code for a caller that needs to tell them apart

    (`--check` treats a 403/404 from `GET /api/v0/me` as that optional information failing to load,
    not a failure, while the same status from `GET /api/v0/stats/total` is the real "key does not
    work").
    """

    def __init__(self, status: int, message: str) -> None:
        super().__init__(message)
        self.status = status


# ---------------------------------------------------------------------------------- environment ---


def _repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


def _parse_dotenv(path: Path) -> dict[str, str]:
    """A `.env` file's `KEY=value` pairs. Missing file, blank lines and `#` comments are fine."""
    try:
        text = path.read_text(encoding="utf-8")
    except OSError:
        return {}
    values: dict[str, str] = {}
    for line in text.splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#") or "=" not in stripped:
            continue
        key, _, value = stripped.partition("=")
        key = key.strip()
        value = value.strip()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in ("'", '"'):
            value = value[1:-1]
        if key:
            values[key] = value
    return values


def _main_checkout(root: Path) -> Path | None:
    """The main checkout's root when `root` is a linked git worktree, else None.

    A worktree's `.git` is a file (`gitdir: <main>/.git/worktrees/<name>`), and that directory's
    `commondir` names the shared `.git`, whose parent is the main checkout. Read from the files
    rather than by running git, so a missing git or an odd layout only means no second place to
    look. **Only a shared directory named `.git` has a checkout for a parent**: a worktree of a bare
    repository, or of one made with `--separate-git-dir`, shares a directory somewhere else, whose
    parent is not a checkout at all, so there is no fallback there.
    """
    try:
        text = (root / ".git").read_text(encoding="utf-8").strip()
        if not text.startswith("gitdir:"):
            return None
        gitdir = Path(text.partition(":")[2].strip())
        if not gitdir.is_absolute():
            gitdir = root / gitdir
        common = (gitdir / (gitdir / "commondir").read_text(encoding="utf-8").strip()).resolve()
    except OSError:
        return None
    if common.name != ".git":
        return None
    main = common.parent
    return main if main.resolve() != root.resolve() else None


def env_or_dotenv(key: str, *, root: Path | None = None) -> str | None:
    """`key` from the process environment, falling back to a `.env` file at the repo root.

    The process environment always wins -- `.env` is a convenience for a shell that has not
    exported the variable, never a way to override one that has. In a linked worktree, which has
    no `.env` of its own unless one is put there, the main checkout's `.env` is read after the
    worktree's, so an agent working in a worktree finds the key the player keeps in the checkout.
    Callers never print what comes back; this only says whether a value was found.
    """
    value = os.environ.get(key)
    if value:
        return value
    here = root or _repo_root()
    for place in (here, _main_checkout(here)):
        if place is None:
            continue
        found = _parse_dotenv(place / ".env").get(key)
        if found:
            return found
    return None


# --------------------------------------------------------------------------------------- time ---


def round_to_hour(moment: datetime) -> datetime:
    """`moment`, in UTC, with minutes/seconds/microseconds zeroed -- the API asks for this."""
    if moment.tzinfo is None:
        moment = moment.replace(tzinfo=UTC)
    return moment.astimezone(UTC).replace(minute=0, second=0, microsecond=0)


def rfc3339(moment: datetime) -> str:
    if moment.tzinfo is None:
        moment = moment.replace(tzinfo=UTC)
    return moment.astimezone(UTC).strftime("%Y-%m-%dT%H:%M:%SZ")


def parse_moment(text: str) -> datetime:
    """A `--start`/`--end` value: a bare date or a full RFC3339 timestamp."""
    candidate = text.strip()
    if re.fullmatch(r"\d{4}-\d{2}-\d{2}", candidate):
        candidate += "T00:00:00+00:00"
    elif candidate.endswith("Z"):
        candidate = candidate[:-1] + "+00:00"
    try:
        moment = datetime.fromisoformat(candidate)
    except ValueError as exc:
        raise GoatCounterError(f"not a date/time: {text!r} (use YYYY-MM-DD or RFC3339)") from exc
    if moment.tzinfo is None:
        moment = moment.replace(tzinfo=UTC)
    return moment


# ---------------------------------------------------------------------------------- fetching ---


def require_https(site: str) -> None:
    """Refuses a site that is not an `https://` URL with a host: the key would travel in the clear."""
    parts = urllib.parse.urlsplit(site)
    if parts.scheme != "https" or not parts.netloc:
        raise GoatCounterError(
            f"the site must be an https:// URL, not {site!r} -- the API key would be sent in the clear"
        )


class _SameSiteRedirects(urllib.request.HTTPRedirectHandler):
    """Follows a redirect only within the request's own `https://` host.

    urllib's own handler copies every header but the content ones onto the redirected request,
    `Authorization` included, whatever host it points at; a redirect elsewhere, or down to
    `http://`, is refused instead of handing the key to it.
    """

    def redirect_request(
        self,
        req: urllib.request.Request,
        fp: Any,
        code: int,
        msg: str,
        headers: Any,
        newurl: str,
    ) -> urllib.request.Request | None:
        here = urllib.parse.urlsplit(req.full_url)
        there = urllib.parse.urlsplit(urllib.parse.urljoin(req.full_url, newurl))
        if there.scheme != "https" or there.netloc != here.netloc:
            raise GoatCounterError(
                f"GoatCounter redirected {here.netloc} to {there.scheme}://{there.netloc} (HTTP {code}); "
                "not following it with the API key"
            )
        return super().redirect_request(req, fp, code, msg, headers, newurl)


def _build_opener() -> urllib.request.OpenerDirector:
    # ssl.create_default_context() already honours the OpenSSL-level SSL_CERT_FILE/SSL_CERT_DIR
    # and the system trust store on its own; REQUESTS_CA_BUNDLE is not an OpenSSL variable, so it
    # is read explicitly here for a proxy whose CA bundle is only published under that name (see
    # this repo's own cloud-session proxy). HTTPS_PROXY itself needs no handling here --
    # urllib.request's default ProxyHandler, included by build_opener() with no arguments, already
    # reads it.
    cafile = os.environ.get("SSL_CERT_FILE") or os.environ.get("REQUESTS_CA_BUNDLE")
    context = ssl.create_default_context(cafile=cafile) if cafile else ssl.create_default_context()
    return urllib.request.build_opener(urllib.request.HTTPSHandler(context=context), _SameSiteRedirects())


def _is_transient(error: object) -> bool:
    """A dropped or timed-out connection, which a second try may get through (http.client's
    RemoteDisconnected is a ConnectionResetError)."""
    return isinstance(error, (ConnectionError, TimeoutError, http.client.HTTPException))


def _server_answer(exc: urllib.error.HTTPError) -> str:
    """The server's own words for an HTTP error, trimmed -- the body GoatCounter sends says what was wrong."""
    try:
        text = exc.read().decode("utf-8", "replace").strip()
    except OSError:
        text = ""
    return (text[:500] or exc.reason or "no message") if isinstance(text, str) else "no message"


def _get(opener: urllib.request.OpenerDirector, url: str, token: str, *, timeout: float = 20.0) -> dict[str, Any]:
    request = urllib.request.Request(url, headers={"Authorization": f"Bearer {token}", "Accept": "application/json"})
    attempt = 0
    while True:
        attempt += 1
        try:
            with opener.open(request, timeout=timeout) as response:
                body = response.read()
        except urllib.error.HTTPError as exc:
            if exc.code in (401, 403):
                raise GoatCounterHTTPError(
                    exc.code, f"GoatCounter rejected the API key (HTTP {exc.code}) -- check GOATCOUNTER_TOKEN"
                ) from exc
            if exc.code in (429, 502, 503, 504) and attempt <= MAX_RETRIES:
                time.sleep(RETRY_BACKOFF_SECONDS * attempt)
                continue
            raise GoatCounterHTTPError(
                exc.code, f"GoatCounter returned HTTP {exc.code} for {url.partition('?')[0]}: {_server_answer(exc)}"
            ) from exc
        except urllib.error.URLError as exc:
            if _is_transient(exc.reason) and attempt <= MAX_RETRIES:
                time.sleep(RETRY_BACKOFF_SECONDS * attempt)
                continue
            raise GoatCounterError(f"could not reach GoatCounter: {exc.reason}") from exc
        except OSError as exc:
            if _is_transient(exc) and attempt <= MAX_RETRIES:
                time.sleep(RETRY_BACKOFF_SECONDS * attempt)
                continue
            raise GoatCounterError(f"network error reaching GoatCounter: {exc}") from exc
        try:
            decoded: Any = json.loads(body.decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError) as exc:
            raise GoatCounterError(f"GoatCounter's response was not valid JSON: {exc}") from exc
        if not isinstance(decoded, dict):
            raise GoatCounterError("GoatCounter's response was not a JSON object")
        return decoded


def make_fetcher(site: str, token: str) -> Fetcher:
    base = site.rstrip("/") + "/stats/hits"
    opener = _build_opener()

    def fetch(params: dict[str, Any]) -> dict[str, Any]:
        # safe="," keeps the comma-joined exclude_paths at one byte a separator instead of three.
        query = urllib.parse.urlencode(params, doseq=True, safe=",")
        if len(query) > MAX_QUERY_BYTES:
            raise GoatCounterError(
                f"the query would be {len(query)} bytes (the server drops requests past ~32 KB); "
                "narrow the range with --days or --start/--end"
            )
        return _get(opener, f"{base}?{query}", token)

    return fetch


def fetch_hits(fetch: Fetcher, start: datetime, end: datetime, *, limit: int = PAGE_LIMIT) -> list[dict[str, Any]]:
    """Every hit in `[start, end]`, paginated with one comma-joined `exclude_paths` while `more` holds."""
    hits: list[dict[str, Any]] = []
    exclude: list[str] = []
    seen: set[str] = set()
    while True:
        params: dict[str, Any] = {"start": rfc3339(start), "end": rfc3339(end), "limit": limit}
        if exclude:
            # One comma-separated value: the server reads only the first of a repeated parameter.
            params["exclude_paths"] = ",".join(exclude)
        page = fetch(params)
        page_hits = page.get("hits")
        if not isinstance(page_hits, list):
            raise GoatCounterError("GoatCounter's response had no 'hits' list")
        # A path already seen is never counted twice, whatever the server sends.
        fresh = [h for h in page_hits if not (isinstance(h, dict) and str(h.get("path_id")) in seen)]
        hits.extend(fresh)
        new_ids = [str(hit["path_id"]) for hit in fresh if isinstance(hit, dict) and "path_id" in hit]
        seen.update(new_ids)
        more = bool(page.get("more"))
        # Paging works by excluding the paths already read, so a page of hits that carry no
        # `path_id` cannot be paged past: stopping there would quietly cut the range short.
        if more and page_hits and not any(isinstance(h, dict) and "path_id" in h for h in page_hits):
            raise GoatCounterError(
                "GoatCounter said there were more hits, but none on the page had a 'path_id' to "
                "page past; the counts would be incomplete"
            )
        # A server claiming more with nothing new to exclude would otherwise loop forever asking
        # the same question; stop rather than trust that half of the contract blindly.
        if not more or not new_ids:
            break
        exclude.extend(new_ids)
    return hits


def fetch_me(site: str, token: str) -> dict[str, Any]:
    """`GET /api/v0/me` -- the token's own name and permissions, optional extra information on top
    of what `check_key` already proved; see `check_key`, which calls this second and tolerates a
    403/404 here.
    """
    opener = _build_opener()
    return _get(opener, site.rstrip("/") + "/me", token)


def fetch_stats_total(site: str, token: str, start: datetime, end: datetime) -> dict[str, Any]:
    """`GET /api/v0/stats/total` -- needs only "Read statistics", the one permission every
    read-only key has, so `check_key` uses it as the actual proof that the key works.
    """
    opener = _build_opener()
    query = urllib.parse.urlencode({"start": rfc3339(start), "end": rfc3339(end)})
    return _get(opener, f"{site.rstrip('/')}/stats/total?{query}", token)


def check_key(
    site: str,
    token: str,
    *,
    now: datetime | None = None,
    stats_fetch: Callable[[str, str, datetime, datetime], dict[str, Any]] | None = None,
    me_fetch: Callable[[str, str], dict[str, Any]] | None = None,
) -> dict[str, Any]:
    """Prove `token` works and say what it can do, without ever handling or printing the key itself.

    `GET /api/v0/stats/total` for the last hour is the proof -- it needs only "Read statistics",
    the one permission every read-only key has, so a failure there (401/403, or a network error)
    is the real "this key does not work" and is left to raise. `GET /api/v0/me` is tried next for
    the token's own name and permissions, which is optional extra information: a 403 or 404 there
    does not fail the check -- only reduces what it can report, because the statistics call already
    proved the key works.

    `stats_fetch`/`me_fetch` default to the real network calls; a test passes fakes instead. The
    defaults are looked up here rather than bound at definition time, so a test that patches
    `fetch_stats_total`/`fetch_me` on the module (as it would any other network call) is honoured
    even when a caller does not pass them explicitly.
    """
    stats_fetch = stats_fetch or fetch_stats_total
    me_fetch = me_fetch or fetch_me
    end = round_to_hour(now or datetime.now(UTC))
    start = end - timedelta(hours=1)
    stats_fetch(site, token, start, end)

    try:
        me = me_fetch(site, token)
    except GoatCounterHTTPError as exc:
        if exc.status in (403, 404):
            note = (
                f"permission list could not be read (GET /api/v0/me answered HTTP {exc.status}); "
                "the key still reads statistics"
            )
        else:
            note = f"permission list could not be checked: {exc}"
        return {"ok": True, "reads_statistics": True, "permissions_available": False, "note": note}

    token_info = me.get("token")
    token_info = token_info if isinstance(token_info, dict) else {}
    return {
        "ok": True,
        "reads_statistics": True,
        "permissions_available": True,
        "name": token_info.get("name"),
        "permissions": token_info.get("permissions"),
        "sites": token_info.get("sites"),
    }


# ---------------------------------------------------------------------------------- grouping ---


class Classified(NamedTuple):
    """One name's shape: `kind` is "run", "day" or "other"; `day`/`rest` are set only for "day"."""

    kind: str
    name: str
    day: int | None = None
    rest: str | None = None


def classify(name: str) -> Classified:
    """`name` with the prefix already stripped, sorted into the shape it matches."""
    for run_prefix in RUN_LEVEL_PREFIXES:
        if name.startswith(run_prefix):
            return Classified("run", name)
    match = DAY_RE.match(name)
    if match:
        return Classified("day", name, int(match.group(1)), match.group(2))
    return Classified("other", name)


def group_hits(hits: list[dict[str, Any]], prefix: str) -> dict[str, Any]:
    """`hits` (the API's own shape) filtered to `prefix` and grouped run-level / by day / other."""
    run_level: dict[str, int] = {}
    days: dict[int, dict[str, int]] = {}
    other: dict[str, int] = {}
    for hit in hits:
        path = hit.get("path")
        count = hit.get("count")
        if not isinstance(path, str) or not path.startswith(prefix) or not isinstance(count, int):
            continue
        name = path[len(prefix) :]
        kind = classify(name)
        if kind.kind == "run":
            run_level[kind.name] = run_level.get(kind.name, 0) + count
        elif kind.kind == "day":
            assert kind.day is not None and kind.rest is not None
            bucket = days.setdefault(kind.day, {})
            bucket[kind.rest] = bucket.get(kind.rest, 0) + count
        else:
            other[kind.name] = other.get(kind.name, 0) + count
    return {"run_level": run_level, "days": days, "other": other}


def to_jsonable(grouped: dict[str, Any]) -> dict[str, Any]:
    return {
        "run_level": dict(grouped["run_level"]),
        "days": {str(day): dict(bucket) for day, bucket in sorted(grouped["days"].items())},
        "other": dict(grouped["other"]),
    }


def _sorted_desc(items: dict[str, int]) -> list[tuple[str, int]]:
    # Count descending, name as the tiebreak, so two runs of the same input print in the same order.
    return sorted(items.items(), key=lambda pair: (-pair[1], pair[0]))


def _pct_suffix(count: int, began: int | None) -> str:
    """`count` as "(N.N% of began)", or "" when the day carries no began count to divide by."""
    return f" ({count / began * 100:.1f}% of began)" if began else ""


class SplitLosses(NamedTuple):
    """A day's bucket, split into its losses: `totals` is the subtotal per kind
    (crying/hard-fail/timeout), `causes` is the per-cause count under each kind (empty for a kind
    whose only hits were the old, causeless shape), and `consumed` is every bucket key already
    accounted for, so the caller's own leftover pass does not print one of them a second time.
    """

    totals: dict[str, int]
    causes: dict[str, dict[str, int]]
    consumed: set[str]


def split_losses(bucket: dict[str, int]) -> SplitLosses:
    """`bucket`'s own `lost-*` keys, split by `LOST_RE` into a subtotal per kind and the per-cause
    counts under it. The old two-event shape's bare `lost-crying` / `lost-hard-fail` (no cause --
    one playthrough, from before VisitCounter folded the cause on) matches with no cause group, so
    it folds into the kind's subtotal with no cause line of its own -- "still listed" without
    needing a second rule.
    """
    totals: dict[str, int] = {}
    causes: dict[str, dict[str, int]] = {}
    consumed: set[str] = set()
    for name, count in bucket.items():
        match = LOST_RE.match(name)
        if not match:
            continue
        kind, cause = match.group(1), match.group(2)
        totals[kind] = totals.get(kind, 0) + count
        if cause:
            causes.setdefault(kind, {})
            causes[kind][cause] = causes[kind].get(cause, 0) + count
        consumed.add(name)
    return SplitLosses(totals, causes, consumed)


def format_text(grouped: dict[str, Any], *, site: str, start: datetime, end: datetime, prefix: str) -> str:
    lines = [f"GoatCounter events for {site} -- {rfc3339(start)} to {rfc3339(end)} (prefix {prefix!r})"]
    lines.append(
        "Counts are attempts, not visitors -- every event opts out of the site's sessions, so it counts "
        "every time it was sent, and a day's began includes every retry of it. The page visit, counted "
        "once per visitor, is under --raw."
    )

    run_level: dict[str, int] = grouped["run_level"]
    lines.append("")
    lines.append("Run-level:")
    if run_level:
        for name, count in _sorted_desc(run_level):
            lines.append(f"  {prefix}{name}: {count}")
    else:
        lines.append("  (none)")

    days: dict[int, dict[str, int]] = grouped["days"]
    for day in sorted(days):
        bucket = days[day]
        lines.append("")
        lines.append(f"Day {day}:")
        began = bucket.get("began")
        if began is not None:
            lines.append(f"  {prefix}day-{day}-began: {began}")

        totals, causes, consumed = split_losses(bucket)
        lost_total = sum(totals.values())
        rest = {name: count for name, count in bucket.items() if name != "began" and name not in consumed}
        # "lost" is a synthetic heading, not a real path GoatCounter ever sent -- it stands in for
        # every lost-* key folded under it, sorted into the same count-descending order as won and
        # everything else the day sent.
        display: dict[str, int] = dict(rest)
        if lost_total:
            display["lost"] = lost_total
        for name, count in _sorted_desc(display):
            if name != "lost":
                lines.append(f"  {prefix}day-{day}-{name}: {count}{_pct_suffix(count, began)}")
                continue
            lines.append(f"  Lost: {lost_total}{_pct_suffix(lost_total, began)}")
            for kind, kind_count in _sorted_desc(totals):
                lines.append(f"    {prefix}day-{day}-lost-{kind}: {kind_count}{_pct_suffix(kind_count, began)}")
                for cause, cause_count in _sorted_desc(causes.get(kind, {})):
                    suffix = _pct_suffix(cause_count, began)
                    lines.append(f"      {prefix}day-{day}-lost-{kind}-{cause}: {cause_count}{suffix}")

    other: dict[str, int] = grouped["other"]
    if other:
        lines.append("")
        lines.append("Matches the prefix but none of the known shapes:")
        for name, count in _sorted_desc(other):
            lines.append(f"  {prefix}{name}: {count}")

    return "\n".join(lines)


def encounter_table(grouped: dict[str, Any]) -> dict[str, Any]:
    """`grouped`'s encounter names as counts per event type: `overall` summed over every day, and
    `days` per day, each event's `seen`, `influenced` and `influenced-unseen` (zero when absent) and
    `ratio`, influenced / seen, or None when nothing was seen."""
    overall: dict[str, dict[str, int]] = {}
    days: dict[int, dict[str, dict[str, int]]] = {}
    for day, bucket in grouped["days"].items():
        for name, count in bucket.items():
            match = ENCOUNTER_RE.match(name)
            if not match or name in NOT_ENCOUNTERS:
                continue
            column, event = match.group(1), match.group(2)
            for table in (overall, days.setdefault(day, {})):
                row = table.setdefault(event, dict.fromkeys(ENCOUNTER_COLUMNS, 0))
                row[column] += count
    return {"overall": _with_ratios(overall), "days": {day: _with_ratios(days[day]) for day in sorted(days)}}


def _with_ratios(table: dict[str, dict[str, int]]) -> dict[str, dict[str, Any]]:
    rows: dict[str, dict[str, Any]] = {}
    for event in sorted(table):
        row: dict[str, Any] = dict(table[event])
        row["ratio"] = row["influenced"] / row["seen"] if row["seen"] else None
        rows[event] = row
    return rows


def encounters_jsonable(table: dict[str, Any]) -> dict[str, Any]:
    return {"overall": table["overall"], "days": {str(day): rows for day, rows in table["days"].items()}}


def _encounter_lines(rows: dict[str, dict[str, Any]]) -> list[str]:
    if not rows:
        return ["  (none)"]
    width = max(len("event"), *(len(event) for event in rows))
    lines = [f"  {'event':<{width}}  {'seen':>6}  {'influenced':>10}  {'ratio':>5}  {'unseen':>6}"]
    # Most seen first, the name as the tiebreak, so two runs of the same input print the same order.
    for event, row in sorted(rows.items(), key=lambda pair: (-pair[1]["seen"], pair[0])):
        ratio = f"{row['ratio']:.2f}" if row["ratio"] is not None else ""
        lines.append(
            f"  {event:<{width}}  {row['seen']:>6}  {row['influenced']:>10}  {ratio:>5}  {row['influenced-unseen']:>6}"
        )
    return lines


def format_encounters(table: dict[str, Any], *, site: str, start: datetime, end: datetime, prefix: str) -> str:
    lines = [f"GoatCounter encounters for {site} -- {rfc3339(start)} to {rfc3339(end)} (prefix {prefix!r})"]
    lines.append(
        "Per event type: encounters seen, how many of those influenced her, influenced / seen (blank when "
        "nothing was seen), and the influences from encounters she never saw (unseen), which the ratio "
        "leaves out."
    )
    lines.append("")
    lines.append("Overall:")
    lines.extend(_encounter_lines(table["overall"]))
    for day, rows in table["days"].items():
        lines.append("")
        lines.append(f"Day {day}:")
        lines.extend(_encounter_lines(rows))
    return "\n".join(lines)


def format_check(result: dict[str, Any], *, site: str) -> str:
    lines = [f"GoatCounter key for {site} reads statistics -- it works."]
    if result.get("permissions_available"):
        name = result.get("name") or "(unnamed)"
        lines.append(f"Token {name!r} -- permissions {result.get('permissions')!r}, sites {result.get('sites')!r}.")
    else:
        lines.append(f"Its {result.get('note')}.")
    return "\n".join(lines)


def format_raw(hits: list[dict[str, Any]], *, site: str, start: datetime, end: datetime) -> str:
    lines = [f"GoatCounter paths for {site} -- {rfc3339(start)} to {rfc3339(end)} (every path, unfiltered)"]
    lines.append("")
    if not hits:
        lines.append("(no hits in range)")
        return "\n".join(lines)
    for entry in sorted(hits, key=lambda h: (-(h.get("count") or 0), str(h.get("path")))):
        kind = "event" if entry.get("event") else "page"
        lines.append(f"  [{kind}] {entry.get('path')}: {entry.get('count')}")
    return "\n".join(lines)


def to_raw_jsonable(hits: list[dict[str, Any]]) -> list[dict[str, Any]]:
    return [{"path": h.get("path"), "count": h.get("count"), "event": bool(h.get("event"))} for h in hits]


# --------------------------------------------------------------------------------------- CLI ---


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument(
        "--days", type=int, default=None, help=f"how many days back from --end to start (default {DEFAULT_DAYS})"
    )
    parser.add_argument(
        "--start", type=str, default=None, help="range start, YYYY-MM-DD or RFC3339 (default: --end minus --days)"
    )
    parser.add_argument("--end", type=str, default=None, help="range end, YYYY-MM-DD or RFC3339 (default: now)")
    parser.add_argument(
        "--prefix", type=str, default=DEFAULT_PREFIX, help=f"event path prefix to read (default {DEFAULT_PREFIX!r})"
    )
    parser.add_argument(
        "--site",
        type=str,
        default=None,
        help=f"GoatCounter API base URL (default {DEFAULT_SITE}, or $GOATCOUNTER_SITE)",
    )
    parser.add_argument("--json", action="store_true", help="print the result as JSON instead of plain text")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument(
        "--raw",
        action="store_true",
        help="print every path and its count for the range, unfiltered by --prefix -- events and the page visit alike",
    )
    mode.add_argument(
        "--encounters",
        action="store_true",
        help=(
            "print seen, influenced, influenced / seen and unseen influences per event type, overall and "
            "per day, instead of the funnel"
        ),
    )
    mode.add_argument(
        "--check",
        action="store_true",
        help=(
            "prove the key reads statistics (GET /api/v0/stats/total) and report its permissions "
            "if GET /api/v0/me allows it -- never the key"
        ),
    )
    return parser


def resolve_range(args: argparse.Namespace) -> tuple[datetime, datetime]:
    end = round_to_hour(parse_moment(args.end)) if args.end else round_to_hour(datetime.now(UTC))
    if args.start:
        start = round_to_hour(parse_moment(args.start))
    else:
        days = args.days if args.days is not None else DEFAULT_DAYS
        start = end - timedelta(days=days)
    return start, end


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)

    if args.days is not None and args.days <= 0:
        print("goatcounter: --days must be a positive number of days", file=sys.stderr)
        return 2

    site = args.site or env_or_dotenv("GOATCOUNTER_SITE") or DEFAULT_SITE
    try:
        require_https(site)
    except GoatCounterError as exc:
        print(f"goatcounter: {exc}", file=sys.stderr)
        return 2

    # The key check happens before any network call, on purpose -- see the module docstring and
    # M209's brief. GOATCOUNTER_TOKEN is never accepted as a flag: a flag lands in shell history
    # and process listings, an environment variable does not print itself by accident.
    token = env_or_dotenv("GOATCOUNTER_TOKEN")
    if not token:
        print(
            "goatcounter: GOATCOUNTER_TOKEN is not set. Create a read-only API key on the "
            "GoatCounter site's own Settings -> API page, then either export it --\n"
            "  export GOATCOUNTER_TOKEN=...\n"
            "-- or put it in a .env file at the repository root (GOATCOUNTER_TOKEN=...). "
            "It is never accepted as a command-line flag.",
            file=sys.stderr,
        )
        return 1

    if args.check:
        try:
            result = check_key(site, token)
        except GoatCounterError as exc:
            print(f"goatcounter: {exc}", file=sys.stderr)
            return 1
        if args.json:
            print(json.dumps(result, indent=2, sort_keys=True))
        else:
            print(format_check(result, site=site))
        return 0

    try:
        start, end = resolve_range(args)
    except GoatCounterError as exc:
        print(f"goatcounter: {exc}", file=sys.stderr)
        return 2

    try:
        hits = fetch_hits(make_fetcher(site, token), start, end)
    except GoatCounterError as exc:
        print(f"goatcounter: {exc}", file=sys.stderr)
        return 1

    if args.raw:
        if args.json:
            print(json.dumps(to_raw_jsonable(hits), indent=2, sort_keys=True))
        else:
            print(format_raw(hits, site=site, start=start, end=end))
        return 0

    grouped = group_hits(hits, args.prefix)
    if args.encounters:
        table = encounter_table(grouped)
        if args.json:
            print(json.dumps(encounters_jsonable(table), indent=2, sort_keys=True))
        else:
            print(format_encounters(table, site=site, start=start, end=end, prefix=args.prefix))
        return 0
    if args.json:
        print(json.dumps(to_jsonable(grouped), indent=2, sort_keys=True))
    else:
        print(format_text(grouped, site=site, start=start, end=end, prefix=args.prefix))
    return 0


if __name__ == "__main__":
    sys.exit(main())
