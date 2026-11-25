class_name EventDirector
extends RefCounted
## Places the events whose content is *the moment they happen to you* rather than *where they
## are*: the ones the day owes her and the player's own walk sites.
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
## **What is deliberately kept.** The day still says how many it owes, in the declared table
## (`PlacementDensity.moments_on()`, a number an act, measured) — so making the cat land cannot
## quietly make the day denser too. And the spawn is far enough ahead to be a *reaction window*: `AHEAD_LEAD_DISTANCE` is
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
## `EventDef.is_sited_from_her_walk()` — day 3's burning building, and the day's poster crews
## after it — is a place in every sense: a tile, a body, a field, and what it leaves on the city
## outlives the day. What it cannot be is *anywhere*: the fire is the authored beat of act I and
## a crew is the walls visibly changing, and either one on a street she never walks down is a
## silhouette spent on nothing. So the day plans it and this sites it, on a tile of the row's
## own ground ahead of her heading (a building face for the fire and the crews), once her
## direction for the day is clear.
##
## The two jobs share this class because they share the one thing neither the scheduler nor the
## manager has: **the direction she is actually travelling, now**. They do not share a queue, an
## interval or a spawn — a crossing is created on the spot and forgotten, and a place is written
## into the day's own plan for `EventManager` to stream like any other.

## Seconds between two `AHEAD` events, so the day's allowance is spread over the walk rather
## than spent in the first ten seconds. The director rolls within this band.
const AHEAD_INTERVAL := Vector2(11.0, 26.0)
## Chance, rolled once a day past `Tuning.RUN_TAUGHT_DAY`, that `EventDirector` sends `charging_dog` in
## its day-3 shape again — off her heading, already noticing her, no tip and no guarantee. See
## `EventDirector._owe_the_sprinkled_dog()`.
##
## **Measured with `tests/probes/m96_dog_sprinkle.gd`, not derived**, the same way `Tuning.
## Tuning.CROWD_PEDESTRIANS_PER_ACT` and every other density number in this file is: eight seeds, every
## day past the teaching day, a whole day of continuous walking. Pushed to the front of the
## director's own queue rather than appended — `tests/probes/m99_caps.gd` already found that a busy
## day's own `AHEAD_OF_PLAYER` pool is oversubscribed by design (dozens queued, a handful drained
## before the day ends), so an appended roll was met **zero times in 88 sampled days** before this
## was pushed to the front instead; pushed, every roll that lands is met. **0.15 measured a mean of
## 1.00 met encounters per run** (one seed of eight rolled none, one rolled two); **0.25** — the
## value kept — **measured 1.75** (one seed rolled none, one rolled three). "A few per run, not per
## day" reads as a mean nearer two than one, so 0.25 is the choice.
const CHARGING_DOG_SPRINKLE_CHANCE := 0.25
## Extra `police_patrol` rows the return leg owes in acts III and IV, one entry per act —
## `Tuning.act_for_day()` is 1-based, so `RETURN_PATROLS_PER_ACT[act - 1]`. Acts I and II carry
## none, so the teaching days and the return she learns the mechanic on stay exactly as they were
## measured. Sized against the return leg's own length (`docs/DECISIONS.md`, M98: a return leg
## measured at 32.9s in act III and 47.3s in act IV) and the row's own cost — non-lethal, 74px/s,
## a 185px outer radius — so a leg meets one or two of them rather than four: an amount the
## sleeping baby can take, not a gauntlet.
const RETURN_PATROLS_PER_ACT: Array[int] = [0, 0, 2, 3]
## How far apart the return leg's own patrols land, once `EventDirector.owe_the_return()` has
## fired for the day. Tighter than `AHEAD_INTERVAL` on purpose, so the rows it owes land inside
## the 33-47s return leg they were sized against rather than arriving after she is already home.
const RETURN_PATROL_INTERVAL := Vector2(9.0, 16.0)
## The same for each of the return leg's patrols (`RETURN_PATROLS_PER_ACT`): rigged into a bag of
## this many as the one before it is handed out, so they come one after another inside the leg.
## *(inbox #561 in coral-bunny, of the return patrols: "they will need rigged bags".)* Two, with
## `RETURN_PATROL_INTERVAL` between handouts, draws a patrol's marble every 18-32s of walking, which
## lands one or two inside a return leg rather than all of them; a patrol with no room when its
## marble is drawn waits for a later turn that has some (`_sent_waiting`).
const RETURN_PATROL_WITHIN_THE_NEXT := 2
## Rows whose share of her route's bag is set here rather than by `ROUTE_BAG_MARBLES_PER_WEIGHT`
## times their weight, because the weight is not only the bag's: the dawn's draw reads it on every
## day the row is placed, as its share of the view bags and of the moments she is owed. Each is the
## share of the ordinary bag its marbles make, as near as whole marbles come
## (`ordinary_route_marbles()`), so it holds whatever else the bag holds. *(inbox #566 in
## feathery-stork, of day 3's bag of 16: "I'd say we could do 2 dogs -- we don't need the charging
## dog that often and in 17 rolls there are two guaranteed ones", then "16 is fine".)*
## `charging_dog`'s is two marbles in sixteen: with the dog walker the director sends ahead of her
## in day 3's bag, three in twenty-six. It is in the bag only on day 3, the one day it is
## director-sited; its lesson is a bag of its own in front (`EventDirector._teach_the_run()`) and
## takes none of these, so with the lesson these marbles rarely reach `max_per_day`'s 3.
const ROUTE_BAG_SHARE_OF := {"charging_dog": 2.0 / 16.0}
## Marbles per unit of `EventDef.drawn_as_often()` in the bag the director draws her route's
## events from (`EventDirector`, `MarbleBag.in_proportion()`), rounded, at least one a row.
## *(olive-koala, statement 2: "events should use the marble bag approach as well. that way we
## can control what the player sees on their route".)* The bag is the stretch over which the
## mix is exact, and at 2 every weight comes out whole. With the rows the director sends ahead
## of her in it (`EventDef.is_sent_ahead()`: the dog walker, the patrol and the convoy, the
## heaviest of its rows) a bag holds more than a whole day of walking at `AHEAD_INTERVAL`
## hands out (`tests/probes/olive_badger_route_mix.gd` counts both), so the mix is exact over
## a bag, never over a day; and over a bag only where nothing waits for room, since a sent row
## that waits comes after the marbles handed out meanwhile (`_sent_waiting`) and can fall past
## its bag's end.
const ROUTE_BAG_MARBLES_PER_WEIGHT := 2.0

## How far to either side of the crossing point the run reaches at most. A street's width, so the
## cat comes out of one kerb and is gone into the other; a run is cut where something solid stands
## sooner (`crossing_ahead_of()`).
const CROSSING_REACH_TILES := Tuning.STREET_WIDTH

var _map: CityMap
## What every run this director sites is cut to (`Navigator.trim()`), so a cat, a bike or a car sent
## at her never runs through a building, a barrier or a body.
var _navigator: Navigator
var _rng := RandomNumberGenerator.new()
## The events the day owes her and has not yet spent, in the order they are handed out. A `null`
## entry is **a marble from the route's bag**: one of the events the day owes her route, which row
## it is decided by `_route` when it is handed out rather than at dawn. A
## non-null entry is a row owed as itself — a sprinkled dog, a forced row.
var _owed: Array[EventDef] = []
## The day, for the siting a row asks for on it (`EventDef.spawn_mode_on()`).
var _day := 0
## **What she meets on her route is drawn from a marble bag.** *(olive-koala, statement 2: "events
## should use the marble bag approach as well. that way we can control what the player sees on
## their route".)* Filled with each row the director sites today in proportion to its weight
## (`ROUTE_BAG_MARBLES_PER_WEIGHT`), so over any stretch the length of a bag in which nothing waits
## for room the mix she meets is the rows' own rather than a roll's streaks; a sent row that waits
## (`_sent_waiting`) comes after the marbles handed out meanwhile, which can carry it past its bag's
## end. The marbles are row ids, looked up in `_route_rows`. Its own stream, derived from the day's
## director stream rather than drawn from it, so the bag draws nothing from the director's stream;
## which row a handout is still moves the draws after it there (a crossing spends one on its side,
## the convoy one on the end it comes from each time it is sited, the dog walker one on the point of
## its bark it is created at, `age_it_is_sent_at()`, and the patrol, a loose dog or a cyclist none),
## and the same seed and the same walk are the same day. Null on a rig that has not started a day.
var _route: MarbleBag = null
## Row id -> today's `EventDef` for it, heated like the day's own placements: every row the
## ordinary bag holds, and any a rig put in front of it (`rig_her_route()`).
var _route_rows := {}
## Row id -> how many of it the director has handed out today, so a row's `max_per_day` holds for
## what she meets as it holds for what the dawn draws. Asked only of the ordinary bag's rows
## (`_ordinary_rows`): a rigged marble is there because something asked for it.
var _met_today := {}
## The ids the ordinary bag is filled with today.
var _ordinary_rows := {}
## The plans a marble put on her route (`_place_on_her_route()`). Not in the day's plan until first
## sited: `EventManager` adds one there then (`is_from_her_route()`).
var _placed_from_the_route := {}
## The ids of the rows whose place is laid on her path just ahead of her
## (`WalkSiting.lay_just_ahead()`) rather than past the streaming band: the ones a rig named with
## `just_ahead` (`rig_her_route()`). Cleared in `start_day()`.
var _rigged_just_ahead := {}
## The plans of `_placed_from_the_route` whose id `_rigged_just_ahead` holds, as `plan -> true`.
var _just_ahead := {}
var _next_in := 0.0
## Whether `owe_the_return()` has already handed today its return-phase patrols. Set once and
## never cleared until `start_day()`, so a baby that wakes and settles again does not owe a
## second batch — see that function's own doc.
var _return_owed := false
## Whether the queue is rolling `RETURN_PATROL_INTERVAL` instead of `AHEAD_INTERVAL`
## for the rest of the day. Set by `owe_the_return()` and never cleared until `start_day()`: once
## the return owes its pressure, the pacing stays tight even if the phase drops back to walking.
var _return_pacing := false
## The walk's plans, as `start_day()` was handed them (the walk's own store, which a unit's draw
## adds to as she walks): what a row the director sends ahead of her is kept clear of
## (`_clear_of_the_plans()`).
var _plans: Array[EventPlan] = []
## Where today's region-door bodies stand — a hut, a boom or an alley post. Read off the day's own
## plan in `start_day()` below, so the director needs no second channel to the region plan, and
## used by `due()` to refuse a siting whose path would run through a door's own clear ground. Empty
## on every day before `Tuning.REGION_WALL_FIRST_DAY`.
var _doors := PackedVector2Array()
## What works out the route of a row it sends ahead of her as it goes (`way_on()`), null until handed
## one or until it makes its own.
var _way_on: WayOn = null

