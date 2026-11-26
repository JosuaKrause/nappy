extends "res://tests/events_shared_city.gd"
## The two halves of `EventScheduler.role_for`: a lethal event is a wall and a wall never stands
## on ground a route runs along, and friction is aimed at the route as a weight rather than a rule.
## Plus the placement rules a pinned or pacing row keeps on top of that: a pinned row is only
## offered ground it can be pinned on, a square's own poster crew never leaves the square, a pacing
## row on the route's sidewalk can still be left room to pass, a route's own junctions and sidewalk
## stay clear of what it schedules, and a flock is scenery rather than a placed obstruction. Also what
## the catalogue's placements keep true on a planned day: a parked van at the kerb, a lorry with a
## wall to back into, nothing on the doorstep street, nothing on ground a route holds, no body
## closing a walked sidewalk, and no spread on a corner.
##
## Extends `events_shared_city.gd` for the cases that read the shared city's day plans (the parked van, the
## lorry, the doorstep street); every other case rolls its own seed on its own generated map.
##
## **Where each case gets its city.** The held-ground and walked-sidewalk cases generate their own
## cities (`CityGenerator.generate()`), and the parked van, lorry, doorstep street, flock and
## corner-refusal cases read the shared test city of `events_shared_city.gd`, which is generated
## outside the cache. Every other case is handed a copy of its seed's city from the cache of generated cities
## (`tests/city_map_cache.gd`): each seed is generated once in the test process, and the copy is the
## same city `CityGenerator.generate()` builds for the seed. A case that plans a city over many
## days works the city's mast sites out once, on the city as built and before the first day repaints
## it (`_sites_of()`), and hands them to every dawn it plans, as the game does. The one case that
## hands a placement a stand-in ground (`_test_a_placement_asks_the_ground_it_is_handed`) stands
## on drawn streets (`StreetMap.full()`): the ground is the stand-in's, the map is only where the
## tiles are.
##
## **Why these cases keep generated cities.** What each sweep asks is a placement rule's behaviour
## among the ground a whole day's routes leave (which tiles a route holds, which sidewalks it
## walks, where a row's body fits), and the floors under their counts rest on what the generator
## produces across seeds, so a hand-drawn street shape would hold a different, smaller claim. The
## four sweeps that plan the same seed's day on its routes share one plan
## (`_planned_on_the_route()`), and the flock case and the corner-refusal case read the shared
## city's days (`_planned()`), which the planning of a day leaves as it was (it spends nothing).
##
## **Day 1 here grows the ordinary tree**, deliberately: these sweeps hand `RouteTree.for_day()` no
## tutorial route, since what each asks is a rule over any day's tree; the tree day 1 grows in
## the game, along the tutorial route, is held by `tests/test_seals.gd` and
## `tests/test_events_scheduler.gd`'s day-1 case (`_test_day_one_on_the_tutorial_tree`).
##
## **Why a real city is built here.** This is not a direct test of the city: these cases ask what the
## dawn plans on a generated city (where a day's rows were placed), so they need a city and a planned
## day. The dawn's group handed each dawn the city's mast sites and shared one plan between the cases
## that ask the same day (the record minty-quail-amber-elk), and rejected moving the sweeps onto
## hand-drawn maps. One case builds no city: the lethal row's reach case asks the rows alone. The
## friction case repaints the seed-4242 city per day and grows its routes on it.

const MapCache := preload("res://tests/city_map_cache.gd")
const STEP := 1.0 / 60.0

## **A seed's day planned on that day's routes**, once for the suite (`_planned_on_the_route()`):
## the plan of a city's day from the stream `_rng(day)` hands out, a fresh run (nothing spent) and
## the route tree the day grows, with the city's mast sites. The four sweeps that ask exactly this
## of a seed's city (the pacing row's sweep, the junctions, the route's own sidewalk and the
## pacing row's opening) read it, each against its own repainted copy of the city, and none writes
## to a plan. The key is the seed and the day (the count of blocked segments it also holds is the
## city's absent streets, the same every day); what keeps a changed map out is the helper's refusal
## of a city with closed tiles: a case that
## closes streets or holds segments before it plans (held ground, the walked sidewalk) plans its
## own dawns, since the dawn's placement reads those and a plan made on another map state is
## another answer.
var _route_plans := {}

func _planned_on_the_route(map: CityMap, sites: Array[MastSites.Site], day: int,
		tree: RouteTree) -> Array[EventPlan]:
	assert(map.closed_tile_set().is_empty(),
			"a plan shared by the suite is planned on an open map")
	var key := "%d:%d:%d" % [map.city_seed(), day, map.blocked_segments().size()]
	if not _route_plans.has(key):
		var consumed: Array[String] = []
		_route_plans[key] = GameDawn.of(DaySpec.for_day(day), _rng(day), map) \
				.masts(sites).spent(consumed).on(tree).plan().placements()
	return _route_plans[key]

func run(t: TestRunner) -> void:
	_test_the_day_is_placed_by_role(t)
	_test_friction_on_a_sidewalk_can_be_walked_past(t)
	_test_a_pinned_row_is_only_offered_ground_it_can_be_pinned_on(t)
	_test_the_square_poster_crew_only_ever_stands_on_a_square(t)
	_test_a_placement_asks_the_ground_it_is_handed(t)
	_test_a_recipes_drawn_row_keeps_its_route_on_its_run(t)
	_test_a_pacing_row_on_the_routes_sidewalk_can_be_left(t)
	_test_a_routes_junctions_stay_clear(t)
	_test_nothing_takes_the_routes_own_sidewalk(t)
	_test_a_pacing_rows_opening_stays_open(t)
	_test_a_flock_is_scenery(t)
	_test_a_lethal_rows_line_reach_is_its_whole_field(t)
	_test_a_parked_van_is_at_the_kerb(t)
	_test_a_lorry_has_a_wall_to_back_into(t)
	_test_nothing_stands_on_the_doorstep_street(t)
	_test_nothing_the_catalogue_places_stands_on_held_ground(t)
	_test_no_body_closes_a_walked_sidewalk(t)
	_test_a_spread_never_lands_on_a_corner(t)


## The two halves of `EventScheduler.role_for`, checked in one pass over the days because each of
## them costs a whole `build_day` and the suite is already the slowest thing in this project.
##
## **A lethal event is a wall, and a wall never stands on ground a route runs along.**
## *(`docs/CITY.md`: "hard and lethal blockers form the paths — they are the walls… the route is
## what is left between them.")* This is the one absolute in `RowGround._times_for_role()` and it is what the
## milestone can most easily get wrong: a lethal row on the route she is being guided down is not a
## wall in the wrong place, it is the guidance pointing at the thing it exists to point away from.
##
## **Asked per sidewalk, which is why the far side of a route's own street is counted separately
## below rather than treated as a failure.** A branch runs along one sidewalk of a street, so the
## other one is ground no route walks and is where a wall belongs — *"the market stall should appear
## on the other side of the street"*. `corridor.depth()` cannot tell those two apart, so the
## assertion asks `carries_a_route()` and the count is what shows the distinction is live.
##
## **Friction is aimed at the route**, which is the other half of the same sentence: *"benign
## blockers go on the route… to make it more challenging."* That one is a **weight**
## (`EVENT_CORRIDOR_WEIGHT`, four copies of an on-corridor tile in the roll). Its upper bound is
## asserted: a corridor carrying nearly all of it would mean every street off the route is empty,
## which reads as a set rather than as a city. **The floor is a relation, not a number**: the share
## depends on the city (three rules take corridor ground away from a row: one cutting her line
## through a crossing is refused it, `RouteLineRule`; one that would close the route's sidewalk,
## `RouteSidewalkRule`; a pacing row with no way off its sidewalk,
## `StreetInvalidation._a_pacing_beat_walls_a_sidewalk`), so the costly rows placed on the corridor are compared with
## what a draw without the weight would put there: for each, the corridor's share of the ground
## `RowGround.tiles_for()` offers that row, summed. With the weight at 1 the placed count
## falls under that sum; with it on, it stands well over it on every city tried.
##
## **The whole share sits under its own natural ceiling because `delivery_van` counts as a wall in
## this tally while its own ground is weighted exactly like friction.** `delivery_van` is a wall by
## fit (`_closes_the_band_by_its_own_placement`) and is refused every route-carrying cell like any
## other wall, so it never shows up as `friction_on_the_route` even though `RowGround._times_for_role()`'s `by_cost`
## clause spreads its ground the same way friction's is spread.
##
## An `AHEAD_OF_PLAYER` row is exempt from the first half and the exemption is the design rather
## than a hole: the charging dog is sited by `EventDirector` in front of wherever she turns out to
## be walking, so it is by construction on her route and the scheduler never chose a tile for it.
## That is why `EventScheduler.role_for()` calls it `NONE` — see the note there.
##
## Five days rather than fourteen. What is being checked is a property of the construction, and the
## days are sampled across the acts so that the catalogue's lethal rows (none before day 5) and its
## late density are both in the sample.
##
## **Its own city rather than the shared `_map()`**, because it repaints one — which blocks and
## arcs are calm is what a `RouteTree` grows from, so the tree has to be grown against today's
## paint. The shared map is handed out pristine and the day plans memoized against it would be
## answers about a city that no longer existed if this repainted underneath them.
## Half the width of a junction box (`Tuning.STREET_WIDTH` tiles square, 192px), which is the reach
## below which a row standing on a street beside a crossing cannot cover the box's own six-tile arm
## however close it stands. Used to split the friction into the rows the box's half of the line
## rule (`RouteLineRule`) can refuse corridor ground and the rows it cannot.
const _A_JUNCTION_BOXES_HALF_WIDTH := Tuning.STREET_WIDTH * Tuning.TILE_SIZE * 0.5

