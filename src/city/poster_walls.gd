class_name PosterWalls
extends Node
## The posters on the city's walls: where they can go, what goes up each dawn, what a crew pastes
## while she watches, and the sheet she tears down by pushing against it.
##
## **Only blank ground-floor wall carries a poster**, one row to a wall — `Building.
## blank_ground_floor_cells()`, never a window, a door, a storefront, a portico, a fire escape's
## column or her own home block (M185, a ground floor is blank wall or shops). A front is the south
## face of a lot, the only face the city draws, so every poster faces an east-west street and is
## pasted and torn from the sidewalk tile directly in front of it. That tile is what names a cell
## everywhere: `PosterState` keys by it, a crew is sited on it, she pushes from it.
##
## **What is on the walls is run state, and this only reads and writes it.** `GameState.posters`
## holds it, so it survives a save and a lost day gives it back; this node is rebuilt with the city
## and hands each `Building` the cells it draws (`Building.posters`). It draws nothing itself — the
## sheets are part of the front, drawn in the building's own `_draw()` on the Buildings layer, under
## every entity, so a crew and she stand in front of them.
##
## What puts a sheet up:
##
## - **Dawn.** From `FIRST_DAY` (day 4, the first day crews appear) every morning pastes a share
##   of the walls from the day's own `posters` stream, so some are already up that first morning
##   and each day's walls add to the last. What kind goes up, and how much of a wall, follows the
##   progression in `docs/TODO.md`'s M180 (`KIND_FIRST_DAY`, `KIND_WEIGHTS`, `_sheets_for()`).
## - **A crew on her way.** `poster_crew` is sited on her walk, in front of a blank cell
##   (`EventScheduler.WalkSiting`, `fronts()`), and pastes its wall a sheet at a time while it is in
##   her view — see `_work_the_crews()`.
## - **Pasting over.** A new sheet on an old one covers it exactly most of the time and shows it
##   beneath, offset enough to read, the rest (`OVERPASTE_SHARE`).

## The first day any poster is on a wall — the first day `poster_crew` is in the catalogue.
const FIRST_DAY := 4

## The day each kind joins the walls. A kind that has arrived stays in the mix.
const KIND_FIRST_DAY := {
	PosterArt.Kind.LEADER: 4,
	PosterArt.Kind.RULES: 4,
	PosterArt.Kind.CURFEW: 6,
	PosterArt.Kind.UNIFORM: 8,
	PosterArt.Kind.WANTED: 12,
}
## How often each kind is chosen, per act (index `act - 1`), among the kinds that have arrived.
## Act III is the dark uniform sheets' act; act IV puts the portrait everywhere beside the wanted
## notice. Taste, open to overturn.
const KIND_WEIGHTS := [
	{},
	{PosterArt.Kind.LEADER: 1.0, PosterArt.Kind.RULES: 1.0, PosterArt.Kind.CURFEW: 1.0},
	{PosterArt.Kind.UNIFORM: 3.0, PosterArt.Kind.LEADER: 1.0, PosterArt.Kind.RULES: 1.0,
		PosterArt.Kind.CURFEW: 1.0},
	{PosterArt.Kind.LEADER: 3.0, PosterArt.Kind.WANTED: 2.0, PosterArt.Kind.UNIFORM: 1.0,
		PosterArt.Kind.RULES: 0.5, PosterArt.Kind.CURFEW: 0.5},
]
## Share of the walls each dawn works, per act, on the streets the day's routes run along and off
## them. "Sparse at first and denser towards the end", and in act III and IV most of it on "the
## streets she uses most" — which are the day's own routes, the one reading of that a morning can
## make. A front faces an east-west street and the main road runs north-south, so act IV's "most
## walls on a main street" is read as the routes too. Taste, open to overturn.
const DAWN_SHARE_ON_ROUTES := [0.0, 0.10, 0.30, 0.45]
const DAWN_SHARE_OFF_ROUTES := [0.0, 0.06, 0.08, 0.12]
## Extra share of the walls the first morning of each act beyond the first works, on top of the
## above: day 4 is the city's first posters ("some are already up that first morning"), day 8 the
## uniform sheets going up edge to edge, day 12 the wanted notice. On the routes and off them alike.
const ACT_MORNING_SHARE := 0.10
## Share of new sheets pasted over an older one that leave it showing, offset, rather than
## covering it exactly. The exception: "if it's visibly over pasted for all of them then it will
## look weird" (PLAYTEST-123, statement 33). Taste, open to overturn.
const OVERPASTE_SHARE := 0.25

