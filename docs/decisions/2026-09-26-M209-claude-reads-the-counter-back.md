## M209 — Claude reads the counter back · built 2026-09-26

*([PLAYTEST-141](../playtests/PLAYTEST-141.md): "how can I make claude be able to see values from
goatcounter"; "make it so the interaction with the API happens via script not directly".)*

**What is built.** `tools/goatcounter.sh` (with `tools/goatcounter.py`) pages GoatCounter's read
API, `GET /api/v0/stats/hits` on `https://josuakrause.goatcounter.com/api/v0/`, and prints the
`nappy-` events as a per-day funnel: run-level events first, then each day with `began` at the top
and every other count as a share of it, and any name of an unknown shape listed at the end. A line
under the header says the counts are visitors, not attempts, because the API's `count` is
visitors. `--json` prints the same grouping, `--raw` every path's count, and `--check` proves the
key with `GET /api/v0/stats/total` before asking `GET /api/v0/me` for its permissions. The key is
`GOATCOUNTER_TOKEN`, from the environment or a git-ignored `.env` at the repository root, never a
flag. The using-tools catalogue says the API is reached only through this script.

**Measured against the live account** with the player's statistics-only key, from another session:
the funnel printed the last 30 days (two fresh runs, both ending badly, one reaching day 7).
`--check` first failed with HTTP 404 on `/api/v0/me`, asked before the funnel while the key was
minutes old and most likely not yet propagated; it now proves the key through the statistics
endpoint and reports a refused `/me` instead of failing. On 2026-09-26 the same key passed the
fixed `--check`, `/me` included (token `claude`, permissions `65`, sites `[-1]`).

**Choices left open to overturn**: `--raw` ignores `--prefix`; `began`'s own line shows no share;
a 429 is retried up to five times with backoff and a 401 or 403 is not; `--check` prints
permissions as the API returns them.

**Superseded in part** by [M225](2026-09-26-M225.md): the game's events now go to `nappy.goatcounter.com`, which `tools/goatcounter.py` reads by default, and the header says the counts are attempts, not visitors.