func _test_the_day_is_placed_by_role(t: TestRunner) -> void:
	var map := MapCache.of(4242)
	var sites := _sites_of(map)
	# The day's poster crews are drawn by exactly these rules and handed to her walk with no
	# position (`MarbleDraw.draw()`). What this asks is how the draw places, so the crews are
	# read where the draw put them.
	var crew_draft := EventCatalogue.shipped().by_id("poster_crew").redraft()
	crew_draft.not_sited_from_her_walk()
	var crew := crew_draft.build()
	var walls := 0
	var walls_across_the_street := 0
	var friction_on_the_route := 0
	var friction := 0
	# What a draw with no weight would put on the corridor: per friction row, the corridor's share of
	# the ground that row may stand on.
	var friction_on_the_route_unweighted := 0.0
	var narrow := 0
	var deep := {true: 0, false: 0}
	var placed := {true: 0, false: 0}
	# Every gap of every day sampled, and which of them a wall was put in. Keyed by day as well as
	# by street, because the same street is a gap on one day and ordinary ground on another.
	var gaps := {}
	var gaps_walled := {}
	for day: int in [1, 5, 8, 11, 14]:
		var state := CityState.new()
		state.begin_day(map.plans_by_block(), day)
		map.repaint(state)
		var tree := RouteTree.for_day(map, day, null)
		var corridor := Corridor.of(tree)
		for key in tree.gaps():
			gaps["%d:%s" % [day, key]] = true
		var consumed: Array[String] = []
		var ground := EventScheduler.row_ground(map)
		for plan in GameDawn.of(DaySpec.for_day(day), _rng(day), map) \
				.masts(sites).with_row(crew) \
				.spent(consumed).on(tree).plan().placements():
			if not plan.is_placed():
				continue
			var tile := map.world_to_tile(plan.placed_at())
			var away := corridor.depth(tile)
			if plan.role() == GameEnums.BlockerRole.WALL and corridor.is_in_a_gap(tile):
				var segment := map.street_network().segment_containing(tile)
				if segment:
					gaps_walled["%d:%s" % [day, segment.key()]] = true
			if plan.role() == GameEnums.BlockerRole.WALL:
				walls += 1
				t.check(plan.ends_the_day()
						or plan.row().walk_through_cost() >= EventScheduler.WALL_WORTH_OF_COST
						or _takes_a_whole_sidewalk(plan.row())
						or _paces_a_beat_with_no_way_out(plan, map),
						"day %d: '%s' is a wall because it is lethal, very costly, leaves no line"
						% [day, plan.row_id()] + " past it on a sidewalk, or paces one with no"
						+ " crossing in its beat")
				t.check(not corridor.carries_a_route(tile),
						"day %d: the wall '%s' at %s stands on no ground a route runs along"
						% [day, plan.row_id(), RunTrace.tile(tile)])
				if away == 0:
					walls_across_the_street += 1
				placed[plan.ends_the_day()] += 1
				if away >= 2:
					deep[plan.ends_the_day()] += 1
			elif plan.role() == GameEnums.BlockerRole.FRICTION:
				friction += 1
				if away == 0:
					friction_on_the_route += 1
				var offered := ground.tiles_for(plan.row())
				var on_it := 0
				for offered_tile in offered:
					if corridor.depth(offered_tile) == 0:
						on_it += 1
				friction_on_the_route_unweighted += float(on_it) / maxf(1.0, float(offered.size()))
				# The rows small enough to stand beside a crossing without taking it.
				if plan.line_reach() <= _A_JUNCTION_BOXES_HALF_WIDTH:
					narrow += 1
	# A sample with no walls in it would pass every assertion above and mean nothing.
	t.check(walls > 20, "the days sampled place walls at all (%d)" % walls)
	# And a sample where no wall ever landed across the street from a route would satisfy the
	# per-sidewalk assertion above with nothing but ordinary off-corridor ground under it — the
	# refusal would read the same whether it was stated per street or per sidewalk. *"The market
	# stall should appear on the other side of the street where for some reason no event was
	# chosen"* is the placement that had to become possible, so it is counted.
	t.check(walls_across_the_street > 0,
			"and some of them stand on a route street's far sidewalk (%d)" % walls_across_the_street)
	t.check(friction > 0, "and friction at all (%d)" % friction)
	t.check(narrow > 50, "and enough of it narrow enough to stand beside a crossing (%d)" % narrow)
	var share := float(friction_on_the_route) / maxf(1.0, float(friction))
	t.check(friction_on_the_route > friction_on_the_route_unweighted,
			("the weight puts more costly rows on the corridor (%d) than a draw over the ground "
			+ "they may stand on would (%.1f of %d)")
			% [friction_on_the_route, friction_on_the_route_unweighted, friction])
	t.check(share < 0.9, "and the streets off it are not empty (%.0f%% on it)" % (share * 100.0))

	# **The range, as a relationship rather than as two numbers.** *"It ranges from very costly to
	# deadly"* is a claim about which of the two is further from the routes, so that is what is
	# asserted: a day where both bands happened to be equally deep would satisfy any pair of
	# thresholds and would not be a gradient. `dog_walker` staying friction is the other half and is
	# checked where the constant is set — see `EventScheduler.WALL_WORTH_OF_COST`.
	t.check(placed[true] > 10 and placed[false] > 10,
			"the sample has both kinds of wall in it (%d lethal, %d very costly)"
			% [placed[true], placed[false]])
	var deadly_deep := float(deep[true]) / maxf(1.0, float(placed[true]))
	var costly_deep := float(deep[false]) / maxf(1.0, float(placed[false]))
	t.check(deadly_deep > costly_deep,
			"and the deadly end of the range sits further off the routes than the costly end "
			+ "(%.0f%% against %.0f%% two turnings out)" % [deadly_deep * 100.0, costly_deep * 100.0])

	# **A gap is sometimes closed and sometimes open, and both halves are the instruction.** *(M55,
	# playtest 17 finding 2: "sometimes put a blocker between (wall or event) and sometimes leave it
	# open".)* Asserted as a band rather than a number, because `EVENT_WALL_GAP_WEIGHT` is a weight
	# and the exact share moves with the catalogue — what may not move is that neither end is empty.
	# A day that walled every gap would have turned one corridor into several separate ones, which
	# is the shape `RouteTree` deliberately does not grow; a day that walled none is the finding.
	#
	# **The floor is 0.2 because a precinct is safe ground and a wall is danger.** A precinct's box
	# carries no `ROAD` or `CROSSING` tile, so the rows that place on a carriageway — the patrol, the
	# roadblock — cannot sit in a gap that runs through one. The `SIDEWALK`-placed rows still can,
	# which is why this is a smaller pool of candidates rather than a gap nothing may ever wall, and
	# why the denominator is still every gap: measured over the same map and the same sampled days,
	# 26 of 89 gaps carried a wall before the precinct's box was paved and 21 of 89 after it — the
	# count of gaps itself does not move, because which segments qualify is `RouteTree`'s business
	# and nothing here touches it. Five gaps, all of them through the one stretch of the city whose
	# design is that it is the safest ground in it. The band is what the check is for; the exact
	# share moves with the catalogue.
	t.check(gaps.size() > 20, "the days sampled have gaps between adjacent strands (%d)" % gaps.size())
	var walled_share := float(gaps_walled.size()) / maxf(1.0, float(gaps.size()))
	t.check(walled_share > 0.2, "%d of %d gaps carry a wall" % [gaps_walled.size(), gaps.size()])
	t.check(walled_share < 0.85,
			"and the rest are left open (%.0f%% walled)" % (walled_share * 100.0))

## **Anything the day still aims at the route can be walked past on the route's own sidewalk.**
## *(PLAYTEST-77: "on the side of the street where the path was chosen only obstacles that can be
## bypassed should be possible.")* Friction is the role weighted *onto* the corridor
## (`EventScheduler.EVENT_CORRIDOR_WEIGHT`, four copies of an on-corridor tile in the roll), so what stays
## friction is what the guidance walks her into — and a sidewalk is two lanes of tile, so a row
## reaching across both of them from either has taken the last line along it.
##
## **This asserts the consequence rather than the clause.** `EventScheduler.role_for` answers
## `WALL` for a row that leaves no line; what has to be true afterwards is that every row still
## aimed at the route leaves one, which is the sentence the player wrote and the thing that would
## go red if the clause were weakened or if a new catalogue row were given a wider field than its
## role can carry.
##
## **The role is read off a placement the scheduler makes** (`_role_it_places_as()`), not off the
## function that derives it, so a row the day cannot place is not asked: the days are 8 and 14,
## when the catalogue's costly sidewalk rows are on offer. A role can move with the day
## (`charging_dog` is director-sited on `Tuning.RUN_TAUGHT_DAY` and map-placed after it).
##
## **A pacing row is not one of the rows this is about**, and the exclusion is the design rather
## than a hole: a beat takes its ground in time, so what a walk needs past one is a phase rather
## than a lane. `_test_a_pacing_row_on_the_routes_sidewalk_can_be_left` is its half of the same
## question, and this count would be the wrong instrument for it.
##
## **A body narrow enough to move off the wall's own middle can still stay friction**, and
## `poster_crew` is the row that proves it: `AGAINST_THE_BUILDING` rather than `ANY` (a crew pastes
## posters at the wall it works on, not in the middle of the pavement) pins its 11px body to the
## frontage lane's own tile centre, `TILE_SIZE * 0.5` from the wall, spanning 5-27px of the 64px
## band and leaving 37px to the kerb — over the 28px she needs — where centred it would have left
## only 21px on each side. So the population below is one row across two days rather than the two
## rows (`delivery_van` and `poster_crew`) it used to be before either was read against the
## physical clause at all; `delivery_van` stays a wall by the same reading
## (`_closes_the_band_by_its_own_placement`'s own doc has its arithmetic).
##
## **The second loop is independent of the scheduler's role on purpose**, re-deriving the edge-to-edge gap
## by hand rather than asking the scheduler for it, so a future row narrow enough to slip both
## readings is caught by its own numbers rather than assumed impossible. `burning_building`
## (`ONE_SHOT`) is excluded from it since a set piece is never asked the friction-or-wall question.
func _test_friction_on_a_sidewalk_can_be_walked_past(t: TestRunner) -> void:
	var checked := 0
	for day: int in [8, 14]:
		var map := _repainted_city(day)
		var corridor := Corridor.of(RouteTree.for_day(map, day, null))
		for def in CatalogueRows.every():
			if not def.stands_on(GameEnums.TileType.SIDEWALK) or def.paces_a_beat():
				continue
			if _role_it_places_as(def, day, map, corridor) != GameEnums.BlockerRole.FRICTION:
				continue
			if not def.has_a_line_to_avoid():
				continue
			checked += 1
			t.check(not def.reaches_the_far_lane(),
					"day %d: '%s' is friction on a sidewalk and denies %.1fpx of it, so the far"
					% [day, def.id(), def.line_reach()]
					+ " lane (%.0fpx out) is still a line" % float((Tuning.SIDEWALK_WIDTH - 1) * Tuning.TILE_SIZE))
	t.check(checked >= 2,
			"and the catalogue has rows on a sidewalk to ask it of (%d)" % checked)

	var solid_on_a_sidewalk := 0
	var narrow_and_placed := 0
	var her_clearance := 2.0 * Tuning.PLAYER_BODY_RADIUS
	var cities := {}
	for day: int in [8, 10, 14]:
		cities[day] = _repainted_city(day)
	for def in CatalogueRows.every():
		if not def.stands_on(GameEnums.TileType.SIDEWALK) or def.paces_a_beat() or def.moves():
			continue
		if def.obstructs_within() <= 0.0:
			continue
		# A `ONE_SHOT` is a set piece, not asked the friction-or-wall question at all
		# (the scheduler answers it before the cost or physical clause ever runs), so a
		# solid one on a sidewalk is exempt here. `burning_building` carries no body (the fire truck
		# it calls in is the danger, not the fire), so the check above already passes it over.
		if def.is_a_one_shot():
			continue
		solid_on_a_sidewalk += 1
		var gap := _gap_past_the_body(def)
		if gap >= her_clearance:
			continue
		# Read off the placement the scheduler makes on each of the days that can place the row
		# (the placement a recipe asks for, `EventScheduler.recipe_placement()`); `night_raid`
		# is on offer on day 10 alone.
		var placed_on := 0
		for day: int in cities:
			var map: CityMap = cities[day]
			var role := _role_it_places_as(def, day, map, Corridor.of(RouteTree.for_day(map, day, null)))
			if role == -1:
				continue
			placed_on += 1
			t.check(role == GameEnums.BlockerRole.WALL,
					"day %d: '%s' leaves %.1fpx where she needs %.0f (obstructs %.1fpx, %s), so it has to"
					% [day, def.id(), gap, her_clearance, def.obstructs_within(),
					EventDef.Pavement.keys()[def.sidewalk_lane()]]
					+ " be placed as a wall rather than friction")
		narrow_and_placed += 1 if placed_on > 0 else 0
		t.check(placed_on > 0, "'%s' is placed on one of the days asked (%d)" % [def.id(), placed_on])
	t.check(solid_on_a_sidewalk >= 4,
			"and the catalogue has solid, non-pacing sidewalk rows to ask this of (%d)"
			% solid_on_a_sidewalk)
	t.check(narrow_and_placed >= 1,
			"and some of them leave her too narrow a gap to pass, placed as a wall (%d)"
			% narrow_and_placed)