## A crew pastes one sheet this often while it is in her view, and its first one this soon after
## she first sees it — so the sheets go up while she watches, which is what "the crew is seen
## pasting" asks for.
const PASTE_EVERY := 2.0
const FIRST_PASTE_AFTER := 0.8

var _city: City
var _map: CityMap
## One entry per front with a blank cell: `{"building": Building, "cols": Array[int],
## "tiles": Array[Vector2i]}`, the cells in column order, west to east.
var _walls: Array[Dictionary] = []
## Front tile -> `Vector2i(wall index, cell index)`.
var _by_tile: Dictionary = {}
var _day := 0
## Whether a day is being played, rather than the escape or nothing at all. Crews and tears only
## run inside one.
var _day_running := false
## Crew front tile -> its job: `{"queue": Array[Vector2i], "kind", "next_in", "pasted", "total",
## "rng"}`. A day's, keyed by where the crew stands, so a crew streamed out and back in carries on.
var _jobs: Dictionary = {}
var _player: Stroller = null

## Reads every building's blank ground-floor cells. Called once by `City.build()`, whose buildings
## are fixed for the run.
func setup(city: City, map: CityMap) -> void:
	_city = city
	_map = map
	_walls.clear()
	_by_tile.clear()
	for building in city.buildings():
		var cols: Array[int] = []
		var tiles: Array[Vector2i] = []
		for rect in building.blank_ground_floor_cells():
			var col := roundi((rect.position.x + building.columns() * Building.TILE * 0.5)
					/ Building.TILE)
			var front := map.world_to_tile(building.global_position
					+ Vector2(rect.get_center().x, Building.TILE * 0.5))
			if not _is_a_front(map, front):
				continue
			cols.append(col)
			tiles.append(front)
		if cols.is_empty():
			continue
		for i in tiles.size():
			_by_tile[tiles[i]] = Vector2i(_walls.size(), i)
		_walls.append({"building": building, "cols": cols, "tiles": tiles})
	PosterArt.prepare()

## Whether `tile` is the sidewalk directly in front of a building's front: the frontage lane of an
## east-west street's north sidewalk, with the building's lot just north of it. A lot's south edge
## can face an alley, a park or a courtyard instead, and nobody pastes or tears from there.
static func _is_a_front(map: CityMap, tile: Vector2i) -> bool:
	return map.pavement_inward(tile) == Vector2i.UP \
			and map.tile_at(tile + Vector2i.UP) == GameEnums.TileType.BUILDING

## Every front tile a crew may stand on to paste, as a set — what `EventScheduler.WalkSiting`
## narrows `poster_crew`'s ground to.
func fronts() -> Dictionary:
	var found := {}
	for tile: Vector2i in _by_tile:
		found[tile] = true
	return found

## How many fronts carry a blank cell, for the tests.
func wall_count() -> int:
	return _walls.size()

## Today's walls. Pastes every dawn from `FIRST_DAY` up to `day` not yet pasted — one on an
## ordinary morning, all of them on a run started later under `--day`. `tree` is the day's route
## tree, what "the streets she uses most" is read against. Called by `City.start_day()` after the day's closures, which is after
## `GameState.begin_day()` photographed the walls, so a retry pastes the same dawn again.
func start_day(day: int, tree: RouteTree) -> void:
	_day = day
	_day_running = true
	_jobs.clear()
	var state := GameState.posters
	var corridor := Corridor.of(tree) if tree else null
	for dawn in range(maxi(state.pasted_through + 1, FIRST_DAY), day + 1):
		_paste_the_dawn(dawn, corridor)
	state.pasted_through = maxi(state.pasted_through, day)
	refresh()

