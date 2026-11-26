extends RefCounted
## `BadgeModel` stepped on its own: fakes for the dangers, a rectangle for the view — no scene, no
## camera, no frame timing. Which warnings and which warned things carry a screen-edge badge, when it
## comes down and the order the badges are listed in are decided there, so they are checked there;
## which rows earn a badge at all is the row's own question (`EventDef.announces_its_coming()`,
## checked in `tests/test_events_catalogue.gd`), handed to the model as an answer. The one
## exception is the drawing test, which adds a real `DangerEdge` to the tree and waits for its
## draw, to check that it draws exactly what the model lists.

const STEP := 1.0 / 60.0
## The camera's view about her at (0, 0): what is in sight.
const VIEW := Rect2(-320.0, -180.0, 640.0, 360.0)

func run(t: TestRunner) -> void:
	_test_a_danger_in_the_world_that_was_not_warned_of_has_no_badge(t)
	_test_a_thing_that_arrives_under_its_warning_keeps_its_badge(t)
	_test_a_warned_thing_keeps_its_badge_while_it_stands_and_while_it_turns_away(t)
	_test_a_warned_thing_seen_once_carries_no_badge_again(t)
	_test_a_warned_badge_ends_when_its_danger_is_over_or_leaves_the_world(t)
	_test_six_warned_things_at_once_are_all_badged_until_each_is_in_sight(t)
	await _test_the_drawing_shows_every_badge_the_model_lists(t)
	_test_a_row_that_does_not_announce_has_no_badge(t)
	_test_a_pending_warning_is_announced_for_its_whole_warning(t)
	_test_a_pending_warning_is_listed_closing_at_its_approach_speed(t)
	_test_every_badge_is_listed_soonest_arrival_first(t)
	_test_the_warning_with_less_time_left_is_listed_first(t)
	_test_a_pending_warning_is_ranked_by_its_arrival_among_warned_things(t)
	_test_a_subject_no_longer_handed_over_is_forgotten(t)

static func _vehicle(key: int, at: Vector2, speed := 190.0) -> BadgeModel.Subject:
	var s := BadgeModel.Subject.new()
	s.key = key
	s.position = at
	s.approach_speed = speed
	return s

## A thing created where its warning pointed (`EventInstance.was_warned_of()`).
static func _warned(key: int, at: Vector2, speed := 190.0) -> BadgeModel.Subject:
	var s := _vehicle(key, at, speed)
	s.warned = true
	return s

static func _step(model: BadgeModel, subjects: Array) -> void:
	for s: BadgeModel.Subject in subjects:
		if not s.pending:
			s.shown = VIEW.has_point(s.position)
	model.step(Vector2.ZERO, subjects)

static func _up(model: BadgeModel, id: String) -> bool:
	for b in model.announcing():
		if b.logged_name() == id:
			return true
	return false

## **One path, a warning put up before its danger is placed** *(minty-dolphin #852: "Don't let
## legacy implementations prevent you from establishing a clean design")*: a fire engine closing on
## her from off screen at 190 px/s, lethal and announcing, that was not created under a warning, is
## never badged, however near it comes before it is in sight. Nothing in the world is measured.
func _test_a_danger_in_the_world_that_was_not_warned_of_has_no_badge(t: TestRunner) -> void:
	var model := BadgeModel.new()
	var truck := _vehicle(1, Vector2(1200.0, 0.0))
	truck.logged_name = "fire_truck"
	var badged := 0
	while not truck.shown:
		truck.position.x -= truck.approach_speed * STEP
		_step(model, [truck])
		badged += 1 if _up(model, "fire_truck") else 0
	t.check(badged == 0, "a danger closing from off screen with no warning first has no badge (%d frames)"
			% badged)

