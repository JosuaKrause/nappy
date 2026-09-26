## M62 — Checkpoints that divide the map · built 2026-09-10

*(2026-09-02: "checkpoints in the later acts should divide the map into segments/areas. that is
the player should be forced to cross checkpoints to reach parts of the map and the checkpoints
live alongside the full perimeter of each region. checkpoints can reuse the other woman with baby
logic. the cost can be time (and a bit of excitement) while being detained until released" —
and, on the shape: "a checkpoint is a barrier across the street where there are guards on the
side-walks with a hut and a gate over the roadway (cars need to slow down to a full stop before
the gate opens and they can go ahead again). the player walks to a hut gets detained inside and
then spawns on the other side afterwards. it works in both directions with the same cost each
time"; "regions should be a partition of the map"; "what the regions are is determined at initial
city creation and paths planning and boundary placement are 100% orthogonal. a region edge can
never affect a path"; "a region that contains no accessible calm zone should have no checkpoints /
gates"; "it is okay to move checkpoints on a daily basis".)* M45's three items — permanent
impassable structure, a closure that points, and a soft version placed to say *not this way* —
were folded in on 2026-09-09 and are answered here, by the wall, by the doors, and by M64's
sealing respectively.

**The four decisions put to the player on 2026-09-09 and taken as drafted** *("go")*: a region is
a set of street segments, not blocks; the main road is ordinary ground the partition may cut,
rather than a permanent boundary of its own; four regions (`Tuning.REGION_COUNT`); and the wall is
planned daily beside the closures rather than being `absent_segments` structure, which narrows
M45's *"reuse `absent_segments`"* to reuse of the category with the player's agreement. The
alternative for the main road — the spine as an east/west boundary — was named and not taken
because it gates every crossing the tree makes and collides with `docs/CITY.md`'s *she may cross
wherever she likes*.

**What a region is, made exact.** Every lattice junction belongs to exactly one region, decided
once at generation from an RNG of the map's own (`RegionPlanner.assign`, stored as
`CityMap.region_of_junction`). A segment whose two ends share a region is interior; one whose ends
differ is a **boundary segment**. A route crosses regions if and only if it walks a boundary
segment or a **crossing alley** — an alley whose two mouths open onto ground of two regions —
so *every crossing passes exactly one barrier* is true by construction. **Atoms** are unioned
before growth so a flood claims them whole: every junction at either end of a calm area's access
segments, the same for a commercial square's frontage, the near junction of any dead-end stub
either kind of ground touches, the home street's two junctions, and every junction along a
precinct span. Growth is `REGION_COUNT` seeds by farthest-point sampling (never two in one atom),
then a round-robin breadth-first flood over real segments, one step per region in turn.

**Alleys were atoms in the first build, and that is why the first build's regions were one giant
and three scraps.** An alley's atom is all four corners of its block, and a city's 21 to 26
through-alleys chain those into one atom of 47 to 74 of the 144 junctions — measured on six seeds;
without alley atoms the largest atom is 12 to 23, a single calm zone's ring. One seed put every
calm area into the home region that way, which surfaced as the home having no door and produced a
home-exemption rule that the second build deleted. An alley is a crossing instead: on the tree it
is a door (a `checkpoint_post` at each mouth), off it both mouths are walled.

**The wall stands at a boundary segment's mouth, one tile deep, not its midpoint.** A `roadblock`
body's 60px reach covers about two tiles along the street each way, which from the midpoint
covers an alley mouth at offset 4 outright; at the mouth, with the wall variant's obstruction
overridden to one tile (three bodies across the 192px width, `SealPlanner.place_hard_on`), no
alley mouth is ever under a body, and the whole of a boundary segment's ground belongs to the
region at its far end (`RegionPlanner.ground_region_of`). Which end carries the wall is decided at
generation (`CityMap.boundary_wall_at_a`): the lower region id's end by default, then a greedy
pass over alleys sets a segment's ground to match an alley's other street where possible, which
left **13 of 142** two-street alleys as crossings on the six-seed sweep.

