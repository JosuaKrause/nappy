## M174 — The rows are corrected for the decay, and the halo and the caret say what the bar does · built 2026-09-20

*(2026-09-20, [PLAYTEST-112](../playtests/PLAYTEST-112.md): "I can easily walk next to him for an
extended amount of time without any real penalty … he gets deep red but my bar doesn't move up
much"; [PLAYTEST-113](../playtests/PLAYTEST-113.md): "let's increase the influence of those
obstacles. notably, yeller, unleashed dog, walker with dog. also, let's fix what the halo
reflects"; [PLAYTEST-114](../playtests/PLAYTEST-114.md): "we didn't change the yeller but we changed
everything around him. the decay rate etc etc"; [PLAYTEST-115](../playtests/PLAYTEST-115.md): "what
matters for the dogs is walking past them. and it shouldn't be free. at the very least restore
the net gain if not a bit more", "the same for the yeller btw", and of the caret, "if I keep
doing what I'm doing I very likely get that amount in net gain".)* One agent, four rounds on
`feature/m174-yeller-cost-and-halo`, reviewed here.

**The cause was M117, not the rows.** `EXCITEMENT_DECAY_WALKING` went from 3.5 to 6.0 a second
on 2026-09-12 and every row tuned before it lost 2.5 a second net. The first comparison looked
at the rows between two releases, found nothing and said so; the player named the cause.

**The measure is the pass, and the orchestrator's first target was the wrong one.** The entry
first asked for a net rise while walking *beside* a source inside its `inner_radius` (at least
8 a second awake, 2 asleep). Against that, the two dogs already passed and only the man
shouting moved, by a `core_intensity` of 25 within 50px — built, then taken out again when the
player overturned the measure: a pass, she and the source going different ways, at fixed
sideways offsets, the source moving as the game moves it, net of the decay earned over the same
seconds. `tests/probes/m174_pass.gd` is the instrument and `tests/probes/m174_walk_beside.gd`
the earlier one; both are kept and neither runs in CI.

**The numbers**, a pass with the baby awake at 0, 20 and 40px, in points net:

| Row | under 3.5 | before | after | what moved |
| --- | --- | --- | --- | --- |
| `homeless_yeller` | 10.2 / 10.1 / 9.6 | 1.5 / 1.5 / 1.1 | 11.1 / 11.0 / 10.3 | `intensity` 14 → 20 |
| `dog_walker` | 14.7 / 14.1 / 11.9 | 10.5 / 10.0 / 8.0 | 16.1 / 15.3 / 12.6 | `intensity` 26 → 33 |
| `loose_dog` | 14.1 / 13.8 / 12.8 | 11.0 / 10.7 / 9.8 | 15.0 / 14.7 / 13.5 | `intensity` 32 → 39 |
| `leaf_blower` | 24.7 / 24.1 / 22.5 | 14.4 / 13.8 / 12.3 | 23.9 / 22.6 / 18.7 | `core_intensity` 22.2 → 35 |

Asleep, the man shouting's pass is still under nothing (about −3 where it was about nothing
under 3.5), and the dog walker's is +4.3 against +5.4. `loose_dog` stops at 39 because at 42
running past it became cheaper than walking, which the catalogue allows `car_accident` alone.

**The wall line moved, by the player's choice among three.** A first round kept
`Tuning.WALL_WORTH_OF_COST` at 35 and could restore the man shouting to about 94% and the dog
walker to about 80%, since a walk-through cost past the line schedules a row as a wall and
takes it off the corridor, and the line sits on purpose between `dog_walker`, which has to stay
friction, and `leaf_blower`, which has to stay a wall. A fully restored dog walker costs more
than the leaf blower did. Put to the player: merge short and finish in M175; restore fully now,
raising `leaf_blower` by what the decay took and moving the line; or let the dog walker become
a wall. *"Restore fully now."* The line is 48 points, with `dog_walker` at 42.7 and
`homeless_yeller` at 40.0 under it and `leaf_blower` at 52.9 over it. Run over every catalogue
row at both lines, no row's role differs from what it was before the milestone.

**What a day places, re-measured** (`tests/probes/m64_measure.gd`, eight seeds): friction on the
corridor 1005 → 964 over days 1, 5, 8, 11 and 14, walls on it unchanged at 332, and day 1's
friction 19.6 → 17.5 a seed. `tests/test_events.gd`'s placed-by-role floor followed its own
stated rule down from 0.34 to 0.31. The day-1 drop was not run down or compensated for:
*"Once it's released we will do some runs and tweak the numbers by feel."*

**Rejected on the way:** raising the man shouting's `intensity` with the line at 35 (53.5
points, a wall); shrinking his `outer_radius` toward 126px to buy intensity under the line,
which made `EventScheduler`'s pacing beat that walls a sidewalk with nowhere to leave
unreachable over six seeds of fourteen days — his reach is back at 210; touching any decay
constant, since M117's quiet-street recovery is the player's own priority fix.

**The halo is net.** *Asked on 2026-09-08 for the gross points landed · overturned by the player
on 2026-09-20.* `ExcitementHalo.net_landed()` takes a source's landed points over the window
less its share of `Baby.decay_in_window()`, shared in proportion to what each source landed,
never below nothing: every share scales by the same factor, so the halos sum to the bar's rise
while it climbs and all reach nothing together when it does not. The colour and transparency
curves read the net value unchanged.

**The caret is the anticipated net gain.** *The cues rule that nothing about her own walking
moves the caret · overturned by the player on 2026-09-20.* `expected_impact_at()` on an event
and on a crowd agent projects her at her current velocity as well as the source at its own,
and nets the projection against her current decay and the baby's current sensitivity. That
"what I'm doing" means her movement and the baby's state is the orchestrator's reading.
`will_be_lethal()` still holds her position fixed: that it ends the day is not a claim her
walking should soften. Open in `TODO.md`: the projection holds a pulsed row's rate as it stands
for the whole horizon, and each caret nets all of her decay against its own source rather than
sharing it; the promise is tested against an unpulsed row, within three points.
