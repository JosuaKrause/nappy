class_name EventDirector
extends RefCounted
## Places the events whose content is *the moment they happen to you* rather than *where they
## are*: the ones the day budgets and the player's own walk sites.
##
## A cat that happens where it spawns is a cat nobody meets; it has to arrive in front of her
## while she walks, every time.
##
## That is a real distinction and not just a placement trick. A café spilling across a pavement
## is a *place*: it is worth putting on a map because knowing it is there changes the route you
## pick, and walking a street to find out is the game. A cat bolting is worth nothing at all as
## a place — you cannot plan around a thing that lasts three seconds, and a cat that ran across
## an empty road two blocks away was, for six milestones, an event the player had no way of ever
## meeting. It only exists as an interruption, so it is authored as one.
##
## **What is deliberately kept.** The day's budget still buys it, in `EventScheduler`, at the
## same cost as everything else — so making the cat land cannot quietly make the day denser
## too. And the spawn is far enough ahead to be a *reaction window*: `AHEAD_LEAD_DISTANCE` is
## two seconds of walking, and the cat starts a street's width off to one side, so she is
## outside its outer radius the whole time it is crouching. That is the telegraph fairness
## contract holding for an event that arrives without warning, which is the only way one is
## allowed to.
##
## Determinism is the day's RNG on its own stream, as everything else is. The *timing* depends
## on where the player walked, so no seed reproduces it from outside — which is exactly what
## `Telemetry`'s `roll` entries exist to write down.
##
## **And one thing sited here *is* a place.** `site_what_is_on_her_way()` is the second half of
## this class and it breaks the sentence above on purpose: a row carrying
## `EventDef.sited_on_her_way` — day 3's burning building, and the day's poster crews after it —
## is a place in every sense: a tile, a body, a field, and what it leaves on the city outlives the
## day. What it cannot be is *anywhere*: the fire is the authored beat of act I and a crew is the
## walls visibly changing, and either one on a street she never walks down is a silhouette spent on
## nothing. So the day budgets it and this sites it, on a tile of the row's own ground ahead of her
## heading (a building face for the fire and the crews), once her direction for the day is clear.
##
## The two jobs share this class because they share the one thing neither the scheduler nor the
## manager has: **the direction she is actually travelling, now**. They do not share a queue, an
## interval or a spawn — a crossing is created on the spot and forgotten, and a place is written
## into the day's own plan for `EventManager` to stream like any other.

## How far to either side of the crossing point the run reaches. A street's width, so the cat
## comes out of one kerb and is gone into the other.
const CROSSING_REACH_TILES := Tuning.STREET_WIDTH

var _map: CityMap
var _rng := RandomNumberGenerator.new()
## The events the day has budgeted and not yet spent, in the order they are handed out. A `null`
## entry is **a marble from the route's bag**: one of the events the day bought for her route,
## which row it is decided by `_route` when it is handed out rather than by the dawn's roll. A
## non-null entry is a row owed as itself — a sprinkled dog, a forced row.
var _owed: Array[EventDef] = []
## The day, for the siting a row asks for on it (`EventDef.spawn_mode_on()`).
var _day := 0
## **What she meets on her route is drawn from a marble bag.** *(olive-koala, statement 2: "events
## should use the marble bag approach as well. that way we can control what the player sees on
## their route".)* Filled with each row the director sites today in proportion to its weight
## (`Tuning.ROUTE_BAG_MARBLES_PER_WEIGHT`), so over any stretch the length of a bag the mix she
## meets is the rows' own rather than a roll's streaks. The marbles are row ids, looked up in
## `_route_rows`. Its own stream, derived from the day's director stream rather than drawn from it,
## so the bag draws nothing from the director's stream; which row a handout is still moves the
## draws after it there (a crossing spends one on its side, a row down her line none), and the same
## seed and the same walk are the same day. Null on a rig that has not started a day.
var _route: MarbleBag = null
## Row id -> today's `EventDef` for it, heated like the day's own placements: every row the
## ordinary bag holds, and any a rig put in front of it (`rig_her_route()`).
var _route_rows := {}
## Row id -> how many of it the director has handed out today, so a row's `max_per_day` holds for
## what she meets as it holds for what the dawn buys. Asked only of the ordinary bag's rows
## (`_ordinary_rows`): a rigged marble is there because something asked for it.
var _met_today := {}
## The ids the ordinary bag is filled with today.
var _ordinary_rows := {}
## The stream a place put on her route by a marble (`_place_on_her_route()`) is sited and re-sited
## from — its own, so it never moves a crew's or the fire's.
var _place_rng := RandomNumberGenerator.new()
## The plans a marble put on her route, so their sitings draw from `_place_rng`. Not in the day's
## plan until first sited: `EventManager` adds one there then (`is_from_her_route()`).
var _placed_from_the_route := {}
var _next_in := 0.0
## Whether `owe_the_return()` has already handed today its return-phase patrols. Set once and
## never cleared until `start_day()`, so a baby that wakes and settles again does not owe a
## second batch — see that function's own doc.
var _return_owed := false
## Whether the queue is rolling `Tuning.RETURN_PATROL_INTERVAL` instead of `Tuning.AHEAD_INTERVAL`
## for the rest of the day. Set by `owe_the_return()` and never cleared until `start_day()`: once
## the return owes its pressure, the pacing stays tight even if the phase drops back to walking.
var _return_pacing := false
## Where today's region-door bodies stand — a hut, a boom or an alley post. Read off the day's own
## plan in `start_day()` below, so the director needs no second channel to the region plan, and
## used by `due()` to refuse a siting whose path would run through a door's own clear ground. Empty
## on every day before `Tuning.REGION_WALL_FIRST_DAY`.
var _doors := PackedVector2Array()

## Today's plans that the day budgeted and left for her walk to site — `EventDef.sited_on_her_way`,
## which is day 3's fire, and the poster crews from day 4 — read off the same plan list `_owed` is,
## in `start_day()`; and the places a marble from her route's bag names, added the moment the marble
## is drawn (`_place_on_her_route()`). Emptied as each one is put in the world.
var _on_her_way: Array[EventScheduler.Planned] = []
## The day's placement context, for siting one of those against the same ground, corridor, doors and
## protected calm every dawn placement was stated against. Null on a day with nothing to site, and
## on any rig that starts the director without one.
var _siting: EventScheduler.WalkSiting = null
## Seconds of *walking* since the day started — the clock `_on_her_way` waits out, ticking only
## while she is actually going somewhere for the same reason `due()`'s own clock does.
var _walked := 0.0
## For each plan still on its way to somewhere: how long it has been behind her. Keyed by the plan.
## See `site_what_is_on_her_way()`.
var _behind_her := {}
## Seconds of walking since the walk was last looked at, for both halves of the question — whether
## there is anywhere to site what is still owed, and whether what is already sited is still on her
## way. See `ON_HER_WAY_LOOK`.
var _since_the_last_look := 0.0
## The stream the siting rolls its candidate tile out of. Derived from the day's own director stream
## rather than drawn from it, so which building face the fire takes cannot move a single cat.
var _walk_rng := RandomNumberGenerator.new()
## The same for a recurring row sited on her way — `poster_crew` — so the crews' sitings are a
## stream of their own and never move the fire's.
var _crew_rng := RandomNumberGenerator.new()
## A patrol a torn poster has sent — see `send_a_patrol()` — or null. Held apart from `_owed`
## rather than put in it, so the day's own queue, its pacing and its stream are exactly what they
## would have been had she never torn anything.
var _sent: EventDef = null
## Seconds of walking before `_sent` is sited.
var _sent_in := 0.0

func _init(map: CityMap) -> void:
	_map = map

