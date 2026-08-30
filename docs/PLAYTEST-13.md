# Playtest 13 — the crowd is the game, and nobody chose that

The thirteenth report, taken on `b7590fb` — `main` with M41, M42, M44 and the built half of M43 on
it. One sitting, one run, five nerves spent, ended on **day 4** with a bad ending.

The player opened by saying they could not comment on much, *"since you didn't actually finish your
work so a lot of things we discussed are not in yet"*, and closed with the instruction that governs
what happens next:

> **"don't tell me to playtest again unless all the things we discussed have been implemented —
> there is otherwise not really any point in playtesting since it will just surface the already
> mentioned things again"**

That is a process finding and it is the most important line in the document. M43 was merged half
done on the argument that *"what is left of it cannot be done at a keyboard"* — that the two open
findings needed a played run. This report is what that decision actually bought: a run that spent
five nerves rediscovering things already written down, because the milestone that would have
changed them had not been built. **A playtest is a scarce resource and it was spent on a build
that was known to be incomplete.**

The trace is `run-2026-08-30T031851-seed3251793152-b7590fb.log`. Every number below is read off
it or off the code it was played on; nothing here is a probe.

---

## The findings, as reported

| # | What the player said | Kind |
|---|---|---|
| 1 | "just walking around now increases excitement — this is bad" | balance |
| 2 | "it's hard to find parks now — this needs the fixes we discussed" | design |
| 3 | "I see random gray barriers placed half on the street and half on the sidewalk — no clue what they are supposed to be but they raise excitement for some reason?" | bug |
| 4 | "for telemetry render out the entire city grid into a picture in the telemetry folder" | tooling |
| 5 | "allow creating a screenshot via key press that saves into the telemetry folder and writes a telemetry note for context — this is to help debugging; not a game feature" | tooling |
| 6 | "the dog doesn't stop fast enough on day 3 — we talked about this! when running the pursuit should stop quickly — it *only* should keep going if the player doesn't run" | bug |
| 7 | "the main road doesn't really have much traffic I can freely walk over it — also think of the main road as a soft block to guide the player — they will avoid crossing it until it becomes necessary" | balance + design |
| 8 | "I had a tutorial pursuing dog on day 4 — that should not happen" | bug |

Two decisions were taken in the same sitting, in answer to questions put during the analysis:

> **On finding 2:** *"make more calm areas take up multiple blocks — I said a long time ago that an
> inner courtyard (surrounded by buildings) should have a footprint of 2x2 blocks (apartment
> complex) — this never got implemented. not all calm areas have to take up multiple blocks but add
> more that do. also, add calm varieties that take up 2x1 non-square shapes"* — **plus M45 as
> designed.**

> **On finding 8:** the charging dog **recurs past day 3, but is not sited ahead of her.** It goes
> back to being a thing she walks up to rather than a thing the director drops in her path.

---

## The one sentence

**The crowd is supplying almost all of the difficulty, and every authored system in the game is
being judged through it.**

This is not a new finding. It is playtest 07's finding 17, then playtest 10's *"the thing nobody
reported"* — five runs, no day won, every losing line reading `crowd 39.4, events 0.0` — and it has
now been reported by a person, in finding 1, in the plainest possible terms. It has been deferred
three times, most recently in `HANDOFF.md`'s note that *"the crowd milestone is not next and may
not exist"* because M41 had moved every number it was going to argue about.

M41 moved them. The finding survived. **It is next.**

Findings 1 and 7 are the same sentence from opposite ends: the ordinary pavement is loud enough to
end a day on its own, and the one street that is *supposed* to be the loudest and most dangerous
thing in the city is a street she crossed without noticing and, on this seed, never walked down at
all.

---

## Finding 1 — the pavement is the hazard

**The strongest evidence is the first entry of the run and it needs no interpretation:**

```
   3.1  idle     stood still 3.0s on sidewalk, exc 0 -> 8, sleep 0 -> 0
```

Three seconds of standing still on an ordinary pavement, one street from her own front door,
before she has met anything: **+2.7 excitement a second.** `EXCITEMENT_DECAY_IDLE` is 0.0 by
decision (M33: *"what settles a baby is being pushed"*), so on the pavement there is no floor under
her at all — standing still is a pure climb at whatever the crowd is doing.

