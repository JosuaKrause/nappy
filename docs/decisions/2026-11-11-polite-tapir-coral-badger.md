# polite-tapir — Step 5's switch: the escape city's walk is drawn by the unit draw · 2026-11-17

**What it is.** The last of placement step 5's three pull requests (polite-tapir's
`placement-by-construction.md`, step 5, the escape city's draw is the same unit draw), after the
seam (the record polite-tapir-dappled-magpie) and the ground (polite-tapir-misty-lynx). It builds
section 5.3 of Fable's design (`.claude/briefs/designs/placement-step5-escape-unit-draw-design.md`
in the orchestrator's checkout, not tracked). Two builders wrote it: the first built the code and
the suites and stopped at its context limit; the second wrote the docs, re-recorded the run-log
fixture, ran the probes and opened it.

**What was built.** The escape city's walk is drawn by the day's own unit draw with three settings
on its spec: one bag for the whole walk (`WholeWalkBag`), one marble a street (the ground's
setting), and every unit drawn before she sets off in the order the walk names its streets
(`UnitDraw.draw_in_their_order()`, `DayUnits.all()`, `DaySpec.draws_before_she_sets_off()`), each
judged among everything drawn before it. A marble a street refuses stays in the bag for the next.
The escape's own loop (`EventScheduler._draw_the_walk()`, its street bag and seed), the spec's
switch between draws (`DaySpec.Draw`), the escape's caps and `StreetLocations.drawing_order()` are
deleted, and `build_day()` no longer returns early for the escape. The bag holds nine empty marbles
(`DaySpec.FINALE_BAG_EMPTY`).

**The empty marbles.** The player's order for the bag puts empty last ("trucks > explosions > vans >
barriers > empty", inbox #785 in minty-lemur, and "The bag" when asked whether that meant the
marbles), while a third of the streets stood empty, since a danger a street had no room for was
thrown away. Keeping a refused marble in the bag with one empty marble would leave 9% of streets
empty and twice the vans, an escape nobody has walked. The design measured each count with a
prototype over 24 seeds (752 streets), and nine keeps today's share:

| Empty marbles | Dangers a street | Streets with none | Trucks | Explosions | Vans | Roadblocks |
|---|---|---|---|---|---|---|
| main (1, a refused marble spent) | 0.66 | 34.2% | 167 | 193 | 91 | 44 |
| 1 | 0.91 | 9.2% | 195 | 247 | 186 | 55 |
| 6 | 0.71 | 28.9% | 185 | 196 | 105 | 49 |
| 8 | 0.67 | 33.2% | 181 | 187 | 90 | 44 |
| 9 | 0.66 | 34.3% | 181 | 178 | 89 | 46 |
| 10 | 0.63 | 36.7% | 176 | 175 | 80 | 45 |
| 12 | 0.61 | 39.4% | 173 | 171 | 71 | 41 |
| 14 | 0.57 | 42.8% | 157 | 167 | 71 | 35 |

Set aside: the touching units' scope with routes cut to their street (28% empty, 233 trucks); a third
of the marbles empty (39%); one empty marble (9%, twice the vans); the roomiest tile in a street
(no difference). Nine is the orchestrator's reading that the player's approval of the design review
(hold the escape steady, let lilac-marten, the fuller escape, set the real count) answers the
question; the player may overturn it, and lilac-marten sets the count.

**What it measured** (the built game, against main, 24 seeds): the escape planned 0.66 dangers a
street and 34% of streets with none before and after (trucks 167 → 181, explosions 193 → 178, vans
91 → 89, roadblocks 44 → 46), within a point of the prototype; eight and ten empty marbles plan 33%
and 37% empty. Walked to the tunnel, 13 walks got out before and 12 after (out in 69.0s and 64.9s);
to the bridge, 10 and 10 (65.9s and 58.5s); at 24 walks an exit the count moves by several on chance,
and it gates nothing. No two roadblocks stand nearer than their notices over 40 seeds, before or
after. The placement fingerprint differs only on the escape's lines, and `walk_rows`' lines are
main's. The replan's median time read higher (324 → 413 ms), measured while main's walks ran on the
same machine.

**Found on the way.** A posted roadblock guard charges a straight walker and misses her on some
streets, at main too (3 of 32 walks), every miss on a vertical street walked forward. The switch
moved which streets stand a band, and the finale rig's check that every straight walk past a posted
guard is caught failed on two of its crossings. The check is a floor of half the walks caught, and
`docs/EVENTS.md` and `docs/MECHANICS.md` say that most walks are caught; the defect is filed as the
entry azure-squirrel, which waits for the refactor (the orchestrator's decision, open to the
player).

**Proposed, not asked for, open to the player:** the finale rig hands its dawn no masts, since the
escape's dawn places none; `field_reads.txt` lost two lines more than the design named
(`event_scheduler.gd`'s `max_per_day` and `drawn`); `tools/test_only_members.txt` keeps
`day_spec.gd bag`; the dawn's run-log line reads "every unit drawn before she sets off: N units, M
rows". The balance skill's "Two levers" no longer names the escape's bag turning the caps off, a
setting that is gone.

**What is left of polite-tapir's placement:** step 4's last pull request, the beat laid in a unit
before it draws, waiting on the board questions `beats-on-her-street` and `beat-changes-its-unit`.
