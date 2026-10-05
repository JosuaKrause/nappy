# pebbly-pelican — tools/goatcounter.sh pages with one comma-joined exclude list · 2026-10-05 · not from an entry


Inbox #595, said in a session on 2026-10-05: "looks like you need to fix goatcounter." What had
failed: `tools/goatcounter.sh --check` worked with the `.env` key, but `--raw` and the per-day
funnel over 30 and 60 days ended with "network error reaching GoatCounter: Remote end closed
connection without response".

**The cause, reproduced against the live API.** GoatCounter's `/api/v0/stats/hits` honours only the
first of a repeated `exclude_paths` parameter. The tool paged by sending one `exclude_paths=<id>`
per path already seen, so every page returned mostly the same hits again — a 7-day range came back
as 1400 hits over only 101 distinct paths, and larger ranges counted the same paths more than once
— and the query grew about 24 bytes per path until, past about 32 KB, the server closed the
connection (31,269 bytes answered, 33,669 closed, on the fourteenth page). A comma-joined
`exclude_paths=1,2,3` excludes them all: the same range took two pages and returned 128 paths.

**Fixed** in `tools/goatcounter.py`: the paths seen go in one comma-joined `exclude_paths`; a path
already seen is never counted twice; a query that would pass 30 KB is refused with a message to
narrow the range; a dropped connection, a 429 and a 502, 503 or 504 are retried with backoff; an
HTTP error prints the server's own answer without the query string. `tools/test_goatcounter.py`
covers each on canned responses. Counts read before this fix over more than one page were inflated.

**What it read.** Over 2026-09-05 to 2026-10-05: `poster-torn` on day 4 once, day 6 three times and
day 9 once; `poster-pursuit` never, nor in 90 days. Five tears, the run's first always safe and one
in ten after it a pursuit, make about 0.4 pursuits expected, so none is what the bag predicts. No
encounter events yet over 90 days: the counter that sends them (spry-llama) shipped with v0.25.3 on
2026-10-05.
