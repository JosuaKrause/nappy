**`tools/goatcounter.sh --by-release` groups the counts into one window per release.** It reads the
release tags (`v*`) and their dates from git, and sums the daily counts it already fetches into a
window per release, from that release's day up to the next one's. A day on which two or more
releases went out is shown as mixed, carrying every release of that day, rather than split between
them ("mixing releases is fine"). It works with the funnel and with `--encounters` alike, and on past
data, since it needs nothing the page does not already send.

It follows **cli-tools** (help on `--help` and `-h`, an unknown flag rejected before any work starts)
and `tools/goatcounter.py`'s own rules, and its row in the **using-tools** catalogue is updated in the
same commit. `tools/test_goatcounter.py` covers the grouping, a mixed day included, with no network.