## Takes over the day's `AHEAD_OF_PLAYER` and `TOWARD_PLAYER` plans — everything the scheduler
## budgeted but left for the director to site while she walks. Called with the same plan list the
## manager streams the sited events from, so the two halves of a day cannot disagree about what is
## owed.
##
## Asked over `plan.def.spawn_mode_on(day)` rather than `spawn_mode` alone, so a row whose siting
## changes after its own `first_day` — `charging_dog` past `Tuning.RUN_TAUGHT_DAY` — is owed to the
## director only on the days it actually answers `AHEAD_OF_PLAYER` or `TOWARD_PLAYER`. Without this
## the scheduler's own `EventScheduler._place_one()` would place the row on a tile *and* the
## director would separately site a second one in front of her, from the one `EventDef` both read.
##
## `heat` is the shape the route bag's rows are put in (`EventCatalogue.heated()`), the same
## `GameState.resistance_progress` the day's own placements were planned at.
func start_day(day: int, plans: Array[EventScheduler.Planned],
		rng: RandomNumberGenerator, siting: EventScheduler.WalkSiting = null,
		heat: int = 0) -> void:
	_owed.clear()
	_rng = rng
	_day = day
	_met_today.clear()
	_placed_from_the_route.clear()
	_return_patrols_left = 0
	_patrol_bag_left = 0
	_fill_the_route_bag(day, heat, rng)
	_return_owed = false
	_return_pacing = false
	_doors.clear()
	_on_her_way.clear()
	_behind_her.clear()
	_walked = 0.0
	_since_the_last_look = 0.0
	_sent = null
	_siting = siting
	# Derived from the day stream's seed rather than drawn from the stream itself: the siting rolls
	# a candidate tile and a re-siting rolls another, and a day on which she turned round would
	# otherwise hand every cat after it a different interval than a day on which she did not.
	_walk_rng.seed = hash("%d:on-her-way" % rng.seed)
	_crew_rng.seed = hash("%d:crews-on-her-way" % rng.seed)
	_place_rng.seed = hash("%d:placed-from-the-route" % rng.seed)
	# The first pursuer the day bought, for day 3's lesson — see `_teach_the_run()`.
	var lesson: EventDef = null
	for plan in plans:
		# A door body is read off the same list, so "where do today's doors stand" is answered once,
		# by the plan, rather than by a second wire from the region planner to here. The huts and
		# posts are the bodies that inspect her and the boom is the one that does not; all three
		# keep their clear ground.
		if (plan.def.redetains or plan.def.lifts_for_traffic) and plan.is_placed():
			_doors.append(plan.position)
		# A place the day budgeted and left unsited, read off the same list for the same reason.
		if plan.def.sited_on_her_way and not plan.is_placed():
			_on_her_way.append(plan)
		var mode := plan.def.spawn_mode_on(day)
		if mode == EventDef.SpawnMode.AHEAD_OF_PLAYER or mode == EventDef.SpawnMode.TOWARD_PLAYER:
			if plan.def.pursues and not lesson:
				lesson = plan.def
			# The dawn decides how many the route is owed; the bag decides which each one is.
			_owed.append(null if _route_rows.has(plan.def.id) else plan.def)
	_owe_the_sprinkled_dog(day)
	_take_the_forced_row()
	# The first one is not free: a cat on the doorstep before she has taken a step reads as the
	# game starting badly rather than as something happening.
	_next_in = _roll_interval()
	if _forced:
		return
	_teach_the_run(day, lesson)

## The row `--force <id>` names, or `null` when the flag is absent — see `DevFlags.forced_row()`
## for what the flag is for. Debug builds only, like every other dev flag.
var _forced: EventDef
## Seconds between two forced rows, from `--force <id> [seconds]`.
var _forced_interval := 0.0

## Throws away the day's own owed list and replaces it with the one row `--force` names, so the
## director hands out that row and nothing else for the whole day.
##
## **The day-3 run lesson is skipped while this is on**, in `start_day()` above: `_teach_the_run()`
## exists to put `charging_dog` at the head of a real day's queue, and under this flag there is no
## real queue to put it at the head of — every entry is already the forced row, so moving one to the
## front would only mean the first encounter arrives at `LESSON_DELAY` instead of the interval that
## was asked for.
##
## An unknown id is a loud failure rather than a silent no-op: `--force cylist` would otherwise look
## exactly like a day that happened not to schedule one.
func _take_the_forced_row() -> void:
	_forced = null
	if not DevFlags.enabled():
		return
	var id := DevFlags.forced_row()
	if id == "":
		return
	var def := EventCatalogue.by_id(id)
	if not def:
		push_error("--force names no event in the catalogue: '%s'" % id)
		return
	_forced = def
	_forced_interval = DevFlags.forced_interval()
	_owed.clear()
	_owed.append(def)

## Puts the day-3 lesson at the front of the queue: the day running becomes the answer opens with
## an incident that requires it.
##
## Running is a trap against every other row in the catalogue and is meant to be — so the day the
## exception arrives, the game cannot leave finding it to chance. `charging_dog` is `weight 1.4`
## of a day-3 pool and it would otherwise land whenever it landed, which for the one event that
## teaches a control is not good enough.
##
## Two things, and only on that day: the pursuit is moved to the head of the owed list, and the
## first interval is cut to a lesson rather than an ambush. `LESSON_DELAY` is far enough in that
## she is walking and off the doorstep — the director will not site anything while she is standing
## still — and early enough that it is the first thing that happens to her. *(inbox #561 in coral-bunny, asked
## whether the lesson should come after a bag of five: "keep it first".)*
##
## **The lesson is a rigged bag of one, and it is not paid for.** *(inbox #566 in feathery-stork: "but the first dog
## is a rigged bag with only one entry that is separate from anything that comes after" · "the
## lesson is not paid for. why would it be? that's not how the marble bag works".)* A bag holding
## only the dog goes in front of the route's bag (`MarbleBag.rig()` at a size of one takes nothing
## from the bag behind it), and the first of the events the dawn bought for her route is the one
## drawn from it. The ordinary bag after it keeps every dog marble it was filled with
## (`Tuning.ROUTE_BAG_MARBLES_OF`).
##
## It is *not* a scripted event, and that is deliberate: it is one of the day's own budgeted
## `AHEAD_OF_PLAYER` plans, so teaching the run cannot quietly make day 3 denser than the budget
## says. If the day happened not to buy one, there is nothing to teach and nothing happens.
func _teach_the_run(day: int, lesson: EventDef) -> void:
	if day != Tuning.RUN_TAUGHT_DAY or not lesson:
		return
	if _route_rows.has(lesson.id):
		if not _owed.has(null):
			return
		_route.rig([lesson.id], 1)
		_bag_the_next(1)
	else:
		var at := _owed.find(lesson)
		if at < 0:
			return
		_owed.remove_at(at)
		_owed.push_front(lesson)
	_next_in = LESSON_DELAY

## How far into day 3 the lesson lands. A few seconds of ordinary walking first, so that what
## happens reads as the day changing rather than as the day starting.
const LESSON_DELAY := 6.0

## Moves `count` of the owed list's marbles to its head, adding marbles where it holds fewer, so the
## next `count` events handed out are the route bag's next `count` draws — what a rig of that size
## needs to be a guarantee about what is handed out on her route rather than about the bag alone.
func _bag_the_next(count: int) -> void:
	var taken := 0
	var rest: Array[EventDef] = []
	for owed_def in _owed:
		if owed_def == null and taken < count:
			taken += 1
			continue
		rest.append(owed_def)
	_owed = rest
	for _i in count:
		_owed.push_front(null)