## A city of seed 4242 painted for `day` and nothing else done to it.
func _repainted_city(day: int) -> CityMap:
	var map := MapCache.of(4242)
	var state := CityState.new()
	state.begin_day(map.plans_by_block(), day)
	map.repaint(state)
	return map

## The role the scheduler gives `def` on `day`, read off the placement it makes on the first tile
## of the ground it offers that takes one (`EventScheduler.recipe_placement()`, which the scene
## recipes call and which judges the candidate as the day's fill does): the role a plan carries.
## `-1` when no tile of the ground takes the row, or the day does not place it.
func _role_it_places_as(def: EventDef, day: int, map: CityMap, corridor: Corridor) -> int:
	var no_doors := PackedVector2Array()
	var nothing_down: Array[EventPlan] = []
	var calm := CalmAreas.of(map)
	var locations := DayLocations.lay_out(map, corridor)
	var standing: Array[EventPlan] = []
	var ground := EventScheduler.row_ground(map, corridor)
	for tile in ground.tiles_for(def.for_day(day)):
		var plan := EventScheduler.recipe_placement(def, day, map, GamePlanBuilder.over(map),
				map.tile_to_world(tile), 1, nothing_down, corridor, ground, no_doors, calm,
				standing, locations)
		if plan:
			return plan.role()
	return -1

## The edge-to-edge gap left across a sidewalk band past the row's body stood where its
## `pavement_side` puts it, by hand from the body's radius and the band: the physical reading of a
## row that leaves her no way past it.
func _gap_past_the_body(def: EventDef) -> float:
	var band := float(Tuning.SIDEWALK_WIDTH) * Tuning.TILE_SIZE
	var pos: float
	match def.sidewalk_lane():
		EventDef.Pavement.AT_THE_KERB:
			pos = Tuning.TILE_SIZE * 0.5
		EventDef.Pavement.AGAINST_THE_BUILDING:
			pos = band - Tuning.TILE_SIZE * 0.5
		_:
			pos = band * 0.5
	return maxf(pos - def.obstructs_within(), band - (pos + def.obstructs_within()))

## Whether a row's own numbers leave no line along a sidewalk it may stand on, stated from the
## def's public readings: its reach spans the far lane, or its body leaves a gap under what she
## needs. A pacing row is asked of its beat instead (`_paces_a_beat_with_no_way_out`).
func _takes_a_whole_sidewalk(def: EventDef) -> bool:
	return not def.paces_a_beat() and _leaves_no_line_along_a_sidewalk(def)

func _leaves_no_line_along_a_sidewalk(def: EventDef) -> bool:
	if not def.stands_on(GameEnums.TileType.SIDEWALK) or not def.has_a_line_to_avoid():
		return false
	return def.reaches_the_far_lane() \
			or (def.obstructs_within() > 0.0 and _gap_past_the_body(def) < 2.0 * Tuning.PLAYER_BODY_RADIUS)

## Whether a pacing placement leaves no line along a sidewalk and its beat passes neither a
## junction nor a side route: the beat's geometry is written out below.
func _paces_a_beat_with_no_way_out(plan: EventPlan, map: CityMap) -> bool:
	return plan.paces_a_beat() and _leaves_no_line_along_a_sidewalk(plan.row()) \
			and not _a_beat_touches_a_junction(map, plan) \
			and not _a_beat_passes_a_side_route(map, plan)

## **A row pinned to one side of a pavement may not be offered ground that has no sides.**
## *(2026-09-19: "we need a separate square poster crew entity for this", PLAYTEST-107.)* A square
## answers no `CityMap.pavement_inward`, so the ground the scheduler offers (`RowGround.tiles_for()`) refuses every square
## tile to a row carrying `AT_THE_KERB` or `AGAINST_THE_BUILDING` — and a `placement` entry whose
## every tile is refused is not a placement, it is a kind of ground the row silently stopped
## appearing on. That is exactly what happened to the poster crew when it moved against the
## building, and it is invisible in the def: the list still reads as though squares were offered.
##
## Asked of the whole catalogue against a real city rather than of the one row, so the next row
## given a pavement side is held to it without anybody adding an id to a list. Rows with an empty
## `placement` are the seal pictures, sited by `SealPlanner` on ground it picks itself.
func _test_a_pinned_row_is_only_offered_ground_it_can_be_pinned_on(t: TestRunner) -> void:
	var map := MapCache.of(4242)
	var ground := EventScheduler.row_ground(map)
	var asked := 0
	for def in CatalogueRows.every():
		if def.sidewalk_lane() == EventDef.Pavement.ANY or def.ground_kinds().is_empty():
			continue
		var offered := {}
		for tile in ground.tiles_for(def):
			var offered_type := map.tile_at(tile)
			offered[offered_type] = int(offered.get(offered_type, 0)) + 1
		for type in def.ground_kinds():
			var wanted: int = offered.get(type, 0)
			asked += 1
			t.check(wanted > 0,
					"'%s' is pinned %s, and the %s ground it lists has %d tiles that side exists on"
					% [def.id(), EventDef.Pavement.keys()[def.sidewalk_lane()],
					GameEnums.TileType.keys()[type], wanted])
	t.check(asked >= 4, "and the catalogue has pinned rows to ask it of (%d)" % asked)
	# The pool the roll actually draws from, for the one row the player asked about: `poster_crew`
	# is a sidewalk row now, and the square crew is the row that stands on squares.
	t.check(not ground.tiles_for(EventCatalogue.shipped().by_id("poster_crew")).is_empty(),
			"and the sidewalk crew still has ground of its own to stand on")