Walking does not help as much as it should. `EXCITEMENT_DECAY_WALKING` is 3.5/s on ordinary ground
and the trace has the crowd beating it repeatedly with nothing authored anywhere near her:

| trace line | crowd | events | walking decay | net |
|---|---:|---:|---:|---:|
| day 2, 16.4s, `near cafe_tables 170px` | 10.8 | 0.0 | 3.5 | **+7.3** |
| day 2, 81.3s, `near cafe_tables 170px` | 17.3 | 0.0 | 3.5 | **+13.8** |
| day 1, 15.2s, `near cafe_tables 169px` | 4.1 | 0.1 | 3.5 | +0.7 |
| day 3, 8.8s, `walked into somebody` | 25.4 | 0.2 | 3.5 | **+21.9** |

And a contact is worth twenty to thirty-four points a second while it lasts. There are **fifteen**
`walked into somebody` entries in a four-day run, and their crowd column reads 22.2, 22.2, 22.2,
23.6, 24.0, 25.4, 26.7, 26.9, 27.5, 27.6, 30.3, 30.3, 30.8, 33.0, 34.3.

**The meter reaches the freeze threshold before she leaves her own neighbourhood, every single
day.** `freeze sleep stopped filling` at exc 35 fires at **6.3s, 12.5s, 7.2s, 8.6s and 9.9s** on
the five attempts that got that far — which means the sleepiness meter, the thing the day is
actually about, is switched off within ten seconds of the doorstep on every attempt, by a crowd she
has not chosen to walk into.

**And the day that was lost was lost entirely to it:**

```
  29.4  lost     lost_crying after 29.4s — She started crying. There is no settling her now.
                 | exc 100, in 24.6/s (crowd 24.6, events 0.0), sleep 6
                 | near: delivery_van 272px (out of range)
```

A hundred points in twenty-nine seconds, `events 0.0`, and the nearest authored thing in the game
is out of range. That is playtest 10's line, verbatim, one milestone later.

**What this is not.** It is not a claim that the crowd should be quiet — the noise floor being
emergent rather than a constant is an invariant and a good one, and *"the crowd is expensive to be
careless in and free to be careful in"* is the ratio the design is built on. What the trace says is
that the careful line has stopped existing: M33 already measured that ratio away (eleven contacts
down a lane centre against one on the midline became thirteen against fifteen) and answered it with
a *behaviour* — people step aside. Fifteen contacts in four days says the behaviour is not
carrying it.

Three numbers are in the frame and the milestone has to measure rather than argue which:
`CROWD_PEDESTRIANS_PER_ACT[0]` (200), `BUMP_RADIUS` / what a contact costs, and
`EXCITEMENT_DECAY_IDLE` being 0.0 on ground that is neither calm nor quiet.

## Finding 7 — the main road is the quietest thing in the city

Two halves, and the first one is a defect in the code rather than a number.

**`CrowdLanes.busyness()` still weights the middle corridor of *each* axis at
`ARTERIAL_BUSYNESS`.** It reads:

```gdscript
var blocks: int = Tuning.CITY_BLOCKS.x if vertical else Tuning.CITY_BLOCKS.y
if index == arterial_index(blocks):
	return ARTERIAL_BUSYNESS
```

`CityMap.main_road` is a **vertical** corridor and there is one of it — that is M41's whole
correction, taken after playtest 12 said *"there should be one north to south main road I had
multiple (and there should be no east to west ones at all)"*. The correction reached
`street_kind()`, `GroundTiles`, `TrafficSignals` and `decay_multiplier`. **It never reached the
crowd.** So the city has one main road you can see and two the traffic believes in, and the
weighting that was measured for one street is being spent on two.

The trace confirms it from the other side. She crossed roads about thirty times in the run and
**five** of those produced a horn; every `cue the mark over her head … a car, and she is in the
road` entry lasted between **0.1s and 0.7s**, which is the lethal cue in the game firing for less
than a second and then going away. Nobody ever waited at a kerb.

And on this seed she **never walked on the main road at all**. It is corridor 5, tiles x=70–75; the
whole run happens between x=84 and x=108. The crossings at y=72–73 that *look* like arterial
crossings — `(99,73)`, `(88,73)`, `(85,72)` — are the middle **horizontal** corridor, the phantom
arterial above. She spent four days crossing the busiest street in the city without ever being told
it was one, and never met the street that was supposed to be it.

**The second half is a design instruction and it is new:**