## The lesson does not retire. *(2026-09-13, PLAYTEST-68: "The waiting is good. But we can sprinkle
## the day 3 charging dog in every now and then, too. Since they always come from offscreen the
## only difference now is that day 3 dog is guaranteed to happen and has a tutorial tip.")* Past
## the day it switches to a `MAP` placement, `charging_dog` recurs two ways at once: waited into on
## a tile, and — now and then, rolled once a day here — sent by this director in its day-3 shape,
## off her heading, already noticing her.
##
## **The row itself, untouched.** `EventCatalogue.by_id()` returns the shared, cold `EventDef` —
## `pursues_within` still its authored 0.0 — so nothing here has to build a copy the way
## `EventScheduler._for_day()` does for the waiting one: a director-sited dog is met exactly as
## day 3's is, charging the moment it streams in, because both are already-noticing encounters
## rather than places she is routed into. No tip and no guarantee are the whole of what changes —
## `_teach_the_run()` owns the guarantee and the delay that make day 3 a lesson, and neither runs
## here.
##
## **Rolled once a day, outside the scheduler's own budget** — the same shape `owe_the_return()`
## already is: a rare encounter added to the queue rather than competing with cafés and roadworks
## for it, because a lesson-sized moment that only happens when the density dice agree is not one a
## player can point to. `Tuning.CHARGING_DOG_SPRINKLE_CHANCE` is the rate, set against
## `tests/probes/m96_dog_sprinkle.gd` — see that constant for what was measured and chosen.
##
## **Put at the front, not the back.** `tests/probes/m99_caps.gd` already measured that a busy
## day's own `AHEAD_OF_PLAYER` pool is oversubscribed by design — `cat_dash`, `cyclist` and
## `loose_dog` between them queue dozens a day and the pacing (`Tuning.AHEAD_INTERVAL`) only ever
## drains a handful before the day ends — so an item *appended* here would sit behind all of that
## and the roll below would almost never actually meet her. This is not a second chance at that same
## budget: the roll already made it rare, and stacking a second rare event on top of "reached before
## the day runs out" would make it rarer still, unmeasurably so, exactly like `_teach_the_run()`
## moving the day-3 lesson to the front rather than leaving it wherever the pool happened to place
## it. Pushing to the front only decides which of today's `AHEAD_OF_PLAYER` encounters is met
## *first* when one has been rolled at all; it never adds a second roll on top of the first.
##
## Asked over the def's own `spawn_mode_switches_after_day` rather than `Tuning.RUN_TAUGHT_DAY`
## directly, so this stays in step with whichever day the row's siting actually changes on.
func _owe_the_sprinkled_dog(day: int) -> void:
	var dog := EventCatalogue.by_id("charging_dog")
	if not dog or day <= dog.spawn_mode_switches_after_day:
		return
	if _rng.randf() < Tuning.CHARGING_DOG_SPRINKLE_CHANCE:
		_owed.push_front(dog)

func owed() -> int:
	return _owed.size()

# ------------------------------------------------------------ the route's bag ---

## Fills `_route` with every row the director sites on `day` — recurring, available, and
## `AHEAD_OF_PLAYER` or `TOWARD_PLAYER` that day — in proportion to its weight. **The dawn placement
## stays a weighted roll** (`EventScheduler._fill_with_recurring()`), and what it buys for her route
## is how many she is owed, at the same cost as everything else; the bag only decides which row
## each of those is, in the order she meets them. *(2026-09-27, asked how far the bags reach, the
## player chose the route's events only.)*
func _fill_the_route_bag(day: int, heat: int, rng: RandomNumberGenerator) -> void:
	_route_rows.clear()
	_ordinary_rows.clear()
	for def in route_rows_on(day, heat):
		_route_rows[def.id] = def
		_ordinary_rows[def.id] = true
	_route = MarbleBag.new([], ordinary_route_marbles(day, heat), hash("%d:route-bag" % rng.seed))

## The rows the director sites on `day` — recurring, available, and `AHEAD_OF_PLAYER` or
## `TOWARD_PLAYER` that day — at `heat`, in the catalogue's own order.
static func route_rows_on(day: int, heat: int) -> Array[EventDef]:
	var rows: Array[EventDef] = []
	for def in EventCatalogue.of_kind(GameEnums.EventKind.RECURRING, day, heat):
		var mode := def.spawn_mode_on(day)
		if mode == EventDef.SpawnMode.AHEAD_OF_PLAYER or mode == EventDef.SpawnMode.TOWARD_PLAYER:
			rows.append(def)
	return rows

## The marbles of `day`'s ordinary route bag: each of `route_rows_on()` in proportion to its weight
## (`Tuning.ROUTE_BAG_MARBLES_PER_WEIGHT`). A row `Tuning.ROUTE_BAG_MARBLES_OF` names comes as often
## as it says rather than as its weight says: the weight is the dawn roll's too, on every day.
static func ordinary_route_marbles(day: int, heat: int) -> Array:
	var weights := {}
	for def in route_rows_on(day, heat):
		weights[def.id] = def.weight
	return MarbleBag.in_proportion(weights, Tuning.ROUTE_BAG_MARBLES_PER_WEIGHT,
			Tuning.ROUTE_BAG_MARBLES_OF)

## **A scene's route, from the bag its recipe rigs** (`setup.route_bag`, `docs/SCENE_RECIPES.md`).
## *(polite-dolphin, inbox #555: "the events should still spawn using the same rules but the marble
## bag should be rigged".)* Called after `start_day()`, which a scene runs with no plans of the
## day's own: what she is owed on her route becomes `owed` marbles of a bag holding `marbles`, with
## `pre_bag` drawn from first when it holds any, and everything after that is the director's own —
## the pacing, the siting ahead of her or down her line, the doors, a row's `max_per_day` over the
## ordinary bag's rows, and a rig a task asks for later (`rig_her_route()`). `first_after` is the
## seconds of walking before the first is due, or a negative number for the ordinary roll
## (`Tuning.AHEAD_INTERVAL`): a scene is a minute rather than a day, the same reason day 3's lesson
## has `LESSON_DELAY`. A row the catalogue does not have is refused by the recipe before this runs.
func start_recipe_route(marbles: Array, pre_bag: Array, owed: int, first_after: float,
		heat: int) -> void:
	_owed.clear()
	_route_rows.clear()
	_ordinary_rows.clear()
	_return_patrols_left = 0
	_patrol_bag_left = 0
	for id: String in marbles + pre_bag:
		if not _route_rows.has(id):
			_route_rows[id] = _with_ground(EventCatalogue.heated(EventCatalogue.by_id(id), heat))
	for id: String in marbles:
		_ordinary_rows[id] = true
	_route = MarbleBag.new(pre_bag, marbles, hash("%d:route-bag" % _rng.seed))
	for _i in owed:
		_owed.append(null)
	_next_in = first_after if first_after >= 0.0 else _roll_interval()

## The bag her route's events are drawn from, for a caller that rigs what comes next — a scene that
## wants a row met at a known point of the walk. Null before `start_day()`.
func route_bag() -> MarbleBag:
	return _route

## **Rigs her route so the marbles of `ids` are among the next `size` events handed out on it**:
## a bag of `size` marbles, `ids` and the rest drawn from the bag she was drawing from, is drawn from
## first, and that bag carries on with what it has left once the rigged one is empty
## (`MarbleBag.rig()`). A row that is not one the director sites — the man shouting, a mast, a
## place — is handed to her walk to site ahead of her when its marble comes up
## (`_place_on_her_route()`), and waits there for a legal site without holding up the events behind
## it. Answers the rigged bag's marbles, or nothing under `--force`, whose queue is the forced row's
## alone, and on a rig with no day.
##
## **The next `size` events she is owed are the rigged bag's**, so the guarantee is about what is
## handed out on her route and not about the bag alone: they are moved to the head of the owed list,
## ahead of a sprinkled dog not yet met, and the list is topped up when the day has fewer left. For a
## moment that is what she meets; for a place it is its marble, and the place is met once her walk
## finds it a site, which can be after an event behind it, or never.
## `siting` is the day's placement context, for a place; `heat` the shape its row is put in.
func rig_her_route(ids: Array[String], size: int, heat: int = 0,
		siting: EventScheduler.WalkSiting = null) -> Array:
	if _forced or not _route:
		return []
	if siting and not _siting:
		_siting = siting
	var ensured := []
	for id in ids:
		var def := EventCatalogue.by_id(id)
		if not def:
			push_error("a rigged route names no event in the catalogue: '%s'" % id)
			continue
		if not _route_rows.has(id):
			_route_rows[id] = _with_ground(EventCatalogue.heated(def, heat))
		ensured.append(id)
	_route.rig(ensured, size)
	var rigged := _route.bag_in_front()
	_bag_the_next(rigged.size())
	return rigged