## **The square's poster crew stands on squares and on nothing else.** *(2026-09-19: "we need a
## separate square poster crew entity for this", PLAYTEST-107.)* The sidewalk crew pastes against
## a building and the square crew at the column a square has instead of one; what makes them two
## rows rather than one is the ground, so the ground is what this asserts.
##
## **The sweep places the row rather than waiting for the dice to offer it.** Its weight is a
## hundredth of the sidewalk crew's — the square's share of the old row's own placements, measured
## — so it arrives well under once a day, and a sweep that planned whole days would be asking
## nothing at all on most of them and would go red on a reseed rather than on a defect.
## `EventScheduler.recipe_placement()` is the public entry that judges a row on one chosen tile as
## the day's own placement does (the scene recipes call it), so the sweep asks it directly, over seeds and over
## days spanning the acts: the ground the scheduler offers the row (`RowGround.tiles_for()`) has to be
## squares alone, the row is placed on tiles drawn from it, and every sidewalk tile of a sample
## strewn over the map is refused it, loudly: the refusal says the location the tile names does not
## take the row there (or that none holds it), rather than the row being placed somewhere else. The count at the end is what
## stops it passing having placed nothing.
func _test_the_square_poster_crew_only_ever_stands_on_a_square(t: TestRunner) -> void:
	var def := EventCatalogue.shipped().by_id("poster_crew_square")
	t.check(def != null and def.own_first_day() <= 14, "the square poster crew is in the catalogue")
	if not def:
		return
	var placed := 0
	var refused := 0
	for i in 3:
		var map := MapCache.of(4242 + i * 97)
		for day: int in [4, 9, 14]:
			var state := CityState.new()
			state.begin_day(map.plans_by_block(), day)
			map.repaint(state)
			var tree := RouteTree.for_day(map, day, null)
			var corridor := Corridor.of(tree)
			var ground := EventScheduler.row_ground(map, corridor)
			var offered := ground.tiles_for(def)
			var off_the_squares := 0
			for tile in offered:
				if map.tile_at(tile) != GameEnums.TileType.SQUARE:
					off_the_squares += 1
			t.check(not offered.is_empty() and off_the_squares == 0,
					"day %d: the ground offered the square crew is squares alone (%d of %d are not)"
					% [day, off_the_squares, offered.size()])
			var already: Array[EventPlan] = []
			var no_doors := PackedVector2Array()
			var calm := CalmAreas.of(map)
			var locations := DayLocations.lay_out(map, corridor)
			var standing: Array[EventPlan] = []
			var rng := _rng(day)
			for copy in 3:
				if offered.is_empty():
					break
				var tile: Vector2i = offered[rng.randi_range(0, offered.size() - 1)]
				var plan := EventScheduler.recipe_placement(def, day, map,
						GamePlanBuilder.over(map), map.tile_to_world(tile), day + copy * 31, already,
						corridor, ground, no_doors, calm, standing, locations)
				if not plan:
					continue
				already.append(plan)
				placed += 1
				var type := map.tile_at(map.world_to_tile(plan.placed_at()))
				t.check(type == GameEnums.TileType.SQUARE,
						"day %d: the square crew stands on %s"
						% [day, GameEnums.TileType.keys()[type]])
			var sidewalk := map.tiles_of_type(GameEnums.TileType.SIDEWALK)
			for k in 24:
				var tile: Vector2i = sidewalk[(k * 7919) % sidewalk.size()]
				var why: Array[String] = []
				var plan := EventScheduler.recipe_placement(def, day, map,
						GamePlanBuilder.over(map), map.tile_to_world(tile), day, already, corridor,
						ground, no_doors, calm, standing, locations, why)
				t.check(plan == null, "day %d: a sidewalk tile %s is refused the square crew"
						% [day, RunTrace.tile(tile)])
				t.check(why.size() == 1 and (why[0].contains("does not take")
						or why[0].contains("no location holds")),
						"day %d: and the refusal says why: its location does not take the row there (%s)"
						% [day, why])
				refused += 1
	t.check(placed >= 1, "and the sweep actually placed one (%d)" % placed)
	t.check(refused > 100, "and refused it sidewalk ground (%d tiles asked)" % refused)

## **A placement asks the ground it is handed and makes none of its own**
## (`EventScheduler.recipe_placement()`, whose `ground` is the scene's one ground, made once for
## every row of a scene): on drawn streets (`StreetMap.full()`), with a stand-in ground that
## offers exactly one sidewalk tile (`_OneTileGround`), a tile it offers is not refused for the
## location not taking the row and the placement is made there; the next tile along the same
## sidewalk is refused with the location not taking the row there; and a stand-in that offers no
## tile (`_BareGround`) refuses the first one too. A placement that made a ground of its own would
## place the row on all three, which is what the refusals hold.
func _test_a_placement_asks_the_ground_it_is_handed(t: TestRunner) -> void:
	var day := 9
	var def := EventCatalogue.shipped().by_id("poster_crew")
	var map := StreetMap.full()
	var locations := DayLocations.lay_out(map, Corridor.of(null))
	var sidewalk := map.tiles_of_type(GameEnums.TileType.SIDEWALK)
	var offered: Vector2i = sidewalk[0]
	var beside := Vector2i(-1, -1)
	for tile in sidewalk:
		if tile != offered and locations.holding(tile, GameEnums.TileType.SIDEWALK) \
				== locations.holding(offered, GameEnums.TileType.SIDEWALK):
			beside = tile
			break
	t.check(beside != Vector2i(-1, -1), "the offered tile has a tile beside it in its location")
	var no_doors := PackedVector2Array()
	var calm := CalmAreas.of(map)
	var why: Array[String] = []
	var placed := EventScheduler.recipe_placement(def, day, map, GamePlanBuilder.over(map),
			map.tile_to_world(offered), 1, [], null, _OneTileGround.new(offered), no_doors, calm,
			[], locations, why)
	t.check(placed != null, "the row is placed on the one tile the ground handed in offers (%s)"
			% [why])
	var refused: Array[String] = []
	var beside_it := EventScheduler.recipe_placement(def, day, map, GamePlanBuilder.over(map),
			map.tile_to_world(beside), 1, [], null, _OneTileGround.new(offered), no_doors, calm,
			[], locations, refused)
	t.check(beside_it == null and refused.size() == 1 and refused[0].contains("does not take"),
			"and the next tile along the sidewalk is refused: the ground does not offer it (%s)"
			% [refused])
	var bare: Array[String] = []
	var none := EventScheduler.recipe_placement(def, day, map, GamePlanBuilder.over(map),
			map.tile_to_world(offered), 1, [], null, _BareGround.new(), no_doors, calm, [],
			locations, bare)
	t.check(none == null and bare.size() == 1 and bare[0].contains("does not take"),
			"and the tile is refused when the ground handed in offers none (%s)" % [bare])

## A ground that offers no tile to any row.
class _BareGround extends RowGround:
	func _init() -> void:
		super(null, null, true, RowGround.Weights.new(), Callable())

	## Overrides RowGround.offers_for_role.
	func offers_for_role(_def: EventDef, _role: GameEnums.BlockerRole) -> Dictionary:
		return {}

## A ground that offers one tile, once, to every row.
class _OneTileGround extends RowGround:
	var _tile: Vector2i

	func _init(tile: Vector2i) -> void:
		super(null, null, true, RowGround.Weights.new(), Callable())
		_tile = tile

	## Overrides RowGround.offers_for_role.
	func offers_for_role(_def: EventDef, _role: GameEnums.BlockerRole) -> Dictionary:
		return {_tile: 1}

## **A scene recipe lays a row the units draw as the day lays it: its route stays on its
## location's run** (`Location.run()`, `EventScheduler.recipe_placement()`), so an authored man
## shouting or chatting mother has the beat a played day gives one and never a longer one. Asked
## over a few cities for each of the two moving rows a unit draws: every point of a placed route is a tile of the run of the
## location holding the row's tile, and the count of placements whose uncut route would have left
## the run is what stops the check passing on routes that were short anyway.
func _test_a_recipes_drawn_row_keeps_its_route_on_its_run(t: TestRunner) -> void:
	var placed := 0
	var would_leave := 0
	for id: String in ["homeless_yeller", "chatting_mother"]:
		var def := EventCatalogue.shipped().by_id(id)
		var day := maxi(def.own_first_day(), 6)
		for i in 3:
			var map := MapCache.of(4242 + i * 97)
			var state := CityState.new()
			state.begin_day(map.plans_by_block(), day)
			map.repaint(state)
			var corridor := Corridor.of(RouteTree.for_day(map, day, null))
			var locations := DayLocations.lay_out(map, corridor)
			var ground := EventScheduler.row_ground(map, corridor)
			var offered := ground.tiles_for(def)
			var rng := _rng(day)
			for k in 6:
				if offered.is_empty():
					break
				var tile: Vector2i = offered[rng.randi_range(0, offered.size() - 1)]
				var seed_of_route := day + k * 17
				var plan := EventScheduler.recipe_placement(def, day, map,
						GamePlanBuilder.over(map), map.tile_to_world(tile), seed_of_route, [],
						corridor, ground, PackedVector2Array(), CalmAreas.of(map), [],
						locations)
				if plan == null:
					continue
				placed += 1
				var location := locations.holding(tile, map.tile_at(tile))
				var run := location.run()
				var outside := 0
				for point in plan.walks():
					if not run.has_point(map.world_to_tile(point)):
						outside += 1
				t.check(outside == 0, "%s on day %d: %d of its route's points lie off the run %s"
						% [id, day, outside, run])
				var uncut_rng := RandomNumberGenerator.new()
				uncut_rng.seed = seed_of_route
				var uncut := LocationFit.new(day, map, GamePlanBuilder.over(map),
						EventScheduler.row_ground(map, corridor)).build(def, tile, uncut_rng,
						Rect2i())
				if uncut != null:
					for point in uncut.walks():
						if not run.has_point(map.world_to_tile(point)):
							would_leave += 1
							break
	t.check(placed >= 4, "the sweep placed routes to check (%d)" % placed)
	t.check(would_leave >= 1,
			"and some route would have left its run uncut (%d), so the bound is what held it"
			% would_leave)