## Today's plans that the day made and left for her walk to site —
## `EventDef.is_sited_from_her_walk()`, which is day 3's fire, and the poster crews from day 4
## — read off the same plan list `_owed` is, in `start_day()`, or handed over as a unit draws
## one as she walks (`owe_on_her_way()`); and the places a marble from her route's bag names,
## added the moment the marble is drawn (`_place_on_her_route()`). Emptied as each one is put
## in the world.
var _on_her_way: Array[EventPlan] = []
## The day's placement context, for siting one of those against the same ground, corridor, doors and
## protected calm every dawn placement was stated against. Null on a day with nothing to site, and
## on any rig that starts the director without one.
var _siting: WalkSiting = null
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

func _init(map: CityMap, navigator: Navigator = null) -> void:
	_map = map
	_navigator = navigator if navigator else Navigator.new(map)

## Takes over the day's `AHEAD_OF_PLAYER` and `TOWARD_PLAYER` plans — everything the scheduler
## owes but left for the director to site while she walks. Called with the same plan list the
## manager streams the sited events from, so the two halves of a day cannot disagree about what is
## owed.
##
## Asked over `plan.spawn_mode_on(day)` rather than `spawn_mode` alone, so a row whose siting
## changes after its own `first_day` — `charging_dog` past `Tuning.RUN_TAUGHT_DAY` — is owed to the
## director only on the days it actually answers `AHEAD_OF_PLAYER` or `TOWARD_PLAYER`. Without this
## the scheduler's dawn would place the row on a tile *and* the
## director would separately site a second one in front of her, from the one `EventDef` both read.
##
## `heat` is the shape the route bag's rows are put in (`EventCatalogue.heated()`), the same
## `RunState.resistance().progress()` the day's own placements were planned at.
##
## **`sends` is the walk's own setting of what the director may send her**
## (`DaySpec.director_sends()`), and the day's number decides nothing of it: a walk that sends none
## of an ordinary day's rows (`DaySpec.DirectorSends.NOTHING`) has no route bag, owes nothing
## from the plan and rolls no sprinkled dog and no day-one rig, whatever `day` is; one that sends
## the rows of its own plan (`SENT_AHEAD_ROWS_OF_ITS_PLAN`) owes only the sent-ahead rows its plan
## left unplaced, in a route bag of those alone. There is no
## default: a caller says what its walk sends. `wait_share` is the share of `AHEAD_INTERVAL` the
## walk
## lets pass between two handouts (`DaySpec.handout_wait_share()`).
func start_day(day: int, plans: Array[EventPlan],
		rng: RandomNumberGenerator, sends: DaySpec.DirectorSends,
		siting: WalkSiting = null, heat: int = 0, wait_share := 1.0) -> void:
	_owed.clear()
	_wait_share = wait_share
	_lesson = null
	_rng = rng
	_day = day
	_met_today.clear()
	_placed_from_the_route.clear()
	_rigged_just_ahead.clear()
	_just_ahead.clear()
	_return_patrols_left = 0
	_patrol_bag_left = 0
	_sends_the_days_rows = sends == DaySpec.DirectorSends.THE_DAYS_ROWS
	var its_trucks := sends == DaySpec.DirectorSends.SENT_AHEAD_ROWS_OF_ITS_PLAN
	var trucks: Array[EventDef] = []
	_fill_the_route_bag(day, heat, rng)
	_return_owed = false
	_return_pacing = false
	_doors.clear()
	_on_her_way.clear()
	_behind_her.clear()
	_sent_waiting.clear()
	_walked = 0.0
	_since_the_last_look = 0.0
	_siting = siting
	_plans = plans
	# The first pursuer the day owes, for day 3's lesson — see `_teach_the_run()`.
	var lesson: EventDef = null
	for plan in plans:
		# A door body is read off the same list, so "where do today's doors stand" is answered once,
		# by the plan (`EventPlan.is_door()`), rather than by a second wire from the region planner to
		# here. The huts and posts are the bodies that inspect her and the boom is the one that does
		# not; all three keep their clear ground.
		if plan.is_door() and plan.is_placed():
			_doors.append(plan.placed_at())
		# A place the day planned and left unsited, read off the same list for the same reason.
		if plan.is_sited_from_her_walk() and not plan.is_placed():
			_on_her_way.append(plan)
		if not _sends_the_days_rows:
			if its_trucks and plan.is_sent_ahead() and not plan.is_placed():
				trucks.append(plan.row())
			continue
		var mode := plan.spawn_mode_on(day)
		# A row the director sends ahead of her is owed as a moment where the dawn left it unplaced
		# (`DawnMoments`); placed, it is a place something else stood (a scene recipe's).
		if mode == EventDef.SpawnMode.AHEAD_OF_PLAYER or mode == EventDef.SpawnMode.TOWARD_PLAYER \
				or (plan.is_sent_ahead() and not plan.is_placed()):
			if plan.pursues() and not lesson:
				lesson = plan.row()
			# The dawn decides how many the route is owed; the bag decides which each one is.
			_owed.append(null if _route_rows.has(plan.row_id()) else plan.row())
	if _sends_the_days_rows:
		_owe_the_sprinkled_dog(day)
	_owe_its_trucks(trucks, heat)
	_take_the_forced_row()
	# The first one is not free: a cat on the doorstep before she has taken a step reads as the
	# game starting badly rather than as something happening.
	_next_in = _roll_interval()
	if _forced:
		return
	_teach_the_run(day, lesson)
	_rig_day_one(day, heat)

## **The sent-ahead rows a walk's own plan left for the director**
## (`DaySpec.hands_the_director()`): each is
## a marble of a route bag that holds them alone, and a slot owed, so she meets as many as the plan
## handed over, one at the director's usual pace, each sited ahead of her as a day's convoy is
## (`_routed()`). A truck is no row of the ordinary bag, so `max_per_day` caps none of them.
func _owe_its_trucks(trucks: Array[EventDef], heat: int) -> void:
	if trucks.is_empty():
		return
	var marbles := []
	for def in trucks:
		_route_rows[def.id()] = _routed(def, heat)
		marbles.append(def.id())
		_owed.append(null)
	_route = MarbleBag.new([], marbles, hash("%d:route-bag" % _rng.seed))

## The share of `AHEAD_INTERVAL` the walk lets pass between two handouts (`start_day()`'s
## `wait_share`).
var _wait_share := 1.0

## Whether today's route is the ordinary day's rows (`start_day()`'s `sends`). When it is not, the
## director's route bag holds only what the walk's plan hands it (`_owe_its_trucks()`), or nothing.
var _sends_the_days_rows := true

## How many dog walkers day one's first handouts hold (`_rig_day_one()`).
const DAY_ONE_DOG_WALKERS := 2
## Among how many of day one's first handouts they come (`_rig_day_one()`).
const DAY_ONE_DOG_WALKERS_WITHIN := 3
## The row day one's rigged bag holds (`_rig_day_one()`).
const DAY_ONE_DOG_WALKER := "dog_walker"

## **Day one's dog walkers come by construction**: two of the first three marbles drawn on her
## route are dog walkers. *(PLAYTEST-05 6: the dog-walker decision has to be made at least twice on
## day one; inbox #561 in coral-bunny, the player's own tool for a guarantee about her route, a
## rigged bag.)* The dog walker is a marble of her route's bag (`EventDef.is_sent_ahead()`), so the
## guarantee is about what she meets wherever she has a sidewalk ahead of her, and three handouts
## are at most three of `AHEAD_INTERVAL`'s longest waits of walking. One drawn where she has none
## waits for room (`_sent_waiting`) and is met after an event behind it, or never: the pace holds
## over the guarantee, the orchestrator's reading of board question sent-ahead-pace. Nothing on any
## other day, and nothing on a day whose bag holds no dog walker.
func _rig_day_one(day: int, heat: int) -> void:
	if day != 1 or not _route_rows.has(DAY_ONE_DOG_WALKER):
		return
	var ids: Array[String] = []
	for _i in DAY_ONE_DOG_WALKERS:
		ids.append(DAY_ONE_DOG_WALKER)
	rig_her_route(ids, DAY_ONE_DOG_WALKERS_WITHIN, heat)