## Today's row a marble names, or null — what a caller rigging her route prepares the siting for.
func route_row(id: String) -> EventDef:
	return _route_rows.get(id)

## A place whose own row names no ground — a loudspeaker mast, whose sites are the city's
## (`MastSites`) — is offered the sidewalk and the square when a marble puts it on her route, the
## ground `ResistanceDirector._add_a_mast_near()` offers a mast near a mark, and on it only what a
## mast site may be (`MastSites._is_eligible()`, asked by `EventScheduler.WalkSiting`). A copy, never
## the shared heated row every dawn placement of it reads (`EventCatalogue.heated()`).
static func _with_ground(def: EventDef) -> EventDef:
	if not def.placement.is_empty() or def.spawn_mode != EventDef.SpawnMode.MAP:
		return def
	var placed := def.duplicate() as EventDef
	placed.shape = def.shape
	placed.placement = [GameEnums.TileType.SIDEWALK, GameEnums.TileType.SQUARE]
	return placed

## The row the next marble from the route's bag names, peeked rather than drawn — a siting that
## fails must not spend it. A marble whose row has been met `max_per_day` times today is spent unmet
## and the next one asked; it is counted against a return patrol's bag like a marble handed out
## (`_handed_from_the_route()`), because it was one of that bag's marbles and the patrol's "within
## the next" is counted in them. Null when the bag has nothing left to name.
func _next_on_the_route() -> EventDef:
	for _i in ROUTE_SKIP_LIMIT:
		var id: Variant = _route.peek() if _route else null
		if id == null:
			return null
		var def: EventDef = _route_rows.get(id)
		if def and (not _ordinary_rows.has(id) or int(_met_today.get(id, 0)) < def.max_per_day):
			return def
		_route.draw()
		_handed_from_the_route()
	return null

## How many marbles in a row `_next_on_the_route()` may spend on rows that have had their day before
## it gives up: more than a whole bag, so it only stops on a bag whose every row is spent.
const ROUTE_SKIP_LIMIT := 64

## A marble that names a place rather than a moment — the man shouting or the mast a rigged bag puts
## on her route — is handed out the moment it is drawn, like any other marble: its owed slot and
## the marble are spent, and the place goes on the list of what her walk sites
## (`site_what_is_on_her_way()`), unplaced, the way day 3's fire waits there. That half sites it on
## its own cadence: on the branch of the day's route tree she is walking, past the streaming band
## and within `ON_HER_WAY_SIGHT` seconds of walking of it, through every acceptance rule a dawn
## placement is under, so it is never seen to appear, it is reachable on the route she is walking,
## and it is in the world once she walks on; and it re-sites it ahead of her if she turns away before
## it has been.
##
## **A place that cannot be sited yet holds nothing up.** A refusal is ordinary — she is off the
## day's routes, or walking home inside the streaming band of the branch's end — so the events
## behind its marble, a return patrol among them, come on the queue's own pacing while it waits, and
## a place that never finds a site is a place she does not meet. With no placement context at all
## (a rig that started the day without one) there is nowhere to ask, and the marble is spent unmet.
func _place_on_her_route(def: EventDef) -> void:
	_next_in = _roll_interval()
	_owed.pop_front()
	_route.draw()
	_handed_from_the_route()
	if not _siting:
		return
	_met_today[def.id] = int(_met_today.get(def.id, 0)) + 1
	var waiting := EventScheduler.Planned.new(def, Vector2.INF)
	_on_her_way.append(waiting)
	_placed_from_the_route[waiting] = true

## Whether `plan` is a place a marble from her route's bag put on her way (`_place_on_her_route()`),
## which joins the day's plan when it is first sited rather than at dawn.
func is_from_her_route(plan: EventScheduler.Planned) -> bool:
	return _placed_from_the_route.has(plan)

# ------------------------------------------------- the place that is on her way ---

## How long she has to have been **walking** before a place the day left to her walk is sited. Far
## enough in that a heading means something — a player who steps out of the door and turns round
## twice has not chosen a direction for the day yet — and past `LESSON_DELAY` with room to spare, so
## day 3's run lesson is over before the fire is put anywhere.
const ON_HER_WAY_AFTER := 18.0

## And this far from the doorstep besides, in pixels. The two together rather than either alone: the
## clock answers *has she settled into a direction* and the distance answers *is she out of the
## notch the home sits in*, and a player who spends the first half minute in the home street has
## satisfied one of them and neither.
const ON_HER_WAY_BEYOND_HOME := 400.0

## How much further she may have to walk past the streaming band to reach the site, in seconds —
## the width of the siting band, measured **along the route she is on** like the rest of it. Still
## well inside the outbound leg of a 210s day with the walk home in hand. The near end of the band
## is not a number of seconds but the streaming band itself; see `_siting_band()`.
const ON_HER_WAY_SIGHT := 16.0

## How long the thing has to be behind her before it is moved, in seconds of walking. It is not
## instant on purpose: three seconds of walking the wrong way is a player who has changed her mind,
## one frame of it is a player stepping round a bollard.
const ON_HER_WAY_TURNED_AWAY := 3.0

## How far behind her it has to be to count as behind her at all, as a dot product against the unit
## heading — past a right angle, by half.
##
## **A corner is not a change of mind, and a rule stated at zero cannot tell the difference.** She
## walks a lattice: a block of walking north with the fire a thousand pixels east puts it a few
## degrees behind square, so a threshold at zero re-sites it at every junction and she spends the
## day chasing something that is always the same distance ahead. At −0.5 that same turn leaves it
## alone — it is still the way she is generally going — and what does move it is a heading that has
## genuinely put it behind her, which is the case the rule is for.
##
## **It is the coarse half of the question and `EventScheduler.WalkSiting` answers the fine half.**
## A fire on the fork she did not take is a few degrees off square and passes this test for ever;
## what moves it is that it is no longer on the branch she is walking. See
## `_is_no_longer_on_her_way()`.
const ON_HER_WAY_BEHIND := -0.5

## How often the walk is looked at, in seconds of walking — one cadence for both halves of the
## question, because both are asked of the same walk and neither is worth a frame's answer.
##
## A refusal is ordinary — there is no tile of the row's own ground on the branch ahead of her, or
## the one there is stands in a door's clear ground or would close her way out — and the answer is to ask again a
## street later rather than to place it somewhere illegal. A placement already made is asked on the
## same beat whether the walk has left it behind, which is a walk of the route tree rather than a
## dot product and does not belong in a physics frame: a refused attempt scans her branch, rolls
## `Tuning.EVENT_PLACEMENT_TRIES` candidates and floods the reachability grid, and doing that sixty
## times a second while she walks into a corner is the one hitch on the beat of the day she is meant
## to be watching.
const ON_HER_WAY_LOOK := 1.0

