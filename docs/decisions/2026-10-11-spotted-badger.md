# spotted-badger — GoatCounter counts grouped by release · 2026-10-11

[minty-marmot](../playtests/2026-10-11-minty-marmot.md), #706: "when analyzing goatcounter stats can
we build tooling to correlate it with releases?"; offered grouping by the releases' dates or the page
sending its version: "A is the right choice. mixing releases is fine. in the future we will have
slower release cadence".

**What is built.** `tools/goatcounter.sh --by-release` prints the funnel, or with `--encounters` the
encounters, once per release window, and with `--json` a `windows` list. The windows come from the
`v*` tags in git: each runs from a release's day up to the next release's day, and a day with two or
more releases is one window labelled `mixed day: v1, v2`, never split. `--by-release` with `--raw` or
`--check`, or in a repository with no `v*` tag, is refused before any network call. Each window is
its own `stats/hits` read, so its counts are exact. `tools/test_goatcounter.py` covers the windows
and both modes without the network; the using-tools catalogue and `docs/TELEMETRY.md` describe the
flag. Nothing in the game changed: the page's events still carry no version.

*Chosen by the implementer, open to overturn:*
- A tag's date is git's `creatordate` (the tagger date of an annotated tag), compared in UTC like
  every range the tool sends, so a tag made late in the evening west of UTC falls on the next day.
- The days before the first release form their own window, `before the first release`; the release
  in force when a range opens keeps its window, clipped to the range's start.
- The entry said the windows would sum daily counts the tool already fetched; the tool fetches one
  total per range, so it makes one read per window instead, more requests in exchange for exact
  counts without relying on the API's per-day shape.