## The row `--force <id>` names, or `null` when the flag is absent — see `DevFlags.forced_row()`
## for what the flag is for.
var _forced: EventDef
## Seconds between two forced rows, from `--force <id> [seconds]`.
var _forced_interval := 0.0
## The id and interval `force()` was handed, taken up by each `start_day()`.
var _force_id := ""
var _force_interval := 0.0

## `--force <id> [seconds]`, handed in by the manager: from the next `start_day()` on, the day's own
## owed list is replaced by that one row, every `interval` seconds. "" for the ordinary day.
func force(id: String, interval: float) -> void:
	_force_id = id
	_force_interval = interval

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
	if _force_id == "":
		return
	var def := EventCatalogue.by_id(_force_id)
	if not def:
		push_error("--force names no event in the catalogue: '%s'" % _force_id)
		return
	# A row the director sends ahead of her is forced as it sends it (`EventDef.as_sent_ahead()`).
	_forced = def.as_sent_ahead()
	_forced_interval = _force_interval
	_owed.clear()
	_owed.append(_forced)

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
## from the bag behind it), and the first of the events the dawn owes her route is the one
## drawn from it. The ordinary bag after it keeps every dog marble it was filled with
## (`ROUTE_BAG_SHARE_OF`).
##
## It is *not* a scripted event, and that is deliberate: it is one of the day's own owed
## `AHEAD_OF_PLAYER` plans, so teaching the run cannot quietly make day 3 denser than the day's
## count of moments says. If the day happened to owe none, there is nothing to teach and nothing happens.
##
## **The one it hands out is the lesson's own row** (`EventCatalogue.lesson_of()`: the charging
## dog's is `charging_dog_tutorial`), the first of `lesson`'s row `due()` hands out, so its
## GoatCounter counts are its own. A dog forced with `--force` is not the lesson: the forced day
## teaches nothing.
func _teach_the_run(day: int, lesson: EventDef) -> void:
	if day != Tuning.RUN_TAUGHT_DAY or not lesson:
		return
	if _route_rows.has(lesson.id()):
		if not _owed.has(null):
			return
		_route.rig([lesson.id()], 1)
		_bag_the_next(1)
	else:
		var at := _owed.find(lesson)
		if at < 0:
			return
		_owed.remove_at(at)
		_owed.push_front(lesson)
	_next_in = LESSON_DELAY
	_lesson = lesson

## The row `_teach_the_run()` put first today, until `due()` has handed it out as the lesson's own
## row; null on every other day and after.
var _lesson: EventDef = null

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
## `EventDef.notice_within()` still its authored 0.0 — so nothing here has to build a copy the way
## `EventDef.for_day()` does for the waiting one: a director-sited dog is met exactly as
## day 3's is, charging the moment it streams in, because both are already-noticing encounters
## rather than places she is routed into. No tip and no guarantee are the whole of what changes —
## `_teach_the_run()` owns the guarantee and the delay that make day 3 a lesson, and neither runs
## here.
##
## **Rolled once a day, outside the scheduler's own count of moments** — the same shape `owe_the_return()`
## already is: a rare encounter added to the queue rather than competing with cafés and roadworks
## for it, because a lesson-sized moment that only happens when the density dice agree is not one a
## player can point to. `CHARGING_DOG_SPRINKLE_CHANCE` is the rate, set against
## `tests/probes/m96_dog_sprinkle.gd` — see that constant for what was measured and chosen.
##
## **Put at the front, not the back.** `tests/probes/m99_caps.gd` already measured that a busy
## day's own `AHEAD_OF_PLAYER` pool is oversubscribed by design — `cat_dash`, `cyclist` and
## `loose_dog` between them queue dozens a day and the pacing (`AHEAD_INTERVAL`) only ever
## drains a handful before the day ends — so an item *appended* here would sit behind all of that
## and the roll below would almost never actually meet her. This is not a second chance at that same
## count: the roll already made it rare, and stacking a second rare event on top of "reached before
## the day runs out" would make it rarer still, unmeasurably so, exactly like `_teach_the_run()`
## moving the day-3 lesson to the front rather than leaving it wherever the pool happened to place
## it. Pushing to the front only decides which of today's `AHEAD_OF_PLAYER` encounters is met
## *first* when one has been rolled at all; it never adds a second roll on top of the first.
##
## Asked over the def's own `EventDef.spawn_mode_on()` rather than `Tuning.RUN_TAUGHT_DAY`
## directly, so this stays in step with whichever day the row's siting actually changes on.
func _owe_the_sprinkled_dog(day: int) -> void:
	var dog := EventCatalogue.by_id("charging_dog")
	if not dog or not dog.is_past_its_switch_on(day):
		return
	if _rng.randf() < CHARGING_DOG_SPRINKLE_CHANCE:
		_owed.push_front(dog)

## How many events she is still owed today: the queue's, and the rows sent ahead of her whose
## marbles were drawn while she had no room for them (`_sent_waiting`), which are still to come.
func owed() -> int:
	return _owed.size() + _sent_waiting.size()

# ------------------------------------------------------------ the route's bag ---

## Fills `_route` with every row the director sites on `day` — recurring, available, and
## `AHEAD_OF_PLAYER` or `TOWARD_PLAYER` that day, or sent ahead of her (`EventDef.is_sent_ahead()`)
## — in proportion to its weight. **How many she is owed
## is the day's** (`PlacementDensity.moments_on()`, each drawn by weight under its cap by
## `DawnMoments`); the bag only decides which row each of those is, in the
## order she meets them. *(2026-09-27, asked how far the bags reach, the
## player chose the route's events only.)*
func _fill_the_route_bag(day: int, heat: int, rng: RandomNumberGenerator) -> void:
	_route_rows.clear()
	_ordinary_rows.clear()
	if not _sends_the_days_rows:
		_route = null
		return
	for def in _route_rows_on(day, heat):
		_route_rows[def.id()] = def
		_ordinary_rows[def.id()] = true
	_route = MarbleBag.new([], ordinary_route_marbles(day, heat), hash("%d:route-bag" % rng.seed))

## The rows the director sites on `day` — recurring, available, and `AHEAD_OF_PLAYER` or
## `TOWARD_PLAYER` that day, or sent ahead of her (`EventDef.is_sent_ahead()`, as the copy it sends,
## `EventDef.as_sent_ahead()`) — at `heat`, in the catalogue's own order.
static func _route_rows_on(day: int, heat: int) -> Array[EventDef]:
	var rows: Array[EventDef] = []
	for def in EventCatalogue.of_kind(GameEnums.EventKind.RECURRING, day, heat):
		var mode := def.spawn_mode_on(day)
		if def.is_sent_ahead():
			rows.append(def.as_sent_ahead())
		elif mode == EventDef.SpawnMode.AHEAD_OF_PLAYER or mode == EventDef.SpawnMode.TOWARD_PLAYER:
			rows.append(def)
	return rows

## The marbles of `day`'s ordinary route bag: each of `_route_rows_on()` in proportion to its weight
## (`ROUTE_BAG_MARBLES_PER_WEIGHT`). A row `ROUTE_BAG_SHARE_OF` names comes as often as its share
## says rather than as its weight says (the weight is the dawn roll's too, on every day): the whole
## marbles nearest that share of the bag the other rows make with it, at least one.
static func ordinary_route_marbles(day: int, heat: int) -> Array:
	var weights := {}
	var other_weights := {}
	for def in _route_rows_on(day, heat):
		weights[def.id()] = def.drawn_as_often()
		if not ROUTE_BAG_SHARE_OF.has(def.id()):
			other_weights[def.id()] = def.drawn_as_often()
	var others := MarbleBag.in_proportion(other_weights, ROUTE_BAG_MARBLES_PER_WEIGHT).size()
	var counts := {}
	for id: String in ROUTE_BAG_SHARE_OF:
		if weights.has(id):
			var share: float = ROUTE_BAG_SHARE_OF[id]
			counts[id] = maxi(1, roundi(others * share / (1.0 - share)))
	return MarbleBag.in_proportion(weights, ROUTE_BAG_MARBLES_PER_WEIGHT, counts)