## The escape, or anything else that shows the city without playing a day in it: the walls as the
## run left them, with no crew working and nothing to tear.
func show_only() -> void:
	_day_running = false
	_jobs.clear()
	refresh()

## Hands every front the cells it draws.
func refresh() -> void:
	for i in _walls.size():
		_refresh_wall(i)

func _refresh_wall(index: int) -> void:
	var wall := _walls[index]
	var state := GameState.posters
	var cells := {}
	for i in (wall["tiles"] as Array).size():
		var tile: Vector2i = wall["tiles"][i]
		if state.cells.has(tile):
			cells[wall["cols"][i]] = state.cells[tile]
	(wall["building"] as Building).posters = cells

# ------------------------------------------------------------------- dawn ---

## One morning's pasting, from that day's own `posters` stream, so no other roll moves. Every wall
## is asked in the same order every run, which is what makes the dawn reproducible from the seed.
func _paste_the_dawn(day: int, corridor: Corridor) -> void:
	var rng := GameState.day_rng(day, "posters")
	var act := Tuning.act_for_day(day)
	var first_morning := day == FIRST_DAY or Tuning.ACT_START_DAYS.has(day)
	for i in _walls.size():
		var wall := _walls[i]
		var building := wall["building"] as Building
		var on_routes := corridor != null and corridor.carries_a_route(wall["tiles"][0])
		var share: float = DAWN_SHARE_ON_ROUTES[act - 1] if on_routes \
				else DAWN_SHARE_OFF_ROUTES[act - 1]
		if first_morning:
			share += ACT_MORNING_SHARE
		# Rolled for every wall, burnt or not, so a block burning never moves another wall's roll.
		var roll := rng.randf()
		var kind := _kind_for(day, rng)
		if roll >= share or building.condition == Building.Condition.BURNT:
			continue
		var tiles: Array = wall["tiles"]
		var count := _sheets_for(kind, act, tiles.size(), rng)
		var start := rng.randi_range(0, tiles.size() - count)
		for c in range(start, start + count):
			_paste_one(tiles[c], kind, rng)
		# A wall worked again is worked whole: its torn sheets go under the new paste as well.
		for tile: Vector2i in tiles:
			if GameState.posters.is_torn(tile):
				_paste_one(tile, kind, rng)

## One kind for a wall being worked on `day`, weighted by its act among the kinds that have
## arrived. Always consumes one value.
static func _kind_for(day: int, rng: RandomNumberGenerator) -> int:
	var weights: Dictionary = KIND_WEIGHTS[Tuning.act_for_day(day) - 1]
	var total := 0.0
	for kind: int in weights:
		if day >= int(KIND_FIRST_DAY[kind]):
			total += float(weights[kind])
	var pick := rng.randf() * total
	var chosen := PosterArt.Kind.LEADER
	for kind: int in weights:
		if day < int(KIND_FIRST_DAY[kind]):
			continue
		chosen = kind
		pick -= float(weights[kind])
		if pick < 0.0:
			break
	return chosen

## How many of a wall's `cells` one working covers: one or two in act II ("a wall here and there,
## one or two sheets on it"), the whole wall for the uniform sheet ("whole walls, edge to edge"),
## at least half of it in act IV ("dense"). Always consumes one value.
static func _sheets_for(kind: int, act: int, cells: int, rng: RandomNumberGenerator) -> int:
	var roll := rng.randi_range(0, 1 << 16)
	if kind == PosterArt.Kind.UNIFORM:
		return cells
	var low := 1
	var high := 2
	if act >= 4:
		low = ceili(cells * 0.5)
		high = cells
	elif act == 3:
		high = 3
	low = clampi(low, 1, cells)
	high = clampi(high, low, cells)
	return low + roll % (high - low + 1)