## Sites, or re-sites, whatever the day budgeted and left for her walk to place: a tile of the row's
## own ground (a building face for the fire and the crews, a sidewalk for a man shouting) on the
## day's own route tree, **on the branch she is walking**, ahead of her by distance along that
## route, off screen, `ON_HER_WAY_SIGHT` seconds of walking short of being seen. Returns every plan
## this call moved, so the caller can give back the ground the old body was standing on and take the
## new — `EventManager._site_what_is_on_her_way()` is that caller — and a place from her route's bag
## sited for the first time, which the caller adds to the day's plan (`is_from_her_route()`).
##
## **The path is the day's route tree and nothing else is a site.** *(PLAYTEST-119: "the fire needs
## to spawn on the current path the player is on — moving it around works but valid spawn locations
## are only on the path".)* `EventScheduler.WalkSiting.ahead_of()` carries the geometry; what this
## half owns is *when* it is asked and *which* plan is asked about.
##
## **The walk home changes nothing.** *(PLAYTEST-120: "if they managed to avoid it thus far they
## should still have to try avoid it further. only once the event has actually taken place does it
## become fixed".)* Nothing here asks which leg of the day she is on: the return leg is a heading
## like any other, so a fire she has dodged is sited and moved ahead of the way home by the same
## rule. What keeps that from being a wall across the way home is the acceptance check — a site is
## refused unless the home and a calm area she has not used are both still reachable outside the
## fire's field and the engine's.
##
## **It may move until it is real, and never after.** A plan that has been streamed in once has
## recorded its scar and moved its block along its arc (`EventManager._create`), so the city already
## remembers it burning there; moving it then would mean repairing a fact, which is the one thing
## this repository does not do to a guarantee. `Planned.was_live` is that line, and it is drawn at
## the streaming radius rather than at the screen edge — which is 900px out against a view half
## diagonal of about 367, so in practice it stops moving a good six seconds of walking before she
## could ever have seen it.
##
## **Nothing is moved to satisfy the guarantee, and nothing is ever sited off the path.** When the
## branch ahead of her offers no legal tile of the row's own ground — she has stepped off the tree
## through a thinned seal or into an alley, the window holds none of that ground (no building
## frontage, for the fire and the crews), a candidate stands in a door's clear ground,
## or one would close her own way out — this answers with nothing and asks again a second later, from
## wherever she has got to. A day she walks into a corner is a day it waits.
func site_what_is_on_her_way(delta: float, at: Vector2, velocity: Vector2,
		plans: Array[EventScheduler.Planned]) -> Array[EventScheduler.Planned]:
	var moved: Array[EventScheduler.Planned] = []
	_forget_what_is_real()
	var speed := velocity.length()
	# The same clock `due()` runs on and for the same reason: a direction is something she is
	# travelling in, not something she is facing, and a player standing still has neither.
	if speed < Tuning.AHEAD_MIN_SPEED:
		return moved
	# Counted while nothing waits as well: a place a marble hands over mid-day
	# (`_place_on_her_route()`) is sited on a walk that has been under way all along.
	_walked += delta
	if _on_her_way.is_empty() or not _siting:
		return moved
	_since_the_last_look += delta
	if _walked < ON_HER_WAY_AFTER or _since_the_last_look < ON_HER_WAY_LOOK:
		return moved
	# The walking seconds since the previous look, which is what the turned-away clock counts in:
	# the look runs on its own cadence, so a frame's `delta` would undercount it by the cadence.
	var elapsed := _since_the_last_look
	_since_the_last_look = 0.0
	if at.distance_to(_map.home_world_position()) < ON_HER_WAY_BEYOND_HOME:
		return moved
	var heading := velocity / speed
	for plan in _on_her_way:
		if plan.is_placed() and not _is_no_longer_on_her_way(plan, at, heading, elapsed):
			continue
		if not plan.is_placed() and _waits_its_turn(plan):
			continue
		var band := _siting_band()
		var rng := _walk_rng if plan.def.kind == GameEnums.EventKind.ONE_SHOT \
				else (_place_rng if _placed_from_the_route.has(plan) else _crew_rng)
		var sited := _siting.ahead_of(plan.def, rng, _everything_but(plans, plan), at, heading,
				band.x, band.y)
		if not sited:
			continue
		plan.position = sited.position
		plan.path = sited.path
		plan.facing = sited.facing
		plan.role = sited.role
		_behind_her[plan] = 0.0
		moved.append(plan)
	return moved

## **A recurring row is sited on her way one at a time**: the next of the day's crews waits while
## another is sited ahead of her and not yet in the world. All of them at once would put the day's
## crews on the one stretch of street the band covers; one at a time, each is met on its own and
## the next is sited as the last comes into reach, so they are spread along the day's walk.
func _waits_its_turn(plan: EventScheduler.Planned) -> bool:
	if plan.def.kind == GameEnums.EventKind.ONE_SHOT:
		return false
	for other in _on_her_way:
		if other != plan and other.def.id == plan.def.id and other.is_placed():
			return true
	return false

## Drops from the list anything that is already real or already spent, so the loop above only ever
## considers a plan that can still legally be moved.
func _forget_what_is_real() -> void:
	var still_ours: Array[EventScheduler.Planned] = []
	for plan in _on_her_way:
		if plan.was_live or plan.spent:
			_behind_her.erase(plan)
			continue
		still_ours.append(plan)
	_on_her_way = still_ours

## Whether `plan` has stopped being on the way she is walking for long enough to be moved — see
## `ON_HER_WAY_TURNED_AWAY` for why a single look is not the question. The clock is reset by any
## look at which it is still on her way, so what it measures is a sustained change of direction
## rather than a total.
##
## **Two ways to stop being on her way, and the second is what a fork needs.** It is behind her
## (`ON_HER_WAY_BEHIND`), or it is no longer on the branch she is walking — the case of a fire
## sited before she committed to one of two ways out of a junction, which stays a few degrees off
## square from the fork she actually took and would otherwise sit there, on a street she is never
## going to walk down, for the rest of the day.
##
## **Being momentarily off the tree is not a change of direction.** `WalkSiting.still_ahead_of()`
## answers true when it cannot tell — she has cut through a park, taken an alley, or stepped over a
## thinned seal — because the alternative is re-siting the fire every time she leaves the sidewalk.
func _is_no_longer_on_her_way(plan: EventScheduler.Planned, at: Vector2, heading: Vector2,
		elapsed: float) -> bool:
	var toward := plan.position - at
	var still_ahead := toward.length_squared() < 1.0 \
			or (toward.normalized().dot(heading) > ON_HER_WAY_BEHIND
			and _siting.still_ahead_of(at, heading, plan.position))
	if still_ahead:
		_behind_her[plan] = 0.0
		return false
	var behind: float = float(_behind_her.get(plan, 0.0)) + elapsed
	_behind_her[plan] = behind
	return behind >= ON_HER_WAY_TURNED_AWAY

## How far ahead of her the siting goes, as a near and a far distance.
##
## **The near end is the streaming band**, radius plus hysteresis, and it is a distance *across the
## block* rather than along the route: a placement inside it would be in the world on the frame it
## was made — a fire that has already recorded its scar, and so one that can never be moved again,
## before she has walked a single step toward it. Streaming is a radius, so this end of the band has
## to be one too. It puts the first sight of it at least 9 seconds of walking away, since the view
## reaches `Tuning.VIEW_HALF_EXTENT` and the rest is walking.
##
## **The far end is how much more walking there is to reach it**, so it is read along the route
## through every corner and junction — `EventScheduler.WalkSiting.ahead_of()` walks the cells. A
## distance off the edge of the view would be the straight-line reading again, and the day's routes
## are loop-erased walks rather than lines: 1200px across the block is regularly 2800px of walking,
## and a band stated as a straight line leaves almost nothing on the route inside it.
func _siting_band() -> Vector2:
	var near := Tuning.EVENT_STREAM_RADIUS + Tuning.EVENT_STREAM_HYSTERESIS
	return Vector2(near, near + Tuning.WALK_SPEED * ON_HER_WAY_SIGHT)

## The day's other plans, for spacing and for the walkability question — everything but the one
## being sited, which must not be spaced against the body it is about to stop standing at.
func _everything_but(plans: Array[EventScheduler.Planned],
		plan: EventScheduler.Planned) -> Array[EventScheduler.Planned]:
	var others: Array[EventScheduler.Planned] = []
	for other in plans:
		if other != plan:
			others.append(other)
	return others

