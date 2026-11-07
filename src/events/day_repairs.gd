class_name DayRepairs
extends RefCounted
## **The two repairs that keep a planned day winnable**: calm ground nothing spoils, and a route to
## it from home. A day can only be won on calm ground, so these are the difference between a hard day
## and an impossible one (docs/CITY.md, "Guarantees").
##
## Each is the last line under a placement rule rather than the rule itself, and both are **only ever
## a removal**, the one monotonic exception the city keeps (**city**, "Check before accepting"):
## taking a body off the ground can only add reachable ground, so nothing another pass decided
## becomes false here.
##
## `EventScheduler.build_day()` asks both once the day is planned, in this order, and hands each
## the day's `DayEvents` (the rows and what they spoil and block) and its `CalmAreas`, so a test
## hands them stand-ins with the answers set. They read the day through those two: on a day with no
## area set aside, the walkable repair keeps a route to every calm tile of the map as dawn sees it
## (`CalmAreas.calm_tiles()`).

## **At least one calm area stays clean every day**, or the day has no safe ground and the player has
## no move (docs/CITY.md). The least disturbed one keeps its quiet.
##
## **It is the last line rather than the rule, and it usually finds nothing to do.** What keeps an
## *unvisited* area clean is `CalmAreas.unused_ground()`, at placement; this runs afterwards and asks
## the one question placement cannot answer — has the day ended up with no clean calm ground
## anywhere, which can only happen once she has settled in every area there is. Two independent
## mechanisms rather than one, for the same reason a reachability check is kept under the corridor:
## the day a placement rule stops holding is the day a run becomes unwinnable, and nothing else would
## say so.
##
## The calm areas are whatever the arcs have left — a requisitioned park is not one, because it is not
## calm any more — and a playground and a scar do not spoil one (`EventScheduler.Planned.spoils()`).
##
## It also takes the block she settled in yesterday, and protects a **different** one where it can.
## Without that the two halves fight: the day deliberately puts something in her park, and then this
## rule, looking for the least disturbed calm ground, finds the block with exactly one spoiler on it
## and strips the very event that was the point.
##
## **`calm.besides()` does not count** — day 12's swing park, which is taken once she has reached
## it, so the clean ground the day owes her has to be somewhere else. It is never stripped here and
## never the one found clean.
static func ensure_one_usable_park(events: DayEvents, calm: CalmAreas) -> void:
	var counted: Array[Vector2i] = []
	for block in calm.blocks():
		if block != calm.besides():
			counted.append(block)
	if counted.is_empty():
		return
	for block in counted:
		if not events.is_spoiled(block):
			return

	# **Every calm area she has not used this act stays clean, not just one of them.**
	# `MIN_CALM_BLOCKS` is derived as an act's worth of days **plus one** on the assumption that the
	# only thing which burns an area is *going* to it — so an area spoiled before she has ever been
	# there brings the run's hard stop a day closer.
	#
	# That rule is enforced at **placement** (`CalmAreas.unused_ground()`), so by the time this runs
	# there is normally nothing to strip. What is left here is the case placement cannot answer:
	# **she has been to all of them**, so nothing was protected and the day could have no clean
	# ground on it at all. A winnable day outranks a fresh decision, so the least disturbed area is
	# cleared and the rest stand.
	var untouched: Array[Vector2i] = []
	for block in calm.unused():
		if block != calm.besides():
			untouched.append(block)

	if untouched.is_empty():
		var least: Vector2i = counted[0]
		for block in counted:
			if events.spoilers_of(block).size() < events.spoilers_of(least).size():
				least = block
		untouched = [least] as Array[Vector2i]

	for block in untouched:
		for plan in events.spoilers_of(block):
			events.remove(plan)

