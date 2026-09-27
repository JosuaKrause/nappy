**Neither the halo nor the meter has been reproduced on the released page, and the one build every
sighting happens on has not itself been tried yet.** "The yeller has no effect on the meter and its
halo doesn't even turn on" ([PLAYTEST-140](../../playtests/PLAYTEST-140.md), statement 4) and "the
man shouting charges nothing on an ordinary day, not only on the day of the note"
([PLAYTEST-144](../../playtests/PLAYTEST-144.md), statement 21) are both still open — a bare
`EventInstance`, a real `City` + `EventManager` stream on five seeds, and a full boot of the game
walking toward a live instance all charge and light him correctly, but every one of those is native
or headless, while every sighting (both playtests above, plus the released-page stills in
`docs/evidence/playtest-144-phone-v0.18.0-2026-09-26/`) is on the Web export. See
[2026-09-25-M205-2.md](../../decisions/2026-09-25-M205-2.md) for what was tried, including the two
candidates the player's own stills already rule out.

**Next step:** a local *release* Web export (the kind CI publishes, not a debug export served
locally) walked beside a live `homeless_yeller`, reading his `contribution_at()`,
`ExcitementHalo.select_sources()` and the meter's own rate in the browser while it happens.