## Hands the day's return leg its own pressure — `docs/TODO.md`'s M98, pressure in the empty acts
## — the moment `EventManager` hears `EventBus.return_phase_started`. `Tuning.RETURN_PATROLS_PER_
## ACT[act - 1]` copies of `police_patrol`, at the day's own heat, are owed on top of the day's own
## events, each rigged into the route's bag in turn (`_rig_the_next_patrol()`) and sited
## `TOWARD_PLAYER` down her own carriageway rather than crossed — see
## `_toward_her_on_the_road()` — and the interval the queue rolls for the rest of the day switches
## from `Tuning.AHEAD_INTERVAL` to the tighter `Tuning.RETURN_PATROL_INTERVAL`, so the extra rows
## land inside the leg rather than after she is home.
##
## Acts I and II are untouched: the array's first two entries are 0, so the teaching days and the
## return she learns the mechanic on stay exactly as they were measured.
##
## **Idempotent for the day.** `return_phase_started` can fire more than once — the baby wakes and
## is walked back down before settling again — and the return is owed exactly once; `_return_owed`
## is what remembers that past the phase dropping back to `WALKING` and the rows already owed stay
## owed regardless. **`--force` leaves the forced queue alone**: under it `_owed` holds only the
## forced row and there is no ordinary queue for this to add to or re-pace.
func owe_the_return(day: int, heat: int) -> void:
	if _return_owed or _forced:
		return
	_return_owed = true
	var act := Tuning.act_for_day(day)
	if act < 3:
		return
	var count: int = Tuning.RETURN_PATROLS_PER_ACT[act - 1]
	if count <= 0:
		return
	var for_return := _patrol_toward_her(heat)
	if not for_return:
		return
	# One more event owed for each patrol, as the patrols were always on top of what the day bought;
	# each is the ensured marble of a rigged bag, rigged as the one before it is handed out.
	_route_rows[RETURN_PATROL] = for_return
	for i in count:
		_owed.append(null)
	_return_patrols_left = count
	_rig_the_next_patrol()
	_return_pacing = true
	# Shortened immediately rather than left for the next ordinary roll to expire — `AHEAD_INTERVAL`
	# can still be waiting out up to 26s when the phase turns, and a 33s return leg cannot afford
	# to spend most of itself on a wait rolled under the pacing this call just replaced — but only
	# ever shortened, never lengthened: a `minf` against whatever is already ticking down means the
	# return can land its first row sooner than the ordinary pacing would have, never later.
	_next_in = minf(_next_in, _roll_interval())

## The marble a return patrol is in the route's bag.
const RETURN_PATROL := "police_patrol"
## How many of today's return patrols are still to be rigged into the route's bag.
var _return_patrols_left := 0
## How many more events are handed out of the route's bag before the next patrol is rigged: the
## size of the patrol's own bag, counted down as it is drawn.
var _patrol_bag_left := 0

## **Each return patrol is a rigged bag** of `Tuning.RETURN_PATROL_WITHIN_THE_NEXT` marbles, the
## patrol and the rest drawn from the bag she was drawing from, and the next is rigged once that bag
## has been handed out — so each comes within its own bag's events and two never come back to back
## unless the second bag starts with what the first ended on. *(inbox #561 in coral-bunny: "The return patrols in acts III and IV are added at the back of the
## route queue -- the marble bag approach will properly fix this" · "they will need rigged
## bags".)* Behind the day's own events, the dozens the dawn buys and the pacing never drains, they
## would never come; rigged, each one comes within that many events of the last.
func _rig_the_next_patrol() -> void:
	if _return_patrols_left <= 0 or not _route:
		return
	_return_patrols_left -= 1
	_route.rig([RETURN_PATROL], Tuning.RETURN_PATROL_WITHIN_THE_NEXT)
	_patrol_bag_left = _route.bag_in_front().size()
	_bag_the_next(_patrol_bag_left)

## Counts one event handed out of the route's bag against the patrol's bag, and rigs the next patrol
## when it is spent.
func _handed_from_the_route() -> void:
	if _patrol_bag_left <= 0:
		return
	_patrol_bag_left -= 1
	if _patrol_bag_left == 0:
		_rig_the_next_patrol()

## A copy of `police_patrol` at `heat`, sited `TOWARD_PLAYER` down her own carriageway — the shape
## both the return leg's patrols and a torn poster's are sent in. Null, with an error, if the
## catalogue has no such row.
##
## The day's own heated copy — the same call `EventScheduler.build_day()` makes for every other
## placement of the row today — duplicated once more rather than mutated, because `heated()` caches
## its answer and shares it with every ordinary `MAP` placement of the row for the rest of the run:
## setting `spawn_mode` on that shared copy would turn every later patrol into a director-sited
## one, not just the ones sent here. See `EventCatalogue._hot` and `EventDef.at_heat()`'s own note
## on why a heated row is a derived copy in the first place.
func _patrol_toward_her(heat: int) -> EventDef:
	var cold := EventCatalogue.by_id("police_patrol")
	if not cold:
		push_error("no 'police_patrol' row in the catalogue")
		return null
	var heated := EventCatalogue.heated(cold, heat)
	var toward := heated.duplicate() as EventDef
	toward.shape = heated.shape
	toward.spawn_mode = EventDef.SpawnMode.TOWARD_PLAYER
	return toward

## A torn poster has drawn the pursuit marble (`PosterWalls`): a `police_patrol` is sent toward her
## from off screen, under the lead its row already owes — the one `_toward_her_on_the_road()` gives
## the return leg's patrols, down the carriageway lane driving toward her, at least
## `offscreen_notice` seconds outside the view.
##
## **Sited once she walks, not while she pushes.** A heading into a wall has no along-street
## component to send a car down, so the patrol waits for her to be going somewhere again —
## `TEAR_PATROL_AFTER` seconds of walking — and waits a second more whenever there is no road beside
## her to send it down, the way every other `due()` siting does.
##
## **Outside the day's own queue.** It does not join `_owed`, take a turn in it, roll an interval
## or touch any stream, so a day on which she tears a poster hands every other director-sited
## row the same interval it would have had. At most one is waiting: a second pursuit marble before
## the first patrol arrives is the same patrol, already on its way. `--force` leaves it alone as it
## leaves the return leg's.
func send_a_patrol(heat: int) -> void:
	if _forced or _sent:
		return
	_sent = _patrol_toward_her(heat)
	_sent_in = TEAR_PATROL_AFTER

## Seconds of walking between a tear that sends a patrol and the patrol being sited: enough for her
## to have turned from the wall and have a heading along the street.
const TEAR_PATROL_AFTER := 1.0

## Whether a patrol a tear sent can be sited now, and where: `[EventDef, path]` or empty. Runs the
## same clock `due()` does — only while she is walking — on its own countdown.
func _site_the_sent_patrol(delta: float, at: Vector2, velocity: Vector2) -> Array:
	if not _sent:
		return []
	var speed := velocity.length()
	if speed < Tuning.AHEAD_MIN_SPEED:
		return []
	_sent_in -= delta
	if _sent_in > 0.0:
		return []
	var path := _toward_her_on_the_road(at, velocity / speed, _sent)
	if path.is_empty() or not EventScheduler.clear_of_the_doors(path[0], path, _doors,
			_sent.field_reach()):
		_sent_in = 1.0
		return []
	var handed := _sent
	_sent = null
	return [handed, path]

## Whether a torn poster's patrol is waiting to be sited. For the tests.
func has_a_sent_patrol() -> bool:
	return _sent != null

