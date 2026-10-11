priority: next

# spotted-badger — GoatCounter counts grouped by release · filed 2026-10-11

[minty-marmot](../../playtests/2026-10-11-minty-marmot.md), #706:

> when analyzing goatcounter stats can we build tooling to correlate it with releases?

Asked to choose between grouping the daily counts by the releases' dates (A) and having the page
send its version with its events (B):

> A is the right choice. mixing releases is fine. in the future we will have slower release cadence

*The band is the filer's proposal:* the note names none and is not from playing.

**What exists.** `tools/goatcounter.sh` (`tools/goatcounter.py`) is the only way the repository reads
GoatCounter. It prints the `nappy-` event counts as a per-day funnel, or per event type and day with
`--encounters`. The page's events (`VisitCounter`, `src/autoload/visit_counter.gd`) carry no build
version, and nothing in the game changes for this entry: B was not chosen.

The work is [counts-by-release.md](counts-by-release.md).