## Pastes `kind` on one cell, over whatever is there: exactly, most of the time, and offset so the
## older sheet shows the rest — never a sheet over the same kind offset, which would read as one
## poster drawn twice. Always consumes two values.
func _paste_one(tile: Vector2i, kind: int, rng: RandomNumberGenerator) -> void:
	var offset_roll := rng.randf()
	var side := 1 if rng.randf() < 0.5 else -1
	var state := GameState.posters
	var old: Dictionary = state.cells.get(tile, {})
	var offset := offset_roll < OVERPASTE_SHARE and not old.is_empty() \
			and int(old["kind"]) != kind
	state.paste(tile, kind, offset, side)

# ----------------------------------------------------------------- the day ---

func _physics_process(delta: float) -> void:
	if not _day_running or _walls.is_empty():
		return
	if not _player:
		_player = get_tree().get_first_node_in_group("player") as Stroller
		if not _player:
			return
	_work_the_crews(delta, _player.global_position)

## Every poster crew in the world pastes the wall it stands at, one sheet every `PASTE_EVERY`
## seconds while it is inside her view, starting with the cell in front of it and working outward,
## then any torn sheet on the same wall. One kind per crew, from its own stream: the day and where
## it stands. A crew that has finished stands and works on, and its wall keeps what it pasted.
func _work_the_crews(delta: float, at: Vector2) -> void:
	for instance in _city.events.instances():
		if not is_instance_valid(instance) or instance.def.id != "poster_crew":
			continue
		var tile := _map.world_to_tile(instance.global_position)
		if not _by_tile.has(tile):
			continue
		var offset := (instance.global_position - at).abs()
		if offset.x > Tuning.VIEW_HALF_EXTENT.x or offset.y > Tuning.VIEW_HALF_EXTENT.y:
			continue
		if not _jobs.has(tile):
			_jobs[tile] = _job_for(tile)
		var job: Dictionary = _jobs[tile]
		var queue: Array = job["queue"]
		if queue.is_empty():
			continue
		job["next_in"] = float(job["next_in"]) - delta
		if float(job["next_in"]) > 0.0:
			continue
		job["next_in"] = PASTE_EVERY
		var cell: Vector2i = queue.pop_front()
		_paste_one(cell, int(job["kind"]), job["rng"])
		job["pasted"] = int(job["pasted"]) + 1
		_refresh_wall(_by_tile[tile].x)
		# Where and what, because nothing else records it: the crew was sited on her walk, and
		# whether it finished depends on how long she stayed in sight of it.
		var what: String = PosterArt.Kind.keys()[int(job["kind"])].to_lower()
		if int(job["pasted"]) == 1:
			Telemetry.note("scar", "a poster crew at %s starts pasting %s sheets on the wall, %d to go"
					% [TelemetryLog.tile(tile), what, int(job["total"])])
		elif queue.is_empty():
			Telemetry.note("scar", "the poster crew at %s has pasted its wall: %d %s sheets"
					% [TelemetryLog.tile(tile), int(job["pasted"]), what])

## A crew's work: which kind it carries and which cells, in the order it pastes them.
func _job_for(tile: Vector2i) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:%d:%d:poster-crew" % [GameState.run_seed, _day, tile.x, tile.y])
	var at: Vector2i = _by_tile[tile]
	var tiles: Array = _walls[at.x]["tiles"]
	var kind := _kind_for(_day, rng)
	var count := _sheets_for(kind, Tuning.act_for_day(_day), tiles.size(), rng)
	var queue: Array[Vector2i] = []
	for step in tiles.size() * 2:
		var index := at.y + ((step + 1) >> 1) * (1 if step % 2 == 1 else -1)
		if index < 0 or index >= tiles.size() or queue.has(tiles[index]):
			continue
		if queue.size() < count:
			queue.append(tiles[index])
	for other: Vector2i in tiles:
		if GameState.posters.is_torn(other) and not queue.has(other):
			queue.append(other)
	return {"queue": queue, "kind": kind, "next_in": FIRST_PASTE_AFTER, "pasted": 0,
			"total": queue.size(), "rng": rng}