## **A man pacing the route's own sidewalk can always be left at a crossing, and one who cannot be
## left is never on it.** *(PLAYTEST-77, 2026-09-19: "if the yeller paces across a crosswalk then
## there is a way to avoid them. if they stay on the segment for the whole time with no side route
## then there is no way to avoid them. distinguish those cases when deciding whether the yeller is a
## wall".)*
##
## Both halves of that sentence are asserted over the finished day, because it is one rule read from
## its two sides: a pacing row whose field leaves no line along a sidewalk may stand on the route's
## own side **only** where its beat passes a way out, and where it passes none, it is a wall and
## stands anywhere but there. A way out is a **junction box** — the ground every crosswalk in the
## city is painted on — or a **side route**, ground off the street opening off the sidewalk's own
## side, which is the *"no side route"* half of the same sentence.
##
## The beat's own geometry is written out here rather than borrowed from the scheduler, for the
## reason the junction check gives: only the reading of which rows the question is about
## (`EventPlan.counts_against_the_line()`) and what the corridor walks (`Corridor.carries_a_route`) is shared.
##
## **Its non-vacuity is three counts**, because each could pass having seen nothing: a sample with no
## pacing row on a route sidewalk, one where no beat was ever walled, and one where the side-route
## half of the reading never saw a side route at all. The third is reported with the number of beats
## the side route answers for **on its own** beside it, which is the interesting one: where that is
## zero, every beat with a side route also reaches a junction and the half changes no placement in
## this sample — it is still what a beat truncated beside a park would be answered by.
##
## **The walled count is small, and the arithmetic says it has to be.** `homeless_yeller` paces a
## beat of eight tiles against a block of `Tuning.BLOCK_SIZE` (8), so a beat laid anywhere on a
## street runs into the junction box at one end of it unless `PlanBuilder._along_street_path()`
## truncates it — at a closure, at a calm zone's absorbed corridor, or against the map's own margin.
## The walled case is that truncation, which is why the floor under it is *one* rather than a share:
## what it guards is that the sweep can still produce the case at all. City 88 is in the sweep for
## it: its day 1, before any mast holds a location, paces a walled beat, so the floor rests on a day
## no change to the later days' draws moves.
func _test_a_pacing_row_on_the_routes_sidewalk_can_be_left(t: TestRunner) -> void:
	var on_the_route := 0
	var walled := 0
	var by_a_side_route := 0
	var passes_a_side_route := 0
	var unavoidable_on_the_route := 0
	var first := ""
	for map_seed: int in [4242, 90210, 1234567, 88]:
		var map := MapCache.of(map_seed)
		var sites := _sites_of(map)
		for day: int in [1, 3, 5, 8, 11, 14]:
			var state := CityState.new()
			state.begin_day(map.plans_by_block(), day)
			map.repaint(state)
			var tree := RouteTree.for_day(map, day, null)
			var corridor := Corridor.of(tree)
			for plan in _planned_on_the_route(map, sites, day, tree):
				if not plan.paces_a_beat() or not plan.counts_against_the_line():
					continue
				if not plan.row().reaches_the_far_lane():
					continue
				var crossed := _a_beat_touches_a_junction(map, plan)
				var sideways := _a_beat_passes_a_side_route(map, plan)
				if sideways:
					passes_a_side_route += 1
					if not crossed:
						by_a_side_route += 1
				if not crossed and not sideways:
					walled += 1
				if not corridor.carries_a_route(map.world_to_tile(plan.placed_at())):
					continue
				on_the_route += 1
				if crossed or sideways:
					continue
				unavoidable_on_the_route += 1
				if first == "":
					first = "day %d, '%s' at %s" \
							% [day, plan.row_id(), RunTrace.tile(map.world_to_tile(plan.placed_at()))]
	t.check(on_the_route > 5,
			"the days sampled pace a row along the route's own sidewalk (%d)" % on_the_route)
	t.check(walled >= 1,
			"and pace one whose beat passes no way off its sidewalk (%d)" % walled)
	t.check(passes_a_side_route >= 1,
			"and pace one whose beat passes a side route off its sidewalk (%d, of which %d have no"
			% [passes_a_side_route, by_a_side_route] + " junction in the beat either)")
	t.check(unavoidable_on_the_route == 0,
			"and every one on the route's own sidewalk has a way out inside its beat (%d does not%s)"
			% [unavoidable_on_the_route, "" if first == "" else ": " + first])

## Whether a beat's straight run touches a junction box, which is the only ground in the city a
## crosswalk is painted on (`StreetLayout._street_tile`).
func _a_beat_touches_a_junction(map: CityMap, plan: EventPlan) -> bool:
	for at in _beat_tiles(map, plan):
		if CityMap.junction_at(at) != Vector2i(-1, -1):
			return true
	return false

## Whether a beat's straight run passes ground off the street opening off the sidewalk's own side —
## an alley mouth, a park or square edge, a courtyard. Two tiles deep, so a doorway notch is not a
## way out; written out here rather than borrowed for the reason the walk below is.
func _a_beat_passes_a_side_route(map: CityMap, plan: EventPlan) -> bool:
	for at in _beat_tiles(map, plan):
		var inward := map.pavement_inward(at)
		if inward == Vector2i.ZERO:
			continue
		var edge := at
		for _across in Tuning.SIDEWALK_WIDTH:
			edge += inward
			if map.tile_at(edge) != GameEnums.TileType.SIDEWALK:
				break
		if map.is_open(edge) and not map.is_street(edge) \
				and map.is_open(edge + inward) and not map.is_street(edge + inward):
			return true
	return false

## The tiles a beat's straight run covers, ends included.
func _beat_tiles(map: CityMap, plan: EventPlan) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	if plan.walks().size() < 2:
		return found
	var from := map.world_to_tile(plan.walks()[0])
	var to := map.world_to_tile(plan.walks()[plan.walks().size() - 1])
	var step := Vector2i(signi(to.x - from.x), signi(to.y - from.y))
	var at := from
	while true:
		found.append(at)
		if at == to or step == Vector2i.ZERO:
			return found
		at += step
	return found

## **A route's junctions stay clear.** *(PLAYTEST-69: "a path through the city must never hit
## excitement — so all obstacles should be routable around by eg crossing to the other side of the
## street".)* A junction is the only place a line along a route may change pavement, so a crossing
## the day's rows have closed between them is a cut that the ground on either side of it cannot
## answer: `tests/probes/m129_zero_cost_line.gd` measured it as the shape breaking more routes than
## every other shape put together.
##
## **The assertion is about the finished day rather than about the refusal**, which is what keeps it
## from being the rule read back to itself. `RouteLineRule` refuses
## one candidate at a time, against what is already down; what has to be true afterwards is that
## nothing *else* the morning does — a scar prepended, an ambient placed, a park spoiled — has
## left a crossing closed. Measured over the five sampled days of seed 4242:
## 50 of 360 route junctions were closed before the rule existed and none are with it.
##
## **The geometry is stated here rather than borrowed**, for the same reason: the box's own flood
## fill is written out below, so a change to the scheduler's private helper cannot quietly change
## what this file claims. Only the primitives are shared — which junctions the routes cross
## (`RouteTree.junctions()`), which streets are on the corridor (`Corridor.depth`), and what a row
## denies (`EventPlan.counts_against_the_line()` and `EventDef.line_reach()`, the reading PLAYTEST-71
## settled and the one place it is written down).
##
## **And it cannot pass vacuously**: a day where no counted row ever stood within reach of a route
## junction would satisfy it with nothing checked, so the rows that do are counted and asserted.
func _test_a_routes_junctions_stay_clear(t: TestRunner) -> void:
	var map := MapCache.of(4242)
	var sites := _sites_of(map)
	var junctions := 0
	var in_reach := 0
	var closed := 0
	var first := ""
	for day: int in [1, 5, 9, 14]:
		var state := CityState.new()
		state.begin_day(map.plans_by_block(), day)
		map.repaint(state)
		var tree := RouteTree.for_day(map, day, null)
		var corridor := Corridor.of(tree)
		var counted: Array[EventPlan] = []
		for plan in _planned_on_the_route(map, sites, day, tree):
			if plan.counts_against_the_line():
				counted.append(plan)
		for junction in tree.junctions():
			junctions += 1
			var box := Rect2i(junction * CityMap.period(), Vector2i.ONE * Tuning.STREET_WIDTH)
			var world := map.tile_rect_to_world(box)
			var here: Array[EventPlan] = []
			for plan in counted:
				var reach := plan.line_reach()
				if plan.distance_from(world.get_center()) <= reach + world.size.length() * 0.5:
					here.append(plan)
			in_reach += here.size()
			if here.is_empty():
				continue
			if _the_crossing_is_walkable(map, corridor, junction, box, here):
				continue
			closed += 1
			if first == "":
				var ids := {}
				for plan in here:
					ids[plan.row_id()] = true
				first = "day %d, junction %s, covered by [%s]" \
						% [day, junction, ", ".join(PackedStringArray(ids.keys()))]
	t.check(junctions > 100, "the days sampled plan routes across junctions (%d)" % junctions)
	t.check(in_reach > 100,
			"and place rows within reach of them, so the check is not vacuous (%d)" % in_reach)
	t.check(closed == 0, "no route junction is closed by what the day placed (%d closed%s)"
			% [closed, "" if first == "" else ": " + first])

## The test's own statement of *a line can still cross here*: take every row's reach off the
## junction box and ask whether the box's remaining ground joins every route street that meets it.
##
## Both halves matter. A box with somewhere free left in it is not a crossing if the free ground is
## a corner cut off from the streets, and a box whose two arms are each free is not a crossing if
## nothing joins them — which is why this is a flood fill rather than a count.
func _the_crossing_is_walkable(map: CityMap, corridor: Corridor, junction: Vector2i, box: Rect2i,
		rows: Array[EventPlan]) -> bool:
	var free := {}
	for y in range(box.position.y, box.end.y):
		for x in range(box.position.x, box.end.x):
			var tile := Vector2i(x, y)
			if not map.is_open(tile):
				continue
			var taken := false
			for plan in rows:
				if plan.denies(map.tile_to_world(tile),
						plan.line_reach()):
					taken = true
					break
			if not taken:
				free[tile] = true
	if free.is_empty():
		return false
	var arms: Array = []
	for segment in map.street_network().at_junction(junction):
		if corridor.depth(segment.tile_rect().position) != 0:
			continue
		var open_here: Array[Vector2i] = []
		var step := segment.other_end(junction) - junction
		for i in Tuning.STREET_WIDTH:
			var tile := box.position + Vector2i(i, i)
			if step.x > 0:
				tile = box.position + Vector2i(Tuning.STREET_WIDTH - 1, i)
			elif step.x < 0:
				tile = box.position + Vector2i(0, i)
			elif step.y > 0:
				tile = box.position + Vector2i(i, Tuning.STREET_WIDTH - 1)
			else:
				tile = box.position + Vector2i(i, 0)
			if free.has(tile):
				open_here.append(tile)
		if open_here.is_empty():
			return false
		arms.append(open_here)
	if arms.size() < 2:
		return true
	var reached := {}
	var queue: Array[Vector2i] = []
	for tile: Vector2i in arms[0]:
		reached[tile] = true
		queue.append(tile)
	var head := 0
	while head < queue.size():
		var at: Vector2i = queue[head]
		head += 1
		for step: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = at + step
			if free.has(next) and not reached.has(next):
				reached[next] = true
				queue.append(next)
	for i in range(1, arms.size()):
		var joined := false
		for tile: Vector2i in arms[i]:
			if reached.has(tile):
				joined = true
				break
		if not joined:
			return false
	return true

