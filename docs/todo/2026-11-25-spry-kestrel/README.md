priority: now

# spry-kestrel — A flag to see the escape building's window flashes with and without a least gap · filed 2026-11-25

**The ask.** The player asked to see the escape building's window flashes with and without a least gap
before judging it (their board answer on building-flash-limit, inbox #1787 in gentle-beaver). Their earlier words ask the flashes to match the
apartment building's (minty-lemur #785). Today `FlashRhythm.LEAST_GAP` (0.4 s) applies to the city only;
the building keeps the player's own timing, where 6.3% of 20,000 simulated walks hold four flashes in a
second (`tools/decisions.sh snowy-goose`).

**What a builder does.** Build a dev flag that sets the least gap between the building's flashes (for
instance `--building-flash-gap S` on the command line and `?debug=1&buildingflashgap=S` on the web, 0
meaning none), under **cli-tools** (help, rejection of bad input, one place the flag list lives), and a
Review-tab item (`tools/new-name.sh review --entry <name>`) with the command to play:
`tools/run.sh --seed 4242 --start-escape` with the gap on and off. The question the run answers is
whether the building keeps its own curve or takes the city's limit. The default stays the player's own
timing until they answer.

**Proposed, not asked for:** the flag's name and its web twin, and the band `now` (the filer's
proposals).