func _test_a_thing_that_arrives_under_its_warning_keeps_its_badge(t: TestRunner) -> void:
	var model := BadgeModel.new()
	var dog := _warned(1, Vector2(VIEW.end.x + 20.0, 0.0), 100.0)
	dog.logged_name = "dog"
	_step(model, [dog])
	t.check(_up(model, "dog"), "created just out of sight under its warning, it is badged at once")
	var kept := true
	while not dog.shown:
		_step(model, [dog])
		kept = kept and (dog.shown or _up(model, "dog"))
		dog.position.x -= 100.0 * STEP
	_step(model, [dog])
	t.check(kept, "and keeps it on every frame until it is in sight")
	t.check(not _up(model, "dog"), "where the thing itself has done the badge's job")

## *"Anyway a badge shouldn't disappear before the entity is visible"* (minty-dolphin #852): a warned
## thing that stops out of sight, and one that turns away from her, keeps its badge.
func _test_a_warned_thing_keeps_its_badge_while_it_stands_and_while_it_turns_away(t: TestRunner) -> void:
	var model := BadgeModel.new()
	var stands := _warned(1, Vector2(600.0, 0.0))
	stands.logged_name = "stands"
	var turns := _warned(2, Vector2(-600.0, 0.0))
	turns.logged_name = "turns"
	var kept := 0
	for i in 120:
		turns.position.x -= 190.0 * STEP
		_step(model, [stands, turns])
		kept += 1 if _up(model, "stands") and _up(model, "turns") else 0
	t.check(kept == 120, "standing or going away out of sight, both keep their badges (%d of 120)" % kept)

## Once she has seen it, its badge has done its job: out of sight again, it carries none.
func _test_a_warned_thing_seen_once_carries_no_badge_again(t: TestRunner) -> void:
	var model := BadgeModel.new()
	var man := _warned(1, Vector2(0.0, 400.0), 130.0)
	man.logged_name = "masked_pursuer"
	_step(model, [man])
	t.check(_up(model, "masked_pursuer"), "out of sight under his warning he is badged")
	man.position = Vector2(0.0, 100.0)
	_step(model, [man])
	t.check(not _up(model, "masked_pursuer"), "in sight, he carries none")
	man.position = Vector2(0.0, -400.0)
	_step(model, [man])
	t.check(not _up(model, "masked_pursuer"), "and past her and out of sight again, still none")

func _test_a_warned_badge_ends_when_its_danger_is_over_or_leaves_the_world(t: TestRunner) -> void:
	var model := BadgeModel.new()
	var truck := _warned(1, Vector2(900.0, 0.0))
	truck.logged_name = "fire_truck"
	_step(model, [truck])
	t.check(_up(model, "fire_truck"), "a warned danger out of sight is badged")
	truck.finished = true
	_step(model, [truck])
	t.check(not _up(model, "fire_truck"), "and loses its badge once it is over")
	var cyclist := _warned(2, Vector2(900.0, 0.0))
	cyclist.logged_name = "cyclist"
	_step(model, [cyclist])
	_step(model, [])
	t.check(not _up(model, "cyclist"), "and one no longer handed over loses its badge")

## No cap on how many are up (board `badge-cap`): six warned things out of sight at once are all
## listed on every frame until each is in sight.
func _test_six_warned_things_at_once_are_all_badged_until_each_is_in_sight(t: TestRunner) -> void:
	var model := BadgeModel.new()
	var subjects: Array = []
	for i in 6:
		var v := _warned(i + 1, Vector2(500.0 + 60.0 * i, -150.0 + 60.0 * i), 190.0)
		v.logged_name = "v%d" % i
		subjects.append(v)
	var short := 0
	var seen := {}
	for f in 200:
		for v: BadgeModel.Subject in subjects:
			v.position.x -= v.approach_speed * STEP
		_step(model, subjects)
		var unseen := 0
		for v: BadgeModel.Subject in subjects:
			if v.shown:
				seen[v.key] = true
			unseen += 0 if seen.has(v.key) else 1
		short += absi(unseen - model.announcing().size())
	t.check(short == 0, "every warned thing not yet seen keeps its badge, six at once (%d short)" % short)