## **Nothing takes the sidewalk a route is walked along.** *(PLAYTEST-69: "all obstacles should be
## routable around by eg crossing to the other side of the street, which in turn means the other
## side of the street must be open enough so we can walk on it unimpeded"; PLAYTEST-77: "on the side
## of the street where the path was chosen only obstacles that can be bypassed should be
## possible".)* A branch runs down one sidewalk of a street and the kerb tint marks that one, so the
## far side staying open answers a van and does not answer a row standing on the route's own side.
##
## **It is a shape the numbers make rather than a rare accident**, which is why it is worth a check
## of its own: a sidewalk is 64px and most of the catalogue denies more than that from wherever it
## stands. The probe measured a row spanning a whole street breaking 39 routes in 97 cuts before any
## of these rules existed.
##
## Asserted over the finished day and over **every row reaching the band at once**, which is the
## rule's own wording — a band closed by a pair is the shape the measurement found. What that
## catches beyond the refusal itself is anything the morning does outside the day's rules: a scar
## prepended, an ambient placed, a park spoiled.
##
## **Its non-vacuity has two halves**, because a sweep that found no walked sidewalks, or found them
## and had no row standing anywhere near one, would pass having checked nothing. Both are counted.
##
## The walk is written out here rather than borrowed from the scheduler, for the reason the junction
## check gives — only the reading of what a row denies is shared, since there is one place that is
## written down.
func _test_nothing_takes_the_routes_own_sidewalk(t: TestRunner) -> void:
	var map := MapCache.of(4242)
	var sites := _sites_of(map)
	var bands := 0
	var bands_with_a_row := 0
	var closed := 0
	var first := ""
	for day: int in [1, 5, 9, 14]:
		var state := CityState.new()
		state.begin_day(map.plans_by_block(), day)
		map.repaint(state)
		var tree := RouteTree.for_day(map, day, null)
		var corridor := Corridor.of(tree)
		var counted: Array[EventPlan] = []
		for plan in _planned_on_the_route(map, sites, day, tree):
			# A pacing row is left out for the reason the rule leaves it out: a beat is passed by
			# waiting rather than by a lane, and its own two rules are what govern it.
			if plan.counts_against_the_line() and not plan.paces_a_beat():
				counted.append(plan)
		for segment in map.street_network().segments():
			var rect := segment.tile_rect()
			if corridor.depth(rect.position) != 0:
				continue
			for band in _sidewalk_bands_of(rect, segment.horizontal):
				if not _a_route_is_walked_along(corridor, band):
					continue
				bands += 1
				var world := map.tile_rect_to_world(band)
				var standing: Array[EventPlan] = []
				for plan in counted:
					if plan.reach_touches(world,
							plan.line_reach()):
						standing.append(plan)
				if standing.is_empty():
					continue
				bands_with_a_row += 1
				if _a_walk_along(map, band, segment.horizontal, standing):
					continue
				closed += 1
				if first == "":
					var ids := {}
					for plan in standing:
						ids[plan.row_id()] = true
					first = "day %d, street %s, held by [%s]" \
							% [day, segment.key(), ", ".join(PackedStringArray(ids.keys()))]
	t.check(bands > 50, "the days sampled walk routes along sidewalks (%d)" % bands)
	t.check(bands_with_a_row > 20,
			"and rows stand within reach of them (%d of %d)" % [bands_with_a_row, bands])
	t.check(closed == 0, "and a line survives along every one of them (%d closed%s)"
			% [closed, "" if first == "" else ": " + first])

## The two sidewalk bands of a street's tile rect, written out here rather than borrowed for the
## reason the walk below is.
func _sidewalk_bands_of(rect: Rect2i, horizontal: bool) -> Array[Rect2i]:
	var across := Vector2i.DOWN if horizontal else Vector2i.RIGHT
	var size := Vector2i(rect.size.x, Tuning.SIDEWALK_WIDTH) if horizontal \
			else Vector2i(Tuning.SIDEWALK_WIDTH, rect.size.y)
	var far := across * (Tuning.STREET_WIDTH - Tuning.SIDEWALK_WIDTH)
	return [Rect2i(rect.position, size), Rect2i(rect.position + far, size)]

func _a_route_is_walked_along(corridor: Corridor, band: Rect2i) -> bool:
	for y in range(band.position.y, band.end.y):
		for x in range(band.position.x, band.end.x):
			if corridor.carries_a_route(Vector2i(x, y)):
				return true
	return false

## **A pacing row leaves the line open for part of its beat.** *(PLAYTEST-71: "time pass — don't
## route around them".)* A man walking a footway and back is passed by waiting, so the ground his
## beat denies is the ground it never leaves free — and what the probe finds broken is never the
## beat by itself but the beat's one open end with something else standing in it.
##
## So the claim is about a **street carrying a pacing row**, asked of every row reaching that street
## at once: a walk from one of its junctions to the other has to survive all of them together. That
## is what `PacingOpeningRule._leaves_a_pacing_beats_opening` refuses a placement for, and asserting it
## over the finished day is what catches anything a later pass adds without asking.
##
## **It cannot pass vacuously**: a sample where no pacing row ever stood on a route street would
## satisfy it having checked nothing, so those streets are counted and asserted. `homeless_yeller`
## (14.0 over 210px, no body, paces) is the row the sample is really about.
func _test_a_pacing_rows_opening_stays_open(t: TestRunner) -> void:
	var map := MapCache.of(4242)
	var sites := _sites_of(map)
	var paced_streets := 0
	var closed := 0
	var first := ""
	# Five days, the ones `_test_the_day_is_placed_by_role` samples. A pacing row is one row of the
	# catalogue and the junction and width rules have taken most of the corridor away from it, so
	# the sample turns up a handful of paced route streets rather than dozens — which is why the
	# guard below is a floor with room under it rather than a measurement to keep in step. What it
	# is for is only that the check ran against real ground at all.
	for day: int in [1, 5, 8, 11, 14]:
		var state := CityState.new()
		state.begin_day(map.plans_by_block(), day)
		map.repaint(state)
		var tree := RouteTree.for_day(map, day, null)
		var corridor := Corridor.of(tree)
		var counted: Array[EventPlan] = []
		for plan in _planned_on_the_route(map, sites, day, tree):
			if plan.counts_against_the_line():
				counted.append(plan)
		var streets := {}
		for plan in counted:
			if not plan.paces_a_beat():
				continue
			var segment := map.street_network().segment_containing(map.world_to_tile(
					plan.placed_at()))
			if segment and corridor.depth(segment.tile_rect().position) == 0:
				streets[segment.key()] = segment
		for key: Vector3i in streets:
			var segment: StreetNetwork.Segment = streets[key]
			paced_streets += 1
			var rect := map.tile_rect_to_world(segment.tile_rect())
			var standing: Array[EventPlan] = []
			for plan in counted:
				if plan.reach_touches(rect,
						plan.line_reach()):
					standing.append(plan)
			if _a_walk_along_the_street(map, segment, standing):
				continue
			closed += 1
			if first == "":
				var ids := {}
				for plan in standing:
					ids[plan.row_id()] = true
				first = "day %d, street %s, held by [%s]" \
						% [day, key, ", ".join(PackedStringArray(ids.keys()))]
	t.check(paced_streets >= 3,
			"the days sampled pace a row along the route's own streets (%d)" % paced_streets)
	t.check(closed == 0, "and the beat's opening is left open on every one (%d closed%s)"
			% [closed, "" if first == "" else ": " + first])

## Whether a walk exists from one end of a street to the other with these rows standing on it: the
## street's own ground, both pavements, the carriageway between the kerbs left out because a line
## may not cross there anyway, four-connected so a barrier laid diagonally counts as closing it.
func _a_walk_along_the_street(map: CityMap, segment: StreetNetwork.Segment,
		rows: Array[EventPlan]) -> bool:
	return _a_walk_along(map, segment.tile_rect(), segment.horizontal, rows)

## The same walk over an arbitrary run of a street's ground — one sidewalk band of it, or the whole
## street — from one end of `rect` to the other along `horizontal`.
func _a_walk_along(map: CityMap, rect: Rect2i, horizontal: bool,
		rows: Array[EventPlan]) -> bool:
	var free := {}
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var tile := Vector2i(x, y)
			if not map.is_open(tile):
				continue
			var across := CityMap.corridor_offset(tile.y if horizontal else tile.x)
			var type := map.tile_at(tile)
			if CityMap.is_road_offset(across) and (type == GameEnums.TileType.ROAD
					or type == GameEnums.TileType.CROSSING):
				continue
			var taken := false
			for plan in rows:
				if plan.denies(map.tile_to_world(tile),
						plan.line_reach()):
					taken = true
					break
			if not taken:
				free[tile] = true
	var last := (rect.end.x - 1) if horizontal else (rect.end.y - 1)
	var seen := {}
	var queue: Array[Vector2i] = []
	for tile: Vector2i in free:
		var at_the_start := tile.x == rect.position.x if horizontal \
				else tile.y == rect.position.y
		if at_the_start:
			seen[tile] = true
			queue.append(tile)
	var head := 0
	while head < queue.size():
		var at: Vector2i = queue[head]
		head += 1
		if (at.x if horizontal else at.y) == last:
			return true
		for step: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = at + step
			if free.has(next) and not seen.has(next):
				seen[next] = true
				queue.append(next)
	return false

## **A flock is scenery — overturned on 2026-09-13**, PLAYTEST-71: *"flocks are basically free
## already — don't count it as block, just count is scenery."* Under the plain cost rule a
## 42-over-168px field crosses `EventScheduler.WALL_WORTH_OF_COST`, so without `EventDef.Role.SCENERY`
## `EventScheduler.role_for()` would call `pigeon_flock` a `WALL` and `RowGround._times_for_role()` would pull it off every route
## corridor the way any other expensive row is. `Role.SCENERY` is checked first and answers `NONE`.
##
## Two claims. The role is a fact about the def, checked directly on every placement the day
## makes. Whether one actually **lands** on the corridor is a fact about the roll rather than
## about the rule, so it is checked the way `_test_alley_robbery_never_lands_on_a_required_alley`
## checks the opposite claim — over several days on a real generated map, until at least one
## placement turns up at `corridor.depth(tile) == 0`. A check that never saw an on-corridor flock
## would hold whether the exemption worked or not.
func _test_a_flock_is_scenery(t: TestRunner) -> void:
	var def := EventCatalogue.shipped().by_id("pigeon_flock")
	var on_corridor := 0
	var off_corridor := 0
	var map := _map()
	for day: int in [1, 4, 8, 11, 14]:
		var corridor := Corridor.of(RouteTree.for_day(map, day, null))
		for plan in _planned(day):
			if plan.row_id() != "pigeon_flock" or not plan.is_placed():
				continue
			t.check(plan.role() == GameEnums.BlockerRole.NONE,
					"day %d: a placed flock carries no role, not a wall's" % day)
			var tile := map.world_to_tile(plan.placed_at())
			if corridor.depth(tile) == 0:
				on_corridor += 1
			else:
				off_corridor += 1
	t.check(on_corridor > 0,
			"a flock lands on the day's own corridor at least once (%d on, %d off)"
			% [on_corridor, off_corridor])