## **A scene's route, from the bag its recipe rigs** (`setup.route_bag`, `docs/SCENE_RECIPES.md`).
## *(polite-dolphin, inbox #555: "the events should still spawn using the same rules but the marble
## bag should be rigged".)* Called after `start_day()`, which a scene runs with no plans of the
## day's own: what she is owed on her route becomes `owed` marbles of a bag holding `marbles`, with
## `pre_bag` drawn from first when it holds any, and everything after that is the director's own —
## the pacing, the siting ahead of her or down her line, the doors, a row's `max_per_day` over the
## ordinary bag's rows, and a rig a task asks for later (`rig_her_route()`). `first_after` is the
## seconds of walking before the first is due, or a negative number for the ordinary roll
## (`AHEAD_INTERVAL`): a scene is a minute rather than a day, the same reason day 3's lesson
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
			_route_rows[id] = _routed(EventCatalogue.by_id(id), heat)
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
## (`MarbleBag.rig()`). A row that is not one the director sites — a mast, a place — is handed to
## her walk to site ahead of her when its marble comes up
## (`_place_on_her_route()`), and waits there for a legal site without holding up the events behind
## it. Answers the rigged bag's marbles, or nothing under `--force`, whose queue is the forced row's
## alone, and on a rig with no day.
##
## **The next `size` events she is owed are the rigged bag's**, so the guarantee is about what is
## handed out on her route and not about the bag alone: they are moved to the head of the owed list,
## ahead of a sprinkled dog not yet met, and the list is topped up when the day has fewer left. For a
## moment that is what she meets; for a place it is its marble, and the place is met once her walk
## finds it a site, which can be after an event behind it, or never.
## `siting` is the day's placement context, for a place; `heat` the shape its row is put in. A place
## whose id is among `ids` is laid on her path just ahead of her, out of her view
## (`WalkSiting.lay_just_ahead()`), where `just_ahead`, and past the streaming band otherwise
## (`WalkSiting.lay_ahead()`).
func rig_her_route(ids: Array[String], size: int, heat: int = 0,
		siting: WalkSiting = null, just_ahead := false) -> Array:
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
			_route_rows[id] = _routed(def, heat)
		ensured.append(id)
		if just_ahead:
			_rigged_just_ahead[id] = true
	_route.rig(ensured, size)
	var rigged := _route.bag_in_front()
	_bag_the_next(rigged.size())
	return rigged

## Today's row a marble names, or null — what a caller rigging her route prepares the siting for.
func route_row(id: String) -> EventDef:
	return _route_rows.get(id)

## **Today's copy of `def` at `heat` as her route's bag hands it out**: the copy the director sends
## (`EventDef.as_sent_ahead()`) for a row it sends ahead of her, otherwise the heated row, with
## ground offered where it is a place whose row names none (`_with_ground()`).
static func _routed(def: EventDef, heat: int) -> EventDef:
	var heated := EventCatalogue.heated(def, heat)
	return heated.as_sent_ahead() if heated.is_sent_ahead() else _with_ground(heated)

## A place whose own row names no ground — a loudspeaker mast, whose sites are the city's
## (`MastSites`) — is offered the sidewalk and the square when a marble puts it on her route, the
## ground `ResistanceDirector._add_a_mast_near()` offers a mast near a mark, and on it only what a
## mast site may be (`MastSites.is_eligible()`, asked by `SitedGround`). A copy, never
## the shared heated row every dawn placement of it reads (`EventCatalogue.heated()`).
static func _with_ground(def: EventDef) -> EventDef:
	if not def.ground_kinds().is_empty() or not def.is_placed_on_the_map():
		return def
	var draft := def.redraft()
	draft.ground([GameEnums.TileType.SIDEWALK, GameEnums.TileType.SQUARE])
	return draft.build()

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
		if def and (not _ordinary_rows.has(id) or int(_met_today.get(id, 0)) < def.most_in_a_day()):
			return def
		_route.draw()
		_handed_from_the_route()
	return null

## How many marbles in a row `_next_on_the_route()` may spend on rows that have had their day before
## it gives up: more than a whole bag, so it only stops on a bag whose every row is spent.
const ROUTE_SKIP_LIMIT := 64

## A marble that names a place rather than a moment — the mast day 11's rigged bag puts on her
## route — is handed out the moment it is drawn, like any other marble: its owed slot and the marble
## are spent, and the place goes on the list of what her walk sites (`site_what_is_on_her_way()`),
## unplaced, the way day 3's fire waits there. That half sites it on its own cadence: on the nearest
## free location of the branch of the day's route tree she is walking, past the streaming band
## (`WalkSiting.lay_ahead()`), or, for a row its rig asked laid just ahead (day 6's man shouting, day 7's
## van; `rig_her_route()`), just ahead of her and out of her view (`WalkSiting.lay_just_ahead()`), in a
## unit that has not drawn where her way has one (`WalkSiting`), through every acceptance rule a
## dawn placement is under, so it is never seen to appear, it is reachable on the route she is
## walking, and it is in the world once she walks on; and it re-sites it ahead of her if she turns
## away before it has been.
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
	_met_today[def.id()] = int(_met_today.get(def.id(), 0)) + 1
	var waiting := EventPlan.new(def, Vector2.INF)
	_on_her_way.append(waiting)
	_placed_from_the_route[waiting] = true
	if _rigged_just_ahead.has(def.id()):
		_just_ahead[waiting] = true

## Whether `plan` is a place a marble from her route's bag put on her way (`_place_on_her_route()`),
## which joins the day's plan when it is first sited rather than at dawn.
func is_from_her_route(plan: EventPlan) -> bool:
	return _placed_from_the_route.has(plan)

## **A row a unit drew as she walks and handed to her walk** (`plan`, unplaced: the sidewalk poster
## crew), owed to her walk as one the dawn left is (`start_day()` reads those off the day's plan),
## sited on her way like any other (`site_what_is_on_her_way()`). `siting` is the day's placement
## context, taken where the day had none, since a day with nothing left for her walk at its start
## was started without one.
func owe_on_her_way(plan: EventPlan, siting: WalkSiting) -> void:
	_on_her_way.append(plan)
	if not _siting:
		_siting = siting

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
## **It is the coarse half of the question and `WalkSiting` answers the fine half.**
## A fire on the fork she did not take is a few degrees off square and passes this test for ever;
## what moves it is that it is no longer on the branch she is walking. See
## `_is_no_longer_on_her_way()`.
const ON_HER_WAY_BEHIND := -0.5

## How often the walk is looked at, in seconds of walking — one cadence for both halves of the
## question, because both are asked of the same walk and neither is worth a frame's answer.
##
## A refusal is ordinary — there is no tile of the row's own ground on the branch ahead of her, or
## the one there is stands in a door's clear ground or breaks another of the day's rules — and the
## answer is to ask again a street later rather than to place it somewhere illegal. A placement
## already made is asked on the same beat whether the walk has left it behind, which is a walk of
## the route tree rather than a dot product and does not belong in a physics frame: a refused
## attempt scans her branch and judges a candidate on the tiles of up to `WalkSiting.LOCATIONS_A_LOOK`
## locations, and doing that sixty times a second while she walks into a corner is the one hitch on
## the beat of the day she is meant to be watching.
const ON_HER_WAY_LOOK := 1.0

## Sites, or re-sites, whatever the day planned and left for her walk to place: a tile of the row's
## own ground (a building face for the fire and the crews) on the day's own route tree **on the
## branch she is walking**, in the nearest free location of it beyond the streaming band, a unit's
## that has not drawn where there is one (`WalkSiting.lay_ahead()`), off screen; and a place a rig
## asked laid just ahead (`rig_her_route()`) on her path just ahead of her instead, straight ahead and
## just out of her view (`WalkSiting.lay_just_ahead()`). Returns every plan
## this call moved, so the caller can give back the ground the old body was standing on and take the
## new — `EventsAhead.site_what_is_on_her_way()` is that caller — and a place from her route's bag
## sited for the first time, which the caller adds to the day's plan (`is_from_her_route()`).
##
## **The path is the day's route tree and nothing else is a site.** *(PLAYTEST-119: "the fire needs
## to spawn on the current path the player is on — moving it around works but valid spawn locations
## are only on the path".)* `WalkSiting` carries the geometry; what this half owns is *when* it is
## asked and *which* plan is asked about.
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
## recorded its scar and moved its block along its arc (`EventSpawner.create`), so the city already
## remembers it burning there; moving it then would mean repairing a fact, which is the one thing
## this repository does not do to a guarantee. `EventPlan.has_been_in_the_world()` is that line, and it
## is drawn at the streaming radius rather than at the screen edge — which is 900px out against a view half
## diagonal of about 367, so in practice it stops moving a good six seconds of walking before she
## could ever have seen it.
##
## **Nothing is moved to satisfy the guarantee, and nothing is ever sited off the path.** When the
## branch ahead of her offers no legal tile of the row's own ground — she has stepped off the tree
## through a thinned seal or into an alley, the window holds none of that ground (no building
## frontage, for the fire and the crews), or a candidate stands in a door's clear ground — this answers with nothing and asks again a second later, from
## wherever she has got to. A day she walks into a corner is a day it waits.
##
## **And a beat goes first in a unit that has not drawn.** The siting offers the locations of the
## nearest unit on her way that has not drawn before those a drawn unit left empty, and the unit
## draws round the beat (`WalkSiting.lay_ahead()`, `UnitDraw`).
func site_what_is_on_her_way(delta: float, at: Vector2,
		velocity: Vector2) -> Array[EventPlan]:
	var moved: Array[EventPlan] = []
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
	# One look reads one way ahead for every copy it asks about (`WalkSiting.begin_look()`). A
	# placed plan is asked about without its own body, which every other ask counts, and the siting
	# does that itself.
	_siting.begin_look(at, heading)
	for plan in _on_her_way:
		if plan.is_placed() and not _is_no_longer_on_her_way(plan, at, heading, elapsed):
			continue
		if not plan.is_placed() and _waits_its_turn(plan):
			continue
		var laid := _siting.lay_just_ahead(plan) if _just_ahead.has(plan) \
				else _siting.lay_ahead(plan)
		if not laid:
			continue
		_behind_her[plan] = 0.0
		moved.append(plan)
	_siting.end_look()
	return moved