**The tree wins over "a region with no calm area gets no doors".** A door is exactly a crossing
the day's tree uses; everything else on the boundary is wall. That makes the player's rule true on
every day the route does not pass through a calm-less region, and on the days it does — **12 of 48**
sampled (seed, day) pairs — the crossings on the route are doors because *a region edge can never
affect a path* is the stronger rule. The first build's force-wall rule overrode an on-tree segment
6 times in 48 days, which was that decree being broken; it and its home exemption are gone.

**The wall starts on day 7** (`Tuning.REGION_WALL_FIRST_DAY`), the `roadblock` row's own first
day, because the player's words are *"checkpoints in the later acts"* and no day was named. Before
it the regions exist and nothing is drawn. `ClosurePlanner` refuses boundary segments as candidates
and `SealPlanner.plan_day` skips them and crossing alleys, so the wall is the seal there.

**The door.** Three bodies at the wall's own positions: a `checkpoint_hut` on each pavement lane
(hut, doorway to the carriageway, a standing guard) and a `checkpoint_gate` over the road; a
`checkpoint_post` at each mouth of an alley door. The huts and posts detain through
`chatting_mother`'s mechanism — `Tuning.CHECKPOINT_DETAIN_SECONDS` 6.0, `detain_radius` 48 —
and a new `EventDef.redetains` flag re-arms the instance once she is released and outside the
radius, so the toll is paid both ways every time; the chatting mother keeps her once-only
behaviour. On release `Stroller.teleport_to` puts her at the mirror of where she stood, pushed
out `obstructs_radius + PLAYER_BODY_RADIUS + CHECKPOINT_RELEASE_MARGIN` (54px) on the same lane,
velocity and shove zeroed so the friction run-out cannot carry her back in. **The excitement is
the detention's own flat `CHAT_EXCITEMENT`**, plus a hut field of intensity 6.0 over 52/66px:
3.0 was tried first and the events suite refused it — against `EXCITEMENT_DECAY_WALKING` 3.5/s the
walk-through cost came out negative, a field cheaper to walk through than around. Cars stop at the
gate: `Crowd._stop_for_gates` holds a car at `CAR_STOP_LINE_SETBACK` short of a gate on its lane
for `GATE_STOP_SECONDS` (1.2s), the gate reads raised while a car is within a car's length and
lowers after. The `checkpoint` catalogue row became `roadblock` (`Look.ROADBLOCK`), numbers and
picture unchanged, because two rows drawing armed men across a street and meaning opposite things
about whether you can pass could not share a word.

**Measured, six seeds, days 7 to 14** (`tests/test_regions.gd` and `tests/test_checkpoints.gd`
print the same lines): regions of 16 to 56 junctions each — `[56,46,20,20]`, `[34,45,25,38]`,
`[39,40,32,31]`, `[41,52,33,16]`, `[22,39,43,37]`, `[38,46,29,28]`; about 34 boundary crossings a
city, of which a sampled day walls about 24 and opens about 10 as doors; on a four-seed sweep 326
street doors and 4 alley doors over 32 days. The rig held her 6.0s and released her 54px past the
band on her own lane in both directions; a car stopped 1.23s at a gate and passed with it raised.
Reachability without the main road with the wall standing held on 83 of 84 sampled days; the one
miss is the wall closing the specific main-road-free alternative while the tree's own route and
the calm-area guarantee stand, a property the wall never promised, so the test reports it as a
rate rather than asserting it.

**Chosen where the design was silent, and each is cheap to overturn:** the day the wall starts;
the wall's default end; the detention length; the hut's field; `GATE_LANE_TOLERANCE` (40px,
from geometry rather than measurement); one shared timer per gate rather than the junction box's
two-way negotiation, so on a busy two-way street both queues can clear together; `checkpoint_
post` on a 64px alley mouth as a single guard with no hut; the region partition asserted at exactly
`REGION_COUNT` regions since every sampled seed produced four. **Open and unwalked:** whether a
wall at a mouth reads as a district edge; whether six seconds at a hut reads as a toll; whether
the resistance task titled *"The checkpoint"* (`ResistanceSteps`, which spawns a `roadblock`)
should be retitled now that the word means the door. A latent gap found on the way is filed under
M100: a rig that starts `EventManager` before `City.start_day` gets no tree and so no seals and no
wall.