## What a row denies along a line (`EventDef.line_reach()`): a lethal row keeps its whole
## outer radius, since nothing about being quiet at the rim makes walking into it survivable, and
## no row reaches less than its own body.
func _test_a_lethal_rows_line_reach_is_its_whole_field(t: TestRunner) -> void:
	var lethal := 0
	for def in CatalogueRows.every():
		if not def.ends_the_day():
			continue
		lethal += 1
		t.check(is_equal_approx(def.line_reach(), maxf(def.heard_within(), def.obstructs_within())),
				"%s: a lethal row's line reach is its whole field (%.0fpx)"
				% [def.id(), def.line_reach()])
	t.check(lethal > 0, "the catalogue has lethal rows to ask (%d)" % lethal)
	for def in CatalogueRows.every():
		t.check(def.line_reach() >= def.obstructs_within(),
				"%s: no row reaches less than its own body" % def.id())

## Playtest 07, finding 7: *"there is also a car obstacle on the road that is basically a still
## car standing on the road doing nothing."* A parked van belongs against a kerb — on the
## pavement she is walking down, and out of a traffic lane the crowd drives straight through.
func _test_a_parked_van_is_at_the_kerb(t: TestRunner) -> void:
	var map := _map()
	var parked := 0
	for day in range(1, 15):
		for plan in _planned(day):
			if plan.row().sidewalk_lane() != EventDef.Pavement.AT_THE_KERB:
				continue
			parked += 1
			var tile := map.world_to_tile(plan.placed_at())
			var inward := map.pavement_inward(tile)
			t.check(inward != Vector2i.ZERO,
					"day %d: '%s' is on a pavement with a kerb on one side" % [day, plan.row_id()])
			if inward == Vector2i.ZERO:
				continue
			var beside := map.tile_at(tile - inward)
			t.check(beside == GameEnums.TileType.ROAD or beside == GameEnums.TileType.CROSSING,
					"day %d: '%s' has the carriageway on the other side of it (%d)"
					% [day, plan.row_id(), beside])
	t.check(parked > 0, "and a run parks something (%d over 14 days)" % parked)

## Playtest 07, finding 15: *"the backing out lorry does not connect to the building making it
## hard to visually read."* The danger is the gap behind a wall of metal, so there has to be a
## wall — and it has to be east or west of it, because the silhouette is drawn side-on.
func _test_a_lorry_has_a_wall_to_back_into(t: TestRunner) -> void:
	var map := _map()
	var backing := 0
	for day in range(3, 15):
		for plan in _planned(day):
			if plan.row().sidewalk_lane() != EventDef.Pavement.AGAINST_THE_BUILDING:
				continue
			# A place the day owes her walk has no tile yet to have a frontage behind it — day 3's
			# fire is sited later, against the same `RowGround._wants_this_side()` rule this asks about, and
			# where it lands is asked of a real walk in `tests/test_event_manager.gd`.
			if not plan.is_placed():
				continue
			backing += 1
			var tile := map.world_to_tile(plan.placed_at())
			var inward := map.pavement_inward(tile)
			t.check(inward != Vector2i.ZERO and inward.y == 0,
					"day %d: '%s' backs into a frontage it can be drawn facing" % [day, plan.row_id()])
			if inward == Vector2i.ZERO:
				continue
			t.check(map.tile_at(tile + inward) == GameEnums.TileType.BUILDING,
					"day %d: '%s' has a real building behind it" % [day, plan.row_id()])
			# Facing *out* of the wall, so the box end is the end that is in the yard.
			t.check(plan.faces() == -Vector2(inward),
					"day %d: '%s' is turned to reverse into it" % [day, plan.row_id()])
	t.check(backing > 0, "and a run sites one (%d over days 3-14)" % backing)

## Playtest 11, finding 1: *"events/hazards should not spawn on the home block."* The home is a
## notch with one exit, so the walk from the doorstep to the first junction is the one stretch of
## a day she does not choose to be on — and a thing standing on it is a tax rather than a route
## decision. `ClosurePlanner` has refused to close that same street since M16, for the same reason.
##
## Measured before the exemption, eight seeds over days 1, 3, 7 and 14: **0.47 events a day** stood
## on it, which is one morning in two starting with something on the doorstep. The share is exactly
## the share of the pavement the street is (0.30% of both), which is placement being uniform and is
## why this needed a rule rather than a weighting.
##
## The last two checks are the ones that keep it from passing vacuously: an exemption over ground
## nothing could have stood on is not an exemption, and a day that stopped placing events would
## satisfy the first check perfectly.
func _test_nothing_stands_on_the_doorstep_street(t: TestRunner) -> void:
	var map := _map()
	var home := ClosurePlanner.home_street(map)
	t.check(home != null, "the front door opens onto a street")
	if not home:
		return
	var rect := home.tile_rect()
	var placed := 0
	for day in range(1, 15):
		for plan in _planned(day):
			if plan.placed_at() == Vector2.INF:
				continue   # an `AHEAD_OF_PLAYER` row, sited by the director while she walks
			placed += 1
			t.check(not rect.has_point(map.world_to_tile(plan.placed_at())),
					"day %d: '%s' is not standing on the street she starts the day on"
					% [day, plan.row_id()])

	var pavement := 0
	for tile in map.tiles_of_type(GameEnums.TileType.SIDEWALK):
		if rect.has_point(tile):
			pavement += 1
	t.check(pavement > 0,
			"and the exempt street is pavement something could otherwise have stood on (%d tiles)"
			% pavement)
	t.check(placed > 14, "and the days it was checked over still place events (%d)" % placed)

## `plan` as `[position.x, position.y, obstructs_within()]`, appended to `bodies` — or not, for the
## same two exemptions the rule and its own probe make: a region door's body (`EventPlan.is_door()`)
## costs by design, and a `Role.SCENERY` row has no ground to keep clear of.
func _add_a_physical_body(bodies: Array, plan: EventPlan) -> void:
	if not plan.is_placed() or plan.obstructs_within() <= 0.0:
		return
	if plan.row().is_scenery() or plan.is_door():
		return
	bodies.append(Vector3(plan.placed_at().x, plan.placed_at().y, plan.obstructs_within()))