## Checkpoints, barricades and roadblocks physically close streets, and from Act IV several
## can land on the same day. Any combination that seals the home off from every park makes
## the day unwinnable in a way the player cannot see coming, so obstructions are dropped —
## widest first — until a route exists again. What obstructs is
## `EventScheduler.Planned.obstructs()`: a hard fail counts as a wall here too.
##
## **On days 9, 12 and the finale's it keeps a route to the day's resistance target as well**
## (`target`: the tiles of the door, the swing or the station's door the contact may stand on, already
## past the director's own refusals of the tile — see `EventManager.start_day()`). The day is
## planned so the route exists: the target is tree ground (`RouteTree.for_day`), so no seal stands
## on the way, no closure lands on it and no wall is placed on it, and this is the last line under
## that for the catalogue's own bodies — which may stand on the corridor as friction — the same
## second opinion it is for the calm. Asked the way `ResistanceDirector._reachable_from_home()` asks
## it, so the tile the director then picks is one this guarantees: under
## `EventScheduler.blocked_by()`'s discs of every obstructing plan, `events.standing()` included,
## since the seals and the region wall's own bodies (planned before this, and never this pass's to
## drop) obstruct the day too.
##
## **A day whose target is already reachable loses nothing.** When `events.standing()` alone seals the
## target off, dropping the catalogue's bodies cannot help, so the target half asks nothing of them
## rather than emptying the day for no route — a construction failure the resistance suite's sweep
## exists to catch, noted in `trace` if it ever happens in play.
##
## **`calm.besides()` is a calm area the calm half does not count** (day 12's swing park). The route
## kept is then to a calm area other than it, and to a clean one — nothing the day planned spoiling
## it, which `ensure_one_usable_park()` has just made sure exists — where one is reachable with every
## body gone; otherwise to any other calm ground. Reached from home, it is reached from the swing too:
## the swing is kept reachable from home by the target half, and walking is the same both ways.
static func ensure_the_city_is_still_walkable(map: CityMap, events: DayEvents, calm: CalmAreas,
		target: Array[Vector2i] = [], trace: RunTrace = null) -> void:
	var blockers := events.obstructions()
	if blockers.is_empty():
		return

	blockers.sort_custom(func(a: EventScheduler.Planned, b: EventScheduler.Planned) -> bool:
		return a.blocking_radius() > b.blocking_radius())

	# Built once and asked once per blocker dropped, which is a handful of iterations at most —
	# the grid is the day's tiles, which none of this loop changes.
	var grid := ReachabilityGrid.build(map)
	var fixed := events.standing_obstructions()
	var kept_target: Array[Vector2i] = target
	if not target.is_empty() and not _target_is_reachable(map, grid, target, fixed):
		if trace:
			trace.note("plan", "the day's own seals and wall cut the resistance's target off")
		kept_target = []
	var kept_calm := _calm_to_keep_reachable(map, events, calm, grid)
	while not blockers.is_empty() and not (_park_is_reachable(map, grid, blockers, kept_calm)
			and _target_is_reachable(map, grid, kept_target, fixed, blockers)):
		events.remove(blockers.pop_front())

## The calm tiles `ensure_the_city_is_still_walkable()` keeps a route to: every calm tile on an
## ordinary day; with `calm.besides()` set, the calm tiles of every *clean* area but that one which is
## reachable under today's closures alone, falling back to the calm tiles of every area but that one.
static func _calm_to_keep_reachable(map: CityMap, events: DayEvents, calm: CalmAreas,
		grid: ReachabilityGrid) -> Array[Vector2i]:
	if calm.besides() == CalmAreas.NONE:
		return calm.calm_tiles()
	var reached := grid.flood([map.home_rect.position], map.closed_tiles)
	var clean: Array[Vector2i] = []
	var other: Array[Vector2i] = []
	for block in calm.blocks():
		if block == calm.besides():
			continue
		var tiles := calm.calm_tiles_of(block)
		var reachable := false
		for tile in tiles:
			reachable = reachable or grid.reaches(tile, map.closed_tiles, reached)
		other.append_array(tiles)
		if reachable and not events.is_spoiled(block):
			clean.append_array(tiles)
	return clean if not clean.is_empty() else other

## Whether some tile of `target` is reached from the home with every one of `blockers` and
## `more_blockers` standing — `ResistanceDirector._reachable_from_home()`'s own question, asked of
## the pool rather than of one tile. True of an empty `target`, which is every day without a narrow
## resistance target.
static func _target_is_reachable(map: CityMap, grid: ReachabilityGrid, target: Array[Vector2i],
		blockers: Array[EventScheduler.Planned],
		more_blockers: Array[EventScheduler.Planned] = []) -> bool:
	if target.is_empty():
		return true
	var blocked := EventScheduler.blocked_by(map, blockers)
	for plan in more_blockers:
		EventScheduler.block_a_disc(map, blocked, plan.position, plan.blocking_radius())
	var reached := grid.flood([map.home_rect.position], blocked)
	for tile in target:
		if grid.reaches(tile, blocked, reached):
			return true
	return false

## Whether the grid still finds a way from the home to some calm tile, with `map.closed_tiles` —
## today's closures, at the precision `RoadClosure.tiles()` gives them — plus every blocker's own
## obstruction circle added on top.
##
## **This asks the same grid `ClosurePlanner._invariant_holds` does**, so the two reachability
## answers are one function apart rather than two implementations that could drift: both are
## `ReachabilityGrid.flood()`/`reaches()` under a `blocked` set, and the grid does not care whether
## the tiles in it came from a candidate's barrier or an event's circle.
##
## `kept_calm` is the calm ground to ask about, every calm tile when empty.
static func _park_is_reachable(map: CityMap, grid: ReachabilityGrid,
		blockers: Array[EventScheduler.Planned], kept_calm: Array[Vector2i] = []) -> bool:
	var blocked := EventScheduler.blocked_by(map, blockers)
	var reached := grid.flood([map.home_rect.position], blocked)
	for tile in kept_calm if not kept_calm.is_empty() else map.calm_tiles():
		if grid.reaches(tile, blocked, reached):
			return true
	return false
