class_name M207Lead
extends RefCounted
## Measurement probe for M207, "a warning comes shortly before its danger": for every row whose
## warning is spent on an approach she can answer, how many seconds pass **from the first warning
## she can see to the earliest moment the thing can reach her**, for the three answers she can
## give the instant she sees it — keep walking into it, stop, or turn round and walk away — against
## the floor the row's own fairness contract sets (`EventDef.minimum_telegraph()`:
## `Tuning.required_telegraph_time()` for an ordinary row, `Tuning.PURSUIT_MIN_NOTICE` for a
## pursuer). Not a suite: it prints a table rather than asserting one, so it lives under
## `tests/probes/`, where the runner never discovers it, and runs only by name:
##
##     tools/test.sh probes/m207_warning_lead.gd
##
## PLAYTEST-140: *"12.9s is a *long* warning to the point where nothing really happens anymore. I
## feel the same with the biker. it gets warned too early so most of the time you're already gone
## when anything happens."*
##
## **The rig.** A real `EventInstance` of the catalogue's own def, never added to a tree, placed
## the way the game places it — where `EventDirector` sites a row that is sited, where a waiting
## row stands for one that waits for her — and ticked at 60Hz beside her, with `player_at` told to
## it every frame the way `EventManager` does. Open ground, no map: a straight street with nothing
## in it, so nothing but the row's own siting and speed decides the numbers.
##
## **The first warning** is the first frame, once the row's own telegraph has started (for a row
## that waits, once it has noticed her), at which either the thing itself is inside the view — the
## `Tuning.VIEW_HALF_EXTENT` box about her, the camera being centred on her — or `DangerEdge` would
## have its badge up: its own `_is_worth_an_arrow()`, its own smoothed approach and
## `DangerEdge.announces()`, and its own `SCREEN_MARGIN` hysteresis, all called rather than copied.
## **The earliest reach** is the first frame `EventInstance.is_lethal_at()` is true for a
## `hard_fail` row, and for any other row the first frame after its telegraph that its field
## charges her anything at all (`contribution_at()` above zero at full strength) — the moment the
## thing it was warning about is actually happening to her.
##
## **Her answer is instant.** She walks into it at `Tuning.WALK_SPEED` until the first warning (the
## director only sites a row while she is walking, and a waiting row is only noticed by walking up
## to it), then on the same frame either keeps walking, stops dead, or walks the other way at the
## same speed — no acceleration, so an answer is priced at its best case. "Never" means the row
## left, finished, or ran out its path without once reaching her inside `LIMIT`.
##
## **What is not in this table, and why.** A `MAP` row that stands still — a café, a reversing
## lorry, a loudspeaker — spends its telegraph when it is streamed in, far off screen, and is then
## a place she walks up to: its warning is the sight of it, for as long as her own walk takes, and
## no number of the row's decides that. The same is true of a slow mover (a dog walker, the
## ordinary daytime `police_patrol`), which `DangerEdge` never announces because it can be walked
## away from.

const STEP := 1.0 / 60.0
## Long enough for the slowest approach in the table to arrive, and short enough that "never" means
## never rather than eventually.
const LIMIT := 30.0
## `DangerEdge` measures in design-space screen px over a 1280x720 viewport at the camera's zoom 2,
## so a screen margin is half as many world px.
const ZOOM := 2.0

enum Answer { TOWARD, STAND, AWAY }
const ANSWERS := [Answer.TOWARD, Answer.STAND, Answer.AWAY]

func run(t) -> void:
	var edge := DangerEdge.new()
	print("\n== M207: seconds from the first warning to the earliest reach ==")
	print("| row | how it is met | walking toward | standing | walking away | floor | "
			+ "over the floor (toward / standing / away) |")
	print("|---|---|---|---|---|---|---|")
	for encounter in encounters():
		var cells: Array[String] = []
		var overs: Array[String] = []
		var floor_s: float = encounter["def"].minimum_telegraph()
		for answer: Answer in ANSWERS:
			var result := measure(encounter, answer, edge)
			cells.append(_cell(result))
			overs.append("never" if result["lead"] == INF else "%+.2f" % (result["lead"] - floor_s))
		print("| `%s` | %s | %s | %s | %s | %.2f | %s |" % [encounter["def"].id, encounter["how"],
				cells[0], cells[1], cells[2], floor_s, " / ".join(overs)])
	edge.free()
	t.check(true, "zz_m207 warning lead probe ran")

static func _cell(result: Dictionary) -> String:
	if result["warned_at"] == INF:
		return "never warned"
	if result["lead"] == INF:
		return "never (%s)" % result["why"]
	return "%.2f" % result["lead"]