## **A recurring row is sited on her way one at a time**: the next of the day's crews waits while
## another is sited ahead of her and not yet in the world. All of them at once would put the day's
## crews on the one stretch of street the nearest free locations cover; one at a time, each is met on its own and
## the next is sited as the last comes into reach, so they are spread along the day's walk.
func _waits_its_turn(plan: EventPlan) -> bool:
	if plan.is_a_one_shot():
		return false
	for other in _on_her_way:
		if other != plan and other.is_the_same_row_as(plan) and other.is_placed():
			return true
	return false

## Drops from the list anything that is already real or already spent, so the loop above only ever
## considers a plan that can still legally be moved.
func _forget_what_is_real() -> void:
	var still_ours: Array[EventPlan] = []
	for plan in _on_her_way:
		if plan.has_been_in_the_world() or plan.is_spent():
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
func _is_no_longer_on_her_way(plan: EventPlan, at: Vector2, heading: Vector2,
		elapsed: float) -> bool:
	var toward := plan.placed_at() - at
	var still_ahead := toward.length_squared() < 1.0 \
			or (toward.normalized().dot(heading) > ON_HER_WAY_BEHIND
			and _siting.still_ahead_of(at, heading, plan.placed_at()))
	if still_ahead:
		_behind_her[plan] = 0.0
		return false
	var behind: float = float(_behind_her.get(plan, 0.0)) + elapsed
	_behind_her[plan] = behind
	return behind >= ON_HER_WAY_TURNED_AWAY

## Hands the day's return leg its own pressure — `docs/TODO.md`'s M98, pressure in the empty acts
## — the moment `EventManager` hears `EventBus.return_phase_started`. `Tuning.RETURN_PATROLS_PER_
## ACT[act - 1]` patrols are owed on top of the day's own events, each rigged into the route's bag
## in turn (`_rig_the_next_patrol()`): the patrol the director sends ahead of her
## (`EventDef.as_sent_ahead()`, at the day's own heat, a row of the bag from its first day), sited
## down her own carriageway rather than crossed — see `_toward_her_on_the_road()` — and the interval the queue rolls for the rest of the day switches
## from `AHEAD_INTERVAL` to the tighter `RETURN_PATROL_INTERVAL`, so the extra rows
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
	var count: int = RETURN_PATROLS_PER_ACT[act - 1]
	if count <= 0:
		return
	# A scene's route holds only the rows its recipe names, so the patrol joins it here.
	if not _route_rows.has(RETURN_PATROL):
		var cold := EventCatalogue.by_id(RETURN_PATROL)
		if not cold:
			push_error("no '%s' row in the catalogue" % RETURN_PATROL)
			return
		_route_rows[RETURN_PATROL] = _routed(cold, heat)
	# One more event owed for each patrol, as the patrols were always on top of what the day owes;
	# each is the ensured marble of a rigged bag, rigged as the one before it is handed out.
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

## **Each return patrol is a rigged bag** of `RETURN_PATROL_WITHIN_THE_NEXT` marbles, the
## patrol and the rest drawn from the bag she was drawing from, and the next is rigged once that bag
## has been handed out — so each marble comes within its own bag's events, and two are drawn back
## to back only where the second bag starts with what the first ended on. A patrol with no room
## waits for it (`_sent_waiting`) and is sent on a later turn that has room, so two can still be
## met on two turns running: two that waited, or one that waited and the next as it is drawn.
## *(inbox #561 in coral-bunny: "The return patrols in acts III and IV are added at the back of
## the route queue -- the marble bag approach will properly fix this" · "they will need rigged
## bags".)* Behind the day's own events, the dozens the dawn owes and the pacing never drains, they
## would never come; rigged, each one comes within that many events of the last.
func _rig_the_next_patrol() -> void:
	if _return_patrols_left <= 0 or not _route:
		return
	_return_patrols_left -= 1
	_route.rig([RETURN_PATROL], RETURN_PATROL_WITHIN_THE_NEXT)
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

## Advances the clock and returns the event to place plus the path to place it on, or null when
## nothing is due. `heading` is the direction she is actually travelling, not the way she is
## facing: something that crosses in front of a player standing still is not in front of
## anything.
##
## Returns `[EventDef, PackedVector2Array, float, Variant]`: the row, the path to place it on, the
## seconds it crouches beyond its telegraph (`EventDef.crouch_for_a_run()`, zero for anything but a
## cut crossing), and the point on her line the run was sited to cross (a `Vector2`, or `null` for a
## `TOWARD_PLAYER` row, which has no crossing), or an empty array. A place the route's bag names is
## handed to her walk to site (`_place_on_her_route()`) and answers the empty array: it joins the
## day's plan through `site_what_is_on_her_way()` once it has a site. A row sent ahead of her that
## found no room is answered here on a later turn of the clock that finds it some, ahead of the next
## marble (`_send_what_waited()`). `view` is the camera's whole
## view (`VisibleView`), which a row sent down a lane of the road is sited out of; null for a camera
## on her.
func due(delta: float, at: Vector2, velocity: Vector2, view: VisibleView = null) -> Array:
	if _owed.is_empty() and _sent_waiting.is_empty():
		return []
	var speed := velocity.length()
	# The clock only runs while she is going somewhere. A player who stops to let the meter
	# recover is not owed a cat for waiting, and one who spends the day in a park should not
	# come back to the pavement and be handed four of them at once: nothing is sent but on the
	# clock's turn, what waited for room included (`_send_what_waited()`).
	if speed < Tuning.AHEAD_MIN_SPEED:
		return []
	var heading := velocity / speed
	_next_in -= delta
	if _next_in > 0.0:
		return []
	var waited := _send_what_waited(at, heading, view)
	if not waited.is_empty():
		return waited
	if _owed.is_empty():
		# Only rows that wait for room are owed, and none has any: asked again shortly, on this
		# same turn of the clock.
		_next_in = SENT_RETRY
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
	if from_the_bag and next.spawn_mode_on(_day) == EventDef.SpawnMode.MAP \
			and not next.is_sent_ahead():
		_place_on_her_route(next)
		return []
	var sited := _sited(next, at, heading, view)
	var path: PackedVector2Array = sited[0]
	if path.is_empty():
		# **A marble of her route sent ahead of her that has no room never holds the route**: its
		# slot and its marble are spent, and it waits for room (`_send_what_waited()`), as a place
		# a marble names waits for its site. *(calm-pelican-6: a marble that cannot be sited never
		# blocks the route.)* **Nor does it spend the turn**: nothing was sent, so the turn is asked
		# again a second later, of the next marble, as a turn whose row found no room otherwise
		# is. Rolled as a wait, every row that waited would cost her a thing met on her walk.
		if from_the_bag and next.is_sent_ahead():
			_hand_out(next, true)
			_sent_waiting.append(next)
			_next_in = SENT_RETRY
			return []
		# Nowhere to put it — she is in the middle of a park, or against the map edge. Try
		# again shortly rather than burning the allowance on a place that would not read.
		_next_in = 1.0
		return []
	var handed := _hand_out(next, from_the_bag)
	# Refilled rather than seeded with a hundred copies, so the queue length stays honest and
	# `owed()` — which the HUD reads — says "one more coming" rather than a number that means
	# nothing under this flag.
	if _forced and _owed.is_empty():
		_owed.append(_forced)
	return [handed, path, sited[1], sited[2]]

## **How soon a turn of the clock that sent nothing is asked again**: a second of her walking, the
## cadence every siting that waits for ground is asked again on. A turn sends nothing where only rows
## waiting for room are owed (`_sent_waiting`) and none has any, or where the marble it drew is a row
## sent ahead of her with no room, which then waits; the turn goes to the next marble a second later.
const SENT_RETRY := 1.0

## The rows sent ahead of her whose marbles were drawn while she had no room for them (no
## carriageway beside her, no sidewalk ahead, a placed plan's room in the way), in the order they
## were drawn: their slots and marbles spent, each sent on a later turn of the clock that finds it
## room (`_send_what_waited()`). Emptied by `start_day()`.
var _sent_waiting: Array[EventDef] = []

## **What waited for room takes the clock's turn** (`due()`, once its wait is over): the first row of
## `_sent_waiting` that has room now, asked in the order they were drawn, answered as `due()` answers
## and the next wait rolled; the empty array where none has, and the turn goes to the next marble.
## *(inbox #1460 in silky-lemur, board question sent-ahead-pace: the three come in place of what the director sends,
## at its unchanged clock.)* Its slot was spent when it was drawn, so it takes a turn and no marble:
## nothing is sent closer to the last than the clock allows, whatever waited, and a walk off the
## streets for a minute ends in what waited coming one a turn, not in a burst.
func _send_what_waited(at: Vector2, heading: Vector2, view: VisibleView) -> Array:
	for i in _sent_waiting.size():
		var sited := _sited(_sent_waiting[i], at, heading, view)
		if not (sited[0] as PackedVector2Array).is_empty():
			var waited := _sent_waiting[i]
			_sent_waiting.remove_at(i)
			_next_in = _roll_interval()
			return [waited, sited[0], sited[1], sited[2]]
	return []

