# downy-lemur — GoatCounter analysis is one command, tools/goatcounter.sh --report, and the tool knows every shape the doc lists · 2026-10-19 · not from an entry


Not from an entry. After the orchestrator analyzed thirty days of GoatCounter by hand on 2026-10-19,
the player asked: "how can we systematize analyzing stats? also let's fix the tooling" (PR #811). The
hand analysis itself is `docs/stats/2026-10-19-goatcounter.md`.

**Built.** `tools/goatcounter.sh --report` prints that analysis on one page: visitors (hits on
`/nappy.josuakrause.com`), fresh and resumed runs, controls, mode, endings, the escape and
checkpoints (grouped by the day they came from); a per-day table of attempts, wins, win rate, the
crying, hard-fail and timeout split and the two largest causes with their share; cause totals,
crying and hard fails apart; and the walls, with the caveats and thresholds printed. The thresholds
are named constants: `MIN_ATTEMPTS` (20), `WALL_RATE_MARGIN` (0.10) and `WALL_CAUSE_SHARE` (0.25).
`--report --by-release` gives the per-day win rates and walls per release window, `--json` the same
data, and `--markdown` the report as Markdown, which is how a read worth keeping becomes a file under
`docs/stats/` (the **using-tools** row says when: before changing a balance number or a danger, after
a release once its window has runs, and when the player asks).

**The gaps fixed.** `nappy-mode-*` and `nappy-checkpoint-N-from-day-M` were printed as unknown
shapes; they are run-level shapes now, and a test parses every backticked `nappy-` name in
`docs/TELEMETRY.md`'s event bullets and asserts each classifies to a known shape (it also asserts it
found more than 25 names, so a change in the doc's format fails rather than passes empty). A `GET
/stats/hits` that answered HTTP 404 once and worked a minute later could not be reproduced and no
cause was found (no page cursor, cold cache or path id), so a 404 there is retried like a 429, up to
five times with backoff, each retry printed; `/me` keeps its 404, which `--check` relies on. A final
failure prints the status and the page's own sentence, not the HTML. `--site` reaches the API with
or without a trailing slash and `/api/v0`, and a 401 says a key belongs to one site.

**Choices made where the design was silent, open to overturn:** a day under 20 attempts is printed
and marked low-sample but left out of the median and the walls; a timeout counts as a cause; "well
below the median" is 10 points absolute; the old causeless `lost-crying` and `lost-hard-fail` count in
the loss split with no cause.