## Every encounter the table reports, in catalogue order: `{def, how, spawn, path, her, heading,
## warm}`. `her` and `heading` are where she starts and the way she is walking when it begins;
## `warm` is how long the instance lives before she arrives (a `MAP` mover's telegraph is spent when
## it streams in, before she is anywhere near it).
static func encounters() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	var up := Vector2.UP
	var right := Vector2.RIGHT

	# `cat_dash`: `EventDirector._crossing_ahead_of()` — across her line, `ahead_of_player_lead()` in
	# front of her, from one side `CROSSING_REACH_TILES` away.
	var cat := EventCatalogue.by_id("cat_dash")
	for heading: Vector2 in [up, right]:
		var centre := heading * cat.ahead_of_player_lead()
		var across := Vector2(-heading.y, heading.x) \
				* float(EventDirector.CROSSING_REACH_TILES * Tuning.TILE_SIZE)
		list.append({"def": cat, "how": "director, across her line, %s" % _axis(heading),
				"path": PackedVector2Array([centre - across, centre + across]),
				"her": Vector2.ZERO, "heading": heading, "warm": 0.0})

	# `alley_mouse`: waits in an alley until she is within `pursues_within`, then dashes across it.
	# With no map its path is the flat 64px crossing `EventInstance._alley_crossing_path()` falls
	# back to, across X — so she walks up the alley along Y.
	var mouse := EventCatalogue.by_id("alley_mouse")
	list.append({"def": mouse, "how": "waits in an alley, dashes across it",
			"path": PackedVector2Array(), "spawn": Vector2.ZERO,
			"her": Vector2(0.0, mouse.pursues_within + 200.0), "heading": up, "warm": 0.0})

	# `fire_truck` and `military_convoy`: `MAP`/summoned movers, streamed in at
	# `EVENT_STREAM_RADIUS` and driving straight down her street — the closest the city can bring
	# one at her. Their lead is `DangerEdge.LEAD_TIME` and the street, not a siting rule.
	for id: String in ["fire_truck", "military_convoy"]:
		var mover := EventCatalogue.by_id(id)
		var from := Vector2(0.0, -Tuning.EVENT_STREAM_RADIUS)
		list.append({"def": mover, "how": "streamed in down her street",
				"path": PackedVector2Array([from, from + Vector2(0.0, 4000.0)]),
				"her": Vector2(Tuning.TILE_SIZE * 1.5, 0.0), "heading": up, "warm": 0.0})

	# `loose_dog` and `cyclist`: `EventDirector._toward_her()` — `toward_player_lead()` down her own
	# line, routed the same distance behind her.
	for id: String in ["loose_dog", "cyclist"]:
		var def := EventCatalogue.by_id(id)
		for heading: Vector2 in [up, right]:
			var lead := def.toward_player_lead(heading)
			list.append({"def": def, "how": "director, down her line, %s" % _axis(heading),
					"path": PackedVector2Array([heading * lead, -heading * lead]),
					"her": Vector2.ZERO, "heading": heading, "warm": 0.0})

	# `pigeon_flock`: waits, quiet, until she is within `pursues_within`, then goes up.
	var flock := EventCatalogue.by_id("pigeon_flock")
	list.append({"def": flock, "how": "waits on the sidewalk", "path": PackedVector2Array(),
			"spawn": Vector2.ZERO, "her": Vector2(0.0, flock.pursues_within + 200.0),
			"heading": up, "warm": 0.0})

	# `charging_dog`: day 3's own, sited by the director `offscreen_lead()` ahead of her at its
	# `pursue_speed`; and every later day's, a `MAP` row waiting for her
	# (`EventScheduler._for_day()`).
	var dog := EventCatalogue.by_id("charging_dog")
	for heading: Vector2 in [up, right]:
		var lead := Tuning.offscreen_lead(heading, dog.pursue_speed + Tuning.WALK_SPEED,
				dog.offscreen_notice)
		list.append({"def": dog, "how": "day 3, director, ahead of her, %s" % _axis(heading),
				"path": PackedVector2Array(), "spawn": heading * lead,
				"her": Vector2.ZERO, "heading": heading, "warm": 0.0})
	var later_dog := EventScheduler._for_day(dog, Tuning.RUN_TAUGHT_DAY + 1)
	list.append({"def": later_dog, "how": "day 4 on, waits for her", "path": PackedVector2Array(),
			"spawn": Vector2.ZERO, "her": Vector2(0.0, later_dog.pursues_within + 200.0),
			"heading": up, "warm": 0.0})

	# `police_patrol` on the return leg: `EventDirector._toward_her_on_the_road()` — the plain
	# `offscreen_lead()`, down the carriageway lane that drives toward her. She is on the kerb lane
	# of the north sidewalk (offset 1), walking east; the car is in whichever road lane
	# `CrowdLanes.road_lane()` says runs west.
	# The copy `EventDirector._patrol_toward_her()` makes, at no heat.
	var patrol: EventDef = EventCatalogue.by_id("police_patrol").duplicate()
	patrol.shape = EventCatalogue.by_id("police_patrol").shape
	patrol.spawn_mode = EventDef.SpawnMode.TOWARD_PLAYER
	var lane := CrowdLanes.road_lane(false, -1.0)
	var lateral := float(lane - 1) * Tuning.TILE_SIZE
	var patrol_lead := Tuning.offscreen_lead(right, patrol.speed + Tuning.WALK_SPEED,
			patrol.offscreen_notice)
	list.append({"def": patrol, "how": "return leg, director, down the road toward her",
			"path": PackedVector2Array([Vector2(patrol_lead, lateral), Vector2(-patrol_lead, lateral)]),
			"her": Vector2.ZERO, "heading": right, "warm": 0.0})

	# `door_guard`: steps out of the hut beside her, at the door geometry
	# `tests/test_checkpoints.gd` walks — 32px along the street, 48px across.
	var guard := EventCatalogue.by_id("door_guard")
	var guard_at := Vector2(32.0, 48.0)
	list.append({"def": guard, "how": "steps out of the hut beside her",
			"path": PackedVector2Array(), "spawn": guard_at, "her": Vector2(1.0, 0.0),
			"heading": (guard_at - Vector2(1.0, 0.0)).normalized(), "warm": 0.0})

	# `alley_robbery`: waits in the alley until she is within `pursues_within`.
	var robber := EventCatalogue.by_id("alley_robbery")
	list.append({"def": robber, "how": "waits in an alley", "path": PackedVector2Array(),
			"spawn": Vector2.ZERO, "her": Vector2(0.0, robber.pursues_within + 200.0),
			"heading": up, "warm": 0.0})

	# `masked_pursuer`: waits at the foot of the stairwell until she is in it, stands out his
	# notice, then runs up the shaft — her line.
	var masked := EventCatalogue.by_id("masked_pursuer")
	list.append({"def": masked, "how": "waits at the foot of the stairwell",
			"path": PackedVector2Array([Vector2.ZERO, Vector2(0.0, -1600.0)]),
			"her": Vector2(0.0, -(masked.pursues_within + 100.0)), "heading": Vector2.DOWN,
			"warm": 0.0})
	return list