## **Where `next` goes, with her at `at` walking `heading`**: `[path, crouch, crossing point]`, the
## path empty where it has no room — see `due()` for the shape. A `TOWARD_PLAYER` row whose
## `placement` names `ROAD` is a car, not a bike — the patrol the director sends ahead of her — and
## a car belongs on the carriageway lane that drives toward her rather than on her own pavement.
## `_toward_her()` is still what every `TOWARD_PLAYER` row on foot (`cyclist`, `loose_dog`, the sent
## `dog_walker`) gets; only the road-placed ones take the road-aware sibling. A row warned of first
## in the lane beside her (the convoy) is sited there (`_in_the_lane_beside_her()`). `view` is the
## camera's whole view a row in a lane is sited out of, or null for a camera on her.
##
## **A region door keeps clear ground around itself, and a run sited in front of her is a placement
## like any other** (`clear_to_send()`). The whole path is asked, not its start: a cyclist coming
## down her own line *through* a door's gap is exactly what this refuses, and a row whose lead
## happens to clear the gap while its run does not would slip past a check on the spawn point alone.
## Refused rather than nudged, so the allowance is not burnt and the row arrives once she is past
## the door. **A row sent ahead of her keeps the spacing every placement keeps** too: nothing else
## happens inside a lethal event's field.
func _sited(next: EventDef, at: Vector2, heading: Vector2, view: VisibleView) -> Array:
	var path: PackedVector2Array
	var crouch := 0.0
	var crossing_point: Variant = null
	if next.is_warned_in_its_lane():
		path = _in_the_lane_beside_her(at, heading, next, view)
		if path.is_empty() or not clear_to_send(path, next):
			path = _down_the_street_she_comes_to(at, heading, next, view)
	elif next.comes_toward_her():
		path = _toward_her_on_the_road(at, heading, next, view) \
				if next.keeps_to_the_carriageway() \
				else _toward_her(at, heading, next)
	else:
		var crossing := _crossing_with_its_crouch(at, heading, next)
		path = crossing[0]
		crouch = crossing[1]
		crossing_point = crossing[2]
	if not path.is_empty() and not clear_to_send(path, next):
		path = PackedVector2Array()
	return [path, crouch, crossing_point]

## Spends the event at the head of the queue on `next`: its slot, and its marble when it came from
## the bag (`from_the_bag`), with today's count of the row. Answers the row handed out — the
## lesson's own row in place of the day-3 lesson's (`EventCatalogue.lesson_of()`). The next wait is
## rolled.
func _hand_out(next: EventDef, from_the_bag: bool) -> EventDef:
	_next_in = _roll_interval()
	var handed := _owed.pop_front() as EventDef
	if from_the_bag:
		handed = next
		_route.draw()
		_handed_from_the_route()
	_met_today[handed.id()] = int(_met_today.get(handed.id(), 0)) + 1
	if _lesson and handed.id() == _lesson.id():
		handed = EventCatalogue.lesson_of(handed)
		_lesson = null
	return handed

func _roll_interval() -> float:
	# Fixed rather than rolled under `--force`, and it does not touch `_rng`: the flag is for
	# looking at one row several times, and a rolled 11-26s wait between looks is the thing it
	# exists to remove. Leaving the stream alone also means a `--seed` city is bit-identical with
	# the flag on and off, so what she walks past is the same city either way.
	if _forced:
		return _forced_interval
	if _return_pacing:
		return _rng.randf_range(RETURN_PATROL_INTERVAL.x, RETURN_PATROL_INTERVAL.y)
	return _rng.randf_range(AHEAD_INTERVAL.x, AHEAD_INTERVAL.y) * _wait_share

## A run straight across her line, `AHEAD_LEAD_DISTANCE` in front of her.
##
## Perpendicular to *her* heading rather than to the street, which is the difference between a
## cat that crosses the road and a cat that crosses her path. On a pavement those are the same
## thing; walking across a square they are not, and the second one is what was asked for.
##
## Empty when the crossing point is not somewhere the row could stand — the lead lands inside a
## building, on a closure or under a body, or outside the map. The caller waits and asks again.
##
## **The run keeps to the ground the row can run on** (`Navigator.trim()`): cut each way at the
## first solid, so it never starts or ends inside a lot. **And it crouches no nearer her line than
## keeps her, walking on, outside its field until it runs** (`EventDef.nearest_crouch()`): both
## ends go to the nearer cut where that leaves so much, so the crossing point stays the middle of
## the run; where only one side does, the run comes from it and ends at the other side's solid;
## where neither does, there is no crossing and the caller asks again. Its lead is timed for a run
## of the whole reach (`EventDef.ahead_of_player_lead()`), so a start cut nearer is made up by a
## longer crouch (`EventDef.crouch_for_a_run()`, handed back with the run), and the cat still
## reaches her line when she does; a row that does not crouch is refused a cut start.
##
## **A pursuer is sited at the lead point itself and given no route.** It does not cross her line,
## it comes down it, so a path is the wrong shape for it entirely — and building one anyway puts
## the day-3 dog a street's width off to one side of the place this function has just checked,
## 266px away and diagonal, which on a 640x360 view is at the corner of the screen or past it. What
## she is owed is the sight of it coming, and it has to be sited where that can be seen — but the
## seeing is now a screen-edge badge's job for as long as the dog is off screen, not the dog's own
## silhouette, which is the overturn below.
##
## **And a pursuer is sited at least `def.warned_for()` seconds outside the view along the
## heading in play, not against a flat number sized for one axis.** *(2026-09-07: "bikers /
## unleashed dogs all pop in in front of the player instead of starting off screen", "events that go
## towards the player (biker / pursuing dog) should at least be 200ms off screen with a warning",
## and, of the day-3 dog specifically, "the run tutorial spawns inside the visible area making the
## headsup way too short now".)* A flat 200px sits inside the 320px horizontal boundary, so a dog
## sited while she walked east or west had no offscreen phase at all — it appeared already on
## screen. `Offscreen.lead()`, asked for the heading, the closing speed and `def.warned_for()`, asks the real
## question instead: how far to the edge of the view *this* heading actually reaches, plus how far
## it and she together cover in the row's own notice — for `charging_dog` at 130px/s pursuing,
## closing at 130 + `WALK_SPEED` (92) = 222px/s, `EventDef.warned_for()` of 0.5s buys 111px, sized
## against playtest 20's own measurement of how much closing an evasion needed. `WarningSpec`'s badge
## notice (`_badge_notice`) says why the dog carries a different notice than the rest of the catalogue,
## and its own `telegraphs_for()` is what pays for the longer approach.
##
## **Unavoidable, on purpose, was the day-3 dog's whole point** — a dog starting further away is a
## dog with more room to be walked around, which is exactly what siting it close was for.
## *(2026-09-07: asked for a close, unavoidable teaching dog · overturned to a further one, because
## the tap-controlled heads-up was too short at the old distance.)* So the dog moves out with
## everything else, and whatever keeps the lesson forceful now has to come from somewhere other than
## siting it too close to see coming — an open question, not one this function answers.
##
## **The site is a direction and a check, not where the pursuer is created.** `EventManager` warns
## of it first (`EventsAhead._warn_down_her_heading()`, M226): its badge is up alone for its own
## `warned_for()`, pointing down the way this site lies from her, and it is then created just out
## of sight that way on walkable ground (`PendingWarning.along_her_heading()`), its approach still to
## run. The lunge is still fired by **proximity** (`EventPursuit`).
##
## **This function only ever sites `charging_dog` on `Tuning.RUN_TAUGHT_DAY`.** Every day after,
## `EventDef.spawn_mode_on()` answers `MAP` instead of `AHEAD_OF_PLAYER` for that row, so
## `EventScheduler` places it on a tile like `alley_robbery` and `start_day()` above never adds it
## to `_owed` at all — it is not sited off her heading by this function, it is not sited by this
## function. A pursuer arriving here is always the teaching day's own dog, dead ahead on purpose,
## because the lesson depends on being unavoidable.
func crossing_ahead_of(at: Vector2, heading: Vector2,
		def: EventDef = null) -> PackedVector2Array:
	return _crossing_with_its_crouch(at, heading, def)[0]

