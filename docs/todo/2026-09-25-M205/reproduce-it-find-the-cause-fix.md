**Neither the halo nor the meter has been reproduced on the released page, and the one build every
sighting happens on has not itself been tried yet.** "The yeller has no effect on the meter and its
halo doesn't even turn on" ([PLAYTEST-140](../../playtests/PLAYTEST-140.md), statement 4) and, in
the player's own words, "No the yeller had no effect on a regular day"
([PLAYTEST-144](../../playtests/PLAYTEST-144.md), statement 21) are both still open, alongside two
more sightings from the same playtest's phone and desktop-Chrome stills: statement 24, no halo and
no meter movement on the phone, and statement 27, no halo in this Mac's own desktop Chrome either.
A bare `EventInstance`, a real `City` + `EventManager` stream on five seeds, and a full boot of the
game walking toward a live instance all charge and light him correctly, but every one of those is
native or headless, while every sighting (both playtests above, plus the released-page stills in
`docs/evidence/playtest-144-phone-v0.18.0-2026-09-26/`) is on the Web export. See
[2026-09-25-M205-2.md](../../decisions/2026-09-25-M205-2.md) for what was tried, including the two
candidates the player's own stills already rule out.

**Next step, runnable as written:** `tools/export-web.sh` with no argument (a release export, the
kind CI publishes) builds `build/web/`; `cd build/web && python3 -m http.server 8060` serves it —
the same command `tools/serve-web.sh` runs, so no COOP/COEP headers are needed (its preset has
threads off); then open `http://localhost:8060/index.html?debug=1` — a release export answers the
dev-flag query only with `?debug=1` present (`tools/serve-web.sh --help`). Walk beside a live
`homeless_yeller` there, reading his `contribution_at()`, `ExcitementHalo.select_sources()` and the
meter's own rate in the browser while it happens.