static func _axis(heading: Vector2) -> String:
	return "vertical" if absf(heading.y) > absf(heading.x) else "horizontal"

## One encounter walked with one answer: `{warned_at, reached_at, lead, why, by}`, seconds from the
## start of the encounter, `INF` where it never happened; `by` is `"badge"` or `"sight"`, whichever
## the first warning was. Static and public so `tests/test_events_pursuit.gd` holds the cyclist to
## the identical walk this probe prints, rather than a second copy of it that could disagree.
static func measure(encounter: Dictionary, answer: Answer, edge: DangerEdge) -> Dictionary:
	var def: EventDef = encounter["def"]
	var path: PackedVector2Array = encounter["path"]
	var spawn: Vector2 = encounter.get("spawn", path[0] if path.size() > 0 else Vector2.ZERO)
	var instance := EventInstance.new()
	instance.setup(def, spawn, path)
	var her: Vector2 = encounter["her"]
	var heading: Vector2 = encounter["heading"]
	var velocity := heading * Tuning.WALK_SPEED
	var result := {"warned_at": INF, "reached_at": INF, "lead": INF, "why": "30s", "by": ""}
	var warm_steps := int(ceil(float(encounter["warm"]) / STEP))
	for _i in warm_steps:
		instance._process(STEP)
	# `DangerEdge._measure()`'s own per-instance state, started the frame it is first seen.
	var was := instance.global_position
	var approach := 0.0
	var hold := 0.0
	var elapsed := 0.0
	while elapsed < LIMIT:
		her += velocity * STEP
		instance.player_at = her
		instance.player_running = false
		instance._process(STEP)
		elapsed += STEP
		if instance.is_finished or instance.is_leaving:
			result["why"] = "it left"
			break
		var at := instance.global_position
		var raw := DangerEdge.approach_speed(was, at, her, STEP)
		approach = lerpf(approach, raw, clampf(STEP * DangerEdge.SMOOTHING, 0.0, 1.0))
		was = at
		var gap := maxf(0.0, at.distance_to(her) - def.outer_radius)
		var in_view := _in_view(at - her, 0.0)
		if edge._is_worth_an_arrow(instance) and DangerEdge.announces(approach, gap) \
				and not _in_view(at - her, DangerEdge.SCREEN_MARGIN / ZOOM):
			hold = DangerEdge.HOLD
		else:
			hold = maxf(0.0, hold - STEP)
		var badge := hold > 0.0 and not in_view
		if result["warned_at"] == INF and not instance.is_waiting() and (in_view or badge):
			result["warned_at"] = elapsed
			result["by"] = "sight" if in_view else "badge"
			match answer:
				Answer.STAND:
					velocity = Vector2.ZERO
				Answer.AWAY:
					velocity = -heading * Tuning.WALK_SPEED
		if result["warned_at"] != INF and _reaches(instance, her):
			result["reached_at"] = elapsed
			result["lead"] = elapsed - float(result["warned_at"])
			break
	instance.free()
	return result

static func _in_view(offset: Vector2, margin: float) -> bool:
	return absf(offset.x) <= Tuning.VIEW_HALF_EXTENT.x + margin \
			and absf(offset.y) <= Tuning.VIEW_HALF_EXTENT.y + margin

static func _reaches(instance: EventInstance, her: Vector2) -> bool:
	if instance.def.hard_fail:
		return instance.is_lethal_at(her)
	if instance.is_telegraphing() or instance.is_waiting():
		return false
	return instance.contribution_at(her) > 0.0
