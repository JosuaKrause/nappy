# downy-lemur — The GoatCounter report describes and flags nothing · 2026-10-19


`tools/goatcounter.sh --report` printed a "Walls" section: days whose win rate fell
`WALL_RATE_MARGIN` under the median of the sampled days, and causes ending at least
`WALL_CAUSE_SHARE` (25%) of a day's attempts. The margin was lowered from 15 to 10 points in PR
#811's review so that days 6 and 7, which the orchestrator had already found by hand
(`docs/stats/2026-10-19-goatcounter.md`), would be flagged, and a test pinned exactly those days:
the tool was fitted to the conclusion it was meant to help reach. The player, told so on
2026-10-19: "let's not bias the analysis -- those findings might be relevant now but the next time
might have a different focus. let's not blind ourself to that", and agreed that the report should
describe rather than conclude (PR #814).

**Built.** The Walls section, `WALL_RATE_MARGIN`, `WALL_CAUSE_SHARE` and the median printed for them
are gone from every form of `--report` (text, `--markdown`, `--json`, `--by-release`). The per-day
table keeps attempts, wins, win rate, lost and the crying, hard-fail and timeout split; its top-two
causes column is replaced by "Causes per day", every cause of every day biggest first with its share
of that day's attempts (inline on the `--by-release` lines, and the full sorted list in `--json`).
`MIN_ATTEMPTS` stays only as the `(low-sample)` mark, a note on how far a number can be trusted, and
excludes nothing. The real-data test is a fixture of the table's numbers, not of which days stand
out. The `--help` text and the **using-tools** row say that the report flags nothing and that the
reading is written by hand each time, from the whole report, with no focus carried over from the
last read.

**Choices made where the design was silent, open to overturn:** days stay in day order and causes
are sorted by size; the `--by-release` lines carry the full cause list inline.