## Advances the clock and returns the event to place plus the path to place it on, or null when
## nothing is due. `heading` is the direction she is actually travelling, not the way she is
## facing: something that crosses in front of a player standing still is not in front of
## anything.
##
## Returns `[EventDef, PackedVector2Array]`, or an empty array. A place the route's bag names is
## handed to her walk to site (`_place_on_her_route()`) and answers the empty array: it joins the
## day's plan through `site_what_is_on_her_way()` once it has a site.
func due(delta: float, at: Vector2, velocity: Vector2) -> Array:
	var sent := _site_the_sent_patrol(delta, at, velocity)
	if not sent.is_empty():
		return sent
	if _owed.is_empty():
		return []
	var speed := velocity.length()
	# The clock only runs while she is going somewhere. A player who stops to let the meter
	# recover is not owed a cat for waiting, and one who spends the day in a park should not
	# come back to the pavement and be handed four of them at once.
	if speed < Tuning.AHEAD_MIN_SPEED:
		return []
	_next_in -= delta
	if _next_in > 0.0:
		return []

	# Peeked rather than popped, because what it wants sited depends on what it is: a pursuer is
	# put *in her way* rather than across it, a `TOWARD_PLAYER` row is put *down* her own line, and
	# a placement that fails must not spend the event.
	var next := _owed[0] as EventDef
	var from_the_bag := next == null
	if from_the_bag:
		next = _next_on_the_route()
		if not next:
			# The bag has nothing left to name today: the event is owed nothing.
			_owed.pop_front()
			return []
	if from_the_bag and next.spawn_mode_on(_day) == EventDef.SpawnMode.MAP:
		_place_on_her_route(next)
		return []
	var heading := velocity / speed
	# A `TOWARD_PLAYER` row whose `placement` names `ROAD` is a car, not a bike — `police_patrol`
	# is the one row `owe_the_return()` ever adds this way — and a car belongs on the carriageway
	# lane that drives toward her rather than on her own pavement. `_toward_her()` is still what
	# every `TOWARD_PLAYER` row on foot (`cyclist`, `loose_dog`) gets; only the road-placed ones
	# take the road-aware sibling.
	var path: PackedVector2Array
	if next.spawn_mode == EventDef.SpawnMode.TOWARD_PLAYER:
		path = _toward_her_on_the_road(at, heading, next) \
				if next.placement.has(GameEnums.TileType.ROAD) \
				else _toward_her(at, heading, next)
	else:
		path = _crossing_ahead_of(at, heading, next)
	if path.is_empty():
		# Nowhere to put it — she is in the middle of a park, or against the map edge. Try
		# again shortly rather than burning the allowance on a place that would not read.
		_next_in = 1.0
		return []
	# **A region door keeps clear ground around itself, and a run sited in front of her is a
	# placement like any other.** The whole path is asked, not its start: a cyclist coming down her
	# own line *through* a door's gap is exactly what this refuses, and a row whose lead happens to
	# clear the gap while its run does not would slip past a check on the spawn point alone.
	# Refused rather than nudged — the same "try again shortly" the branch above takes, so the
	# allowance is not burnt and the row arrives once she is past the door.
	if not EventScheduler.clear_of_the_doors(path[0], path, _doors, next.field_reach()):
		_next_in = 1.0
		return []
	_next_in = _roll_interval()
	var handed := _owed.pop_front() as EventDef
	if from_the_bag:
		handed = next
		_route.draw()
		_handed_from_the_route()
	_met_today[handed.id] = int(_met_today.get(handed.id, 0)) + 1
	# Refilled rather than seeded with a hundred copies, so the queue length stays honest and
	# `owed()` — which the HUD reads — says "one more coming" rather than a number that means
	# nothing under this flag.
	if _forced and _owed.is_empty():
		_owed.append(_forced)
	return [handed, path]

func _roll_interval() -> float:
	# Fixed rather than rolled under `--force`, and it does not touch `_rng`: the flag is for
	# looking at one row several times, and a rolled 11-26s wait between looks is the thing it
	# exists to remove. Leaving the stream alone also means a `--seed` city is bit-identical with
	# the flag on and off, so what she walks past is the same city either way.
	if _forced:
		return _forced_interval
	if _return_pacing:
		return _rng.randf_range(Tuning.RETURN_PATROL_INTERVAL.x, Tuning.RETURN_PATROL_INTERVAL.y)
	return _rng.randf_range(Tuning.AHEAD_INTERVAL.x, Tuning.AHEAD_INTERVAL.y)

## A run straight across her line, `AHEAD_LEAD_DISTANCE` in front of her.
##
## Perpendicular to *her* heading rather than to the street, which is the difference between a
## cat that crosses the road and a cat that crosses her path. On a pavement those are the same
## thing; walking across a square they are not, and the second one is what was asked for.
##
## Empty when the crossing point is not somewhere anybody could walk — the lead lands inside a
## building, or outside the map. The caller waits and asks again.
##
## **A pursuer is sited at the lead point itself and given no route.** It does not cross her line,
## it comes down it, so a path is the wrong shape for it entirely — and building one anyway puts
## the day-3 dog a street's width off to one side of the place this function has just checked,
## 266px away and diagonal, which on a 640x360 view is at the corner of the screen or past it. What
## she is owed is the sight of it coming, and it has to be sited where that can be seen — but the
## seeing is now a screen-edge badge's job for as long as the dog is off screen, not the dog's own
## silhouette, which is the overturn below.
##
## **And a pursuer is sited at least `def.offscreen_notice` seconds outside the view along the
## heading in play, not against a flat number sized for one axis.** *(2026-09-07: "bikers /
## unleashed dogs all pop in in front of the player instead of starting off screen", "events that go
## towards the player (biker / pursuing dog) should at least be 200ms off screen with a warning",
## and, of the day-3 dog specifically, "the run tutorial spawns inside the visible area making the
## headsup way too short now".)* A flat 200px sits inside the 320px horizontal boundary, so a dog
## sited while she walked east or west had no offscreen phase at all — it appeared already on
## screen. `Tuning.offscreen_lead(heading, closing_speed, def.offscreen_notice)` asks the real
## question instead: how far to the edge of the view *this* heading actually reaches, plus how far
## it and she together cover in the row's own notice — for `charging_dog` at 130px/s pursuing,
## closing at 130 + `WALK_SPEED` (92) = 222px/s, `EventDef.offscreen_notice` of 0.5s buys 111px, sized
## against playtest 20's own measurement of how much closing an evasion needed. See that field's own
## reasoning for why the dog carries a different notice than the rest of the catalogue, and its own
## `telegraph_time` for what pays for the longer approach.
##
## **Unavoidable, on purpose, was the day-3 dog's whole point** — a dog starting further away is a
## dog with more room to be walked around, which is exactly what siting it close was for.
## *(2026-09-07: asked for a close, unavoidable teaching dog · overturned to a further one, because
## the tap-controlled heads-up was too short at the old distance.)* So the dog moves out with
## everything else, and whatever keeps the lesson forceful now has to come from somewhere other than
## siting it too close to see coming — an open question, not one this function answers.
##
## **The site is a direction and a check, not where the pursuer is created.** `EventManager` warns
## of it first (`EventManager._warn_down_her_heading()`, M226): its badge is up alone for its own
## `offscreen_notice`, pointing down the way this site lies from her, and it is then created just out
## of sight that way on walkable ground (`PendingWarning.along_her_heading()`), its approach still to
## run. The lunge is still fired by **proximity** (see `EventInstance._lunged`).
##
## **This function only ever sites `charging_dog` on `Tuning.RUN_TAUGHT_DAY`.** Every day after,
## `EventDef.spawn_mode_on()` answers `MAP` instead of `AHEAD_OF_PLAYER` for that row, so
## `EventScheduler` places it on a tile like `alley_robbery` and `start_day()` above never adds it
## to `_owed` at all — it is not sited off her heading by this function, it is not sited by this
## function. A pursuer arriving here is always the teaching day's own dog, dead ahead on purpose,
## because the lesson depends on being unavoidable.
func _crossing_ahead_of(at: Vector2, heading: Vector2,
		def: EventDef = null) -> PackedVector2Array:
	var lead := Tuning.offscreen_lead(heading, def.pursue_speed + Tuning.WALK_SPEED,
				def.offscreen_notice) \
			if def and def.pursues \
			else (def.ahead_of_player_lead() if def else Tuning.AHEAD_LEAD_DISTANCE)
	var centre := at + heading * lead
	if not _map.is_walkable(_map.world_to_tile(centre)):
		return PackedVector2Array()
	if def and def.pursues:
		return PackedVector2Array([centre])
	var across := Vector2(-heading.y, heading.x) * float(CROSSING_REACH_TILES * Tuning.TILE_SIZE)
	# The side it comes from is a coin flip, so a player cannot learn to watch one shoulder.
	if _rng.randf() < 0.5:
		across = -across
	var from := centre - across
	var to := centre + across
	if not _map.in_bounds(_map.world_to_tile(from)) or not _map.in_bounds(_map.world_to_tile(to)):
		return PackedVector2Array()
	return PackedVector2Array([from, to])

