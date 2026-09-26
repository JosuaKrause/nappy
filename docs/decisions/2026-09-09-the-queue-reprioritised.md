## The queue reprioritised — 2026-09-09

The player went through the open milestones one by one and placed them; `TODO.md`'s gameplay queue
carries the sentences. What this record keeps is what the check behind it found, so nobody re-opens
an item the code had already answered.

**Two items closed on a player's verdict.** M63's one remaining item — whether a thumb can hold the
8px lane midline `CrowdLanes` opens between a pavement's two walking lanes — was answered *"not sure
what this is but yeah the midline works"*. M60's home arrow landing under a thumb was answered
*"home arrow under thumb is not a problem"*. Both sections are gone from `TODO.md`; M60's last item,
the browser smoke pass, was explained rather than closed — playtests 27 onward answered *boots and
takes input* at the live address, and the half nobody has done (frame rate on a foreign machine, a
stranger's first impression) sits in M100.

**Found built when the folded milestones were checked against the code.** M43's pause lesson no
longer fires while she is held: `HUD._teach_the_pause()` resets its timer while `Stroller
.is_detained()` or the tree is paused. M43's run lesson resets on every attempt at the teaching day:
`HUD._teach_the_day()` clears `_taught_run` whenever the day started is `RUN_TAUGHT_DAY`. M47's
apartment complex exists as `CityGenerator._place_apartment_complexes`, a courtyard lot four blocks
across; its non-adjacency rule covers courtyards through `_has_calm_neighbour` in `_cut_courtyards`,
and `validate()` checks all eight neighbours of every calm block — though the player corrected the
claim that this settles adjacency: *"non -adjacency rule doesn't cover parks yet -- that's something
we might want to tweak later"*, which M97 carries as a later item. M47's multi-block count was
re-derived for 121 blocks — `MIN_CALM_ZONES` 1, `MAX_CALM_ZONES` 2, the rest single-block by design.
M45's soft version — events placed to say *not this way* — is M64's `SealPlanner`. The
`burning_building` spawning in the road is gone: `EventInstance._be_done()` finishes an event with
`spawns_on_finish` where it stands rather than letting it drive off. The seed-retry note was a fact
rather than a task and `docs/CITY.md` already states it.

**Where the rest went.** M45 folded into M62, with the reachability-grid confirmation the small
items carried. M43 became M96, M47 became M97, M25 and M26 became M98, M50 became M99, and the small
items, M10 and the open design questions became M100. M61 sits after M62; M65 is revisited after
M62 rather than built as written; M56's build item runs alongside M62 and its measurement waits
until act III is reached, which the player put after the current batch. The illustrated actor work
is Codex's parallel track, and SVG stays the game's graphics until that passes its visual gates.

**One collision, resolved by the player the same day.** M47's *main road as a soft block* asked for
a toll on crossing the spine, and M64's route tree relies on crossing the spine being free. Put to
the player, the answer was that the toll already exists: *"M47's toll already exists — it's timing
the traffic lights. we don't need to penalize routing through it just yet — it naturally happens
that only some routes cross it."* So the item is closed rather than carried: waiting for a green is
the crossing's price, and the tree's own growth is what makes crossing a decision some routes take
and others do not. What would make it worth discussing again is a played run in which every route
crosses the spine for nothing, not an argument about the multiplier.

**M26's scripted short-run event is the charging dog, and was all along.** Playtest 02 asked for
*"a scripted day-1-only event that requires a short run, after the first block"*, parked behind the
patrols work because running was then wrong against everything. Put back to the player as
keep-or-drop, the answer was neither: *"this is what became the charging dog"*. The dog is that
event moved to day 3, the day running becomes the right answer, and sited ahead of her so the run is
unavoidable — the *safe place* the playtest wanted. So M98, pressure in the empty acts, holds only
M25's return-phase item.

**`RUN_TAUGHT_DAY` stays at 3.** The move to day 2 had stood as *decided and not implemented*
since the M49 session's "Day 3 carries act I's whole payload"; put back to the player on
2026-09-09 because it gates every pursuit, the answer was *"run taught goes to 3 not 2"*, so the
item is closed and the constant is left alone.

**And one bug reported in the same session**, filed at the top of M100's defects: events spawn
inside a fully blocked street. The mechanism was read the same day — `closed_tiles` holds only the
ground a flood from the doorstep cannot reach, so a closed street with a side opening stays open to
the scheduler, and a hard seal is bodies rather than a closure and marks nothing closed at all. And
one design instruction, filed as M101: the burning building becomes the day-3 one-shot and the fire
engine spawns when the fire is first seen, reversing today's `spawns_on_finish` link. The session's
words are in `PLAYTEST-49.md`.