## A row that does not announce its coming (`EventDef.announces_its_coming()` false, the loose dog)
## has no badge, warned of or not.
func _test_a_row_that_does_not_announce_has_no_badge(t: TestRunner) -> void:
	var model := BadgeModel.new()
	var dog := _warned(1, Vector2(900.0, 0.0), 60.0)
	dog.announces = false
	dog.logged_name = "loose_dog"
	var pending := _vehicle(2, Vector2(900.0, 0.0), 60.0)
	pending.pending = true
	pending.left = 0.5
	pending.announces = false
	pending.logged_name = "loose_dog_warning"
	_step(model, [dog, pending])
	t.check(model.announcing().is_empty(), "neither has a badge (%d)" % model.announcing().size())

func _test_the_drawing_shows_every_badge_the_model_lists(t: TestRunner) -> void:
	var atlas := _PictureAtlas.new()
	atlas.acquire(&"events")
	var source := _Source.new(EventSurroundings.new().reading(EventCatalogue.shipped()))
	var player := Node2D.new()
	t.add_child(player)
	var def := EventCatalogue.shipped().by_id("fire_truck")
	for i in 6:
		var at := Vector2(400.0 + 10.0 * i, -60.0 + 24.0 * i)
		var warning := PendingWarning.new(def,
				func(_her: Vector2) -> Vector2: return at, func(_p: Vector2, _her: Vector2) -> bool: return true)
		warning.put_up(Vector2.ZERO)
		source.held.append(warning)
	var edge := DangerEdge.new()
	edge.use_atlas(atlas)
	edge.size = Vector2(1280.0, 720.0)
	t.add_child(edge)
	edge.setup(source, player)
	atlas.watch(edge)
	for i in 4:
		await t.get_tree().process_frame
	t.check(edge.badges().announcing().size() == 6, "six badges listed (%d)" % edge.badges().announcing().size())
	var body := StringName(EventPictures.icon_for(def.picture()))
	var drawn := 0
	if not atlas.passes.is_empty():
		for name: StringName in atlas.passes[atlas.passes.size() - 1]:
			drawn += 1 if name == body else 0
	t.check(drawn == 6, "and six arrows drawn in the last whole draw pass (%d)" % drawn)
	edge.free()
	player.free()
	source.free()
	atlas.release(&"events")

## An atlas that notes the pictures a control asks for in each of its draw passes. The control's
## `draw` signal comes before its `_draw()` in a pass, so a pass is closed by the next one's signal.
class _PictureAtlas extends AtlasLibrary:
	## The finished passes, each the list of region names asked for in it.
	var passes: Array = []
	var _asked: Array[StringName] = []

	func watch(control: Control) -> void:
		control.draw.connect(_close_the_pass)

	## Overrides AtlasLibrary.region.
	func region(name: StringName) -> AtlasTexture:
		_asked.append(name)
		return super.region(name)

	func _close_the_pass() -> void:
		passes.append(_asked)
		_asked = []

## The day's events with nothing in the world and the warnings it is given, standing in for the
## warnings the manager's own board holds (`EventManager.pending_warnings()`). Its view is the
## manager's own, never looked through here, so it sees nothing: a warning is announced on screen or
## off, so the six are announced as the game announces them.
class _Source extends EventManager:
	var held: Array[PendingWarning] = []

	## Overrides EventManager.pending_warnings.
	func pending_warnings() -> Array[PendingWarning]:
		return held

func _test_a_pending_warning_is_announced_for_its_whole_warning(t: TestRunner) -> void:
	var model := BadgeModel.new()
	var w := _vehicle(0, Vector2(0.0, 0.0), 190.0)
	w.pending = true
	w.position = Vector2(100.0, 0.0)  # in view: still announced, nothing there to see
	w.left = 0.7
	w.logged_name = "cyclist"
	model.step(Vector2.ZERO, [w])
	t.check(_up(model, "cyclist"), "a warning with nothing in the world yet is up, on screen or off")

