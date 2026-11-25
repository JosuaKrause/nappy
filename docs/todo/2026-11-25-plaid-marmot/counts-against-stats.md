**Open: whether GoatCounter's counts of a release that carries the refactor match the ones in
`docs/stats/`.** `tools/goatcounter.sh --by-release` groups the funnel into one window per
release, and `--encounters --by-release` the encounters; `docs/stats/2026-10-19-goatcounter.md` and
`docs/stats/2026-10-24-goatcounter.md` are the earlier readings to set them against. The remeasure
already compared the names the game sends (the record minty-quail-cozy-rabbit: the day-14 blackout
name became `nappy-day-16-blackout`, the building and the city count as days 15 and 16, every other
sent list is equal); what is left is the counts, which move with the player's play as much as with
the code, so a difference is listed and not judged. It needs the read-only `GOATCOUNTER_TOKEN`
(`tools/goatcounter.sh --help`).