## `crossing_ahead_of()`'s run, and how much longer than its telegraph it crouches before running
## it (`EventDef.crouch_for_a_run()`), as `[path, seconds, point]`: the crouch is the run's own, so it is
## worked out where the run is, and the point is where the run meets her line (`Vector2.ZERO` with
## an empty path).
func _crossing_with_its_crouch(at: Vector2, heading: Vector2, def: EventDef = null) -> Array:
	var none := [PackedVector2Array(), 0.0, Vector2.ZERO]
	var lead := Offscreen.lead(heading, def.chase_speed() + Tuning.WALK_SPEED,
				def.warned_for()) \
			if def and def.pursues() \
			else (def.ahead_of_player_lead() if def else Tuning.AHEAD_LEAD_DISTANCE)
	var centre := at + heading * lead
	var mover := EventInstance.mover_for(def) if def else Mover.on_foot()
	if not _navigator.passable_at(centre, mover):
		return none
	if def and def.pursues():
		return [PackedVector2Array([centre]), 0.0, centre]
	var across := Vector2(-heading.y, heading.x) * float(CROSSING_REACH_TILES * Tuning.TILE_SIZE)
	# The side it comes from is a coin flip, so a player cannot learn to watch one shoulder.
	if _rng.randf() < 0.5:
		across = -across
	var from := centre - across
	var to := centre + across
	if not _map.in_bounds(_map.world_to_tile(from)) or not _map.in_bounds(_map.world_to_tile(to)):
		return none
	# Cut each way at the first solid. A crouch nearer her line than `EventDef.nearest_crouch()`
	# would have her inside its field before it runs, so the run starts no nearer: where both cuts
	# leave that much, both ends go to the nearer cut and the crossing point stays the middle of the
	# run; where only one side does, the run comes from it and ends at the other's solid; where
	# neither does, there is no crossing and the caller asks again. A start nearer than the whole
	# reach its lead was timed for is made up by a longer crouch (`EventDef.crouch_for_a_run()`),
	# and a row with no crouch to hold is refused a cut start, since it would reach her line before
	# she does.
	var way := across.normalized()
	var back := _navigator.trim(PackedVector2Array([centre, from]), mover)
	var on := _navigator.trim(PackedVector2Array([centre, to]), mover)
	var behind := centre.distance_to(back[back.size() - 1])
	var ahead := centre.distance_to(on[on.size() - 1])
	var nearest := maxf(def.nearest_crouch() if def else 0.0, Tuning.TILE_SIZE * 0.5)
	var start := minf(behind, ahead)
	var finish := start
	if start < nearest:
		if ahead > behind:
			way = -way
		start = maxf(behind, ahead)
		finish = minf(behind, ahead)
	if start < nearest or start + finish < Tuning.TILE_SIZE:
		return none
	if def and not def.holds_still() and start < across.length() - 0.01:
		return none
	return [PackedVector2Array([centre - way * start, centre + way * finish]),
			def.crouch_for_a_run(start) if def else 0.0, centre]

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
## The warning is the row's own `telegraphs_for()`, spent before the thing exists, so nothing about
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
	var path := _navigator.trim(PendingWarning.route_down_her_line(_map, place, at, site_heading),
			EventInstance.mover_for(def))
	if path.size() < 2 or path[0].distance_to(path[1]) < Tuning.TILE_SIZE:
		return PackedVector2Array()
	return path

## **How old a row the director sends ahead of her down her line is as it is created** (the dog
## walker, `EventDef.is_sent_ahead()`; `EventsAhead._send_down_her_line()`): its telegraph spent, at
## a point of its beat drawn on the director's stream. It is the row she would come upon, put just
## ahead of her, so the point of its bark that reaches her is as free as it is for one she walks up
## to, and a pass costs what `docs/COSTS.md` prices the row at (its pass averaged over its beat),
## however far out it is created. Fixed by where it is created, as the loose dog's beat is
## (`EventSpawner.age_when_warned()`), the price would follow the edge of the view: one figure on a
## street running north-south and another on one running east-west. One draw, made as it is created.
func age_it_is_sent_at(def: EventDef) -> float:
	return def.age_at_a_point_of_its_beat(_rng.randf())

## **Whether a row sent ahead of her on `path` stands clear of the walk's placed plans**: it starts
## no nearer than `EventScheduler.EVENT_SPACING_ANY` to any of them, and no point of its route is
## inside the field a plan keeps clear (`EventPlan.keeps_its_field_clear()`, measured as
## `EventPlan.gap_to()` against the field's reach), the rule every dawn placement keeps
## (`StreetInvalidation.room_around()`). A spent or unplaced plan is not asked.
func _clear_of_the_plans(path: PackedVector2Array, def: EventDef) -> bool:
	var sent := EventPlan.new(def, path[0], path)
	for plan in _plans:
		if plan.is_spent() or not plan.is_placed():
			continue
		if plan.distance_from(path[0]) < EventScheduler.EVENT_SPACING_ANY:
			return false
		if plan.keeps_its_field_clear() and sent.gap_to(plan) < plan.field_reach():
			return false
	return true

## **Whether a route may be sent at her**: it stays out of the clear ground around today's region
## doors, and, for a row sent ahead of her (`EventDef.is_sent_ahead()`), keeps the room every
## placement keeps from the walk's placed plans (`_clear_of_the_plans()`). The refusal `due()` makes
## of every siting, asked again by `EventsAhead` of a row's route when the row is created, since its
## place has moved with her since it was sited.
func clear_to_send(path: PackedVector2Array, def: EventDef) -> bool:
	if not DoorClearanceRule.clear_of_the_doors(path[0], path, _doors, def.field_reach()):
		return false
	return not def.is_sent_ahead() or _clear_of_the_plans(path, def)

## **Whether a row sent ahead of her may take a further leg on `path`** (`WayOn.next_leg()`): it stays
## out of the clear ground around today's region doors and out of every field a placed plan keeps
## clear (`EventPlan.keeps_its_field_clear()`), the two halves of `clear_to_send()` that are about
## where a row goes. Not the start's `EventScheduler.EVENT_SPACING_ANY` from a placed plan: that keeps
## one thing from being created on top of another, and would refuse a dog walker its next leg past a
## cafe's tables.
func clear_to_go_on(path: PackedVector2Array, def: EventDef) -> bool:
	if not DoorClearanceRule.clear_of_the_doors(path[0], path, _doors, def.field_reach()):
		return false
	var going_on := EventPlan.new(def, path[0], path)
	for plan in _plans:
		if plan.is_spent() or not plan.is_placed():
			continue
		if plan.keeps_its_field_clear() and going_on.gap_to(plan) < plan.field_reach():
			return false
	return true

## **Hands in the walk's way on** (`WayOn`), made once a walk over its through roads
## (`EventManager`), and tells it the day's rule (`clear_to_go_on()`).
func use_way_on(handed: WayOn) -> void:
	_way_on = handed
	_way_on.use_the_days_rule(clear_to_go_on)

## **What works out the route of a row it sends ahead of her as it goes** (`WayOn`): the one handed in
## (`use_way_on()`), or, handed none, one of its own over its map as the map stands now, the way it
## takes the map's navigator where it is handed none.
func way_on() -> WayOn:
	if _way_on == null:
		use_way_on(WayOn.new(_map, _navigator, ThroughRoads.over(_map, Mover.vehicle())))
	return _way_on

## The road-aware sibling of `_toward_her()`, for a `TOWARD_PLAYER` row whose `placement` names
## `ROAD` — the `police_patrol` the director sends ahead of her (`EventDef.as_sent_ahead()`), the
## return leg's among them, a car rather than a bike.
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
## to: a park, a square, a precinct — or where its leg could not be driven or gone on from
## (`leg_in_the_lane()`).
##
## **Created at once, not warned first, and wholly out of the camera's view on its first frame.**
## *(M226 amendment 6, the player: "I don't want any pop in".)* Its place is in its lane just out of
## sight up the road (`PendingWarning.in_its_lane()`, against `view`: everything the car draws, its
## picture and its caret, outside the camera's whole view, the camera's lead included), as the
## convoy's is, and its first leg runs past her by as far (`leg_in_the_lane()`). A row on foot that
## `_toward_her()` sites goes up as a screen-edge warning before it exists
## (`EventDef.warns_before_it_exists()`); a patrol is created in the world instead, and telegraphs on
## its way in (`telegraphs_for()` 1.97s) with no badge, since 74px/s is slower than a walk and it is never
## lethal (`EventDef.at_heat()` states it for the `PRESSES` rung) — that is why
## `EventDef.announces_its_coming()` gives it no badge. Under the player's rule a thing telegraphs
## its coming only if it goes fast, comes toward her and carries a heavy penalty (PLAYTEST-145,
## statements 18-23), and a patrol is not fast; its strike in front of it on the carriageway is a
## car's, warned the way a car warns (`EventDef.drives()`), not a badge from off screen.
func _toward_her_on_the_road(at: Vector2, heading: Vector2, def: EventDef,
		view: VisibleView) -> PackedVector2Array:
	var inward := _map.pavement_inward(_map.world_to_tile(at))
	if inward == Vector2i.ZERO:
		return PackedVector2Array()
	var vertical := inward.x != 0
	var along := Vector2(inward.y, inward.x)
	var component := heading.dot(along)
	if is_zero_approx(component):
		return PackedVector2Array()
	var index := CrowdLanes.corridor_at(at.x if vertical else at.y)
	if index < 0:
		return PackedVector2Array()
	# The car drives opposite her own along-corridor heading — coming down the street as she
	# walks up it — so its lane is the one `CrowdLanes.road_direction()` says legally runs that
	# way, not merely a point somewhere in the road band.
	return _down_the_lane(at, -along * signf(component), index, def, view)