## A warning with nothing in the world yet is listed closing at the approach its subject carries, not
## at nothing: the run log reads this number for the day's charging dog.
func _test_a_pending_warning_is_listed_closing_at_its_approach_speed(t: TestRunner) -> void:
	var model := BadgeModel.new()
	var w := _vehicle(0, Vector2(900.0, 0.0), 240.0)
	w.pending = true
	w.left = 1.5
	w.logged_name = "dog"
	model.step(Vector2.ZERO, [w])
	var listed := model.announcing()
	t.check(listed.size() == 1 and is_equal_approx(listed[0].approach(), 240.0),
			"a pending warning is listed closing at its approach speed (%s)"
			% [listed.map(func(b: EdgeBadges.Badge) -> float: return b.approach())])

## A pending warning with 0.7s left is ranked against a warned thing by when each arrives, at its own
## approach to its field's edge: the warned one, still 0.6s off, is listed ahead of it, and once it
## is 0.75s off the warning is. A warning's arrival time read wrong by a tenth of a second would swap
## the second order.
func _test_a_pending_warning_is_ranked_by_its_arrival_among_warned_things(t: TestRunner) -> void:
	for arrives: float in [0.6, 0.75]:
		var model := BadgeModel.new()
		var live := _warned(1, Vector2(600.0 * arrives, 0.0) + Vector2(VIEW.end.x, 0.0), 600.0)
		live.heard_within = VIEW.end.x
		live.logged_name = "live"
		var warning := _vehicle(2, Vector2(100.0, 0.0), 190.0)
		warning.pending = true
		warning.left = 0.7
		warning.logged_name = "warning"
		_step(model, [live, warning])
		var names := []
		for b in model.announcing():
			names.append(b.logged_name())
		var expected := ["live", "warning"] if arrives < 0.7 else ["warning", "live"]
		t.check(names == expected, "%.2fs off, against a warning with 0.7s left: %s (%s)"
				% [arrives, str(expected), str(names)])

func _test_the_warning_with_less_time_left_is_listed_first(t: TestRunner) -> void:
	for sooner_first: bool in [true, false]:
		var model := BadgeModel.new()
		var late := _vehicle(1, Vector2(100.0, 0.0))
		late.pending = true
		late.left = 2.0
		late.logged_name = "late"
		var soon := _vehicle(2, Vector2(100.0, 0.0))
		soon.pending = true
		soon.left = 0.7
		soon.logged_name = "soon"
		var handed: Array = [soon, late] if sooner_first else [late, soon]
		model.step(Vector2.ZERO, handed)
		var names := []
		for b in model.announcing():
			names.append(b.logged_name())
		t.check(names == ["soon", "late"], "the warning with less time left is first, handed in either order (%s)" % str(names))

func _test_every_badge_is_listed_soonest_arrival_first(t: TestRunner) -> void:
	var model := BadgeModel.new()
	var subjects: Array = []
	for i: int in [3, 0, 4, 1, 2]:
		var v := _warned(i + 1, Vector2(500.0 + 100.0 * i, 0.0))
		v.logged_name = "v%d" % i
		subjects.append(v)
	_step(model, subjects)
	var names := []
	for b in model.announcing():
		names.append(b.logged_name())
	t.check(names == ["v0", "v1", "v2", "v3", "v4"], "all five, the soonest to arrive first (%s)" % str(names))

## What forgetting shows: a warned thing seen once and then no longer handed over is forgotten, so
## the model keeps nothing of things gone from the world. A thing handed over again under the same
## key is what the game never makes (an instance id is never reused while the model runs), so the
## check is the model's own: it holds no more keys than it is handed.
func _test_a_subject_no_longer_handed_over_is_forgotten(t: TestRunner) -> void:
	var model := BadgeModel.new()
	var seen := _warned(7, Vector2(100.0, 0.0))
	seen.logged_name = "seen"
	_step(model, [seen])
	t.check(not _up(model, "seen"), "a warned thing in sight has no badge")
	_step(model, [])
	seen.position = Vector2(900.0, 0.0)
	_step(model, [seen])
	t.check(_up(model, "seen"), "forgotten once it is gone, the same key out of sight is badged afresh")