> *"think of the main road as a soft block to guide the player — they will avoid crossing it until
> it becomes necessary"*

This is the same idea as M45's closures-that-point, one level up and permanent. A closure says *not
this way today*; the spine says *not this way unless you mean it*, every day, in a place the player
learns once. It is the piece M45's *"a city that is not a full grid, permanently"* was missing:
the spine is already a line down the middle of the map, it already has a hierarchy and a picture,
and making it genuinely expensive to cross turns the city into two halves with a toll between them
without removing a single walkable tile. **That is a soft version of the permanent restriction M45
was going to build out of cul-de-sacs, and it should be built first, because it costs no geometry.**

## Finding 2 — the parks are as many as they were and much harder to find

The count is not the problem and the trace says so: `plan calm: 1 forest, 3 courtyard,
4 quiet_square` — **eight** calm areas, against a `MIN_CALM_BLOCKS` floor of 5. Playtest 12's
finding 5 was implemented and it held.

What changed is the denominator. The city went 7×7 → 9×9 → **11×11** across M42 and M41: 49 blocks
to 121. Eight calm areas in 121 blocks is one in fifteen where the same eight used to be one in
six. **The equation the player asked to keep was about count and the thing they are now
experiencing is density**, and the two came apart when the map grew.

The decision taken on this finding does not simply raise the count, and that is the interesting
part:

> *"make more calm areas take up multiple blocks — I said a long time ago that an inner courtyard
> (surrounded by buildings) should have a footprint of 2x2 blocks (apartment complex) — this never
> got implemented. not all calm areas have to take up multiple blocks but add more that do. also,
> add calm varieties that take up 2x1 non-square shapes"*

So the answer is **area rather than count**: the same number of destinations, each of them bigger
and harder to miss, and shapes that are not all squares. Three things follow.

- **The 2×2 inner courtyard is an old request that was never built.** What exists is
  `COURTYARD_SIZE_TILES` — a 4-tile court carved *inside* one residential block, three per city.
  What was asked for is an apartment complex: four blocks of buildings with a shared court in the
  middle of them, which is a different thing from a park and a different thing from M21's calm
  zone. M21 built the four-block zone by **absorbing the streets between four blocks**, which is
  the mechanism this needs — with buildings around the outside instead of open ground.
- **Non-square 2×1 calm areas are new geometry.** `CALM_ZONE_BLOCKS` is a single integer and every
  piece of arithmetic downstream — the tile rect, which segments are absorbed, which junctions
  survive — is written in terms of one number squared. A 2×1 makes that a `Vector2i`, and
  `CityMap.anchor_of()` / `lot_rect()` are where it is felt.
- **A bigger calm area absorbs more streets, and `absent_segments` is how the lattice finds out.**
  That is the same machinery M45 wants for permanent restrictions, arriving from the other
  direction — so these two are one piece of work and should be built together.

**And a second lever was taken in the same session, which is a placement rule rather than new
geometry:**

> *"another way to get density is to make a rule to not have a calm area at the edge of the map or
> next to the main road"*

Today a single calm block has **neither** rule — `_assign_purposes` constrains it only by "not
claimed", "no open calm across the street" and `_too_near_the_home` — so a quiet square can stand
in the outermost block column against the boundary wall, or across the road from the spine. A 2×2
zone has half of one: `_zone_fits` refuses a footprint that would *absorb* a stretch of the
arterial, which is a different rule about a different thing.

Counted on the lattice, for a single calm area, with the home clearance already applied: **96
eligible blocks today → 56 with the edge rule → 48 with both.** The field halves and the count
does not move, which is exactly what the finding asked for.

Two things the count says that the proposal did not. **The density argument is almost entirely the
edge rule** — the outer ring is 40 blocks and the spine's two columns add 8 more, because the main
road runs down the middle where the home clearance has already removed a 5×5 — so *"not beside the
main road"* has to stand on design instead, where it is the stronger of the two: the spine is 0.6
decay ground, a park you can hear it from is not calm, and calm that never sits beside it means
**crossing it always leads somewhere worth crossing for**. And **it recovers half the loss, not all
of it**: the 7×7 city had ~24 eligible blocks for the same 5–7 areas. This lever and the bigger
calm areas are complementary — one shrinks the field, the other enlarges each destination.

## Finding 3 — the gray barriers are `construction`, and they are drawn wrong twice

*"no clue what they are supposed to be"* is the finding, and the trace names the row:

```
  41.5  near     construction at (102,139), 199px, … in 16.5/s (crowd 1.4, events 15.1)
  42.7  near     construction at (102,139), 109px, … in  9.2/s (crowd 0.0, events 9.2)
  49.3  near     construction at (102,139), 110px, … in  9.1/s (crowd 0.0, events 9.1)
```

It is worth **9.1/s at 110 pixels**, which is where *"they raise excitement for some reason"* comes
from — and it is the only thing charging her on that street. So the field is fine. The picture is
not, in two separate ways, and both are geometry rather than art.

**It does not fit the pavement it stands on.** `construction` has `obstructs_radius = 34`, so
`_draw_spread` draws it **68px wide**. A sidewalk is `SIDEWALK_WIDTH * TILE_SIZE` = **64px**, and
an event stands at a tile centre — 16px from one edge of that pavement and 48px from the other. A
68px object centred there covers −18 to +50 or +14 to +82: **it overhangs by 18px whichever of the
two sidewalk lanes it lands in**, into the carriageway on one and into the building lot on the
other. "Half on the street and half on the sidewalk", exactly.

**And it is always drawn east–west.** `_draw_spread` spreads along the node's local x and nothing
ever rotates an `EventInstance` — there is no `rotation` or `draw_set_transform` for orientation
anywhere in the file. So the same barrier that hangs into the road on a north–south street lies
*along* the kerb on an east–west one, parallel to the traffic, blocking a pavement it is not
across. A barrier's entire content is which way it faces.

Two things generalise past this row, which is why it is worth more than a number:

- **`obstructs_radius` is half the silhouette (M34) and nothing checks it against the ground the
  thing is standing on.** Every `_draw_spread` row has the same arithmetic available to break:
  `market_stall`, `checkpoint`, `barricade`, `burnt_shell`, `cafe_tables`. This wants a rule with a
  test — *a body on a pavement fits on the pavement* — in the shape of M34's own.
- **The sprite is blue-grey (`#6b7a8c`, `#4e5a68`) with no hazard marking at all.** M37's rule is
  one picture per row and no two rows sharing one, and this row passes it while still not saying
  what it is. Municipal barriers are red-and-white for the same reason the game has a vocabulary:
  *how dangerous a thing is has to be visible from looking at the thing.*

## Finding 6 — the chase does not end when she runs

`Tuning.PURSUIT_SHAKEN_OFF` is 0.8s **of the gap opening**, and M39's write-up claims the answer
costs *"0.86s of running, 12 points"*. The trace disagrees on both, three chases running:

| day | chase lasted | she ran | it cost |
|---|---:|---:|---|
| 3, attempt 1 | **5.4s** | 3.2s | exc 9 → 95, lost the day |
| 3, attempt 4 | **5.4s** | 2.1s | exc 16 → 66 |
| 4 | 1.3s | 0.0s | hard fail |

Two chases in this run lasted **5.4 seconds** — nearly twice `PURSUIT_TIME` — while she was running
for most of them. The first one turned a meter reading 9 into a meter reading 95 and ended the day.

The cause is in `EventInstance._chase`: the timer requires **0.8 continuous seconds** of the gap
opening and is reset to zero by any frame that does not open it.

```gdscript
if _last_range < INF and range_to_her > _last_range + 0.001:
	_outrun_for += delta
else:
	_outrun_for = 0.0
```

The trace shows what that costs against a real player, who does not hold a key down for a clean
0.8s: she ran in **four separate bursts** — 1.2s, 0.5s, 1.4s, 0.4s — and every gap between them put
the counter back to zero. Worse, the first `(WALK_SPEED + RUN_SPEED) / ACCELERATION` of every burst
is spent turning round and accelerating, during which the gap is still *closing*, so a 1.2s burst
may contain well under 0.8s of opening. The requirement is effectively *one uninterrupted run
longer than the player has any reason to know about.*

**The instruction is unambiguous and it is the design, not a constant:**

> *"when running the pursuit should stop quickly — it **only** should keep going if the player
> doesn't run"*

So the break-off condition should be **she is running away from it**, not *the gap has been opening
for 0.8s*. The rate framing was M39's fix for a different complaint and its reasoning still holds —
*only running can open the gap*, so a rate cannot be faked by walking — but it buys that guarantee
by measuring the *consequence* of running instead of running itself, and the consequence is
polluted by acceleration, by diagonals, and by a player who lets go of shift. Reading the state
directly gives the same guarantee (walking away still cannot end a chase, because walking away is
not running) with none of the noise, and it makes the sentence the player said true: *stop quickly
when she runs, keep coming when she does not.*