## A run straight *down* her own line rather than across it: `TOWARD_PLAYER`'s whole point, for a
## row on foot (`cyclist`, `loose_dog`). Returns `[place, far end]`: where its warning's badge
## points, and the far end of the route it will be created on once that warning is over —
## `EventManager` puts the warning up rather than the thing (`PendingWarning`), and the direction the
## thing comes from is read off these two points.
##
## **The place is just off screen, whatever the row's telegraph.** *(2026-09-07: "bikers / unleashed
## dogs all pop in in front of the player instead of starting off screen", and "events that go
## towards the player (biker / pursuing dog) should at least be 200ms off screen with a warning".)*
## `PendingWarning.down_her_line()` puts it just out of sight along her heading, on a sidewalk or a
## square.
## *(PLAYTEST-145: "I don't like that the warning is tied to the size of the field or the speed.")*
## The warning is the row's own `telegraph_time`, spent before the thing exists, so nothing about
## where it is sited has to outlast it.
##
## **The line is straightened onto the pavement she is standing on, when she is standing on one.**
## *(2026-09-07: "also biker should be on the same side of the road not the other side".)* Sited
## along her literal heading, the lead drifts across the carriageway from a heading only a little off
## the corridor's own axis — a diagonal drag on the touch controls crosses a six-tile street before
## the lead reaches the edge of the view, landing the row on the far sidewalk, where it reads as
## scenery rather than as a lane she has to answer for. `_onto_her_side()` below is the preference,
## not a requirement: where there is no pavement edge to prefer — the carriageway, a junction, open
## ground — or the heading has no along-corridor component to send it down, the literal heading is
## used exactly as before.
##
## Empty when there is no sidewalk or square at the place, or the route would leave the map. The
## caller waits and asks again.
func _toward_her(at: Vector2, heading: Vector2, def: EventDef) -> PackedVector2Array:
	var site_heading := _onto_her_side(at, heading)
	var place := PendingWarning.down_her_line(_map, def, at, site_heading)
	if place == Vector2.INF:
		return PackedVector2Array()
	var path := PendingWarning.route_down_her_line(_map, place, at, site_heading)
	if path[0].distance_to(path[1]) < Tuning.TILE_SIZE:
		return PackedVector2Array()
	return path

## Whether a route stays out of the clear ground around today's region doors — the same refusal
## `due()` makes of every siting, asked again by `EventManager` of a warned row's route when the
## row is created, since its place has moved with her since it was sited.
func clear_of_the_doors(path: PackedVector2Array, def: EventDef) -> bool:
	return EventScheduler.clear_of_the_doors(path[0], path, _doors, def.field_reach())

## The road-aware sibling of `_toward_her()`, for a `TOWARD_PLAYER` row whose `placement` names
## `ROAD` — `owe_the_return()`'s own `police_patrol` copies and a torn poster's (`send_a_patrol()`),
## a car rather than a bike.
## `_toward_her()` straightens the line onto *her* pavement; a car has no business on a pavement
## at all, so this runs it down the **carriageway lane that drives toward her** instead, using
## `CrowdLanes` for the lane geometry the same way `Crowd` sites one.
##
## Built the same way `_onto_her_side()` reads a corridor's own axis, then handed to
## `CrowdLanes`: `pavement_inward()` says which axis the corridor she is beside runs on and which
## way is into it, `corridor_at()` says which corridor that is, and `road_lane()` picks the lane
## that legally runs the direction the car is coming from — **opposite her own heading**, since it
## is meeting her rather than following her.
##
## Empty wherever there is nothing to run a car down: she is not beside a plain sidewalk edge at
## all (`pavement_inward()` answers `Vector2i.ZERO` for a park, a square, a junction, or the
## carriageway itself), her heading has no along-corridor component to pick a direction from, or
## the corridor there has no carriageway to drive on — a precinct is paved kerb to kerb, so its
## "road" tiles fail `is_driveable_at()` and this returns empty exactly where the brief asks it
## to: a park, a square, a precinct.
##
## **Created at once, not warned first.** A row on foot that `_toward_her()` sites goes up as a
## screen-edge warning before it exists (`EventDef.warns_before_it_exists()`); a patrol is sited
## here in the world at the ordinary `Tuning.offscreen_lead()` margin instead, and telegraphs on its
## way in (`telegraph_time` 1.97s) with no badge, since 74px/s is slower than a walk and it is never
## `hard_fail` (`EventDef.at_heat()` states it for the `PRESSES` rung) — that is why
## `DangerEdge._is_worth_an_arrow()` gives it no badge today. Under the player's rule a thing
## telegraphs only if it goes fast, can end the day and comes toward her (PLAYTEST-145, statements
## 19-24), and a patrol is neither fast nor `hard_fail`, so it needs no telegraph at all; what it
## does instead is M226's.
func _toward_her_on_the_road(at: Vector2, heading: Vector2, def: EventDef) -> PackedVector2Array:
	var inward := _map.pavement_inward(_map.world_to_tile(at))
	if inward == Vector2i.ZERO:
		return PackedVector2Array()
	var vertical := inward.x != 0
	var along := Vector2(inward.y, inward.x)
	var component := heading.dot(along)
	if is_zero_approx(component):
		return PackedVector2Array()
	var site_heading := along * signf(component)
	var index := CrowdLanes.corridor_at(at.x if vertical else at.y)
	if index < 0:
		return PackedVector2Array()
	# The car drives opposite her own along-corridor heading — coming down the street as she
	# walks up it — so its lane is the one `CrowdLanes.road_direction()` says legally runs that
	# way, not merely a point somewhere in the road band.
	var direction := -(site_heading.y if vertical else site_heading.x)
	var lane_coordinate := CrowdLanes.lane_centre(index, CrowdLanes.road_lane(vertical, direction))
	var closing := def.speed + Tuning.WALK_SPEED
	var lead := Tuning.offscreen_lead(site_heading, closing, def.offscreen_notice)
	var far := at + site_heading * lead
	var behind := at - site_heading * lead
	if vertical:
		far.x = lane_coordinate
		behind.x = lane_coordinate
	else:
		far.y = lane_coordinate
		behind.y = lane_coordinate
	if not _map.is_driveable_at(vertical, _map.world_to_tile(far)) \
			or not _map.is_driveable_at(vertical, _map.world_to_tile(behind)):
		return PackedVector2Array()
	return PackedVector2Array([far, behind])

## Swaps a heading with a lateral drift for the corridor's own axis, when she is standing on a plain
## pavement edge — `CityMap.pavement_inward()` names which side of a corridor a sidewalk tile is on,
## and its own axis (`RIGHT`/`LEFT` for a corridor running north-south, `DOWN`/`UP` for one running
## east-west) is the only one a `TOWARD_PLAYER` row's approach has to answer to. Zeroing the
## heading's component on that axis and keeping only the along-corridor part sends the row straight
## down *her* pavement instead of wherever her literal heading happens to point, so it approaches
## from ahead along the street rather than drifting across it — which is what a bike riding down a
## street already does, whatever diagonal she happens to be walking at.
##
## Returns `heading` unchanged in the two cases where there is nothing to prefer: she is not on a
## plain sidewalk edge (the carriageway, a junction, open ground — `pavement_inward()` answers
## `Vector2i.ZERO`), or her heading has no along-corridor component at all, which is walking straight
## across the street and leaves no corridor line to send the row down.
func _onto_her_side(at: Vector2, heading: Vector2) -> Vector2:
	var inward := _map.pavement_inward(_map.world_to_tile(at))
	if inward == Vector2i.ZERO:
		return heading
	var along := Vector2(inward.y, inward.x)
	var component := heading.dot(along)
	if is_zero_approx(component):
		return heading
	return along * signf(component)
