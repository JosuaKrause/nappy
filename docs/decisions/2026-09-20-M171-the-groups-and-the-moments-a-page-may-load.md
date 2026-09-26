## M171, the groups and the moments a page may load — built 2026-09-20

Pull request #252, the other half of [PLAYTEST-109](../playtests/PLAYTEST-109.md)'s notes.

**The groups.** *"putting both genders in the player atlas is a bit wasteful since it's
guaranteed to not use half of it."* `stroller` became three: `mother` and `father`, thirty
views each, and `stroller`, the five pram views, which are the only pictures the two share. A
run holds the pram's page and its own parent's; the other parent's is never loaded. *"the UI
and head indicators could be combined."* The five head indicators are on `ui`'s page. The
membership's note that they were apart "because the marks above her head are drawn by a
separate pass and tinted on their own" described nothing a page decides: the tint is a colour
at the draw call and the pass is an order of calls.

**The moments.** *"we cannot start loading something in the frame we need it"* · *"we probably
could preload everything. or at least load everything needed for a day during the day brief.
and everything that might always be needed at startup"* · *"don't unload anything that might
be needed in one day and in the next."* `main.gd` holds every page a day draws from boot, for
the life of the process — `RESIDENT_GROUPS`: `ui`, `stroller`, `buildings`, `street_kit`,
`ground`, `decoration`, `crowd` — and the run's parent beside them, which is known at boot on
every path: `GameState.start_run()` rolls it and a resumed run reads it off the save before the
city is built. A held restart reloads the scene in the same process and rerolls the parent, so
the boot drops the other parent's page when it takes its own. The day brief opens a second
window and loads nothing today. `events` is not held, since nothing draws from that page until
the events move. **Measured:** eight pages in 7 to 12 ms over six headless boots and 9 ms
windowed, beside a city generated in over 400 ms, so the fallback — the day's pages in the day
brief — was not needed.

**The interior is the escape's alone.** *"what do you mean interiors need to be loaded? this
is only needed in the escape day brief (which is still not implemented I gather?)"* The
`--start-escape` boot holds it, 4 ms; when M102, the finale, has a brief, the call moves there.

**The rule.** `AtlasLibrary` is unmanaged until a boot claims the loading moments; after that a
page read from disk with no window open is logged as `OUTSIDE` and raises an engine error,
which the test gate is red for. Only a boot claims, so a suite that builds a `Stroller` or a
`City` by hand stays unmanaged and `tests/test_full_run.gd`, which boots `main`, runs with the
rule on. The first version let the day brief's window claim as well, and one suite driving a
brief on a hand-built `main` turned the rule on for every suite after it. The run log writes
one `texture` line for each page actually read — `atlas page 'interior' loaded in the escape:
4.0 ms, 1948 x 260` — before the error, so an offender is recorded either way.

**This overturns part of the design the player approved in PLAYTEST-108**, "one runtime loader
hands out regions by name and owns group lifetime by reference count", in the player's words
above: the count stays as the proof a page is there, and lifetime is the process's.

**Open to overturn.** The group names `mother` and `father`; `--start-escape city` holds
`interior` though that section never draws it; three suites outside the brief's fence were
edited because the change broke them — `test_stroller_gait.gd`, `test_player_presentation.gd`,
`test_stroller.gd`.