**What must not be lost with it**, both already written down: the chase may not end before it has
been a threat (`PURSUIT_MIN_NOTICE` is the floor under it), and walking away must never work at any
distance — the M36 trap, where a trigger at the break-off distance let a rig stroll away every time.

## Finding 8 — the tutorial dog is not a tutorial

`charging_dog` is `first_day = 3` with `spawn_mode = AHEAD_OF_PLAYER` and no last day, so the
scheduler keeps placing it for the rest of the run and the director keeps siting it in front of
her. Day 4 of the trace:

```
   0.0  plan     events: … charging_dog x3, …
  25.0  ahead    charging_dog comes at her from 200px in front of her at (42,89)
  26.3  lost     lost_hard_fail after 26.3s — It went wrong.
```

Three of them planned on day 4, and the one she met arrived in the identical presentation to the
day-3 lesson — *"comes at her from 200px in front of her"* — which is why it reads as the tutorial
turning up again. `EventScheduler._ensure_the_run_is_taught()` is correctly gated to
`RUN_TAUGHT_DAY`; the row underneath it is not gated to anything.

**Decided: it recurs, but is not sited ahead of her.** `AHEAD_OF_PLAYER` is documented as being for
*"the small number whose entire content is the moment it happens to you"*, and after day 3 that is
exactly what a charging dog stops being: the lesson is over, and the row's job becomes a hazard
with a place, like every other pursuit in the catalogue. `alley_robbery` already shows the shape —
`pursues_within`, a thing that is somewhere, that can be seen and priced and routed around, and
that becomes a chase if she walks up to it.

Two constraints on the change. A `MAP`-placed pursuer needs `pursues_within` or it will never
trigger at all, and `Tuning.validate_pursuit`'s third clause — the trigger must sit inside
`PURSUIT_BREAK_OFF` — is the one that makes walking away fail. And day 3 must keep the placement
it has, because the lesson depends on the encounter being unavoidable.

## Findings 4 and 5 — two pieces of debugging tooling, and neither is a game feature

Both are asked for by name and both are small. They are listed last because they are the least
interesting and they should probably be built **first**, since the milestone above them is going to
want exactly the two things they provide.

**A picture of the whole city grid, written into the telemetry folder.** `--overview` already
frames the map for a screenshot, but it is a dev flag on a run somebody has to take, and it
photographs the *rendered* city rather than the grid. What is asked for is the grid itself, written
beside the log, every run, without anybody doing anything: one pixel or one small square per tile,
coloured by tile type, so the layout a trace describes can be *looked at*. Everything needed is
already there — `Tile` decides the colour, `CityMap` holds the grid, `Telemetry` owns the
directory and the naming. It answers the questions this milestone is about to ask constantly:
where the calm areas are, where the main road is, what the closures cut, and how far any of it is
from the door.

**A key that takes a screenshot and writes a note.** `Telemetry.snapshot()` exists and is
heuristic — it fires on the entries a reader stops at. What is missing is the player being able to
say *look at this*. It needs its own key, it must bypass `SHOTS_PER_DAY` (a person asking is not a
heuristic firing), and it writes a `note` alongside so the picture has a line in the trace to sit
next to. It is explicitly *"to help debugging; not a game feature"*, so it goes with the dev flags
and under the same eventual debug-build gate.

---

## What this is planned as

**M46 — the crowd is not the game.** Findings 1 and 7's first half. The thing three playtests have
now said and two milestones have deferred.

**M47 — a city with places in it.** Finding 2, finding 7's second half, and M45. The 2×2 apartment
complex, non-square calm areas, permanent restrictions, closures that point, and the spine as a
soft block. One milestone because they are one mechanism: `absent_segments` and what a lot is.

**M48 — things drawn where they stand.** Finding 3, and the rule under it.

**M43's last findings.** Finding 6 is M43's own open cool-off entry, answered by a played run at
last. Finding 8 is small and belongs with it.

**Tooling.** Findings 4 and 5, built first.

The order is in [TODO.md](TODO.md). **Nothing goes back to the player until all of it is in** — see
the instruction at the top of this file.