## `docs/DECISIONS.md`, M100, "Events spawn inside a fully blocked street" and "Nothing on the home block":
## a catalogue placement is refused a candidate tile whose street segment is held today — a
## closure, a hard seal, a region wall or door, or a segment bordering the home block
## (`CityMap.held`) — or that lies inside the home block's own lot
## (`CityMap.is_on_home_block`). Replicates `EventManager.start_day`'s own ordering: the seals and
## the region plan are known, and `held` is filled, before `EventScheduler.build_day`
## rolls a single candidate.
##
## **And the fifth refusal, a standing street tree's own ground** (`docs/CITY.md`, "Street trees"):
## every catalogue placement and every seal body on these same full days is asked whether it stands
## on a tile `StreetTrees.footprint_tiles` covers. The seals are asked here rather than only in
## `tests/test_seals.gd` because they are the half that does **not** go through
## `RowGround.tiles_for()` — `SealPlanner._seal_along_tile` is a second implementation of
## one rule, and a day's plan is where the two have to agree. `fallen_tree` is the single exception
## and is excluded by name: it is the body that stands in a pit and empties it.
##
## **The seals' own bodies, the closure marker and the checkpoint rows are placed by their
## planners, not by the catalogue roll, so they are unaffected** — asserted by comparison rather
## than against a remembered count: the seals are planned twice on the same seeded stream, once
## with `SealPlanner.plan_day`'s `held` out-param wired in exactly as `EventManager.start_day`
## wires it and once without, and the two plans must be the same size, since `held` is written
## by the planner and read by nobody in it; closures, walls, doors and checkpoint bodies never
## read the holds at all, so they only have to exist across the sampled days (day 7 and day 10
## are in the sample for the regions). A remembered total would fail on every unrelated change to
## the generator — it did, twice, the day this was written — and say nothing about holds.
## **Two seeds and five days.** A (seed, day) here is the most expensive unit anywhere in this
## suite — a `RouteTree`, a region plan, a closure plan, two seal plans and a `build_day` — and
## what it proves is that five refusals inside `RowGround.tiles_for()` fire, which every single pair
## exercises over its whole day's worth of candidates. The days stay five rather than one because
## holds come from four different planners and each has its own first day (region walls from
## `REGION_WALL_FIRST_DAY`, closures from act I), so the sample has to span the acts; the seeds
## drop to two because the second is there to keep the sample from being one street plan and the
## third and fourth were asking the same question a third and fourth time.
func _test_nothing_the_catalogue_places_stands_on_held_ground(t: TestRunner) -> void:
	const SEEDS := 2
	const BASE_SEED := 314159
	const DAYS := [1, 4, 7, 10, 14]
	var total_closures := 0
	var total_boundary := 0
	var total_checkpoints := 0
	var total_seals := 0
	var checked := 0
	var checked_trees := 0
	for i in SEEDS:
		var map := CityGenerator.generate(BASE_SEED + i * 137)
		var sites := _sites_of(map)
		for day: int in DAYS:
			var state := CityState.new()
			state.begin_day(map.plans_by_block(), day)
			map.repaint(state)
			var tree := RouteTree.for_day(map, day, null)
			var region_plan := RegionPlanner.plan_day(map, DaySpec.for_day(day), tree)
			var closure_rng := RandomNumberGenerator.new()
			closure_rng.seed = hash("closures:%d:%d" % [map.city_seed(), day])
			var closures := ClosurePlanner.plan_day(map, DaySpec.for_day(day),
					closure_rng, tree, region_plan)
			map.close_streets(closures)

			# The same population `EventManager.start_day` performs, before `build_day` runs.
			map.clear_day_holds()
			for closure in closures:
				map.hold_segment(closure.street_key(), HeldStreets.Why.CLOSURE)
			for segment in region_plan.wall_segments():
				map.hold_segment(segment.key(), HeldStreets.Why.WALL)
			for segment in region_plan.door_segments():
				map.hold_segment(segment.key(), HeldStreets.Why.DOOR)
			for segment in map.street_network().around_blocks(Rect2i(map.home_block_coordinate(), Vector2i.ONE)):
				map.hold_segment(segment.key(), HeldStreets.Why.HOME)

			var boundary := {}
			for segment in region_plan.wall_segments():
				boundary[segment.key()] = true
			for segment in region_plan.door_segments():
				boundary[segment.key()] = true
			for rect in region_plan.walled_alleys():
				boundary[rect.position] = true
			for rect in region_plan.door_alleys():
				boundary[rect.position] = true
			var seal_rng := RandomNumberGenerator.new()
			seal_rng.seed = hash("seals:%d:%d" % [map.city_seed(), day])
			var seals := SealPlanner.plan_day(map, DaySpec.for_day(day), tree, seal_rng, boundary, map.held_streets())
			var unheld_rng := RandomNumberGenerator.new()
			unheld_rng.seed = hash("seals:%d:%d" % [map.city_seed(), day])
			var seals_unheld := SealPlanner.plan_day(map, DaySpec.for_day(day), tree, unheld_rng, boundary)
			t.check(seals.size() == seals_unheld.size(),
					"seed %d day %d: holding the hard seals' ground plans the same seals (%d vs %d)"
					% [map.city_seed(), day, seals.size(), seals_unheld.size()])

			# **A tree and an event never share ground** — `docs/CITY.md`, "Street trees". Checked
			# over the same full days, against the tree footprints themselves rather than against
			# the pit tiles, since the refusal is stated over the ground the shadow reaches.
			var trees := StreetTrees.footprint_tiles(map)
			for seal in seals:
				if seal.row_id() == "fallen_tree":
					continue   # the one body that stands in a pit, and empties it; see below
				var seal_tile := map.world_to_tile(seal.placed_at())
				t.check(not trees.has(seal_tile),
						"seed %d day %d: seal '%s' stands in a street tree at %s"
						% [map.city_seed(), day, seal.row_id(), seal_tile])
				checked_trees += 1

			var consumed: Array[String] = []
			for plan in GameDawn.of(DaySpec.for_day(day), _rng(day), map) \
					.masts(sites).spent(consumed).on(tree).plan().placements():
				if not plan.is_placed():
					continue
				checked += 1
				var tile := map.world_to_tile(plan.placed_at())
				t.check(not map.is_closed(tile),
						"seed %d day %d: '%s' does not stand on a closed tile"
						% [map.city_seed(), day, plan.row_id()])
				t.check(not map.is_held_at(tile),
						"seed %d day %d: '%s' does not stand on a held segment"
						% [map.city_seed(), day, plan.row_id()])
				t.check(not map.is_on_home_block(tile),
						"seed %d day %d: '%s' does not stand inside the home block"
						% [map.city_seed(), day, plan.row_id()])
				t.check(not trees.has(tile),
						"seed %d day %d: '%s' stands in a street tree at %s"
						% [map.city_seed(), day, plan.row_id(), tile])
				checked_trees += 1

			total_closures += closures.size()
			total_boundary += region_plan.wall_segments().size() \
					+ region_plan.door_segments().size()
			total_checkpoints += region_plan.door_plans().size()
			total_seals += seals.size()

	t.check(checked > 0, "the catalogue placed something to check across every sampled day (%d)"
			% checked)
	t.check(total_closures > 0, "the sampled days closed streets to hold (%d)" % total_closures)
	t.check(total_boundary > 0, "the sampled days had walls and doors to hold (%d)" % total_boundary)
	t.check(total_checkpoints > 0,
			"the sampled days stood checkpoint bodies on their doors (%d)" % total_checkpoints)
	t.check(total_seals > 0, "the sampled days sealed streets (%d)" % total_seals)
	t.check(checked_trees > 0,
			"and every one of those bodies was asked whether it stands in a tree (%d)"
			% checked_trees)

## **No solid body, alone or together, closes a walked sidewalk.** *(PLAYTEST-94, 2026-09-19: "I
## still get hard walls on the side of the sidewalk that is on the path -- how can this be so hard
## to do correctly?")* `tests/probes/m129_walked_sidewalk_walls.gd` measures the same question at
## zero over a wider sample; this asks it of `RouteSidewalkRule.closes_a_walked_sidewalk_band`
## directly, the one function both the probe and this test call, so neither can drift from what
## the other means by *closed*. Every solid body that day stands — the candidate loop's own rows,
## the seals, and the region wall's and doors' bodies, gathered the way
## `_test_nothing_the_catalogue_places_stands_on_held_ground` already assembles a full day — is
## checked cumulatively against every walked-sidewalk band, the way the width rule itself asks it.
##
## **Two seeds and three days, a quarter of the probe's own 24.** A (seed, day) here assembles the
## same expensive unit that test already prices at the suite's own budget — a tree, a region plan,
## closures, a seal plan and a `build_day` — so this asks one more question of it rather than
## building a second assembly; the probe is where the wider sample already lives if this suite's
## own finding ever needs a closer look.
func _test_no_body_closes_a_walked_sidewalk(t: TestRunner) -> void:
	const SEEDS := 2
	const BASE_SEED := 271828
	const DAYS := [1, 8, 13]
	var bands_checked := 0
	for i in SEEDS:
		var map := CityGenerator.generate(BASE_SEED + i * 173)
		var sites := _sites_of(map)
		for day: int in DAYS:
			var state := CityState.new()
			state.begin_day(map.plans_by_block(), day)
			map.repaint(state)
			var tree := RouteTree.for_day(map, day, null)
			var region_plan := RegionPlanner.plan_day(map, DaySpec.for_day(day), tree)
			var closure_rng := RandomNumberGenerator.new()
			closure_rng.seed = hash("closures:%d:%d" % [map.city_seed(), day])
			var closures := ClosurePlanner.plan_day(map, DaySpec.for_day(day),
					closure_rng, tree, region_plan)
			map.close_streets(closures)

			map.clear_day_holds()
			for closure in closures:
				map.hold_segment(closure.street_key(), HeldStreets.Why.CLOSURE)
			for segment in region_plan.wall_segments():
				map.hold_segment(segment.key(), HeldStreets.Why.WALL)
			for segment in region_plan.door_segments():
				map.hold_segment(segment.key(), HeldStreets.Why.DOOR)
			for segment in map.street_network().around_blocks(Rect2i(map.home_block_coordinate(), Vector2i.ONE)):
				map.hold_segment(segment.key(), HeldStreets.Why.HOME)

			var boundary := {}
			for segment in region_plan.wall_segments():
				boundary[segment.key()] = true
			for segment in region_plan.door_segments():
				boundary[segment.key()] = true
			for rect in region_plan.walled_alleys():
				boundary[rect.position] = true
			for rect in region_plan.door_alleys():
				boundary[rect.position] = true
			var seal_rng := RandomNumberGenerator.new()
			seal_rng.seed = hash("seals:%d:%d" % [map.city_seed(), day])
			var seals := SealPlanner.plan_day(map, DaySpec.for_day(day), tree, seal_rng, boundary, map.held_streets())

			var bodies: Array = []
			var consumed: Array[String] = []
			for plan in GameDawn.of(DaySpec.for_day(day), _rng(day), map) \
					.masts(sites).spent(consumed).on(tree).plan().placements():
				_add_a_physical_body(bodies, plan)
			for plan in seals:
				_add_a_physical_body(bodies, plan)
			for plan in region_plan.wall_plans():
				_add_a_physical_body(bodies, plan)
			for plan in region_plan.door_plans():
				_add_a_physical_body(bodies, plan)

			var corridor := Corridor.of(tree)
			for entry: Array in corridor.walked_sidewalks(map):
				var segment: StreetNetwork.Segment = entry[0]
				var band: Rect2i = entry[1]
				bands_checked += 1
				t.check(not RouteSidewalkRule.closes_a_walked_sidewalk_band(
						map, band, segment.horizontal, bodies),
						"seed %d day %d: street %s's walked sidewalk keeps a lane she fits through"
						% [map.city_seed(), day, segment.key()])
	t.check(bands_checked > 50,
			"and the days sampled have walked-sidewalk bands to ask it of (%d)" % bands_checked)

## **A spread never lands on a corner.** `RowGround._is_a_corner()` refuses any tile whose two
## coordinates are both inside a corridor band to a row whose body `BodySpec.as_a_spread()` names — see
## `docs/DECISIONS.md`, "a spread on a corner is placed as if the corner were nothing": such a tile
## has no single street for `BodyStance.lies_vertically_at()` or `BodyStance._centred_on_the_pavement_band()` to answer about.
## Walked over the **planned** placements of several seeds and every day of a run, rather than over
## the candidate pool directly, because a clean pool and a roll that still lands on a stale entry
## are two different bugs.
## **One seed, all fourteen days.** The refusal is a filter on the candidate pool rather than
## anything about a layout, so what a second city adds is more draws from the same rule — and a
## day's worth of draws is already hundreds. The days stay whole because a run is what carries the
## `consumed` set forward, which is what makes a later day's pool different from an earlier one's.
func _test_a_spread_never_lands_on_a_corner(t: TestRunner) -> void:
	var checked := 0
	for run_seed: int in [4242]:
		var map := _map()
		for day in range(1, 15):
			for plan in _planned(day):
				if not plan.is_placed() or not plan.row().lies_as_a_spread():
					continue
				checked += 1
				var tile := map.world_to_tile(plan.placed_at())
				var on_corner := CityMap.corridor_offset(tile.x) >= 0 \
						and CityMap.corridor_offset(tile.y) >= 0
				t.check(not on_corner,
						"seed %d day %d: '%s' at tile %s is not on a corner"
						% [run_seed, day, plan.row_id(), tile])
	t.check(checked > 0, "some run placed a spread to check (%d)" % checked)