## **Where a row warned of first in the lane beside her is sited** (the convoy the director sends
## ahead of her, `EventDef.is_warned_in_its_lane()`): returns its first leg, from where its badge
## points to the leg's far end, which `EventsAhead` builds again from where she is once its warning
## is over (`leg_in_the_lane()`). Day 13's column is its precedent (`ResistanceHappenings`).
##
## **The lane is the carriageway of the street she is beside**, read as `_toward_her_on_the_road()`
## reads it (`CityMap.pavement_inward()`, `CrowdLanes`). It drives toward her, against her heading
## along the street, and never from behind her ("just spawn in the car just ahead of the player",
## inbox #1460 in silky-lemur). **The place is level with her along the road and just out of sight up it**
## (`PendingWarning.in_its_lane()`, against `view`), and **the first leg runs down the lane past her
## to the far edge of the next junction box** (`leg_in_the_lane()`).
##
## Empty where there is nothing to run it down: she is not beside a plain sidewalk edge, the
## street there has no leg a car may drive and go on from (`leg_in_the_lane()`), or the end ahead of
## her has no place out of sight. The caller then asks the street she comes to
## (`_down_the_street_she_comes_to()`).
func _in_the_lane_beside_her(at: Vector2, heading: Vector2, def: EventDef,
		view: VisibleView) -> PackedVector2Array:
	var inward := _map.pavement_inward(_map.world_to_tile(at))
	if inward == Vector2i.ZERO:
		return PackedVector2Array()
	var vertical := inward.x != 0
	var index := CrowdLanes.corridor_at(at.x if vertical else at.y)
	if index < 0:
		return PackedVector2Array()
	var along := Vector2(inward.y, inward.x)
	var component := heading.dot(along)
	var going := -along * signf(component) if not is_zero_approx(component) else along
	return _down_the_lane(at, going, index, def, view)

## **Where a row warned of first in its lane is sited when the lane beside her has no room for it**
## (`_in_the_lane_beside_her()` empty, or its leg not clear to send): down the street that crosses
## hers at the next junction box ahead of her, from either end, driving toward the box. Its place is
## level with her across that street, which is the box she is walking to, and just out of sight up
## it (`PendingWarning.in_its_lane()`), and its first leg runs through the box to its far edge
## (`leg_in_the_lane()`), so it crosses her way ahead of her, warned of first and from where its
## badge
## points, as the convoy in the lane beside her comes past her. It is held to everything the lane
## beside her is held to (`_down_the_lane()`, `clear_to_send()`).
##
## Empty where she is not beside a plain sidewalk edge, is not walking along the street, or neither
## end of the street ahead has a leg a car may drive and go on from out of sight.
func _down_the_street_she_comes_to(at: Vector2, heading: Vector2, def: EventDef,
		view: VisibleView) -> PackedVector2Array:
	var inward := _map.pavement_inward(_map.world_to_tile(at))
	if inward == Vector2i.ZERO:
		return PackedVector2Array()
	var vertical := inward.x != 0
	var along := Vector2(inward.y, inward.x)
	var component := heading.dot(along)
	if is_zero_approx(component):
		return PackedVector2Array()
	var ahead := along * signf(component)
	var forward := (ahead.y if vertical else ahead.x) > 0.0
	var period := float(CityMap.period() * Tuning.TILE_SIZE)
	var box := float(Tuning.STREET_WIDTH * Tuning.TILE_SIZE)
	var her_along := at.y if vertical else at.x
	var behind := floorf(her_along / period)
	if not forward and her_along - behind * period <= box:
		behind -= 1.0
	var middle := (behind + (1.0 if forward else 0.0)) * period + box * 0.5
	var index := CrowdLanes.corridor_at(middle)
	if index < 0:
		return PackedVector2Array()
	for going: Vector2 in [Vector2(inward), -Vector2(inward)]:
		var leg := _down_the_lane(at, going, index, def, view)
		if not leg.is_empty() and clear_to_send(leg, def):
			return leg
	return PackedVector2Array()

## The first leg of `def` in the lane of corridor `index` driving `going` (a unit along the street),
## from its place just out of sight up the lane (`PendingWarning.in_its_lane()`, against `view`, the
## camera's whole view, or a camera on her where there is none), or empty
## (`leg_in_the_lane()`).
func _down_the_lane(at: Vector2, going: Vector2, index: int, def: EventDef,
		view: VisibleView) -> PackedVector2Array:
	var vertical := absf(going.y) > absf(going.x)
	var lane := CrowdLanes.lane_centre(index,
			CrowdLanes.road_lane(vertical, going.y if vertical else going.x))
	var lane_point := Vector2(lane, at.y) if vertical else Vector2(at.x, lane)
	var ends := PendingWarning.lane_ends(_map, going)
	var place := PendingWarning.in_its_lane(def, at, lane_point, going, ends.x, ends.y, view)
	if place == Vector2.INF:
		return PackedVector2Array()
	if def.is_warned_in_its_lane() and not _holds_while_its_badge_is_up(def, place, at, going):
		return PackedVector2Array()
	return leg_in_the_lane(def, place, at, going)

## **Whether a row warned of first in its lane could be created from wherever the camera is once its
## badge has been up**: the thing is created just out of sight of where the camera is then
## (`EventsAhead._warn_in_its_lane()`), a place that has moved along the road with her by up to
## `RUN_SPEED` times `warned_for()`, and a tile for the camera's own lead. Its place and its leg
## are asked every half tile of that stretch either way; a break in the carriageway, a leg a car may
## not drive or go on from, or a placed plan's room across it refuses the row, which waits for
## room. A badge is never raised for a thing that cannot come: "a badge shouldn't disappear before
## the entity is visible" (minty-dolphin #852).
func _holds_while_its_badge_is_up(def: EventDef, place: Vector2, at: Vector2,
		going: Vector2) -> bool:
	var reach := Tuning.RUN_SPEED * def.warned_for() + Tuning.TILE_SIZE
	var shift := -reach
	while shift <= reach:
		var by := going * shift
		var leg := leg_in_the_lane(def, place + by, at + by, going)
		if leg.is_empty() or not clear_to_send(leg, def):
			return false
		shift += Tuning.TILE_SIZE * 0.5
	return true

## **The first leg of a row sent down a lane of the road beside her** (the patrol and the convoy the
## director sends ahead of her), from `place` in the lane driving `going` (a unit along the road),
## with her at `her`: the one place the leg is built, asked as the row is sited (`due()`) and again
## as a row warned of first is created a second later (`EventsAhead`), from where she is then.
##
## **It runs down the lane past her**: a row warned of first in its lane (the convoy, 120px/s) to the
## far edge of the next junction box (`past_the_next_box()`), one created at once (the patrol, slower
## than her walk) past her by as far as its place is up the road from her.
##
## **Nothing is sent on a leg it could not go on from.** The leg is sent only where the day's
## `WayOn` says a car may drive it (`WayOn.drives_clear()`: carriageway every half tile, no
## precinct's paving and no street a calm zone absorbed, and nothing on it that stops the row) and
## gives it a next leg from its end (`WayOn.next_leg()`). Once it exists its route is worked out as it
## goes and it leaves by legs of the same (`EventInstance.go_on_by()`), so it keeps to carriageway for
## as long as she can see it, whichever way she walks.
##
## Empty where any of that fails, and the row waits for room as any sent row does. What it must keep
## clear of is `clear_to_send()`'s, asked of the leg it answers.
func leg_in_the_lane(def: EventDef, place: Vector2, her: Vector2,
		going: Vector2) -> PackedVector2Array:
	var vertical := absf(going.y) > absf(going.x)
	var level := Vector2(place.x, her.y) if vertical else Vector2(her.x, place.y)
	var ends := PendingWarning.lane_ends(_map, going)
	var far := past_the_next_box(level, going, ends) if def.is_warned_in_its_lane() \
			else _past_her_by(level, going, place.distance_to(level), ends)
	if (far - level).dot(going) < 0.0:
		return PackedVector2Array()
	var leg := PackedVector2Array([place, far])
	var way := way_on()
	if not way.drives_clear(def, leg) or way.next_leg(def, far, going, her).is_empty():
		return PackedVector2Array()
	return leg

## The point `by` down a lane from `level` driving `going`, held between `ends` (the lane's ends on
## the map, `PendingWarning.lane_ends()`).
static func _past_her_by(level: Vector2, going: Vector2, by: float, ends: Vector2) -> Vector2:
	var far := level + going * by
	if absf(going.y) > absf(going.x):
		far.y = clampf(far.y, ends.x, ends.y)
	else:
		far.x = clampf(far.x, ends.x, ends.y)
	return far

## **The far edge of the next junction box down a lane** from `level` (a point of the lane level
## with her), driving `going`: the box she stands beside or the first one ahead of her, the
## corridors crossing the street every `CityMap.period()` tiles, held between `ends` (the lane's
## ends on the map, `PendingWarning.lane_ends()`).
static func past_the_next_box(level: Vector2, going: Vector2, ends: Vector2) -> Vector2:
	var vertical := absf(going.y) > absf(going.x)
	var at := level.y if vertical else level.x
	var period := float(CityMap.period() * Tuning.TILE_SIZE)
	var box := float(Tuning.STREET_WIDTH * Tuning.TILE_SIZE)
	var far: float
	if (going.y if vertical else going.x) > 0.0:
		far = floorf((at - box) / period + 1.0) * period + box
	else:
		far = ceilf(at / period - 1.0) * period
	far = clampf(far, ends.x, ends.y)
	return Vector2(level.x, far) if vertical else Vector2(far, level.y)

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
