# minty-quail — Every day's locations are drawn from a bag per view · 2026-11-08

minty-quail's `placement-by-construction.md`, its third step split in two; this is the first half,
in #1254.

**Built.** Locations are laid out on every day, not on day 13 alone, and beyond the streets: an
alley is three locations along it, a square or park a grid of 4-tile cells, a junction box one
location its streets share; a section that draws a carriageway event takes its two sidewalks with
it, and `Corridor.view_of_ground()` gives each location its view. `ViewBag` is one view's bag:
marbles drawn without putting back and refilled once empty, a marble a location refuses kept for
the next one, each location's weight scaling a marble's share. `LocationDraw` draws every open
location once within the caps, asking `LocationGround`, whose one implementation for now,
`JudgedLocationGround`, is today's `_judge()` behind that interface and holds the per-location
weights (inbox #1185's board answer 5(c)): precinct ×4, the street between two route strands ×6
for a costly wall, the alley mouse beside a sack pile ×5, the mouse trying the tiles beside the pile
first. A row's weight per view comes from its role (`view_weight()`); the empty marbles from today's
measured share per view and day (`VIEW_SHARES`), scaled per view and per day (`ON_SHARE_SCALES`,
`ADJACENT_SHARE_SCALES`, `OFF_SHARE_SCALES`, fitted on 18 seeds); the moments she is owed stay in the
director's bag, from `MOMENTS_PER_DAY`. Heat raises a pressing row's weight with its cap. Deleted:
the fill, the day's budget (`budget_for`'s use as a budget, `EventDef.cost`), the wall thinning,
`_pick_weighted`, the old mouse preference, and the fill's day-13 roadblocks, which now come from
the roadblock phase alone. #1249's two notes: the swap's pair is a typed
`ResistanceDirector.SectionToSwap`, and the content test starts from her real screen view.

**Measured.** Against main over 18 seeds per day and 18 more not used in the fit: the share of
on-route locations holding an event is within +1.3% of today's on average (−14% to +13% per day on
the unseen cities, inside the ±13% two-standard-deviation noise of about 490 events a side); a day's
count within 5%. One scale per view, the first version, left her route about 10% light and 17% on
days 7 and 8, which the orchestrator sent back as a change to what the route decision faces.

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
next; a per-day scale rather than per act, neither distinguishable on unseen cities; in the
gatehouse day's share of hard blocking, only walls with a body in the way or a lethal field count
as hard.
