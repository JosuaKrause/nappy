# minty-quail — Every day's locations are drawn from a bag per view · 2026-11-08

minty-quail's `placement-by-construction.md`, its third step split in two; this is the first half,
in #1254.

**Built.** Locations are laid out on every day, not on day 13 alone, and beyond the streets: an
alley is three locations along it, a square or park a grid of 4-tile cells, a junction box one
location its streets share, the whole box (its corners, its carriageway and its crossings); a section that draws a carriageway event takes its two sidewalks with
it, and `Corridor.view_of_ground()` gives each location its view. `ViewBag` is one view's bag:
marbles drawn without putting back and refilled once empty, a marble a location refuses kept for
the next one, each location's weight scaling a marble's share. `LocationDraw` draws every open
location once within the caps, asking `LocationGround`, whose one implementation for now,
`JudgedLocationGround`, is today's `_judge()` behind that interface and holds the per-location
weights (inbox #1185's board answer 5(c)): precinct ×4, the street between two route strands ×6
for a costly wall, the alley mouse beside a sack pile ×5, the mouse trying the tiles beside the pile
first. A row's weight per kind of ground (`EventScheduler.GROUND_WEIGHTS`) is fitted so its daily count
holds today's, since ground with few locations would otherwise get few draws; a row's weight per
view comes from its role (`view_weight()`); the empty marbles from today's
measured share per view and day (`VIEW_SHARES`), scaled per view and per day (`ON_SHARE_SCALES`,
`ADJACENT_SHARE_SCALES`, `OFF_SHARE_SCALES`, fitted on 18 seeds); the moments she is owed stay in the
director's bag, from `MOMENTS_PER_DAY`. Heat raises a pressing row's weight with its cap. The draw is handed each row's cap; on the
gatehouse day every wall-role row has its weight and its cap scaled by the day's share (azure-puffin
4), a fractional cap rounded up or down at random on its own stream, so a wall whose cap binds is
thinned as well. Deleted:
the fill, the day's budget (`budget_for`'s use as a budget, `EventDef.cost`), the wall thinning,
`_pick_weighted`, the old mouse preference, and the fill's day-13 roadblocks, which now come from
the roadblock phase alone. #1249's two notes: the swap's pair is a typed
`ResistanceDirector.SectionToSwap`, and the content test starts from her real screen view.

**Measured.** Against main (`9f148031c`) with `tests/probes/placement_rows.gd`, which asks only
what every tree has, over three samples: 18 cities the tables were fitted on (`90210+31i`), 18 more
(`70001+37i`) whose counts the walls-and-friction scales were also fitted on, and the reviewer's 14
(`31337+43i`), used in no fit; a cell is outside noise past two standard deviations (√(a+b)). The
fit: each row's weight per kind of ground (`GROUND_WEIGHTS`), each view's scale per day
(`VIEW_SHARE_SCALES`), and the walls and the friction per view and act (`WALL_VIEW_SCALES`,
`FRICTION_VIEW_SCALES`), stepped together until the passes moved within noise. A day's count is
within ±1% to ±5% of main's on every sample. **Her route's walls and friction**, pooled over the 50
cities, per city per day: walls 6.39 → 6.33 (−1.0%) and friction 19.41 → 19.09 (−1.7%), days 9-14
walls 4.16 → 4.14; no single day of either outside noise. Before the per-view role scales the bags
moved walls off her route (6.39 → 5.84, −8.6%, and −14.5% from day 9) and onto the ground off it
(+9.3%); the orchestrator sent that back as a change to what the route decision faces, as it had
sent back the first version's route about 10% light. Each row per kind of ground, averaged over the
days, on the fitted cities: from −8% (roadblocks on the carriageway, day 13's) to +6%, but for the
chatting mother at junctions (−28% to −40%, below) and the rows of a tenth of an event a day or less
(the square's poster crew, the protest on open ground, ±25% to ±50% on counts of a few dozen).

**The day-6 man shouting.** The test's bar fell short on its five pinned cities, and the builder's
first answer lowered it to more than half of 44 cities; the orchestrator sent that back, since the
player asked for a guarantee (olive-koala 2). Over 44 cities, on main and on the branch, the rig
holds every time: the bag is rigged at the mark and he is sited, before more than two events are
handed out, ahead of her on the street she walks, out of her view. The old check counted whether
the test's fixed walk brought him into view, and that walk turns off his street on about half the
cities. The test now checks the guarantee itself, on every pinned city. Left for the walk's draws
(the step after this one): a body already in the world is never moved, so a player who turns at the
next junction passes him by.

**Choices where the design was silent, open to overturn:** the step split in two, the bags and the
draw first with `_judge()` still deciding a candidate, `StreetRule`s and `LocationFit` in its place
next; each view's scale per day, the walls' and the friction's per view per act, the act being what the late days' walls asked for and as fine as the counts allow; parity held
per row per kind of ground, not per row per view; the moments she is owed a fixed count per day
(23 to 32, measured on main).

**For the end-of-refactor remeasure:** what this step changes on purpose, or leaves outside noise,
with its figures (main → head, events a day).
- Day 13's roadblocks are the roadblock phase's alone: 23.1 → 17.1 on every sample, and the task
  swaps more often for it.
- The moments she is owed are a fixed count per day (`MOMENTS_PER_DAY`, 23 to 32), where the fill's
  rolls made them vary by city.
- The gatehouse day's share scales every wall-role row's weight and cap, the cap's fraction rounded
  at random on its own stream.
- A junction box is one location, the whole box.
- Density near the region doors: `test_checkpoints` lets the doors' gap cost up to a fifth.
- Dawn planning time: +29% for the same day plans, the reviewer's measurement at `11f088f98`, not
  measured again on the final head.
- Off her route, walls +2.8% pooled over the 50 cities (just outside noise).
- The chatting mother at junctions, 0.4 → 0.3 (fitted) and 0.4 → 0.2 (unseen, the reviewer's): her
  cap of two is spent on the streets, drawn before the ground beyond them.
- By view, while each row's count per kind of ground holds: the man shouting on her route +15%,
  route-adjacent −10% to −13%; the police patrol on her route −14% to −15%, route-adjacent +18% to
  +28%; roadblocks on her route +13% to +24%, route-adjacent −13% to −19%, off it −10% to −17%; the
  pigeons route-adjacent −16% to −25%, off the route +10% to +19%; the market stall off the route
  +30%; the delivery van off the route +14%; the reversing lorry route-adjacent −22% to −30%, off the
  route +14%; the chatting mother on her route −11% to −27% and off it +24% to +67%; the leaf blower
  off the route −11%.
- Single days: the delivery van on day 1 (12.3 → 9.9 to 10.2); the market stall on days 2, 5, 8 and
  11; the man shouting on days 12 to 14 (+20% to +34% on days 13 and 14); the reversing lorry on
  days 6, 10 and 14; cafe tables on day 11 of the reviewer's cities (11.4 → 8.4).
