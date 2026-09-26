## M102 — The finale · built behind the flag, 2026-09-12

*(2026-09-12: "also build the entire escape sequence to the end but make it playable only via flag
today (what is now the apartment escape should continue)", overturning the 2026-09-09 "this is just
a plan for now — we probably won't actually implement it for a while".)* Four agent commits on
`feature/the-finale`, reviewed here. The whole fifteenth walk exists — the building with its
events, the service exit onto the city, two chains through three calm areas each to the tunnel and
the bridge, the explosions and their craters, the two hint lines, the millisecond clock, the
section restart and the epilogue — and it is reached only through `--start-escape`. The one thing
deliberately not wired is the entry from day 14's own summary, held back by the same instruction
and still open in `TODO.md`.

**The chains, and why a stop is not a block.** `FinalePlanner.plan()` grows two ordered chains —
service exit, three calm areas one after another, an edge — where a day grows a `RouteTree` with
two distinct routes to each calm area counted as a max flow. The escape asks the opposite
question, *(2026-09-09: "the finale route is not a tree any more … no overlapping routes")*, so the
second chain is grown with every cell of the first treated as wall: they part at the door and share
no cell after it. A stop is a connected component of `Tile.is_calm` ground rather than an entry in
`map.calm_blocks`, and blocks were tried first and do not work — `MIN_CALM_BLOCKS` is 5 and the two
chains need six distinct stops between them, so a third of cities would have had to share one.
Flooding the ground instead makes a four-block zone one place to rest rather than four, brings
courtyards in (calm she can settle in, which the block list does not carry), and makes "three
distinct" a property nothing has to state. Measured over eight seeds: **8 to 11 components per
city**, so six is never tight.

**The sealing, and the street the first version spared.** `SealPlanner.plan_finale()` takes the
chains' open cells where `plan_day` takes a tree and reuses the placement code unchanged. Three
differences, each because the escape is not a day: every seal is hard, since a soft one leaves the
carriageway open and the brief is a single path; the main road is sealed like anything else,
because the chains *end* on the spine and leaving the rest of it open would join them at the one
street touching both exits; and every alley mouth off the chains is walled rather than a fraction
of the qualifying ones. **The first version spared any street a chain merely touched**, which
measured at **37 open streets against chains worth about 11 streets' cells** — every street at
every junction a walk turns at, three times as much open ground as the walk itself.
`FinalePlanner.runs_through()` asks the question at the street's own midpoint instead, which is
where a hard seal stands, so a street the chain only clips is sealed there without closing
anything.

**What stands on the streets that survive.** `EventScheduler.build_finale()` places army trucks,
masked men in vans and on foot, and the bursts. Three of the four rows are existing ones unchanged
— the convoy with the barricade it ordinarily leaves stripped, since a convoy here is traffic
rather than an aftermath, and `roadblock` at full heat, whose guards leave the post. Only
`finale_explosion` is new, and it draws nothing: there is no burst on the street, only the noise
and the hole. Off screen is bought with the streaming radius rather than with a rule — a `MAP`
placement enters the world at 900px against a 640×360 view and is over before she can reach it —
which is also what lets its crater land on the carriageway she then has to route around.
`EventManager.start_finale()` takes the finished plan rather than working one out, because with no
tree, no region plan, no closures and no catalogue budget a mode inside `start_day` would have been
six of its seven passes skipped.

**Section one, and the two sitings that are not decoration.** `InteriorEvents` hosts the mouse, the
masked man on one stairwell, the fire on the other, the steam in the basement and the explosions
outside — *"we can keep the events inside the house relatively minimal"*, so at most one of each.
It is deliberately not an `EventManager`: that class is a day stated over a `CityMap` this building
does not have, and what an `EventInstance` actually needs from its owner is four things — be put in
the world, be told where she is, be summed, and fire the hard fail. **The fire goes on a turn
landing, not a floor landing**: a floor landing has that floor's own door one tile beside it and the
fire's body is wider than that, so a fire there would close the way *out* of the stairwell as well
as the way down it and the answer to it would be walking back up. On the half-landing it closes
exactly one flight, both doors stay reachable, and the way past is into the hallway and along to
the other shaft — which is why the two stairwells are at opposite ends, and the masked man is on
that other shaft, so the way past a fire has somebody coming up it. He is mobile and not `pursues`,
which is the counterplay the brief asks for — *"avoided by going into a corridor and letting them
pass"* — since a pursuer steers at her and the only answer to one is speed, while a man running a
line is answered by not being on it. **The steam paces for a measured reason**: `steam.svg` is 32px
across, so a standing vent is a 16px body in a basement corridor two tiles wide, which leaves her
28px of pram and body a four-pixel lane in the one place in the building with no second route.
That is "no line to walk" exactly; pacing takes the body away by the rule `EventDef.paces` already
states and pays it back in intensity. The basement pair is sited a third and two thirds along the
corridor's own walk rather than at written tile offsets, and finding that walk needed an
eight-connected search, since a flight is a run of diagonal steps and a four-connected one finds no
route out of the basement door at all. The window flash is the explosion's whole cue indoors —
every hallway window at once, counted down in `_process` rather than handed to a `SceneTreeTimer`,
so it freezes behind a pause screen instead of burning down while nothing is played.

**`FinaleController` owns a `DayController` rather than being a second one.** Everything the escape
wants from a clock is already there — the countdown, the three losing paths, the
`EventBus.day_time_changed` the HUD draws from, `--invincible` standing it still — and what it
wants *differently* is only what happens at the end of one. A finale mode inside `DayController`
would have had to disable the home win, the calendar and the Nerve, which is more of that file than
this whole class is. `setup(null, null)` is what makes the home win unreachable: with no map
`_is_home()` is always false, so the one way a day ends *well* can never fire in a walk with no
home to go to.

**One clock, and a loss is the only thing that restarts it.** Crossing the service door calls
`enter_city()`, which changes the section and leaves the clock alone, because a sequence with one
clock cannot restart it half way through — which is the whole of *("the timer for the sequence is
the same length and running out loses")*. A lost section starts again where it began with nothing
spent: `GameState` is not touched at all, which is *("sounds good at that point you earned it")* in
code rather than in prose, and the baby is reset to asleep with sleepiness full on every attempt,
which is also what makes a retry playable, since the meter that just reached a hundred is what lost
it. Where she is put is `main`'s answer rather than the controller's, because only `main` holds
both worlds; `section_started` fires for a fresh section and a retry alike, so the placement is
written once and the hint line is the only thing that asks which it was. The millisecond format is
a flag on the one function that draws the clock rather than a second clock or a second label, and
it calls `GameState.format_clock()`, the same formatter the ending screen's run length uses.

**The epilogue is an entry point on `DaySummary`, not a fourth `GameEnums.Ending`.** An ending is a
*run's* outcome picked from the nerves and the sabotage; this is the last screen of a sequence the
run hands over to. Two lines and the clock, and nothing triumphant, which is the tone rule
`NARRATIVE.md` already holds. The exit's reach is measured from the last walkable tile of the spine
rather than from where `CityEdge` anchors the portal's picture, since that picture is anchored on
the map edge past the ground she can stand on and a reach wide enough to cover the difference would
also have covered the street before it.

**Chosen where the design was silent, and all of it open to overturn.** That a stop is a calm
*component* rather than a block. That the areas are sorted north to south, the tunnel chain taking
the three northern ones met southmost-first and the bridge chain the three southern ones in the
order she meets them, so neither chain doubles back past the door. That the second chain, not the
first, is the one grown against a wall. That there is one crater row at one size rather than the
three prepared ones, since `spawns_on_finish` names a single row and three sizes of one hole would
be three looks nobody could tell apart on the screen-edge badge. That the masked man waits at the
foot of his shaft until she is in it, since one who ran his line at the start would be gone before
she had come down a floor. That `--start-escape city` is the word that boots section two alone.
And every number in `Tuning`'s finale block: `FINALE_LENGTH_SECONDS` (read through from
`DAY_LENGTH_SECONDS`, 180s, so the two can never drift), `FINALE_PARKS_PER_CHAIN` (3),
`FINALE_EXIT_REACH` (1.5 tiles, past her 14px body and under two tiles),
`FINALE_EXPLOSION_INTERVAL` (22s, so the windows flash four times over a clock),
`FINALE_WINDOW_FLASH_SECONDS` (0.12s, taken as a span so it does not depend on the frame rate) and
the per-street densities `FINALE_TRUCKS_PER_STREET` (1), `FINALE_VANS_PER_STREET` (1),
`FINALE_GUARDS_PER_STREET` (2) and `FINALE_EXPLOSIONS_PER_STREET` (1), which put roughly one lethal
thing every two tiles of walking while `EventScheduler._room_around()` still refuses anything it
cannot give room to.

**The suite.** `tests/test_finale.gd` asserts the shape of the walk rather than any number in it,
over four generated cities rather than one, since a chain is a search over a lattice and what is
most likely to go wrong — a park the walk cannot reach, an exit behind a wall — is a property of
one city's geometry: that the chains part at the door and share no cell after it, that each passes
three distinct calm areas and reaches its own edge, that both exits are reachable through the open
cells alone, that every street off the chains carries a seal, that the finale city has nobody in
it, that a burst leaves a crater as wide as its own picture (asserted as a relationship and again
end to end through `EventManager`), that the clock reads milliseconds only in the finale, that a
lost section starts again and costs no Nerve, and that the `city` word boots the second section.
Two of those exist to stop the others passing vacuously: both chains have to be real walks before
"they share no cell" means anything, and the sealed count has to be large before "every street off
the chains is sealed" does. `tests/test_interior.gd` adds the fire closing one stairwell and
leaving the other, the basement pair standing on the corridor she has to walk, and an explosion
flashing every hallway window; `tests/test_events.gd` carries `finale_explosion` and
`impact_crater` through the catalogue-wide contracts.

**Evidence** is `docs/evidence/archive/session-captures/2026-09-12/m102-finale/`, both runs on seed
4242 under `--invincible`: `section-one-hallway-window-flash.png` is the third-floor hallway at the
first explosion beat, the six windows carrying `hallway_wall_window_flash.svg` and the clock
reading `3:00.000`; and the burst under
`rig-145442-seed4242-v0.8.2-746-ga87f5bf-dirty/asked/burst-8950729-001/`, 36 frames over three
seconds with its `burst.json` timings and an MP4 beside it, walking the tunnel chain's first leg
with a van moving on the carriageway and the street beside her shut by burnt-out cars. What only a
person can answer — whether the choice at the door reads as a choice, whether the millisecond clock
is tension or noise — is in `REVIEW.md`.
